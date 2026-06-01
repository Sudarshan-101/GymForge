import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'home/home_tab.dart';
import 'members/members_tab.dart';
import 'staff/staff_tab.dart';
import 'leaderboard/leaderboard_tab.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _ownerProfile;
  bool _profileLoaded = false;

  // Cached once after profile loads — never rebuilt on setState.
  // This is critical: IndexedStack must receive the SAME widget instances
  // every build, otherwise streams restart and the leaderboard flickers.
  List<Widget>? _tabs;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getOwnerProfile();
    if (!mounted) return;
    final gid  = profile?['gymId']  ?? '';
    final name = profile?['name']   ?? 'Owner';
    setState(() {
      _ownerProfile  = profile;
      _profileLoaded = true;
      // Build tabs exactly once with the real gymId — never again.
      _tabs = [
        HomeTab(gymId: gid, ownerName: name),
        MembersTab(gymId: gid),
        StaffTab(gymId: gid),
        LeaderboardTab(gymId: gid),
      ];
    });
  }

  String get gymId    => _ownerProfile?['gymId'] ?? '';
  String get ownerName => _ownerProfile?['name'] ?? 'Owner';

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    if (!_profileLoaded) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.kAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs!,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final c = GFColors(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Home',
                  index: 0,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Members',
                  index: 1,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 1)),
              _NavItem(
                  icon: Icons.badge_outlined,
                  activeIcon: Icons.badge,
                  label: 'Staff',
                  index: 2,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(
                  icon: Icons.emoji_events_outlined,
                  activeIcon: Icons.emoji_events,
                  label: 'Leaders',
                  index: 3,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                isActive ? activeIcon : icon,
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
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
