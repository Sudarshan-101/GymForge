import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_theme.dart';
import '../../../services/notification_service.dart';
import '../../../services/member_service.dart';
import '../../../models/daily_stats_model.dart';
import '../../../models/member_model.dart';
import '../../../models/quiz_model.dart';
import '../../../widgets/member_avatar.dart';
import '../qr_scanner_screen.dart';
import '../profile_screen.dart';

class MemberHomeTab extends StatefulWidget {
  final MemberSession session;
  const MemberHomeTab({super.key, required this.session});
  @override
  State<MemberHomeTab> createState() => _MemberHomeTabState();
}

class _MemberHomeTabState extends State<MemberHomeTab> with WidgetsBindingObserver {
  final _service = MemberService();
  StreamSubscription? _prizeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _runMemberNotifications();
    _prizeSub = _service.prizeStream(widget.session.gymId).listen((_) {});
  }

  Future<void> _runMemberNotifications() async {
    final svc = NotificationService.instance;
    await svc.initAndGreet(widget.session.name, isOwner: false);
    await svc.checkMembershipExpiry(
        widget.session.gymId, widget.session.memberId);
    await svc.checkCompetitionAlerts(
        widget.session.gymId, widget.session.memberId, widget.session.name);
    try {
      final snap = await _service.getLatestAnnouncement(widget.session.gymId);
      if (snap != null) {
        final prefs = await SharedPreferences.getInstance();
        final lastId = prefs.getString('last_announce_shown') ?? '';
        final id = snap['id'] as String? ?? '';
        if (id.isNotEmpty && id != lastId) {
          await prefs.setString('last_announce_shown', id);
          await svc.notifyAnnouncement(
              snap['message'] ?? '', snap['sentBy'] ?? 'Gym');
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prizeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!kIsWeb) SystemNavigator.pop();
      },
      child: StreamBuilder<DailyStats>(
        stream: _service.todayStatsStream(
            widget.session.gymId, widget.session.memberId),
        builder: (_, sSnap) {
          final stats = sSnap.data ?? const DailyStats(date: '');
          return StreamBuilder<MemberModel?>(
            stream: _service.memberStream(
                widget.session.gymId, widget.session.memberId),
            builder: (_, mSnap) => _body(stats, mSnap.data),
          );
        },
      ),
    );
  }

  Widget _body(DailyStats stats, MemberModel? member) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                member: member,
                session: widget.session,
                isDark: c.isDark,
                onProfileTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            MemberProfileScreen(session: widget.session))),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Membership Status Card ────────────────────────
                  _MembershipStatusCard(member: member, isDark: c.isDark),
                  const SizedBox(height: 16),

                  // ── Level + XP card ───────────────────────────────
                  _LevelCard(member: member, isDark: c.isDark),
                  const SizedBox(height: 16),

                  // ── Streak card ───────────────────────────────────
                  _StreakCard(
                    member: member,
                    checkedIn: stats.checkedIn,
                    isDark: c.isDark,
                  ),
                  const SizedBox(height: 16),

                  // ── Check-in button ───────────────────────────────
                  _CheckinButton(
                    checkedIn: stats.checkedIn,
                    streak: member?.currentStreak ?? 0,
                    onTap: stats.checkedIn
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                QRScannerScreen(session: widget.session))),
                  ),
                  const SizedBox(height: 16),

                  // ── Daily Quiz ────────────────────────────────────
                  DailyQuizCard(
                    gymId: widget.session.gymId,
                    memberId: widget.session.memberId,
                    isDark: c.isDark,
                  ),
                  const SizedBox(height: 16),

                  // ── Announcements ─────────────────────────────────
                  _AnnouncementsSection(
                      gymId: widget.session.gymId, isDark: c.isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STICKY HEADER
// ════════════════════════════════════════════════════════════════════════════

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final MemberModel? member;
  final MemberSession session;
  final bool isDark;
  final VoidCallback onProfileTap;

  const _HeaderDelegate({
    required this.member,
    required this.session,
    required this.isDark,
    required this.onProfileTap,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = GFColors(context);
    final h = DateTime.now().hour;
    final greet = h < 12
        ? 'Morning'
        : h < 17
            ? 'Afternoon'
            : 'Evening';

    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
      child: Row(children: [
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good $greet', style: TextStyle(color: c.text3, fontSize: 12)),
            Text(session.name,
                style: GoogleFonts.inter(
                    color: c.text1, fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        )),
        if (member != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.kAccent, size: 13),
              const SizedBox(width: 3),
              Text('${member!.totalPoints}',
                  style: const TextStyle(
                      color: AppTheme.kAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        GestureDetector(
          onTap: onProfileTap,
          child: MemberAvatar(
            photoUrl: member?.photoUrl ?? '',
            initials: member?.initials ??
                (session.name.isNotEmpty ? session.name[0].toUpperCase() : 'M'),
            radius: 19,
            ringColor: AppTheme.kAccent,
          ),
        ),
      ]),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.member != member || old.isDark != isDark;
}

// ════════════════════════════════════════════════════════════════════════════
// MEMBERSHIP STATUS CARD
// ════════════════════════════════════════════════════════════════════════════

class _MembershipStatusCard extends StatelessWidget {
  final MemberModel? member;
  final bool isDark;
  const _MembershipStatusCard({required this.member, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final cardBg = isDark ? c.card : Colors.white;
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol = isDark ? c.text3 : const Color(0xFF9E9E9E);
    final isActive = member?.isActive ?? true;
    final daysLeft = member?.daysUntilRenewal ?? 0;
    final statusColor = isActive
        ? (daysLeft <= 7 ? const Color(0xFFFF7043) : AppTheme.kGreen)
        : AppTheme.kRed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 3))
              ],
      ),
      child: Row(children: [
        // Status icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: Icon(
              isActive ? Icons.verified_rounded : Icons.cancel_rounded,
              color: statusColor,
              size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(
              isActive
                  ? (daysLeft <= 7
                      ? 'Renews in $daysLeft days'
                      : 'Membership Active')
                  : 'Membership Inactive',
              style: GoogleFonts.inter(
                  color: textCol, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
              member != null
                  ? '${member!.planType} · ${member!.memberId}'
                  : 'Loading...',
              style: TextStyle(color: subCol, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LEVEL CARD
// ════════════════════════════════════════════════════════════════════════════

class _LevelCard extends StatelessWidget {
  final MemberModel? member;
  final bool isDark;
  const _LevelCard({required this.member, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final totalPts = member?.totalPoints ?? 0;
    final level = (totalPts / 500).floor() + 1;
    final xp = totalPts % 500;
    final xpPct = xp / 500;
    final cardBg = isDark ? c.card : Colors.white;
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol = isDark ? c.text3 : const Color(0xFF9E9E9E);
    final trackBg = isDark ? c.border : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3))
              ],
      ),
      child: Row(children: [
        // Level badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppTheme.kAccent, AppTheme.kAccent.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.kAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]),
          child: Center(
              child: Text('$level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Level $level',
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$xp / 500 XP', style: TextStyle(color: subCol, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpPct,
              minHeight: 6,
              backgroundColor: trackBg,
              valueColor: const AlwaysStoppedAnimation(AppTheme.kAccent),
            ),
          ),
          const SizedBox(height: 5),
          Text('${(500 - xp)} XP to level ${level + 1}',
              style: TextStyle(color: subCol, fontSize: 10)),
        ])),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STREAK CARD
// ════════════════════════════════════════════════════════════════════════════

class _StreakCard extends StatelessWidget {
  final MemberModel? member;
  final bool checkedIn;
  final bool isDark;
  const _StreakCard(
      {required this.member, required this.checkedIn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final streak = member?.currentStreak ?? 0;
    final visits = member?.totalAttendance ?? 0;
    final cardBg = isDark ? c.card : Colors.white;
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol = isDark ? c.text3 : const Color(0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3))
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF7043),
            value: '$streak',
            label: 'Day Streak',
            textCol: textCol,
            subCol: subCol,
          ),
          Container(width: 1, height: 40, color: c.border),
          _StatItem(
            icon: Icons.fitness_center_rounded,
            iconColor: AppTheme.kAccent,
            value: '$visits',
            label: 'Total Visits',
            textCol: textCol,
            subCol: subCol,
          ),
          Container(width: 1, height: 40, color: c.border),
          _StatItem(
            icon: checkedIn
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            iconColor: checkedIn ? AppTheme.kGreen : subCol,
            value: checkedIn ? '✓' : '–',
            label: 'Today',
            textCol: checkedIn ? AppTheme.kGreen : textCol,
            subCol: subCol,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color textCol;
  final Color subCol;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.textCol,
    required this.subCol,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  color: textCol, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: subCol, fontSize: 10, letterSpacing: 0.2)),
        ],
      );
}

// ════════════════════════════════════════════════════════════════════════════
// CHECK-IN BUTTON
// ════════════════════════════════════════════════════════════════════════════

class _CheckinButton extends StatelessWidget {
  final bool checkedIn;
  final int streak;
  final VoidCallback? onTap;
  const _CheckinButton(
      {required this.checkedIn, required this.streak, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final isDark = c.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: checkedIn ? (isDark ? c.card : Colors.white) : AppTheme.kAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: checkedIn
              ? null
              : [
                  BoxShadow(
                      color: AppTheme.kAccent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: checkedIn
                    ? AppTheme.kAccentDim
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: Icon(
                checkedIn
                    ? Icons.check_circle_rounded
                    : Icons.qr_code_scanner_rounded,
                color: checkedIn ? AppTheme.kAccent : Colors.white,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  checkedIn ? 'Checked In Today' : 'Check In to Gym',
                  style: GoogleFonts.inter(
                      color: checkedIn ? c.text1 : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  checkedIn
                      ? (streak > 1
                          ? '$streak day streak  🔥'
                          : 'Great work today!')
                      : 'Scan QR code at the entrance',
                  style: TextStyle(
                      color: checkedIn
                          ? c.text1.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 12),
                ),
              ])),
          if (!checkedIn)
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          if (checkedIn && streak > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$streak 🔥',
                  style: const TextStyle(
                      color: Color(0xFFFF7043),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ANNOUNCEMENTS
// ════════════════════════════════════════════════════════════════════════════

class _AnnouncementsSection extends StatelessWidget {
  final String gymId;
  final bool isDark;
  const _AnnouncementsSection({required this.gymId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final service = MemberService();
    final cardBg = isDark ? c.card : Colors.white;
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol = isDark ? c.text3 : const Color(0xFF9E9E9E);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.announcementsStream(gymId),
      builder: (_, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Announcements',
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.kAccentDim,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${items.length} new',
                  style: const TextStyle(
                      color: AppTheme.kAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          ...items.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDark
                        ? AppTheme.cardShadow
                        : const [
                            BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                  ),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: AppTheme.kAccentDim,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.campaign_rounded,
                              color: AppTheme.kAccent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(a['message'] ?? '',
                                  style: TextStyle(
                                      color: textCol,
                                      fontSize: 13,
                                      height: 1.4)),
                              const SizedBox(height: 3),
                              Text('by ${a['sentBy'] ?? 'Gym'}',
                                  style: TextStyle(color: subCol, fontSize: 11)),
                            ])),
                      ]),
                ),
              )),
        ]);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DAILY QUIZ CARD
// ═══════════════════════════════════════════════════════════════════════════

class DailyQuizCard extends StatefulWidget {
  final String gymId;
  final String memberId;
  final bool isDark;
  const DailyQuizCard(
      {super.key,
      required this.gymId,
      required this.memberId,
      required this.isDark});
  @override
  State<DailyQuizCard> createState() => _DailyQuizCardState();
}

class _DailyQuizCardState extends State<DailyQuizCard>
    with SingleTickerProviderStateMixin {
  final _service = MemberService();

  QuizQuestion get _q => todayQuestion;
  int? _selected;
  bool _answered = false;
  bool _loading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
    _checkAlreadyAnswered();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyAnswered() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'quiz_${widget.memberId}_$today';
    final saved = prefs.getInt(key);
    if (saved != null && mounted) {
      setState(() {
        _selected = saved;
        _answered = true;
      });
    }
  }

  Future<void> _submit(int idx) async {
    if (_answered || _loading) return;
    setState(() {
      _selected = idx;
      _loading = true;
    });

    final correct = idx == _q.correctIndex;
    final pts = correct ? 10 : 5;

    try {
      await _service.addPoints(widget.gymId, widget.memberId, pts);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('quiz_${widget.memberId}_$today', idx);

    if (!correct) _shakeCtrl.forward(from: 0);

    if (mounted) {
      setState(() {
        _answered = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppTheme.kCard : Colors.white;
    final textCol =
        widget.isDark ? AppTheme.kTextPrimary : const Color(0xFF212121);
    final subCol =
        widget.isDark ? AppTheme.kTextSecondary : const Color(0xFF757575);
    final divCol =
        widget.isDark ? AppTheme.kCardBorder : const Color(0xFFEEEEEE);

    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            _answered && _selected != _q.correctIndex
                ? 6 * (0.5 - _shake.value).abs()
                : 0,
            0),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isDark
              ? AppTheme.cardShadow
              : const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.kAccent, AppTheme.kAccent.withValues(alpha: 0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Text('🧠', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Quiz',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      Text(
                        _q.isTrueFalse ? 'True or False' : 'Pick the right answer',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!_answered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('⚡ +10 pts',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                if (_answered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _selected == _q.correctIndex ? '✓ +10' : '✓ +5',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(_q.question,
                  style: TextStyle(
                      color: textCol,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4)),
            ),
            Divider(height: 1, color: divCol),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: _q.isTrueFalse
                  ? Row(children: [
                      Expanded(
                          child: _OptionTile(
                              label: 'True',
                              index: 0,
                              q: _q,
                              selected: _selected,
                              answered: _answered,
                              onTap: () => _submit(0),
                              isDark: widget.isDark,
                              loading: _loading)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _OptionTile(
                              label: 'False',
                              index: 1,
                              q: _q,
                              selected: _selected,
                              answered: _answered,
                              onTap: () => _submit(1),
                              isDark: widget.isDark,
                              loading: _loading)),
                    ])
                  : Column(
                      children: List.generate(
                          _q.options.length,
                          (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _OptionTile(
                                  label: _q.options[i],
                                  index: i,
                                  q: _q,
                                  selected: _selected,
                                  answered: _answered,
                                  onTap: () => _submit(i),
                                  isDark: widget.isDark,
                                  loading: _loading,
                                ),
                              )),
                    ),
            ),
            if (_answered)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_selected == _q.correctIndex
                          ? AppTheme.kGreen
                          : AppTheme.kRed)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_selected == _q.correctIndex
                            ? AppTheme.kGreen
                            : AppTheme.kRed)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected == _q.correctIndex
                          ? '🎉 Correct! +10 points'
                          : '💡 Not quite — +5 points for trying!',
                      style: TextStyle(
                        color: _selected == _q.correctIndex
                            ? AppTheme.kGreen
                            : AppTheme.kRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_q.explanation,
                        style: TextStyle(
                            color: subCol, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            if (_answered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Come back tomorrow for a new question!',
                    style: TextStyle(color: subCol, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final QuizQuestion q;
  final int? selected;
  final bool answered;
  final bool loading;
  final VoidCallback onTap;
  final bool isDark;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.q,
    required this.selected,
    required this.answered,
    required this.loading,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == index;
    final bool isCorrect = answered && index == q.correctIndex;
    final bool isWrong = answered && isSelected && index != q.correctIndex;

    Color borderColor;
    Color bgColor;
    Color textColor;

    if (isCorrect) {
      borderColor = AppTheme.kGreen;
      bgColor = AppTheme.kGreen.withValues(alpha: 0.12);
      textColor = AppTheme.kGreen;
    } else if (isWrong) {
      borderColor = AppTheme.kRed;
      bgColor = AppTheme.kRed.withValues(alpha: 0.1);
      textColor = AppTheme.kRed;
    } else if (isSelected && !answered) {
      borderColor = AppTheme.kAccent;
      bgColor = AppTheme.kAccentDim;
      textColor = AppTheme.kAccent;
    } else {
      borderColor = isDark ? AppTheme.kCardBorder : const Color(0xFFE0E0E0);
      bgColor = isDark ? AppTheme.kCardElevated : const Color(0xFFF5F5F5);
      textColor = isDark ? AppTheme.kTextPrimary : const Color(0xFF212121);
    }

    final letters = ['A', 'B', 'C', 'D'];
    final letter = index < letters.length ? letters[index] : '';

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: borderColor, width: isCorrect || isWrong ? 1.5 : 1),
        ),
        child: Row(children: [
          if (!q.isTrueFalse) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(letter,
                    style: TextStyle(
                        color: borderColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
          ] else
            Text(index == 0 ? '✓ ' : '✗ ',
                style: TextStyle(
                    color: borderColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: isSelected || isCorrect
                        ? FontWeight.w700
                        : FontWeight.w500)),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.kGreen, size: 16),
          if (isWrong)
            const Icon(Icons.cancel_rounded, color: AppTheme.kRed, size: 16),
        ]),
      ),
    );
  }
}
