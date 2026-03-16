import 'package:flutter/material.dart';
import '../services/theme_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — sistema de cores central para todo o app
// Uso:  final t = AppTheme.current;
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  final bool isDark;
  const AppTheme._(this.isDark);

  static AppTheme get current => AppTheme._(ThemeService.instance.isDark);

  // ── Fundos ────────────────────────────────────────────────────────────────
  Color get bg        => isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF2F2F7);
  Color get card      => isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get cardAlt   => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  Color get appBar    => isDark ? const Color(0xFF111111) : Colors.white;
  Color get navBg     => isDark ? const Color(0xFF111111) : Colors.white;
  Color get popup     => isDark ? const Color(0xFF2C2C2E) : Colors.white;
  Color get sheet     => isDark ? const Color(0xFF1C1C1E) : Colors.white;

  // ── Texto ─────────────────────────────────────────────────────────────────
  Color get text      => isDark ? Colors.white            : const Color(0xFF1C1C1E);
  Color get textSub   => isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
  Color get textHint  => isDark ? const Color(0xFF48484A) : const Color(0xFFAEAEB2);

  // ── Ícones ────────────────────────────────────────────────────────────────
  Color get icon      => isDark ? Colors.white            : const Color(0xFF1C1C1E);
  Color get iconSub   => isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

  // ── Bordas / divisores ────────────────────────────────────────────────────
  Color get divider   => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D1D6);
  Color get border    => isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);
  Color get navBorder => isDark ? Colors.transparent      : const Color(0xFFD1D1D6);

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Color get navActive   => isDark ? Colors.white          : const Color(0xFF1C1C1E);
  Color get navInactive => isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);

  // ── Input ─────────────────────────────────────────────────────────────────
  Color get inputBg     => isDark ? Colors.white.withOpacity(0.09) : Colors.black.withOpacity(0.06);
  Color get inputBorder => isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);
  Color get inputText   => isDark ? Colors.white          : const Color(0xFF1C1C1E);
  Color get inputHint   => isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);

  // ── Feed / thumbnails ─────────────────────────────────────────────────────
  Color get thumbBg     => isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
  Color get thumbIcon   => isDark ? Colors.white24          : Colors.black26;

  // ── Mini player ───────────────────────────────────────────────────────────
  Color get miniPlayerBg => isDark ? const Color(0xFF1C1C1E) : Colors.white;

  // ── Skeleton ──────────────────────────────────────────────────────────────
  List<Color> get shimmer => isDark
      ? const [Color(0xFF1C1C1E), Color(0xFF2C2C2E), Color(0xFF1C1C1E)]
      : const [Color(0xFFE5E5EA), Color(0xFFF2F2F7), Color(0xFFE5E5EA)];

  // ── Drawer ────────────────────────────────────────────────────────────────
  Color get drawerBg    => isDark ? const Color(0xFF111111) : Colors.white;

  // ── Status bar ────────────────────────────────────────────────────────────
  Brightness get statusBar => isDark ? Brightness.light : Brightness.dark;

  // ── Cor de destaque ───────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF9000);
}

// Widget que reconstrói automaticamente quando o tema muda
class AppThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AppTheme) builder;
  const AppThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ThemeService.instance,
    builder: (ctx, _) => builder(ctx, AppTheme.current),
  );
}
