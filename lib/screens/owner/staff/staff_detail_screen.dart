import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/staff_model.dart';

class StaffDetailScreen extends StatefulWidget {
  final StaffModel staff;
  final String gymId;

  const StaffDetailScreen({super.key, required this.staff, required this.gymId});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final _firestoreService = FirestoreService();
  bool _toggling = false;

  Color get _roleColor {
    switch (widget.staff.role) {
      case 'Manager': return AppTheme.kGold;
      case 'Trainer': return AppTheme.kPrimary;
      case 'Receptionist': return AppTheme.kAccent;
      default: return AppTheme.kTextSecondary;
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _toggling = true);
    await _firestoreService.toggleStaffStatus(
      widget.gymId,
      widget.staff.id,
      !widget.staff.isActive,
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.staff.isActive
              ? '${widget.staff.name} deactivated'
              : '${widget.staff.name} activated',
        ),
        backgroundColor:
            widget.staff.isActive ? AppTheme.kRed : AppTheme.kGreen,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final s = widget.staff;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: c.surface,
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  gradient: c.isDark ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_roleColor.withValues(alpha: 0.15), c.surface],
                  ) : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.kAccent.withValues(alpha: 0.06), c.surface],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _roleColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          s.initials,
                          style: TextStyle(
                            color: _roleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.name,
                      style: GoogleFonts.inter(
                        color: c.text1,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick info row
                Row(
                  children: [
                    Expanded(
                      child: _QuickInfo(
                        label: 'Shift',
                        value: s.shift,
                        icon: Icons.access_time,
                        color: AppTheme.kAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickInfo(
                        label: 'Status',
                        value: s.isActive ? 'Active' : 'Inactive',
                        icon: s.isActive ? Icons.check_circle : Icons.cancel,
                        color: s.isActive ? AppTheme.kGreen : c.text3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickInfo(
                        label: 'Joined',
                        value: DateFormat('MMM yyyy').format(s.joinDate),
                        icon: Icons.calendar_today,
                        color: AppTheme.kGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Staff Information
                GFCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle('STAFF INFORMATION'),
                      const SizedBox(height: 14),
                      _infoRow(Icons.badge_outlined, 'Staff ID', s.staffId,
                          valueColor: AppTheme.kAccent),
                      _divider(),
                      _infoRow(Icons.email_outlined, 'Email', s.email),
                      if (s.phone.isNotEmpty) ...[
                        _divider(),
                        _infoRow(Icons.phone_outlined, 'Phone', s.phone),
                      ],
                      _divider(),
                      _infoRow(Icons.work_outline, 'Role', s.role),
                      _divider(),
                      _infoRow(Icons.schedule, 'Shift', s.shift),
                      if (s.specialization != null &&
                          s.specialization!.isNotEmpty) ...[
                        _divider(),
                        _infoRow(Icons.fitness_center, 'Specialization',
                            s.specialization!),
                      ],
                      _divider(),
                      _infoRow(
                        Icons.calendar_month_outlined,
                        'Join Date',
                        DateFormat('d MMMM yyyy').format(s.joinDate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle status button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _toggling ? null : _toggleStatus,
                    icon: _toggling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.kRed),
                          )
                        : Icon(
                            s.isActive
                                ? Icons.person_off_outlined
                                : Icons.person_outline,
                            color:
                                s.isActive ? AppTheme.kRed : AppTheme.kGreen,
                            size: 18,
                          ),
                    label: Text(
                      s.isActive ? 'DEACTIVATE STAFF' : 'ACTIVATE STAFF',
                      style: GoogleFonts.inter(
                        color: s.isActive ? AppTheme.kRed : AppTheme.kGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: s.isActive
                            ? AppTheme.kRed.withValues(alpha: 0.4)
                            : AppTheme.kGreen.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(String text) {
    final c = GFColors(context);
    return Text(
        text,
        style: TextStyle(
          color: c.text2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ));
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    final c = GFColors(context);
    return Row(
      children: [
        Icon(icon, color: c.text3, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: c.text2, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? c.text1,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    final c = GFColors(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: c.border, height: 1));
  }
}

class _QuickInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(color: c.text3, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
