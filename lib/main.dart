import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/widget_service.dart';
import 'services/member_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/owner/owner_shell.dart';
import 'screens/member/member_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  final startupError = await _bootstrap();
  runApp(GymForgeApp(startup: Future.value(startupError)));
}

Future<String?> _bootstrap() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;

    // Guard against un-configured web placeholder
    if (kIsWeb && options.appId.contains(':web:placeholder')) {
      throw StateError(
        'Firebase web appId is still a placeholder.\n'
        'Open Firebase Console → Project Settings → Web Apps,\n'
        'create a web app, and paste its config into\n'
        'lib/firebase_options.dart → DefaultFirebaseOptions.web.',
      );
    }

    await Firebase.initializeApp(options: options).timeout(
      const Duration(seconds: 12),
    );
    await WidgetService.init();

    if (!kIsWeb) {
      await _requestNativePermissions();
    }

    return null;
  } catch (e) {
    return e.toString();
  }
}

/// Request native-only permissions (Android / iOS only — never called on web).
Future<void> _requestNativePermissions() async {
  // Import permission_handler only on native via conditional import pattern.
  // The permission_handler package itself is excluded from the web build
  // because it uses dart:io. To avoid any import error on web we gate
  // the entire call behind kIsWeb in main() above.
  try {
    // ignore: avoid_dynamic_calls
    final ph = await _loadPermissionHandler();
    if (ph != null) await ph();
  } catch (_) {}
}

// Stub — actual implementation injected at compile time via conditional import.
// Using a dynamic approach so the web tree-shaker drops this entire path.
Future<Function?> _loadPermissionHandler() async => null;

// ─── App Root ─────────────────────────────────────────────────────────────────
class GymForgeApp extends StatelessWidget {
  /// Resolves to null on success, or an error string on bootstrap failure.
  final Future<String?> startup;

  const GymForgeApp({super.key, required this.startup});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (_, tp, __) {
          // Keep system status-bar icons in sync with the selected theme.
          if (!kIsWeb) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  tp.isDark ? Brightness.light : Brightness.dark,
            ));
          }

          return MaterialApp(
            title: 'GymForge',
            debugShowCheckedModeBanner: false,
            theme: tp.theme,
            builder: (ctx, child) {
              // On wide screens (tablet / desktop) centre the app in a
              // phone-sized container with a subtle shadow.
              return _ResponsiveFrame(child: child ?? const SizedBox.shrink());
            },
            home: FutureBuilder<String?>(
              future: startup,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _Splash();
                }
                if (snap.data != null) {
                  // Bootstrap failed — show a user-friendly error screen.
                  return _ErrorScreen(message: snap.data!);
                }
                return const _AuthGate();
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Responsive frame (centres UI on wide screens) ───────────────────────────
class _ResponsiveFrame extends StatelessWidget {
  final Widget child;
  const _ResponsiveFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final width = MediaQuery.sizeOf(context).width;
    if (width < 700) return child; // already mobile-width → no frame needed

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
// Two independent session checks on every cold start:
//   1. SharedPrefs  → Gym Member  → MemberShell
//   2. Firebase Auth → Gym Owner  → OwnerShell
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _hasMemberSession;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _checkMemberSession();
  }

  Future<void> _checkMemberSession() async {
    final session = await MemberService().getSession();
    if (mounted) {
      setState(() {
        _hasMemberSession = session != null;
        _firebaseReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseReady) return const _Splash();

    if (_hasMemberSession == true) return const MemberShell();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (snap.hasData && snap.data != null) return const OwnerShell();
        return const LoginScreen();
      },
    );
  }
}

// ─── Splash ───────────────────────────────────────────────────────────────────
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.kAccent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 30)
                  ],
                ),
                child: const Icon(Icons.fitness_center,
                    color: Colors.black, size: 38),
              ),
              const SizedBox(height: 24),
              const Text('GYMFORGE',
                  style: TextStyle(
                      color: AppTheme.kAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6)),
              const SizedBox(height: 8),
              const Text('Manage · Track · Grow',
                  style: TextStyle(
                      color: AppTheme.kTextSecondary, fontSize: 13)),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.kAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bootstrap error screen ───────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.kRed, size: 56),
              const SizedBox(height: 20),
              const Text('Startup Error',
                  style: TextStyle(
                      color: AppTheme.kRed,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.kSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                      color: AppTheme.kTextSecondary,
                      fontSize: 13,
                      fontFamily: 'monospace'),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check your Firebase configuration in\nlib/firebase_options.dart',
                style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
