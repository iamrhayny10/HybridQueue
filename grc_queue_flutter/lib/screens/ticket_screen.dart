// lib/screens/ticket_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../utils/constants.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue  = context.watch<QueueService>();
    final auth   = context.watch<AuthService>();
    final ticket = queue.myTicket;

    if (ticket == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size:  64,
                color: AppConstants.textMuted,
              ),
              SizedBox(height: 16),
              Text(
                'No active ticket',
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w600,
                  color:      AppConstants.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Go to Home and select a service to get a queue ticket.',
                style: TextStyle(
                  fontSize: 14,
                  color:    AppConstants.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: queue.fetchWaitingQueue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _StatusBanner(ticket: ticket),
            if (ticket.status == TicketStatus.serving &&
                ticket.calledAt != null) ...[
              const SizedBox(height: 10),
              _CancellationCountdown(calledAt: ticket.calledAt!),
            ],
            const SizedBox(height: 14),
            _TicketCard(ticket: ticket),
            const SizedBox(height: 14),
            _ErtBlock(ticket: ticket),
            const SizedBox(height: 14),
            if (ticket.status == TicketStatus.waiting) ...[
              _ProgressBlock(queue: queue, ticket: ticket),
              const SizedBox(height: 14),
            ],
            if (ticket.isActive)
              _LeaveButton(
                onLeave: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title:   const Text('Leave queue?'),
                      content: const Text(
                        'Your ticket will be cancelled and your queue position lost.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child:     const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.dangerRed,
                          ),
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  final err = await queue.leaveQueue(
                    userId: auth.user!.userId,
                  );
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err)),
                    );
                  }
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Cancellation countdown — shown while ticket is Serving ─────
class _CancellationCountdown extends StatefulWidget {
  final DateTime calledAt;
  const _CancellationCountdown({required this.calledAt});

  @override
  State<_CancellationCountdown> createState() =>
      _CancellationCountdownState();
}

class _CancellationCountdownState extends State<_CancellationCountdown> {
  static const int graceMinutes = 1;
  late final DateTime _deadline;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _deadline = widget.calledAt.add(const Duration(minutes: graceMinutes));
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final left = _deadline.difference(now);
    if (mounted) {
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    // Urgent once half the grace window (rounded down, min 1) remains.
    final urgentAtMinutes = (graceMinutes / 2).floor().clamp(1, graceMinutes);
    final urgent  = _remaining.inMinutes < urgentAtMinutes;
    final expired = _remaining == Duration.zero;

    final color = expired
        ? AppConstants.dangerRed
        : urgent
            ? AppConstants.dangerRed
            : AppConstants.successGreen;
    final bg = expired || urgent
        ? AppConstants.dangerBg
        : AppConstants.successBg;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            expired ? Icons.error_outline : Icons.timer_outlined,
            size:  20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              expired
                  ? 'Time may be up — please proceed immediately or your '
                    'ticket may be cancelled.'
                  : 'Please arrive within '
                    '${minutes}:${seconds.toString().padLeft(2, '0')} '
                    'or your ticket may be cancelled.',
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final TicketModel ticket;
  const _StatusBanner({required this.ticket});

  @override
  Widget build(BuildContext context) {
    switch (ticket.status) {
      case TicketStatus.serving:
        return _banner(
          bg:         AppConstants.successBg,
          border:     const Color(0xFF86EFAC),
          icon:       Icons.notifications_active_outlined,
          iconColor:  AppConstants.successGreen,
          title:      'Your turn has arrived!',
          subtitle:   'Please proceed to '
              '${ticket.windowName ?? "your assigned window"} now.',
          titleColor: AppConstants.successGreen,
        );
      case TicketStatus.served:
        return _banner(
          bg:         const Color(0xFFF0F9FF),
          border:     const Color(0xFF93C5FD),
          icon:       Icons.check_circle_outline,
          iconColor:  AppConstants.primaryBlue,
          title:      'Transaction complete',
          subtitle:   'Your request has been processed. Thank you!',
          titleColor: AppConstants.primaryBlue,
        );
      case TicketStatus.skipped:
        return _banner(
          bg:         AppConstants.dangerBg,
          border:     const Color(0xFFFCA5A5),
          icon:       Icons.cancel_outlined,
          iconColor:  AppConstants.dangerRed,
          title:      'Ticket cancelled',
          subtitle:   'Your queue ticket was cancelled.',
          titleColor: AppConstants.dangerRed,
        );
      default:
        final color = AppConstants.svcColor(ticket.serviceType);
        return _banner(
          bg:         AppConstants.svcBg(ticket.serviceType),
          border:     color.withOpacity(0.3),
          icon:       Icons.hourglass_top_outlined,
          iconColor:  color,
          title:      'You are in the queue',
          subtitle:   "Stay nearby. We'll notify you when it's your turn.",
          titleColor: color,
        );
    }
  }

  Widget _banner({
    required Color    bg,
    required Color    border,
    required IconData icon,
    required Color    iconColor,
    required String   title,
    required String   subtitle,
    required Color    titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                    color:      titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:    titleColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket detail card ────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.svcColor(ticket.serviceType);
    final bg    = AppConstants.svcBg(ticket.serviceType);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'YOUR QUEUE NUMBER',
            style: TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              letterSpacing: 0.08,
              color:         color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ticket.ticketNumber,
            style: TextStyle(
              fontSize:   56,
              fontWeight: FontWeight.w800,
              color:      color,
              fontFamily: 'monospace',
              height:     1.1,
            ),
          ),
          Text(
            ticket.serviceType,
            style: TextStyle(fontSize: 14, color: color),
          ),
          const SizedBox(height: 14),
          Divider(color: color.withOpacity(0.2)),
          _row('Status',    ticket.statusLabel,        color),
          _row('Window',    ticket.windowName ?? '—',  color),
          _row('Issued at', ticket.issuedTimeDisplay,  color),
          if (ticket.skipCount > 0)
            _row('Re-queued', '${ticket.skipCount}× (max 3)', color),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── ERT block — static until overrun, then counts UP ──────────
//
// Logic:
//   waited   = now − issuedAt
//   baseTime = the service's base time from the Control Panel (NOT this ticket's own ERT)
//   overrun  = waited >= baseTime
//
//   NOT overrun → display = predictedErt (static, e.g. "5.0 min")
//   OVERRUN     → _ertAtOverrunStart is locked ONCE (the ERT at that moment) and
//                 display = _ertAtOverrunStart + (waited − baseTime)
//                 e.g. ERT 5.0, base 5: at 6 min → 6.0 ↑, at 7 min → 7.0 ↑
//                      ERT 7.0, base 5: at 6 min → 8.0 ↑, at 7 min → 9.0 ↑
//
//   Server polls are IGNORED for the display value once overrun has started,
//   so there is no oscillation.
//
//   When the ticket is called (Serving) / Served / Skipped, or nowOverrun turns
//   false → _increasing = false → the timer stops and the ERT FREEZES at its
//   current value.
// ──────────────────────────────────────────────────────────────
class _ErtBlock extends StatefulWidget {
  final TicketModel ticket;
  const _ErtBlock({required this.ticket});

  @override
  State<_ErtBlock> createState() => _ErtBlockState();
}

class _ErtBlockState extends State<_ErtBlock> {
  Timer?  _timer;
  double? _ertAtOverrunStart;   // ERT locked in at the moment the overrun starts
  double  _displayErt = 0;      // the value shown in the card
  bool    _overrun    = false;  // waited >= baseTime
  bool    _increasing = false;  // true only while the number is counting up

  @override
  void initState() {
    super.initState();
    _initDisplay();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(_ErtBlock old) {
    super.didUpdateWidget(old);
    final o = old.ticket;
    final n = widget.ticket;

    // New ticket, or the same ticket re-queued after a skip (new issuedAt /
    // skipCount) — reset everything and start counting again.
    if (o.ticketId != n.ticketId ||
        o.issuedAt != n.issuedAt ||
        o.skipCount != n.skipCount) {
      _ertAtOverrunStart = null;
      _overrun    = false;
      _increasing = false;
      _initDisplay();
      if (n.status == TicketStatus.waiting) _startTimer();
    } else if (n.status == TicketStatus.waiting && _timer == null) {
      // Back to waiting after the timer had stopped — resume.
      _startTimer();
    }
  }

  void _initDisplay() {
    _displayErt = widget.ticket.predictedErt ?? 0;
  }

  void _tick() {
    if (!mounted) return;
    final t = widget.ticket;

    // Called / served / skipped → stop counting, display freezes as it is.
    if (t.status != TicketStatus.waiting) {
      _increasing = false;
      _timer?.cancel();
      _timer = null;
      return;
    }

    final ert = t.predictedErt;
    if (ert == null) return; // nothing to compute yet

    // The overrun point is the SERVICE's base time (Control Panel), not this
    // ticket's own ERT. (The tickets API does not send base_time, so t.baseTime
    // is normally null and the service value is used.)
    final baseTime = t.baseTime ??
        context.read<QueueService>().baseTimeForService(t.serviceType);

    final waitedMin =
        DateTime.now().difference(t.issuedAt).inMilliseconds / 60000.0;
    final nowOverrun = waitedMin >= baseTime;

    if (!nowOverrun) {
      if (_ertAtOverrunStart != null) {
        // Was overrunning, now is not (e.g. base time was raised) → freeze at
        // the current value instead of snapping back to the server value.
        if (_increasing) setState(() => _increasing = false);
        return;
      }
      // Before overrun — static at the server ERT (changes only if the ticket's
      // queue position changes, e.g. a PWD ticket joins ahead of it).
      setState(() {
        _overrun    = false;
        _increasing = false;
        _displayErt = ert;
      });
    } else {
      // First overrun tick — lock the starting ERT once.
      _ertAtOverrunStart ??= ert;
      final addedMin = waitedMin - baseTime;
      setState(() {
        _overrun    = true;
        _increasing = true;
        _displayErt = _ertAtOverrunStart! + addedMin;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;

    // ── Static terminal states ─────────────────────────────────
    if (t.status == TicketStatus.serving) {
      return _ertCard(display: 'Now!',   label: 'Your turn — proceed to the window', overrun: false);
    }
    if (t.status == TicketStatus.served) {
      return _ertCard(display: 'Done ✓', label: 'Transaction complete',              overrun: false);
    }
    if (t.status == TicketStatus.skipped) {
      return _ertCard(display: '—',      label: 'Ticket cancelled',                  overrun: false);
    }

    // ── No ERT yet ────────────────────────────────────────────
    if (t.predictedErt == null) {
      return _ertCard(
        display: '…',
        label:   'Calculating estimate…',
        overrun: false,
      );
    }

    // ── Normal / overrun display ───────────────────────────────
    final displayStr = '${_displayErt.toStringAsFixed(1)} min';

    return _ertCard(
      display: _overrun ? '$displayStr ↑' : displayStr,
      label:   _overrun
          ? 'Overrun — taking longer than expected'
          : 'Estimated response time',
      overrun: _overrun,
    );
  }

  Widget _ertCard({
    required String display,
    required String label,
    required bool   overrun,
  }) {
    final textColor = overrun ? AppConstants.dangerRed : AppConstants.textPrimary;

    return Card(
      color: overrun ? AppConstants.dangerBg : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              display,
              style: TextStyle(
                fontSize:   44,
                fontWeight: FontWeight.w800,
                color:      textColor,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:   13,
                color:      overrun ? AppConstants.dangerRed : AppConstants.textMuted,
                fontWeight: overrun ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: overrun ? AppConstants.dangerBg : AppConstants.successBg,
                borderRadius: BorderRadius.circular(20),
                border: overrun
                    ? Border.all(color: AppConstants.dangerRed.withOpacity(0.3))
                    : null,
              ),
              child: Text(
                overrun
                    ? '⚠ Wait exceeds base time'
                    : 'ML-based prediction · Random Forest',
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color: overrun ? AppConstants.dangerRed : AppConstants.successGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────
class _ProgressBlock extends StatelessWidget {
  final QueueService queue;
  final TicketModel  ticket;
  const _ProgressBlock({required this.queue, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final pos   = queue.myPosition;
    final total = queue.svcQueueTotal;
    final pct   = total > 0
        ? (1 - pos / total).clamp(0.0, 1.0)
        : 0.0;
    final color = AppConstants.svcColor(ticket.serviceType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Queue progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   14,
                  ),
                ),
                Text(
                  '$pos of $total in ${ticket.serviceType}',
                  style: const TextStyle(
                    fontSize:   13,
                    color:      AppConstants.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           pct,
                minHeight:       8,
                backgroundColor: AppConstants.borderGray,
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start',
                    style: TextStyle(
                        fontSize: 11,
                        color:    AppConstants.textMuted)),
                Text('Your turn',
                    style: TextStyle(
                        fontSize: 11,
                        color:    AppConstants.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leave queue button ────────────────────────────────────────
class _LeaveButton extends StatelessWidget {
  final VoidCallback onLeave;
  const _LeaveButton({required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLeave,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.dangerRed,
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          backgroundColor: AppConstants.dangerBg,
        ),
        icon:  const Icon(Icons.exit_to_app_outlined),
        label: const Text('Leave queue'),
      ),
    );
  }
}
