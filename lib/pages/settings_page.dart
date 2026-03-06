import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';
import 'lock_screen.dart';

// ── SVG icons ─────────────────────────────────────────────────────────────────
const _iSettings = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1,4.75H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2ZM7.333,2a1.75,1.75,0,1,1-1.75,1.75A1.752,1.752,0,0,1,7.333,2Z"/><path d="M23,11H20.264a3.727,3.727,0,0,0-7.194,0H1a1,1,0,0,0,0,2H13.07a3.727,3.727,0,0,0,7.194,0H23a1,1,0,0,0,0-2Zm-6.333,2.75A1.75,1.75,0,1,1,18.417,12,1.752,1.752,0,0,1,16.667,13.75Z"/><path d="M23,19.25H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2ZM7.333,22a1.75,1.75,0,1,1,1.75-1.75A1.753,1.753,0,0,1,7.333,22Z"/></svg>';
const _iLock   = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M11,15c0,.553-.448,1-1,1H5c-2.757,0-5-2.243-5-5v-3C0,5.243,2.243,3,5,3h14c2.757,0,5,2.243,5,5,0,.553-.447,1-1,1s-1-.447-1-1c0-1.654-1.346-3-3-3H5c-1.654,0-3,1.346-3,3v3c0,1.654,1.346,3,3,3h5c.552,0,1,.447,1,1Zm-2.293-7.707c-.391-.391-1.023-.391-1.414,0l-.793,.793-.793-.793c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414l.793,.793-.793,.793c-.391,.391-.391,1.023,0,1.414,.195,.195,.451,.293,.707,.293s.512-.098,.707-.293l.793-.793,.793,.793c.195,.195,.451,.293,.707,.293s.512-.098,.707-.293c.391-.391,.391-1.023,0-1.414l-.793-.793,.793-.793c.391-.391,.391-1.023,0-1.414Zm6,1.414c.391-.391,.391-1.023,0-1.414s-1.023-.391-1.414,0l-.793,.793-.793-.793c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414l.793,.793-.793,.793c-.391,.391-.391,1.023,0,1.414,.195,.195,.451,.293,.707,.293s.512-.098,.707-.293l3-3Zm9.293,9.293v2c0,2.206-1.794,4-4,4h-4c-2.206,0-4-1.794-4-4v-2c0-1.474,.81-2.75,2-3.444v-1.556c0-2.206,1.794-4,4-4s4,1.794,4,4v1.556c1.19,.694,2,1.97,2,3.444Zm-8-4h4v-1c0-1.103-.897-2-2-2s-2,.897-2,2v1Zm6,4c0-1.103-.897-2-2-2h-4c-1.103,0-2,.897-2,2v2c0,1.103,.897,2,2,2h4c1.103,0,2-.897,2-2v-2Zm-4-.5c-.828,0-1.5,.672-1.5,1.5s.672,1.5,1.5,1.5,1.5-.672,1.5-1.5-.672-1.5-1.5-1.5Z"/></svg>';
const _iTrash  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M21,4H17.9A5.009,5.009,0,0,0,13,0H11A5.009,5.009,0,0,0,6.1,4H3A1,1,0,0,0,3,6H4V19a5.006,5.006,0,0,0,5,5h6a5.006,5.006,0,0,0,5-5V6h1a1,1,0,0,0,0-2ZM11,2h2a3.006,3.006,0,0,1,2.829,2H8.171A3.006,3.006,0,0,1,11,2Zm7,17a3,3,0,0,1-3,3H9a3,3,0,0,1-3-3V6H18Z"/><path d="M10,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,10,18Z"/><path d="M14,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,14,18Z"/></svg>';
const _iReload = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,0c-2.991,0-5.813,1.113-8,3.078V1c0-.553-.448-1-1-1s-1,.447-1,1V5c0,1.103,.897,2,2,2h4c.552,0,1-.447,1-1s-.448-1-1-1h-3.13c1.876-1.913,4.422-3,7.13-3,5.514,0,10,4.486,10,10s-4.486,10-10,10c-5.21,0-9.492-3.908-9.959-9.09-.049-.55-.526-.956-1.086-.906C.405,12.054,0,12.54,.049,13.09c.561,6.22,5.699,10.91,11.951,10.91,6.617,0,12-5.383,12-12S18.617,0,12,0Z"/></svg>';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lock = false;
  final _ts = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    LockService.instance.isEnabled().then((v) {
      if (mounted) setState(() => _lock = v);
    });
  }

  // ── helpers ─────────────────────────────────────────────────────────────────
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: const Color(0xFF1C1C1C),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));

  void _pinSheet({required LockMode mode, required VoidCallback onDone}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _PinSheet(child: mode == LockMode.unlock
          ? LockScreen(mode: LockMode.unlock, onUnlocked: () { Navigator.pop(context); onDone(); })
          : LockScreen(mode: LockMode.setNew,  onPinSet: (p) async {
              await LockService.instance.setPin(p);
              if (mounted) { Navigator.pop(context); onDone(); }
            })),
    );
  }

  // ── Lock delay picker (iOS wheel style) ────────────────────────────────────
  void _pickLockDelay() {
    // Preset options in seconds
    final options = [0, 5, 10, 30, 60, 120, 300, 600, 1800, 3600, 7200, 14400];
    final labels  = ['Imediato','5 seg','10 seg','30 seg','1 min',
                     '2 min','5 min','10 min','30 min','1 hora','2 horas','4 horas'];
    int idx = options.indexOf(_ts.lockDelay);
    if (idx < 0) idx = 0;
    final ctrl = FixedExtentScrollController(initialItem: idx);

    _showPickerSheet(
      title: 'Bloquear após',
      child: CupertinoPicker(
        scrollController: ctrl,
        itemExtent: 44,
        looping: false,
        onSelectedItemChanged: (i) => idx = i,
        children: labels.map((l) => Center(child: Text(l,
            style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
      ),
      onConfirm: () {
        _ts.setLockDelay(options[idx]);
        setState(() {});
      },
    );
  }

  // ── Volume picker ──────────────────────────────────────────────────────────
  void _pickVolume() {
    int vol = _ts.maxVolume;
    _showPickerSheet(
      title: 'Volume máximo',
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(
            initialItem: ((vol ~/ 10) - 1).clamp(0, 9)),
        itemExtent: 44, looping: false,
        onSelectedItemChanged: (i) => vol = (i + 1) * 10,
        children: List.generate(10, (i) => Center(child: Text(
            '${(i + 1) * 10}%',
            style: const TextStyle(color: Colors.white, fontSize: 16)))),
      ),
      onConfirm: () { _ts.setMaxVolume(vol); setState(() {}); },
    );
  }

  // ── Search engine picker ───────────────────────────────────────────────────
  void _pickEngine() {
    final keys = ThemeService.engines.keys.toList();
    int idx = keys.indexOf(_ts.engine);
    if (idx < 0) idx = 0;
    _showPickerSheet(
      title: 'Motor de pesquisa',
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: idx),
        itemExtent: 44, looping: false,
        onSelectedItemChanged: (i) => idx = i,
        children: ThemeService.engines.values.map((v) => Center(child: Text(v,
            style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
      ),
      onConfirm: () { _ts.setEngine(keys[idx]); setState(() {}); },
    );
  }

  // ── Wallpaper picker ───────────────────────────────────────────────────────
  void _pickWallpaper() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          const Text('Fundo de ecrã', style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ThemeService.wallpapers.length,
              itemBuilder: (_, i) {
                final wp = ThemeService.wallpapers[i];
                final sel = wp == _ts.bg;
                return GestureDetector(
                  onTap: () { _ts.setBg(wp); setState(() {}); Navigator.pop(context); },
                  child: Container(
                    width: 100, height: 160,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? Colors.white : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(wp, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.05),
                              child: const Icon(Icons.image_outlined,
                                  color: Colors.white24))),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Generic iOS-style picker sheet ─────────────────────────────────────────
  void _showPickerSheet({
    required String title,
    required Widget child,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Spacer(),
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () { Navigator.pop(context); onConfirm(); },
                child: const Text('OK', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          SizedBox(height: 180, child: child),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _BlurAppBar(title: 'Definições'),
      body: AnimatedBuilder(
        animation: _ts,
        builder: (_, __) => ListView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16, bottom: 24,
          ),
          children: [

            // ── Aparência ──────────────────────────────────────────────
            _Section(children: [
              _SwitchRow(
                svg: _iSettings,
                label: 'Tema escuro',
                sub: _ts.isDark ? 'Modo escuro ativo' : 'Modo claro ativo',
                value: _ts.isDark,
                onChanged: (v) { _ts.setDark(v); setState(() {}); },
              ),
              _div(),
              _TapRow(
                svg: _iReload,
                label: 'Fundo de ecrã',
                sub: _ts.bg.split('/').last,
                onTap: _pickWallpaper,
              ),
            ]),

            _label('APARÊNCIA'),
            const SizedBox(height: 16),

            // ── Segurança ──────────────────────────────────────────────
            _Section(children: [
              _SwitchRow(
                svg: _iLock,
                label: 'Bloquear app',
                sub: _lock ? 'PIN obrigatório ao abrir' : 'Sem bloqueio',
                value: _lock,
                onChanged: (v) {
                  _pinSheet(mode: LockMode.unlock, onDone: () async {
                    await LockService.instance.setEnabled(v);
                    if (mounted) setState(() => _lock = v);
                    _snack(v ? 'Bloqueio ativado' : 'Bloqueio desativado');
                  });
                },
              ),
              if (_lock) ...[
                _div(),
                _TapRow(
                  svg: _iLock,
                  label: 'Alterar PIN',
                  sub: 'Muda o código de acesso',
                  onTap: () => _pinSheet(
                    mode: LockMode.setNew,
                    onDone: () => _snack('PIN alterado'),
                  ),
                ),
                _div(),
                _TapRow(
                  svg: _iSettings,
                  label: 'Bloquear após',
                  sub: _ts.lockDelayLabel,
                  onTap: _pickLockDelay,
                ),
              ],
            ]),

            _label('SEGURANÇA'),
            const SizedBox(height: 16),

            // ── Privacidade ────────────────────────────────────────────
            _Section(children: [
              _SwitchRow(
                svg: _iLock,
                label: 'Privacidade nos recentes',
                sub: _ts.privacyRecent
                    ? 'App aparece em preto nos recentes'
                    : 'Conteúdo visível nos recentes',
                value: _ts.privacyRecent,
                onChanged: (v) {
                  _ts.setPrivacyRecent(v);
                  // Update FLAG_SECURE via native channel
                  const ch = MethodChannelHelper._ch;
                  try { ch.invokeMethod('setSecure', {'enable': v}); } catch(_){}
                  setState(() {});
                },
              ),
              _div(),
              _SwitchRow(
                svg: _iLock,
                label: 'Bloquear capturas',
                sub: _ts.noScreenshot ? 'Screenshots bloqueados' : 'Screenshots permitidos',
                value: _ts.noScreenshot,
                onChanged: (v) {
                  _ts.setNoScreenshot(v);
                  const ch = MethodChannelHelper._ch;
                  try { ch.invokeMethod('setSecure', {'enable': v}); } catch(_){}
                  setState(() {});
                },
              ),
            ]),

            _label('PRIVACIDADE'),
            const SizedBox(height: 16),

            // ── Navegação ──────────────────────────────────────────────
            _Section(children: [
              _TapRow(
                svg: _iSettings,
                label: 'Motor de pesquisa',
                sub: ThemeService.engines[_ts.engine] ?? 'Google',
                onTap: _pickEngine,
              ),
              _div(),
              _TapRow(
                svg: _iSettings,
                label: 'Volume máximo',
                sub: '${_ts.maxVolume}%',
                onTap: _pickVolume,
              ),
            ]),

            _label('NAVEGAÇÃO'),
            const SizedBox(height: 16),

            // ── Manutenção ─────────────────────────────────────────────
            _Section(children: [
              _TapRow(
                svg: _iReload,
                label: 'Recarregar ícones',
                sub: 'Baixa novamente os favicons',
                onTap: () async {
                  await FaviconService.instance.clearAll();
                  await FaviconService.instance.preloadAll();
                  if (context.mounted) _snack('Ícones recarregados');
                },
              ),
              _div(),
              _TapRow(
                svg: _iTrash,
                label: 'Limpar downloads',
                sub: 'Apaga todos os ficheiros baixados',
                onTap: () => _confirmClear(context),
                destructive: true,
              ),
            ]),

            _label('MANUTENÇÃO'),
            const SizedBox(height: 16),

            // ── Sobre ──────────────────────────────────────────────────
            _Section(children: [
              _TapRow(
                svg: _iSettings,
                label: 'patrulhaXX',
                sub: 'Versão 1.0.0 · Navegação privada',
                onTap: () {},
              ),
            ]),

            _label('SOBRE'),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
    child: Text(t, style: TextStyle(
        color: Colors.white.withOpacity(0.3), fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );

  Widget _div() => Divider(height: 1,
      color: Colors.white.withOpacity(0.06), indent: 16, endIndent: 16);

  void _confirmClear(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Limpar downloads?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('Cancelar',
                    style: TextStyle(color: Colors.white70)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                for (final item in DownloadService.instance.items.toList()) {
                  await DownloadService.instance.delete(item.id);
                }
                if (context.mounted) _snack('Downloads limpos');
              },
              child: Container(height: 48,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('Apagar tudo',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)))),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blur AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _BlurAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _BlurAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xFF0C0C0C).withOpacity(0.7),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(title, style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section container with blur
// ─────────────────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String svg, label, sub;
  final VoidCallback onTap;
  final bool destructive;

  const _TapRow({required this.svg, required this.label, required this.sub,
      required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            SvgPicture.string(svg, width: 18, height: 18,
                colorFilter: ColorFilter.mode(
                    destructive ? Colors.redAccent : Colors.white60,
                    BlendMode.srcIn)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(
                  color: destructive ? Colors.redAccent : Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2), size: 18),
          ]),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String svg, label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.svg, required this.label, required this.sub,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SvgPicture.string(svg, width: 18, height: 18,
            colorFilter: const ColorFilter.mode(Colors.white60, BlendMode.srcIn)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
        Switch(
          value: value, onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF4A9EFF),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
        ),
      ]),
    );
  }
}

// Helper to access the MethodChannel from settings
class MethodChannelHelper {
  static const _ch = MethodChannel('com.patrulhaxx/secure');
}

class _PinSheet extends StatelessWidget {
  final Widget child;
  const _PinSheet({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.9,
    decoration: const BoxDecoration(color: Color(0xFF0C0C0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: child),
  );
}
