// lib/screens/pwd_priority_screen.dart
// Student applies for the PWD Priority Lane (PWD ID number + photo of the ID).
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/pwd_service.dart';
import '../utils/constants.dart';

class PwdPriorityScreen extends StatefulWidget {
  const PwdPriorityScreen({super.key});

  @override
  State<PwdPriorityScreen> createState() => _PwdPriorityScreenState();
}

class _PwdPriorityScreenState extends State<PwdPriorityScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _picker   = ImagePicker();

  PwdInfo?   _info;
  bool       _loading    = true;
  bool       _submitting = false;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().user?.token ?? '';
    final info  = await PwdService.fetchStatus(token);
    if (!mounted) return;
    setState(() {
      _info    = info;
      _loading = false;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(msg),
        backgroundColor: isError ? AppConstants.dangerRed : AppConstants.successGreen,
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source:       source,
        maxWidth:     1280,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (_) {
      _snack('Could not open the camera or gallery.', isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      _snack('Please add a clear photo of your PWD ID.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    final token = context.read<AuthService>().user?.token ?? '';
    final err   = await PwdService.apply(
      token:      token,
      idNumber:   _idCtrl.text,
      photoBytes: _photo!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) {
      _snack(err, isError: true);
    } else {
      _snack('Submitted! Please wait for the school to verify your PWD ID.');
      setState(() {
        _photo   = null;
        _loading = true;
      });
      _idCtrl.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PWD Priority Lane')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _intro(),
                    const SizedBox(height: 16),
                    _statusCard(),
                    if (_info == null ||
                        _info!.status == 'none' ||
                        _info!.isRejected) ...[
                      const SizedBox(height: 20),
                      _form(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppConstants.lightBlue,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppConstants.borderBlue),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.accessible_forward, color: AppConstants.primaryBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verified Persons with Disability (PWD) are served first in every '
                'queue. Your ticket number will show a "P" (for example RP-001). '
                'To use the Priority Lane, submit your PWD ID for verification.',
                style: TextStyle(fontSize: 13, color: AppConstants.darkBlue),
              ),
            ),
          ],
        ),
      );

  Widget _statusCard() {
    final s = _info?.status ?? 'none';
    late final Color  bg;
    late final Color  fg;
    late final IconData icon;
    late final String title;
    late final String body;

    switch (s) {
      case 'verified':
        bg = AppConstants.successBg;
        fg = AppConstants.successGreen;
        icon = Icons.verified;
        title = 'Priority Lane active';
        body = 'Your PWD status is verified. When you get a queue ticket, '
            'turn on "Use Priority Lane (PWD)".';
        break;
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.hourglass_top;
        title = 'Verification pending';
        body = 'Your PWD ID (${_info?.idNumber ?? ''}) was submitted. '
            'Please wait for the school to review it.';
        break;
      case 'rejected':
        bg = AppConstants.dangerBg;
        fg = AppConstants.dangerRed;
        icon = Icons.error_outline;
        title = 'Verification not approved';
        body = (_info?.rejectReason?.isNotEmpty ?? false)
            ? 'Reason: ${_info!.rejectReason}. You may submit again below.'
            : 'You may submit your PWD ID again below.';
        break;
      default:
        bg = AppConstants.lightBlue;
        fg = AppConstants.darkBlue;
        icon = Icons.info_outline;
        title = 'Not yet registered';
        body = 'Fill in the form below to apply for the Priority Lane.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 13, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PWD ID number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller:         _idCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText:   'e.g. 13-7404-000-0000001',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Please enter your PWD ID number.';
              if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-\/ ]{5,29}$').hasMatch(t)) {
                return 'Enter a valid PWD ID number (6–30 characters).';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          const Text('Photo of your PWD ID',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width:  double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppConstants.borderGray),
            ),
            child: _photo == null
                ? const Center(
                    child: Text('No photo yet',
                        style: TextStyle(color: AppConstants.textMuted)))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_photo!, fit: BoxFit.contain),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _pick(ImageSource.camera),
                  icon:  const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _pick(ImageSource.gallery),
                  icon:  const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Make sure your name, photo and ID number are clearly visible. '
            'Your ID is used only to verify Priority Lane access and is '
            'reviewed by the school administrator.',
            style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit for verification'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
