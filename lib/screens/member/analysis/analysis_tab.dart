import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/member_service.dart';
import '../../../models/daily_stats_model.dart';
import '../../../models/member_model.dart';

class AnalysisTab extends StatefulWidget {
  final MemberSession session;
  const AnalysisTab({super.key, required this.session});

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  final _service = MemberService();
  List<DailyStats> _month = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await _service.getMemberHistory(
        widget.session.gymId, widget.session.memberId, days: 30);
    if (mounted) setState(() { _month = m; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: Text('Member Analytics',
            style: GoogleFonts.inter(
                color: c.text1,
                fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.text2),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.kAccent))
          : StreamBuilder<MemberModel?>(
              stream: _service.memberStream(
                  widget.session.gymId, widget.session.memberId),
              builder: (_, snap) => _buildBody(snap.data),
            ),
    );
  }

  Widget _buildBody(MemberModel? member) {
    final checkedInDays = _month.where((d) => d.checkedIn).length;
    final monthPct = _month.isEmpty ? 0.0 : checkedInDays / _month.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Top stat cards ──────────────────────────────────────────────
        _buildTopStats(member, checkedInDays, monthPct),
        const SizedBox(height: 20),

        // ── Membership info card ────────────────────────────────────────
        _buildMembershipCard(member),
        const SizedBox(height: 16),

        // ── Monthly attendance chart ────────────────────────────────────
        _buildAttendanceChart(member),
        const SizedBox(height: 16),

        // ── Gym visits trend ────────────────────────────────────────────
        _buildVisitsTrend(),
      ],
    );
  }

  // ── Top stat cards ────────────────────────────────────────────────────────
  Widget _buildTopStats(MemberModel? member, int checkedIn, double pct) {
    final c = GFColors(context);
    final totalPts = member?.totalPoints ?? 0;
    final level = (totalPts / 500).floor() + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview',
            style: GoogleFonts.inter(
                color: c.text1,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _BigStatCard(
            label: 'Total Visits',
            value: '${member?.totalAttendance ?? 0}',
            icon: Icons.fitness_center_rounded,
            color: AppTheme.kAccent,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _BigStatCard(
            label: 'Current Level',
            value: 'Lv $level',
            icon: Icons.military_tech_rounded,
            color: const Color(0xFFFFB300),
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _BigStatCard(
            label: 'Total XP',
            value: '${member?.totalPoints ?? 0}',
            icon: Icons.bolt_rounded,
            color: AppTheme.kAccent,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _BigStatCard(
            label: 'Streak',
            value: '${member?.currentStreak ?? 0}d 🔥',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF7043),
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _BigStatCard(
            label: 'This Month',
            value: '$checkedIn visits',
            icon: Icons.calendar_month_rounded,
            color: AppTheme.kGreen,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _BigStatCard(
            label: 'Attendance %',
            value: '${(pct * 100).round()}%',
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFF7C4DFF),
          )),
        ]),
      ],
    );
  }

  // ── Membership card ───────────────────────────────────────────────────────
  Widget _buildMembershipCard(MemberModel? member) {
    final c = GFColors(context);
    final isActive = member?.isActive ?? false;
    final statusColor = isActive ? AppTheme.kGreen : AppTheme.kRed;
    final lastVisit = member?.lastVisit;
    final fmt = DateFormat('dd MMM yyyy');

    return MCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.card_membership_rounded,
                color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Membership Details',
              style: GoogleFonts.inter(
                  color: c.text1, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        _DetailRow(
            label: 'Plan',
            value: member?.planType ?? '—',
            icon: Icons.workspace_premium_rounded),
        const SizedBox(height: 10),
        _DetailRow(
            label: 'Member ID',
            value: member?.memberId ?? '—',
            icon: Icons.badge_rounded),
        const SizedBox(height: 10),
        _DetailRow(
            label: 'Renewal Date',
            value: member != null
                ? fmt.format(member.paymentCycleDate)
                : '—',
            icon: Icons.event_rounded),
        const SizedBox(height: 10),
        _DetailRow(
            label: 'Last Check-in',
            value: lastVisit != null ? fmt.format(lastVisit) : 'Never',
            icon: Icons.access_time_rounded),
      ]),
    );
  }

  // ── Attendance heatmap (30 days) ─────────────────────────────────────────
  Widget _buildAttendanceChart(MemberModel? member) {
    final c = GFColors(context);
    // Build 5-week grid (35 cells, first few may be empty)
    final now = DateTime.now();
    final startDay = now.subtract(Duration(days: _month.length - 1));
    // Pad to start of week (Mon)
    final weekdayOffset = (startDay.weekday - 1) % 7;
    final allCells = <_CalCell>[];
    for (int i = 0; i < weekdayOffset; i++) {
      allCells.add(const _CalCell(date: null, checkedIn: false));
    }
    for (final d in _month) {
      allCells.add(_CalCell(
          date: d.date.isNotEmpty ? d.date : null, checkedIn: d.checkedIn));
    }

    return MCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppTheme.kAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.grid_view_rounded,
                color: AppTheme.kAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Text('30-Day Attendance',
              style: GoogleFonts.inter(
                  color: c.text1, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 6),
        Text('${_month.where((d) => d.checkedIn).length} visits this month',
            style: TextStyle(color: c.text3, fontSize: 12)),
        const SizedBox(height: 16),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => SizedBox(
                    width: 32,
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.text3, fontSize: 10)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Grid
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allCells.map((cell) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cell.date == null
                    ? Colors.transparent
                    : cell.checkedIn
                        ? AppTheme.kAccent
                        : c.border,
                borderRadius: BorderRadius.circular(6),
                boxShadow: cell.checkedIn
                    ? [
                        BoxShadow(
                          color: AppTheme.kAccent.withValues(alpha: 0.3),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
              child: cell.date != null
                  ? Icon(
                      cell.checkedIn
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 14,
                      color: cell.checkedIn ? Colors.white : c.text3,
                    )
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const _Legend(color: AppTheme.kAccent, label: 'Visited'),
          const SizedBox(width: 16),
          _Legend(color: c.border, label: 'Missed'),
        ]),
      ]),
    );
  }

  // ── Weekly visits bar chart ───────────────────────────────────────────────
  Widget _buildVisitsTrend() {
    final c = GFColors(context);
    // Group last 4 weeks by week
    final weeks = <String, int>{};
    final now = DateTime.now();
    for (int w = 3; w >= 0; w--) {
      final start = now.subtract(Duration(days: (w + 1) * 7 - 1));
      final label = DateFormat('MMM d').format(start);
      weeks[label] = 0;
    }
    for (final d in _month) {
      if (!d.checkedIn) continue;
      try {
        final date = DateTime.parse(d.date);
        final daysAgo = now.difference(date).inDays;
        final weekIdx = (daysAgo / 7).floor().clamp(0, 3);
        final start =
            now.subtract(Duration(days: (weekIdx + 1) * 7 - 1));
        final label = DateFormat('MMM d').format(start);
        weeks[label] = (weeks[label] ?? 0) + 1;
      } catch (_) {}
    }
    final labels = weeks.keys.toList();
    final values = weeks.values.toList();
    final maxY =
        (values.isEmpty ? 7 : values.reduce((a, b) => a > b ? a : b) + 1)
            .toDouble()
            .clamp(3.0, 14.0);

    return MCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppTheme.kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bar_chart_rounded,
                color: AppTheme.kGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Weekly Visits',
              style: GoogleFonts.inter(
                  color: c.text1, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      c.isDark ? c.card : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} visits',
                      TextStyle(
                          color: c.text1,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[idx],
                            style:
                                TextStyle(color: c.text3, fontSize: 9)),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: c.border, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(values.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.kGreen,
                        AppTheme.kGreen.withValues(alpha: 0.5)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: 36,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ]);
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Helper classes ─────────────────────────────────────────────────────────

class _CalCell {
  final String? date;
  final bool checkedIn;
  const _CalCell({required this.date, required this.checkedIn});
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: c.text3, fontSize: 11)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Row(children: [
      Icon(icon, color: AppTheme.kAccent, size: 16),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: c.text3, fontSize: 12, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.inter(
              color: c.text1, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _BigStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.inter(
                color: c.text1, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: c.text2, fontSize: 11)),
      ]),
    );
  }
}

class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const MCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
        boxShadow: c.isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
      ),
      child: child,
    );
  }
}
