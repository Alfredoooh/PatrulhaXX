import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/lock_service.dart';
import '../theme/app_theme.dart';

enum LockMode { unlock, setNew }

// ═════════════════════════════════════════════════════════════════════════════
// Toast de feedback no topo
// ═════════════════════════════════════════════════════════════════════════════
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
      top: topPad + 10, left: 20, right: 20,
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
                    child: Lottie.asset(
                      widget.success
                          ? 'assets/lottie/tick_mark.json'
                          : 'assets/lottie/wrong_feedback.json',
                      repeat: false, fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.message,
                      style: TextStyle(color: Colors.black.withOpacity(0.80),
                          fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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

// ═════════════════════════════════════════════════════════════════════════════
// LockScreen - VERSÃO COM MAIS ANIMAÇÕES
// ═════════════════════════════════════════════════════════════════════════════
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
  bool _processing = false;

  AnimationController? _lottieCtrl;

  // ANIMAÇÃO 1: Shake quando erro
  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  // ANIMAÇÃO 2: Fade in dos dots
  late final AnimationController _dotsFade;
  late final Animation<double> _dotsFadeAnim;

  // ANIMAÇÃO 3: Success pulse
  late final AnimationController _successPulse;
  late final Animation<double> _successPulseAnim;

  final List<int> _keyTimestamps = [];

  @override
  void initState() {
    super.initState();
    
    // SHAKE animation
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));

    // DOTS FADE IN animation
    _dotsFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _dotsFadeAnim = CurvedAnimation(parent: _dotsFade, curve: Curves.easeOut);
    _dotsFade.forward();

    // SUCCESS PULSE animation
    _successPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _successPulseAnim = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _successPulse, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    _dotsFade.dispose();
    _successPulse.dispose();
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
    return _firstPin == null ? 'Define um PIN (mínimo 4 dígitos)' : 'Repete o PIN';
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
        // ANIMAÇÃO SUCCESS
        _successPulse.forward(from: 0);
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
      setState(() { _firstPin = _input; _input = ''; _keyTimestamps.clear(); _processing = false; });
      return;
    }

    if (_firstPin == _input) {
      await LockService.instance.setPin(_input);
      if (mounted) {
        _showTopToast(success: true, msg: 'PIN definido!');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) widget.onPinSet?.call(_input);
      }
    } else {
      _showTopToast(success: false, msg: 'PINs não coincidem.');
      _triggerError();
      setState(() { _firstPin = null; _input = ''; _keyTimestamps.clear(); _processing = false; });
    }
  }

  void _triggerError() {
    setState(() => _error = true);
    HapticFeedback.vibrate();
    _shake.forward(from: 0);
    _keyTimestamps.clear();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() { _input = ''; _error = false; });
    });
  }

  void _showTopToast({required bool success, required String msg}) {
    setState(() {
      _showToast = true;
      _toastSuccess = success;
      _toastMsg = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final botPad = MediaQuery.of(context).padding.bottom;
    final keypadH = sz.height * 0.48;

    return AppThemeBuilder(builder: (context, theme) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: Stack(children: [
          Column(children: [
            // ZONA SUPERIOR — título + dots
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título com fade in
                    FadeTransition(
                      opacity: _dotsFadeAnim,
                      child: Text(_title,
                        style: GoogleFonts.playfairDisplay(
                          color: theme.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo / erro
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(_subtitle,
                        key: ValueKey(_subtitle),
                        style: TextStyle(
                          color: _error ? AppTheme.error : theme.textSub,
                          fontSize: 13,
                        )),
                    ),

                    const SizedBox(height: 32),

                    // Dots com SHAKE e FADE IN
                    FadeTransition(
                      opacity: _dotsFadeAnim,
                      child: AnimatedBuilder(
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
                              
                              return AnimatedBuilder(
                                animation: _successPulseAnim,
                                builder: (_, child) {
                                  final scale = filled && _toastSuccess ? _successPulseAnim.value : 1.0;
                                  return Transform.scale(scale: scale, child: child);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  width: filled ? 16 : 13,
                                  height: filled ? 16 : 13,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _error
                                        ? AppTheme.error
                                        : filled
                                            ? AppTheme.accent
                                            : theme.divider,
                                    boxShadow: filled && !_error
                                        ? [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 6)]
                                        : null,
                                  ),
                                  child: ch != null
                                      ? Center(child: Text(ch,
                                          style: const TextStyle(color: Colors.white, fontSize: 9,
                                              fontWeight: FontWeight.bold)))
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ZONA INFERIOR — teclado
            Container(
              height: keypadH + botPad,
              decoration: BoxDecoration(
                color: theme.cardAlt,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 12),
                  child: _Keypad(
                    onKey: _onKey,
                    onDelete: _onDel,
                    onToggleVisible: () => setState(() => _visible = !_visible),
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
              onDone: () { if (mounted) setState(() => _showToast = false); },
            ),
        ]),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Keypad
// ═════════════════════════════════════════════════════════════════════════════
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete, onToggleVisible;
  final bool isVisible, processing;

  const _Keypad({
    required this.onKey, required this.onDelete,
    required this.onToggleVisible, required this.isVisible,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AnimatedOpacity(
            opacity: processing ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildRow(['1', '2', '3'], theme),
          _buildRow(['4', '5', '6'], theme),
          _buildRow(['7', '8', '9'], theme),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _KeyBtn(onTap: onToggleVisible, enabled: !processing, theme: theme,
              child: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: theme.iconSub, size: 22)),
            _KeyBtn(onTap: () => onKey('0'), enabled: !processing, theme: theme,
              child: Text('0', style: TextStyle(color: theme.text, fontSize: 28, fontWeight: FontWeight.w300))),
            _KeyBtn(onTap: onDelete, enabled: !processing, theme: theme,
              child: Icon(Icons.backspace_rounded, color: theme.iconSub, size: 22)),
          ]),
        ],
      );
    });
  }

  Widget _buildRow(List<String> keys, AppTheme theme) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: keys.map((k) => _KeyBtn(
      onTap: () => onKey(k), enabled: !processing, theme: theme,
      child: Text(k, style: TextStyle(
          color: theme.text, fontSize: 28, fontWeight: FontWeight.w300)),
    )).toList(),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Botão do teclado — COM SCALE ANIMATION e RIPPLE
// ═════════════════════════════════════════════════════════════════════════════
class _KeyBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;
  final AppTheme theme;
  const _KeyBtn({required this.onTap, required this.child, this.enabled = true, required this.theme});
  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 160),
        lowerBound: 0, upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _ripple = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled ? (_) { _c.reverse(); widget.onTap(); } : null,
      onTapCancel: widget.enabled ? () => _c.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // RIPPLE EFFECT
            AnimatedBuilder(
              animation: _ripple,
              builder: (_, __) => Container(
                width: 74 + (30 * _ripple.value),
                height: 74 + (30 * _ripple.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.15 * (1 - _ripple.value)),
                ),
              ),
            ),
            // BOTÃO
            Container(
              width: 74, height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.enabled ? widget.theme.card : widget.theme.card.withOpacity(0.4),
              ),
              child: Center(child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LockSetupScreen - Tela para configurar PIN
// ═════════════════════════════════════════════════════════════════════════════
class LockSetupScreen extends StatelessWidget {
  const LockSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LockScreen(
      mode: LockMode.setNew,
      onPinSet: (pin) => Navigator.pop(context, true),
    );
  }
}
