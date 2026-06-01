import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ── GymForge Design System v3 — Premium Blue Dark Theme ─────────────────────
/// Single accent, minimal color noise, production-ready.
class AppTheme {
  AppTheme._();

  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color kBg            = Color(0xFF0B0B0B);
  static const Color kSurface       = Color(0xFF111111);
  static const Color kCard          = Color(0xFF202020);
  static const Color kCardElevated  = Color(0xFF2E2E2E);
  static const Color kCardBorder    = Color(0xFF424242);

  /// Primary accent — indigo blue. ONLY for buttons, active states, highlights.
  static const Color kAccent        = Color(0xFF2196F3);
  static const Color kAccentDim     = Color(0x1A2196F3);  // 10% fill
  static const Color kAccentGlow    = Color(0x302196F3);  // subtle glow

  /// Semantic — icon tinting ONLY, never as backgrounds
  static const Color kGreen         = Color(0xFF66BB6A);
  static const Color kGreenDim      = Color(0x1566BB6A);
  static const Color kRed           = Color(0xFFF44336);
  static const Color kRedDim        = Color(0x15F44336);
  static const Color kGold          = Color(0xFFFFB300);
  static const Color kGoldDim       = Color(0x15FFB300);
  static const Color kCyan          = Color(0xFF2196F3);  // alias to accent
  static const Color kCyanDim       = Color(0x1A2196F3);
  static const Color kPurple        = Color(0xFF7E57C2);

  /// Leaderboard medals
  static const Color kMedalGold     = Color(0xFFFFB300);
  static const Color kMedalSilver   = Color(0xFFB0BEC5);
  static const Color kMedalBronze   = Color(0xFFAA6C47);

  /// Text
  static const Color kTextPrimary   = Color(0xFFFFFFFF);
  static const Color kTextSecondary = Color(0xFFB0BEC5);
  static const Color kTextMuted     = Color(0xFF616161);

  // ── Legacy aliases — keep existing code compiling ─────────────────────────
  static const Color kPrimary       = kAccent;
  static const Color kPrimaryLight  = kAccentDim;
  static const Color kPrimaryMid    = Color(0xFF1E88E5);
  static const Color kAccentLight   = kAccentDim;
  static const Color kGreenLight    = kGreenDim;
  static const Color kRedLight      = kRedDim;
  static const Color kGoldLight     = kGoldDim;
  static const Color kBlueLight     = kAccentDim;
  static const Color kPurpleLight   = Color(0x157E57C2);
  static const Color kBlue          = kAccent;
  static const Color kSurface2      = kCardElevated;

  // ── Spacing (8dp grid) ────────────────────────────────────────────────────
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;

  // ── Radius ────────────────────────────────────────────────────────────────
  static const double radius   = 12;   // cards
  static const double radiusSm = 8;
  static const double radiusXs = 4;
  static const double radiusLg = 20;   // buttons

  // ── Shadow ────────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x28000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> accentGlow = [
    const BoxShadow(color: kAccentGlow, blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ── Typography ────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.inter(
      color: kTextPrimary, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get h2 => GoogleFonts.inter(
      color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h3 => GoogleFonts.inter(
      color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get body1 => GoogleFonts.inter(
      color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body2 => GoogleFonts.inter(
      color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get caption => GoogleFonts.inter(
      color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
  static TextStyle get btnLabel => GoogleFonts.inter(
      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
      letterSpacing: 0.5, height: 1);

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary:   kAccent,
        secondary: kAccent,
        surface:   kCard,
        onPrimary: Colors.white,
        onSurface: kTextPrimary,
        outline:   kCardBorder,
        error:     kRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor:    kTextSecondary,
        displayColor: kTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:        kSurface,
        elevation:              0,
        scrolledUnderElevation: 0,
        surfaceTintColor:       Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(
            color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: btnLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kAccent,
          side: const BorderSide(color: kAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: btnLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   kCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kCardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kCardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kRed, width: 1.5)),
        labelStyle:       const TextStyle(color: kTextSecondary, fontSize: 14),
        hintStyle:        const TextStyle(color: kTextMuted,     fontSize: 13),
        prefixIconColor:  kTextMuted,
        suffixIconColor:  kTextMuted,
        contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle:       const TextStyle(color: kRed, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color:     kCard,
        elevation: 2,
        shadowColor: const Color(0x28000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide.none,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor:            kAccent,
        unselectedLabelColor:  kTextMuted,
        indicatorColor:        kAccent,
        indicatorSize:         TabBarIndicatorSize.tab,
        labelStyle:    GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor:  kCardBorder,
      ),
      dividerColor:  kCardBorder,
      iconTheme:     const IconThemeData(color: kTextSecondary, size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   kCardElevated,
        contentTextStyle:  const TextStyle(color: kTextPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior:          SnackBarBehavior.floating,
        elevation:         4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            kAccent,
        linearTrackColor: kCardBorder,
      ),
      switchTheme: SwitchThemeData(
        thumbColor:  WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kAccent : kTextMuted),
        trackColor:  WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kAccentDim : kCard),
      ),
    );
  }

  // ── Light palette tokens ────────────────────────────────────────────────
  static const Color _lBg      = Color(0xFFF5F5F5);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lCard    = Color(0xFFFFFFFF);
  static const Color _lBorder  = Color(0xFFE0E0E0);
  static const Color _lText1   = Color(0xFF212121);
  static const Color _lText2   = Color(0xFF757575);
  static const Color _lText3   = Color(0xFFBDBDBD);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lBg,
      colorScheme: const ColorScheme.light(
        primary:   kAccent,
        secondary: kAccent,
        surface:   _lCard,
        onPrimary: Colors.white,
        onSurface: _lText1,
        outline:   _lBorder,
        error:     kRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor:    _lText2,
        displayColor: _lText1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:        _lSurface,
        elevation:              0,
        scrolledUnderElevation: 0,
        surfaceTintColor:       Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(
            color: _lText1, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: _lText1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: btnLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kAccent,
          side: const BorderSide(color: kAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: btnLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: _lBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _lBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _lBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: kRed, width: 1.5)),
        labelStyle: const TextStyle(color: _lText2, fontSize: 14),
        hintStyle:  const TextStyle(color: _lText3, fontSize: 13),
        prefixIconColor: _lText2,
        suffixIconColor: _lText2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(color: kRed, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color:       _lCard,
        elevation:   2,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide.none),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor:           kAccent,
        unselectedLabelColor: _lText2,
        indicatorColor:       kAccent,
        indicatorSize:        TabBarIndicatorSize.tab,
        labelStyle:    GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor:  _lBorder,
      ),
      dividerColor: _lBorder,
      iconTheme: const IconThemeData(color: _lText2, size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   _lSurface,
        contentTextStyle:  const TextStyle(color: _lText1, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior:          SnackBarBehavior.floating,
        elevation:         4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            kAccent,
        linearTrackColor: _lBorder,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kAccent : _lText3),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kAccentDim : _lBorder),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Standard dark card — 12dp radius, 16dp padding, #202020 bg, soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? background;
  final Color? borderColor;
  final double? radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.background,
    this.borderColor,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.radius;
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: background ?? GFColors(context).card,
        borderRadius: BorderRadius.circular(r),
        boxShadow: AppTheme.cardShadow,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 0.5)
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        splashColor:    AppTheme.kAccent.withValues(alpha: 0.08),
        highlightColor: AppTheme.kAccent.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

// Legacy aliases
class GFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final double? radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  const GFCard({super.key, required this.child, this.padding, this.color,
      this.borderColor, this.radius, this.onTap, this.shadow});
  @override
  Widget build(BuildContext context) => AppCard(
      padding: padding, background: color,
      borderColor: borderColor, radius: radius, onTap: onTap,
      child: child);
}

class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  const MCard({super.key, required this.child, this.padding, this.color,
      this.onTap, this.radius = AppTheme.radius});
  @override
  Widget build(BuildContext context) =>
      AppCard(padding: padding, background: color,
          onTap: onTap, radius: radius, child: child);
}

class MemberTheme {
  MemberTheme._();
  static const Color kBg            = AppTheme.kBg;
  static const Color kSurface       = AppTheme.kSurface;
  static const Color kCard          = AppTheme.kCard;
  static const Color kCardBorder    = AppTheme.kCardBorder;
  static const Color kPrimary       = AppTheme.kAccent;
  static const Color kPrimaryLight  = AppTheme.kAccentDim;
  static const Color kAccent        = AppTheme.kAccent;
  static const Color kAccentDim     = AppTheme.kAccentDim;
  static const Color kGreen         = AppTheme.kGreen;
  static const Color kGreenDim      = AppTheme.kGreenDim;
  static const Color kGreenLight    = AppTheme.kGreenDim;
  static const Color kRed           = AppTheme.kRed;
  static const Color kRedDim        = AppTheme.kRedDim;
  static const Color kGold          = AppTheme.kGold;
  static const Color kGoldDim       = AppTheme.kGoldDim;
  static const Color kCyan          = AppTheme.kAccent;
  static const Color kCyanDim       = AppTheme.kAccentDim;
  static const Color kPink          = AppTheme.kPurple;
  static const Color kPurple        = AppTheme.kPurple;
  static const Color kTextPrimary   = AppTheme.kTextPrimary;
  static const Color kTextSecondary = AppTheme.kTextSecondary;
  static const Color kTextMuted     = AppTheme.kTextMuted;
  static ThemeData get dark => AppTheme.dark;
}

/// Primary CTA button — blue, 20dp radius, 0.95 scale press.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final bool outline;
  final Color? color;
  final double height;
  const AppButton({super.key, required this.label, this.onTap, this.icon,
      this.loading = false, this.outline = false, this.color, this.height = 52});
  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? AppTheme.kAccent;
    final fg = widget.outline ? bg : Colors.white;
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color:        widget.outline ? Colors.transparent : bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border:       widget.outline ? Border.all(color: bg, width: 1.5) : null,
            boxShadow:    widget.outline || widget.onTap == null ? null : AppTheme.accentGlow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              onTap: null, // handled by GestureDetector above
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              splashColor: Colors.white.withValues(alpha: 0.12),
              child: Center(
                child: widget.loading
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(widget.label, style: AppTheme.btnLabel.copyWith(color: fg)),
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double height;
  const NeonButton({super.key, required this.label, this.onTap, this.icon,
      this.loading = false, this.height = 52});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity, height: height,
      child: AppButton(label: label, onTap: onTap, icon: icon, loading: loading));
}

/// Animated fill progress bar — accent on #424242 track.
class AppProgressBar extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  const AppProgressBar({super.key, required this.value,
      required this.color, this.height = 4});
  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.0, end: widget.value.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }
  @override
  void didUpdateWidget(AppProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween(begin: _anim.value, end: widget.value.clamp(0.0, 1.0))
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl..reset()..forward();
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(builder: (_, c) => Stack(children: [
        Container(height: widget.height, width: c.maxWidth,
            decoration: BoxDecoration(
                color: GFColors(context).border,
                borderRadius: BorderRadius.circular(widget.height))),
        Container(height: widget.height, width: c.maxWidth * _anim.value,
            decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.height))),
      ])));
}

class MProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const MProgressBar({super.key, required this.value,
      required this.color, this.height = 4});
  @override
  Widget build(BuildContext context) =>
      AppProgressBar(value: value, color: color, height: height);
}

/// Section header with optional trailing.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title,
      this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(title, style: AppTheme.h3),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTheme.caption),
        ],
      ])),
      if (trailing != null) trailing!,
    ]);
  }
}

/// Stat tile — dark card, icon uses color, value always white.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const StatTile({super.key, required this.label, required this.value,
      required this.icon, required this.color, this.sub});
  @override
  Widget build(BuildContext context) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppTheme.kCardElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          child: Icon(icon, color: color, size: 18)),
      const SizedBox(height: AppTheme.sp12),
      Text(value, style: AppTheme.h2.copyWith(fontSize: 22)),
      const SizedBox(height: 2),
      Text(label, style: AppTheme.caption),
      if (sub != null) Text(sub!, style: AppTheme.body2),
    ]));
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const GradientCard({super.key, required this.child, required this.colors,
      this.radius = AppTheme.radius, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppTheme.sp20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: AppTheme.cardShadow),
        child: child));
}

class MGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const MGradientCard({super.key, required this.child, required this.colors,
      this.radius = AppTheme.radius, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) =>
      GradientCard(colors: colors, radius: radius, padding: padding, onTap: onTap, child: child);
}

class GFGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const GFGradientCard({super.key, required this.child, required this.colors,
      this.radius = AppTheme.radius, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) =>
      GradientCard(colors: colors, radius: radius, padding: padding, onTap: onTap, child: child);
}

/// Tag/Pill chip — #2E2E2E bg, subtle.
class TagChip extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? bgColor;
  const TagChip({super.key, required this.label, this.textColor, this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor ?? AppTheme.kCardElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      child: Text(label, style: AppTheme.caption.copyWith(
          color: textColor ?? AppTheme.kTextSecondary)));
}

class GFBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;
  const GFBadge({super.key, required this.label, required this.bgColor,
      required this.textColor, this.icon});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: textColor), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));
}

class GlowBox extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double radius;
  final double blurRadius;
  const GlowBox({super.key, required this.child, required this.glowColor,
      this.radius = AppTheme.radius, this.blurRadius = 16});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.22),
              blurRadius: blurRadius, offset: const Offset(0, 4))]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), child: child));
}

/// Press wrapper — 0.97 scale with ripple.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 80));
    _s = Tween(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child));
}

// ── Light theme (minimal, clean) ─────────────────────────────────────────────
// Intentionally not defined inside AppTheme class to avoid circular usage.


// ═══════════════════════════════════════════════════════════════════════════
// THEME-AWARE COLORS — use these in build() methods for light/dark support
// ═══════════════════════════════════════════════════════════════════════════

/// Drop-in helper: `final c = GFColors(context);`  then use `c.card`, `c.text1`, etc.
/// Works correctly in both dark and light mode.
class GFColors {
  final BuildContext context;
  final bool isDark;

  GFColors(this.context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  Color get bg       => isDark ? AppTheme.kBg            : const Color(0xFFF5F5F5);
  Color get surface  => isDark ? AppTheme.kSurface        : Colors.white;
  Color get card     => isDark ? AppTheme.kCard           : Colors.white;
  Color get elevated => isDark ? AppTheme.kCardElevated   : const Color(0xFFF0F0F0);
  Color get border   => isDark ? AppTheme.kCardBorder     : const Color(0xFFE0E0E0);
  Color get text1    => isDark ? AppTheme.kTextPrimary    : const Color(0xFF212121);
  Color get text2    => isDark ? AppTheme.kTextSecondary  : const Color(0xFF757575);
  Color get text3    => isDark ? AppTheme.kTextMuted      : const Color(0xFFBDBDBD);
  Color get shadow   => isDark ? const Color(0x28000000)  : const Color(0x14000000);

  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 2))
  ];
}
