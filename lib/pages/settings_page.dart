import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';
import 'lock_screen.dart';

const _iSettings = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1,4.75H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2ZM7.333,2a1.75,1.75,0,1,1-1.75,1.75A1.752,1.752,0,0,1,7.333,2Z"/><path d="M23,11H20.264a3.727,3.727,0,0,0-7.194,0H1a1,1,0,0,0,0,2H13.07a3.727,3.727,0,0,0,7.194,0H23a1,1,0,0,0,0-2Zm-6.333,2.75A1.75,1.75,0,1,1,18.417,12,1.752,1.752,0,0,1,16.667,13.75Z"/><path d="M23,19.25H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2ZM7.333,22a1.75,1.75,0,1,1,1.75-1.75A1.753,1.753,0,0,1,7.333,22Z"/></svg>';
const _iLock   = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M19,10h-1V7A7,7,0,0,0,5,7v3H4a3,3,0,0,0-3,3V21a3,3,0,0,0,3,3H19a3,3,0,0,0,3-3V13A3,3,0,0,0,19,10ZM7,7a5,5,0,0,1,10,0v3H7Zm8,10.723V19a1,1,0,0,1-2,0V17.723a2,2,0,1,1,2,0Z"/></svg>';
const _iTrash  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M21,4H17.9A5.009,5.009,0,0,0,13,0H11A5.009,5.009,0,0,0,6.1,4H3A1,1,0,0,0,3,6H4V19a5.006,5.006,0,0,0,5,5h6a5.006,5.006,0,0,0,5-5V6h1a1,1,0,0,0,0-2ZM11,2h2a3.006,3.006,0,0,1,2.829,2H8.171A3.006,3.006,0,0,1,11,2Zm7,17a3,3,0,0,1-3,3H9a3,3,0,0,1-3-3V6H18Z"/><path d="M10,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,10,18Z"/><path d="M14,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,14,18Z"/></svg>';
const _iReload = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,0c-2.991,0-5.813,1.113-8,3.078V1c0-.553-.448-1-1-1s-1,.447-1,1V5c0,1.103,.897,2,2,2h4c.552,0,1-.447,1-1s-.448-1-1-1h-3.13c1.876-1.913,4.422-3,7.13-3,5.514,0,10,4.486,10,10s-4.486,10-10,10c-5.21,0-9.492-3.908-9.959-9.09-.049-.55-.526-.956-1.086-.906C.405,12.054,0,12.54,.049,13.09c.561,6.22,5.699,10.91,11.951,10.91,6.617,0,12-5.383,12-12S18.617,0,12,0Z"/></svg>';

const _secureChannel = MethodChannel('com.patrulhaxx/secure');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lock = false;
  final _ts = ThemeService.instance;

  // cores base do tema
  Color get _bg    => _ts.isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
  Color get _card  => _ts.isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _text  => _ts.isDark ? Colors.white : Colors.black;
  Color get _sub   => _ts.isDark ? Colors.white54 : Colors.black45;
  Color get _div   => _ts.isDark ? Colors.white12 : Colors.black12;

  @override
  void initState() {
    super.initState();
    LockService.instance.isEnabled()
        .then((v) { if (mounted) setState(() => _lock = v); });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1C1C1C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _applySecure(bool v) {
    try { _secureChannel.invokeMethod('setSecure', {'enable': v}); } catch (_) {}
  }

  void _pinSheet({required LockMode mode, required VoidCallback onDone}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
            color: Color(0xFF0C0C0C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: mode == LockMode.unlock
              ? LockScreen(mode: LockMode.unlock,
                  onUnlocked: () { Navigator.pop(context); onDone(); })
              : LockScreen(mode: LockMode.setNew,
                  onPinSet: (p) async {
                    await LockService.instance.setPin(p);
                    if (mounted) { Navigator.pop(context); onDone(); }
                  }),
        ),
      ),
    );
  }

  void _pickLockDelay() {
    final opts   = [0,5,10,30,60,120,300,600,1800,3600,7200,14400];
    final labels = ['Imediato','5 seg','10 seg','30 seg','1 min',
                    '2 min','5 min','10 min','30 min','1 hora','2 horas','4 horas'];
    int idx = opts.indexOf(_ts.lockDelay).clamp(0, opts.length - 1);
    _picker('Bloquear após',
      CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: idx),
        itemExtent: 44, looping: false,
        onSelectedItemChanged: (i) => idx = i,
        children: labels.map((l) => Center(child: Text(l,
            style: TextStyle(color: _text, fontSize: 16)))).toList(),
      ),
      () { _ts.setLockDelay(opts[idx]); setState(() {}); },
    );
  }

  void _pickVolume() {
    int vol = _ts.maxVolume;
    _picker('Volume máximo',
      CupertinoPicker(
        scrollController: FixedExtentScrollController(
            initialItem: ((vol ~/ 10) - 1).clamp(0, 9)),
        itemExtent: 44, looping: false,
        onSelectedItemChanged: (i) => vol = (i + 1) * 10,
        children: List.generate(10, (i) => Center(child: Text('${(i+1)*10}%',
            style: TextStyle(color: _text, fontSize: 16)))),
      ),
      () { _ts.setMaxVolume(vol); setState(() {}); },
    );
  }

  void _pickEngine() {
    final keys = ThemeService.engines.keys.toList();
    int idx = keys.indexOf(_ts.engine).clamp(0, keys.length - 1);
    _picker('Motor de pesquisa',
      CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: idx),
        itemExtent: 44, looping: false,
        onSelectedItemChanged: (i) => idx = i,
        children: ThemeService.engines.values.map((v) => Center(child: Text(v,
            style: TextStyle(color: _text, fontSize: 16)))).toList(),
      ),
      () { _ts.setEngine(keys[idx]); setState(() {}); },
    );
  }

  void _picker(String title, Widget child, VoidCallback onOk) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: _div,
                borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Spacer(),
            Text(title, style: TextStyle(color: _text, fontSize: 15,
                fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () { Navigator.pop(context); onOk(); },
              child: Text('OK', style: TextStyle(color: _ts.isDark
                  ? Colors.white : Colors.blue,
                  fontWeight: FontWeight.w700))),
          ]),
        ),
        SizedBox(height: 180, child: child),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _pickWallpaper() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: _div,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        Text('Fundo de ecrã', style: TextStyle(color: _text,
            fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ThemeService.wallpapers.length,
          itemBuilder: (_, i) {
            final wp = ThemeService.wallpapers[i];
            final sel = wp == _ts.bg;
            return GestureDetector(
              onTap: () { _ts.setBg(wp); setState(() {}); Navigator.pop(context); },
              child: Container(
                width: 90, height: 160, margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? (_ts.isDark ? Colors.white : Colors.black)
                                 : Colors.transparent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(wp, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.05))),
                ),
              ),
            );
          },
        )),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
    child: Text(t.toUpperCase(), style: TextStyle(color: _sub,
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  Widget _section(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: _card,
        borderRadius: BorderRadius.circular(16)),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );

  Widget _divider() =>
      Divider(height: 1, color: _div, indent: 52, endIndent: 16);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ts,
      builder: (_, __) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: _text, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Definições', style: TextStyle(color: _text,
              fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [

            // ── Aparência ────────────────────────────────────────────
            _label('Aparência'),
            _section([
              _SwitchRow(svg: _iSettings, label: 'Tema escuro',
                  sub: _ts.isDark ? 'Modo escuro ativo' : 'Modo claro ativo',
                  value: _ts.isDark, textColor: _text, subColor: _sub,
                  onChanged: (v) { _ts.setDark(v); setState(() {}); }),
              _divider(),
              _TapRow(svg: _iReload, label: 'Fundo de ecrã',
                  sub: _ts.bg.split('/').last,
                  textColor: _text, subColor: _sub,
                  onTap: _pickWallpaper),
            ]),
            const SizedBox(height: 16),

            // ── Segurança ────────────────────────────────────────────
            _label('Segurança'),
            _section([
              _SwitchRow(svg: _iLock, label: 'Bloquear app',
                  sub: _lock ? 'PIN obrigatório' : 'Sem bloqueio',
                  value: _lock, textColor: _text, subColor: _sub,
                  onChanged: (v) {
                    _pinSheet(mode: LockMode.unlock, onDone: () async {
                      await LockService.instance.setEnabled(v);
                      if (mounted) setState(() => _lock = v);
                    });
                  }),
              if (_lock) ...[
                _divider(),
                _TapRow(svg: _iLock, label: 'Alterar PIN',
                    sub: 'Muda o código de acesso',
                    textColor: _text, subColor: _sub,
                    onTap: () => _pinSheet(mode: LockMode.setNew,
                        onDone: () => _snack('PIN alterado'))),
                _divider(),
                _TapRow(svg: _iSettings, label: 'Bloquear após',
                    sub: _ts.lockDelayLabel, textColor: _text, subColor: _sub,
                    onTap: _pickLockDelay),
              ],
            ]),
            const SizedBox(height: 16),

            // ── Privacidade ──────────────────────────────────────────
            _label('Privacidade'),
            _section([
              _SwitchRow(svg: _iLock, label: 'Privacidade nos recentes',
                  sub: _ts.privacyRecent
                      ? 'App aparece em preto' : 'Conteúdo visível',
                  value: _ts.privacyRecent, textColor: _text, subColor: _sub,
                  onChanged: (v) {
                    _ts.setPrivacyRecent(v); _applySecure(v); setState(() {});
                  }),
              _divider(),
              _SwitchRow(svg: _iLock, label: 'Bloquear capturas',
                  sub: _ts.noScreenshot
                      ? 'Screenshots bloqueados' : 'Screenshots permitidos',
                  value: _ts.noScreenshot, textColor: _text, subColor: _sub,
                  onChanged: (v) {
                    _ts.setNoScreenshot(v); _applySecure(v); setState(() {});
                  }),
            ]),
            const SizedBox(height: 16),

            // ── Navegação ────────────────────────────────────────────
            _label('Navegação'),
            _section([
              _TapRow(svg: _iSettings, label: 'Motor de pesquisa',
                  sub: ThemeService.engines[_ts.engine] ?? 'Google',
                  textColor: _text, subColor: _sub, onTap: _pickEngine),
              _divider(),
              _TapRow(svg: _iSettings, label: 'Volume máximo',
                  sub: '${_ts.maxVolume}%',
                  textColor: _text, subColor: _sub, onTap: _pickVolume),
            ]),
            const SizedBox(height: 16),

            // ── Manutenção ───────────────────────────────────────────
            _label('Manutenção'),
            _section([
              _TapRow(svg: _iReload, label: 'Recarregar ícones',
                  sub: 'Baixa novamente os favicons',
                  textColor: _text, subColor: _sub,
                  onTap: () async {
                    await FaviconService.instance.clearAll();
                    await FaviconService.instance.preloadAll();
                    if (context.mounted) _snack('Ícones recarregados');
                  }),
              _divider(),
              _TapRow(svg: _iTrash, label: 'Limpar downloads',
                  sub: 'Apaga todos os ficheiros',
                  textColor: _text, subColor: _sub,
                  destructive: true, onTap: _confirmClear),
            ]),
            const SizedBox(height: 16),

            // ── Sobre ────────────────────────────────────────────────
            _label('Sobre'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _card,
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // ícone do app em vez de SVG
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/logo.png',
                        width: 44, height: 44,
                        errorBuilder: (_, __, ___) => Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 24))),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('patrulhaXX', style: TextStyle(color: _text,
                        fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Versão 1.0.0 · Navegação privada',
                        style: TextStyle(color: _sub, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmClear() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: _div,
                  borderRadius: BorderRadius.circular(2)))),
          Text('Limpar downloads?', style: TextStyle(color: _text,
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: BorderSide(color: _div),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancelar'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                for (final item in DownloadService.instance.items.toList()) {
                  await DownloadService.instance.delete(item.id);
                }
                if (context.mounted) _snack('Downloads limpos');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Apagar tudo'),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Row widgets ───────────────────────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  final String svg, label, sub;
  final VoidCallback onTap;
  final Color textColor, subColor;
  final bool destructive;

  const _TapRow({required this.svg, required this.label, required this.sub,
      required this.onTap, required this.textColor, required this.subColor,
      this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final fgColor = destructive ? Colors.redAccent : textColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SvgPicture.string(svg, width: 20, height: 20,
              colorFilter: ColorFilter.mode(
                  destructive ? Colors.redAccent : subColor, BlendMode.srcIn)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label, style: TextStyle(color: fgColor, fontSize: 14,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String svg, label, sub;
  final bool value;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.svg, required this.label, required this.sub,
      required this.value, required this.textColor, required this.subColor,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SvgPicture.string(svg, width: 20, height: 20,
            colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
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
