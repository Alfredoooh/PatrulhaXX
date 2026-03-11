import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:lottie/lottie.dart';
import '../services/lock_service.dart';
import 'home_page.dart';

enum LockMode { unlock, setNew }

// ─── Toast topo estilo Samsung ────────────────────────────────────────────────
class _TopToast extends StatefulWidget {
  final bool success;
  final String message;
  final VoidCallback onDone;
  const _TopToast({required this.success, required this.message, required this.onDone});

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2400), _dismiss);
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
      top: topPad + 10,
      left: 20, right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Container cinza claro com Lottie animado
                  Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEEEEE),
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
                ]),
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

  const LockScreen({super.key, this.mode = LockMode.unlock, this.onUnlocked, this.onPinSet});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  String _input = '';
  String? _firstPin;
  bool _error = false;
  bool _visible = false;
  bool _showToast = false;
  bool _toastSuccess = false;
  String _toastMsg = '';
  bool _unlocking = false;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _shake.dispose(); super.dispose(); }

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
    setState(() { _error = false; _input += k; });
    // Auto-confirmar ao atingir 4 dígitos
    if (_input.length >= 4) Future.microtask(_onConfirm);
  }

  void _onDel() {
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onConfirm() async {
    if (_input.length < 4) { _triggerError(); return; }

    if (widget.mode == LockMode.unlock) {
      final ok = await LockService.instance.verify(_input);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'Bem-vindo de volta!');
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

    if (_firstPin == null) {
      setState(() { _firstPin = _input; _input = ''; });
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
    setState(() { _error = true; _input = ''; });
    _shake.forward(from: 0);
  }

  void _showTopToast({required bool success, required String msg}) {
    setState(() { _toastSuccess = success; _toastMsg = msg; _showToast = true; });
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 520),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: const Color(0xFF0C0C0C),
      closedColor: const Color(0xFFf5a992),
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      openBuilder: (_, __) => const HomePage(),
      closedBuilder: (_, openIt) {
        if (_unlocking) {
          WidgetsBinding.instance.addPostFrameCallback((_) => openIt());
        }
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
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
                child: Image.asset('assets/logo.png',
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white38, size: 36),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Título — Playfair Display
            Text(_title,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              )),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(_subtitle,
                key: ValueKey(_subtitle),
                style: TextStyle(
                  color: _error ? Colors.redAccent : Colors.white70,
                  fontSize: 13,
                )),
            ),

            const SizedBox(height: 28),

            // Dots
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
                        color: _error ? Colors.redAccent
                            : filled ? Colors.white : Colors.white.withOpacity(0.35),
                        boxShadow: filled && !_error
                            ? [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: ch != null
                          ? Center(child: Text(ch,
                              style: const TextStyle(color: Colors.black, fontSize: 9,
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
              onToggleVisible: () => setState(() => _visible = !_visible),
              isVisible: _visible,
            ),

            const SizedBox(height: 32),
          ]),
        ),

        // Toast
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

// ── Keypad ────────────────────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisible;
  final bool isVisible;

  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onToggleVisible,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Botão olho — ícone Material simples (sem Lottie, sem glass)
          _KeyBtn(
            onTap: onToggleVisible,
            child: Icon(
              isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          _KeyBtn(
            onTap: () => onKey('0'),
            child: const Text('0',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
          ),
          _KeyBtn(
            onTap: onDelete,
            child: const Icon(Icons.backspace_rounded, color: Colors.white, size: 22),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _KeyBtn(
        onTap: () => onKey(k),
        child: Text(k,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
      )).toList(),
    );
  }
}

// ── Botão — sólido, visível, Android style ────────────────────────────────────
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
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 180),
        lowerBound: 0, upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: 74, height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Sólido, visível — Android style, sem glass
            color: const Color(0xFFE8816A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 6,
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
