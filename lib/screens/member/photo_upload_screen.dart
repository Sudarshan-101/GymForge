
import 'package:flutter/foundation.dart';  // kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../services/member_service.dart';
import 'member_shell.dart';

/// Shown after first-time password setup.
/// Member can upload a profile photo or skip.
class PhotoUploadScreen extends StatefulWidget {
  final String gymId;
  final String memberId;
  final String memberName;
  const PhotoUploadScreen({
    super.key,
    required this.gymId,
    required this.memberId,
    required this.memberName,
  });
  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final _service = MemberService();
  final _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source,
          imageQuality: 75,
          maxWidth: 512,
          maxHeight: 512);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = source == ImageSource.camera
          ? 'Could not open the camera. Allow camera permission, then try again.'
          : 'Could not pick image. Try again.');
    }
  }

  Future<void> _upload() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() { _uploading = true; _error = null; });

    final mime = _detectMime(bytes);
    final url = await _service.uploadProfilePhotoBytes(
        widget.gymId, widget.memberId, bytes, contentType: mime);

    setState(() => _uploading = false);
    if (url == null) {
      setState(() => _error =
          'Upload failed. Check your connection or Firebase Storage rules.');
      return;
    }
    _goHome();
  }

  /// Detect MIME from magic bytes — avoids mislabelling PNG as jpeg.
  String _detectMime(Uint8List b) {
    if (b.length >= 4 &&
        b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length >= 4 && b[0] == 0x52 && b[1] == 0x49 &&
        b[2] == 0x46 && b[3] == 0x46 && b.length > 12 &&
        b[8] == 0x57 && b[9] == 0x45) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  void _goHome() {
    if (!mounted) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppTheme.kBg               : const Color(0xFFF5F5F5);
    final card = isDark ? AppTheme.kCard              : Colors.white;
    final text1= isDark ? AppTheme.kTextPrimary       : const Color(0xFF212121);
    final text2= isDark ? AppTheme.kTextSecondary     : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.kAccentDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded,
                    color: AppTheme.kAccent, size: 34),
              ),
              const SizedBox(height: 20),
              Text('Add a Profile Photo',
                  style: GoogleFonts.inter(
                      color: text1, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Let your gym mates see who you are on the leaderboard!',
                textAlign: TextAlign.center,
                style: TextStyle(color: text2, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),

              // Preview circle
              GestureDetector(
                onTap: _showPicker,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card,
                    border: Border.all(
                        color: _image != null
                            ? AppTheme.kAccent
                            : AppTheme.kCardBorder,
                        width: 2.5),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipOval(
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover,
                            gaplessPlayback: true)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: text2, size: 36),
                              const SizedBox(height: 6),
                              Text('Tap to choose',
                                  style: TextStyle(color: text2, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              if (_image == null) ...[
                _ActionBtn(
                  icon: Icons.photo_camera_rounded,
                  label: 'Take a Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _ActionBtn(
                  icon: Icons.photo_library_rounded,
                  label: kIsWeb ? 'Choose Photo' : 'Choose from Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _upload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(_uploading ? 'Uploading…' : 'Save Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _image = null; _imageBytes = null; _error = null;
                  }),
                  child: Text('Choose different photo',
                      style: TextStyle(color: text2)),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.kRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.kRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.kRed, fontSize: 13)),
                ),
              ],

              const Spacer(),
              TextButton(
                onPressed: _uploading ? null : _goHome,
                child: Text('Skip for now',
                    style: TextStyle(
                        color: text2, fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.kCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.kAccent),
            title: const Text('Take a Photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppTheme.kAccent),
            title: const Text('Choose from Gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: AppTheme.kAccent),
          label: Text(label,
              style: const TextStyle(
                  color: AppTheme.kAccent, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppTheme.kAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}
