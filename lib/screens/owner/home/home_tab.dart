import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/notification_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/member_model.dart';
import 'business_analytics_screen.dart';
import 'add_member_screen.dart';
import 'qr_screen.dart';
import 'owner_profile_screen.dart';

class HomeTab extends StatefulWidget {
  final String gymId;
  final String ownerName;
  const HomeTab({super.key, required this.gymId, required this.ownerName});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _firestoreService = FirestoreService();
  final _announcementCtrl = TextEditingController();
  bool _sendingAnnouncement = false;
  String? _gymName;

  @override
  void initState() {
    super.initState();
    _runNotificationChecks();
    _loadGymName();
  }

  Future<void> _runNotificationChecks() async {
    final svc = NotificationService.instance;
    await svc.initAndGreet(widget.ownerName, isOwner: true);
    await svc.checkRenewalAlerts(widget.gymId);
    await svc.checkRetentionAlerts(widget.gymId);
    await svc.checkLeaderboardChange(widget.gymId);
  }

  Future<void> _loadGymName() async {
    final gym = await _firestoreService.getGym(widget.gymId);
    if (mounted) setState(() => _gymName = gym?['gymName'] ?? 'My Gym');
  }

  @override
  void dispose() {
    _announcementCtrl.dispose();
    super.dispose();
  }



  Future<void> _sendAnnouncement() async {
    final msg = _announcementCtrl.text.trim();
    if (msg.isEmpty) return;
    if (widget.gymId.isEmpty) return;
    setState(() => _sendingAnnouncement = true);
    try {
      await _firestoreService.sendAnnouncement(widget.gymId, msg, widget.ownerName);
      _announcementCtrl.clear();
      if (mounted) {
        setState(() => _sendingAnnouncement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent to all members!'),
            backgroundColor: AppTheme.kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingAnnouncement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    if (widget.gymId.isEmpty) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            StreamBuilder<List<MemberModel>>(
              stream: _firestoreService.membersStream(widget.gymId),
              builder: (context, snap) {
                final members = snap.data ?? [];
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildKpiRow(members),
                      const SizedBox(height: 20),
                      _buildHeroAnalyticsCard(),
                      const SizedBox(height: 16),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 16),
                      _buildAnnouncementCard(),
                      const SizedBox(height: 16),
                      _buildPrizeCard(),
                      const SizedBox(height: 16),
                      _buildPendingRenewals(members),
                      const SizedBox(height: 16),
                      _buildAchievementsAndTop(members),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final c = GFColors(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          // Logo + gym name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.kAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppTheme.kAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _gymName ?? 'My Gym',
                  style: GoogleFonts.inter(
                    color: c.text1,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: c.text2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.notifications_none_outlined,
                  color: c.text2, size: 20),
            ),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OwnerProfileScreen(
                    gymId: widget.gymId, ownerName: widget.ownerName))),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.4)),
              ),
              child: Center(child: Text(
                widget.ownerName.isNotEmpty ? widget.ownerName[0].toUpperCase() : 'O',
                style: const TextStyle(
                    color: AppTheme.kAccent, fontWeight: FontWeight.w800, fontSize: 16),
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Row ───────────────────────────────────────────────────────────────

  // ── Prize Card ─────────────────────────────────────────────────────────────
  Widget _buildPrizeCard() {
    final c = GFColors(context);
    return GFCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppTheme.kGoldLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.emoji_events_rounded,
                  color: AppTheme.kGold, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly Prize', style: TextStyle(
                color: c.text1, fontWeight: FontWeight.w700, fontSize: 15)),
            Text('Award for the #1 ranked member',
                style: TextStyle(color: c.text2, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 14),
        StreamBuilder<String?>(
          stream: _firestoreService.prizeStream(widget.gymId),
          builder: (context, snap) {
            final current = snap.data;
            if (current != null && current.isNotEmpty) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.kGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.kGold.withValues(alpha: 0.3))),
                    child: Text('🏆 $current',
                        style: const TextStyle(color: AppTheme.kGold,
                            fontWeight: FontWeight.w700, fontSize: 14))),
                const SizedBox(height: 10),
                GestureDetector(
                    onTap: () => _showPrizeDialog(context),
                    child: Text('Change prize',
                        style: TextStyle(color: c.text2,
                            fontSize: 12, decoration: TextDecoration.underline))),
              ]);
            }
            return SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showPrizeDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Set Monthly Prize'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            );
          },
        ),
      ]),
    );
  }

  void _showPrizeDialog(BuildContext context) {
    final c = GFColors(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Monthly Prize',
            style: TextStyle(color: c.text1)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: c.text1),
          decoration: const InputDecoration(
              hintText: 'e.g. Free 1-month membership!',
              labelText: 'Prize Description'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: c.text2))),
          ElevatedButton(
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  await _firestoreService.setPrize(widget.gymId, text);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kGold,
                  foregroundColor: Colors.black),
              child: const Text('Set Prize')),
        ],
      ),
    );
  }

  Widget _buildKpiRow(List<MemberModel> members) {
    final active = members.where((m) => m.isActive).length;
    return Row(
      children: [
        Expanded(
          child: _KpiChip(
            label: 'Active Members',
            value: '$active',
            icon: Icons.people_alt_rounded,
            color: AppTheme.kPrimary,
            bgColor: AppTheme.kPrimaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<int>(
            stream: _firestoreService.todayAttendanceStream(widget.gymId),
            builder: (ctx, snap) => _KpiChip(
              label: "Today's Check-ins",
              value: '${snap.data ?? 0}',
              icon: Icons.login_rounded,
              color: AppTheme.kAccent,
              bgColor: AppTheme.kGreenLight,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Analytics Card ───────────────────────────────────────────────────
  Widget _buildHeroAnalyticsCard() {
    return GFGradientCard(
      colors: const [AppTheme.kPrimary, Color(0xFF7C75F0)],
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BusinessAnalyticsScreen(gymId: widget.gymId),
        ));
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Business Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'View Revenue,\nMembership & More',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Open Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.pie_chart_rounded,
                color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            label: 'Add Member',
            subtitle: 'Enrol new member',
            icon: Icons.person_add_rounded,
            color: AppTheme.kAccent,
            bgColor: AppTheme.kAccentLight,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddMemberScreen(gymId: widget.gymId),
              ));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            label: 'Check-in QR',
            subtitle: 'Display for members',
            icon: Icons.qr_code_2_rounded,
            color: AppTheme.kPrimary,
            bgColor: AppTheme.kPrimaryLight,
            onTap: () async {
              final gym = await _firestoreService.getGym(widget.gymId);
              if (mounted) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QRScreen(
                    gymId: widget.gymId,
                    gymName: gym?['gymName'] ?? _gymName ?? 'My Gym',
                  ),
                ));
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.recentAchievementsStream(widget.gymId),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return _QuickActionCard(
                label: 'Achievements',
                subtitle: count > 0 ? '$count milestones' : 'No new yet',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.kGold,
                bgColor: AppTheme.kGoldLight,
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Announcement Card ─────────────────────────────────────────────────────
  Widget _buildAnnouncementCard() {
    final c = GFColors(context);
    return GFCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.kAccentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: AppTheme.kAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Announcement',
                    style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Notify all members instantly',
                    style: TextStyle(
                      color: c.text2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _announcementCtrl,
            maxLines: 3,
            style: TextStyle(
                color: c.text1, fontSize: 14, height: 1.5),
            decoration: const InputDecoration(
              hintText:
              'e.g. "Gym will be closed on Sunday for maintenance…"',
              hintMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sendingAnnouncement ? null : _sendAnnouncement,
              icon: _sendingAnnouncement
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_sendingAnnouncement ? 'Sending…' : 'Send to All Members'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRenewals(List<MemberModel> members) {
    final c = GFColors(context);
    final renewals = members
        .where((m) => m.isActive && m.isRenewalSoon)
        .toList()
      ..sort((a, b) => a.daysUntilRenewal.compareTo(b.daysUntilRenewal));

    return GFCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: renewals.isEmpty
                          ? AppTheme.kGreenLight
                          : AppTheme.kGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      renewals.isEmpty
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: renewals.isEmpty
                          ? AppTheme.kGreen
                          : AppTheme.kGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pending Renewals',
                    style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (renewals.isNotEmpty)
                GFBadge(
                  label: '${renewals.length} due',
                  bgColor: AppTheme.kGoldLight,
                  textColor: AppTheme.kGold,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (renewals.isEmpty)
            Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  'All memberships up to date  🎉',
                  style: TextStyle(
                      color: c.text2, fontSize: 13),
                ),
              ],
            )
          else
            ...renewals.take(5).map((m) => _RenewalRow(member: m)),
        ],
      ),
    );
  }

  // ── Achievements + Top Performers ─────────────────────────────────────────
  Widget _buildAchievementsAndTop(List<MemberModel> members) {
    final c = GFColors(context);
    final top3 = List<MemberModel>.from(members)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final topList = top3.take(3).toList();

    return Column(
      children: [
        // Recent Achievements
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.recentAchievementsStream(widget.gymId),
          builder: (context, snap) {
            final items = snap.data ?? [];
            return GFCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.kGoldLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: AppTheme.kGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recent Achievements',
                        style: TextStyle(
                          color: c.text1,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Text(
                      'Member milestones will appear here.',
                      style: TextStyle(
                          color: c.text2, fontSize: 13),
                    )
                  else
                    ...items.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏅',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a['message'] ?? '',
                              style: TextStyle(
                                color: c.text2,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Top 3 Performers
        GFCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.military_tech_rounded,
                        color: AppTheme.kPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Top 3 Performers',
                    style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (topList.isEmpty)
                Text(
                  'Start adding members to see top performers.',
                  style: TextStyle(
                      color: c.text2, fontSize: 13),
                )
              else
                ...topList.asMap().entries.map(
                      (e) => _TopRow(rank: e.key + 1, member: e.value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── KPI Chip ─────────────────────────────────────────────────────────────────
class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: c.text1,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: c.text2,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: c.text1,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: c.text2,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Renewal Row ───────────────────────────────────────────────────────────────
class _RenewalRow extends StatelessWidget {
  final MemberModel member;
  const _RenewalRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final days = member.daysUntilRenewal;
    final isUrgent = days <= 2;
    final color = isUrgent ? AppTheme.kRed : AppTheme.kGold;
    final bgColor = isUrgent ? AppTheme.kRedLight : AppTheme.kGoldLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              member.initials,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${member.planType} · ID: ${member.memberId}',
                  style: TextStyle(
                      color: c.text2, fontSize: 11),
                ),
              ],
            ),
          ),
          GFBadge(
            label: days == 0
                ? 'TODAY'
                : days == 1
                ? '1 day'
                : '$days days',
            bgColor: color.withValues(alpha: 0.15),
            textColor: color,
          ),
        ],
      ),
    );
  }
}

// ── Top Performer Row ─────────────────────────────────────────────────────────
class _TopRow extends StatelessWidget {
  final int rank;
  final MemberModel member;
  const _TopRow({required this.rank, required this.member});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [AppTheme.kGold, c.text2, const Color(0xFFCD7F32)];
    final bgColors = [AppTheme.kGoldLight, const Color(0xFFF3F4F6), const Color(0xFFFDF6EE)];
    final color = colors[rank - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColors[rank - 1],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              member.initials,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${member.currentStreak} day streak · ${member.totalAttendance} visits',
                  style: TextStyle(
                      color: c.text2, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.totalPoints}',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('pts',
                  style: TextStyle(
                      color: c.text2, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}