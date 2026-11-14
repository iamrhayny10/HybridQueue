// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _sidCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _pwCtrl     = TextEditingController();
  final _confCtrl   = TextEditingController();
  bool  _obscurePw  = true;
  bool  _obscureCf  = true;

  // Student ID format: YYYY-MM-NNNNN  e.g. 2017-05-07116
  static final _sidRegex = RegExp(r'^\d{4}-\d{2}-\d{5,}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sidCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth  = context.read<AuthService>();
    final error = await auth.register(
      fullName:  _nameCtrl.text.trim(),
      studentId: _sidCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      password:  _pwCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Account created! You can now log in.'),
          backgroundColor: AppConstants.successGreen,
          duration:        Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(error),
          backgroundColor: AppConstants.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student registration',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                    color:      AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use your official GRC student details.',
                  style: TextStyle(fontSize: 14, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 28),

                // Full name
                TextFormField(
                  controller:            _nameCtrl,
                  textCapitalization:    TextCapitalization.words,
                  textInputAction:       TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText:  'Full name',
                    hintText:   'As it appears on your school ID',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your full name.';
                    }
                    if (v.trim().split(' ').length < 2) {
                      return 'Enter your complete full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Student ID
                TextFormField(
                  controller:      _sidCtrl,
                  keyboardType:    TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                    _StudentIdFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText:  'Student ID',
                    hintText:   'e.g. 2017-05-07116',
                    helperText: 'Format: YYYY-MM-NNNNN',
                    helperStyle: const TextStyle(
                      fontSize: 11,
                      color:    AppConstants.textMuted,
                    ),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    // Live format check icon
                    suffix: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _sidCtrl,
                      builder: (_, val, __) {
                        if (val.text.isEmpty) return const SizedBox.shrink();
                        final ok = _sidRegex.hasMatch(val.text);
                        return Icon(
                          ok
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size:  18,
                          color: ok
                              ? AppConstants.successGreen
                              : AppConstants.textMuted,
                        );
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your Student ID.';
                    }
                    if (!_sidRegex.hasMatch(v.trim())) {
                      return 'Format: YYYY-MM-NNNNN (e.g. 2017-05-07116)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller:      _emailCtrl,
                  keyboardType:    TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText:  'Email address',
                    hintText:   'you@student.grc.edu.ph',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email address.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller:      _pwCtrl,
                  obscureText:     _obscurePw,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText:  'Password',
                    hintText:   'Minimum 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePw
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePw = !_obscurePw),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password.';
                    if (v.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm password
                TextFormField(
                  controller:      _confCtrl,
                  obscureText:     _obscureCf,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText:  'Confirm password',
                    hintText:   'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCf
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCf = !_obscureCf),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (v != _pwCtrl.text) return 'Passwords do not match.';
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        AppConstants.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: AppConstants.borderBlue),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppConstants.primaryBlue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your Student ID is used as your login username. '
                          'Contact the registrar if you do not know your Student ID.',
                          style: TextStyle(
                            fontSize: 12,
                            color:    AppConstants.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading
                      ? const SizedBox(
                          width:  20,
                          height: 20,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Log in'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Auto-format Student ID as YYYY-MM-NNNNN ──────────────────
class _StudentIdFormatter extends TextInputFormatter {
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
