
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'signup_screen.dart';
import 'services/api_service.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/president_dashboard.dart';
import 'services/auth_storage.dart';
import 'screens/admin_mfa_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _loginErrorMessage;
  Timer? _loginErrorTimer;

  static const Color navy = Color(0xFF050B25);
  static const Color blue = Color(0xFF3478FF);
  static const Color purple = Color(0xFF8052F5);
  static const Color cyan = Color(0xFF19D9ED);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _loginErrorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLoginError(String message) {
    _loginErrorTimer?.cancel();
    setState(() => _loginErrorMessage = message);
    _loginErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _loginErrorMessage = null);
    });
  }

  Widget _buildLoginErrorPopup() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      child: _loginErrorMessage == null
          ? const SizedBox(key: ValueKey('no-login-error-popup'))
          : ConstrainedBox(
              key: const ValueKey('login-error-popup'),
              constraints: const BoxConstraints(maxWidth: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _loginErrorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Administrators must complete MFA before receiving/storing JWT tokens.
      if (result['mfa_required'] == true) {
        final challengeToken = result['challenge_token'];

        if (challengeToken is! String || challengeToken.isEmpty) {
          throw Exception('MFA challenge token missing');
        }

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminMfaScreen(
              challengeToken: challengeToken,
              setupRequired: result['mfa_setup_required'] == true,
              rememberMe: _rememberMe,
            ),
          ),
        );
        return;
      }

      // Student login keeps the existing direct-token flow.
      final accessToken = result['access_token'];
      final refreshToken = result['refresh_token'];

      if (accessToken is! String ||
          accessToken.isEmpty ||
          refreshToken is! String ||
          refreshToken.isEmpty) {
        throw Exception('JWT tokens missing');
      }

      final user = result['user'];
      if (user is! Map) {
        throw Exception('User details missing from login response');
      }

      final loggedInUser = Map<String, dynamic>.from(user);
      final role = loggedInUser['role']?.toString().toLowerCase();

      if (role != 'student' && role != 'club_admin') {
        throw Exception('Unexpected login response for role: $role');
      }

      await AuthStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      _showMessage('Welcome ${loggedInUser['full_name'] ?? 'User'}!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'club_admin'
              ? PresidentDashboard(user: loggedInUser)
              : StudentDashboardScreen(user: loggedInUser),
        ),
      );

    } catch (error) {
      debugPrint('LOGIN ERROR: $error');
      debugPrint('ERROR TYPE: ${error.runtimeType}');

      if (!mounted) return;

      final errorMessage = error.toString().replaceFirst('Exception: ', '');
      _showLoginError(
        errorMessage.isNotEmpty
            ? errorMessage
            : 'Unable to log in. Check your connection or try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    final borderRadius = BorderRadius.circular(30);

    return InputDecoration(
      hintText: hint,

      // Readable placeholder on Android devices
      hintStyle: const TextStyle(
        color: Color(0xFF757D89),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF757D89),
        size: 22,
      ),

      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),

      filled: true,
      fillColor: const Color(0xFFF5F6F8),

      isDense: false,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: blue,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF1F3F7),
          foregroundColor: const Color(0xFF030620),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.g_mobiledata_rounded,
              size: 29,
              color: Color(0xFF4285F4),
            ),
            SizedBox(width: 6),
            Text(
              'Google',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive dimensions
    final bool isSmallScreen = screenWidth < 360;

    final double horizontalMargin =
        isSmallScreen ? 12 : 15;

    final double panelPadding =
        isSmallScreen ? 16 : 22;

    // Preserve the existing logo proportions,
    // but prevent oversized layouts.
    final double logoHeight =
        (screenHeight * 0.48).clamp(270.0, 430.0);

    final double panelOverlap =
        (logoHeight * 0.174).clamp(45.0, 75.0);

    return Scaffold(
      backgroundColor: const Color(0xFF030620),

      resizeToAvoidBottomInset: false,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final formContent = SizedBox(
              width: constraints.maxWidth.clamp(0.0, 480.0).toDouble(),
              child: Column(
                    children: [
                      // NEXORA LOGO BACKGROUND
                      SizedBox(
                        height: logoHeight,
                        width: double.infinity,
                        child: ColoredBox(
                          color: navy,
                          child: Image.asset(
                            'assets/images/nexora_icon_as_bg.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),

                      // OVERLAPPING WHITE LOGIN PANEL
                      Transform.translate(
                        offset: Offset(0, -panelOverlap),

                        child: Container(
                          width: double.infinity,

                          margin: EdgeInsets.symmetric(
                            horizontal: horizontalMargin,
                          ),

                          padding: EdgeInsets.fromLTRB(
                            panelPadding,
                            14,
                            panelPadding,
                            16,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: Form(
                            key: _formKey,

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,

                              children: [
                                // LOGIN TITLE
                                const Text(
                                  'Login',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: navy,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // SIGNUP LINK
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    const Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),

                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: blue,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // EMAIL FIELD
                                TextFormField(
                                  controller: _emailController,

                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),

                                  keyboardType:
                                      TextInputType.emailAddress,

                                  textInputAction:
                                      TextInputAction.next,

                                  decoration: _inputDecoration(
                                    hint:
                                        'Enter your email address',
                                    icon:
                                        Icons.mail_outline_rounded,
                                  ),

                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }

                                    if (!RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(value.trim())) {
                                      return 'Enter a valid email address';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // PASSWORD FIELD
                                TextFormField(
                                  controller:
                                      _passwordController,

                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    letterSpacing: -0.5,
                                  ),

                                  obscureText: _hidePassword,

                                  textInputAction:
                                      TextInputAction.done,

                                  onFieldSubmitted: (_) => _login(),

                                  decoration: _inputDecoration(
                                    hint: 'Enter your password',
                                    icon:
                                        Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? 'Show password'
                                          : 'Hide password',

                                      onPressed: () {
                                        setState(() {
                                          _hidePassword =
                                              !_hidePassword;
                                        });
                                      },

                                      icon: Icon(
                                        _hidePassword
                                            ? Icons
                                                .visibility_off_outlined
                                            : Icons
                                                .visibility_outlined,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ),

                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return 'Please enter your password';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 10),

                                // REMEMBER ME + FORGOT PASSWORD
                                Wrap(
                                  alignment:
                                      WrapAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,

                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          activeColor: blue,
                                          side: const BorderSide(
                                          color: Color(0xFF3478FF),
                                          width: 2,
                                          ),

                                          shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          ),
                                          visualDensity:
                                              VisualDensity.compact,

                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe =
                                                  value ?? false;
                                            });
                                          },
                                        ),

                                        const Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        _showMessage(
                                          'Password recovery coming soon.',
                                        );
                                      },

                                      style: TextButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                      ),

                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                // GRADIENT LOGIN BUTTON
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 54,
                                      width: double.infinity,
                                      child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient:
                                          const LinearGradient(
                                        colors: [
                                          purple,
                                          blue,
                                          cyan,
                                        ],
                                        begin:
                                            Alignment.centerLeft,
                                        end:
                                            Alignment.centerRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),

                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _login,

                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.transparent,
                                        foregroundColor:
                                            Colors.white,
                                        shadowColor:
                                            Colors.transparent,
                                        elevation: 0,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),

                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 64,
                                      child: _buildLoginErrorPopup(),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                // The error floats over this divider without
                                // changing the layout of the login form.
                                SizedBox(
                                  height: 20,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Divider(
                                              color: Color(0xFFE4E8EB),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'Or Continue With',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                            child: Divider(
                                              color: Color(0xFFE4E8EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Transform.translate(
                                        // Legacy divider overlay is kept out of
                                        // view; the visible popup is above Login.
                                        offset: const Offset(0, -10000),
                                        child: OverflowBox(
                                          maxWidth: 300,
                                          maxHeight: 80,
                                          alignment: Alignment.center,
                                          child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          reverseDuration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          transitionBuilder:
                                              (child, animation) {
                                          final curvedAnimation =
                                              CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                            reverseCurve: Curves.easeInCubic,
                                          );
                                          return FadeTransition(
                                            opacity: curvedAnimation,
                                            child: ScaleTransition(
                                              scale: Tween<double>(
                                                begin: 0.92,
                                                end: 1,
                                              ).animate(curvedAnimation),
                                              child: child,
                                            ),
                                          );
                                          },
                                          child: _loginErrorMessage == null
                                            ? const SizedBox(
                                                key: ValueKey('no-login-error'),
                                              )
                                            : ConstrainedBox(
                                                key: const ValueKey(
                                                  'login-error',
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: 300,
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.82),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Color(0x33000000),
                                                          blurRadius: 12,
                                                          offset: Offset(0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .error_outline_rounded,
                                                          color: Colors.redAccent,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            _loginErrorMessage!,
                                                            textAlign:
                                                                TextAlign.center,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                0xFFD32F2F,
                                                              ),
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // GOOGLE BUTTON
                                _socialButton(
                                  onTap: () {
                                    _showMessage(
                                      'Google sign-in is not connected yet.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Prevent bottom clipping
                      const SizedBox(height: 16),
                    ],
              ),
            );

            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: formContent,
              ),
            );
          },
        ),
      ),
    );
  }
}
