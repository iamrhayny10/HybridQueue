// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // ── Server URL ─────────────────────────────────────────────
  //
  // OPTION A — Local only (hotspot, same WiFi):
  //   'http://192.168.100.3/queue_system/backend/api'
  //
  // OPTION B — Hosted on InfinityFree (works on any internet, recommended):
  //   Replace YOUR_SUBDOMAIN with your actual InfinityFree subdomain
  //   Example: 'https://grcqueue.infinityfreeapp.com/backend/api'
  //   See README.txt → INFINITYFREE HOSTING SETUP for full instructions
  //
  // CURRENT SETTING — Serveo permanent tunnel URL
  // Make sure serveo is running: ssh -R grcqueue2:80:localhost:80 serveo.net
  static const String baseUrl =
      'https://grcqueue2.serveousercontent.com/queue_system/backend/api';

  static const String authEndpoint    = '$baseUrl/auth.php';
  static const String ticketsEndpoint = '$baseUrl/tickets.php';
  static const String pwdEndpoint     = '$baseUrl/pwd.php';
  static const String windowsEndpoint = '$baseUrl/windows.php';

  // ── Shared prefs keys ──────────────────────────────────────
  static const String prefSession  = 'qts_session';
  static const String prefTicketId = 'qts_ticket_id';

  // ── Poll interval ──────────────────────────────────────────
  static const Duration pollInterval = Duration(seconds: 5);

  // ── GRC School location & geofencing ──────────────────────
  // 454 GRC Bldg., Rizal Ave. Ext. Cor. 9th Avenue Grace Park, Caloocan
  static const double schoolLat    = 14.64993;
  static const double schoolLng    = 120.98408;
  // Max distance in meters to allow issuing a ticket
  static const double issueRadiusMeters  = 200.0;
  // Live queue monitoring has NO distance restriction — students can
  // check the queue from anywhere (SM, home, etc.)

  // ── DEV BYPASS ─────────────────────────────────────────────
  // Set to TRUE  → location check is skipped (for testing at home)
  // Set to FALSE → location check is enforced (required for demo/showcase)
  // ⚠️  REMEMBER: change to FALSE before the actual presentation!
  static const bool skipLocationCheck = true;

  // ── Service types ──────────────────────────────────────────
  static const List<String> serviceTypes = [
    'Registrar',
    'Cashier',
    'OSA',
  ];

  // ── Colors ─────────────────────────────────────────────────
  static const Color primaryBlue  = Color(0xFF1A56DB);
  static const Color lightBlue    = Color(0xFFEFF6FF);
  static const Color borderBlue   = Color(0xFFBFDBFE);
  static const Color darkBlue     = Color(0xFF1E40AF);
  static const Color successGreen = Color(0xFF166534);
  static const Color successBg    = Color(0xFFDCFCE7);
  static const Color dangerRed    = Color(0xFF991B1B);
  static const Color dangerBg     = Color(0xFFFEE2E2);
  static const Color borderGray   = Color(0xFFE5E5E0);
  static const Color textPrimary  = Color(0xFF111111);
  static const Color textMuted    = Color(0xFF888888);

  // ── Per-service helpers ────────────────────────────────────
  static Color svcColor(String svc) => switch (svc) {
    'Registrar' => const Color(0xFF1A56DB),
    'Cashier'   => const Color(0xFF059669),
    'OSA'       => const Color(0xFF7C3AED),
    _           => const Color(0xFF1A56DB),
  };

  static Color svcBg(String svc) => switch (svc) {
    'Registrar' => const Color(0xFFEFF6FF),
    'Cashier'   => const Color(0xFFD1FAE5),
    'OSA'       => const Color(0xFFEDE9FE),
    _           => const Color(0xFFEFF6FF),
  };

  static String svcIcon(String svc) => switch (svc) {
    'Registrar' => '🎓',
    'Cashier'   => '💳',
    'OSA'       => '🤝',
    _           => '📋',
  };

  static String svcDesc(String svc) => switch (svc) {
    'Registrar' => 'Enrollment, grades, certificates, transcript of records',
    'Cashier'   => 'Tuition fees, miscellaneous payments, refunds',
    'OSA'       => 'Student affairs, scholarships, student organizations',
    _           => '',
  };
}
