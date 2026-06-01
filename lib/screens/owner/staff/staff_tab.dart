import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/staff_model.dart';
import 'add_staff_screen.dart';
import 'staff_detail_screen.dart';

class StaffTab extends StatefulWidget {
  final String gymId;
  const StaffTab({super.key, required this.gymId});

  @override
  State<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<StaffTab> {
  final _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StaffModel> _filter(List<StaffModel> staff) {
    if (_query.isEmpty) return staff;
    return staff
        .where((s) =>
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.staffId.toLowerCase().contains(_query.toLowerCase()) ||
            s.role.toLowerCase().contains(_query.toLowerCase()))
        .toList();
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
          'STAFF',
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
                color: AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add, color: AppTheme.kAccent, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddStaffScreen(gymId: widget.gymId),
              ));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: c.text1),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name, ID or role...',
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
          ),
        ),
      ),
      body: StreamBuilder<List<StaffModel>>(
        stream: _firestoreService.staffStream(widget.gymId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.kPrimary));
          }

          final allStaff = snap.data ?? [];
          final filtered = _filter(allStaff);

          if (allStaff.isEmpty) {
            return _buildEmptyState(context);
          }

          if (filtered.isEmpty) {
            return Center(
              child: Text('No staff found',
                  style: TextStyle(color: c.text2)),
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
                      '${filtered.length} staff member${filtered.length != 1 ? 's' : ''}',
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
                  itemBuilder: (ctx, i) =>
                      _StaffListTile(staff: filtered[i], gymId: widget.gymId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final c = GFColors(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.kAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined,
                color: AppTheme.kAccent, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No Staff Yet',
            style: TextStyle(
                color: c.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add trainers and staff members',
            style: TextStyle(color: c.text2, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddStaffScreen(gymId: widget.gymId),
              ));
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('ADD STAFF MEMBER'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kAccent),
          ),
        ],
      ),
    );
  }
}

class _StaffListTile extends StatelessWidget {
  final StaffModel staff;
  final String gymId;

  const _StaffListTile({required this.staff, required this.gymId});

  Color get _roleColor {
    switch (staff.role) {
      case 'Manager':
        return AppTheme.kGold;
      case 'Trainer':
        return AppTheme.kPrimary;
      case 'Receptionist':
        return AppTheme.kAccent;
      default:
        return AppTheme.kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StaffDetailScreen(staff: staff, gymId: gymId),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: _roleColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Center(
                child: Text(
                  staff.initials,
                  style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID: ${staff.staffId}',
                    style: TextStyle(
                        color: c.text3, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    staff.role,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.shift,
                  style: TextStyle(
                      color: c.text3, fontSize: 10),
                ),
              ],
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
