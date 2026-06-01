import 'dart:async';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/member_avatar.dart';
import '../../../services/member_service.dart';
import '../../../models/member_model.dart';

class MemberLeaderboardTab extends StatefulWidget {
  final MemberSession session;
  const MemberLeaderboardTab({super.key, required this.session});
  @override State<MemberLeaderboardTab> createState() => _MemberLeaderboardTabState();
}

class _MemberLeaderboardTabState extends State<MemberLeaderboardTab> {
  final _service = MemberService();
  String _filter = 'Points';
  String? _prize;
  StreamSubscription? _prizeSub;

  @override
  void initState() {
    super.initState();
    _prizeSub = _service.prizeStream(widget.session.gymId).listen((p) {
      if (mounted && p != _prize) setState(() => _prize = p);
    });
  }

  @override
  void dispose() { _prizeSub?.cancel(); super.dispose(); }

  List<MemberModel> _sorted(List<MemberModel> m) {
    final list = List<MemberModel>.from(m);
    switch (_filter) {
      case 'Streak': list.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
      case 'Visits': list.sort((a, b) => b.totalAttendance.compareTo(a.totalAttendance));
      default:       list.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(child: StreamBuilder<List<MemberModel>>(
            stream: _service.leaderboardStream(widget.session.gymId),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.kAccent));
              }
              if (snap.hasError) {
                return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}',
                        style: const TextStyle(color: AppTheme.kRed, fontSize: 13),
                        textAlign: TextAlign.center)));
              }
              final sorted = _sorted(snap.data ?? []);
              if (sorted.isEmpty) {
                return Center(child: Text('No members yet.\nStart earning points! 💪',
                    style: TextStyle(color: c.text2, fontSize: 14),
                    textAlign: TextAlign.center));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (_prize != null && _prize!.isNotEmpty) _prizeCard(),
                  if (sorted.length >= 3) _podium(sorted),
                  const SizedBox(height: 8),
                  ...List.generate(
                    sorted.length > 3 ? sorted.length - 3 : sorted.length,
                        (i) {
                      final si = sorted.length >= 3 ? 3 : 0;
                      return _RankRow(
                        rank: si + i + 1,
                        member: sorted[si + i],
                        isMe: sorted[si + i].memberId == widget.session.memberId,
                        filter: _filter,
                      );
                    },
                  ),
                ],
              );
            },
          )),
        ]),
      ),
    );
  }

  Widget _header() {
    final c = GFColors(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: '🏆  Leaderboard', subtitle: 'Your gym\'s top performers'),
        const SizedBox(height: 12),
        Row(children: ['Points', 'Streak', 'Visits'].map((f) {
          final sel = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppTheme.kAccentDim : c.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppTheme.kAccent : c.border),
              ),
              child: Text(f, style: TextStyle(
                  color: sel ? Colors.black : c.text2,
                  fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          );
        }).toList()),
      ]),
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
          border: Border.all(color: c.isDark ? AppTheme.kGold.withValues(alpha: 0.4) : AppTheme.kAccent.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(children: [
          const Text('🥇', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly Prize — 1st Place',
                style: TextStyle(color: c.isDark ? AppTheme.kGold : AppTheme.kAccent, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(_prize!, style: TextStyle(color: c.text1, fontSize: 15, fontWeight: FontWeight.w700)),
          ])),
        ]),
      ),
    );
  }

  Widget _podium(List<MemberModel> s) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _Spot(m: s[1], rank: 2, h: 72, isMe: s[1].memberId == widget.session.memberId, f: _filter)),
        const SizedBox(width: 8),
        Expanded(child: _Spot(m: s[0], rank: 1, h: 100, isMe: s[0].memberId == widget.session.memberId, f: _filter)),
        const SizedBox(width: 8),
        Expanded(child: _Spot(m: s[2], rank: 3, h: 56, isMe: s[2].memberId == widget.session.memberId, f: _filter)),
      ]),
    );
  }
}

class _Spot extends StatelessWidget {
  final MemberModel m;
  final int rank;
  final double h;
  final bool isMe;
  final String f;
  const _Spot({required this.m, required this.rank, required this.h, required this.isMe, required this.f});

  Color _rankColor(bool isDark) => rank == 1 ? AppTheme.kGold : rank == 2 ? AppTheme.kMedalSilver : AppTheme.kMedalBronze;
  String get _v => f == 'Streak' ? '${m.currentStreak}🔥' : f == 'Visits' ? '${m.totalAttendance}' : '${m.totalPoints}';

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final badges = ['🥇', '🥈', '🥉'];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 42, height: 42,
          decoration: BoxDecoration(
              color: _rankColor(c.isDark).withValues(alpha: 0.15), shape: BoxShape.circle,
              border: Border.all(color: isMe ? AppTheme.kAccent : _rankColor(c.isDark), width: 1.5)),
          child: Center(child: Text(m.initials,
              style: TextStyle(color: _rankColor(c.isDark), fontWeight: FontWeight.w800, fontSize: 14)))),
      const SizedBox(height: 5),
      Text(m.name.split(' ').first,
          style: TextStyle(color: isMe ? AppTheme.kAccent : c.text1,
              fontSize: 11, fontWeight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      Text(_v, style: TextStyle(color: _rankColor(c.isDark), fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Container(width: double.infinity, height: h,
          decoration: BoxDecoration(
              color: _rankColor(c.isDark).withValues(alpha: 0.10),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              border: Border.all(color: _rankColor(c.isDark).withValues(alpha: 0.25), width: 0.5)),
          child: Center(child: Text(badges[rank-1], style: TextStyle(fontSize: rank==1?26:20)))),
    ]);
  }
}

class _RankRow extends StatelessWidget {
  final int rank; final MemberModel member; final bool isMe; final String filter;
  const _RankRow({required this.rank, required this.member, required this.isMe, required this.filter});

  String get _v => filter == 'Streak' ? '${member.currentStreak}' : filter == 'Visits' ? '${member.totalAttendance}' : '${member.totalPoints}';
  String get _l => filter == 'Streak' ? 'days' : filter == 'Visits' ? 'visits' : 'pts';

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.kAccentDim : c.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: isMe ? AppTheme.kAccent.withValues(alpha: 0.4) : c.border, width: 0.5),
      ),
      child: Row(children: [
        SizedBox(width: 28, child: Text('#$rank',
            style: TextStyle(color: c.text3, fontSize: 13, fontWeight: FontWeight.w700))),
        MemberAvatar(
          photoUrl: member.photoUrl,
          initials: member.initials,
          radius: 18,
          ringColor: isMe ? AppTheme.kAccent : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(member.name,
                style: TextStyle(color: isMe ? AppTheme.kAccent : c.text1,
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(4)),
                  child: const Text('YOU', style: TextStyle(color: AppTheme.kAccent, fontSize: 9, fontWeight: FontWeight.w800))),
            ],
          ]),
          Text('${member.currentStreak}🔥  ${member.totalAttendance} visits',
              style: TextStyle(color: c.text3, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_v, style: TextStyle(color: isMe ? AppTheme.kAccent : AppTheme.kGold,
              fontSize: 18, fontWeight: FontWeight.w800)),
          Text(_l, style: TextStyle(color: c.text3, fontSize: 10)),
        ]),
      ]),
    );
  }
}