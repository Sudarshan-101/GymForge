import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/member_model.dart';

class BusinessAnalyticsScreen extends StatefulWidget {
  final String gymId;
  const BusinessAnalyticsScreen({super.key, required this.gymId});

  @override
  State<BusinessAnalyticsScreen> createState() =>
      _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabCtrl;
  Map<String, dynamic> _revenueData = {};
  Map<int, int> _heatmap = {};
  bool _loadingRevenue = true;
  bool _loadingHeatmap = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final revenue = await _firestoreService.getRevenueData(widget.gymId);
    final heatmap = await _firestoreService.getCheckinHeatmap(widget.gymId);
    if (mounted) {
      setState(() {
        _revenueData = revenue;
        _heatmap = heatmap;
        _loadingRevenue = false;
        _loadingHeatmap = false;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(
          'BUSINESS ANALYTICS',
          style: GoogleFonts.inter(
            color: c.text1,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppTheme.kPrimary,
          indicatorWeight: 2,
          labelColor: AppTheme.kPrimary,
          unselectedLabelColor: c.text3,
          labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Members'),
            Tab(text: 'Check-ins'),
            Tab(text: 'Retention'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildRevenuTab(),
          _buildMembershipTab(),
          _buildHeatmapTab(),
          _buildRetentionTab(),
        ],
      ),
    );
  }

  // ─── Revenue Tab ───────────────────────────────────────────────────────────
  Widget _buildRevenuTab() {
    final c = GFColors(context);
    if (_loadingRevenue) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary));
    }

    final thisMonth = (_revenueData['thisMonth'] as num?)?.toDouble() ?? 0;
    final lastMonth = (_revenueData['lastMonth'] as num?)?.toDouble() ?? 0;
    final changeStr = _revenueData['change'] ?? '0';
    final changeVal = double.tryParse(changeStr) ?? 0;
    final isUp = changeVal >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle('Revenue Overview'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'This Month',
                  value: '₹${thisMonth.toStringAsFixed(0)}',
                  color: AppTheme.kAccent,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Last Month',
                  value: '₹${lastMonth.toStringAsFixed(0)}',
                  color: c.text2,
                  icon: Icons.history,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GFCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isUp ? AppTheme.kGreen : AppTheme.kRed).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isUp ? AppTheme.kGreen : AppTheme.kRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isUp ? '+' : ''}$changeStr% vs last month',
                      style: TextStyle(
                        color: isUp ? AppTheme.kGreen : AppTheme.kRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isUp
                          ? 'Great! Revenue is growing.'
                          : 'Revenue dipped — check renewals.',
                      style: TextStyle(
                          color: c.text2, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Monthly Comparison'),
          const SizedBox(height: 16),
          GFCard(
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: (thisMonth > lastMonth ? thisMonth : lastMonth) * 1.3 + 1000,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, _) => Text(
                          '₹${(v / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                              color: c.text3, fontSize: 9),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final labels = ['Last Month', 'This Month'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[v.toInt()],
                              style: TextStyle(
                                  color: c.text3, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: c.border, strokeWidth: 0.5),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: lastMonth,
                        color: c.text2.withValues(alpha: 0.4),
                        width: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: thisMonth,
                        gradient: const LinearGradient(
                          colors: [AppTheme.kPrimary, Color(0xFFFF8A65)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Membership Distribution Tab ───────────────────────────────────────────
  Widget _buildMembershipTab() {
    final c = GFColors(context);
    return StreamBuilder<List<MemberModel>>(
      stream: _firestoreService.membersStream(widget.gymId),
      builder: (context, snap) {
        final members = snap.data ?? [];
        final monthly =
            members.where((m) => m.planType == 'Monthly').length;
        final quarterly =
            members.where((m) => m.planType == 'Quarterly').length;
        final annual =
            members.where((m) => m.planType == 'Annual').length;
        final total = members.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _sectionTitle('Membership Distribution'),
              const SizedBox(height: 16),
              GFCard(
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: total == 0
                          ? Center(
                              child: Text('No members yet',
                                  style: TextStyle(color: c.text3)))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 50,
                                sections: [
                                  if (monthly > 0)
                                    PieChartSectionData(
                                      value: monthly.toDouble(),
                                      title: '$monthly',
                                      color: AppTheme.kPrimary,
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                  if (quarterly > 0)
                                    PieChartSectionData(
                                      value: quarterly.toDouble(),
                                      title: '$quarterly',
                                      color: AppTheme.kAccent,
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                  if (annual > 0)
                                    PieChartSectionData(
                                      value: annual.toDouble(),
                                      title: '$annual',
                                      color: AppTheme.kGold,
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LegendDot(
                            color: AppTheme.kPrimary,
                            label: 'Monthly',
                            count: monthly),
                        _LegendDot(
                            color: AppTheme.kAccent,
                            label: 'Quarterly',
                            count: quarterly),
                        _LegendDot(
                            color: AppTheme.kGold,
                            label: 'Annual',
                            count: annual),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                        label: 'Total Members',
                        value: '$total',
                        color: c.text2,
                        icon: Icons.people),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                        label: 'Active',
                        value:
                            '${members.where((m) => m.isActive).length}',
                        color: AppTheme.kAccent,
                        icon: Icons.check_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Heatmap Tab ───────────────────────────────────────────────────────────
  Widget _buildHeatmapTab() {
    final c = GFColors(context);
    if (_loadingHeatmap) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary));
    }

    final maxVal =
        _heatmap.values.isEmpty ? 1 : _heatmap.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle('Check-in Heatmap (Last 30 Days)'),
          Text(
            'See your busiest hours to plan trainer shifts',
            style: TextStyle(color: c.text2, fontSize: 12),
          ),
          const SizedBox(height: 20),
          GFCard(
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: (maxVal + 2).toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => c.card,
                      getTooltipItem: (group, _, rod, __) {
                        final hour = group.x + 5;
                        final ampm = hour < 12 ? 'AM' : 'PM';
                        final h = hour > 12 ? hour - 12 : hour;
                        return BarTooltipItem(
                          '$h$ampm\n${rod.toY.toInt()} check-ins',
                          TextStyle(color: c.text1, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 2,
                        getTitlesWidget: (val, _) {
                          final hour = val.toInt() + 5;
                          if (hour % 2 != 0) return const SizedBox.shrink();
                          final ampm = hour < 12 ? 'AM' : 'PM';
                          final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                          return Text(
                            '$h$ampm',
                            style: TextStyle(
                                color: c.text3, fontSize: 8),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: c.border, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _heatmap.entries.map((e) {
                    final hour = e.key;
                    final count = e.value;
                    final isPeak = count == maxVal && maxVal > 0;
                    return BarChartGroupData(
                      x: hour - 5,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: isPeak ? AppTheme.kPrimary : AppTheme.kPrimary.withValues(alpha: 0.35),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (maxVal > 0) ...[
            const SizedBox(height: 16),
            GFCard(
              borderColor: AppTheme.kPrimary.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights, color: AppTheme.kPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peak Hours',
                          style: TextStyle(
                              color: c.text1,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        Text(
                          _getPeakHoursText(),
                          style: TextStyle(
                              color: c.text2, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPeakHoursText() {
    final sorted = _heatmap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).where((e) => e.value > 0).toList();
    if (top.isEmpty) return 'No data yet';
    return top.map((e) {
      final h = e.key;
      final ampm = h < 12 ? 'AM' : 'PM';
      final disp = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$disp$ampm (${e.value})';
    }).join(', ');
  }

  // ─── Retention Tab ─────────────────────────────────────────────────────────
  Widget _buildRetentionTab() {
    final c = GFColors(context);
    return StreamBuilder<List<MemberModel>>(
      stream: _firestoreService.membersStream(widget.gymId),
      builder: (context, snap) {
        final members = snap.data ?? [];
        final inactive = members
            .where((m) => m.isActive && m.isInactive && m.totalAttendance > 0)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _sectionTitle('Retention Report'),
              Text(
                'Members who haven\'t visited in 10+ days',
                style: TextStyle(color: c.text2, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Active Members',
                      value: '${members.where((m) => m.isActive).length}',
                      color: AppTheme.kAccent,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'At Risk',
                      value: '${inactive.length}',
                      color: AppTheme.kRed,
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (inactive.isEmpty)
                GFCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration,
                            color: AppTheme.kAccent, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All members are active!',
                                style: TextStyle(
                                    color: c.text1,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                              Text(
                                'Great retention rate. Keep it up!',
                                style: TextStyle(
                                    color: c.text2,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  'Send a "We miss you" nudge to these members:',
                  style: TextStyle(
                      color: c.text3, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ...inactive.map((m) => _InactiveMemberRow(member: m)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    final c = GFColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: c.text1,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
                color: color, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(color: c.text3, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendDot(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: c.text2, fontSize: 11)),
            Text('$count members',
                style:
                    TextStyle(color: c.text3, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _InactiveMemberRow extends StatelessWidget {
  final MemberModel member;

  const _InactiveMemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final daysSince = member.lastVisit != null
        ? DateTime.now().difference(member.lastVisit!).inDays
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.kRed.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.kRed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: const TextStyle(
                    color: AppTheme.kRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
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
                  daysSince != null
                      ? 'Last seen $daysSince days ago'
                      : 'Never visited',
                  style: TextStyle(
                      color: c.text3, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_none,
              color: AppTheme.kRed, size: 20),
        ],
      ),
    );
  }
}
