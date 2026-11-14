// lib/screens/service_request_screen.dart
// Shown when a student taps a service (Registrar/Cashier/OSA).
// Collects Full Name, Student ID, Purpose
// then calls joinQueue with that info attached.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../services/location_service.dart';
import '../services/pwd_service.dart';
import '../utils/constants.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String serviceType;
  const ServiceRequestScreen({super.key, required this.serviceType});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _sidCtrl     = TextEditingController();
  final _purposeCtrl = TextEditingController();

  bool _loading = false;

  // PWD Priority Lane (only offered to verified PWD students)
  bool _pwdVerified = false;
  bool _usePriority = true;

  // Purpose suggestions per service type
  List<String> get _purposes {
    switch (widget.serviceType) {
      case 'Registrar':
        return ['Enrollment', 'Grade Slip', 'Certificate of Enrollment',
                'Transcript of Records', 'Good Moral Certificate',
                'Document Request', 'Records Verification'];
      case 'Cashier':
        return ['Pay Tuition Fee', 'Pay Miscellaneous Fee',
                'Purchase Uniform', 'Purchase ID', 'Print Grade Slip',
                'Print COM (Certificate of Matriculation)', 'Refund'];
      case 'OSA':
        return ['Scholarship Application', 'Student Clearance',
                'Student Organization Concern', 'Student Affairs',
                'Leave of Absence', 'Complaint / Grievance'];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    if (auth.user != null) {
      _nameCtrl.text = auth.user!.fullName;
      _sidCtrl.text  = auth.user!.username;
      PwdService.fetchStatus(auth.user!.token).then((info) {
        if (mounted && info != null && info.isVerified) {
          setState(() => _pwdVerified = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sidCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Location check
    if (!AppConstants.skipLocationCheck) {
      final locationError = await LocationService.checkWithinSchool();
      if (!mounted) return;
      if (locationError != null) {
        _snack(locationError, isError: true);
        setState(() => _loading = false);
        return;
      }
    }

    final auth  = context.read<AuthService>();
    final queue = context.read<QueueService>();

    final err = await queue.joinQueue(
      userId:      auth.user!.userId,
      serviceType: widget.serviceType,
      yearSection: '',
      purpose:     _purposeCtrl.text.trim(),
      priority:    _pwdVerified && _usePriority,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err, isError: true);
    } else {
      // Go back to home and switch to My Ticket tab
      Navigator.pop(context, true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : AppConstants.primaryBlue,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color get _svcColor {
    switch (widget.serviceType) {
      case 'Registrar': return const Color(0xFF1A56DB);
      case 'Cashier':   return const Color(0xFF059669);
      case 'OSA':       return const Color(0xFF7C3AED);
      default:          return AppConstants.primaryBlue;
    }
  }

  String get _svcIcon {
    switch (widget.serviceType) {
      case 'Registrar': return '🎓';
      case 'Cashier':   return '💳';
      case 'OSA':       return '🤝';
      default:          return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_svcIcon} ${widget.serviceType}'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service header card
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        _svcColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: _svcColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Text(_svcIcon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceType,
                            style: TextStyle(
                              fontSize:   17,
                              fontWeight: FontWeight.w700,
                              color:      _svcColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Fill out the form below to get a queue ticket.',
                            style: TextStyle(
                              fontSize: 12,
                              color:    _svcColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _label('Full Name *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Juan Dela Cruz'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),

              // Student ID
              _label('Student ID *'),
              TextFormField(
                controller: _sidCtrl,
                decoration: const InputDecoration(hintText: 'e.g. 2021-00001'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Student ID is required' : null,
              ),
              const SizedBox(height: 14),

              // Purpose
              _label('Purpose *'),
              // Suggestion chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _purposes.map((p) => GestureDetector(
                  onTap: () => setState(() => _purposeCtrl.text = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _purposeCtrl.text == p
                          ? _svcColor.withOpacity(0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _purposeCtrl.text == p
                            ? _svcColor
                            : AppConstants.borderGray,
                      ),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color: _purposeCtrl.text == p
                            ? _svcColor
                            : AppConstants.textPrimary,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _purposeCtrl,
                decoration: const InputDecoration(
                  hintText: 'Select above or type your purpose...',
                ),
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Purpose is required' : null,
              ),
              if (_pwdVerified) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color:        AppConstants.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: AppConstants.borderBlue),
                  ),
                  child: SwitchListTile(
                    value:     _usePriority,
                    onChanged: (v) => setState(() => _usePriority = v),
                    secondary: const Icon(Icons.accessible_forward,
                        color: AppConstants.primaryBlue),
                    title: const Text('Use Priority Lane (PWD)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('You will be served ahead of the regular queue.'),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Get Queue Ticket button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('🎫', style: TextStyle(fontSize: 18)),
                  label: Text(
                    _loading ? 'Getting ticket…' : 'Get Queue Ticket',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _svcColor,
                    minimumSize:     const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You must be within 200m of GRC to get a ticket.\n'
                'Live queue monitoring works from anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: AppConstants.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
        style: const TextStyle(
          fontSize:   14,
          fontWeight: FontWeight.w600,
          color:      AppConstants.textPrimary,
        ),
      ),
    );
  }
}
