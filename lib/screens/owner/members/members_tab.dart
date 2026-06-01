import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/member_model.dart';
import '../home/add_member_screen.dart';
import 'member_detail_screen.dart';

class MembersTab extends StatefulWidget {
  final String gymId;
  const MembersTab({super.key, required this.gymId});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<MemberModel> _filter(List<MemberModel> members) {
    List<MemberModel> filtered = members;

    if (_query.isNotEmpty) {
      filtered = filtered
          .where((m) =>
      m.name.toLowerCase().contains(_query.toLowerCase()) ||
          m.memberId.toLowerCase().contains(_query.toLowerCase()) ||
          m.email.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    switch (_tabCtrl.index) {
      case 1:
        filtered = filtered.where((m) => m.isActive).toList();
        break;
      case 2:
        filtered = filtered.where((m) => !m.isActive).toList();
        break;
    }

    return filtered;
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
      appBar: AppBar(
        backgroundColor: c.bg,
        title: Text(
          'MEMBERS',
          style: GoogleFonts.inter(
            color: c.text1,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              const Icon(Icons.person_add, color: AppTheme.kAccent, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddMemberScreen(gymId: widget.gymId),
              ));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: c.text1),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID or email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear,
                          color: c.text3, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                // Status filter tabs
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppTheme.kPrimary,
                  indicatorWeight: 2,
                  labelColor: AppTheme.kPrimary,
                  unselectedLabelColor: c.text3,
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  onTap: (_) => setState(() {}),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Inactive'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<MemberModel>>(
        stream: _firestoreService.membersStream(widget.gymId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.kPrimary));
          }

          final allMembers = snap.data ?? [];
          final filtered = _filter(allMembers);

          if (allMembers.isEmpty) {
            return _buildEmptyState();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      color: c.text3, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No members found',
                    style: TextStyle(
                        color: c.text2, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} member${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          color: c.text3, fontSize: 12),
                    ),
                    const Spacer(),
                    if (_query.isNotEmpty)
                      Text(
                        'for "$_query"',
                        style: TextStyle(
                            color: c.text3, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _MemberListTile(member: filtered[i], gymId: widget.gymId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = GFColors(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
            const Icon(Icons.people_outline, color: AppTheme.kPrimary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No Members Yet',
            style: TextStyle(
                color: c.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first member to get started',
            style:
            TextStyle(color: c.text2, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddMemberScreen(gymId: widget.gymId),
              ));
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('ADD FIRST MEMBER'),
          ),
        ],
      ),
    );
  }
}

class _MemberListTile extends StatefulWidget {
  final MemberModel member;
  final String gymId;

  const _MemberListTile({required this.member, required this.gymId});

  @override
  State<_MemberListTile> createState() => _MemberListTileState();
}

class _MemberListTileState extends State<_MemberListTile> {
  final _firestoreService = FirestoreService();
  bool _renewing = false;

  Future<void> _quickRenew() async {
    // Show confirmation before renewing
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = GFColors(ctx);
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Renew Membership',
              style: TextStyle(color: c.text1, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Member: ${widget.member.name}',
                    style: TextStyle(color: c.text2, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Plan: ${widget.member.planType}',
                    style: TextStyle(color: c.text2, fontSize: 13)),
                if (widget.member.planFee > 0) ...[
                  const SizedBox(height: 4),
                  Text('Fee: ${widget.member.feeLabel}',
                      style: const TextStyle(
                          color: AppTheme.kAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: c.text2)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('RENEW'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    setState(() => _renewing = true);
    try {
      await _firestoreService.renewMembership(
        widget.gymId,
        widget.member.id,
        widget.member.planType,
        widget.member.paymentCycleDate,
        planFee: widget.member.planFee,
        memberName: widget.member.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('${widget.member.name} renewed!'),
          ]),
          backgroundColor: AppTheme.kGreen,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Renewal failed: ${e.toString()}'),
          backgroundColor: AppTheme.kRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final member = widget.member;
    final isRenewalSoon = member.isRenewalSoon;
    final isExpired = member.daysUntilRenewal < 0;
    final daysLeft = member.daysUntilRenewal;
    final showRenewBtn = isRenewalSoon || isExpired;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              MemberDetailScreen(member: member, gymId: widget.gymId),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRenewalSoon
                ? AppTheme.kGold.withValues(alpha: 0.4)
                : c.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (member.isActive ? AppTheme.kPrimary : c.text3)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                  (member.isActive ? AppTheme.kPrimary : c.text3)
                      .withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  member.initials,
                  style: TextStyle(
                    color: member.isActive
                        ? AppTheme.kPrimary
                        : c.text3,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          color: c.text1,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!member.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.text3.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'INACTIVE',
                            style: TextStyle(
                                color: c.text3,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID: ${member.memberId} · ${member.planType}',
                    style: TextStyle(
                        color: c.text3, fontSize: 11),
                  ),
                  if (isRenewalSoon)
                    Text(
                      daysLeft == 0
                          ? '⚠️ Renews TODAY'
                          : '⚠️ Renews in $daysLeft day${daysLeft != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.kGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            // Quick renew button (shows when due soon or expired)
            if (showRenewBtn)
              GestureDetector(
                onTap: _renewing ? null : _quickRenew,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? AppTheme.kRed.withValues(alpha: 0.15)
                        : AppTheme.kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isExpired
                          ? AppTheme.kRed.withValues(alpha: 0.4)
                          : AppTheme.kGold.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: _renewing
                      ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isExpired ? AppTheme.kRed : AppTheme.kGold,
                    ),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.autorenew,
                          size: 13,
                          color: isExpired ? AppTheme.kRed : AppTheme.kGold),
                      const SizedBox(width: 4),
                      Text(
                        isExpired ? 'EXPIRED' : 'RENEW',
                        style: TextStyle(
                          color: isExpired ? AppTheme.kRed : AppTheme.kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (member.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.kGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${member.currentStreak}',
                      style: const TextStyle(
                          color: AppTheme.kGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: c.text3, size: 18),
          ],
        ),
      ),
    );
  }
}