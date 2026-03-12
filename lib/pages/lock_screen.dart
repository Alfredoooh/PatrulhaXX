import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/lock_service.dart';

enum LockMode { unlock, setNew }

// ─── Cores ────────────────────────────────────────────────────────────────────
// Topo da tela (zona do logo + dots) — cor de fundo salmão clara
const _kTopBg    = Color(0xFFf5a992);
// Fundo do teclado — escuro
const _kKeypadBg = Color(0xFF1A1515);
// Cor dos botões do teclado — escuro um pouco mais claro que o fundo
const _kBtnColor = Color(0xFF2C2424);
// Raio da curva do container do teclado nas bordas de cima
const _kTopRadius = 36.0;

// ─── Toast topo estilo Samsung ────────────────────────────────────────────────
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
            begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
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

  // Bloquear confirmação dupla enquanto está a processar
  bool _processing = false;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  // Análise de padrão de digitação — timestamps de cada tecla para segurança
  final List<int> _keyTimestamps = [];
  final List<String> _keySequence = [];

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
    // Bloquear input enquanto está a processar verificação
    if (_processing) return;
    if (_input.length >= 12) return;

    HapticFeedback.lightImpact();

    // Registo de segurança: timestamp + tecla para análise de padrão
    _keyTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    _keySequence.add(k);

    setState(() {
      _error = false;
      _input += k;
    });

    // Auto-confirmar apenas se atingiu exactamente 4 dígitos mínimos
    // e não está já a processar
    if (_input.length >= 4 && !_processing) {
      // Pequeno delay para o utilizador ver o último dot preenchido
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_processing) _onConfirm();
      });
    }
  }

  void _onDel() {
    if (_processing) return;
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    // Remover último timestamp também
    if (_keyTimestamps.isNotEmpty) _keyTimestamps.removeLast();
    if (_keySequence.isNotEmpty) _keySequence.removeLast();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  // Análise invisível de padrão de digitação
  // Verifica se a velocidade de digitação é humana (anti-bot / anti-força-bruta)
  bool _isTypingPatternValid() {
    if (_keyTimestamps.length < 2) return true;
    // Se digitou tudo em menos de 200ms total → suspeito (bot ou macro)
    final total = _keyTimestamps.last - _keyTimestamps.first;
    if (total < 200 && _keyTimestamps.length >= 4) return false;
    // Verifica intervalos entre teclas — demasiado uniforme = suspeito
    final intervals = <int>[];
    for (int i = 1; i < _keyTimestamps.length; i++) {
      intervals.add(_keyTimestamps[i] - _keyTimestamps[i - 1]);
    }
    if (intervals.length >= 3) {
      final avg = intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals
          .map((v) => (v - avg) * (v - avg))
          .reduce((a, b) => a + b) / intervals.length;
      // Variância zero ou muito baixa = robô
      if (variance < 5.0 && avg < 100) return false;
    }
    return true;
  }

  Future<void> _onConfirm() async {
    // Guard: evitar chamadas duplas
    if (_processing) return;
    if (_input.length < 4) {
      _triggerError();
      return;
    }

    setState(() => _processing = true);

    // Análise de padrão de digitação
    if (!_isTypingPatternValid()) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _showTopToast(success: false, msg: 'Padrão suspeito detectado.');
        _triggerError();
        setState(() => _processing = false);
      }
      return;
    }

    // Delay mínimo de segurança: sempre 2 segundos antes de verificar
    final verifyFuture = widget.mode == LockMode.unlock
        ? LockService.instance.verify(_input)
        : Future.value(_firstPin == null ? true : _input == _firstPin);

    final results = await Future.wait([
      verifyFuture,
      Future.delayed(const Duration(seconds: 2)), // delay mínimo invariável
    ]);

    if (!mounted) return;

    final ok = results[0] as bool;

    if (widget.mode == LockMode.unlock) {
      if (ok) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'Bem-vindo de volta!');
        // Aguarda toast + transição
        await Future.delayed(const Duration(milliseconds: 800));
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
        _keySequence.clear();
        _processing = false;
      });
    } else {
      if (ok) {
        HapticFeedback.heavyImpact();
        _showTopToast(success: true, msg: 'PIN definido com sucesso!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onPinSet?.call(_input);
      } else {
        setState(() { _firstPin = null; });
        _showTopToast(success: false, msg: 'PINs não coincidem. Recomeça.');
        _triggerError();
        setState(() => _processing = false);
      }
    }
  }

  void _triggerError() {
    HapticFeedback.vibrate();
    _keyTimestamps.clear();
    _keySequence.clear();
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
    final screenH = MediaQuery.of(context).size.height;
    final topPad  = MediaQuery.of(context).padding.top;
    final botPad  = MediaQuery.of(context).padding.bottom;

    // Altura da zona do teclado — ocupa a metade inferior da tela
    final keypadH = screenH * 0.55;

    return Scaffold(
      // Impede que toques fora do teclado activem qualquer coisa
      backgroundColor: _kTopBg,
      body: Stack(children: [

        // ── Layout principal ──────────────────────────────────────────────
        Column(children: [

          // ZONA SUPERIOR — logo + título + dots (fundo salmão)
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 80, height: 80, fit: BoxFit.cover,
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

                  const SizedBox(height: 28),

                  // Título
                  Text(_title,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      )),

                  const SizedBox(height: 6),

                  // Subtítulo / erro
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(_subtitle,
                        key: ValueKey(_subtitle),
                        style: TextStyle(
                          color: _error
                              ? Colors.redAccent
                              : Colors.white70,
                          fontSize: 13,
                        )),
                  ),

                  const SizedBox(height: 28),

                  // Dots indicadores do PIN
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
                            margin:
                                const EdgeInsets.symmetric(horizontal: 6),
                            width: filled ? 16 : 13,
                            height: filled ? 16 : 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _error
                                  ? Colors.redAccent
                                  : filled
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.35),
                              boxShadow: filled && !_error
                                  ? [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(0.4),
                                          blurRadius: 6)
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
                ],
              ),
            ),
          ),

          // ZONA INFERIOR — teclado com fundo escuro e curva no topo
          Container(
            height: keypadH + botPad,
            decoration: BoxDecoration(
              color: _kKeypadBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_kTopRadius),
                topRight: Radius.circular(_kTopRadius),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 12),
                child: _Keypad(
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

        // Toast — sobreposto no topo, fora do Column
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
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisible;
  final bool isVisible;
  final bool processing;

  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onToggleVisible,
    required this.isVisible,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Indicador de processamento
        AnimatedOpacity(
          opacity: processing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf5a992)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _KeyBtn(
            onTap: onToggleVisible,
            enabled: !processing,
            child: Icon(
              isVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
          _KeyBtn(
            onTap: () => onKey('0'),
            enabled: !processing,
            child: const Text('0',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300)),
          ),
          _KeyBtn(
            onTap: onDelete,
            enabled: !processing,
            child: const Icon(Icons.backspace_rounded,
                color: Colors.white70, size: 22),
          ),
        ]),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((k) => _KeyBtn(
                onTap: () => onKey(k),
                enabled: !processing,
                child: Text(k,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w300)),
              ))
          .toList(),
    );
  }
}

// ── Botão do teclado — sólido, escuro, Android style ─────────────────────────
class _KeyBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;
  const _KeyBtn({
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

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
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 160),
        lowerBound: 0,
        upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.88)
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
      // Apenas responde a taps directos no botão
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => _c.reverse() : null,
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Escuro com ligeiro brilho — harmonioso com _kKeypadBg
            color: widget.enabled
                ? _kBtnColor
                : _kBtnColor.withOpacity(0.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
