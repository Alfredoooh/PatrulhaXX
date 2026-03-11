import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:lottie/lottie.dart';
import '../services/lock_service.dart';
import 'home_page.dart';

enum LockMode { unlock, setNew }

// ─────────────────────────────────────────────────────────────────────────────
// Toast de topo estilo Samsung — blur branco opaco, bordas 100% redondas
// ─────────────────────────────────────────────────────────────────────────────
class _TopToast extends StatefulWidget {
  final bool success;
  final String message;
  final VoidCallback onDone;

  const _TopToast({
    required this.success,
    required this.message,
    required this.onDone,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slide = Tween<Offset>(
            begin: const Offset(0, -1.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    // Auto-dismiss depois de 2s
    Future.delayed(const Duration(milliseconds: 2200), _dismiss);
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
    final isSuccess = widget.success;

    return Positioned(
      top: topPad + 10,
      left: 20, right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100), // 100% curvo
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone Lottie em container branco/cinza
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: Lottie.asset(
                        isSuccess
                            ? 'assets/lottie/success.json'
                            : 'assets/lottie/error.json',
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.80),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
// LockScreen
// ─────────────────────────────────────────────────────────────────────────────
class LockScreen extends StatefulWidget {
  final LockMode mode;
  final VoidCallback? onUnlocked;
  final ValueChanged<String>? onPinSet;

  const LockScreen(
      {super.key,
      this.mode = LockMode.unlock,
      this.onUnlocked,
      this.onPinSet});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  String _input = '';
  String? _firstPin;
  bool _error = false;
  bool _visible = false;
  bool _showToast = false;
  bool _toastSuccess = false;
  String _toastMsg = '';
  bool _unlocking = false; // trigger para container transform

  // Shake controller
  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  // Eye icon animado
  late final AnimationController _eyeCtrl;

  @override
  void initState() {
    super.initState();

    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));

    _eyeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
  }

  @override
  void dispose() {
    _shake.dispose();
    _eyeCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == LockMode.unlock) return 'Introduz o teu PIN';
    return _firstPin == null ? 'Novo PIN' : 'Confirmar PIN';
  }

  String get _subtitle {
    if (_error) {
      return widget.mode == LockMode.unlock
          ? 'PIN incorreto. Tenta novamente.'
          : 'PINs não coincidem. Começa de novo.';
    }
    if (widget.mode == LockMode.unlock) return '';
    return _firstPin == null ? 'Define um PIN (mínimo 4 dígitos)' : 'Repete o PIN';
  }

  void _onKey(String k) {
    if (_input.length >= 12) return;
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      _input += k;
    });
    // Auto-confirmar quando atingir 4+ dígitos e já tínhamos firstPin
    // ou quando atingir 4 dígitos em modo unlock
    if (widget.mode == LockMode.unlock && _input.length >= 4) {
      Future.microtask(_onConfirm);
    } else if (widget.mode == LockMode.setNew &&
        _firstPin != null &&
        _input.length >= 4) {
      Future.microtask(_onConfirm);
    } else if (widget.mode == LockMode.setNew &&
        _firstPin == null &&
        _input.length >= 4) {
      Future.microtask(_onConfirm);
    }
  }

  void _onDel() {
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onConfirm() async {
    if (_input.length < 4) {
      _triggerError();
      return;
    }

    if (widget.mode == LockMode.unlock) {
      final ok = await LockService.instance.verify(_input);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'Bem-vindo de volta!');
        // Aguarda toast aparecer e depois transita
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() => _unlocking = true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) widget.onUnlocked?.call();
      } else {
        _showTopToast(success: false, msg: 'PIN incorreto. Tenta novamente.');
        _triggerError();
      }
      return;
    }

    // setNew
    if (_firstPin == null) {
      setState(() {
        _firstPin = _input;
        _input = '';
      });
    } else {
      if (_input == _firstPin) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'PIN definido com sucesso!');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) widget.onPinSet?.call(_input);
      } else {
        setState(() => _firstPin = null);
        _showTopToast(success: false, msg: 'PINs não coincidem. Recomeça.');
        _triggerError();
      }
    }
  }

  void _triggerError() {
    HapticFeedback.vibrate();
    setState(() {
      _error = true;
      _input = '';
    });
    _shake.forward(from: 0);
  }

  void _showTopToast({required bool success, required String msg}) {
    setState(() {
      _toastSuccess = success;
      _toastMsg = msg;
      _showToast = true;
    });
  }

  void _toggleVisible() {
    setState(() => _visible = !_visible);
    if (_visible) {
      _eyeCtrl.forward();
    } else {
      _eyeCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Container transform: quando _unlocking=true, expande para branco e chama onUnlocked
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 520),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: const Color(0xFF0C0C0C),
      closedColor: const Color(0xFFf5a992),
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      // O OpenContainer só é ativado programaticamente via _unlocking
      // Usamos um wrapper que quando _unlocking=true mostra a HomePage
      openBuilder: (_, __) => const HomePage(),
      closedBuilder: (_, openIt) {
        // Quando _unlocking fica true, acionamos o container transform
        if (_unlocking) {
          WidgetsBinding.instance.addPostFrameCallback((_) => openIt());
        }
        return _buildLockBody(context);
      },
    );
  }

  Widget _buildLockBody(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5a992),
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            const SizedBox(height: 44),

            // Logo
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logo.png',
                  width: 80, height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white38, size: 36),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Título — fonte Google sensual/elegante
            Text(
              _title,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _subtitle,
                key: ValueKey(_subtitle),
                style: TextStyle(
                  color: _error ? Colors.redAccent : Colors.white60,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Dots com shake
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0), child: child),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _input.isEmpty ? 4 : _input.length.clamp(4, 12),
                  (i) {
                    final filled = i < _input.length;
                    final ch = filled && _visible ? _input[i] : null;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: filled ? 16 : 13,
                      height: filled ? 16 : 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? Colors.redAccent
                            : filled
                                ? Colors.white
                                : Colors.white.withOpacity(0.25),
                        boxShadow: filled && !_error
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                      ),
                      child: ch != null
                          ? Center(
                              child: Text(ch,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)))
                          : null,
                    );
                  },
                ),
              ),
            ),

            const Spacer(),

            // Keypad
            _Keypad(
              onKey: _onKey,
              onDelete: _onDel,
              onToggleVisible: _toggleVisible,
              eyeCtrl: _eyeCtrl,
              isVisible: _visible,
            ),

            const SizedBox(height: 28),
          ]),
        ),

        // Toast topo
        if (_showToast)
          _TopToast(
            success: _toastSuccess,
            message: _toastMsg,
            onDone: () => setState(() => _showToast = false),
          ),
      ]),
    );
  }
}

// ── Keypad — sem botão confirmar ──────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisible;
  final AnimationController eyeCtrl;
  final bool isVisible;

  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onToggleVisible,
    required this.eyeCtrl,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Column(children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 14),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 14),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Olho Lottie animado
          _KeyBtn(
            onTap: onToggleVisible,
            child: _LottieEye(controller: eyeCtrl, isVisible: isVisible),
          ),
          _KeyBtn(
            onTap: () => onKey('0'),
            child: const Text('0',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w400)),
          ),
          _KeyBtn(
            onTap: onDelete,
            child: const Icon(Icons.backspace_rounded,
                color: Colors.white70, size: 22),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((k) => _KeyBtn(
                onTap: () => onKey(k),
                child: Text(k,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w300)),
              ))
          .toList(),
    );
  }
}

// ── Lottie Eye — olho animado controlado pelo AnimationController ────────────
class _LottieEye extends StatefulWidget {
  final AnimationController controller;
  final bool isVisible;
  const _LottieEye({required this.controller, required this.isVisible});

  @override
  State<_LottieEye> createState() => _LottieEyeState();
}

class _LottieEyeState extends State<_LottieEye> {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/eye.json',
      controller: widget.controller,
      width: 26, height: 26,
      fit: BoxFit.contain,
      onLoaded: (comp) {
        widget.controller.duration = comp.duration;
      },
    );
  }
}

// ── Botão do teclado ──────────────────────────────────────────────────────────
class _KeyBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeyBtn({required this.onTap, required this.child});

  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 180),
        lowerBound: 0,
        upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.84)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Mais visível — branco mais opaco + borda sutil
            color: Colors.white.withOpacity(0.18),
            border: Border.all(
                color: Colors.white.withOpacity(0.22), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
