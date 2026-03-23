import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/lock_service.dart';
import '../theme/app_theme.dart';

enum LockMode { unlock, setNew }

// ─── Toast ────────────────────────────────────────────────────────────────────
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
    _slide =
        Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2600), _dismiss);
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
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEE), shape: BoxShape.circle),
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
                          letterSpacing: -0.1),
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
  const LockScreen({
    super.key,
    this.mode = LockMode.unlock,
    this.onUnlocked,
    this.onPinSet,
  });
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  String  _input        = '';
  String? _firstPin;
  bool    _error        = false;
  bool    _visible      = false;
  bool    _showToast    = false;
  bool    _toastSuccess = false;
  String  _toastMsg     = '';
  bool    _processing   = false;

  AnimationController? _lottieCtrl;

  late final AnimationController _shake;
  late final Animation<double>   _shakeAnim;

  final List<int> _keyTimestamps = [];

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0,  end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end: 0.0),   weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    _lottieCtrl?.dispose();
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
    return _firstPin == null
        ? 'Define um PIN (mínimo 4 dígitos)'
        : 'Repete o PIN';
  }

  void _onKey(String k) {
    if (_processing) return;
    if (_input.length >= 12) return;
    HapticFeedback.lightImpact();
    _keyTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    setState(() { _error = false; _input += k; });
    if (_input.length >= 4 && !_processing) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_processing) _onConfirm();
      });
    }
  }

  void _onDel() {
    if (_processing) return;
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    if (_keyTimestamps.isNotEmpty) _keyTimestamps.removeLast();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  bool _isTypingPatternValid() {
    if (_keyTimestamps.length < 2) return true;
    final total = _keyTimestamps.last - _keyTimestamps.first;
    if (total < 200 && _keyTimestamps.length >= 4) return false;
    return true;
  }

  Future<void> _onConfirm() async {
    if (_processing) return;
    if (_input.length < 4) { _triggerError(); return; }
    setState(() => _processing = true);

    if (!_isTypingPatternValid()) {
      if (mounted) {
        _showTopToast(success: false, msg: 'Padrão suspeito detectado.');
        _triggerError();
        setState(() => _processing = false);
      }
      return;
    }

    if (widget.mode == LockMode.unlock) {
      final ok = await LockService.instance.verify(_input);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'Bem-vindo de volta!');
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) widget.onUnlocked?.call();
      } else {
        _showTopToast(success: false, msg: 'PIN incorreto. Tenta novamente.');
        _triggerError();
        setState(() => _processing = false);
      }
      return;
    }

    // Mode setNew
    if (_firstPin == null) {
      setState(() {
        _firstPin = _input;
        _input = '';
        _keyTimestamps.clear();
        _processing = false;
      });
    } else {
      if (_input == _firstPin) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'PIN definido com sucesso!');
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) widget.onPinSet?.call(_input);
      } else {
        setState(() => _firstPin = null);
        _showTopToast(success: false, msg: 'PINs não coincidem. Recomeça.');
        _triggerError();
        setState(() => _processing = false);
      }
    }
  }

  void _triggerError() {
    HapticFeedback.vibrate();
    _keyTimestamps.clear();
    setState(() { _error = true; _input = ''; });
    _shake.forward(from: 0);
  }

  void _showTopToast({required bool success, required String msg}) {
    if (!mounted) return;
    setState(() {
      _toastSuccess = success;
      _toastMsg     = msg;
      _showToast    = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t       = AppTheme.current;
    final screenH = MediaQuery.of(context).size.height;
    final botPad  = MediaQuery.of(context).padding.bottom;
    final topPad  = MediaQuery.of(context).padding.top;
    final keypadH = screenH * 0.50;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(children: [
        Column(children: [

          // ── Zona superior ─────────────────────────────────────────────
          Expanded(
            child: Stack(children: [

              // Título — fora do grupo centrado, fixo no topo
              Positioned(
                top: topPad + 16,
                left: 0,
                right: 0,
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              // Centro — Lottie + subtítulo + dots
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Lottie no lugar do texto central
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Lottie.asset(
                        'assets/lottie/lock.json',
                        repeat: true,
                        animate: true,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.lock_rounded,
                          size: 64,
                          color: t.iconSub,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dots PIN
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
                              width:  filled ? 16 : 13,
                              height: filled ? 16 : 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _error
                                    ? AppTheme.error
                                    : filled
                                        ? t.text
                                        : t.text.withOpacity(0.25),
                                boxShadow: filled && !_error
                                    ? [
                                        BoxShadow(
                                            color: t.text.withOpacity(0.3),
                                            blurRadius: 6)
                                      ]
                                    : null,
                              ),
                              child: ch != null
                                  ? Center(
                                      child: Text(ch,
                                          style: TextStyle(
                                              color: t.bg,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold)))
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtítulo / erro
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _subtitle,
                        key: ValueKey(_subtitle),
                        style: TextStyle(
                          color: _error
                              ? AppTheme.error
                              : t.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          // ── Zona inferior — teclado sem container visível ─────────────
          SizedBox(
            height: keypadH + botPad,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                child: _Keypad(
                  btnColor: t.cardAlt,
                  textColor: t.text,
                  iconColor: t.textSecondary,
                  onKey: _onKey,
                  onDelete: _onDel,
                  onToggleVisible: () =>
                      setState(() => _visible = !_visible),
                  isVisible: _visible,
                  processing: _processing,
                ),
              ),
            ),
          ),
        ]),

        // Toast
        if (_showToast)
          _TopToast(
            success: _toastSuccess,
            message: _toastMsg,
            onDone: () {
              if (mounted) setState(() => _showToast = false);
            },
          ),
      ]),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final Color btnColor;
  final Color textColor;
  final Color iconColor;
  final ValueChanged<String> onKey;
  final VoidCallback onDelete, onToggleVisible;
  final bool isVisible, processing;

  const _Keypad({
    required this.btnColor,
    required this.textColor,
    required this.iconColor,
    required this.onKey,
    required this.onDelete,
    required this.onToggleVisible,
    required this.isVisible,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        AnimatedOpacity(
          opacity: processing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _KeyBtn(
            btnColor: btnColor,
            onTap: onToggleVisible,
            enabled: !processing,
            child: Icon(
                isVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: iconColor,
                size: 22),
          ),
          _KeyBtn(
            btnColor: btnColor,
            onTap: () => onKey('0'),
            enabled: !processing,
            child: Text('0',
                style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w500)),
          ),
          _KeyBtn(
            btnColor: btnColor,
            onTap: onDelete,
            enabled: !processing,
            child: Icon(Icons.backspace_rounded, color: iconColor, size: 22),
          ),
        ]),
      ],
    );
  }

  Widget _buildRow(List<String> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys
            .map((k) => _KeyBtn(
                  btnColor: btnColor,
                  onTap: () => onKey(k),
                  enabled: !processing,
                  child: Text(k,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w500)),
                ))
            .toList(),
      );
}

// ── Botão do teclado — pill ───────────────────────────────────────────────────
class _KeyBtn extends StatefulWidget {
  final Color btnColor;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;
  const _KeyBtn({
    required this.btnColor,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });
  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 160),
        lowerBound: 0,
        upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   widget.enabled ? (_) => _c.forward()              : null,
      onTapUp:     widget.enabled ? (_) { _c.reverse(); widget.onTap(); } : null,
      onTapCancel: widget.enabled ? () => _c.reverse()               : null,
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: 88,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: widget.enabled
                ? widget.btnColor
                : widget.btnColor.withOpacity(0.4),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
