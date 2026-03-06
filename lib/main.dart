import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/lock_screen.dart';
import 'services/favicon_service.dart';
import 'services/download_service.dart';
import 'services/lock_service.dart';
import 'services/theme_service.dart';

const _ch = MethodChannel('com.patrulhaxx/secure');

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

class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _lockEnabled = false;
  bool _checking = true;
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
      if (delay == 0 && _pausedAt != null) {
        _lock();
      }
      // If delay > 0, timer handles it — cancel if we resumed before it fired
      // (user came back quickly)
      if (_pausedAt != null && delay > 0) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        if (elapsed < delay) {
          _lockTimer?.cancel(); // Not enough time passed — stay unlocked
        }
      }
      _pausedAt = null;
    }
  }

  void _lock() {
    if (mounted) setState(() => _unlocked = false);
  }

  Future<void> _init() async {
    final enabled = await LockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _lockEnabled = enabled;
        _unlocked = !enabled;
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
    if (!_unlocked) {
      return LockScreen(
        mode: LockMode.unlock,
        onUnlocked: () => setState(() { _unlocked = true; _lockEnabled = true; }),
      );
    }
    return const HomePage();
  }
}
