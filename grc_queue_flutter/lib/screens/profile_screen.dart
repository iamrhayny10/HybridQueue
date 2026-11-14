// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user!;

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius:          44,
              backgroundColor: AppConstants.lightBlue,
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize:   30,
                  fontWeight: FontWeight.w700,
                  color:      AppConstants.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w700,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color:        AppConstants.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role,
                style: const TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppConstants.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Card(
              child: Column(
                children: [
                  _infoRow(Icons.badge_outlined,  'Student ID', user.username),
                  const Divider(height: 1),
                  _infoRow(Icons.email_outlined,  'Email',      user.email),
                  const Divider(height: 1),
                  _infoRow(Icons.person_outline,  'Full name',  user.fullName),
                  const Divider(height: 1),
                  _infoRow(Icons.school_outlined, 'Role',       user.role),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _infoRow(Icons.info_outline, 'App version', '1.0.0'),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Institution',
                    'Global Reciprocal Colleges',
                  ),
                  const Divider(height: 1),
                  _infoRow(Icons.map_outlined, 'Campus', 'Caloocan City'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            OutlinedButton.icon(
              onPressed: () async {
                context.read<QueueService>().stopPolling();
                await context.read<AuthService>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.dangerRed,
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: AppConstants.dangerBg,
              ),
              icon:  const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.primaryBlue),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color:    AppConstants.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                  color:      AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
