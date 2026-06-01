import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/owner/owner_shell.dart';
import 'register_screen.dart';
import 'member_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl= TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth     = AuthService();
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final res = await _auth.signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OwnerShell()));
    } else {
      setState(() => _error = res['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.kAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 16)],
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 12),
                Text('GYMFORGE',
                  style: GoogleFonts.inter(color: AppTheme.kAccent, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: 3)),
              ]),
              const SizedBox(height: 48),
              Text('Gym Owner', style: TextStyle(color: c.text2, fontSize: 14)),
              Text('Sign In', style: TextStyle(color: c.text1,
                fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(children: [
                  _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    }),
                  const SizedBox(height: 14),
                  _field(_passCtrl, 'Password', Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: c.text3, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => v!.length < 6 ? 'Password too short' : null),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.kRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.kRed, size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.kRed, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 28),
              NeonButton(label: 'SIGN IN', loading: _loading, onTap: _signIn),
              const SizedBox(height: 36),
              const _Divider(label: 'NEW OWNER?'),
              const SizedBox(height: 20),
              // Create Owner Account button
              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('CREATE GYM ACCOUNT',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
              const _Divider(label: 'GYM MEMBER?'),
              const SizedBox(height: 20),
              // Member login — same style button as owner
              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemberLoginScreen())),
                  icon: const Icon(Icons.fitness_center_rounded, size: 18),
                  label: Text('MEMBER LOGIN',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.text1,
                    side: BorderSide(color: c.border, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType? keyboard, bool obscure = false, Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final c = GFColors(context);
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: TextStyle(color: c.text1, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Row(children: [
      Expanded(child: Divider(color: c.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: TextStyle(color: c.text3, fontSize: 11, letterSpacing: 1)),
      ),
      Expanded(child: Divider(color: c.border)),
    ]);
  }
}
