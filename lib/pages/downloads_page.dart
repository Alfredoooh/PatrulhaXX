import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/download_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../services/transfer_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _kPrimary = Color(0xFFFF9000);

// ── Cores reactivas ao tema ───────────────────────────────────────────────────
Color get _bg   => AppTheme.current.isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
Color get _card => AppTheme.current.card;
Color get _textPrimary => AppTheme.current.text;
Color get _textSub     => AppTheme.current.isDark ? Colors.white54 : Colors.black45;
Color get _divider     => AppTheme.current.isDark ? Colors.white12 : Colors.black12;


const _kBg      = Color(0xFF111111);
const _kCard2   = Color(0xFF1A1A1A);

// ─── ÍCONE DE VOLTAR (conforme enviado) ──────────────────────────────────────
const _svgBack =
    __SVG_0__;

const _svgSend =
    __SVG_1__;

const _svgQr =
    __SVG_2__;

const _svgTrash =
    __SVG_3__;

const _svgWifi =
    __SVG_4__;

const _svgHotspot =
    __SVG_5__;

const _svgScanner =
    __SVG_6__;

// ─────────────────────────────────────────────────────────────────────────────
// DownloadsPage
// ─────────────────────────────────────────────────────────────────────────────
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _svc = DownloadService.instance;
  bool _selectMode = false;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final items = _svc.items;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SvgPicture.string(_svgBack, width: 20, height: 20,
              colorFilter: _selectMode
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          onPressed: _selectMode
              ? () => setState(() { _selectMode = false; _selected.clear(); })
              : () => Navigator.pop(context),
        ),
        title: Text(
          _selectMode ? '${_selected.length} selecionados' : 'Downloads',
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: _selectMode
            ? [
                if (_selected.isNotEmpty) ...[
                  _ABtn(svg: _svgSend, color: Colors.white, onTap: _openSendSheet),
                  _ABtn(svg: _svgTrash, color: Colors.redAccent, onTap: _deleteSelected),
                  const SizedBox(width: 4),
                ],
              ]
            : [
                _ABtn(svg: _svgSend, color: Colors.white.withOpacity(0.6),
                    onTap: () => setState(() => _selectMode = true)),
                _ABtn(svg: _svgQr, color: Colors.white.withOpacity(0.6),
                    onTap: _openReceiveSheet),
                const SizedBox(width: 4),
              ],
      ),
      body: items.isEmpty ? _emptyState() : _grid(items),
    );
  }

  Widget _grid(List<DownloadedItem> items) => MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        itemCount: items.length,
        itemBuilder: (_, i) => _Tile(
          item: items[i],
          selected: _selected.contains(items[i].id),
          selectMode: _selectMode,
          onTap: () {
            if (_selectMode) {
              setState(() {
                _selected.contains(items[i].id)
                    ? _selected.remove(items[i].id)
                    : _selected.add(items[i].id);
                if (_selected.isEmpty) _selectMode = false;
              });
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _Viewer(item: items[i])));
            }
          },
          onLongPress: () => setState(() { _selectMode = true; _selected.add(items[i].id); }),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.string(_svgQr, width: 48, height: 48,
              colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.12), BlendMode.srcIn)),
          const SizedBox(height: 14),
          Text('Sem downloads',
              style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 15)),
        ]),
      );

  Future<void> _deleteSelected() async {
    for (final id in _selected.toList()) await _svc.delete(id);
    if (mounted) setState(() { _selectMode = false; _selected.clear(); });
  }

  void _openSendSheet() {
    final sel = _svc.items.where((i) => _selected.contains(i.id)).toList();
    _showSheet(_SendSheet(items: sel));
  }

  void _openReceiveSheet() {
    _showSheet(_ReceiveSheet(onDone: () { if (mounted) setState(() {}); }));
  }

  void _showSheet(Widget child) => showModalBottomSheet(
        context: context,
        backgroundColor: _card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (_) => child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _SendSheet  —  EMISSOR
//
// FLUXO:
//   1. Abre sheet → mostra campo de código + botão de câmera
//   2a. Escaneia QR  → parse do payload → liga → envia
//   2b. Digita código de 6 chars → parse → liga → envia
//   3. Conectando → spinner
//   4. Enviando → progresso
//   5. Done | Error
// ─────────────────────────────────────────────────────────────────────────────
class _SendSheet extends StatefulWidget {
  final List<DownloadedItem> items;
  const _SendSheet({required this.items});
  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  // enter | scan | connecting | sending | done | error
  String _phase = 'enter';
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  StreamSubscription<TransferProgress>? _sub;
  TransferProgress? _prog;
  int _filesDone = 0;
  DateTime? _t0;
  String _errMsg = '';

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // Chamado após QR scan — payload "pxx:SSID:PASSWORD"
  void _handleQr(String raw) {
    final parsed = TransferService.parseQrPayload(raw);
    if (parsed != null) {
      _connectAndSend(parsed.ssid, parsed.password);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('QR inválido. Tenta inserir manualmente.'),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    setState(() => _phase = 'enter');
  }

  void _tryManual() {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (ssid.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preenche o nome da rede e a password.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    FocusScope.of(context).unfocus();
    _connectAndSend(ssid, pass);
  }

  Future<void> _connectAndSend(String ssid, String password) async {
    setState(() => _phase = 'connecting');
    final ok = await TransferService.instance.connectToReceiver(ssid: ssid, password: password);
    if (!ok) {
      setState(() {
        _errMsg = 'Não foi possível ligar ao dispositivo do recetor.\nConfirma que o recetor está ativo e tenta de novo.';
        _phase = 'error';
      });
      return;
    }
    _startSend();
  }

  void _startSend() {
    final files = widget.items.map((item) {
      final f = File(item.localPath);
      return TransferFile(name: item.name, localPath: item.localPath,
          type: item.type, sizeBytes: f.existsSync() ? f.lengthSync() : 0);
    }).toList();
    setState(() { _phase = 'sending'; _t0 = DateTime.now(); });
    _sub = TransferService.instance.sendFiles(files: files).listen((p) {
      if (!mounted) return;
      setState(() => _prog = p);
      if (p.error) {
        setState(() { _errMsg = p.errorMsg ?? 'Erro ao enviar "${p.fileName}"'; _phase = 'error'; });
      } else if (p.done) {
        _filesDone++;
        if (_filesDone >= files.length) setState(() => _phase = 'done');
      }
    });
  }

  String get _speed {
    if (_prog == null || _t0 == null) return '';
    final s = DateTime.now().difference(_t0!).inMilliseconds / 1000;
    if (s < 0.1) return '';
    return '${TransferService.formatBytes((_prog!.sentBytes / s).toInt())}/s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(),

        // ── Scan directo — sem campos manuais ─────────────────────
        if (_phase == 'enter') ...[
          const _T('Aponta para o QR'),
          _sub2('Aponta a câmera para o QR que aparece no dispositivo do recetor'),
          const SizedBox(height: 16),
          _RealViewfinder(
            onScanned: (ssid, pass) => _connectAndSend(ssid, pass),
          ),
          const SizedBox(height: 8),
          _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context)),
          const SizedBox(height: 16),
        ],

        // fase 'scan' removida — agora entra directo no scanner


        // ── A ligar ───────────────────────────────────────────────────
        if (_phase == 'connecting') ...[
          const SizedBox(height: 32),
          SvgPicture.string(_svgHotspot, width: 32, height: 32,
              colorFilter: const ColorFilter.mode(_kPrimary, BlendMode.srcIn)),
          const SizedBox(height: 14),
          const _T('A ligar…'),
          _sub2('A estabelecer ligação ao recetor'),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5),
          const SizedBox(height: 32),
        ],

        // ── A enviar ──────────────────────────────────────────────────
        if (_phase == 'sending') ...[
          const SizedBox(height: 16),
          SvgPicture.string(_svgWifi, width: 28, height: 28,
              colorFilter: const ColorFilter.mode(_kPrimary, BlendMode.srcIn)),
          const SizedBox(height: 12),
          const _T('A enviar…'),
          if (_prog != null) ...[
            const SizedBox(height: 4),
            _sub2('${_prog!.fileName}  ·  $_speed'),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: _prog!.fraction, minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary)))),
            const SizedBox(height: 6),
            _sub2('${TransferService.formatBytes(_prog!.sentBytes)} / '
                '${TransferService.formatBytes(_prog!.totalBytes)}'),
          ],
          const SizedBox(height: 24),
        ],

        // ── Concluído ─────────────────────────────────────────────────
        if (_phase == 'done') ...[
          const SizedBox(height: 20),
          _SuccessIcon(),
          const SizedBox(height: 12),
          const _T('Enviado!'),
          _sub2('${widget.items.length} ficheiro(s) transferido(s)'),
          const SizedBox(height: 24),
          _GhostBtn(label: 'Fechar', onTap: () => Navigator.pop(context)),
          const SizedBox(height: 24),
        ],

        // ── Erro ──────────────────────────────────────────────────────
        if (_phase == 'error') ...[
          const SizedBox(height: 20),
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          const _T('Falha na ligação'),
          _sub2(_errMsg),
          const SizedBox(height: 20),
          _PrimaryBtn(label: 'Tentar novamente',
              onTap: () => setState(() {
                _phase = 'enter'; _filesDone = 0; _prog = null; _errMsg = ''; })),
          const SizedBox(height: 8),
          _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context)),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReceiveSheet  —  RECETOR
//
// FLUXO:
//   1. Ativa hotspot Wi-Fi Direct via TransferService
//   2. Gera código de 6 chars a partir do SSID
//   3. Mostra QR (payload completo) + código em texto grande + SSID/pass colapsado
//   4. À espera do emissor → mostra progresso quando começa a receber
//   5. Done
// ─────────────────────────────────────────────────────────────────────────────
class _ReceiveSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _ReceiveSheet({required this.onDone});
  @override
  State<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<_ReceiveSheet> {
  String _ssid = '';
  String _password = '';
  bool _ready = false;
  bool _receiving = false;
  bool _allDone = false;
  final List<TransferProgress> _files = [];
  StreamSubscription<TransferProgress>? _progressSub;
  StreamSubscription<TransferState>? _stateSub;
  DateTime? _t0;
  String _errMsg = '';

  @override
  void initState() {
    super.initState();
    _listenState();
    _start();
  }

  void _listenState() {
    _stateSub = TransferService.instance.stateStream.listen((s) {
      if (!mounted) return;
      if (s == TransferState.error) {
        setState(() => _errMsg = 'Ocorreu um erro. Tenta novamente.');
      }
    });
    _progressSub = TransferService.instance.progress.listen((p) {
      if (!mounted) return;
      setState(() {
        _receiving = true;
        _t0 ??= DateTime.now();
        final idx = _files.indexWhere((f) => f.fileName == p.fileName);
        if (idx >= 0) _files[idx] = p; else _files.add(p);
        _allDone = _files.isNotEmpty && _files.every((f) => f.done);
      });
      if (_allDone) widget.onDone();
    });
  }

  Future<void> _start() async {
    try {
      final result = await TransferService.instance.startReceiver();
      if (!mounted) return;
      setState(() { _ssid = result.ssid; _password = result.password; _ready = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errMsg = e.toString());
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _stateSub?.cancel();
    TransferService.instance.stopReceiver();
    super.dispose();
  }

  String get _qrPayload => TransferService.buildQrPayload(_ssid, _password);

  String get _speed {
    if (_files.isEmpty || _t0 == null) return '';
    final total = _files.fold<int>(0, (a, f) => a + f.sentBytes);
    final s = DateTime.now().difference(_t0!).inMilliseconds / 1000;
    if (s < 0.1) return '';
    return '${TransferService.formatBytes((total / s).toInt())}/s';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h * 0.88,
      child: Column(children: [
        _handle(),

        // ── A iniciar ─────────────────────────────────────────────────
        if (!_ready && _errMsg.isEmpty)
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.string(_svgHotspot, width: 36, height: 36,
                colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.2), BlendMode.srcIn)),
            SizedBox(height: 16),
            Text('A ativar hotspot…',
                style: TextStyle(color: AppTheme.current.isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5),
          ]))

        // ── Erro ──────────────────────────────────────────────────────
        else if (_errMsg.isNotEmpty)
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 42),
            const SizedBox(height: 12),
            const _T('Permissão necessária'),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errMsg, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))),
            const SizedBox(height: 24),
            _PrimaryBtn(label: 'Tentar novamente', onTap: () {
              setState(() { _errMsg = ''; _ready = false; });
              _start();
            }),
            const SizedBox(height: 8),
            _GhostBtn(label: 'Fechar', onTap: () => Navigator.pop(context)),
          ]))

        // ── Concluído ─────────────────────────────────────────────────
        else if (_allDone) ...[
          const Spacer(),
          _SuccessIcon(),
          const SizedBox(height: 14),
          const _T('Transferência completa!'),
          _sub2('${_files.length} ficheiro(s) guardado(s) no app'),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: _GhostBtn(label: 'Fechar', onTap: () => Navigator.pop(context))),
        ]

        // ── Pronto — QR + código + progresso ──────────────────────────
        else ...[
          const _T('Pronto para receber'),
          _sub2('Mostra este código ou QR ao emissor'),
          const SizedBox(height: 16),

          // ── QR + SSID + password ──────────────────────────────────
          if (!_receiving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.current.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(children: [
                  // QR no topo — escaneia e liga sem digitar nada
                  _QrDisplay(payload: _qrPayload),
                  const SizedBox(height: 8),
                  Text('Escaneia com o outro app',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),

                  SizedBox(height: 16),
                  Divider(color: AppTheme.current.isDark ? Colors.white12 : Colors.black12, height: 1),
                  const SizedBox(height: 16),

                  // SSID + password visíveis para inserção manual
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ou insere manualmente no outro app:',
                            style: TextStyle(
                                color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26, fontSize: 11)),
                        const SizedBox(height: 10),
                        _NetworkInfo(ssid: _ssid, password: _password),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

          // ── A receber — progresso ──────────────────────────────────
          if (_receiving)
            Expanded(child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: _files.map((f) => _FileBar(p: f, speed: _speed)).toList(),
            ))
          else ...[
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5,
                    color: Colors.white.withOpacity(0.22))),
              const SizedBox(width: 10),
              Text('À espera do emissor…',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
            ]),
          ],

          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context))),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NetworkInfo  —  SSID + password colapsável (usado dentro do _ReceiveSheet)
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkInfo extends StatefulWidget {
  final String ssid, password;
  const _NetworkInfo({required this.ssid, required this.password});
  @override
  State<_NetworkInfo> createState() => _NetworkInfoState();
}

class _NetworkInfoState extends State<_NetworkInfo> {
  bool _showPass = false;
  bool _copiedSsid = false;
  bool _copiedPass = false;

  void _copy(String text, bool isSsid) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() { if (isSsid) _copiedSsid = true; else _copiedPass = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _copiedSsid = false; _copiedPass = false; });
  }

  Widget _row(String label, String value, bool isSsid, bool copied) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26, fontSize: 11)),
      const SizedBox(height: 2),
      Text(
        isSsid ? value : (_showPass ? value : '••••••••'),
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    ])),
    if (!isSsid)
      GestureDetector(
        onTap: () => setState(() => _showPass = !_showPass),
        child: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppTheme.current.thumbIcon, size: 16),
      ),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: () => _copy(value, isSsid),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: copied
            ? const Icon(Icons.check_rounded, key: ValueKey('ok'), color: _kPrimary, size: 16)
            : Icon(Icons.copy_rounded, key: const ValueKey('cp'),
                color: Colors.white.withOpacity(0.3), size: 14),
      ),
    ),
  ]);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.current.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: [
      _row('Rede (SSID)', widget.ssid, true, _copiedSsid),
      const SizedBox(height: 10),
      _row('Password', widget.password, false, _copiedPass),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _QrDisplay  —  QR real via qr_flutter
// ─────────────────────────────────────────────────────────────────────────────
class _QrDisplay extends StatelessWidget {
  final String payload;
  const _QrDisplay({required this.payload});
  @override
  Widget build(BuildContext context) => Container(
    width: 160,
    height: 160,
    color: AppTheme.current.text,
    padding: const EdgeInsets.all(8),
    child: QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: 144,
    ),
  );
}

// ─── Barra de progresso por ficheiro ──────────────────────────────────────────
class _FileBar extends StatelessWidget {
  final TransferProgress p;
  final String speed;
  const _FileBar({required this.p, required this.speed});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p.fileName, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            Text(p.done
                ? TransferService.formatBytes(p.totalBytes)
                : '${TransferService.formatBytes(p.sentBytes)} · $speed',
                style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: p.fraction, minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                    p.done ? _kPrimary : _kPrimary.withOpacity(0.7)))),
        ]),
      );
}

// ─── _RealViewfinder — câmera real com MobileScanner ─────────────────────────
class _RealViewfinder extends StatefulWidget {
  final void Function(String ssid, String pass) onScanned;
  const _RealViewfinder({required this.onScanned});
  @override
  State<_RealViewfinder> createState() => _RealViewfinderState();
}

class _RealViewfinderState extends State<_RealViewfinder> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = TransferService.parseQrPayload(raw);
    if (parsed == null) return;
    _scanned = true;
    _ctrl.stop();
    widget.onScanned(parsed.ssid, parsed.password);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withOpacity(0.5), width: 1.5),
      ),
      child: Stack(children: [
        // Câmera real
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),
        // Overlay com moldura de cantos
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),
        // Linha de scan animada
        const _ScanLine(),
        // Hint em baixo
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.current.isDark ? Colors.black54 : Colors.white70,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Aponta para o QR do recetor',
                  style: TextStyle(color: AppTheme.current.iconSub, fontSize: 12)),
            ),
          ),
        ),
      ]),
    );
  }
}

// Overlay com cantos laranja
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r = 6.0;
    final corners = [
      // top-left
      [Offset(r, len), Offset(r, r), Offset(len, r)],
      // top-right
      [Offset(size.width - r, len), Offset(size.width - r, r), Offset(size.width - len, r)],
      // bottom-left
      [Offset(r, size.height - len), Offset(r, size.height - r), Offset(len, size.height - r)],
      // bottom-right
      [Offset(size.width - r, size.height - len), Offset(size.width - r, size.height - r), Offset(size.width - len, size.height - r)],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// Linha de scan animada
class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800));
    _anim = Tween<double>(begin: 0.05, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _c.repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        left: 24, right: 24,
        top: _anim.value * 240,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _kPrimary.withOpacity(0),
              _kPrimary,
              _kPrimary.withOpacity(0),
            ]),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// Manter _CP para compatibilidade (já não usado mas evita erros de compilação)
class _CP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {}
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _Tile
// ─────────────────────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final DownloadedItem item;
  final bool selected, selectMode;
  final VoidCallback onTap, onLongPress;
  const _Tile({required this.item, required this.selected,
      required this.selectMode, required this.onTap, required this.onLongPress});

  double get _ratio { final h = item.id.hashCode.abs() % 3; if (h == 0) return 3/4; if (h == 1) return 2/3; return 1; }

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    return GestureDetector(
      onTap: onTap, onLongPress: onLongPress,
      child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: AspectRatio(aspectRatio: isVideo ? 9/16 : _ratio,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            if (!isVideo && file.existsSync()) Image.file(file, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03))),
            if (isVideo) Center(child: Container(width: 42, height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.55)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26))),
            if (selected) Container(color: _kPrimary.withOpacity(0.25),
                alignment: Alignment.topRight, padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)),
            if (selectMode && !selected) Positioned(top: 4, right: 4,
              child: Container(width: 18, height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.current.isDark ? Colors.white54 : Colors.black45, width: 1.5), color: Colors.black38))),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Viewer
// ─────────────────────────────────────────────────────────────────────────────
class _Viewer extends StatefulWidget {
  final DownloadedItem item;
  const _Viewer({required this.item});
  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == 'video') _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _vpc = VideoPlayerController.file(File(widget.item.localPath));
      await _vpc!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _vpc!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: _kPrimary,
          handleColor: _kPrimary,
          backgroundColor: Colors.white12,
          bufferedColor: Colors.white24,
        ),
      );
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.item.type == 'video';
    final file = File(widget.item.localPath);
    return Scaffold(
      backgroundColor: AppTheme.current.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.current.bg, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SvgPicture.string(_svgBack, width: 20, height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.item.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
      body: isVideo
          ? _error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.white.withOpacity(0.18), size: 64),
                  SizedBox(height: 12),
                  Text('Não foi possível reproduzir',
                      style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26)),
                ]))
              : !_ready
                  ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5))
                  : Chewie(controller: _chewie!)
          : Center(
              child: InteractiveViewer(child: Image.file(file,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image_outlined,
                          color: Colors.white.withOpacity(0.18), size: 64)))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets comuns
// ─────────────────────────────────────────────────────────────────────────────
Widget _handle() => Column(children: [
      SizedBox(height: 10),
      Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppTheme.current.isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 14),
    ]);

Widget _sub2(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(t, textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.38) : Colors.black38, fontSize: 13)));

class _T extends StatelessWidget {
  final String text;
  const _T(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700));
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 58, height: 58,
        decoration: const BoxDecoration(color: Color(0x22FF9000), shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: _kPrimary, size: 32));
}

class _ABtn extends StatelessWidget {
  final String svg; final Color color; final VoidCallback onTap;
  const _ABtn({required this.svg, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: SvgPicture.string(svg, width: 20, height: 20,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn))));
}

class _BigBtn extends StatelessWidget {
  final String svg, label, sub; final VoidCallback onTap;
  const _BigBtn({required this.svg, required this.label, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
        child: Container(height: 108,
          decoration: BoxDecoration(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.string(svg, width: 27, height: 27,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text(sub, style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26, fontSize: 10)),
          ])));
}

class _PrimaryBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(onTap: onTap,
          child: Container(height: 50,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: AppTheme.current.bg, fontSize: 15, fontWeight: FontWeight.w700)))));
}

class _GhostBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(onTap: onTap,
          child: Container(height: 48,
            decoration: BoxDecoration(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: AppTheme.current.isDark ? Colors.white54 : Colors.black45, fontSize: 14)))));
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        child: Text('← Voltar',
            style: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.35) : Colors.black26, fontSize: 13)));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool autofocus;
  final bool obscure;
  final VoidCallback onDone;
  const _Field({required this.ctrl, required this.hint,
      this.autofocus = false, this.obscure = false, required this.onDone});
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl, autofocus: autofocus, obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) => onDone(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.current.isDark ? Colors.white.withOpacity(0.25) : Colors.black12, fontSize: 13),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ));
}
