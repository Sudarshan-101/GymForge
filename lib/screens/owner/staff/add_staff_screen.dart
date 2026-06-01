import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/staff_model.dart';

class AddStaffScreen extends StatefulWidget {
  final String gymId;

  const AddStaffScreen({super.key, required this.gymId});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _staffIdCtrl = TextEditingController();
  final _specCtrl    = TextEditingController();

  String _role  = 'Trainer';
  String _shift = 'Full-Day';
  bool _loading = false;

  static const _roles  = ['Trainer', 'Manager', 'Receptionist', 'Cleaner'];
  static const _shifts = ['Morning', 'Evening', 'Full-Day'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _staffIdCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
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

  String? _validateStaffId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Staff ID is required';
    if (v.trim().length < 2) return 'ID must be at least 2 characters';
    if (v.contains(' ')) return 'No spaces allowed in ID';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final staffId = _staffIdCtrl.text.trim().toUpperCase();

    final exists = await _service.staffIdExists(widget.gymId, staffId);
    if (exists) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Staff ID "$staffId" already exists. Choose a different ID.');
      }
      return;
    }

    try {
      final staff = StaffModel(
        id: staffId,
        staffId: staffId,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        phone: _phoneCtrl.text.trim(),
        gymId: widget.gymId,
        role: _role,
        shift: _shift,
        joinDate: DateTime.now(),
        specialization: _specCtrl.text.trim().isNotEmpty
            ? _specCtrl.text.trim()
            : null,
      );

      await _service.addStaff(staff);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('${staff.name} added to staff!'),
              ],
            ),
            backgroundColor: AppTheme.kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to add staff member. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.kRed),
    );
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
          'Add Staff Member',
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
            _staffIdField(),
            const SizedBox(height: 28),
            _sectionLabel('ROLE & SCHEDULE'),
            const SizedBox(height: 12),
            _roleSelector(),
            const SizedBox(height: 12),
            _shiftSelector(),
            const SizedBox(height: 12),
            _textField(
              controller: _specCtrl,
              label: 'Specialization (optional)',
              icon: Icons.fitness_center_outlined,
              hintText: 'e.g. Strength Training, Cardio',
            ),
            const SizedBox(height: 32),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

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

  Widget _staffIdField() {
    final c = GFColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _staffIdCtrl,
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
            labelText: 'Staff ID',
            hintText: 'e.g. STF001',
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
          validator: _validateStaffId,
        ),
        const SizedBox(height: 5),
        Text(
          'Letters and numbers only. Members use this to identify staff.',
          style: TextStyle(color: c.text3, fontSize: 11),
        ),
      ],
    );
  }

  Widget _roleSelector() {
    final c = GFColors(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map((role) {
        final isSelected = _role == role;
        return GestureDetector(
          onTap: () => setState(() => _role = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.kPrimary : c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.kPrimary
                    : c.border,
              ),
            ),
            child: Text(
              role,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : c.text2,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _shiftSelector() {
    final c = GFColors(context);
    return Row(
      children: List.generate(_shifts.length, (i) {
        final shift = _shifts[i];
        final isSelected = _shift == shift;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _shift = shift),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin:
                  EdgeInsets.only(right: i < _shifts.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.kPrimary : c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.kPrimary
                      : c.border,
                ),
              ),
              child: Text(
                shift,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : c.text2,
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
        label: Text(_loading ? 'Adding…' : 'Add Staff Member'),
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
