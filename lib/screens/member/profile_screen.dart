import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/member_avatar.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/theme_provider.dart';
import '../../services/member_service.dart';
import '../../models/member_model.dart';
import '../auth/member_login_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final MemberSession session;
  const MemberProfileScreen({super.key, required this.session});
  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _editPhoto(String gymId, String memberId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.kCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading:
              const Icon(Icons.camera_alt_rounded, color: AppTheme.kAccent),
          title: const Text('Take a Photo'),
          onTap: () {
            Navigator.pop(context);
            _pickAndUpload(ImageSource.camera, gymId, memberId);
          },
        ),
        ListTile(
          leading:
              const Icon(Icons.photo_library_rounded, color: AppTheme.kAccent),
          title: const Text('Choose from Gallery'),
          onTap: () {
            Navigator.pop(context);
            _pickAndUpload(ImageSource.gallery, gymId, memberId);
          },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _pickAndUpload(
      ImageSource source, String gymId, String memberId) async {
    try {
      final picked = await _picker.pickImage(
          source: source,
          imageQuality: 75, maxWidth: 512, maxHeight: 512);
      if (picked == null) return;
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      final svc = MemberService();
      final url = await svc.uploadProfilePhotoBytes(gymId, memberId, bytes);
      if (mounted) {
        setState(() => _uploading = false);
        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload failed. Check Firebase Storage rules.'),
            backgroundColor: Colors.red,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Profile photo updated!'),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera
              ? 'Could not open the camera. Allow camera permission, then try again.'
              : 'Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final service = MemberService();
    final isDark = context.watch<ThemeProvider>().isDark;
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('My Profile',
            style: GoogleFonts.inter(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () async {
              await service.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MemberLoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: AppTheme.kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: StreamBuilder<MemberModel?>(
        stream: service.memberStream(session.gymId, session.memberId),
        builder: (_, snap) {
          final member = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // ── Avatar ─────────────────────────────────────────────
              const SizedBox(height: 20),
              Center(
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    StreamBuilder<String>(
                      stream: service.photoUrlStream(
                          session.gymId, session.memberId),
                      builder: (_, snap) => MemberAvatar(
                        photoUrl: snap.data ?? '',
                        initials: session.name.isNotEmpty
                            ? session.name[0].toUpperCase()
                            : 'M',
                        radius: 45,
                        ringColor: AppTheme.kAccent,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editPhoto(session.gymId, session.memberId),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.kAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.bg, width: 2),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.edit,
                                color: Colors.white, size: 14),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(session.name,
                      style: GoogleFonts.inter(
                          color: scheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('ID: ${session.memberId}',
                      style: const TextStyle(
                          color: AppTheme.kAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(session.email,
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Stats row ──────────────────────────────────────────
              if (member != null) ...[
                Row(children: [
                  Expanded(
                      child: _StatBox('Points', '${member.totalPoints}',
                          AppTheme.kAccent, isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatBox('Visits', '${member.totalAttendance}',
                          AppTheme.kAccent, isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatBox('Streak', '${member.currentStreak}d',
                          AppTheme.kAccent, isDark)),
                ]),
                const SizedBox(height: 20),

                // ── Member details ──────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  children: [
                    _InfoRow(
                        Icons.fitness_center, 'Plan', member.planType, scheme),
                    _divider(isDark),
                    _InfoRow(Icons.currency_rupee_rounded, 'Fee',
                        member.feeLabel, scheme),
                    _divider(isDark),
                    _InfoRow(
                        Icons.calendar_today,
                        'Joined',
                        DateFormat('d MMM yyyy').format(member.joinDate),
                        scheme),
                    _divider(isDark),
                    _InfoRow(
                        Icons.schedule,
                        'Next Renewal',
                        DateFormat('d MMM yyyy')
                            .format(member.paymentCycleDate),
                        scheme),
                    _divider(isDark),
                    _InfoRow(
                      member.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      'Status',
                      member.isActive ? 'Active' : 'Inactive',
                      scheme,
                      valueColor:
                          member.isActive ? AppTheme.kGreen : AppTheme.kRed,
                    ),
                  ],
                ),
              ] else
                const Center(
                    child: CircularProgressIndicator(color: AppTheme.kAccent)),

              const SizedBox(height: 16),

              // ── Gym info ───────────────────────────────────────────
              _SectionCard(isDark: isDark, children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('GYM INFO',
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700)),
                ),
                _InfoRow(
                    Icons.business_rounded, 'Gym ID', session.gymId, scheme),
              ]),

              const SizedBox(height: 16),

              // ── Appearance ─────────────────────────────────────────
              _SectionCard(isDark: isDark, children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('APPEARANCE',
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700)),
                ),
                _ThemeToggle(isDark: isDark),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _divider(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(
            color: isDark ? AppTheme.kCardBorder : const Color(0xFFE0E0E0),
            height: 1),
      );
}

// ── Theme Toggle ─────────────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final tp = context.read<ThemeProvider>();
    final bgColor = isDark ? c.elevated : const Color(0xFFF0F4FF);
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol = isDark ? c.text2 : const Color(0xFF757575);
    final borderC = isDark ? c.border : const Color(0xFFDDE3F0);

    return GestureDetector(
      onTap: () {
        tp.toggle();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: borderC, width: 0.5),
          boxShadow: isDark
              ? AppTheme.cardShadow
              : const [
                  BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
        ),
        child: Row(children: [
          // Icon container
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.kAccentDim,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child)),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                color: AppTheme.kAccent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
                  style: TextStyle(color: subCol, fontSize: 12),
                ),
              ])),
          // Premium animated pill toggle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.kAccent : const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(15),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                          color: AppTheme.kAccent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isDark ? 24 : 2,
                top: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 1))
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SectionCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? c.card : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatBox(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? c.card : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: isDark
            ? AppTheme.cardShadow
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: isDark ? c.text3 : const Color(0xFF9E9E9E),
                fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, this.scheme,
      {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: scheme.onSurface.withValues(alpha: 0.4), size: 16),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: valueColor ?? scheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
