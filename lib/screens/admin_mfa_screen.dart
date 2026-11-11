import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'admin_dashboard_screen.dart';

class AdminMfaScreen extends StatefulWidget {
  final String challengeToken;
  final bool setupRequired;
  final bool rememberMe;

  const AdminMfaScreen({
    super.key,
    required this.challengeToken,
    required this.setupRequired,
    required this.rememberMe,
  });

  @override
  State<AdminMfaScreen> createState() => _AdminMfaScreenState();
}

class _AdminMfaScreenState extends State<AdminMfaScreen> {
  static const Color navy = Color(0xFF050B25);
  static const Color blue = Color(0xFF3478FF);
  static const Color purple = Color(0xFF8052F5);
  static const Color cyan = Color(0xFF19D9ED);

  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isRecoveryMode = false;
  bool _setupLoading = false;
  String? _qrCode;
  String? _manualSecret;
  String? _enrollmentToken;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.setupRequired) {
      _beginSetup();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _beginSetup() async {
    setState(() {
      _setupLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.adminMfaSetup(
        challengeToken: widget.challengeToken,
      );
      if (!mounted) return;

      setState(() {
        _qrCode = result['qr_code']?.toString();
        _manualSecret = result['manual_secret']?.toString();
        _enrollmentToken = result['enrollment_token']?.toString();
      });

      if (_qrCode == null ||
          _manualSecret == null ||
          _enrollmentToken == null ||
          _enrollmentToken!.isEmpty) {
        throw Exception('The server did not return complete MFA setup details.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _cleanError(e));
      }
    } finally {
      if (mounted) setState(() => _setupLoading = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> _verify() async {
    if (_isLoading || _setupLoading || (widget.setupRequired && _enrollmentToken == null)) return;
    final code = _codeController.text.trim();

    if (!_isRecoveryMode && !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the six-digit code from your authenticator app.');
      return;
    }
    if (_isRecoveryMode && code.isEmpty) {
      setState(() => _error = 'Enter one of your unused recovery codes.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> result;

      if (widget.setupRequired) {
        final enrollmentToken = _enrollmentToken;
        if (enrollmentToken == null || enrollmentToken.isEmpty) {
          throw Exception('MFA setup has not loaded. Please retry.');
        }
        result = await ApiService.adminMfaVerifySetup(
          enrollmentToken: enrollmentToken,
          code: code,
        );
      } else if (_isRecoveryMode) {
        result = await ApiService.adminMfaRecovery(
          challengeToken: widget.challengeToken,
          recoveryCode: code,
        );
      } else {
        result = await ApiService.adminMfaVerifyLogin(
          challengeToken: widget.challengeToken,
          code: code,
        );
      }

      await _completeLogin(result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = _cleanError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeLogin(Map<String, dynamic> result) async {
    final accessToken = result['access_token'];
    final refreshToken = result['refresh_token'];
    final user = result['user'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        user is! Map) {
      throw Exception('The server returned an incomplete authenticated session.');
    }

    final loggedInUser = Map<String, dynamic>.from(user);
    if (loggedInUser['role']?.toString().toLowerCase() != 'admin') {
      throw Exception('The authenticated account is not an administrator.');
    }

    await AuthStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      rememberMe: widget.rememberMe,
    );

    if (!mounted) return;

    final dynamic rawCodes = result['recovery_codes'];
    if (rawCodes is List && rawCodes.isNotEmpty) {
      final codes = rawCodes.map((code) => code.toString()).toList();
      await _showRecoveryCodes(codes);
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _showRecoveryCodes(List<String> codes) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save your recovery codes'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'These codes are shown only once. Store them somewhere safe. Each code can be used one time if you cannot access your authenticator.',
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  codes.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.7,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codes.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recovery codes copied.')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy recovery codes'),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('I have saved them'),
          ),
        ],
      ),
    );
  }

  Widget _buildQr() {
    final value = _qrCode;
    if (value == null) return const SizedBox.shrink();

    final encoded = value.contains(',')
        ? value.substring(value.indexOf(',') + 1)
        : value;

    try {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Image.memory(
          base64Decode(encoded),
          width: 210,
          height: 210,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return const Text('Unable to display the QR code. Use the manual setup key below.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.setupRequired;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('NEXORA Admin Security'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      isSetup ? Icons.qr_code_2_rounded : Icons.verified_user_rounded,
                      size: 48,
                      color: blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSetup ? 'Set up two-factor authentication' : 'Verify your identity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSetup
                          ? 'Scan this QR code using Google Authenticator or Microsoft Authenticator. Then enter the six-digit code shown in the app.'
                          : 'Enter the six-digit code from your authenticator app to continue to the administrator dashboard.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, height: 1.45),
                    ),
                    if (isSetup) ...[
                      const SizedBox(height: 20),
                      if (_setupLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_qrCode != null) ...[
                        Center(child: _buildQr()),
                        const SizedBox(height: 14),
                        const Text(
                          'Manual setup key',
                          style: TextStyle(fontWeight: FontWeight.bold, color: navy),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _manualSecret ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: navy,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _manualSecret == null
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: _manualSecret!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Setup key copied.')),
                                  );
                                },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy setup key'),
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: _beginSetup,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry setup'),
                        ),
                    ],
                    const SizedBox(height: 18),
                    TextField(
                      controller: _codeController,
                      autofocus: !isSetup,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _verify(),
                      keyboardType: _isRecoveryMode ? TextInputType.text : TextInputType.number,
                      maxLength: _isRecoveryMode ? null : 6,
                      textAlign: TextAlign.center,
                      cursorColor: const Color(0xFF3478FF),

                      style: const TextStyle(
                        color: Color(0xFF101638),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),

                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 22,
                          letterSpacing: 8,
                        ),

                        counterText: '',

                        filled: true,
                        fillColor: const Color(0xFFF4F6FA),

                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3478FF),
                            width: 1.5,
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3478FF),
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3478FF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (!isSetup) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isRecoveryMode = !_isRecoveryMode;
                                    _codeController.clear();
                                    _error = null;
                                  });
                                },
                          child: Text(
                            _isRecoveryMode
                                ? 'Use authenticator code instead'
                                : 'Use a recovery code',
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [purple, blue, cyan]),
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading || _setupLoading || (isSetup && _enrollmentToken == null)
                              ? null
                              : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
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
                              : Text(isSetup ? 'Enable MFA & Continue' : 'Verify & Continue'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel and return to login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
