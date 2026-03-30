// =============================================================================
// settings_page.dart
// patrulhaXX — Definições
//
// Copyright (c) 2024 patrulhaXX. Todos os direitos reservados.
// Este ficheiro é propriedade exclusiva do projecto patrulhaXX.
// Proibida a reprodução, distribuição ou modificação sem autorização escrita.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';
import 'licenses_page.dart';

// =============================================================================
// SVG Assets — todos em assets/icons/svg/settings/
// =============================================================================
// Colocar os ficheiros da pasta svg/ em:  assets/icons/svg/settings/
// E registar no pubspec.yaml:
//   flutter:
//     assets:
//       - assets/icons/svg/settings/

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
    // Inicializa o ThemeMode local a partir do bool isDark do ThemeService
    _cachedThemeMode = _ts.isDark ? ThemeMode.dark : ThemeMode.light;
    LockService.instance.isEnabled()
        .then((v) { if (mounted) setState(() => _lock = v); });
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

  // ── Modal de tema ────────────────────────────────────────────────────────────
  void _pickTheme() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        // Curva elástica: sobe rápido e abranda suavemente
        final curved = CurvedAnimation(
          parent: anim,
          curve: _kElasticOut,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curved),
            child: _ThemeModal(
              ts: _ts,
              initialMode: _cachedThemeMode,
              onChanged: (mode) {
                // Aplica o novo ThemeMode ao ThemeService via isDark/setDark
                switch (mode) {
                  case ThemeMode.dark:
                    _ts.setDark(true);
                  case ThemeMode.light:
                    _ts.setDark(false);
                  case ThemeMode.system:
                    // system: usa o brilho do sistema para decidir
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

  // ── Pin sheet ────────────────────────────────────────────────────────────────
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

  // ── Converte o bool isDark do ThemeService para ThemeMode do Flutter ────────
  // Nota: o ThemeService não expõe ThemeMode — guardamos o valor localmente
  // na _ThemeModal e reflectimos aqui através de _resolvedThemeMode.
  ThemeMode get _resolvedThemeMode => _cachedThemeMode;
  ThemeMode _cachedThemeMode = ThemeMode.dark; // default; actualizado em initState

  // ── Descrição do tema actual ──────────────────────────────────────────────
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

            // ── Aparência ────────────────────────────────────────────────
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
            ]),
            const SizedBox(height: 16),

            // ── Segurança ────────────────────────────────────────────────
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
                  label: 'Bloquear após',
                  sub: _ts.lockDelayLabel,
                  textColor: _text, subColor: _sub,
                  onTap: _pickLockDelay,
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // ── Privacidade ──────────────────────────────────────────────
            _label('Privacidade'),
            _section([
              _SwitchRow(
                svgAsset: _svgLock,
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

            // ── Navegação ────────────────────────────────────────────────
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

            // ── Manutenção ───────────────────────────────────────────────
            _label('Manutenção'),
            _section([
              _TapRow(
                svgAsset: _svgReload,
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

            // ── Sobre ────────────────────────────────────────────────────
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
            _section([
              _TapRow(
                svgAsset: _svgReload,
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
// _kElasticOut / _kElasticIn — curvas nativas do Flutter
// ElasticOutCurve: sobe rápido com pequeno ressalto no fim (period=0.55)
// =============================================================================
const _kElasticOut = ElasticOutCurve(0.55);
const _kElasticIn  = ElasticInCurve(0.55);

// =============================================================================
// _showElasticSheet — showModalBottomSheet com animação elástica (subida rápida
// que abranda suavemente, saída rápida)
// =============================================================================
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
    transitionDuration: const Duration(milliseconds: 440),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final elasticIn = CurvedAnimation(
        parent: anim,
        curve: _kElasticOut,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeAnim = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fadeAnim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(elasticIn),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor ??
                        AppTheme.current.card,
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
// _ThemeModal — modal com 3 opções de tema
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
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) Navigator.of(context).pop();
    });
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
              // Handle
              const SizedBox(height: 10),
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: t.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 14),

              // Título
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

              // Opções
              _ThemeOption(
                svgAsset: _svgAutoTheme,
                label: 'Automático',
                sub: 'Segue as definições do sistema',
                selected: _selected == ThemeMode.system,
                textColor: t.text,
                subColor: t.textSecondary,
                accentColor: AppTheme.ytRed,
                iconColor: t.iconSub,
                onTap: () => _pick(ThemeMode.system),
              ),
              Divider(height: 1, color: t.divider, indent: 52, endIndent: 16),
              _ThemeOption(
                svgAsset: _svgSun,
                label: 'Tema claro',
                sub: 'Interface sempre clara',
                selected: _selected == ThemeMode.light,
                textColor: t.text,
                subColor: t.textSecondary,
                accentColor: AppTheme.ytRed,
                iconColor: t.iconSub,
                onTap: () => _pick(ThemeMode.light),
              ),
              Divider(height: 1, color: t.divider, indent: 52, endIndent: 16),
              _ThemeOption(
                svgAsset: _svgDark,
                label: 'Tema escuro',
                sub: 'Interface sempre escura',
                selected: _selected == ThemeMode.dark,
                textColor: t.text,
                subColor: t.textSecondary,
                accentColor: AppTheme.ytRed,
                iconColor: t.iconSub,
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
// _ThemeOption — linha de opção dentro do modal de tema
// =============================================================================
class _ThemeOption extends StatelessWidget {
  final String svgAsset, label, sub;
  final bool selected;
  final Color textColor, subColor, accentColor, iconColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.svgAsset,
    required this.label,
    required this.sub,
    required this.selected,
    required this.textColor,
    required this.subColor,
    required this.accentColor,
    required this.iconColor,
    required this.onTap,
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
          // Texto mais à esquerda — sem Expanded para não empurrar
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              color: selected ? accentColor : textColor,
              fontSize: 14, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
          ]),
          const Spacer(),
          // Indicador animado de selecção
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
// _TapRow
// =============================================================================
class _TapRow extends StatelessWidget {
  final String svgAsset, label, sub;
  final VoidCallback onTap;
  final Color textColor, subColor;
  final bool destructive;

  const _TapRow({
    required this.svgAsset, required this.label, required this.sub,
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
          SvgPicture.asset(svgAsset, width: 20, height: 20,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
          const SizedBox(width: 14),
          // Texto mais à esquerda
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: fgColor, fontSize: 14,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
          ]),
          const Spacer(),
          SvgPicture.asset(_svgChevron, width: 16, height: 16,
              colorFilter: ColorFilter.mode(
                  subColor.withOpacity(0.5), BlendMode.srcIn)),
        ]),
      ),
    );
  }
}

// =============================================================================
// _SwitchRow
// =============================================================================
class _SwitchRow extends StatelessWidget {
  final String svgAsset, label, sub;
  final bool value;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.svgAsset, required this.label, required this.sub,
    required this.value, required this.textColor, required this.subColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        SvgPicture.asset(svgAsset, width: 20, height: 20,
            colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
        const SizedBox(width: 14),
        // Texto mais à esquerda
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
// _MiniSwitch — switch com animação elástica no thumb
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

    // Posição do thumb com efeito elástico
    _position = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    // Scale do thumb: aperta ligeiramente ao transitar
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);

    // Cor de fundo
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
