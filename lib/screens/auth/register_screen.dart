import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // 0 = role select, 1 = owner form
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _gymNameCtrl = TextEditingController();
  final _gymAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  final _authService = AuthService();
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _gymNameCtrl.dispose();
    _gymAddressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _selectRole() {
    setState(() => _step = 1);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _authService.registerOwner(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      gymName: _gymNameCtrl.text.trim(),
      gymAddress: _gymAddressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      // Sign out after registration → redirect to login
      await _authService.signOut();
      if (!mounted) return;
      _showSuccessDialog(result['gymId']);
    } else {
      setState(() => _error = result['error']);
    }
  }

  void _showSuccessDialog(String gymId) {
    final c = GFColors(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.kAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.kAccent, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Registration Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.text1, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Gym ID has been created:',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.text2, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.4)),
              ),
              child: Text(
                gymId,
                style: GoogleFonts.inter(
                  color: AppTheme.kPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this Gym ID with your members so they can register.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.text2, fontSize: 12),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('GO TO SIGN IN'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 20),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
              _animCtrl.reset();
              _animCtrl.forward();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _step == 0 ? 'CREATE ACCOUNT' : 'GYM OWNER DETAILS',
          style: GoogleFonts.inter(
            color: c.text1,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: _step == 0 ? _buildRoleSelector() : _buildOwnerForm(),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final c = GFColors(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Account',
              style: TextStyle(color: c.text2, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Register Your Gym',
              style: TextStyle(
                  color: c.text1, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(
            'Create your gym account to manage members, track attendance, and grow your business.',
            style: TextStyle(color: c.text2, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 48),
          _RoleCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Gym Owner',
            subtitle:
                'Manage members, track attendance\nand grow your business.',
            glowColor: AppTheme.kAccent,
            onTap: _selectRole,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: c.text3, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Are you a member? Use "Member Login" on the sign in screen. Your gym owner provides your Member ID and Gym ID.',
                  style: TextStyle(color: c.text2, fontSize: 12, height: 1.5),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PERSONAL INFO'),
            const SizedBox(height: 14),
            _buildField(_nameCtrl, 'Full Name', Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _buildField(_emailCtrl, 'Email Address', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress, validator: (v) {
              if (v!.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            }),
            const SizedBox(height: 14),
            _buildField(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _buildField(_passCtrl, 'Password', Icons.lock_outline,
                obscure: _obscure,
                toggleObscure: () => setState(() => _obscure = !_obscure),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                }),
            const SizedBox(height: 14),
            _buildField(
                _confirmPassCtrl, 'Confirm Password', Icons.lock_outline,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                }),
            const SizedBox(height: 28),
            _sectionLabel('GYM DETAILS'),
            const SizedBox(height: 14),
            _buildField(_gymNameCtrl, 'Gym Name', Icons.business_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _buildField(
                _gymAddressCtrl, 'Gym Address', Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.kRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.kRed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.kRed, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            GlowBox(
              glowColor: AppTheme.kPrimary,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'CREATE MY GYM',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.kPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    final c = GFColors(context);
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: c.text1),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: c.text2,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color glowColor;
  final VoidCallback onTap;
  final bool isSecondary;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.glowColor,
    required this.onTap, 
  }) : isSecondary = false;

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GlowBox(
      glowColor: glowColor,
      blurRadius: 15,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSecondary ? c.border : glowColor.withValues(alpha: 0.5),
              width: isSecondary ? 0.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: glowColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: glowColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.text1,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: c.text2,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: glowColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
