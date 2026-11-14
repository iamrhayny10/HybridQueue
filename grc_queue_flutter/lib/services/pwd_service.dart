// lib/services/pwd_service.dart
// Talks to backend/api/pwd.php (PWD Priority Lane verification).
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/http_client.dart';

class PwdInfo {
  final String  status; // none | pending | verified | rejected
  final String? idNumber;
  final String? rejectReason;
  const PwdInfo({required this.status, this.idNumber, this.rejectReason});

  bool get isVerified => status == 'verified';
  bool get isPending  => status == 'pending';
  bool get isRejected => status == 'rejected';
}

class PwdService {
  static Map<String, String> _auth(String token) => {'X-Auth-Token': token};

  /// Current PWD status of the logged-in student (null if the request failed).
  static Future<PwdInfo?> fetchStatus(String token) async {
    try {
      final resp = await AppHttp.get(
        Uri.parse('${AppConstants.pwdEndpoint}?action=status'),
        headers: _auth(token),
      );
      final d = jsonDecode(resp.body) as Map<String, dynamic>;
      if (d['success'] == true) {
        return PwdInfo(
          status:       d['pwd_status'] as String? ?? 'none',
          idNumber:     d['pwd_id_number'] as String?,
          rejectReason: d['reject_reason'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sends the PWD ID number + photo for verification.
  /// Returns null on success, otherwise an error message.
  static Future<String?> apply({
    required String token,
    required String idNumber,
    required List<int> photoBytes,
  }) async {
    try {
      final resp = await AppHttp.post(
        Uri.parse('${AppConstants.pwdEndpoint}?action=apply'),
        headers: _auth(token),
        body: jsonEncode({
          'pwd_id_number': idNumber.trim(),
          'photo_base64':  base64Encode(photoBytes),
        }),
        timeout: const Duration(seconds: 40),
      );
      final d = jsonDecode(resp.body) as Map<String, dynamic>;
      if (d['success'] == true) return null;
      return d['error'] as String? ?? 'Could not submit. Please try again.';
    } catch (_) {
      return 'Cannot connect to server. Check your network.';
    }
  }
}
