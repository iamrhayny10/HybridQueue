// lib/screens/live_queue_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/window_model.dart';
import '../services/queue_service.dart';
import '../utils/constants.dart';

class LiveQueueScreen extends StatelessWidget {
  const LiveQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueService>();

    return RefreshIndicator(
      onRefresh: queue.fetchLiveQueueData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live queue',
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w700,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'See which number is being served and who is next '
              'at each open window. Updated automatically.',
              style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
            ),
            const SizedBox(height: 20),
            ...AppConstants.serviceTypes.map((svc) {
              final wins    = queue.openWindowsFor(svc);
              final waiting = queue.waitingForService(svc);
              final nextUp  = queue.nextWaitingFor(svc, count: 3);
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _ServiceSection(
                  svc:     svc,
                  windows: wins,
                  waiting: waiting,
                  nextUp:  nextUp,
                  queue:   queue,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Service section ───────────────────────────────────────────
class _ServiceSection extends StatelessWidget {
  final String            svc;
  final List<WindowModel> windows;
  final int               waiting;
  final List<TicketModel> nextUp;
  final QueueService      queue;

  const _ServiceSection({
    required this.svc,
    required this.windows,
    required this.waiting,
    required this.nextUp,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.svcColor(svc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service header
        Row(
          children: [
            Text(AppConstants.svcIcon(svc),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              svc,
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      color,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        AppConstants.svcBg(svc),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$waiting waiting',
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color:      color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // No windows open
        if (windows.isEmpty)
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppConstants.borderGray),
            ),
            child: const Center(
              child: Text(
                'No windows open right now',
                style: TextStyle(
                  fontSize: 13,
                  color:    AppConstants.textMuted,
                ),
              ),
            ),
          )
        else ...[
          // Window cards
          ...windows.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _WindowCard(
              window:  w,
              ticket:  queue.servingAt(w.windowId),
            ),
          )),

          // Next up waiting queue (shared across all windows of this service)
          if (nextUp.isNotEmpty) ...[
            const SizedBox(height: 6),
            _NextUpBar(nextUp: nextUp, color: color),
          ],
        ],
      ],
    );
  }
}

// ── Window card — shows now serving ──────────────────────────
class _WindowCard extends StatelessWidget {
  final WindowModel  window;
  final TicketModel? ticket;

  const _WindowCard({required this.window, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color  = AppConstants.svcColor(window.serviceType);
    final hasNum = ticket != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasNum
            ? AppConstants.svcBg(window.serviceType)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasNum
              ? color.withOpacity(0.35)
              : AppConstants.borderGray,
          width: hasNum ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Window info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.window_outlined,
                      size:  14,
                      color: hasNum ? color : AppConstants.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      window.windowName,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color: hasNum
                            ? AppConstants.textPrimary
                            : AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  window.staffName ?? 'Staff',
                  style: const TextStyle(
                    fontSize: 11,
                    color:    AppConstants.textMuted,
                  ),
                ),
                if (hasNum) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:        color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔔 Now serving',
                      style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        color:      color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Ticket number or Ready
          if (hasNum)
            Text(
              ticket!.ticketNumber,
              style: TextStyle(
                fontSize:   28,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color:      color,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ready',
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color:      AppConstants.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Next up bar — shows next 3 waiting tickets ───────────────
class _NextUpBar extends StatelessWidget {
  final List<TicketModel> nextUp;
  final Color             color;

  const _NextUpBar({required this.nextUp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppConstants.borderGray),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_outlined,
            size:  14,
            color: AppConstants.textMuted,
          ),
          const SizedBox(width: 6),
          const Text(
            'Next up:',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      AppConstants.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: nextUp.map((t) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(
                    color: color.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  t.ticketNumber,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color:      color,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
