// lib/services/queue_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import '../models/window_model.dart';
import '../utils/constants.dart';
import '../utils/http_client.dart';
import 'notification_service.dart';

class QueueService extends ChangeNotifier {
  TicketModel?      _myTicket;
  List<TicketModel> _waitingQueue  = [];
  Map<String,double>  _baseTimesCache = {}; // populated from settings API
  List<TicketModel> _allActive     = []; // Waiting + Serving, for live "now serving"
  List<WindowModel> _windows       = [];
  bool              _isJoining     = false;
  bool              _isLoading     = false;
  String?           _error;
  Timer?            _pollTimer;
  int?              _savedTicketId;
  TicketStatus?     _lastStatus;

  // Staged-alert guards so each fires only once per ticket
  bool _alerted10min = false;
  bool _alerted5min  = false;
  bool _alertedLate  = false;

  // How long a called student has before the ticket may be cancelled
  static const int lateGraceMinutes = 1;
  static const int lateWarningAtMinutesLeft = 1;

  TicketModel?      get myTicket     => _myTicket;
  List<TicketModel> get waitingQueue => _waitingQueue;
  List<WindowModel> get windows      => _windows;
  bool              get isJoining    => _isJoining;
  bool              get isLoading    => _isLoading;
  String?           get error        => _error;

  // Open windows for a service type, in a stable order (by name).
  List<WindowModel> openWindowsFor(String svc) {
    final list = _windows
        .where((w) => w.serviceType == svc && w.isOpen)
        .toList();
    list.sort((a, b) => a.windowName.compareTo(b.windowName));
    return list;
  }

  // The ticket currently being served at a specific window, if any.
  TicketModel? servingAt(int windowId) {
    final list = _allActive.cast<TicketModel?>().where(
      (t) => t?.status == TicketStatus.serving,
    );
    for (final t in list) {
      if (t != null && t.windowId == windowId) return t;
    }
    return null;
  }

  // Next [count] waiting tickets for a service type, in queue order.
  List<TicketModel> nextWaitingFor(String svc, {int count = 3}) {
    return _waitingQueue
        .where((t) => t.serviceType == svc)
        .take(count)
        .toList();
  }

  int waitingForService(String svc) =>
      _waitingQueue.where((t) => t.serviceType == svc).length;

  String avgErtForService(String svc) {
    final erts = _waitingQueue
        .where((t) => t.serviceType == svc && t.predictedErt != null)
        .map((t) => t.predictedErt!)
        .toList();
    if (erts.isEmpty) return '—';
    final avg = erts.reduce((a, b) => a + b) / erts.length;
    return '${avg.toStringAsFixed(0)} min';
  }

  int get myPosition {
    if (_myTicket == null) return 0;
    final svcQueue = _waitingQueue
        .where((t) => t.serviceType == _myTicket!.serviceType)
        .toList();
    final idx = svcQueue.indexWhere((t) => t.ticketId == _myTicket!.ticketId);
    return idx >= 0 ? idx + 1 : 0;
  }

  int get svcQueueTotal {
    if (_myTicket == null) return 0;
    return _waitingQueue
        .where((t) => t.serviceType == _myTicket!.serviceType)
        .length;
  }

  /// Returns the currently serving ticket for a given service type
  /// Used by the real-time ERT to detect overrun
  TicketModel? servingTicketForService(String svc) {
    try {
      return _allActive.firstWhere(
        (t) => t.serviceType == svc && t.status == TicketStatus.serving,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the base service time in minutes for a service type.
  /// Reads from _baseTimesCache which is populated from the API.
  double baseTimeForService(String svc) {
    return _baseTimesCache[svc] ?? _defaultBaseTime(svc);
  }

  double _defaultBaseTime(String svc) {
    switch (svc) {
      case 'Registrar': return 10.0;
      case 'Cashier':   return 5.0;
      case 'OSA':       return 8.0;
      default:          return 5.0;
    }
  }

  // ── Restore saved ticket on app restart ──────────────────────
  Future<void> restoreTicket(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getInt(AppConstants.prefTicketId);
    if (raw == null) return;
    _savedTicketId = raw;
    await _fetchMyTicket(userId);
  }

  Future<void> _fetchMyTicket(int userId) async {
    try {
      // Fetch today's tickets for this user — look for any active one
      final resp = await AppHttp.get(
        Uri.parse('${AppConstants.ticketsEndpoint}?user_id=$userId&date=${DateTime.now().toIso8601String().substring(0,10)}'),
      );

      final data    = jsonDecode(resp.body) as Map<String, dynamic>;
      final tickets = (data['tickets'] as List<dynamic>)
          .map((j) => TicketModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // First try to find saved ticket by ID, then fall back to any active ticket
      TicketModel? found;
      if (_savedTicketId != null) {
        found = tickets.cast<TicketModel?>().firstWhere(
          (t) => t?.ticketId == _savedTicketId,
          orElse: () => null,
        );
      }
      // If not found by ID, look for any active ticket for this user
      found ??= tickets.cast<TicketModel?>().firstWhere(
        (t) => t != null && t.isActive,
        orElse: () => null,
      );
      // Save the ticket ID for future polls
      if (found != null) _savedTicketId = found.ticketId;

      if (found != null && found.isActive) {
        // ── Stage: "Your turn has arrived" — fires once, the first time
        //    we observe this ticket as Serving (covers the case where a
        //    poll was missed and we go straight from Waiting to Serving
        //    without having recorded the intermediate state).
        if (found.status == TicketStatus.serving &&
            _lastStatus != TicketStatus.serving) {
          await NotificationService.showYourTurn(
            ticketNumber: found.ticketNumber,
            windowName:   found.windowName ?? 'your assigned window',
            serviceType:  found.serviceType,
          );
        }

        // ── Stages: 10-min / 5-min "about to be called" warnings ──────
        // Only meaningful while still waiting and ERT is known.
        if (found.status == TicketStatus.waiting && found.predictedErt != null) {
          final ert = found.predictedErt!;
          if (!_alerted10min && ert <= 10 && ert > 5) {
            _alerted10min = true;
            await NotificationService.showApproachingAlert(
              ticketNumber: found.ticketNumber,
              serviceType:  found.serviceType,
              minutesAway:  10,
            );
          }
          if (!_alerted5min && ert <= 5) {
            _alerted5min = true;
            await NotificationService.showApproachingAlert(
              ticketNumber: found.ticketNumber,
              serviceType:  found.serviceType,
              minutesAway:  5,
            );
          }
        }

        // ── Stage: late-arrival cancellation warning ───────────────────
        // Fires once if the student has been "Serving" (called) for
        // longer than (graceMinutes - warningAtMinutesLeft) and hasn't
        // been marked Served yet.
        if (found.status == TicketStatus.serving &&
            found.calledAt != null &&
            !_alertedLate) {
          final elapsed = DateTime.now().difference(found.calledAt!).inMinutes;
          final minutesLeft = lateGraceMinutes - elapsed;
          if (minutesLeft <= lateWarningAtMinutesLeft && minutesLeft > 0) {
            _alertedLate = true;
            await NotificationService.showLateWarning(
              ticketNumber: found.ticketNumber,
              windowName:   found.windowName ?? 'your assigned window',
              minutesLeft:  minutesLeft,
            );
          }
        }

        _lastStatus = found.status;
        _myTicket   = found;
      } else {
        // Ticket is no longer active (Served, Skipped, or not found).
        // If we never got a chance to notify the student that they were
        // called (e.g. a poll was missed and the ticket went straight
        // from Waiting to Served/Skipped), let them know what happened
        // instead of silently clearing the ticket with no feedback.
        if (found != null && _lastStatus != TicketStatus.serving) {
          if (found.status == TicketStatus.served) {
            await NotificationService.showQueueUpdate(
              'Ticket ${found.ticketNumber} was marked as served.',
            );
          } else if (found.status == TicketStatus.skipped) {
            await NotificationService.showQueueUpdate(
              'Ticket ${found.ticketNumber} was cancelled. '
              'If you believe this is a mistake, please get a new ticket '
              'or speak with staff.',
            );
          }
        }

        _myTicket      = null;
        _savedTicketId = null;
        _lastStatus    = null;
        _alerted10min  = false;
        _alerted5min   = false;
        _alertedLate   = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.prefTicketId);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Polling ───────────────────────────────────────────────────
  void startPolling(int userId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (_) {
      fetchWaitingQueue();
      fetchLiveQueueData();
      if (_savedTicketId != null) _fetchMyTicket(userId);
    });
    fetchWaitingQueue();
    fetchLiveQueueData();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // Fetches windows + all active (Waiting/Serving) tickets together —
  // this powers the "Live Queue" screen showing what number is
  // currently being served at each open window.
  Future<void> fetchLiveQueueData() async {
    try {
      final results = await Future.wait([
        AppHttp.get(Uri.parse(AppConstants.windowsEndpoint)),
        AppHttp.get(Uri.parse(AppConstants.ticketsEndpoint)),
      ]);

      final winData = jsonDecode(results[0].body) as Map<String, dynamic>;
      _windows = (winData['windows'] as List<dynamic>)
          .map((j) => WindowModel.fromJson(j as Map<String, dynamic>))
          .toList();

      final tkData = jsonDecode(results[1].body) as Map<String, dynamic>;
      _allActive = (tkData['tickets'] as List<dynamic>)
          .map((j) => TicketModel.fromJson(j as Map<String, dynamic>))
          .where((t) => t.isActive)
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchWaitingQueue() async {
    try {
      // Also fetch base times from settings for ERT overrun detection
      try {
        final stResp = await AppHttp.get(Uri.parse('${AppConstants.baseUrl}/settings.php'));
        if (stResp.statusCode == 200) {
          final stData = jsonDecode(stResp.body) as Map<String, dynamic>;
          // settings.php returns: { base_times: { Registrar: {minutes: 10}, ... } }
          final bt = stData['base_times'] as Map<String, dynamic>? ?? {};
          double pick(String svc, double fallback) {
            final m = bt[svc];
            final v = m is Map ? m['minutes'] : null;
            return double.tryParse(v?.toString() ?? '') ?? fallback;
          }
          _baseTimesCache = {
            'Registrar': pick('Registrar', 10.0),
            'Cashier':   pick('Cashier',   5.0),
            'OSA':       pick('OSA',       8.0),
          };
        }
      } catch (_) {}

      final resp = await AppHttp.get(Uri.parse('${AppConstants.ticketsEndpoint}?status=Waiting'));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _waitingQueue = (data['tickets'] as List<dynamic>)
          .map((j) => TicketModel.fromJson(j as Map<String, dynamic>))
          .toList();
      
      // Also fetch Serving tickets so we can detect overrun
      try {
        final srvResp = await AppHttp.get(Uri.parse('${AppConstants.ticketsEndpoint}?status=Serving'));
        if (srvResp.statusCode == 200) {
          final srvData = jsonDecode(srvResp.body) as Map<String, dynamic>;
          final serving = (srvData['tickets'] as List<dynamic>)
              .map((j) => TicketModel.fromJson(j as Map<String, dynamic>))
              .toList();
          // Merge into _allActive
          _allActive = [..._waitingQueue, ...serving];
        }
      } catch (_) {}

      // Sync my ticket from the fresh queue
      if (_myTicket != null && _myTicket!.status == TicketStatus.waiting) {
        final updated = _waitingQueue.cast<TicketModel?>().firstWhere(
          (t) => t?.ticketId == _myTicket!.ticketId,
          orElse: () => null,
        );
        if (updated != null) _myTicket = updated;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Join queue ────────────────────────────────────────────────
  Future<String?> joinQueue({
    required int    userId,
    required String serviceType,
    String?         yearSection,
    String?         purpose,
    bool            priority = false,
  }) async {
    if (_myTicket != null && _myTicket!.isActive) {
      return 'You already have an active ticket: ${_myTicket!.ticketNumber}';
    }

    _isJoining = true;
    _error     = null;
    notifyListeners();

    try {
      final resp = await AppHttp.post(
        Uri.parse(AppConstants.ticketsEndpoint),
        body: jsonEncode({
          'user_id':      userId,
          'service_type': serviceType,
          'source':       'mobile',
          if (yearSection != null && yearSection.isNotEmpty)
            'year_section': yearSection,
          if (purpose != null && purpose.isNotEmpty)
            'purpose': purpose,
          if (priority) 'priority': true,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        _myTicket = TicketModel.fromJson(
          data['ticket'] as Map<String, dynamic>,
        );
        _savedTicketId = _myTicket!.ticketId;
        _lastStatus    = _myTicket!.status;
        _alerted10min  = false;
        _alerted5min   = false;
        _alertedLate   = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.prefTicketId, _myTicket!.ticketId);

        await NotificationService.showQueueUpdate(
          'Ticket ${_myTicket!.ticketNumber} issued for '
          '${_myTicket!.serviceType}. ERT: ${_myTicket!.ertDisplay}',
        );

        await fetchWaitingQueue();
        await fetchLiveQueueData();
        // Force fetch ticket from server to ensure full data is loaded
        _savedTicketId = _myTicket!.ticketId;
        await _fetchMyTicket(userId);
        _isJoining = false;
        notifyListeners();
        return null;
      } else {
        _error     = data['error'] as String? ?? 'Failed to join queue.';
        _isJoining = false;
        notifyListeners();
        return _error;
      }
    } catch (_) {
      _error     = 'Cannot connect to server. Check your network.';
      _isJoining = false;
      notifyListeners();
      return _error;
    }
  }

  // ── Leave queue ───────────────────────────────────────────────
  Future<String?> leaveQueue({required int userId}) async {
    if (_myTicket == null) return 'No active ticket.';
    _isLoading = true;
    notifyListeners();

    try {
      final resp = await AppHttp.put(
        Uri.parse(AppConstants.ticketsEndpoint),
        body: jsonEncode({
          'ticket_id': _myTicket!.ticketId,
          'status':    'Skipped',
          'staff_id':  userId,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        _myTicket      = null;
        _savedTicketId = null;
        _lastStatus    = null;
        _alerted10min  = false;
        _alerted5min   = false;
        _alertedLate   = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.prefTicketId);
        await NotificationService.cancelAll();
        await fetchWaitingQueue();
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        notifyListeners();
        return data['error'] as String? ?? 'Error leaving queue.';
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return 'Cannot connect to server.';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
