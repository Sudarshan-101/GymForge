import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/member_service.dart';
import 'home/member_home_tab.dart';
import 'workout/workout_tab.dart';
import 'analysis/analysis_tab.dart';
import 'leaderboard/member_leaderboard_tab.dart';

class MemberShell extends StatefulWidget {
  const MemberShell({super.key});
  @override
  State<MemberShell> createState() => _MemberShellState();
}

class _MemberShellState extends State<MemberShell> {
  int _index = 0;
  MemberSession? _session;
  bool _loaded = false;
  final _service = MemberService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final s = await _service.getSession();
    if (mounted) setState(() { _session = s; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    if (!_loaded) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.kAccent)),
      );
    }
    if (_session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }

    final tabs = [
      MemberHomeTab(session: _session!),
      WorkoutTab(session: _session!),
      AnalysisTab(session: _session!),
      MemberLeaderboardTab(session: _session!),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_index != 0) {
            setState(() => _index = 0);
          } else {
            // Close app on back from home tab
            SystemNavigator.pop();
          }
        },
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    final c = GFColors(context);
    const items = [
      (Icons.home_rounded,            Icons.home_outlined,            'Home'),
      (Icons.fitness_center_rounded,  Icons.fitness_center_outlined,  'Workout'),
      (Icons.bar_chart_rounded,       Icons.bar_chart_outlined,       'Analysis'),
      (Icons.emoji_events_rounded,    Icons.emoji_events_outlined,    'Ranks'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == _index;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.kAccentDim : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive ? item.$1 : item.$2,
                          color: isActive ? AppTheme.kAccent : c.text3,
                          size: 21,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.inter(
                          color: isActive ? AppTheme.kAccent : c.text3,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: isActive ? 0.2 : 0,
                        ),
                        child: Text(item.$3),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}