import 'dart:async';
import 'dart:convert';
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
    // Sem rede — deixa entrar (não bloqueia por falta de conexão)
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
              ? const Color(0xFF0C0C0C) : const Color(0xFFF2F2F7),
          colorScheme: ThemeService.instance.isDark
              ? const ColorScheme.dark(surface: Color(0xFF1C1C1E), primary: Colors.white)
              : const ColorScheme.light(surface: Color(0xFFFFFFFF), primary: Colors.black),
          useMaterial3: true,
        ),
        home: const _AppGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppGate — verifica beta antes de mostrar qualquer coisa
// ─────────────────────────────────────────────────────────────────────────────
class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked   = false;
  bool _lockEnabled = false;
  bool _checking   = true;
  bool _betaChecked = false;
  _BetaStatus? _beta;
  bool _bannerDismissed = false;

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

  Future<void> _init() async {
    // Verifica beta e lock em paralelo
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C0C0C),
        body: Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24))),
      );
    }

    // Beta expirado — tela bloqueada permanentemente
    if (_betaChecked && (_beta?.expired ?? false)) {
      return const _ExpiredScreen();
    }

    // Lock screen
    if (!_unlocked) {
      return LockScreen(
        mode: LockMode.unlock,
        onUnlocked: () => setState(() { _unlocked = true; _lockEnabled = true; }),
      );
    }

    // App normal com banner beta se ainda há tempo
    return Stack(children: [
      const HomePage(),
      if (_betaChecked && !(_beta?.expired ?? true) &&
          _beta?.expiresAt != null && !_bannerDismissed)
        _BetaBanner(
          beta: _beta!,
          onDismiss: () => setState(() => _bannerDismissed = true),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BetaBanner — aviso de tempo restante, dispensável com X
// ─────────────────────────────────────────────────────────────────────────────
class _BetaBanner extends StatelessWidget {
  final _BetaStatus beta;
  final VoidCallback onDismiss;
  const _BetaBanner({required this.beta, required this.onDismiss});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final days = beta.daysLeft ?? 0;
    final dateStr = beta.expiresAt != null ? _formatDate(beta.expiresAt!) : '';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ícone
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9000).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('β',
                  style: TextStyle(
                    color: Color(0xFFFF9000),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              ),
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  days > 0
                      ? '$days ${days == 1 ? "dia restante" : "dias restantes"} de beta'
                      : 'Último dia de beta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Acesso termina em $dateStr',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.signal_wifi_off_rounded,
                      size: 11, color: Color(0xFFFF9000)),
                  const SizedBox(width: 4),
                  Text(
                    'Evite usar VPN para uma melhor experiência',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10,
                    ),
                  ),
                ]),
              ]),
            ),
            // Botão X
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    size: 18, color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExpiredScreen — app totalmente bloqueado
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiredScreen extends StatelessWidget {
  const _ExpiredScreen();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
                  // Ícone
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('β',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        )),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'O tempo de uso do\nbeta terminou',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Migre para uma nova atualização\npara continuar a usar o app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      height: 1.6,
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
