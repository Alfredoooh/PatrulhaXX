import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';

enum LockMode { unlock, setNew }

class LockScreen extends StatefulWidget {
  final LockMode mode;
  final VoidCallback? onUnlocked;
  final ValueChanged<String>? onPinSet;

  const LockScreen({super.key, this.mode = LockMode.unlock, this.onUnlocked, this.onPinSet});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _input = '';
  String? _firstPin;
  bool _error = false;
  bool _visible = false;

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
    if (widget.mode == LockMode.unlock) return 'Introduz o PIN';
    return _firstPin == null ? 'Novo PIN' : 'Confirmar PIN';
  }

  String get _subtitle {
    if (_error) {
      return widget.mode == LockMode.unlock
          ? 'PIN incorreto. Tenta novamente.'
          : 'PINs não coincidem. Começa de novo.';
    }
    if (widget.mode == LockMode.unlock) return 'Insere o código de acesso';
    return _firstPin == null ? 'Define um PIN (mínimo 4 dígitos)' : 'Repete o PIN';
  }

  void _onKey(String k) {
    if (_input.length >= 12) return;
    HapticFeedback.lightImpact();
    setState(() { _error = false; _input += k; });
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
      if (ok) {
        HapticFeedback.heavyImpact();
        widget.onUnlocked?.call();
      } else {
        _triggerError();
      }
      return;
    }

    if (_firstPin == null) {
      setState(() { _firstPin = _input; _input = ''; });
    } else {
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
    setState(() { _error = true; _input = ''; });
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 44),

          // Logo image
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
                  child: const Icon(Icons.lock_rounded, color: Colors.white38, size: 36),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(_title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_subtitle,
              style: TextStyle(
                  color: _error ? Colors.redAccent : Colors.white38,
                  fontSize: 13)),

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
                    width: filled ? 14 : 12,
                    height: filled ? 14 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error ? Colors.redAccent
                          : filled ? Colors.white : Colors.white12,
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
            onConfirm: _onConfirm,
            onToggleVisible: () => setState(() => _visible = !_visible),
            isVisible: _visible,
            canConfirm: _input.length >= 4,
          ),

          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final VoidCallback onToggleVisible;
  final bool isVisible;
  final bool canConfirm;

  const _Keypad({
    required this.onKey, required this.onDelete, required this.onConfirm,
    required this.onToggleVisible, required this.isVisible, required this.canConfirm,
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
        // Bottom row: toggle visibility | 0 | delete
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _KeyBtn(
            onTap: onToggleVisible,
            child: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.white60, size: 20),
          ),
          _KeyBtn(onTap: () => onKey('0'),
              child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w400))),
          _KeyBtn(onTap: onDelete,
              child: const Icon(Icons.backspace_rounded, color: Colors.white60, size: 20)),
        ]),
        const SizedBox(height: 20),
        // Confirm
        GestureDetector(
          onTap: canConfirm ? onConfirm : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52, width: double.infinity,
            decoration: BoxDecoration(
              color: canConfirm ? Colors.white : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_rounded,
                  color: canConfirm ? Colors.black87 : Colors.white.withOpacity(0.2),
                  size: 20),
              const SizedBox(width: 8),
              Text('Confirmar',
                  style: TextStyle(
                      color: canConfirm ? Colors.black87 : Colors.white.withOpacity(0.2),
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _KeyBtn(
        onTap: () => onKey(k),
        child: Text(k, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w400)),
      )).toList(),
    );
  }
}

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
        reverseDuration: const Duration(milliseconds: 160),
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
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
