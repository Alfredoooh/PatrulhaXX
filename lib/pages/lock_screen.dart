import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../services/lock_service.dart';

enum LockMode { unlock, setNew, confirmNew }

class LockScreen extends StatefulWidget {
  final LockMode mode;
  final VoidCallback? onUnlocked;
  final ValueChanged<String>? onPinSet; // devolve o PIN confirmado

  const LockScreen({
    super.key,
    this.mode = LockMode.unlock,
    this.onUnlocked,
    this.onPinSet,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  String? _firstPin; // guarda o 1º PIN durante confirmação
  bool _error = false;
  bool _obscure = true;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case LockMode.unlock:
        return 'Introduz o PIN';
      case LockMode.setNew:
        return _firstPin == null ? 'Novo PIN' : 'Confirmar PIN';
      case LockMode.confirmNew:
        return 'Confirmar PIN';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case LockMode.unlock:
        return 'Insere o teu PIN para continuar';
      case LockMode.setNew:
        return _firstPin == null
            ? 'Define um PIN (mínimo 4 dígitos)'
            : 'Repete o PIN para confirmar';
      case LockMode.confirmNew:
        return 'Repete o PIN para confirmar';
    }
  }

  void _onKey(String key) {
    if (_input.length >= 12) return;
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      _input += key;
    });
  }

  void _onDelete() {
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
      if (ok) {
        HapticFeedback.heavyImpact();
        widget.onUnlocked?.call();
      } else {
        _triggerError();
      }
      return;
    }

    // setNew / confirmNew
    if (_firstPin == null) {
      // Primeiro input — guarda e pede confirmação
      setState(() {
        _firstPin = _input;
        _input = '';
      });
    } else {
      // Segundo input — compara
      if (_input == _firstPin) {
        HapticFeedback.heavyImpact();
        widget.onPinSet?.call(_input);
      } else {
        setState(() => _firstPin = null);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Logo ────────────────────────────────────────────────────
            const Text(
              'patrulhaXX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // ── Título ──────────────────────────────────────────────────
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error
                  ? (widget.mode == LockMode.unlock
                      ? 'PIN incorreto. Tenta novamente.'
                      : 'PINs não coincidem. Começa de novo.')
                  : _subtitle,
              style: TextStyle(
                color: _error ? Colors.redAccent : Colors.white38,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 36),

            // ── Indicador de dots ───────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _input.isEmpty ? 4 : _input.length.clamp(4, 12),
                  (i) {
                    final filled = i < _input.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: filled ? 14 : 12,
                      height: filled ? 14 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? Colors.redAccent
                            : filled
                                ? Colors.white
                                : Colors.white12,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Toggle mostrar/ocultar PIN
            TextButton.icon(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Ionicons.eye_outline : Ionicons.eye_off_outline,
                size: 15,
                color: Colors.white30,
              ),
              label: Text(
                _obscure ? 'Mostrar' : 'Ocultar',
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ),

            if (!_obscure && _input.isNotEmpty) ...[
              Text(
                _input,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
            ],

            const Spacer(),

            // ── Teclado numérico ────────────────────────────────────────
            _Keypad(
              onKey: _onKey,
              onDelete: _onDelete,
              onConfirm: _onConfirm,
              canConfirm: _input.length >= 4,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Teclado ──────────────────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final bool canConfirm;

  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onConfirm,
    required this.canConfirm,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          ..._rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((k) => _buildKey(k)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Confirmar
          GestureDetector(
            onTap: canConfirm ? onConfirm : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: canConfirm ? Colors.white : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Confirmar',
                  style: TextStyle(
                    color: canConfirm ? Colors.black : Colors.white.withOpacity(0.2),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    if (label.isEmpty) return const SizedBox(width: 72, height: 60);

    if (label == 'del') {
      return _KeyButton(
        onTap: onDelete,
        child: const Icon(Ionicons.backspace_outline,
            color: Colors.white60, size: 20),
      );
    }

    return _KeyButton(
      onTap: () => onKey(label),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeyButton({required this.onTap, required this.child});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_press.value * 0.12),
          child: child,
        ),
        child: Container(
          width: 72,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
