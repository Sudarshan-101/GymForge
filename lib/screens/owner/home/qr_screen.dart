import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

class QRScreen extends StatefulWidget {
  final String gymId;
  final String gymName;

  const QRScreen({super.key, required this.gymId, required this.gymName});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Timer? _timer;
  String _expiryDisplay = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _updateExpiry();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateExpiry());
  }

  void _updateExpiry() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final midnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final diff = midnight.difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (mounted) setState(() => _expiryDisplay = '${h}h ${m}m');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // QR payload: gymforge_checkin:{gymId}:{YYYY-MM-DD} — valid for current day only
  String get _qrData {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'gymforge_checkin:${widget.gymId}:$today';
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final isDark = c.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: c.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Membership QR',
            style: GoogleFonts.inter(
                color: c.text1, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(children: [
              _buildQRCard(c, isDark),
              const SizedBox(height: 20),
              _buildDailyCodeCard(c),
              const SizedBox(height: 20),
              _buildInfoSection(c),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCard(GFColors c, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
              : [Colors.white, const Color(0xFFF8F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kAccent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: AppTheme.kAccent.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(children: [
        // Gym header row
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppTheme.kAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.fitness_center_rounded,
                color: AppTheme.kAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(widget.gymName,
                style: GoogleFonts.inter(
                    color: c.text1, fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text('ID: ${widget.gymId}',
                style: TextStyle(color: c.text3, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppTheme.kGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppTheme.kGreen, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Active',
                  style: TextStyle(
                      color: AppTheme.kGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),

        const SizedBox(height: 24),

        // QR Code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square, color: Color(0xFF4F46E5)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1C1C2E)),
          ),
        ),

        const SizedBox(height: 14),

        // Expiry indicator
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.access_time_rounded, color: c.text3, size: 14),
          const SizedBox(width: 5),
          Text('Valid today · Expires in $_expiryDisplay',
              style: TextStyle(color: c.text3, fontSize: 12)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () { _updateExpiry(); _fadeCtrl.forward(from: 0.7); },
            child: const Icon(Icons.refresh_rounded,
                color: AppTheme.kAccent, size: 16),
          ),
        ]),

        const SizedBox(height: 14),
        Divider(height: 1, color: c.border),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.kAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.gymId,
            style: GoogleFonts.sourceCodePro(
                color: AppTheme.kAccent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
      ]),
    );
  }

  Widget _buildDailyCodeCard(GFColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.key_rounded,
                color: AppTheme.kAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text("Today's Check-In Code",
                style: GoogleFonts.inter(
                    color: c.text1, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('Auto-generated daily · Expires at midnight',
                style: TextStyle(color: c.text3, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.kAccentDim,
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_rounded,
                  color: AppTheme.kAccent, size: 11),
              const SizedBox(width: 4),
              Text(_expiryDisplay,
                  style: const TextStyle(
                      color: AppTheme.kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: c.elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.kAccent.withValues(alpha: 0.2))),
          child: Text(_qrData,
              style: GoogleFonts.sourceCodePro(
                  color: c.text1, fontSize: 11, letterSpacing: 0.4)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  color: AppTheme.kAccent,
                  onTap: _copyCode)),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: const Color(0xFF7C4DFF),
                  onTap: _copyCode)),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  color: AppTheme.kGreen,
                  onTap: () => setState(_updateExpiry))),
        ]),
      ]),
    );
  }

  Widget _buildInfoSection(GFColors c) {
    return Column(children: [
      const _InfoRow(
          icon: Icons.autorenew_rounded,
          color: AppTheme.kGreen,
          text: 'QR auto-updates daily at midnight — no manual action needed'),
      const SizedBox(height: 10),
      const _InfoRow(
          icon: Icons.qr_code_scanner_rounded,
          color: AppTheme.kAccent,
          text:
              'Members scan this from their GymForge app or enter the code manually'),
      const SizedBox(height: 10),
      const _InfoRow(
          icon: Icons.lock_clock_rounded,
          color: Color(0xFFFF7043),
          text:
              'Each code is valid only for today — cannot be reused on another date'),
      const SizedBox(height: 10),
      const _InfoRow(
          icon: Icons.bar_chart_rounded,
          color: AppTheme.kAccent,
          text: 'Each scan records attendance automatically in your dashboard'),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.kGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.kGold.withValues(alpha: 0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.lightbulb_rounded, color: AppTheme.kGold, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Print this QR and display it at your gym entrance for easy check-in.',
              style: TextStyle(
                  color: AppTheme.kGold, fontSize: 12, height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(text,
              style: TextStyle(color: c.text2, fontSize: 13, height: 1.4)),
        ),
      ),
    ]);
  }
}
