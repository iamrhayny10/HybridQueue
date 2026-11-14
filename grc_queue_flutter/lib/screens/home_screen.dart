// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import 'ticket_screen.dart';
import 'profile_screen.dart';
import 'live_queue_screen.dart';
import 'service_request_screen.dart';
import 'pwd_priority_screen.dart';
import '../services/pwd_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int    _tab        = 0;
  String _selectedSvc = '';

  @override
  void initState() {
    super.initState();
    // Always (re)initialize notifications here too — not just after a
    // fresh login — so the Android 13+ permission prompt and channel
    // setup also run for restored sessions (app reopened while already
    // logged in), which bypass the login screen entirely.
    NotificationService.init();
    final auth  = context.read<AuthService>();
    final queue = context.read<QueueService>();
    queue.restoreTicket(auth.user!.userId);
    queue.startPolling(auth.user!.userId);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: isError ? AppConstants.dangerRed : null,
    ));
  }

  Future<void> _joinQueue() async {
    if (_selectedSvc.isEmpty) {
      _snack('Please select a service type.');
      return;
    }

    // Location check — only runs when skipLocationCheck = false
    if (!AppConstants.skipLocationCheck) {
      if (!mounted) return;
      _snack('Checking your location…');
      final locationError = await LocationService.checkWithinSchool();
      if (!mounted) return;
      if (locationError != null) {
        _snack(locationError, isError: true);
        return;
      }
    }

    final auth  = context.read<AuthService>();
    final queue = context.read<QueueService>();
    final err   = await queue.joinQueue(
      userId:      auth.user!.userId,
      serviceType: _selectedSvc,
    );
    if (!mounted) return;
    if (err != null) {
      _snack(err, isError: true);
    } else {
      setState(() => _tab = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthService>();
    final queue = context.watch<QueueService>();
    final user  = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.firstName}',
              style: const TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'GRC Registrar Queue',
              style: TextStyle(
                fontSize: 12,
                color:    AppConstants.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius:          18,
                backgroundColor: AppConstants.lightBlue,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      AppConstants.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildHomeTab(queue),
          const LiveQueueScreen(),
          const TicketScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 2 && queue.myTicket == null) {
            _snack('Get a ticket first.');
            return;
          }
          setState(() => _tab = i);
          // Immediately refresh data when switching tabs
          final auth = context.read<AuthService>();
          queue.fetchWaitingQueue();
          queue.fetchLiveQueueData();
          if (queue.myTicket != null) {
            queue.restoreTicket(auth.user!.userId);
          }
        },
        backgroundColor:  Colors.white,
        elevation:        0,
        indicatorColor:   AppConstants.lightBlue,
        destinations: [
          const NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label:        'Home',
          ),
          const NavigationDestination(
            icon:         Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label:        'Live queue',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible:
                  queue.myTicket?.status == TicketStatus.serving,
              label: const Text('!'),
              child: const Icon(Icons.confirmation_number_outlined),
            ),
            selectedIcon: const Icon(Icons.confirmation_number),
            label:        'My ticket',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(QueueService queue) {
    return RefreshIndicator(
      onRefresh: queue.fetchWaitingQueue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Active ticket banner
            if (queue.myTicket != null && queue.myTicket!.isActive) ...[
              _ActiveBanner(
                ticket: queue.myTicket!,
                onTap:  () => setState(() => _tab = 2),
              ),
              const SizedBox(height: 20),
            ],

            // PWD Priority Lane
            const _PwdCard(),
            const SizedBox(height: 20),

            // Queue summary per service
            const Text(
              'Queue summary',
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...AppConstants.serviceTypes.map((svc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SvcSummaryRow(
                svc:     svc,
                waiting: queue.waitingForService(svc),
                avgErt:  queue.avgErtForService(svc),
              ),
            )),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            // Join queue — service cards
            const Text(
              'Select a service to get a queue ticket',
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap your service below to fill out the request form.',
              style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
            ),
            const SizedBox(height: 14),

            // Service cards
            ...['Registrar', 'Cashier', 'OSA'].map((svc) {
              final colors = {
                'Registrar': const Color(0xFF1A56DB),
                'Cashier':   const Color(0xFF059669),
                'OSA':       const Color(0xFF7C3AED),
              };
              final icons = {
                'Registrar': '🎓',
                'Cashier':   '💳',
                'OSA':       '🤝',
              };
              final descs = {
                'Registrar': 'Enrollment, grades, certificates',
                'Cashier':   'Payments, fees, purchases',
                'OSA':       'Student affairs, scholarships',
              };
              final color = colors[svc]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color:        color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ServiceRequestScreen(serviceType: svc),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() => _tab = 2);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Text(icons[svc]!,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(svc,
                                    style: TextStyle(
                                      fontSize:   15,
                                      fontWeight: FontWeight.w700,
                                      color:      color,
                                    )),
                                Text(descs[svc]!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color:    AppConstants.textMuted,
                                    )),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: color),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

                        const SizedBox(height: 28),
            const Text(
              'Available services',
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...AppConstants.serviceTypes.map((svc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width:  44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:        AppConstants.svcBg(svc),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            AppConstants.svcIcon(svc),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              svc,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:   14,
                                color:      AppConstants.svcColor(svc),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppConstants.svcDesc(svc),
                              style: const TextStyle(
                                fontSize: 12,
                                color:    AppConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ── Queue summary row ─────────────────────────────────────────
class _SvcSummaryRow extends StatelessWidget {
  final String svc;
  final int    waiting;
  final String avgErt;
  const _SvcSummaryRow({
    required this.svc,
    required this.waiting,
    required this.avgErt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppConstants.borderGray),
      ),
      child: Row(
        children: [
          Text(AppConstants.svcIcon(svc),
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              svc,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   14,
                color:      AppConstants.svcColor(svc),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$waiting waiting',
                style: const TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppConstants.textPrimary,
                ),
              ),
              Text(
                'avg $avgErt',
                style: const TextStyle(
                  fontSize: 11,
                  color:    AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active ticket banner ──────────────────────────────────────
class _ActiveBanner extends StatelessWidget {
  final TicketModel  ticket;
  final VoidCallback onTap;
  const _ActiveBanner({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final serving = ticket.status == TicketStatus.serving;
    final color   = AppConstants.svcColor(ticket.serviceType);
    final bg      = serving
        ? AppConstants.successBg
        : AppConstants.svcBg(ticket.serviceType);
    final border  = serving
        ? const Color(0xFF86EFAC)
        : color.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: border),
        ),
        child: Row(
          children: [
            Text(
              serving ? '▶' : AppConstants.svcIcon(ticket.serviceType),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serving
                        ? 'Your turn is now!'
                        : 'Active: ${ticket.ticketNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                      color:      serving
                          ? AppConstants.successGreen
                          : color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ticket.serviceType} · ${ticket.statusLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      color:    serving
                          ? AppConstants.successGreen
                          : color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size:  14,
              color: serving ? AppConstants.successGreen : color,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PWD Priority Lane card ────────────────────────────────────
class _PwdCard extends StatefulWidget {
  const _PwdCard();

  @override
  State<_PwdCard> createState() => _PwdCardState();
}

class _PwdCardState extends State<_PwdCard> {
  PwdInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().user?.token ?? '';
    final info  = await PwdService.fetchStatus(token);
    if (mounted) setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final s = _info?.status ?? 'none';
    Color  bg     = AppConstants.lightBlue;
    Color  fg     = AppConstants.darkBlue;
    String title  = 'PWD Priority Lane';
    String sub    = 'Are you a Person with Disability? Apply for priority service.';
    IconData icon = Icons.accessible_forward;

    if (s == 'verified') {
      bg = AppConstants.successBg; fg = AppConstants.successGreen;
      title = 'Priority Lane active';
      sub   = 'You will be served first. Turn it on when you get a ticket.';
      icon  = Icons.verified;
    } else if (s == 'pending') {
      bg = const Color(0xFFFEF3C7); fg = const Color(0xFFB45309);
      title = 'PWD verification pending';
      sub   = 'Your PWD ID is waiting for review.';
      icon  = Icons.hourglass_top;
    } else if (s == 'rejected') {
      bg = AppConstants.dangerBg; fg = AppConstants.dangerRed;
      title = 'PWD verification not approved';
      sub   = 'Tap to see the reason and submit again.';
      icon  = Icons.error_outline;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PwdPriorityScreen()),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: fg)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: fg),
          ],
        ),
      ),
    );
  }
}
