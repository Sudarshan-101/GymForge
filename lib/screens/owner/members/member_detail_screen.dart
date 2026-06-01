import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../services/member_service.dart';
import '../../../models/member_model.dart';
import '../../../models/daily_stats_model.dart';

class MemberDetailScreen extends StatefulWidget {
  final MemberModel member;
  final String gymId;
  const MemberDetailScreen({super.key, required this.member, required this.gymId});
  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _memberService    = MemberService();
  late TabController _tabs;

  bool _toggling  = false;
  bool _renewing  = false;
  bool _loadingHistory = true;
  List<DailyStats> _history = [];
  int _rank = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    final results = await Future.wait([
      _memberService.getMemberHistory(widget.gymId, widget.member.memberId, days: 30),
      _memberService.getMemberRank(widget.gymId, widget.member.memberId),
    ]);
    if (mounted) {
      setState(() {
      _history = results[0] as List<DailyStats>;
      _rank    = results[1] as int;
      _loadingHistory = false;
    });
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _toggling = true);
    await _firestoreService.toggleMemberStatus(
        widget.gymId, widget.member.id, !widget.member.isActive);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.member.isActive
            ? '${widget.member.name} deactivated'
            : '${widget.member.name} activated'),
        backgroundColor: widget.member.isActive ? AppTheme.kRed : AppTheme.kAccent,
      ));
    }
  }

  Future<void> _renewMembership() async {
    final m = widget.member;
    final durationLabel = m.planType == 'Annual' ? '12 months'
        : m.planType == 'Quarterly' ? '3 months' : '1 month';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
      final c = GFColors(ctx);
      return AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Renew Membership',
            style: TextStyle(color: c.text1, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DialogRow('Member', m.name),
          _DialogRow('Plan', '${m.planType} ($durationLabel)'),
          if (m.planFee > 0) _DialogRow('Fee', m.feeLabel, color: AppTheme.kAccent),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.3))),
            child: Text(
              'Renewal extended by $durationLabel from ${m.paymentCycleDate.isBefore(DateTime.now()) ? "today" : "current date"}.',
              style: const TextStyle(color: AppTheme.kAccent, fontSize: 12, height: 1.5)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: c.text2))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('RENEW')),
        ],
      );
    },
    );
    if (confirm != true) return;
    setState(() => _renewing = true);
    try {
      await _firestoreService.renewMembership(widget.gymId, widget.member.id,
          widget.member.planType, widget.member.paymentCycleDate,
          planFee: widget.member.planFee, memberName: widget.member.name);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${widget.member.name}'s membership renewed!"),
          backgroundColor: AppTheme.kAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _renewing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Renewal failed: $e'), backgroundColor: AppTheme.kRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final m       = widget.member;
    final isDark  = c.isDark;
    final cardBg  = isDark ? c.card : Colors.white;
    final textCol = isDark ? c.text1   : const Color(0xFF212121);
    final subCol  = isDark ? c.text2 : const Color(0xFF757575);
    final divCol  = isDark ? c.border    : const Color(0xFFEEEEEE);
    final bgColor = c.bg;

    return Scaffold(
      backgroundColor: bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: c.surface,
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textCol),
              onPressed: () => Navigator.of(context).pop()),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppTheme.kAccent.withValues(alpha: 0.15),
                             isDark ? c.surface : Colors.white])),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 50),
                  // Avatar
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: (m.isActive ? AppTheme.kAccent : c.text3).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: m.isActive ? AppTheme.kAccent : c.text3, width: 2)),
                    child: Center(child: Text(m.initials,
                        style: TextStyle(
                            color: m.isActive ? AppTheme.kAccent : c.text3,
                            fontSize: 28, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(height: 10),
                  Text(m.name, style: GoogleFonts.inter(
                      color: textCol, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (m.isActive ? AppTheme.kGreen : c.text3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(m.isActive ? '● ACTIVE' : '● INACTIVE',
                          style: TextStyle(
                              color: m.isActive ? AppTheme.kGreen : c.text3,
                              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                    if (_rank > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(8)),
                        child: Text('RANK #$_rank',
                            style: const TextStyle(
                                color: AppTheme.kAccent, fontSize: 11,
                                fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ],
                  ]),
                ]),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppTheme.kAccent,
              labelColor: AppTheme.kAccent,
              unselectedLabelColor: subCol,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Actions'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            // ── Tab 1: Overview ──────────────────────────────────────
            _OverviewTab(m: m, history: _history, rank: _rank, isDark: isDark,
                cardBg: cardBg, textCol: textCol, subCol: subCol, divCol: divCol),

            // ── Tab 2: History ───────────────────────────────────────
            _HistoryTab(history: _history, loading: _loadingHistory,
                isDark: isDark, cardBg: cardBg, textCol: textCol, subCol: subCol),

            // ── Tab 3: Actions ───────────────────────────────────────
            _ActionsTab(m: m, isDark: isDark,
                onRenew: _renewMembership, onToggle: _toggleStatus,
                renewing: _renewing, toggling: _toggling),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1: OVERVIEW
// ═══════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final MemberModel m;
  final List<DailyStats> history;
  final int rank;
  final bool isDark;
  final Color cardBg, textCol, subCol, divCol;
  const _OverviewTab({required this.m, required this.history, required this.rank,
      required this.isDark, required this.cardBg, required this.textCol,
      required this.subCol, required this.divCol});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    // Compute averages from history
    final checkedDays   = history.where((d) => d.checkedIn).toList();
    final avgSteps      = history.isEmpty ? 0
        : (history.map((d) => d.steps).fold(0, (a, b) => a + b) / history.length).round();
    final avgWater      = history.isEmpty ? 0
        : (history.map((d) => d.waterMl).fold(0, (a, b) => a + b) / history.length).round();
    final daysLeft      = m.daysUntilRenewal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Quick stats ──────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9,
          children: [
            _QuickStat('Visits', '${m.totalAttendance}', Icons.fitness_center_rounded,
                AppTheme.kAccent, isDark),
            _QuickStat('Streak', '${m.currentStreak}d', Icons.local_fire_department_rounded,
                const Color(0xFFFF7043), isDark),
            _QuickStat('Points', '${m.totalPoints}', Icons.star_rounded,
                const Color(0xFFFFB300), isDark),
            _QuickStat('Rank', rank > 0 ? '#$rank' : '—', Icons.emoji_events_rounded,
                AppTheme.kAccent, isDark),
          ],
        ),
        const SizedBox(height: 16),

        // ── 30-day averages ──────────────────────────────────────────
        _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SecLabel('30-DAY AVERAGES', subCol),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _AvgTile('Avg Steps',
                NumberFormat('#,###').format(avgSteps), Icons.directions_walk_rounded,
                AppTheme.kAccent, textCol, subCol)),
            Container(width: 1, height: 50,
                color: isDark ? c.border : const Color(0xFFEEEEEE)),
            Expanded(child: _AvgTile('Avg Water',
                '${(avgWater / 1000).toStringAsFixed(1)} L', Icons.water_drop_rounded,
                const Color(0xFF29B6F6), textCol, subCol)),
            Container(width: 1, height: 50,
                color: isDark ? c.border : const Color(0xFFEEEEEE)),
            Expanded(child: _AvgTile('Check-ins',
                '${checkedDays.length} days', Icons.check_circle_outline_rounded,
                AppTheme.kGreen, textCol, subCol)),
          ]),
        ])),
        const SizedBox(height: 12),

        // ── Member info ──────────────────────────────────────────────
        _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SecLabel('MEMBER INFORMATION', subCol),
          const SizedBox(height: 14),
          _InfoRow(Icons.badge_outlined, 'Member ID', m.memberId, textCol, subCol,
              valueColor: AppTheme.kAccent),
          _Div(divCol),
          _InfoRow(Icons.email_outlined, 'Email', m.email, textCol, subCol),
          if (m.phone.isNotEmpty) ...[
            _Div(divCol),
            _InfoRow(Icons.phone_outlined, 'Phone', m.phone, textCol, subCol),
          ],
          _Div(divCol),
          _InfoRow(Icons.calendar_month_outlined, 'Joined',
              DateFormat('d MMM yyyy').format(m.joinDate), textCol, subCol),
          _Div(divCol),
          _InfoRow(Icons.access_time, 'Last Visit',
              m.lastVisit != null
                  ? DateFormat('d MMM yyyy, h:mm a').format(m.lastVisit!)
                  : 'Never visited',
              textCol, subCol,
              valueColor: m.isInactive && m.totalAttendance > 0 ? AppTheme.kRed : null),
        ])),
        const SizedBox(height: 12),

        // ── Membership ───────────────────────────────────────────────
        _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SecLabel('MEMBERSHIP', subCol),
          const SizedBox(height: 14),
          _InfoRow(Icons.card_membership_outlined, 'Plan', m.planType, textCol, subCol),
          _Div(divCol),
          _InfoRow(Icons.currency_rupee_rounded, 'Fee', m.feeLabel, textCol, subCol,
              valueColor: AppTheme.kAccent),
          _Div(divCol),
          _InfoRow(Icons.schedule, 'Next Renewal',
              DateFormat('d MMM yyyy').format(m.paymentCycleDate), textCol, subCol,
              trailing: daysLeft >= 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: (m.isRenewalSoon ? AppTheme.kGold : AppTheme.kGreen).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(daysLeft == 0 ? 'TODAY' : '$daysLeft days',
                          style: TextStyle(
                              color: m.isRenewalSoon ? AppTheme.kGold : AppTheme.kGreen,
                              fontSize: 11, fontWeight: FontWeight.w700)))
                  : const Text('Expired', style: TextStyle(
                      color: AppTheme.kRed, fontSize: 12, fontWeight: FontWeight.w700))),
        ])),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 2: HISTORY
// ═══════════════════════════════════════════════════════════════════════════
class _HistoryTab extends StatelessWidget {
  final List<DailyStats> history;
  final bool loading, isDark;
  final Color cardBg, textCol, subCol;
  const _HistoryTab({required this.history, required this.loading,
      required this.isDark, required this.cardBg, required this.textCol, required this.subCol});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.kAccent));

    final checked = history.where((d) => d.checkedIn).toList();
    if (checked.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_rounded, color: isDark ? c.text3 : const Color(0xFFBDBDBD), size: 48),
        const SizedBox(height: 16),
        Text('No attendance history', style: TextStyle(color: subCol, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Check-ins will appear here', style: TextStyle(color: subCol.withValues(alpha: 0.6), fontSize: 13)),
      ]));
    }

    // Show all days — checked-in days prominently, rest days dimmed
    final reversed = history.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Summary strip ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppTheme.kAccentDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.2))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _MiniBadge('${checked.length}', 'Check-ins', AppTheme.kAccent, textCol),
            _MiniBadge(
                NumberFormat('#,###').format(history.isEmpty ? 0
                    : (history.map((d) => d.steps).fold(0, (a, b) => a + b) / history.length).round()),
                'Avg Steps', const Color(0xFF29B6F6), textCol),
            _MiniBadge(
                '${(history.isEmpty ? 0 : history.map((d) => d.waterMl).fold(0, (a,b)=>a+b) / history.length / 1000).toStringAsFixed(1)}L',
                'Avg Water', AppTheme.kGreen, textCol),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Day-by-day list ──────────────────────────────────────────
        Text('Last 30 Days', style: GoogleFonts.inter(
            color: textCol, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...reversed.where((d) => d.checkedIn || d.steps > 0 || d.waterMl > 0).map((day) {
          final date = _parseDate(day.date);
          final hasActivity = day.checkedIn || day.steps > 0 || day.waterMl > 0;
          if (!hasActivity) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: day.checkedIn
                  ? (isDark ? c.card : Colors.white)
                  : (isDark ? c.card.withValues(alpha: 0.5) : const Color(0xFFFAFAFA)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: day.checkedIn
                      ? AppTheme.kAccent.withValues(alpha: 0.3)
                      : (isDark ? c.border : const Color(0xFFEEEEEE)),
                  width: day.checkedIn ? 1 : 0.5),
              boxShadow: day.checkedIn ? AppTheme.cardShadow : null,
            ),
            child: Row(children: [
              // Date badge
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: day.checkedIn ? AppTheme.kAccentDim : (isDark ? c.elevated : const Color(0xFFEEEEEE)),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(date != null ? DateFormat('MMM').format(date) : '—',
                      style: TextStyle(color: subCol, fontSize: 9, fontWeight: FontWeight.w600)),
                  Text(date != null ? '${date.day}' : '—',
                      style: TextStyle(
                          color: day.checkedIn ? AppTheme.kAccent : textCol,
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(date != null ? DateFormat('EEEE').format(date) : day.date,
                      style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 13)),
                  if (day.checkedIn) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppTheme.kAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Checked In',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                  ],
                  if (day.currentStreak > 1) ...[
                    const SizedBox(width: 4),
                    Text('${day.currentStreak} day streak',
                        style: TextStyle(color: subCol, fontSize: 10)),
                  ],
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (day.steps > 0)
                    _StatChip(Icons.directions_walk_rounded,
                        NumberFormat('#,###').format(day.steps), const Color(0xFF42A5F5), isDark),
                  if (day.waterMl > 0)
                    _StatChip(Icons.water_drop_rounded, '${day.waterMl}ml',
                        const Color(0xFF29B6F6), isDark),
                  if (day.pointsEarned > 0)
                    _StatChip(Icons.bolt_rounded, '+${day.pointsEarned}pts',
                        const Color(0xFFFFB300), isDark),
                ]),
              ])),
            ]),
          );
        }),
      ],
    );
  }

  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) { return null; }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 3: ACTIONS
// ═══════════════════════════════════════════════════════════════════════════
class _ActionsTab extends StatelessWidget {
  final MemberModel m;
  final bool isDark, renewing, toggling;
  final VoidCallback onRenew, onToggle;
  const _ActionsTab({required this.m, required this.isDark, required this.onRenew,
      required this.onToggle, required this.renewing, required this.toggling});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        // Renew
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: renewing ? null : onRenew,
            icon: renewing
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.autorenew_rounded, size: 20),
            label: Text(
              m.paymentCycleDate.isBefore(DateTime.now())
                  ? 'RENEW (EXPIRED)' : 'RENEW MEMBERSHIP',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 12),
        // Toggle status
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            onPressed: toggling ? null : onToggle,
            icon: toggling
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kRed))
                : Icon(m.isActive ? Icons.person_off_outlined : Icons.person_outline,
                    color: m.isActive ? AppTheme.kRed : AppTheme.kAccent, size: 18),
            label: Text(
              m.isActive ? 'DEACTIVATE MEMBER' : 'ACTIVATE MEMBER',
              style: GoogleFonts.inter(
                  color: m.isActive ? AppTheme.kRed : AppTheme.kAccent,
                  fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: (m.isActive ? AppTheme.kRed : AppTheme.kAccent).withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _QuickStat(this.label, this.value, this.icon, this.color, this.isDark);
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol  = isDark ? c.text3   : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: isDark ? c.card : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value, style: GoogleFonts.inter(color: textCol, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: subCol, fontSize: 9), textAlign: TextAlign.center),
      ]));
  }
}

class _AvgTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, textCol, subCol;
  const _AvgTile(this.label, this.value, this.icon, this.color, this.textCol, this.subCol);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.inter(color: textCol, fontSize: 14, fontWeight: FontWeight.w700)),
    Text(label, style: TextStyle(color: subCol, fontSize: 9), textAlign: TextAlign.center),
  ]);
}

class _MiniBadge extends StatelessWidget {
  final String value, label;
  final Color color, textCol;
  const _MiniBadge(this.value, this.label, this.color, this.textCol);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
    Text(label, style: TextStyle(color: GFColors(context).text2, fontSize: 10)),
  ]);
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _StatChip(this.icon, this.label, this.color, this.isDark);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 11),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]));
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.cardShadow),
    child: child);
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SecLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color textCol, subCol;
  final Color? valueColor;
  final Widget? trailing;
  const _InfoRow(this.icon, this.label, this.value, this.textCol, this.subCol,
      {this.valueColor, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: subCol, size: 16),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: subCol, fontSize: 13)),
    const Spacer(),
    trailing ?? Flexible(child: Text(value, textAlign: TextAlign.end,
        style: TextStyle(color: valueColor ?? textCol, fontSize: 13, fontWeight: FontWeight.w600))),
  ]);
}

class _Div extends StatelessWidget {
  final Color color;
  const _Div(this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(color: color, height: 1));
}

class _DialogRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _DialogRow(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: color ?? AppTheme.kTextPrimary,
          fontSize: 13, fontWeight: FontWeight.w600)),
    ]));
}
