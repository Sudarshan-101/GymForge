import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/member_model.dart';

class AddMemberScreen extends StatefulWidget {
  final String gymId;

  const AddMemberScreen({super.key, required this.gymId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _memberIdCtrl = TextEditingController();
  final _feeCtrl      = TextEditingController();

  String _planType = 'Monthly';
  DateTime _renewalDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _memberIdCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  void _onPlanChanged(String plan) {
    setState(() {
      _planType = plan;
      _renewalDate = DateTime.now().add(Duration(
        days: plan == 'Annual' ? 365 : plan == 'Quarterly' ? 90 : 30,
      ));
    });
  }

  String get _feeLabel {
    switch (_planType) {
      case 'Quarterly': return 'Quarterly Fee (₹)';
      case 'Annual':    return 'Annual Fee (₹)';
      default:          return 'Monthly Fee (₹)';
    }
  }

  String get _feeSuffix {
    switch (_planType) {
      case 'Quarterly': return '/qtr';
      case 'Annual':    return '/yr';
      default:          return '/mo';
    }
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Phone number must be exactly 10 digits';
    return null;
  }

  String? _validateMemberId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Member ID is required';
    if (v.trim().length < 2) return 'ID must be at least 2 characters';
    if (v.contains(' ')) return 'No spaces allowed in ID';
    return null;
  }

  String? _validateFee(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final val = double.tryParse(v.trim());
    if (val == null || val < 0) return 'Enter a valid amount';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final memberId = _memberIdCtrl.text.trim().toUpperCase();

    final exists = await _service.memberIdExists(widget.gymId, memberId);
    if (exists) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Member ID "$memberId" already exists. Choose a different ID.');
      }
      return;
    }

    try {
      final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;

      final member = MemberModel(
        id: memberId,
        memberId: memberId,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        phone: _phoneCtrl.text.trim(),
        gymId: widget.gymId,
        planType: _planType,
        planFee: fee,
        joinDate: DateTime.now(),
        paymentCycleDate: _renewalDate,
      );

      await _service.addMember(member);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('${member.name} added successfully!'),
              ],
            ),
            backgroundColor: AppTheme.kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to add member. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.kRed),
    );
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _renewalDate = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add New Member',
          style: GoogleFonts.inter(
            color: c.text1,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _infoBanner(),
            const SizedBox(height: 24),
            _sectionLabel('PERSONAL INFORMATION'),
            const SizedBox(height: 12),
            _textField(
              controller: _nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: _validateName,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _emailCtrl,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _phoneCtrl,
              label: 'Phone Number (optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validatePhone,
              hintText: '10-digit mobile number',
            ),
            const SizedBox(height: 12),
            _memberIdField(),
            const SizedBox(height: 28),
            _sectionLabel('MEMBERSHIP PLAN'),
            const SizedBox(height: 12),
            _planChips(),
            const SizedBox(height: 12),
            _feeField(),
            const SizedBox(height: 12),
            _datePicker(),
            const SizedBox(height: 32),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kPrimaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.kPrimary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The Member ID you set is used by the member to log in. Keep it simple — e.g. MBR001.',
              style: TextStyle(
                color: AppTheme.kPrimary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    final c = GFColors(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: c.text1, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Widget _memberIdField() {
    final c = GFColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _memberIdCtrl,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(12),
          ],
          style: GoogleFonts.inter(
            color: AppTheme.kPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            labelText: 'Member ID',
            hintText: 'e.g. MBR001',
            prefixIcon:
            const Icon(Icons.badge_outlined, color: AppTheme.kPrimary),
            labelStyle: const TextStyle(color: AppTheme.kPrimary),
            filled: true,
            fillColor: AppTheme.kPrimaryLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppTheme.kPrimary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppTheme.kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.kRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.kRed, width: 1.5),
            ),
          ),
          validator: _validateMemberId,
        ),
        const SizedBox(height: 5),
        Text(
          'Letters and numbers only, no spaces. E.g. MBR001',
          style: TextStyle(color: c.text3, fontSize: 11),
        ),
      ],
    );
  }

  Widget _planChips() {
    final c = GFColors(context);
    const plans = ['Monthly', 'Quarterly', 'Annual'];
    return Row(
      children: List.generate(plans.length, (i) {
        final plan = plans[i];
        final isSelected = _planType == plan;
        return Expanded(
          child: GestureDetector(
            onTap: () => _onPlanChanged(plan),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < plans.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.kPrimary : c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.kPrimary
                      : c.border,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppTheme.kPrimary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
                    : [],
              ),
              child: Text(
                plan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                  isSelected ? Colors.white : c.text2,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _feeField() {
    final c = GFColors(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // ₹ prefix box
          Container(
            width: 52,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.kGreenLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
            child: const Center(
              child: Text(
                '₹',
                style: TextStyle(
                  color: AppTheme.kAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // Amount input
          Expanded(
            child: TextFormField(
              controller: _feeCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: GoogleFonts.inter(
                color: c.text1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: _feeLabel,
                hintText: '0',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                fillColor: Colors.transparent,
                labelStyle:
                TextStyle(color: c.text2, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
              ),
              validator: _validateFee,
            ),
          ),
          // /mo suffix
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              _feeSuffix,
              style: TextStyle(
                color: c.text3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker() {
    final c = GFColors(context);
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.kPrimary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Renewal Date',
                    style: TextStyle(
                        color: c.text2, fontSize: 12),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy').format(_renewalDate),
                    style: TextStyle(
                      color: c.text1,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                color: c.text3, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _submit,
        icon: _loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.person_add_rounded, size: 20),
        label: Text(_loading ? 'Adding…' : 'Add Member'),
        style: ElevatedButton.styleFrom(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}