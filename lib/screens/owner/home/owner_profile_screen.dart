import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/login_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String gymId;
  final String ownerName;
  const OwnerProfileScreen({super.key, required this.gymId, required this.ownerName});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _auth      = AuthService();
  final _firestore = FirestoreService();
  Map<String, dynamic>? _gymData;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _firestore.getGym(widget.gymId);
    if (mounted) setState(() { _gymData = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final scheme = Theme.of(context).colorScheme;
    final bg     = c.bg;
    final textCol = isDark ? c.text1 : const Color(0xFF212121);
    final subCol  = isDark ? c.text2 : const Color(0xFF757575);
    final divCol  = isDark ? c.border : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Profile & Settings',
            style: GoogleFonts.inter(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.kAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                const SizedBox(height: 20),

                // ── Owner avatar ────────────────────────────────────
                Center(child: Column(children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.kAccentDim,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.kAccent, width: 2.5),
                      boxShadow: const [BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 20)],
                    ),
                    child: Center(child: Text(
                      widget.ownerName.isNotEmpty ? widget.ownerName[0].toUpperCase() : 'O',
                      style: const TextStyle(color: AppTheme.kAccent, fontSize: 36, fontWeight: FontWeight.w800),
                    )),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.ownerName,
                      style: GoogleFonts.inter(color: textCol, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Gym Owner', style: TextStyle(color: AppTheme.kAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(widget.gymId, style: TextStyle(color: subCol, fontSize: 12)),
                ])),
                const SizedBox(height: 28),

                // ── Gym Details ─────────────────────────────────────
                _SectionLabel('GYM DETAILS', subCol),
                const SizedBox(height: 10),
                _Card(isDark: isDark, children: [
                  _InfoRow(Icons.business_rounded, 'Gym Name',
                      _gymData?['gymName'] ?? 'My Gym', textCol, subCol),
                  _Divider(divCol),
                  _InfoRow(Icons.key_rounded, 'Gym ID', widget.gymId, textCol, subCol,
                      valueColor: AppTheme.kAccent),
                  _Divider(divCol),
                  _InfoRow(Icons.location_on_outlined, 'Address',
                      _gymData?['address'] ?? '—', textCol, subCol),
                  _Divider(divCol),
                  _InfoRow(Icons.phone_outlined, 'Phone',
                      _gymData?['phone'] ?? '—', textCol, subCol),
                  _Divider(divCol),
                  _InfoRow(Icons.calendar_today_outlined, 'Member Since',
                      _gymData?['createdAt'] != null
                          ? DateFormat('d MMM yyyy').format(
                              (_gymData!['createdAt'] as dynamic).toDate())
                          : '—',
                      textCol, subCol),
                ]),
                const SizedBox(height: 16),

                // ── Appearance ──────────────────────────────────────
                _SectionLabel('APPEARANCE', subCol),
                const SizedBox(height: 10),
                _Card(isDark: isDark, children: [
                  _ThemeToggle(isDark: isDark),
                ]),
                const SizedBox(height: 16),

                // ── Account ─────────────────────────────────────────
                _SectionLabel('ACCOUNT', subCol),
                const SizedBox(height: 10),
                _Card(isDark: isDark, children: [
                  _InfoRow(Icons.email_outlined, 'Email',
                      _gymData?['email'] ?? _auth.currentEmail ?? '—', textCol, subCol),
                ]),
                const SizedBox(height: 24),

                // Sign out button
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.kRed, size: 18),
                    label: const Text('Sign Out', style: TextStyle(color: AppTheme.kRed, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.kRed.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Theme Toggle ────────────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final tp     = context.read<ThemeProvider>();
    final textCol = isDark ? c.text1  : const Color(0xFF212121);
    final subCol  = isDark ? c.text2 : const Color(0xFF757575);

    return GestureDetector(
      onTap: () { tp.toggle(); HapticFeedback.selectionClick(); },
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 40, height: 40,
          decoration: const BoxDecoration(color: AppTheme.kAccentDim, shape: BoxShape.circle),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark), color: AppTheme.kAccent, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(color: textCol, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
              style: TextStyle(color: subCol, fontSize: 12)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 52, height: 30,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.kAccent : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(15),
            boxShadow: isDark ? [BoxShadow(
                color: AppTheme.kAccent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
              left: isDark ? 24 : 2, top: 2,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _Card({required this.children, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color textCol, subCol;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, this.textCol, this.subCol, {this.valueColor});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: subCol, size: 16),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: subCol, fontSize: 13)),
    const Spacer(),
    Flexible(child: Text(value, textAlign: TextAlign.end,
        style: TextStyle(color: valueColor ?? textCol, fontSize: 13, fontWeight: FontWeight.w600))),
  ]);
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider(this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(color: color, height: 1));
}
