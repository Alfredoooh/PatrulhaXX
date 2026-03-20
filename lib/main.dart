import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'pages/home_page.dart';
import 'pages/lock_screen.dart';
import 'services/favicon_service.dart';
import 'services/download_service.dart';
import 'services/lock_service.dart';
import 'services/theme_service.dart';

const _ch = MethodChannel('com.patrulhaxx/secure');
const _betaUrl = 'https://alfredoooh.github.io/database/beta.json';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await ThemeService.instance.init();
  await LockService.instance.init();
  await DownloadService.instance.loadSaved();
  FaviconService.instance.preloadAll();

  _applySecure(ThemeService.instance.noScreenshot);

  runApp(const PatrulhaXXApp());
}

void _applySecure(bool enable) {
  try { _ch.invokeMethod('setSecure', {'enable': enable}); } catch (_) {}
}

// ─── Verifica beta via JSON no GitHub ─────────────────────────────────────────
Future<_BetaStatus> _checkBeta() async {
  try {
    final resp = await http
        .get(Uri.parse(_betaUrl))
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return _BetaStatus.expired();
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final beta = data['beta'] as Map<String, dynamic>?;
    if (beta == null) return _BetaStatus.expired();
    final expiresStr = beta['expires'] as String? ?? '';
    final expires = DateTime.tryParse(expiresStr);
    if (expires == null) return _BetaStatus.expired();
    final now = DateTime.now();
    final remaining = expires.difference(now);
    return _BetaStatus(
      expired: now.isAfter(expires),
      expiresAt: expires,
      daysLeft: remaining.inDays,
    );
  } catch (_) {
    return _BetaStatus(expired: false, expiresAt: null, daysLeft: null);
  }
}

class _BetaStatus {
  final bool expired;
  final DateTime? expiresAt;
  final int? daysLeft;
  const _BetaStatus({
    required this.expired,
    required this.expiresAt,
    required this.daysLeft,
  });
  factory _BetaStatus.expired() =>
      const _BetaStatus(expired: true, expiresAt: null, daysLeft: null);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTopToast — usado APENAS para password certa/errada (com Lottie)
// Sem linhas, deslizar para cima dispensa o card
// ─────────────────────────────────────────────────────────────────────────────
class AppTopToast extends StatefulWidget {
  final bool success;
  final String message;
  final String? subtitle;
  final VoidCallback onDone;

  const AppTopToast({
    super.key,
    required this.success,
    required this.message,
    this.subtitle,
    required this.onDone,
  });

  @override
  State<AppTopToast> createState() => _AppTopToastState();
}

class _AppTopToastState extends State<AppTopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 440));
    _slide = Tween<Offset>(
            begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 3200), _dismiss);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _dismiss() async {
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPad + 10 + _dragOffset.clamp(-200.0, 40.0),
      left: 16, right: 16,
      child: GestureDetector(
        // Deslizar para cima dispensa o card
        onVerticalDragUpdate: (d) {
          if (d.delta.dy < 0) {
            setState(() => _dragOffset += d.delta.dy);
          }
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset < -30) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              // Material transparent elimina as linhas de divisão
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.74),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.55), width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      // Lottie — APENAS para password (sucesso/erro)
                      Container(
                        width: 38, height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: Lottie.asset(
                          widget.success
                              ? 'assets/lottie/tick_mark.json'
                              : 'assets/lottie/wrong_feedback.json',
                          repeat: false,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.45),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BetaWarningToast — aviso de dias restantes, SEM Lottie, apenas ícone simples
// Deslizar para cima dispensa o card
// ─────────────────────────────────────────────────────────────────────────────
class _BetaWarningToast extends StatefulWidget {
  final int daysLeft;
  final String expiresFormatted;
  final VoidCallback onDone;

  const _BetaWarningToast({
    required this.daysLeft,
    required this.expiresFormatted,
    required this.onDone,
  });

  @override
  State<_BetaWarningToast> createState() => _BetaWarningToastState();
}

class _BetaWarningToastState extends State<_BetaWarningToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 440));
    _slide = Tween<Offset>(
            begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 4000), _dismiss);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _dismiss() async {
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final days = widget.daysLeft;
    final label = days <= 0
        ? 'Último dia de beta'
        : '$days ${days == 1 ? "dia restante" : "dias restantes"} de beta';

    return Positioned(
      top: topPad + 10 + _dragOffset.clamp(-200.0, 40.0),
      left: 16, right: 16,
      child: GestureDetector(
        onVerticalDragUpdate: (d) {
          if (d.delta.dy < 0) {
            setState(() => _dragOffset += d.delta.dy);
          }
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset < -30) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.74),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.55), width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      // Ícone simples — sem Lottie
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('⏱',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Acesso termina em ${widget.expiresFormatted}',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.45),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class PatrulhaXXApp extends StatelessWidget {
  const PatrulhaXXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (_, __) => MaterialApp(
        title: 'patrulhaXX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: ThemeService.instance.isDark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: ThemeService.instance.isDark
              ? const Color(0xFF0C0C0C)
              : const Color(0xFFF2F2F7),
          colorScheme: ThemeService.instance.isDark
              ? const ColorScheme.dark(
                  surface: Color(0xFF1C1C1E), primary: Colors.white)
              : const ColorScheme.light(
                  surface: Color(0xFFFFFFFF), primary: Colors.black),
          useMaterial3: true,
        ),
        home: const _AppGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppGate
// ─────────────────────────────────────────────────────────────────────────────
class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked    = false;
  bool _lockEnabled = false;
  bool _checking    = true;
  bool _betaChecked = false;
  _BetaStatus? _beta;

  // Toast beta de dias restantes (só ≤ 9 dias)
  bool _showBetaToast    = false;
  bool _betaToastDismissed = false;

  DateTime? _pausedAt;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled || !_unlocked) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      final delay = ThemeService.instance.lockDelay;
      if (delay > 0) {
        _lockTimer?.cancel();
        _lockTimer = Timer(Duration(seconds: delay), _lock);
      }
    } else if (state == AppLifecycleState.resumed) {
      final delay = ThemeService.instance.lockDelay;
      if (delay == 0 && _pausedAt != null) _lock();
      if (_pausedAt != null && delay > 0) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        if (elapsed < delay) _lockTimer?.cancel();
      }
      _pausedAt = null;
    }
  }

  void _lock() {
    if (mounted) setState(() => _unlocked = false);
  }

  // Só mostra aviso se ≤ 9 dias restantes
  bool get _shouldShowBetaWarning {
    if (_beta == null) return false;
    if (_beta!.expired) return false;
    if (_beta!.expiresAt == null) return false;
    final days = _beta!.daysLeft ?? 0;
    return days <= 9;
  }

  Future<void> _init() async {
    final results = await Future.wait([
      _checkBeta(),
      LockService.instance.isEnabled(),
    ]);
    final beta = results[0] as _BetaStatus;
    final lockEnabled = results[1] as bool;
    if (mounted) {
      setState(() {
        _beta = beta;
        _betaChecked = true;
        _lockEnabled = lockEnabled;
        _unlocked = !lockEnabled;
        _checking = false;
      });
      // Mostra aviso apenas se ≤ 9 dias e não foi dispensado
      if (!beta.expired &&
          beta.expiresAt != null &&
          !_betaToastDismissed &&
          (beta.daysLeft ?? 999) <= 9) {
        if (mounted) setState(() => _showBetaToast = true);
      }
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C0C0C),
        body: Center(
            child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Colors.white24))),
      );
    }

    // Beta expirado
    if (_betaChecked && (_beta?.expired ?? false)) {
      return const _ExpiredScreen();
    }

    // Lock screen
    if (!_unlocked) {
      return LockScreen(
        mode: LockMode.unlock,
        onUnlocked: () => setState(() {
          _unlocked = true;
          _lockEnabled = true;
          // Mostra aviso beta após unlock se ≤ 9 dias e não foi dispensado
          if (_betaChecked &&
              !(_beta?.expired ?? true) &&
              _beta?.expiresAt != null &&
              !_betaToastDismissed &&
              (_beta?.daysLeft ?? 999) <= 9) {
            _showBetaToast = true;
          }
        }),
      );
    }

    // App com toast beta sobreposto (só se ≤ 9 dias)
    return Stack(children: [
      const HomePage(),
      if (_showBetaToast && !_betaToastDismissed && _shouldShowBetaWarning)
        _BetaWarningToast(
          daysLeft: _beta!.daysLeft ?? 0,
          expiresFormatted: _formatDate(_beta!.expiresAt!),
          onDone: () => setState(() {
            _showBetaToast = false;
            _betaToastDismissed = true;
          }),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExpiredScreen — sem ícones, apenas texto + botão atualizar
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiredScreen extends StatelessWidget {
  const _ExpiredScreen();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Atualizar versão\ndo aplicativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta versão expirou.\nInstala a versão mais recente para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Abre loja / link de actualização
                        // url_launcher: launchUrl(Uri.parse('...'))
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Atualizar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
