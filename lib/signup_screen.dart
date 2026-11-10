import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';
import 'services/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;
  String? _signupErrorMessage;
  Timer? _signupErrorTimer;

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
    _signupErrorTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSignupError(String message) {
    _signupErrorTimer?.cancel();
    setState(() => _signupErrorMessage = message);
    _signupErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _signupErrorMessage = null);
    });
  }

  Widget _buildSignupErrorPopup() {
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
      child: _signupErrorMessage == null
          ? const SizedBox(key: ValueKey('no-signup-error'))
          : ConstrainedBox(
              key: const ValueKey('signup-error'),
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
                        _signupErrorMessage!,
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

  String? _signupValidationMessage() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (fullName.isEmpty) return 'Please enter your full name.';
    if (email.isEmpty) return 'Please enter your email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (password.isEmpty) return 'Please create a password.';
    if (password.length < 8) return 'Password must contain at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character.';
    }
    if (confirmation.isEmpty) return 'Please confirm your password.';
    if (password != confirmation) return 'Passwords do not match.';
    return null;
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    final validationMessage = _signupValidationMessage();
    if (validationMessage != null) {
      _showSignupError(validationMessage);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.signup(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      _showMessage(
        result['message']?.toString() ?? 'Account created successfully!',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (error) {
      debugPrint('Signup error type: ${error.runtimeType}');
      
      if (!mounted) return;

      _showSignupError(
        error.toString().replaceFirst('Exception: ', ''),
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
    final radius = BorderRadius.circular(30);

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF757D89),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF757D89), size: 22),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        letterSpacing: obscureText ? -0.5 : 0,
      ),
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: _inputDecoration(hint: hint, icon: Icons.lock_outline_rounded)
          .copyWith(
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Show password' : 'Hide password',
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
                size: 22,
              ),
            ),
          ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final normalViewportHeight = screenHeight - MediaQuery.paddingOf(context).vertical;

    final isSmallScreen = screenWidth < 360;

    final horizontalMargin = isSmallScreen ? 12.0 : 15.0;

    final panelPadding = isSmallScreen ? 16.0 : 22.0;

    final logoHeight = (screenHeight * 0.48).clamp(270.0, 430.0);

    final panelOverlap = (logoHeight * (50 / 430)).clamp(35.0, 50.0);

    return Scaffold(
      backgroundColor: const Color(0xFF030620),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final formContent = SizedBox(
              width: screenWidth.clamp(0.0, 480.0).toDouble(),
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

                  // OVERLAPPING SIGNUP PANEL
                  Transform.translate(
                    offset: Offset(0, -panelOverlap),
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        panelPadding,
                        18,
                        panelPadding,
                        22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // TITLE
                            const Text(
                              'Create account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // LOGIN LINK
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // FULL NAME
                            TextFormField(
                              controller: _fullNameController,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                hint: 'Enter your full name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // EMAIL
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hint: 'Enter your email address',
                                icon: Icons.mail_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())) {
                                  return 'Enter a valid email address';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // PASSWORD
                            _passwordField(
                              controller: _passwordController,
                              hint: 'Create a password',
                              obscureText: _hidePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please create a password';
                                }

                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // CONFIRM PASSWORD
                            _passwordField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm your password',
                              obscureText: _hideConfirmPassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _hideConfirmPassword = !_hideConfirmPassword;
                                });
                              },
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signUp(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // SIGN UP BUTTON
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 54,
                                  width: double.infinity,
                                  child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [purple, blue, cyan],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 64,
                                  child: _buildSignupErrorPopup(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );

            if (!isKeyboardVisible) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: formContent,
                ),
              );
            }

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                height: normalViewportHeight,
                width: screenWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: formContent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
