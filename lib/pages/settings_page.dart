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

// ─── SVG Icons ────────────────────────────────────────────────────────────────

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

const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/>'
    '</svg>';

const _iChevron =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M9,18l6-6-6-6" fill="none" stroke="currentColor" stroke-width="2" '
    'stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

const _secureChannel = MethodChannel('com.patrulhaxx/secure');

// ─────────────────────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lock = false;
  bool _screenshot = false;
  bool _maxVolume = false;
  
  final _ts = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await LockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _lock = lockEnabled;
        // Carrega outras configurações aqui
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.appBar,
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text(
                'Definições',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: theme.divider),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // Aparência
                  _Section(title: 'Aparência', theme: theme),
                  _SwitchRow(
                    svg: _iDark,
                    label: 'Modo escuro',
                    sub: 'Interface com cores escuras',
                    value: _ts.isDark,
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onChanged: (v) => _ts.setDark(v),
                  ),
                  _TapRow(
                    svg: _iWallpaper,
                    label: 'Papel de parede',
                    sub: 'Personalizar fundo da app',
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  // Privacidade
                  _Section(title: 'Privacidade', theme: theme),
                  _TapRow(
                    svg: _iPin,
                    label: 'Alterar PIN',
                    sub: 'Definir novo código de acesso',
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onTap: () => _showPinSetup(),
                  ),
                  _SwitchRow(
                    svg: _iLock,
                    label: 'Bloquear app',
                    sub: 'Exigir PIN ao abrir',
                    value: _lock,
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onChanged: (v) async {
                      if (v) {
                        final pin = await LockService.instance.getPin();
                        if (pin == null && mounted) {
                          _showPinSetup();
                        } else {
                          await LockService.instance.setEnabled(true);
                          setState(() => _lock = true);
                        }
                      } else {
                        await LockService.instance.setEnabled(false);
                        setState(() => _lock = false);
                      }
                    },
                  ),
                  _SwitchRow(
                    svg: _iScreenshot,
                    label: 'Bloquear capturas',
                    sub: 'Prevenir screenshots',
                    value: _screenshot,
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onChanged: (v) {
                      setState(() => _screenshot = v);
                      _toggleScreenshot(v);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Reprodução
                  _Section(title: 'Reprodução', theme: theme),
                  _SwitchRow(
                    svg: _iVolume,
                    label: 'Volume máximo',
                    sub: 'Sempre no máximo ao reproduzir',
                    value: _maxVolume,
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onChanged: (v) => setState(() => _maxVolume = v),
                  ),

                  const SizedBox(height: 20),

                  // Avançado
                  _Section(title: 'Avançado', theme: theme),
                  _TapRow(
                    svg: _iEngine,
                    label: 'Motor de pesquisa',
                    sub: 'Google (padrão)',
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onTap: () {},
                  ),
                  _TapRow(
                    svg: _iTrash,
                    label: 'Limpar cache',
                    sub: 'Libertar espaço de armazenamento',
                    textColor: theme.text,
                    subColor: theme.textSub,
                    onTap: () => _confirmClear(theme),
                  ),
                  _TapRow(
                    svg: _iReload,
                    label: 'Reiniciar app',
                    sub: 'Fechar e reabrir completamente',
                    textColor: theme.text,
                    subColor: theme.textSub,
                    destructive: true,
                    onTap: () => SystemNavigator.pop(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showPinSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const LockSetupScreen(),
    )).then((success) {
      if (success == true && mounted) {
        setState(() => _lock = true);
      }
    });
  }

  Future<void> _toggleScreenshot(bool block) async {
    try {
      await _secureChannel.invokeMethod('setSecure', {'enable': block}); // FIXED
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar configuração: $e'),
            backgroundColor: AppTheme.current.cardAlt,
          ),
        );
      }
    }
  }

  void _confirmClear(AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Limpar downloads?',
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.text,
                  side: BorderSide(color: theme.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  for (final item in DownloadService.instance.items.toList()) {
                    await DownloadService.instance.delete(item.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Downloads limpos'),
                        backgroundColor: theme.cardAlt,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apagar tudo'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Section
// ─────────────────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final AppTheme theme;
  const _Section({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              color: theme.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
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
    required this.svg,
    required this.label,
    required this.sub,
    required this.onTap,
    required this.textColor,
    required this.subColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = destructive ? AppTheme.error : textColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          SvgPicture.string(
            svg,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              destructive ? AppTheme.error : subColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(color: subColor, fontSize: 12),
                ),
              ],
            ),
          ),
          SvgPicture.string(
            _iChevron,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              subColor.withOpacity(0.5),
              BlendMode.srcIn,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SwitchRow
// ─────────────────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final String svg, label, sub;
  final bool value;
  final Color textColor, subColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.svg,
    required this.label,
    required this.sub,
    required this.value,
    required this.textColor,
    required this.subColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        SvgPicture.string(
          svg,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
            ],
          ),
        ),
        _MiniSwitch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniSwitch - CORRIGIDO PARA FUNCIONAR
// ─────────────────────────────────────────────────────────────────────────────
class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MiniSwitch({required this.value, required this.onChanged});

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
          color: value ? AppTheme.accent : AppTheme.current.cardAlt,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumb,
            height: _thumb,
            margin: const EdgeInsets.all(_pad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: const [
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
