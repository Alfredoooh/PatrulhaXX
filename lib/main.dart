import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/lock_screen.dart';
import 'services/favicon_service.dart';
import 'services/download_service.dart';
import 'services/lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Inicializa PIN padrão 0123 na primeira instalação
  await LockService.instance.init();

  await DownloadService.instance.loadSaved();
  FaviconService.instance.preloadAll();

  runApp(const PatrulhaXXApp());
}

class PatrulhaXXApp extends StatelessWidget {
  const PatrulhaXXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'patrulhaXX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0C0C),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF161616),
          primary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const _AppGate(),
    );
  }
}

// ── Decide se mostra LockScreen ou HomePage ───────────────────────────────────
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _lockEnabled = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Bloqueia novamente ao voltar do background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lockEnabled && _unlocked) {
      setState(() => _unlocked = false);
    }
  }

  Future<void> _check() async {
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
        body: Center(
          child: Text(
            'patrulhaXX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    if (!_unlocked) {
      return LockScreen(
        mode: LockMode.unlock,
        onUnlocked: () => setState(() => _unlocked = true),
      );
    }

    return const HomePage();
  }
}
