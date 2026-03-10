import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';
import 'lock_screen.dart';

// ─── Cor primária ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFFF9000);

// ─── SVG Icons ────────────────────────────────────────────────────────────────

// Fundo de ecrã
const _iDark =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21.752,15.002A9,9,0,1,1,8.998,2.248,7,7,0,0,0,21.752,15.002Z"'
    ' fill="none" stroke="currentColor" stroke-width="1.8"'
    ' stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

const _iWallpaper =
    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
    '<g transform="matrix(1.3333333,0,0,-1.3333333,0,32)">'
    '<g><g clip-path="url(#c)">'
    '<g transform="translate(5,13)">'
    '<path d="m 0,0 c -2.209,0 -4,-1.791 -4,-4 v -4 c 0,-2.209 1.791,-4 4,-4 h 6 '
    'c 2.209,0 4,1.791 4,4 v 4 c 0,2.2 -1.8,4 -4,4 z" '
    'style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"/>'
    '</g>'
    '<g transform="translate(15,6)">'
    '<path d="m 0,0 c 2.209,0 4,1.791 4,4 v 4 c 0,2.2 -1.8,4 -4,4 h -6 c -2.209,0 -4,-1.791 -4,-4 V 7" '
    'style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"/>'
    '</g>'
    '<g transform="translate(19,11)">'
    '<path d="m 0,0 v 0 c 2.209,0 4,1.791 4,4 v 4 c 0,2.2 -1.8,4 -4,4 h -6 c -2.209,0 -4,-1.791 -4,-4 V 7" '
    'style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"/>'
    '</g>'
    '<g transform="translate(6,9)">'
    '<path d="m 0,0 c 0,-0.553 -0.447,-1 -1,-1 -0.553,0 -1,0.447 -1,1 0,0.553 0.447,1 1,1 0.553,0 1,-0.447 1,-1" '
    'style="fill:currentColor"/>'
    '</g>'
    '<g transform="translate(2.5381,2.3848)">'
    '<path d="M 0,0 5.114,4.384 C 5.512,4.715 6.097,4.688 6.462,4.322 L 6.933,3.846 '
    'c 0.39,-0.391 1.023,-0.391 1.414,0 l 3.807,3.807" '
    'style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"/>'
    '</g>'
    '</g></g></g></svg>';

// Motor de pesquisa
const _iEngine =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m21.17,19.756c.524-.791.83-1.738.83-2.756,0-2.757-2.243-5-5-5s-5,2.243-5,5,2.243,5,5,5'
    'c1.018,0,1.965-.306,2.756-.83l2.537,2.537c.195.195.451.293.707.293s.512-.098.707-.293'
    'c.391-.391.391-1.023,0-1.414l-2.537-2.537Zm-7.17-2.756c0-1.654,1.346-3,3-3s3,1.346,3,3-1.346,3-3,3-3-1.346-3-3Z'
    'M6,4.5c0,.828-.672,1.5-1.5,1.5s-1.5-.672-1.5-1.5.672-1.5,1.5-1.5,1.5.672,1.5,1.5Z'
    'm4,0c0,.828-.672,1.5-1.5,1.5s-1.5-.672-1.5-1.5.672-1.5,1.5-1.5,1.5.672,1.5,1.5Z'
    'M19,0H5C2.243,0,0,2.243,0,5v12c0,2.757,2.243,5,5,5h5c.553,0,1-.447,1-1s-.447-1-1-1h-5'
    'c-1.654,0-3-1.346-3-3v-8h20v3c0,.552.447,1,1,1s1-.448,1-1v-7c0-2.757-2.243-5-5-5Z'
    'M2,7v-2c0-1.654,1.346-3,3-3h14c1.654,0,3,1.346,3,3v2H2Z"/>'
    '</svg>';

// Bloquear capturas de ecrã
const _iScreenshot =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="16" cy="8.011" r="2.5"/>'
    '<path d="M23,16a1,1,0,0,0-1,1v2a3,3,0,0,1-3,3H17a1,1,0,0,0,0,2h2a5.006,5.006,0,0,0,5-5V17A1,1,0,0,0,23,16Z"/>'
    '<path d="M1,8A1,1,0,0,0,2,7V5A3,3,0,0,1,5,2H7A1,1,0,0,0,7,0H5A5.006,5.006,0,0,0,0,5V7A1,1,0,0,0,1,8Z"/>'
    '<path d="M7,22H5a3,3,0,0,1-3-3V17a1,1,0,0,0-2,0v2a5.006,5.006,0,0,0,5,5H7a1,1,0,0,0,0-2Z"/>'
    '<path d="M19,0H17a1,1,0,0,0,0,2h2a3,3,0,0,1,3,3V7a1,1,0,0,0,2,0V5A5.006,5.006,0,0,0,19,0Z"/>'
    '<path d="M18.707,17.293,11.121,9.707a3,3,0,0,0-4.242,0L4.586,12A2,2,0,0,0,4,13.414V16'
    'a3,3,0,0,0,3,3H18a1,1,0,0,0,.707-1.707Z"/>'
    '</svg>';

// Alterar PIN
const _iPin =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M11,15c0,.553-.448,1-1,1H5c-2.757,0-5-2.243-5-5v-3C0,5.243,2.243,3,5,3h14'
    'c2.757,0,5,2.243,5,5,0,.553-.447,1-1,1s-1-.447-1-1c0-1.654-1.346-3-3-3H5c-1.654,0-3,1.346-3,3v3'
    'c0,1.654,1.346,3,3,3h5c.552,0,1,.447,1,1Zm-2.293-7.707c-.391-.391-1.023-.391-1.414,0l-.793,.793'
    '-.793-.793c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414l.793,.793-.793,.793'
    'c-.391,.391-.391,1.023,0,1.414,.195,.195,.451,.293,.707,.293s.512-.098,.707-.293l.793-.793'
    '.793,.793c.195,.195,.451,.293,.707,.293s.512-.098,.707-.293c.391-.391,.391-1.023,0-1.414'
    'l-.793-.793,.793-.793c.391-.391,.391-1.023,0-1.414Zm6,1.414c.391-.391,.391-1.023,0-1.414'
    's-1.023-.391-1.414,0l-.793,.793-.793-.793c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414'
    'l.793,.793-.793,.793c-.391,.391-.391,1.023,0,1.414,.195,.195,.451,.293,.707,.293s.512-.098'
    ',.707-.293l3-3Zm9.293,9.293v2c0,2.206-1.794,4-4,4h-4c-2.206,0-4-1.794-4-4v-2'
    'c0-1.474,.81-2.75,2-3.444v-1.556c0-2.206,1.794-4,4-4s4,1.794,4,4v1.556'
    'c1.19,.694,2,1.97,2,3.444Zm-8-4h4v-1c0-1.103-.897-2-2-2s-2,.897-2,2v1Z'
    'm6,4c0-1.103-.897-2-2-2h-4c-1.103,0-2,.897-2,2v2c0,1.103,.897,2,2,2h4'
    'c1.103,0,2-.897,2-2v-2Zm-4-.5c-.828,0-1.5,.672-1.5,1.5s.672,1.5,1.5,1.5'
    ',1.5-.672,1.5-1.5-.672-1.5-1.5-1.5Z"/>'
    '</svg>';

// Volume máximo
const _iVolume =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.807,4.29a1,1,0,0,0-1.415,1.415,8.913,8.913,0,0,1,0,12.59'
    'a1,1,0,0,0,1.415,1.415A10.916,10.916,0,0,0,20.807,4.29Z"/>'
    '<path d="M18.1,7.291A1,1,0,0,0,16.68,8.706a4.662,4.662,0,0,1,0,6.588'
    'A1,1,0,0,0,18.1,16.709,6.666,6.666,0,0,0,18.1,7.291Z"/>'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2ZM13,21.535a10.083,10.083,0,0,1-5.371-4.08'
    'A1,1,0,0,0,6.792,17H5a3,3,0,0,1-3-3V10A3,3,0,0,1,5,7h1.8'
    'a1,1,0,0,0,.837-.453A10.079,10.079,0,0,1,13,2.465Z"/>'
    '</svg>';

// Privacidade nos recentes
const _iLock =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M19,8.424V7A7,7,0,0,0,5,7V8.424A5,5,0,0,0,2,13v6a5.006,5.006,0,0,0,5,5H17'
    'a5.006,5.006,0,0,0,5-5V13A5,5,0,0,0,19,8.424ZM7,7A5,5,0,0,1,17,7V8H7Z'
    'M20,19a3,3,0,0,1-3,3H7a3,3,0,0,1-3-3V13a3,3,0,0,1,3-3H17a3,3,0,0,1,3,3Z"/>'
    '<path d="M12,14a1,1,0,0,0-1,1v2a1,1,0,0,0,2,0V15A1,1,0,0,0,12,14Z"/>'
    '</svg>';

const _iTrash =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21,4H17.9A5.009,5.009,0,0,0,13,0H11A5.009,5.009,0,0,0,6.1,4H3A1,1,0,0,0,3,6H4V19'
    'a5.006,5.006,0,0,0,5,5h6a5.006,5.006,0,0,0,5-5V6h1a1,1,0,0,0,0-2Z'
    'M11,2h2a3.006,3.006,0,0,1,2.829,2H8.171A3.006,3.006,0,0,1,11,2Z'
    'm7,17a3,3,0,0,1-3,3H9a3,3,0,0,1-3-3V6H18Z"/>'
    '<path d="M10,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,10,18Z"/>'
    '<path d="M14,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,14,18Z"/>'
    '</svg>';

const _iReload =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M12,0c-2.991,0-5.813,1.113-8,3.078V1c0-.553-.448-1-1-1s-1,.447-1,1V5'
    'c0,1.103,.897,2,2,2h4c.552,0,1-.447,1-1s-.448-1-1-1h-3.13C6.746,3.087,9.292,2,12,2'
    'c5.514,0,10,4.486,10,10s-4.486,10-10,10c-5.21,0-9.492-3.908-9.959-9.09'
    '-.049-.55-.526-.956-1.086-.906C.405,12.054,0,12.54,.049,13.09'
    'c.561,6.22,5.699,10.91,11.951,10.91,6.617,0,12-5.383,12-12S18.617,0,12,0Z"/>'
    '</svg>';

const _secureChannel = MethodChannel('com.patrulhaxx/secure');

// ─── Ícone de voltar (AppBar) ─────────────────────────────────────────────────
const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/>'
    '</svg>';

// ─── Chevron direita (trailing nas rows) ──────────────────────────────────────
const _iChevron =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M9,18l6-6-6-6" fill="none" stroke="currentColor" stroke-width="2" '
    'stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

// ─────────────────────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lock = false;
  final _ts = ThemeService.instance;

  // Tema sempre escuro
  Color get _bg   => const Color(0xFF111111);
  Color get _card => const Color(0xFF1C1C1E);
  Color get _text => Colors.white;
  Color get _sub  => Colors.white54;
  Color get _div  => Colors.white12;

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
            style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
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
            style: const TextStyle(color: Colors.white, fontSize: 16)))),
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
            style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
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
            TextButton(
              onPressed: () { Navigator.pop(context); onOk(); },
              child: const Text('OK', style: TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w700))),
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
                    color: sel ? _kPrimary : Colors.transparent,
                    width: 2,
                  ),
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
            // Seta de voltar
            icon: SvgPicture.string(
              _iBack,
              width: 22, height: 22,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
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
              _SwitchRow(
                svg: _iDark,
                label: 'Tema escuro',
                sub: _ts.isDark ? 'Ativo' : 'Desativado',
                value: _ts.isDark,
                textColor: _text, subColor: _sub,
                onChanged: (v) { _ts.setDark(v); setState(() {}); },
              ),
              _divider(),
              _TapRow(
                svg: _iWallpaper,
                label: 'Fundo de ecrã',
                sub: _ts.bg.isEmpty ? 'Padrão' : _ts.bg.split('/').last,
                textColor: _text, subColor: _sub,
                onTap: _pickWallpaper,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Segurança ─────────────────────────────────────────────
            _label('Segurança'),
            _section([
              _SwitchRow(
                svg: _iLock,
                label: 'Bloquear app',
                sub: _lock ? 'PIN obrigatório' : 'Sem bloqueio',
                value: _lock, textColor: _text, subColor: _sub,
                onChanged: (v) {
                  _pinSheet(mode: LockMode.unlock, onDone: () async {
                    await LockService.instance.setEnabled(v);
                    if (mounted) setState(() => _lock = v);
                  });
                },
              ),
              if (_lock) ...[
                _divider(),
                _TapRow(
                  svg: _iPin,
                  label: 'Alterar PIN',
                  sub: 'Muda o código de acesso',
                  textColor: _text, subColor: _sub,
                  onTap: () => _pinSheet(mode: LockMode.setNew,
                      onDone: () => _snack('PIN alterado')),
                ),
                _divider(),
                _TapRow(
                  svg: _iLock,
                  label: 'Bloquear após',
                  sub: _ts.lockDelayLabel,
                  textColor: _text, subColor: _sub,
                  onTap: _pickLockDelay,
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // ── Privacidade ───────────────────────────────────────────
            _label('Privacidade'),
            _section([
              _SwitchRow(
                svg: _iLock,
                label: 'Privacidade nos recentes',
                sub: _ts.privacyRecent
                    ? 'App aparece em preto' : 'Conteúdo visível',
                value: _ts.privacyRecent, textColor: _text, subColor: _sub,
                onChanged: (v) {
                  _ts.setPrivacyRecent(v); _applySecure(v); setState(() {});
                },
              ),
              _divider(),
              _SwitchRow(
                svg: _iScreenshot,
                label: 'Bloquear capturas',
                sub: _ts.noScreenshot
                    ? 'Screenshots bloqueados' : 'Screenshots permitidos',
                value: _ts.noScreenshot, textColor: _text, subColor: _sub,
                onChanged: (v) {
                  _ts.setNoScreenshot(v); _applySecure(v); setState(() {});
                },
              ),
            ]),
            const SizedBox(height: 16),

            // ── Navegação ─────────────────────────────────────────────
            _label('Navegação'),
            _section([
              _TapRow(
                svg: _iEngine,
                label: 'Motor de pesquisa',
                sub: ThemeService.engines[_ts.engine] ?? 'Google',
                textColor: _text, subColor: _sub,
                onTap: _pickEngine,
              ),
              _divider(),
              _TapRow(
                svg: _iVolume,
                label: 'Volume máximo',
                sub: '${_ts.maxVolume}%',
                textColor: _text, subColor: _sub,
                onTap: _pickVolume,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Manutenção ────────────────────────────────────────────
            _label('Manutenção'),
            _section([
              _TapRow(
                svg: _iReload,
                label: 'Recarregar ícones',
                sub: 'Baixa novamente os favicons',
                textColor: _text, subColor: _sub,
                onTap: () async {
                  await FaviconService.instance.clearAll();
                  await FaviconService.instance.preloadAll();
                  if (context.mounted) _snack('Ícones recarregados');
                },
              ),
              _divider(),
              _TapRow(
                svg: _iTrash,
                label: 'Limpar downloads',
                sub: 'Apaga todos os ficheiros',
                textColor: _text, subColor: _sub,
                destructive: true,
                onTap: _confirmClear,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Sobre ─────────────────────────────────────────────────
            _label('Sobre'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _card,
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
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

// ─────────────────────────────────────────────────────────────────────────────
// _TapRow
// ─────────────────────────────────────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  final String svg, label, sub;
  final VoidCallback onTap;
  final Color textColor, subColor;
  final bool destructive;

  const _TapRow({
    required this.svg, required this.label, required this.sub,
    required this.onTap, required this.textColor, required this.subColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = destructive ? Colors.redAccent : textColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          // Chevron SVG elegante
          SvgPicture.string(_iChevron, width: 16, height: 16,
              colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.25), BlendMode.srcIn)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SwitchRow — com switch custom minimalista
// ─────────────────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final String svg, label, sub;
  final bool value;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.svg, required this.label, required this.sub,
    required this.value, required this.textColor, required this.subColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
        _MiniSwitch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniSwitch — switch custom compacto, sem usar o Switch do Flutter
// ─────────────────────────────────────────────────────────────────────────────
class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MiniSwitch({required this.value, required this.onChanged});

  // dimensões
  static const double _w = 40;
  static const double _h = 23;
  static const double _thumb = 17;
  static const double _pad = 3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: _w,
        height: _h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_h / 2),
          color: value ? _kPrimary : Colors.white.withOpacity(0.14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumb,
            height: _thumb,
            margin: const EdgeInsets.all(_pad),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
