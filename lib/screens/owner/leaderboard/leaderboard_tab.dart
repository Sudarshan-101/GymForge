import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/member_avatar.dart';
import '../../../services/firestore_service.dart';
import '../../../models/member_model.dart';

class LeaderboardTab extends StatefulWidget {
  final String gymId;
  const LeaderboardTab({super.key, required this.gymId});
  @override State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final _service = FirestoreService();
  String _sortBy = 'points';
  String? _prize;
  StreamSubscription? _prizeSub;

  @override
  void initState() {
    super.initState();
    _prizeSub = _service.prizeStream(widget.gymId).listen((p) {
      if (mounted && p != _prize) setState(() => _prize = p);
    });
  }

  @override
  void dispose() { _prizeSub?.cancel(); super.dispose(); }

  List<MemberModel> _sorted(List<MemberModel> m) {
    final list = List<MemberModel>.from(m);
    switch (_sortBy) {
      case 'streak':     list.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
      case 'attendance': list.sort((a, b) => b.totalAttendance.compareTo(a.totalAttendance));
      default:           list.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    if (widget.gymId.isEmpty) {
      return Scaffold(backgroundColor: c.bg,
          body: const Center(child: CircularProgressIndicator(color: AppTheme.kAccent)));
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Column(children: [
        _header(),
        Expanded(child: StreamBuilder<List<MemberModel>>(
          stream: _service.leaderboardStream(widget.gymId),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.kAccent));
            }
            if (snap.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(24),
                  child: Text('${snap.error}', style: const TextStyle(color: AppTheme.kRed, fontSize: 13), textAlign: TextAlign.center)));
            }
            final members = _sorted(snap.data ?? []);
            if (members.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.emoji_events_outlined, color: c.text3, size: 48),
                const SizedBox(height: 16),
                Text('No members yet', style: TextStyle(color: c.text2, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Members appear once they earn points.', style: TextStyle(color: c.text3, fontSize: 13)),
              ]));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                if (_prize != null && _prize!.isNotEmpty) _prizeCard(),
                if (members.length >= 3) _podium(members),
                const SizedBox(height: 8),
                ...List.generate(
                  members.length > 3 ? members.length - 3 : members.length,
                      (i) { final si = members.length >= 3 ? 3 : 0;
                  return _Row(rank: si+i+1, member: members[si+i], sortBy: _sortBy); },
                ),
              ],
            );
          },
        )),
      ])),
    );
  }

  Widget _header() {
    final c = GFColors(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LEADERBOARD', style: GoogleFonts.inter(
                color: c.text1, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
            Text('Member rankings', style: TextStyle(color: c.text2, fontSize: 12)),
          ])),
          GestureDetector(
            onTap: () => _prizeDlg(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: c.isDark ? AppTheme.kGoldDim : AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: c.isDark ? AppTheme.kGold.withValues(alpha: 0.35) : AppTheme.kAccent.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.kGold, size: 14),
                const SizedBox(width: 5),
                Text(_prize != null && _prize!.isNotEmpty ? 'Edit Prize' : 'Set Prize',
                    style: TextStyle(color: c.isDark ? AppTheme.kGold : AppTheme.kAccent, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _chip('Points', 'points'),
          _chip('Streak', 'streak'),
          _chip('Attendance', 'attendance'),
        ]),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final c = GFColors(context);
    final sel = value == _sortBy;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppTheme.kAccent : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppTheme.kAccent : c.border),
        ),
        child: Text(label, style: TextStyle(
            color: sel ? Colors.black : c.text2,
            fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _prizeCard() {
    final c = GFColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF1F1800) : c.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.kGold.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(children: [
          const Text('🥇', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Prize — 1st Place',
                style: TextStyle(color: AppTheme.kGold, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(_prize!, style: TextStyle(color: c.text1, fontSize: 15, fontWeight: FontWeight.w700)),
          ])),
        ]),
      ),
    );
  }

  Widget _podium(List<MemberModel> m) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _PSpot(member: m[1], rank: 2, height: 72, sortBy: _sortBy)),
        const SizedBox(width: 8),
        Expanded(child: _PSpot(member: m[0], rank: 1, height: 100, sortBy: _sortBy)),
        const SizedBox(width: 8),
        Expanded(child: _PSpot(member: m[2], rank: 3, height: 56, sortBy: _sortBy)),
      ]),
    );
  }

  void _prizeDlg(BuildContext ctx) {
    final c = GFColors(context);
    final ctrl = TextEditingController(text: _prize ?? '');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      title: Text('Monthly Prize', style: TextStyle(color: c.text1, fontWeight: FontWeight.w700)),
      content: TextField(controller: ctrl,
          style: TextStyle(color: c.text1, fontSize: 14),
          decoration: const InputDecoration(hintText: 'e.g. Amazon voucher ₹500'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.text2))),
        ElevatedButton(
          onPressed: () async {
            final p = ctrl.text.trim();
            if (p.isNotEmpty) await _service.setMonthlyPrize(widget.gymId, p);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kGold, foregroundColor: Colors.black),
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

class _PSpot extends StatelessWidget {
  final MemberModel member; final int rank; final double height; final String sortBy;
  const _PSpot({required this.member, required this.rank, required this.height, required this.sortBy});
  Color _rankColor(bool isDark) => rank == 1 ? AppTheme.kGold : rank == 2 ? AppTheme.kMedalSilver : AppTheme.kMedalBronze;
  String get _v => sortBy == 'streak' ? '${member.currentStreak}🔥' : sortBy == 'attendance' ? '${member.totalAttendance}' : '${member.totalPoints}';
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    const badges = ['🥇','🥈','🥉'];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      MemberAvatar(
        photoUrl: member.photoUrl,
        initials: member.initials,
        radius: 18,
      ),
      const SizedBox(height: 5),
      Text(member.name.split(' ').first, style: TextStyle(color: c.text1, fontSize: 11, fontWeight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      Text(_v, style: TextStyle(color: _rankColor(c.isDark), fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Container(width: double.infinity, height: height,
          decoration: BoxDecoration(
              color: _rankColor(c.isDark).withValues(alpha: 0.10),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              border: Border.all(color: _rankColor(c.isDark).withValues(alpha: 0.25), width: 0.5)),
          child: Center(child: Text(badges[rank-1], style: TextStyle(fontSize: rank==1?26:20)))),
    ]);
  }
}

class _Row extends StatelessWidget {
  final int rank; final MemberModel member; final String sortBy;
  const _Row({required this.rank, required this.member, required this.sortBy});
  String get _v => sortBy == 'streak' ? '${member.currentStreak}' : sortBy == 'attendance' ? '${member.totalAttendance}' : '${member.totalPoints}';
  String get _l => sortBy == 'streak' ? 'days' : sortBy == 'attendance' ? 'visits' : 'pts';
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: c.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: c.border, width: 0.5)),
      child: Row(children: [
        SizedBox(width: 28, child: Text('#$rank', style: TextStyle(color: c.text3, fontSize: 13, fontWeight: FontWeight.w700))),
        Container(width: 36, height: 36,
            decoration: const BoxDecoration(color: AppTheme.kAccentDim, shape: BoxShape.circle),
            child: Center(child: Text(member.initials, style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.w700, fontSize: 13)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name, style: TextStyle(color: c.text1, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${member.currentStreak}🔥  ${member.totalAttendance} visits',
              style: TextStyle(color: c.text3, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_v, style: const TextStyle(color: AppTheme.kGold, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(_l, style: TextStyle(color: c.text3, fontSize: 10)),
        ]),
      ]),
    );
  }
}