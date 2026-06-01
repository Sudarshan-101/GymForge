import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class DebugScreen extends StatefulWidget {
  final String gymId;
  const DebugScreen({super.key, required this.gymId});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _uid = '';
  String _testResult = 'Tap the button to test';
  Color  _testColor = AppTheme.kTextSecondary;
  bool   _testing    = false;

  static const _rulesText =
      'rules_version = \'2\';\n'
      'service cloud.firestore {\n'
      '  match /databases/{database}/documents {\n'
      '    match /{document=**} {\n'
      '      allow read, write: if request.auth != null;\n'
      '    }\n'
      '    match /gyms/{gymId}/members/{memberId} {\n'
      '      allow read: if true;\n'
      '    }\n'
      '  }\n'
      '}';

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? 'Not logged in';
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = 'Testing…'; _testColor = AppTheme.kTextSecondary; });
    try {
      await _db
          .collection('gyms')
          .doc(widget.gymId)
          .collection('announcements')
          .add({
        'message': '__test__',
        'sentBy': 'debug',
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _testResult = '✅ SUCCESS!\nFirestore is working. Announcements and staff will save correctly now.';
        _testColor  = AppTheme.kGreen;
        _testing    = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ STILL BLOCKED\n\nThe rules are not deployed yet.\nPaste the rules shown below into Firebase Console.';
        _testColor  = AppTheme.kRed;
        _testing    = false;
      });
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.kGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Connection Test',
            style: GoogleFonts.inter(
                color: c.text1, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Info cards ────────────────────────────────────────
          _infoTile('Your UID', _uid),
          const SizedBox(height: 10),
          _infoTile('Your Gym ID', widget.gymId),
          const SizedBox(height: 24),

          // ── Test button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_testing ? 'Testing…' : 'Test Firestore Connection'),
            ),
          ),
          const SizedBox(height: 12),

          // ── Test result ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _testColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _testColor.withValues(alpha: 0.3)),
            ),
            child: Text(_testResult,
                style: TextStyle(color: _testColor, fontSize: 13, height: 1.6)),
          ),
          const SizedBox(height: 28),

          // ── Firebase Console instructions ──────────────────────
          _sectionTitle('Fix rules via Firebase Console (no commands needed)'),
          const SizedBox(height: 12),
          _stepCard('1', 'Open this link in your browser',
              child: GestureDetector(
                onTap: () => _copy(
                    'https://console.firebase.google.com/project/gymforge-f9fe3/firestore/rules'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, color: AppTheme.kPrimary, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'console.firebase.google.com → gymforge-f9fe3 → Firestore → Rules',
                          style: TextStyle(
                              color: AppTheme.kPrimary, fontSize: 12, height: 1.4),
                        ),
                      ),
                      Icon(Icons.copy, color: AppTheme.kPrimary, size: 14),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 10),
          _stepCard('2', 'Delete everything in the Rules editor and paste this:',
              child: GestureDetector(
                onTap: () => _copy(_rulesText),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.text1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _rulesText,
                          style: GoogleFonts.sourceCodePro(
                              color: Colors.white, fontSize: 11, height: 1.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, color: Colors.white60, size: 16),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 10),
          _stepCard('3', 'Click the blue "Publish" button in Firebase Console', child: const SizedBox.shrink()),
          const SizedBox(height: 10),
          _stepCard('4', 'Come back and tap "Test Firestore Connection" above', child: const SizedBox.shrink()),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: c.text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.sourceCodePro(
                        color: c.text1,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copy(value),
            child: Icon(Icons.copy, color: c.text3, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final c = GFColors(context);
    return Text(text,
        style: TextStyle(
            color: c.text1,
            fontWeight: FontWeight.w700,
            fontSize: 15));
  }

  Widget _stepCard(String step, String title, {required Widget child}) {
    final c = GFColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(step,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: c.text1,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          if (child is! SizedBox || (child).height != 0) ...[
            const SizedBox(height: 10),
            child,
          ],
        ],
      ),
    );
  }
}
