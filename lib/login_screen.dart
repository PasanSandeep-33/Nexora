
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'signup_screen.dart';
import 'services/api_service.dart';
import 'screens/student_dashboard_screen.dart';
import 'services/auth_storage.dart';

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
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

      final accessToken = result['access_token'];
      final refreshToken = result['refresh_token'];

      if (accessToken is! String ||
          accessToken.isEmpty ||
          refreshToken is! String ||
          refreshToken.isEmpty) {
        throw Exception('JWT tokens missing');
      }

      await AuthStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      final user = result['user'];

      _showMessage(
        'Welcome ${user is Map ? (user['full_name'] ?? '') : ''}!',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const StudentDashboardScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Login failed. Please check your email and password.',
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

      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,

              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                    ? 20
                    : 0,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                  ),

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
                                        fontSize: 12,
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
                                          fontSize: 12,
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
                                            fontSize: 12,
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                // GRADIENT LOGIN BUTTON
                                SizedBox(
                                  height: 54,

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

                                const SizedBox(height: 22),

                                // DIVIDER
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
                                          color:
                                              Colors.grey.shade600,
                                          fontSize: 12,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
