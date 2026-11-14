// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

/// Forgot password for students.
///
/// Step 1 — the student confirms their Student ID and the email they used
///          when registering.
/// Step 2 — if both match, the student chooses a new password.
///
/// Pops with the Student ID after a successful reset so the login screen can
/// pre-fill it.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialStudentId;
  const ForgotPasswordScreen({super.key, this.initialStudentId = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _verifyKey = GlobalKey<FormState>();
  final _resetKey  = GlobalKey<FormState>();
  final _sidCtrl   = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  final _confCtrl  = TextEditingController();

  int     _step       = 1;
  String? _resetToken;
  bool    _obscurePw  = true;
  bool    _obscureCf  = true;

  static final _sidRegex = RegExp(r'^\d{4}-\d{2}-\d{5,}$');

  @override
  void initState() {
    super.initState();
    _sidCtrl.text = widget.initialStudentId;
  }

  @override
  void dispose() {
    _sidCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(message),
        backgroundColor: AppConstants.dangerRed,
      ),
    );
  }

  Future<void> _verify() async {
    if (!_verifyKey.currentState!.validate()) return;
    final auth  = context.read<AuthService>();
    final token = await auth.verifyResetIdentity(
      studentId: _sidCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    if (token != null) {
      setState(() {
        _resetToken = token;
        _step       = 2;
      });
    } else {
      _showError(auth.error ?? 'Verification failed.');
    }
  }

  Future<void> _reset() async {
    if (!_resetKey.currentState!.validate()) return;
    final auth  = context.read<AuthService>();
    final error = await auth.resetPassword(
      studentId:   _sidCtrl.text.trim(),
      resetToken:  _resetToken ?? '',
      newPassword: _pwCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Password reset! Log in with your new password.'),
          backgroundColor: AppConstants.successGreen,
          duration:        Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(_sidCtrl.text.trim());
    } else {
      _showError(error);
      // Token expired or invalid — ask the student to verify again.
      if (error.toLowerCase().contains('verify again')) {
        setState(() {
          _step       = 1;
          _resetToken = null;
          _pwCtrl.clear();
          _confCtrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _step == 1 ? _buildVerify(auth) : _buildReset(auth),
        ),
      ),
    );
  }

  // ── Step 1: verify identity ────────────────────────────────
  Widget _buildVerify(AuthService auth) {
    return Form(
      key: _verifyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1 of 2',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      AppConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verify your account',
            style: TextStyle(
              fontSize:   22,
              fontWeight: FontWeight.w700,
              color:      AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your Student ID and the email you used when you registered.',
            style: TextStyle(fontSize: 14, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 28),

          // Student ID
          TextFormField(
            controller:      _sidCtrl,
            keyboardType:    TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
              _ResetStudentIdFormatter(),
            ],
            decoration: const InputDecoration(
              labelText:  'Student ID',
              hintText:   'e.g. 2017-05-07116',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your Student ID.';
              }
              if (!_sidRegex.hasMatch(v.trim())) {
                return 'Format: YYYY-MM-NNNNN (e.g. 2017-05-07116).';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Registered email
          TextFormField(
            controller:       _emailCtrl,
            keyboardType:     TextInputType.emailAddress,
            textInputAction:  TextInputAction.done,
            onFieldSubmitted: (_) => _verify(),
            decoration: const InputDecoration(
              labelText:  'Registered email',
              hintText:   'you@student.grc.edu.ph',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your registered email.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          _infoNote(
            'Your details must match the Student ID and email on your '
            'registered account. If you no longer remember them, please '
            'contact the registrar.',
          ),
          const SizedBox(height: 22),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _verify,
            child: auth.isLoading ? _spinner() : const Text('Verify account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to log in'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Step 2: choose a new password ──────────────────────────
  Widget _buildReset(AuthService auth) {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2 of 2',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      AppConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a new password',
            style: TextStyle(
              fontSize:   22,
              fontWeight: FontWeight.w700,
              color:      AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Account verified for ${_sidCtrl.text.trim()}. '
            'Choose a new password to continue.',
            style: const TextStyle(fontSize: 14, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 28),

          // New password
          TextFormField(
            controller:      _pwCtrl,
            obscureText:     _obscurePw,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText:  'New password',
              hintText:   'Minimum 8 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePw
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a new password.';
              if (v.length < 8) return 'Password must be at least 8 characters.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm password
          TextFormField(
            controller:       _confCtrl,
            obscureText:      _obscureCf,
            textInputAction:  TextInputAction.done,
            onFieldSubmitted: (_) => _reset(),
            decoration: InputDecoration(
              labelText:  'Confirm new password',
              hintText:   'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCf
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscureCf = !_obscureCf),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password.';
              if (v != _pwCtrl.text) return 'Passwords do not match.';
              return null;
            },
          ),
          const SizedBox(height: 22),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _reset,
            child: auth.isLoading ? _spinner() : const Text('Reset password'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: auth.isLoading
                ? null
                : () => setState(() {
                      _step       = 1;
                      _resetToken = null;
                      _pwCtrl.clear();
                      _confCtrl.clear();
                    }),
            child: const Text('Use different details'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _spinner() => const SizedBox(
        width:  20,
        height: 20,
        child:  CircularProgressIndicator(
          strokeWidth: 2,
          color:       Colors.white,
        ),
      );

  Widget _infoNote(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        AppConstants.lightBlue,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppConstants.borderBlue),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppConstants.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color:    AppConstants.darkBlue,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Auto-format Student ID as YYYY-MM-NNNNN ──────────────────
class _ResetStudentIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 13; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text:      result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
