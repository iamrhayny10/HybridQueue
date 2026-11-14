// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _uidCtrl  = TextEditingController();
  final _pwCtrl   = TextEditingController();
  bool  _obscure  = true;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok   = await auth.login(_uidCtrl.text, _pwCtrl.text);
    if (!mounted) return;
    if (ok) {
      await NotificationService.init();
      final queue = context.read<QueueService>();
      await queue.restoreTicket(auth.user!.userId);
      queue.startPolling(auth.user!.userId);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed.'),
          backgroundColor: AppConstants.dangerRed,
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final sid = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialStudentId: _uidCtrl.text.trim()),
      ),
    );
    if (sid != null && mounted) {
      setState(() => _uidCtrl.text = sid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width:  68,
                height: 68,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:       Border.all(color: AppConstants.borderGray),
                ),
                child: Image.asset(
                  'assets/images/grc_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize:   28,
                  fontWeight: FontWeight.w700,
                  color:      AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'GRC Queue — Student Portal',
                style: TextStyle(
                  fontSize: 14,
                  color:    AppConstants.textMuted,
                ),
              ),
              const SizedBox(height: 36),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Student ID field
                    TextFormField(
                      controller:       _uidCtrl,
                      keyboardType:     TextInputType.text,
                      textInputAction:  TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText:  'Student ID',
                        hintText:   'e.g. 2017-05-07116',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your Student ID.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    // Password field
                    TextFormField(
                      controller:      _pwCtrl,
                      obscureText:     _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText:  'Password',
                        hintText:   '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your password.' : null,
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _login,
                child: auth.isLoading
                    ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                          strokeWidth: 2,
                          color:       Colors.white,
                        ),
                      )
                    : const Text('Log in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Create account'),
              ),
              const SizedBox(height: 28),

              // Info note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppConstants.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppConstants.borderBlue),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppConstants.primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Log in using your GRC Student ID '
                        '(e.g. 2017-05-07116) and your registered password.',
                        style: TextStyle(
                          fontSize: 12,
                          color:    AppConstants.darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
