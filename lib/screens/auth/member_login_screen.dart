import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/member_service.dart';
import '../member/member_shell.dart';
import '../member/photo_upload_screen.dart';

/// Multi-step member login:
/// Step 1 → Gym ID + Member ID + Email   (identity verification)
/// Step 2a → Password                    (if password already set)
/// Step 2b → Set Password + Confirm      (first-time login)
class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});
  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen>
    with SingleTickerProviderStateMixin {
  final _service = MemberService();

  // Step controllers
  final _gymCtrl     = TextEditingController();
  final _memberCtrl  = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _pass2Ctrl   = TextEditingController();

  int  _step       = 1;   // 1=identity, 2a=password, 2b=set-password
  bool _loading    = false;
  bool _obscure1   = true;
  bool _obscure2   = true;
  bool _hasPassword = false;
  String? _error;

  // Data carried from step 1 → step 2
  String? _verifiedGymId;
  String? _verifiedMemberId;
  Map<String, dynamic>? _memberData;

  // Slide animation
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _gymCtrl.dispose(); _memberCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose(); _slideCtrl.dispose();
    super.dispose();
  }

  void _animateToNextStep(int step) {
    _slideCtrl.reset();
    setState(() { _step = step; _error = null; });
    _slideCtrl.forward();
  }

  // ── Step 1 submit: verify identity ──────────────────────────────────────
  Future<void> _verifyIdentity() async {
    final gym    = _gymCtrl.text.trim();
    final member = _memberCtrl.text.trim().toUpperCase();
    final email  = _emailCtrl.text.trim();

    if (gym.isEmpty || member.isEmpty || email.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await _service.verifyIdentity(
        gymId: gym, memberId: member, email: email);
    setState(() => _loading = false);

    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _error = res['error']);
      return;
    }

    _verifiedGymId    = res['gymId'];
    _verifiedMemberId = res['memberId'];
    _memberData       = res['data'];
    _hasPassword      = res['hasPassword'] == true;

    _animateToNextStep(_hasPassword ? 2 : 3);
  }

  // ── Step 2 submit: login with existing password ──────────────────────────
  Future<void> _loginWithPassword() async {
    final pass = _passCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await _service.loginWithPassword(
      gymId:      _verifiedGymId!,
      memberId:   _verifiedMemberId!,
      password:   pass,
      memberData: _memberData!,
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _error = res['error']);
      return;
    }
    _goHome();
  }

  // ── Step 3 submit: set new password ─────────────────────────────────────
  Future<void> _setPassword() async {
    final pass  = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;

    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != pass2) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await _service.setPasswordAndLogin(
      gymId:      _verifiedGymId!,
      memberId:   _verifiedMemberId!,
      password:   pass,
      memberData: _memberData!,
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _error = res['error']);
      return;
    }
    // First-time login → ask for profile photo
    _goToPhotoUpload();
  }

  void _goToPhotoUpload() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => PhotoUploadScreen(
          gymId:      _verifiedGymId!,
          memberId:   _verifiedMemberId!,
          memberName: _memberData?['name'] ?? '',
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MemberShell(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideCtrl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: _body(),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topBar() {
    final c = GFColors(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        if (_step > 1)
          GestureDetector(
            onTap: () => _animateToNextStep(1),
            child: Icon(Icons.arrow_back_ios_new,
                color: c.text1, size: 18),
          )
        else
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios_new,
                color: c.text1, size: 18),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_stepTitle(), style: GoogleFonts.inter(
                color: c.text1, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            // Step indicator
            Row(children: List.generate(3, (i) {
              final active = i < _step;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.kAccent : c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            })),
          ]),
        ),
      ]),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 2: return 'Enter Password';
      case 3: return 'Create Password';
      default: return 'Verify Identity';
    }
  }

  Widget _body() {
    switch (_step) {
      case 2: return _passwordStep();
      case 3: return _setPasswordStep();
      default: return _identityStep();
    }
  }

  // ── Step 1: Identity ───────────────────────────────────────────────────
  Widget _identityStep() {
    final c = GFColors(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _logo(),
      const SizedBox(height: 32),
      Text('Welcome Back',
          style: GoogleFonts.inter(color: c.text2, fontSize: 14)),
      const SizedBox(height: 4),
      Text('Member Login',
          style: GoogleFonts.inter(
              color: c.text1, fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Enter your gym credentials to continue.',
          style: TextStyle(color: c.text2, fontSize: 13)),
      const SizedBox(height: 32),
      _field(_gymCtrl,    'Gym ID',        'gym_abc12345',      Icons.business_rounded),
      const SizedBox(height: 14),
      _field(_memberCtrl, 'Member ID',     'e.g. MBR001',       Icons.badge_rounded,
          caps: TextCapitalization.characters,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(12)]),
      const SizedBox(height: 14),
      _field(_emailCtrl,  'Email Address', 'your@email.com',    Icons.email_rounded,
          keyboard: TextInputType.emailAddress),
      if (_error != null) _errorBox(),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity,
          child: AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onTap: _verifyIdentity,
          )),
      const SizedBox(height: 24),
      Center(child: Text(
          'Your Gym ID and Member ID are provided by your gym owner.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.text3, fontSize: 11, height: 1.6))),
    ]);
  }

  // ── Step 2: Enter existing password ───────────────────────────────────
  Widget _passwordStep() {
    final c = GFColors(context);
    final name = (_memberData?['name'] as String? ?? '').split(' ').first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _logo(),
      const SizedBox(height: 32),
      Text('Hi, $name 👋',
          style: GoogleFonts.inter(
              color: AppTheme.kAccent, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Enter your password to access your dashboard.',
          style: TextStyle(color: c.text2, fontSize: 13)),
      const SizedBox(height: 8),
      _identityChip(),
      const SizedBox(height: 28),
      _passField(_passCtrl, 'Password', _obscure1,
              () => setState(() => _obscure1 = !_obscure1)),
      if (_error != null) _errorBox(),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity,
          child: AppButton(
            label: 'Sign In',
            icon: Icons.login_rounded,
            loading: _loading,
            onTap: _loginWithPassword,
          )),
    ]);
  }

  // ── Step 3: Set new password ──────────────────────────────────────────
  Widget _setPasswordStep() {
    final c = GFColors(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _logo(),
      const SizedBox(height: 32),
      // First-time badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.kAccentDim,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.4)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, color: AppTheme.kAccent, size: 14),
          SizedBox(width: 6),
          Text('First Time Login', style: TextStyle(
              color: AppTheme.kAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Create Your Password',
          style: GoogleFonts.inter(
              color: c.text1, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Set a secure password for future logins.\nYou\'ll use this every time you sign in.',
          style: TextStyle(color: c.text2, fontSize: 13, height: 1.5)),
      const SizedBox(height: 8),
      _identityChip(),
      const SizedBox(height: 28),
      _passField(_passCtrl,  'New Password',     _obscure1,
              () => setState(() => _obscure1 = !_obscure1)),
      const SizedBox(height: 14),
      _passField(_pass2Ctrl, 'Confirm Password', _obscure2,
              () => setState(() => _obscure2 = !_obscure2)),
      const SizedBox(height: 6),
      Text('Minimum 6 characters.',
          style: TextStyle(color: c.text3, fontSize: 11)),
      if (_error != null) _errorBox(),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity,
          child: AppButton(
            label: 'Set Password & Sign In',
            icon: Icons.lock_rounded,
            loading: _loading,
            onTap: _setPassword,
          )),
    ]);
  }

  // ── Shared widgets ─────────────────────────────────────────────────────
  Widget _logo() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: AppTheme.kAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 26),
    );
  }

  Widget _identityChip() {
    final c = GFColors(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        const Icon(Icons.verified_user_rounded, color: AppTheme.kGreen, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_verifiedGymId ?? ''} · ${_verifiedMemberId ?? ''}',
            style: TextStyle(color: c.text2, fontSize: 12),
          ),
        ),
        GestureDetector(
          onTap: () => _animateToNextStep(1),
          child: const Text('Change',
              style: TextStyle(color: AppTheme.kAccent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, String hint, IconData icon, {
        TextInputType? keyboard,
        TextCapitalization caps = TextCapitalization.none,
        List<TextInputFormatter>? formatters,
      }) {

    final c = GFColors(context);    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      inputFormatters: formatters,
      style: TextStyle(color: c.text1, fontSize: 15),
      cursorColor: AppTheme.kAccent,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: c.text2),
        hintStyle: TextStyle(color: c.text3),
        filled: true, fillColor: c.card,
        prefixIcon: Icon(icon, color: c.text3, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: const BorderSide(color: AppTheme.kAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {

    final c = GFColors(context);    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: c.text1, fontSize: 15),
      cursorColor: AppTheme.kAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.text2),
        filled: true, fillColor: c.card,
        prefixIcon: Icon(Icons.lock_rounded, color: c.text3, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: c.text3, size: 18),
          onPressed: toggle,
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: const BorderSide(color: AppTheme.kAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.kRedDim,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.kRed.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.kRed, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!,
              style: const TextStyle(color: AppTheme.kRed, fontSize: 13, height: 1.4))),
        ]),
      ),
    );
  }
}