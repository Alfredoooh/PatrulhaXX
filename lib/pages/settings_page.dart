import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';
import '../services/app_icon_service.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';
import 'licenses_page.dart';

const _svgDark       = 'assets/icons/svg/settings/settings_dark.svg';
const _svgSun        = 'assets/icons/svg/settings/settings_sun.svg';
const _svgAutoTheme  = 'assets/icons/svg/settings/settings_auto_theme.svg';
const _svgWallpaper  = 'assets/icons/svg/settings/settings_wallpaper.svg';
const _svgEngine     = 'assets/icons/svg/settings/settings_engine.svg';
const _svgScreenshot = 'assets/icons/svg/settings/settings_screenshot.svg';
const _svgPin        = 'assets/icons/svg/settings/settings_pin.svg';
const _svgVolume     = 'assets/icons/svg/settings/settings_volume.svg';
const _svgLock       = 'assets/icons/svg/settings/settings_lock.svg';
const _svgTrash      = 'assets/icons/svg/settings/settings_trash.svg';
const _svgReload     = 'assets/icons/svg/settings/settings_reload.svg';
const _svgBack       = 'assets/icons/svg/settings/settings_back.svg';
const _svgChevron    = 'assets/icons/svg/settings/settings_chevron.svg';

const _lucideShield = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/></svg>''';
const _lucideEye = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>''';
const _lucideRefreshCw = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></svg>''';
const _lucideScrollText = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 12h-5"/><path d="M15 8h-5"/><path d="M19 17V5a2 2 0 0 0-2-2H4"/><path d="M8 21h12a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1H11a1 1 0 0 0-1 1v1a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v2a1 1 0 0 0 1 1h3"/></svg>''';
const _lucideTimer = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="10" x2="14" y1="2" y2="2"/><line x1="12" x2="15" y1="14" y2="11"/><circle cx="12" cy="14" r="8"/></svg>''';

// SVG inline para o ícone de "app icon" nas settings
const _lucideAppIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="12" height="12" x="2" y="2" rx="2"/><path d="M14 2c1.1 0 2 .9 2 2v4c0 1.1-.9 2-2 2"/><path d="M20 2c1.1 0 2 .9 2 2v4c0 1.1-.9 2-2 2"/><path d="M10 18H5c-1.7 0-3-1.3-3-3v-1"/><polyline points="7 21 10 18 7 15"/><rect width="12" height="12" x="10" y="10" rx="2"/></svg>''';

const _secureChannel = MethodChannel('com.patrulhaxx/secure');

// =============================================================================
// SettingsPage
// =============================================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lock = false;
  AppIconVariant _activeIcon = AppIconVariant.classic;
  final _ts = ThemeService.instance;

  AppTheme get _t   => AppTheme.current;
  Color get _bg     => _t.bg;
  Color get _card   => _t.card;
  Color get _text   => _t.text;
  Color get _sub    => _t.textSecondary;
  Color get _div    => _t.divider;

  @override
  void initState() {
    super.initState();
    _cachedThemeMode = _ts.isDark ? ThemeMode.dark : ThemeMode.light;
    LockService.instance.isEnabled()
        .then((v) { if (mounted) setState(() => _lock = v); });
    AppIconService.getActiveIcon()
        .then((v) { if (mounted) setState(() => _activeIcon = v); });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: _t.toastText)),
      backgroundColor: _t.toastBg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _applySecure(bool v) {
    try { _secureChannel.invokeMethod('setSecure', {'enable': v}); } catch (_) {}
  }

  // ── Modal de tema ─────────────────────────────────────────────────────────
  void _pickTheme() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final slide = CurvedAnimation(
          parent: anim,
          curve: _kIOSEnter,
          reverseCurve: _kIOSExit,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(slide),
            child: _ThemeModal(
              ts: _ts,
              initialMode: _cachedThemeMode,
              onChanged: (mode) {
                switch (mode) {
                  case ThemeMode.dark:
                    _ts.setDark(true);
                  case ThemeMode.light:
                    _ts.setDark(false);
                  case ThemeMode.system:
                    final brightness =
                        WidgetsBinding.instance.platformDispatcher.platformBrightness;
                    _ts.setDark(brightness == Brightness.dark);
                }
                setState(() => _cachedThemeMode = mode);
              },
            ),
          ),
        );
      },
    );
  }

  // ── Modal de ícone — showCupertinoModalPopup empurra a tela atrás ─────────
  void _pickIcon() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _IconPickerSheet(
        current: _activeIcon,
        onChanged: (variant) async {
          try {
            await AppIconService.setIcon(variant);
            if (mounted) setState(() => _activeIcon = variant);
          } catch (e) {
            if (mounted) _snack('Erro ao trocar ícone');
          }
        },
      ),
    );
  }

  // ── Pin sheet ─────────────────────────────────────────────────────────────
  void _pinSheet({required LockMode mode, required VoidCallback onDone}) {
    _showElasticSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
            color: _t.sheet,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: mode == LockMode.unlock
              ? LockScreen(
                  mode: LockMode.unlock,
                  onUnlocked: () { Navigator.pop(context); onDone(); })
              : LockScreen(
                  mode: LockMode.setNew,
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
    _showElasticSheet(
      context: context,
      backgroundColor: _card,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: _t.sheetHandle,
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
              child: Text('OK', style: TextStyle(
                  color: AppTheme.ytRed, fontWeight: FontWeight.w700))),
          ]),
        ),
        SizedBox(height: 180, child: child),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _pickWallpaper() {
    _showElasticSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _t.sheetHandle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text('Fundo de ecrã', style: TextStyle(color: _text,
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              SvgPicture.asset(_svgWallpaper, width: 20, height: 20,
                  colorFilter: ColorFilter.mode(_sub, BlendMode.srcIn)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usar imagem como fundo',
                      style: TextStyle(color: _text, fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _ts.useWallpaper
                        ? 'Imagem ativa'
                        : (_ts.isDark ? 'Fundo escuro sólido' : 'Fundo claro sólido'),
                    style: TextStyle(color: _sub, fontSize: 12)),
                ],
              )),
              _MiniSwitch(
                value: _ts.useWallpaper,
                onChanged: (v) async {
                  await _ts.setUseWallpaper(v);
                  setLocal(() {});
                  setState(() {});
                },
              ),
            ]),
          ),

          if (_ts.useWallpaper) ...[
            const SizedBox(height: 12),
            SizedBox(height: 160, child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ThemeService.wallpapers.length,
              itemBuilder: (_, i) {
                final wp = ThemeService.wallpapers[i];
                final sel = wp == _ts.bg;
                return GestureDetector(
                  onTap: () {
                    _ts.setBg(wp);
                    setLocal(() {});
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 90, height: 160,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppTheme.ytRed : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(wp, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: _t.thumbBg)),
                    ),
                  ),
                );
              },
            )),
          ],
          const SizedBox(height: 20),
        ]),
      ),
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

  ThemeMode get _resolvedThemeMode => _cachedThemeMode;
  ThemeMode _cachedThemeMode = ThemeMode.dark;

  String get _themeLabel {
    switch (_resolvedThemeMode) {
      case ThemeMode.system: return 'Automático (sistema)';
      case ThemeMode.light:  return 'Tema claro';
      case ThemeMode.dark:   return 'Tema escuro';
    }
  }

  String get _themeSvg {
    switch (_resolvedThemeMode) {
      case ThemeMode.system: return _svgAutoTheme;
      case ThemeMode.light:  return _svgSun;
      case ThemeMode.dark:   return _svgDark;
    }
  }

  String get _iconLabel {
    switch (_activeIcon) {
      case AppIconVariant.classic:  return 'Classic';
      case AppIconVariant.light:    return 'Light';
      case AppIconVariant.original: return 'Original';
    }
  }

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
            icon: SvgPicture.asset(
              _svgBack, width: 22, height: 22,
              colorFilter: ColorFilter.mode(_text, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Definições',
              style: TextStyle(color: _text, fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [

            // ── Aparência ──────────────────────────────────────────────
            _label('Aparência'),
            _section([
              _TapRow(
                svgAsset: _themeSvg,
                label: 'Tema',
                sub: _themeLabel,
                textColor: _text, subColor: _sub,
                onTap: _pickTheme,
              ),
              _divider(),
              _TapRow(
                svgAsset: _svgWallpaper,
                label: 'Fundo de ecrã',
                sub: _ts.useWallpaper
                    ? _ts.bg.split('/').last
                    : (_ts.isDark ? 'Fundo escuro' : 'Fundo claro'),
                textColor: _text, subColor: _sub,
                onTap: _pickWallpaper,
              ),
              _divider(),
              // ── Ícone do app ─────────────────────────────────────────
              _TapRow(
                svgAsset: _svgDark,
                lucideSvg: _lucideAppIcon,
                label: 'Ícone do app',
                sub: _iconLabel,
                textColor: _text, subColor: _sub,
                onTap: _pickIcon,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Segurança ──────────────────────────────────────────────
            _label('Segurança'),
            _section([
              _SwitchRow(
                svgAsset: _svgLock,
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
                  svgAsset: _svgPin,
                  label: 'Alterar PIN',
                  sub: 'Muda o código de acesso',
                  textColor: _text, subColor: _sub,
                  onTap: () => _pinSheet(mode: LockMode.setNew,
                      onDone: () => _snack('PIN alterado')),
                ),
                _divider(),
                _TapRow(
                  svgAsset: _svgLock,
                  lucideSvg: _lucideTimer,
                  label: 'Bloquear após',
                  sub: _ts.lockDelayLabel,
                  textColor: _text, subColor: _sub,
                  onTap: _pickLockDelay,
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // ── Privacidade ────────────────────────────────────────────
            _label('Privacidade'),
            _section([
              _SwitchRow(
                svgAsset: _svgLock,
                lucideSvg: _lucideEye,
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
                svgAsset: _svgScreenshot,
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

            // ── Navegação ──────────────────────────────────────────────
            _label('Navegação'),
            _section([
              _TapRow(
                svgAsset: _svgEngine,
                label: 'Motor de pesquisa',
                sub: ThemeService.engines[_ts.engine] ?? 'Google',
                textColor: _text, subColor: _sub,
                onTap: _pickEngine,
              ),
              _divider(),
              _TapRow(
                svgAsset: _svgVolume,
                label: 'Volume máximo',
                sub: '${_ts.maxVolume}%',
                textColor: _text, subColor: _sub,
                onTap: _pickVolume,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Manutenção ─────────────────────────────────────────────
            _label('Manutenção'),
            _section([
              _TapRow(
                svgAsset: _svgReload,
                lucideSvg: _lucideRefreshCw,
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
                svgAsset: _svgTrash,
                label: 'Limpar downloads',
                sub: 'Apaga todos os ficheiros',
                textColor: _text, subColor: _sub,
                destructive: true,
                onTap: _confirmClear,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Sobre ──────────────────────────────────────────────────
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
                                color: AppTheme.ytRedDark,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 24))),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('nuxxx', style: TextStyle(color: _text,
                        fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Versão 1.0.0 · Navegação privada',
                        style: TextStyle(color: _sub, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            _section([
              _TapRow(
                svgAsset: _svgReload,
                lucideSvg: _lucideScrollText,
                label: 'Licenças de software',
                sub: 'Dependências open source',
                textColor: _text, subColor: _sub,
                onTap: () => openOssLicenses(),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmClear() {
    _showElasticSheet(
      context: context,
      backgroundColor: _card,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: _t.sheetHandle,
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
                  backgroundColor: AppTheme.error,
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

// =============================================================================
// _IconPickerSheet — CupertinoModalPopup: empurra a tela atrás ao subir
// =============================================================================
class _IconPickerSheet extends StatefulWidget {
  final AppIconVariant current;
  final ValueChanged<AppIconVariant> onChanged;
  const _IconPickerSheet({required this.current, required this.onChanged});

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  late AppIconVariant _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  // Dados de cada opção de ícone
  static const _icons = [
    (
      variant: AppIconVariant.classic,
      label: 'Classic',
      sub: 'Fundo vermelho • predefinido',
      // Imagem do ícone Classic (fundo vermelho + texto branco)
      asset: 'assets/icons/ic_classic.png',
    ),
    (
      variant: AppIconVariant.light,
      label: 'Light',
      sub: 'Fundo branco',
      asset: 'assets/icons/ic_light.png',
    ),
    (
      variant: AppIconVariant.original,
      label: 'Original',
      sub: 'Ícone original',
      asset: 'assets/icons/ic_original.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final bottom = MediaQuery.of(context).padding.bottom;

    return CupertinoPopupSurface(
      isSurfacePainted: false,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: t.sheetHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Ícone do app',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Fechar',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Aviso "o app vai fechar e reabrir"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'O app irá fechar e reabrir ao alterar o ícone. É o comportamento normal do Android.',
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Grelha de ícones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _icons.map((data) {
                    final isSelected = _selected == data.variant;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selected = data.variant);
                        widget.onChanged(data.variant);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: 96,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.ytRed.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.ytRed
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Preview do ícone
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                data.asset,
                                width: 64, height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: t.cardAlt,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.apps_rounded,
                                    color: t.textSecondary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.label,
                              style: TextStyle(
                                color: isSelected ? AppTheme.ytRed : t.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.sub,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 24 + bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Curvas e helpers (mantidos exatamente como no original)
// =============================================================================
const _kIOSEnter = Interval(0.0, 1.0, curve: Curves.linearToEaseOut);
const _kIOSExit  = Interval(0.0, 1.0, curve: Curves.easeIn);

Future<T?> _showElasticSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final slide = CurvedAnimation(
        parent: anim,
        curve: _kIOSEnter,
        reverseCurve: _kIOSExit,
      );
      final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(slide),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor ?? AppTheme.current.card,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// =============================================================================
// _ThemeModal (sem alterações)
// =============================================================================
class _ThemeModal extends StatefulWidget {
  final ThemeService ts;
  final ThemeMode initialMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModal({required this.ts, required this.initialMode, required this.onChanged});

  @override
  State<_ThemeModal> createState() => _ThemeModalState();
}

class _ThemeModalState extends State<_ThemeModal> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMode;
  }

  void _pick(ThemeMode mode) {
    setState(() => _selected = mode);
    widget.onChanged(mode);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: t.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text('Tema', style: TextStyle(
                    color: t.text, fontSize: 17,
                    fontWeight: FontWeight.w700, letterSpacing: -0.3,
                  )),
                ]),
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                svgAsset: _svgAutoTheme,
                label: 'Automático',
                sub: 'Segue as definições do sistema',
                selected: _selected == ThemeMode.system,
                textColor: t.text, subColor: t.textSecondary,
                accentColor: AppTheme.ytRed, iconColor: t.iconSub,
                onTap: () => _pick(ThemeMode.system),
              ),
              Divider(height: 1, color: t.divider, indent: 52, endIndent: 16),
              _ThemeOption(
                svgAsset: _svgSun,
                label: 'Tema claro',
                sub: 'Interface sempre clara',
                selected: _selected == ThemeMode.light,
                textColor: t.text, subColor: t.textSecondary,
                accentColor: AppTheme.ytRed, iconColor: t.iconSub,
                onTap: () => _pick(ThemeMode.light),
              ),
              Divider(height: 1, color: t.divider, indent: 52, endIndent: 16),
              _ThemeOption(
                svgAsset: _svgDark,
                label: 'Tema escuro',
                sub: 'Interface sempre escura',
                selected: _selected == ThemeMode.dark,
                textColor: t.text, subColor: t.textSecondary,
                accentColor: AppTheme.ytRed, iconColor: t.iconSub,
                onTap: () => _pick(ThemeMode.dark),
              ),
              SizedBox(height: 12 + bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ThemeOption (sem alterações)
// =============================================================================
class _ThemeOption extends StatelessWidget {
  final String svgAsset, label, sub;
  final bool selected;
  final Color textColor, subColor, accentColor, iconColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.svgAsset, required this.label, required this.sub,
    required this.selected, required this.textColor, required this.subColor,
    required this.accentColor, required this.iconColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SvgPicture.asset(
            svgAsset, width: 20, height: 20,
            colorFilter: ColorFilter.mode(
              selected ? accentColor : iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              color: selected ? accentColor : textColor,
              fontSize: 14, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
          ]),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accentColor : const Color(0x00000000),
              border: Border.all(
                color: selected ? accentColor : subColor.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Color(0xFFFFFFFF), size: 13)
                : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// _SvgIcon (sem alterações)
// =============================================================================
class _SvgIcon extends StatelessWidget {
  final String? assetPath;
  final String? lucideSvg;
  final double size;
  final Color color;

  const _SvgIcon({
    this.assetPath, this.lucideSvg,
    this.size = 20, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cf = ColorFilter.mode(color, BlendMode.srcIn);
    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath!, width: size, height: size, colorFilter: cf,
        errorBuilder: (_, __, ___) => lucideSvg != null
            ? SvgPicture.string(lucideSvg!, width: size, height: size, colorFilter: cf)
            : SizedBox(width: size, height: size),
      );
    }
    if (lucideSvg != null) {
      return SvgPicture.string(lucideSvg!, width: size, height: size, colorFilter: cf);
    }
    return SizedBox(width: size, height: size);
  }
}

// =============================================================================
// _TapRow (sem alterações)
// =============================================================================
class _TapRow extends StatelessWidget {
  final String svgAsset;
  final String? lucideSvg;
  final String label, sub;
  final VoidCallback onTap;
  final Color textColor, subColor;
  final bool destructive;

  const _TapRow({
    required this.svgAsset, this.lucideSvg,
    required this.label, required this.sub,
    required this.onTap, required this.textColor, required this.subColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor   = destructive ? AppTheme.error : textColor;
    final iconColor = destructive ? AppTheme.error : subColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          _SvgIcon(assetPath: svgAsset, lucideSvg: lucideSvg, color: iconColor),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: fgColor, fontSize: 14,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
          ]),
          const Spacer(),
          _SvgIcon(assetPath: _svgChevron, lucideSvg: null,
              size: 16, color: subColor.withOpacity(0.5)),
        ]),
      ),
    );
  }
}

// =============================================================================
// _SwitchRow (sem alterações)
// =============================================================================
class _SwitchRow extends StatelessWidget {
  final String svgAsset;
  final String? lucideSvg;
  final String label, sub;
  final bool value;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.svgAsset, this.lucideSvg,
    required this.label, required this.sub,
    required this.value, required this.textColor, required this.subColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        _SvgIcon(assetPath: svgAsset, lucideSvg: lucideSvg, color: subColor),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
        ]),
        const Spacer(),
        _MiniSwitch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// =============================================================================
// _MiniSwitch (sem alterações)
// =============================================================================
class _MiniSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MiniSwitch({required this.value, required this.onChanged});
  @override
  State<_MiniSwitch> createState() => _MiniSwitchState();
}

class _MiniSwitchState extends State<_MiniSwitch>
    with SingleTickerProviderStateMixin {
  static const double _w     = 44;
  static const double _h     = 25;
  static const double _thumb = 19;
  static const double _pad   = 3;

  late final AnimationController _ctrl;
  late final Animation<double> _position;
  late final Animation<double> _scale;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    if (widget.value) _ctrl.value = 1.0;

    _position = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);

    _bgAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_MiniSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final bg = Color.lerp(t.cardAlt, AppTheme.ytRed, _bgAnim.value)!;
          final travel = _w - _thumb - _pad * 2;
          return Container(
            width: _w, height: _h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_h / 2),
              color: bg,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: _pad + _position.value * travel,
                  top: _pad,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: _thumb, height: _thumb,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFFFFF),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
