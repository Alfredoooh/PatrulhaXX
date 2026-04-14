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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
  String _input = '';
  String? _firstPin;
  bool _error = false;
  bool _visible = false;
  bool _showToast = false;
  bool _toastSuccess = false;
  String _toastMsg = '';
  bool _processing = false;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  final List<int> _keyTimestamps = [];

  // PIN tem sempre 6 dígitos (como na imagem)
  static const int _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == LockMode.unlock) return 'Inserir Senha';
    return _firstPin == null ? 'Novo PIN' : 'Confirmar PIN';
  }

  String get _subtitle {
    if (_error) {
      return widget.mode == LockMode.unlock
          ? 'PIN incorreto. Tenta novamente.'
          : 'PINs não coincidem. Começa de novo.';
    }
    if (widget.mode == LockMode.unlock) return 'Digite sua senha de pagamento.';
    return _firstPin == null
        ? 'Define um PIN de 6 dígitos.'
        : 'Digite novamente para confirmar.';
  }

  void _onKey(String k) {
    if (_processing) return;
    if (_input.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    _keyTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _error = false;
      _input += k;
    });
    // Confirma automaticamente ao atingir o comprimento total
    if (_input.length == _pinLength && !_processing) {
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
    if (_input.length < 4) {
      _triggerError();
      return;
    }
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
    setState(() {
      _error = true;
      _input = '';
    });
    _shake.forward(from: 0);
  }

  void _showTopToast({required bool success, required String msg}) {
    if (!mounted) return;
    setState(() {
      _toastSuccess = success;
      _toastMsg = msg;
      _showToast = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cores pixel-perfect da imagem
    final headerBg     = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEEEFF4);
    final keypadBg     = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final keyBg        = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
    final keyText      = isDark ? Colors.white            : Colors.black;
    final dividerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6);
    final digitBoxBg   = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFDDDDE3);
    final titleColor   = isDark ? Colors.white            : Colors.black;
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.50)
        : Colors.black.withOpacity(0.45);

    return Scaffold(
      backgroundColor: headerBg,
      body: Stack(children: [
        Column(children: [
          // ── Zona superior ──────────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie — animação do cadeado
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/lottie/lock.json',
                    repeat: true,
                    animate: true,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.lock_rounded,
                      size: 56,
                      color: isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.25),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Título
                Text(
                  _title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtítulo / erro
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _subtitle,
                    key: ValueKey(_subtitle),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error ? AppTheme.error : subtitleColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Digit boxes — pixel-perfect da imagem ──────────────
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0), child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (i) {
                        final filled = i < _input.length;
                        final ch = filled && _visible ? _input[i] : null;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 52,
                              decoration: BoxDecoration(
                                color: _error
                                    ? AppTheme.error.withOpacity(0.15)
                                    : filled
                                        ? digitBoxBg
                                        : digitBoxBg.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _error
                                      ? AppTheme.error.withOpacity(0.4)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: ch != null
                                    ? Text(
                                        ch,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : filled
                                        ? Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _error
                                                  ? AppTheme.error
                                                  : titleColor,
                                            ),
                                          )
                                        : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Teclado numérico — pixel-perfect da imagem ─────────────────
          _Keypad(
            keypadBg: keypadBg,
            keyBg: keyBg,
            keyText: keyText,
            dividerColor: dividerColor,
            onKey: _onKey,
            onDelete: _onDel,
            onToggleVisible: () => setState(() => _visible = !_visible),
            isVisible: _visible,
            processing: _processing,
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
// Grade com divisórias finas, botões de altura igual, sem padding lateral.
// Última linha: visibilidade | 0 | backspace
class _Keypad extends StatelessWidget {
  final Color keypadBg;
  final Color keyBg;
  final Color keyText;
  final Color dividerColor;
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisible;
  final bool isVisible;
  final bool processing;

  const _Keypad({
    required this.keypadBg,
    required this.keyBg,
    required this.keyText,
    required this.dividerColor,
    required this.onKey,
    required this.onDelete,
    required this.onToggleVisible,
    required this.isVisible,
    required this.processing,
  });

  // Cada linha do teclado tem altura fixa
  static const double _rowH = 72.0;

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: keypadBg,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Divisor topo
        Container(height: 1, color: dividerColor),

        // Loader subtil quando a processar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: processing ? 2 : 0,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
                keyText.withOpacity(0.15)),
          ),
        ),

        _buildRow(['1', '2', '3']),
        Container(height: 1, color: dividerColor),
        _buildRow(['4', '5', '6']),
        Container(height: 1, color: dividerColor),
        _buildRow(['7', '8', '9']),
        Container(height: 1, color: dividerColor),

        // Última linha: visibilidade | 0 | backspace
        SizedBox(
          height: _rowH,
          child: Row(children: [
            // Visibilidade — fundo ligeiramente diferente (como na imagem)
            Expanded(
              child: _KeyBtn(
                keyBg: keypadBg,
                onTap: onToggleVisible,
                enabled: !processing,
                child: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: keyText.withOpacity(0.6),
                  size: 22,
                ),
              ),
            ),
            Container(width: 1, height: _rowH, color: dividerColor),
            Expanded(
              child: _KeyBtn(
                keyBg: keyBg,
                onTap: () => onKey('0'),
                enabled: !processing,
                child: Text('0',
                    style: TextStyle(
                      color: keyText,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                    )),
              ),
            ),
            Container(width: 1, height: _rowH, color: dividerColor),
            Expanded(
              child: _KeyBtn(
                keyBg: keypadBg,
                onTap: onDelete,
                enabled: !processing,
                child: Icon(
                  Icons.backspace_outlined,
                  color: keyText.withOpacity(0.6),
                  size: 22,
                ),
              ),
            ),
          ]),
        ),

        // Safe area bottom
        SizedBox(height: botPad),
      ]),
    );
  }

  Widget _buildRow(List<String> keys) {
    return SizedBox(
      height: _rowH,
      child: Row(children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0)
            Container(width: 1, height: _rowH, color: dividerColor),
          Expanded(
            child: _KeyBtn(
              keyBg: keyBg,
              onTap: () => onKey(keys[i]),
              enabled: !processing,
              child: Text(
                keys[i],
                style: TextStyle(
                  color: keyText,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Botão do teclado ──────────────────────────────────────────────────────────
class _KeyBtn extends StatefulWidget {
  final Color keyBg;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;
  const _KeyBtn({
    required this.keyBg,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });
  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: double.infinity,
        height: double.infinity,
        color: _pressed
            ? widget.keyBg.withOpacity(0.45)
            : widget.keyBg,
        child: Center(child: widget.child),
      ),
    );
  }
}
