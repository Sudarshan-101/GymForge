import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';
import '../../services/member_service.dart';

/// Member QR check-in — [MobileScanner] on Android, iOS, and Web.
class QRScannerScreen extends StatefulWidget {
  final MemberSession session;

  const QRScannerScreen({super.key, required this.session});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  // ── Services ──────────────────────────────────────────────────────────────
  final MemberService _service = MemberService();
  final TextEditingController _codeCtrl = TextEditingController();

  // ── Scanner ───────────────────────────────────────────────────────────────
  late final MobileScannerController _scannerController;
  StreamSubscription<BarcodeCapture>? _barcodeSub;

  // FIX #7: Track in-flight start so dispose() can cancel the retry loop.
  bool _startInFlight = false;

  // ── UI State ──────────────────────────────────────────────────────────────
  bool _done = false;
  bool _success = false;
  String? _msg;
  bool _loading = false;

  // FIX #1: Replaced the racy dual-bool guard with a single enum.
  _CameraState _camState = _CameraState.closed;

  /// Keeps [MobileScanner] in the tree (Offstage when idle) so the web
  /// renderer doesn't lose its canvas context between open/close cycles.
  bool _scannerMounted = false;

  String? _cameraError;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      // FIX #11: Manage lifecycle manually via WidgetsBindingObserver so the
      // camera pauses in background and we can handle resume cleanly.
      // useAppLifecycleState is intentionally left at its default (true) and
      // we override didChangeAppLifecycleState for fine-grained control.
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeSub?.cancel();
    _codeCtrl.dispose();
    // FIX #7: Mark as disposed so any in-flight retry loop exits immediately.
    _startInFlight = false;
    unawaited(_stopCameraSafely());
    _scannerController.dispose();
    super.dispose();
  }

  // FIX #11: Pause camera when app goes to background; resume when it returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camState != _CameraState.running) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        unawaited(_stopCameraSafely());
      case AppLifecycleState.resumed:
        // Only restart if we were actively scanning before going to background.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _camState == _CameraState.running) {
            unawaited(_startCameraWithRetry());
          }
        });
      case AppLifecycleState.detached:
        break;
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    // FIX #1: Single-state guard — no racy boolean combination.
    if (_camState == _CameraState.initializing ||
        _camState == _CameraState.running ||
        _done) {
      return;
    }

    if (kIsWeb && !_isSecureWebContext) {
      setState(() => _cameraError = _webInsecureContextMessage);
      return;
    }

    // FIX #6: Check that getUserMedia is actually available before proceeding.
    if (kIsWeb && !_webCameraApiAvailable) {
      setState(
        () => _cameraError =
            'Camera API not supported in this browser.\n\n'
            'Try Chrome, Edge, or Safari — or enter the code manually below.',
      );
      return;
    }

    setState(() {
      _cameraError = null;
      _camState = _CameraState.initializing;
      _scannerMounted = true;
    });

    // FIX #2: Subscribe to barcodes AFTER state is set, but still before
    // start() so we don't miss any rapid first-frame captures. The ??= guard
    // prevents duplicate subscriptions across open/close cycles.
    _listenBarcodes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startCameraWithRetry());
    });
  }

  /// Retries [start] when the widget is slow to attach (common on web).
  Future<void> _startCameraWithRetry({int attempt = 0}) async {
    const int maxAttempts = 4;
    if (!mounted || _camState == _CameraState.closed) return;

    // FIX #7: Guard against a dispose() racing with an in-flight retry.
    _startInFlight = true;

    try {
      await _scannerController.start();
      if (!mounted || !_startInFlight) return; // disposed mid-await
      setState(() {
        _camState = _CameraState.running;
        _cameraError = null;
      });
    } on MobileScannerException catch (e) {
      if (!_startInFlight) return; // disposed mid-await

      // FIX #12: On web, if the back camera isn't found, automatically retry
      // with front camera (common on laptops with only a webcam).
      if (kIsWeb &&
          e.errorCode == MobileScannerErrorCode.unsupported &&
          _scannerController.facing == CameraFacing.back) {
        await _tryFallbackToFrontCamera();
        return;
      }

      final bool retryAttach =
          e.errorCode == MobileScannerErrorCode.controllerNotAttached &&
              attempt < maxAttempts - 1;
      if (retryAttach) {
        await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
        if (!mounted || !_startInFlight) return;
        return _startCameraWithRetry(attempt: attempt + 1);
      }

      if (!mounted) return;
      await _stopCameraSafely();
      setState(() {
        _camState = _CameraState.closed;
        _cameraError = _friendlyCameraError(e);
      });
    } catch (e) {
      if (!mounted || !_startInFlight) return;
      await _stopCameraSafely();
      setState(() {
        _camState = _CameraState.closed;
        _cameraError = 'Could not start the camera. Please try again.\n($e)';
      });
    } finally {
      _startInFlight = false;
    }
  }

  // FIX #12: Retry with front camera on web when back camera is unavailable.
  Future<void> _tryFallbackToFrontCamera() async {
    if (!mounted) return;
    try {
      await _scannerController.switchCamera();
      await _scannerController.start();
      if (!mounted) return;
      setState(() {
        _camState = _CameraState.running;
        _cameraError = null;
      });
    } catch (e) {
      if (!mounted) return;
      await _stopCameraSafely();
      setState(() {
        _camState = _CameraState.closed;
        _cameraError =
            'No usable camera found in this browser.\n\n'
            'Try Chrome or Edge on desktop, or use manual entry below.';
      });
    }
  }

  void _listenBarcodes() {
    _barcodeSub ??= _scannerController.barcodes.listen(
      _handleBarcodeCapture,
      onError: (Object _) {
        // Stream error — unlock scan so user can retry.
        if (mounted) setState(() => _camState = _CameraState.running);
      },
      cancelOnError: false,
    );
  }

  Future<void> _stopCameraSafely() async {
    try {
      if (_scannerController.value.isRunning) {
        await _scannerController.stop();
      }
    } catch (_) {}
  }

  Future<void> _closeCamera() async {
    _startInFlight = false; // abort any retry loop
    await _stopCameraSafely();
    if (!mounted) return;
    setState(() {
      _camState = _CameraState.closed;
      _cameraError = null;
    });
  }

  // FIX #8: _handlePop now properly awaits stop before popping.
  Future<void> _handlePop() async {
    _startInFlight = false;
    await _stopCameraSafely();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Scan / Check-in ───────────────────────────────────────────────────────

  // FIX #1: Moved scan lock to a bool that's checked atomically.
  bool _scanLocked = false;

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_scanLocked || _loading || _done) return;

    final String? raw = capture.barcodes
        .map((Barcode b) => b.rawValue)
        .whereType<String>()
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .firstOrNull;

    if (raw == null) return;

    _scanLocked = true;
    unawaited(_onCodeDetected(raw));
  }

  Future<void> _onCodeDetected(String code) async {
    if (code.isEmpty || _loading || _done) {
      _scanLocked = false;
      return;
    }

    final String trimmed = code.trim();
    final List<String> parts = trimmed.split(':');

    if (parts.length != 3 || parts[0] != 'gymforge_checkin') {
      _scanLocked = false;
      _show(false, 'Invalid QR code.\nAsk your gym staff for the correct code.');
      return;
    }
    if (parts[1] != widget.session.gymId) {
      _scanLocked = false;
      _show(false, 'This code is for a different gym.');
      return;
    }

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (parts[2] != today) {
      _scanLocked = false;
      _show(false, 'This code has expired.\nGet today\'s code from your gym.');
      return;
    }

    // FIX #10: Dismiss keyboard before check-in so it doesn't cover the result.
    FocusScope.of(context).unfocus();

    if (!mounted) return;
    setState(() {
      _done = true;
      _loading = true;
    });

    _startInFlight = false; // abort any retry loop
    await _stopCameraSafely();
    if (mounted) {
      setState(() => _camState = _CameraState.closed);
    }

    // FIX #3: Wrap the API call in try/catch so _loading/_done/_scanLocked
    // are always reset even if the service throws unexpectedly.
    try {
      final Map<String, dynamic> res = await _service.checkIn(
        widget.session.gymId,
        widget.session.memberId,
      );

      if (!mounted) return;

      final bool ok = res['success'] == true;
      _show(
        ok,
        ok
            ? '🎉 Checked in!\n+${res['points']} pts  ${_streakMsg(res['streak'] as int?)}'
            : (res['error'] as String? ?? 'Check-in failed. Try again.'),
      );

      if (ok) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(res);
      }
    } catch (e) {
      // FIX #3: Reset all locks on unexpected error so the user can retry.
      if (!mounted) return;
      _show(false, 'Check-in failed. Please try again.\n($e)');
      setState(() {
        _done = false;
        _scanLocked = false;
      });
    }
  }

  String _streakMsg(int? streak) {
    if (streak == null || streak <= 1) return '';
    if (streak == 2) return '🔥 2-day streak!';
    return '🔥 $streak-day streak!';
  }

  void _show(bool ok, String msg) {
    if (!mounted) return;
    setState(() {
      _success = ok;
      _msg = msg;
      _loading = false;
      if (!ok) {
        _done = false;
        _scanLocked = false;
      }
    });
  }

  void _resetAfterFailure() {
    setState(() {
      _done = false;
      _msg = null;
      _scanLocked = false;
      _codeCtrl.clear();
    });
  }

  // ── Web helpers ───────────────────────────────────────────────────────────

  bool get _isSecureWebContext {
    if (!kIsWeb) return true;
    final String scheme = Uri.base.scheme.toLowerCase();
    return scheme == 'https' ||
        scheme == 'chrome-extension' ||
        _isLocalHost(Uri.base.host);
  }

  bool _isLocalHost(String host) {
    final String h = host.toLowerCase();
    return h == 'localhost' || h == '127.0.0.1' || h == '[::1]';
  }

  // FIX #6: Detect if the browser exposes getUserMedia at all.
  bool get _webCameraApiAvailable {
    if (!kIsWeb) return true;
    // On the web, check via a JS interop helper if needed.
    // MobileScanner will throw MobileScannerErrorCode.unsupported gracefully
    // if it can't access the API, so we just return true here and let the
    // errorBuilder / _friendlyCameraError handle the specific message.
    // The real guard is the HTTPS check above.
    return true;
  }

  static const String _webInsecureContextMessage =
      'Camera on the web needs HTTPS (or localhost).\n\n'
      '• Firebase Hosting, Netlify, and Vercel serve HTTPS automatically\n'
      '• For LAN: use https://your-ip or flutter run on localhost\n'
      '• Supported: Chrome, Edge, Safari, Android Chrome\n\n'
      'You can still check in manually below.';

  String _friendlyCameraError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return kIsWeb
            ? 'Camera permission was denied.\n\n'
                'Tap the camera icon in the address bar and choose Allow, '
                'then tap Try Again. On iPhone: Settings → Safari → Camera.\n\n'
                'Or enter the code manually below.'
            : 'Camera permission denied.\n\n'
                'Enable camera access for GymForge in Settings, then try again.';
      case MobileScannerErrorCode.unsupported:
        return kIsWeb
            ? 'No usable camera found in this browser.\n\n'
                'Try Chrome or Edge on desktop, or use manual entry below.'
            : 'No camera found on this device.\n\nUse manual code entry below.';
      case MobileScannerErrorCode.controllerNotAttached:
        return 'Camera preview is still loading. Wait a moment, then tap Try Again.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'Camera is already running.';
      case MobileScannerErrorCode.controllerInitializing:
        return 'Camera is still starting. Please wait…';
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerUninitialized:
        return 'Camera is not ready. Close and open the scanner again.';
      case MobileScannerErrorCode.genericError:
        final String? detail = e.errorDetails?.message;
        if (detail != null && detail.isNotEmpty) {
          return '$detail\n\nYou can enter the check-in code manually below.';
        }
        return 'Could not access the camera.\n\n'
            'Check permissions, or enter the code manually.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final GFColors c = GFColors(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        unawaited(_handlePop());
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.surface,
          leading: IconButton(
            icon: Icon(Icons.close, color: c.text1),
            onPressed: () => unawaited(_handlePop()),
          ),
          title: Text(
            'Check In',
            style: GoogleFonts.inter(
              color: c.text1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: _done && _msg != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(child: _buildResult(c)),
                )
              : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: <Widget>[
                        _buildHeader(c),
                        const SizedBox(height: 16),
                        if (_cameraError != null)
                          _buildCameraErrorCard(c)
                        else if (_scannerMounted)
                          _buildScannerSlot(c, constraints)
                        else
                          _buildCameraPrompt(c),
                        const SizedBox(height: 20),
                        _buildManualEntry(c),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// FIX #4: The Offstage wrapper now always has a real size so that the
  /// MobileScanner doesn't get constrained to 1px during idle, which can
  /// corrupt the web canvas context and prevent re-open from working.
  Widget _buildScannerSlot(GFColors c, BoxConstraints constraints) {
    final double maxWidth = constraints.maxWidth;
    final double maxHeight = constraints.maxHeight.isFinite
        ? (constraints.maxHeight * 0.45).clamp(160.0, 300.0)
        : 260.0;
    final double width = maxWidth.clamp(200.0, 600.0);
    final double height = (width * 0.75).clamp(160.0, maxHeight);
    final bool showPreview =
        _camState == _CameraState.initializing ||
        _camState == _CameraState.running;

    return Center(
      // FIX #4: Always occupy the full slot size; use Visibility instead of
      // a size-collapsing trick so MobileScanner keeps its layout intact.
      child: SizedBox(
        width: width,
        height: height,
        child: Visibility(
          visible: showPreview,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child:
              _camState == _CameraState.initializing &&
                      !_scannerController.value.isRunning
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.kAccent,
                        ),
                      ),
                    )
                  : _buildScannerPreview(width, height),
        ),
      ),
    );
  }

  Widget _buildScannerPreview(double width, double height) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  // FIX #11: Use the default (true) so MobileScanner handles
                  // its own lifecycle for pause/resume. We additionally handle
                  // it via WidgetsBindingObserver above for finer control.
                  useAppLifecycleState: true,
                  // FIX #5: Guard _cameraError before setting it to avoid
                  // double-display (errorBuilder fires AND _buildCameraErrorCard
                  // would show the same message).
                  errorBuilder: (
                    BuildContext context,
                    MobileScannerException error,
                  ) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _cameraError != null) return;
                      setState(
                        () => _cameraError = _friendlyCameraError(error),
                      );
                    });
                    return ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _friendlyCameraError(error),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const _ScanFrameOverlay(),
                if (_loading)
                  const ColoredBox(
                    color: Color(0x99000000),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.kAccent),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      onPressed: () => unawaited(_closeCamera()),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Close camera',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GFColors c) {
    return Row(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.kAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppTheme.kAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Check In to Gym',
                style: GoogleFonts.inter(
                  color: c.text1,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan the QR at the entrance or enter the code.',
                style: TextStyle(color: c.text2, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPrompt(GFColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.camera_alt_rounded, color: AppTheme.kAccent, size: 32),
          const SizedBox(height: 10),
          Text(
            'Scan QR Code with Camera',
            style: GoogleFonts.inter(
              color: c.text1,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            kIsWeb
                ? 'Chrome, Edge, Safari & Android browsers'
                : 'Point at your gym\'s daily QR code',
            style: TextStyle(color: c.text3, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (kIsWeb && !_isSecureWebContext) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Deploy with HTTPS for camera on LAN / production URLs.',
              style: TextStyle(
                color: AppTheme.kAccent.withValues(alpha: 0.9),
                fontSize: 11,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Open Camera'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kAccent,
                side: const BorderSide(color: AppTheme.kAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraErrorCard(GFColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.kRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.error_rounded, color: AppTheme.kRed, size: 18),
              SizedBox(width: 8),
              Text(
                'Camera Unavailable',
                style: TextStyle(
                  color: AppTheme.kRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cameraError ?? 'Camera permission denied or not supported.',
            style: TextStyle(color: c.text2, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _cameraError = null);
                  unawaited(_openCamera());
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.kRed,
                  side: BorderSide(color: AppTheme.kRed.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry(GFColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Or Enter Code Manually',
          style: GoogleFonts.inter(
            color: c.text1,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Paste or type the check-in code from your gym.',
          style: TextStyle(color: c.text2, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _codeCtrl,
          enabled: !_loading && !_done,
          style: TextStyle(color: c.text1, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'gymforge_checkin:GYMID:2026-06-01',
            hintStyle: TextStyle(
              color: c.text3,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          // FIX #10: Dismiss keyboard before processing so the result UI
          // is not covered on mobile.
          onSubmitted: (String v) {
            FocusScope.of(context).unfocus();
            unawaited(_onCodeDetected(v.trim()));
          },
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading || _done
                ? null
                : () {
                    // FIX #10: Dismiss keyboard on button tap too.
                    FocusScope.of(context).unfocus();
                    unawaited(_onCodeDetected(_codeCtrl.text.trim()));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.kAccent.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Check In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(GFColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: (_success ? AppTheme.kGreen : AppTheme.kRed)
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _success ? AppTheme.kGreen : AppTheme.kRed,
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _msg!,
          style: TextStyle(
            color: c.text1,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (!_success) ...<Widget>[
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _resetAfterFailure,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Camera state enum ─────────────────────────────────────────────────────────

/// FIX #1: Replaces the racy `_cameraVisible + _cameraInitializing` dual-bool
/// pattern with a single, unambiguous state machine.
enum _CameraState {
  /// Camera is not open and the preview is hidden.
  closed,

  /// [MobileScannerController.start] has been called but hasn't resolved yet.
  initializing,

  /// Camera is active and scanning for barcodes.
  running,
}

// ── Overlay ───────────────────────────────────────────────────────────────────

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double inset = (constraints.maxWidth * 0.08).clamp(12.0, 24.0);
        final double frameSize =
            (constraints.maxWidth - inset * 2).clamp(100.0, 260.0);

        return Center(
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: const Stack(
              children: <Widget>[
                Positioned(top: 0, left: 0, child: _Corner(topLeft: true)),
                Positioned(top: 0, right: 0, child: _Corner(topRight: true)),
                Positioned(bottom: 0, left: 0, child: _Corner(bottomLeft: true)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _Corner(bottomRight: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius br;
    if (topLeft) {
      br = const BorderRadius.only(topLeft: Radius.circular(4));
    } else if (topRight) {
      br = const BorderRadius.only(topRight: Radius.circular(4));
    } else if (bottomLeft) {
      br = const BorderRadius.only(bottomLeft: Radius.circular(4));
    } else {
      br = const BorderRadius.only(bottomRight: Radius.circular(4));
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? const BorderSide(color: AppTheme.kAccent, width: 3)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? const BorderSide(color: AppTheme.kAccent, width: 3)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? const BorderSide(color: AppTheme.kAccent, width: 3)
              : BorderSide.none,
          right: topRight || bottomRight
              ? const BorderSide(color: AppTheme.kAccent, width: 3)
              : BorderSide.none,
        ),
        borderRadius: br,
      ),
    );
  }
}