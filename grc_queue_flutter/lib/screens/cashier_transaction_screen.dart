// lib/screens/cashier_transaction_screen.dart
// Students fill out a cashier transaction form from the mobile app.
// Submitted transactions appear in the web admin report logs.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/http_client.dart';

class CashierTransactionScreen extends StatefulWidget {
  const CashierTransactionScreen({super.key});

  @override
  State<CashierTransactionScreen> createState() =>
      _CashierTransactionScreenState();
}

class _CashierTransactionScreenState extends State<CashierTransactionScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _sidCtrl   = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _amountCtrl= TextEditingController();

  String  _purpose  = '';
  bool    _loading  = false;
  bool    _submitted= false;

  static const List<String> _purposes = [
    'Purchase Uniform',
    'Purchase ID',
    'Print Grade Slip',
    'Print COM (Certificate of Matriculation)',
    'Pay Tuition Fee',
    'Pay Miscellaneous Fee',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill student name and ID from logged-in user
    final auth = context.read<AuthService>();
    if (auth.user != null) {
      _nameCtrl.text = auth.user!.fullName;
      _sidCtrl.text  = auth.user!.username;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sidCtrl.dispose();
    _otherCtrl.dispose();
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purpose.isEmpty) {
      _snack('Please select a purpose.', isError: true);
      return;
    }
    if (_purpose == 'Other' && _otherCtrl.text.trim().isEmpty) {
      _snack('Please specify the purpose.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final auth    = context.read<AuthService>();
      final purpose = _purpose == 'Other' ? _otherCtrl.text.trim() : _purpose;
      final amount  = _amountCtrl.text.trim();

      final resp = await AppHttp.post(
        Uri.parse('${AppConstants.baseUrl}/transactions.php'),
        body: jsonEncode({
          'student_name':     _nameCtrl.text.trim(),
          'student_id':       _sidCtrl.text.trim(),
          'purpose':          purpose,
          'amount':           amount.isNotEmpty ? double.tryParse(amount) : null,
          'notes':            _notesCtrl.text.trim(),
          'user_id':          auth.user?.userId ?? 0,
          'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (data['success'] == true) {
        setState(() { _submitted = true; _loading = false; });
      } else {
        _snack(data['error'] ?? 'Failed to submit. Try again.', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Connection error. Check your network.', isError: true);
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : AppConstants.primaryBlue,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _reset() {
    _formKey.currentState?.reset();
    _purpose = '';
    _otherCtrl.clear();
    _notesCtrl.clear();
    _amountCtrl.clear();
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Transaction'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F0),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Success screen ──────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color:        const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 44, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 24),
            const Text('Transaction Submitted!',
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w700,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your transaction has been recorded.\n'
              'The cashier staff will process your request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppConstants.textMuted),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reset,
                child: const Text('Submit another'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF1A56DB)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill out this form to request a cashier transaction. '
                      'The cashier staff will process it in order.',
                      style: TextStyle(
                        fontSize: 13,
                        color:    Color(0xFF1E40AF),
                        height:   1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Student Name
            _label('Student Name *'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Juan Dela Cruz',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Student ID
            _label('Student ID'),
            TextFormField(
              controller: _sidCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 2021-00001',
              ),
            ),
            const SizedBox(height: 14),

            // Purpose
            _label('Purpose of Transaction *'),
            Container(
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppConstants.borderGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:       _purpose.isEmpty ? null : _purpose,
                  hint:        const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child:   Text('Select purpose',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15)),
                  ),
                  isExpanded:  true,
                  padding:     const EdgeInsets.symmetric(horizontal: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: _purposes.map((p) => DropdownMenuItem(
                    value: p,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child:   Text(p, style: const TextStyle(fontSize: 15)),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _purpose = v ?? ''),
                ),
              ),
            ),
            if (_purpose == 'Other') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _otherCtrl,
                decoration: const InputDecoration(
                  hintText: 'Specify your transaction...',
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Amount
            _label('Amount (₱, optional)'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText:  '0.00',
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            _label('Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines:   3,
              decoration: const InputDecoration(
                hintText: 'Any additional information...',
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child:   Text(text,
        style: const TextStyle(
          fontSize:   14,
          fontWeight: FontWeight.w600,
          color:      AppConstants.textPrimary,
        ),
      ),
    );
  }
}
