import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/download_service.dart';
import '../services/transfer_service.dart';

const _kPrimary = Color(0xFFFF9000);
const _kBg      = Color(0xFF111111);
const _kCard2   = Color(0xFF1A1A1A);

// ─── ÍCONE DE VOLTAR (conforme enviado) ──────────────────────────────────────
const _svgBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

const _svgSend =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m4.034.282C2.981-.22,1.748-.037.893.749.054,1.521-.22,2.657.18,3.717'
    'l4.528,8.288L.264,20.288c-.396,1.061-.121,2.196.719,2.966.524.479,1.19.734,'
    '1.887.734.441,0,.895-.102,1.332-.312l19.769-11.678L4.034.282Zm-2.002,2.676'
    'c-.114-.381.108-.64.214-.736.095-.087.433-.348.895-.149l15.185,8.928H6.438'
    'L2.032,2.958Zm1.229,18.954c-.472.228-.829-.044-.928-.134-.105-.097-.329-.355'
    '-.214-.737l4.324-8.041h11.898L3.261,21.912Z"/></svg>';

const _svgQr =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M3,3h7v7H3V3Zm2,2v3h3V5H5Z"/>'
    '<path d="M14,3h7v7h-7V3Zm2,2v3h3V5h-3Z"/>'
    '<path d="M3,14h7v7H3v-7Zm2,2v3h3v-3H5Z"/>'
    '<path d="M14,14h2v2h-2v-2Z"/><path d="M18,14h3v2h-3v-2Z"/>'
    '<path d="M14,18h2v3h-2v-3Z"/><path d="M18,18h3v3h-3v-3Z"/>'
    '</svg>';

const _svgTrash =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21,4H17.9A5.009,5.009,0,0,0,13,0H11A5.009,5.009,0,0,0,6.1,4H3'
    'A1,1,0,0,0,3,6H4V19a5.006,5.006,0,0,0,5,5h6a5.006,5.006,0,0,0,5-5V6h1'
    'a1,1,0,0,0,0-2ZM11,2h2a3.006,3.006,0,0,1,2.829,2H8.171A3.006,3.006,0,0,1,11,2Z'
    'm7,17a3,3,0,0,1-3,3H9a3,3,0,0,1-3-3V6H18Z"/>'
    '<path d="M10,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,10,18Z"/>'
    '<path d="M14,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,14,18Z"/>'
    '</svg>';

const _svgWifi =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="12" cy="20" r="2" fill="currentColor"/>'
    '<path d="M12,13a8,8,0,0,0-5.657,2.343,1,1,0,1,0,1.414,1.414,6,6,0,0,1,8.486,0,1,1,0,1,0,1.414-1.414A8,8,0,0,0,12,13Z" fill="currentColor"/>'
    '<path d="M12,8A13,13,0,0,0,2.808,11.808a1,1,0,1,0,1.414,1.414,11,11,0,0,1,15.556,0,1,1,0,0,0,1.414-1.414A13,13,0,0,0,12,8Z" fill="currentColor"/>'
    '<path d="M23.536,4.05A18,18,0,0,0,.464,4.05,1,1,0,1,0,1.878,5.464a16,16,0,0,1,20.244,0A1,1,0,1,0,23.536,4.05Z" fill="currentColor"/>'
    '</svg>';

const _svgHotspot =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M12,2A10,10,0,1,0,22,12,10,10,0,0,0,12,2Zm0,18a8,8,0,1,1,8-8A8,8,0,0,1,12,20Z"/>'
    '<circle cx="12" cy="12" r="3"/>'
    '<path d="M12,7a5,5,0,1,0,5,5A5,5,0,0,0,12,7Zm0,8a3,3,0,1,1,3-3A3,3,0,0,1,12,15Z" opacity=".4"/>'
    '</svg>';

const _svgScanner =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m23,13H1c-.552,0-1-.448-1-1s.448-1,1-1h22c.552,0,1,.448,1,1s-.448,1-1,1Z'
    'm-15,10c0-.552-.448-1-1-1h-2c-1.654,0-3-1.346-3-3v-2c0-.552-.448-1-1-1s-1,.448-1,1'
    'v2c0,2.757,2.243,5,5,5h2c.552,0,1-.448,1-1Zm16-4v-2c0-.552-.448-1-1-1s-1,.448-1,1v2'
    'c0,1.654-1.346,3-3,3h-2c-.552,0-1,.448-1,1s.448,1,1,1h2c2.757,0,5-2.243,5-5Z'
    'm0-12v-2c0-2.757-2.243-5-5-5h-2c-.552,0-1,.448-1,1s.448,1,1,1h2c1.654,0,3,1.346,3,3'
    'v2c0,.552.448,1,1,1s1-.448,1-1Zm-22,0v-2c0-1.654,1.346-3,3-3h2c.552,0,1-.448,1-1'
    's-.448-1-1-1h-2C2.243,0,0,2.243,0,5v2c0,.552.448,1,1,1s1-.448,1-1Z"/>'
    '</svg>';

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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
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
        backgroundColor: _kCard2,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (_) => child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _SendSheet  —  EMISSOR
// Fases: choose → scan | manual → connecting → sending → done | error
// ─────────────────────────────────────────────────────────────────────────────
class _SendSheet extends StatefulWidget {
  final List<DownloadedItem> items;
  const _SendSheet({required this.items});
  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  // choose | scan | manual | connecting | sending | done | error
  String _phase = 'choose';
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  StreamSubscription<TransferProgress>? _sub;
  TransferProgress? _prog;
  int _filesDone = 0;
  DateTime? _t0;
  String _errMsg = '';

  @override
  void dispose() { _ssidCtrl.dispose(); _passCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  Future<void> _connectAndSend(String ssid, String password) async {
    setState(() { _phase = 'connecting'; });
    final ok = await TransferService.instance.connectToReceiver(
        ssid: ssid, password: password);
    if (!ok) {
      setState(() {
        _errMsg = 'Não foi possível ligar ao hotspot "$ssid".\n'
            'Liga manualmente nas definições Wi-Fi e tenta de novo.';
        _phase = 'error';
      });
      return;
    }
    _startSend();
  }

  void _startSend() {
    final files = widget.items.map((item) {
      final f = File(item.localPath);
      return TransferFile(
        name: item.name, localPath: item.localPath,
        type: item.type, sizeBytes: f.existsSync() ? f.lengthSync() : 0,
      );
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

  void _tryManual() {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Insere o nome da rede (SSID)'),
        backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    FocusScope.of(context).unfocus();
    _connectAndSend(ssid, pass);
  }

  String get _speed {
    if (_prog == null || _t0 == null) return '';
    final s = DateTime.now().difference(_t0!).inMilliseconds / 1000;
    if (s <= 0) return '';
    return '${TransferService.formatBytes((_prog!.sentBytes / s).toInt())}/s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(),

        // ── Escolha ───────────────────────────────────────────────────
        if (_phase == 'choose') ...[
          const _T('Enviar via Wi-Fi Direto'),
          _sub2('${widget.items.length} ficheiro(s)  ·  sem internet  ·  ultra rápido'),
          const SizedBox(height: 28),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(child: _BigBtn(svg: _svgScanner, label: 'Escanear QR',
                  sub: 'Lê o QR do recetor', onTap: () => setState(() => _phase = 'scan'))),
              const SizedBox(width: 12),
              Expanded(child: _BigBtn(svg: _svgWifi, label: 'Inserir rede',
                  sub: 'SSID + password do recetor', onTap: () => setState(() => _phase = 'manual'))),
            ]),
          ),
          const SizedBox(height: 28),
        ],

        // ── QR scan ───────────────────────────────────────────────────
        if (_phase == 'scan') ...[
          const _T('Escanear QR do recetor'),
          const SizedBox(height: 16),
          _Viewfinder(onManual: () => setState(() => _phase = 'manual'),
              onScanned: (ssid, pass) => _connectAndSend(ssid, pass)),
          const SizedBox(height: 12),
          _BackBtn(onTap: () => setState(() => _phase = 'choose')),
          const SizedBox(height: 16),
        ],

        // ── Manual ────────────────────────────────────────────────────
        if (_phase == 'manual') ...[
          const _T('Rede Wi-Fi do recetor'),
          _sub2('Vai a "Receber" no outro telemóvel e copia o SSID'),
          const SizedBox(height: 18),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              _Field(ctrl: _ssidCtrl, hint: 'Nome da rede (SSID)  ex: pXX_A1B2C3',
                  autofocus: true, onDone: () => FocusScope.of(context).nextFocus()),
              const SizedBox(height: 10),
              _Field(ctrl: _passCtrl, hint: 'Password', obscure: true, onDone: _tryManual),
            ]),
          ),
          const SizedBox(height: 16),
          _PrimaryBtn(label: 'Ligar e enviar', onTap: _tryManual),
          const SizedBox(height: 4),
          // Fallback: abrir definições Wi-Fi manualmente
          TextButton(
            onPressed: () async {
              await TransferService.openWifiSettings();
              if (mounted) setState(() => _phase = 'sending');
              _startSend();
            },
            child: Text('Já liguei manualmente → continuar',
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
          ),
          _BackBtn(onTap: () => setState(() => _phase = 'choose')),
          const SizedBox(height: 12),
        ],

        // ── A ligar ───────────────────────────────────────────────────
        if (_phase == 'connecting') ...[
          const SizedBox(height: 28),
          SvgPicture.string(_svgHotspot, width: 32, height: 32,
              colorFilter: const ColorFilter.mode(_kPrimary, BlendMode.srcIn)),
          const SizedBox(height: 14),
          const _T('A ligar ao hotspot…'),
          _sub2('Aguarda enquanto nos ligamos à rede do recetor'),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5),
          const SizedBox(height: 28),
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
            _sub2('${TransferService.formatBytes(_prog!.sentBytes)} / ${TransferService.formatBytes(_prog!.totalBytes)}'),
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
              onTap: () => setState(() { _phase = 'choose'; _filesDone = 0; _prog = null; })),
          const SizedBox(height: 6),
          // Abre definições Wi-Fi do sistema
          TextButton(
            onPressed: TransferService.openWifiSettings,
            child: Text('Abrir definições Wi-Fi',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ),
          _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context)),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReceiveSheet  —  RECETOR
// Ativa hotspot do Android, mostra SSID + password + QR, recebe via TCP
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
        setState(() { _errMsg = 'Ocorreu um erro. Tenta novamente.'; });
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
      setState(() { _errMsg = e.toString(); });
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _stateSub?.cancel();
    TransferService.instance.stopReceiver();
    super.dispose();
  }

  String get _qrPayload =>
      TransferService.buildQrPayload(_ssid, _password);

  String get _speed {
    if (_files.isEmpty || _t0 == null) return '';
    final total = _files.fold<int>(0, (a, f) => a + f.sentBytes);
    final s = DateTime.now().difference(_t0!).inMilliseconds / 1000;
    if (s <= 0) return '';
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
            const SizedBox(height: 16),
            const Text('A ativar hotspot…',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5),
            const SizedBox(height: 12),
            TextButton(
              onPressed: TransferService.openWifiSettings,
              child: Text('Ativar manualmente nas definições',
                  style: TextStyle(color: _kPrimary.withOpacity(0.7), fontSize: 12)),
            ),
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
            _PrimaryBtn(label: 'Abrir definições', onTap: TransferService.openWifiSettings),
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

        // ── Pronto / A receber ─────────────────────────────────────────
        else ...[
          const _T('Hotspot ativo · Pronto para receber'),
          _sub2('O emissor deve ligar-se a esta rede Wi-Fi'),
          const SizedBox(height: 20),

          // QR code com SSID + password
          _QrDisplay(payload: _qrPayload),

          const SizedBox(height: 18),

          // SSID
          _NetworkInfo(ssid: _ssid, password: _password),

          const SizedBox(height: 18),

          // Status
          if (!_receiving)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5,
                    color: Colors.white.withOpacity(0.22))),
              const SizedBox(width: 10),
              Text('À espera do emissor…',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
            ])
          else
            Expanded(child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _files.map((f) => _FileBar(p: f, speed: _speed)).toList(),
            )),

          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context))),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NetworkInfo  —  mostra SSID e password com botão de copiar
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(children: [
          // SSID
          Row(children: [
            SvgPicture.string(_svgHotspot, width: 14, height: 14,
                colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.4), BlendMode.srcIn)),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.ssid,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
            GestureDetector(
              onTap: () => _copy(widget.ssid, true),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: _copiedSsid
                    ? const Icon(Icons.check_rounded, key: ValueKey('cs'), color: _kPrimary, size: 16)
                    : Icon(Icons.copy_rounded, key: const ValueKey('ns'),
                        color: Colors.white.withOpacity(0.3), size: 14)),
            ),
          ]),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 10),
          // Password
          Row(children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 8),
            Expanded(child: Text(
                _showPass ? widget.password : '•' * widget.password.length,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
            GestureDetector(
              onTap: () => setState(() => _showPass = !_showPass),
              child: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _copy(widget.password, false),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: _copiedPass
                    ? const Icon(Icons.check_rounded, key: ValueKey('cp'), color: _kPrimary, size: 16)
                    : Icon(Icons.copy_rounded, key: const ValueKey('np'),
                        color: Colors.white.withOpacity(0.3), size: 14)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QrDisplay  —  QR visual (CustomPainter)
// Em produção: QrImageView(data: payload) do package qr_flutter
// ─────────────────────────────────────────────────────────────────────────────
class _QrDisplay extends StatelessWidget {
  final String payload;
  const _QrDisplay({required this.payload});
  @override
  Widget build(BuildContext context) => Container(
        width: 186, height: 186,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.45),
                blurRadius: 22, offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(painter: _QrPainter(payload)),
        ),
      );
}

class _QrPainter extends CustomPainter {
  final String data;
  const _QrPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    const n = 21;
    final cs = size.width / n;
    final black = Paint()..color = Colors.black;
    final white = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), white);
    _f(canvas, black, white, 0, 0, cs);
    _f(canvas, black, white, n - 7, 0, cs);
    _f(canvas, black, white, 0, n - 7, cs);
    for (int i = 8; i < n - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cs, 6 * cs, cs, cs), black);
        canvas.drawRect(Rect.fromLTWH(6 * cs, i * cs, cs, cs), black);
      }
    }
    final seed = data.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFF);
    final rng = Random(seed);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_res(r, c, n)) continue;
        if (rng.nextBool()) canvas.drawRect(
            Rect.fromLTWH(c * cs + .5, r * cs + .5, cs - 1, cs - 1), black);
      }
    }
  }
  void _f(Canvas cv, Paint b, Paint w, int cx, int cy, double cs) {
    cv.drawRect(Rect.fromLTWH(cx*cs, cy*cs, 7*cs, 7*cs), b);
    cv.drawRect(Rect.fromLTWH((cx+1)*cs,(cy+1)*cs,5*cs,5*cs), w);
    cv.drawRect(Rect.fromLTWH((cx+2)*cs,(cy+2)*cs,3*cs,3*cs), b);
  }
  bool _res(int r, int c, int n) {
    if (r < 8 && c < 8) return true;
    if (r < 8 && c >= n-8) return true;
    if (r >= n-8 && c < 8) return true;
    if (r == 6 || c == 6) return true;
    return false;
  }
  @override
  bool shouldRepaint(covariant _QrPainter o) => o.data != data;
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
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
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

// ─── Viewfinder ───────────────────────────────────────────────────────────────
class _Viewfinder extends StatelessWidget {
  final VoidCallback onManual;
  final void Function(String ssid, String pass) onScanned;
  const _Viewfinder({required this.onManual, required this.onScanned});

  List<Widget> _corners() {
    Widget c(bool fx, bool fy) => Positioned(
          left: fx ? null : 14, right: fx ? 14 : null,
          top: fy ? null : 14, bottom: fy ? 14 : null,
          child: Transform.scale(scaleX: fx ? -1 : 1, scaleY: fy ? -1 : 1,
              child: CustomPaint(painter: _CP(), size: const Size(22, 22))));
    return [c(false,false),c(true,false),c(false,true),c(true,true)];
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kPrimary.withOpacity(0.4), width: 1.5),
        ),
        child: Stack(alignment: Alignment.center, children: [
          ..._corners(),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.string(_svgScanner, width: 38, height: 38,
                colorFilter: const ColorFilter.mode(Colors.white24, BlendMode.srcIn)),
            const SizedBox(height: 10),
            const Text('Aponta para o QR do recetor',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 18),
            GestureDetector(onTap: onManual,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Inserir rede manualmente',
                    style: TextStyle(color: Colors.white54, fontSize: 12)))),
          ]),
        ]),
      );
}

class _CP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawPath(Path()
          ..moveTo(0, s.height*.6)..lineTo(0, 4)
          ..arcToPoint(const Offset(4, 0), radius: const Radius.circular(4))
          ..lineTo(s.width*.6, 0),
        Paint()..color = _kPrimary..strokeWidth = 2.5
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
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
            Container(color: Colors.white.withOpacity(0.05)),
            if (!isVideo && file.existsSync()) Image.file(file, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white.withOpacity(0.05))),
            if (isVideo) Center(child: Container(width: 42, height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.55)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26))),
            if (selected) Container(color: _kPrimary.withOpacity(0.25),
                alignment: Alignment.topRight, padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)),
            if (selectMode && !selected) Positioned(top: 4, right: 4,
              child: Container(width: 18, height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1.5), color: Colors.black38))),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Viewer
// ─────────────────────────────────────────────────────────────────────────────
class _Viewer extends StatelessWidget {
  final DownloadedItem item;
  const _Viewer({required this.item});
  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SvgPicture.string(_svgBack, width: 20, height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(item.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
      body: Center(
        child: isVideo
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam_rounded, color: Colors.white.withOpacity(0.18), size: 64),
                const SizedBox(height: 16),
                Text('Vídeo guardado', style: TextStyle(color: Colors.white.withOpacity(0.35))),
              ])
            : InteractiveViewer(child: Image.file(file,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image_outlined, color: Colors.white.withOpacity(0.18), size: 64))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets comuns
// ─────────────────────────────────────────────────────────────────────────────
Widget _handle() => Column(children: [
      const SizedBox(height: 10),
      Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 14),
    ]);

Widget _sub2(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(t, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 13)));

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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.string(svg, width: 27, height: 27,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
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
            child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)))));
}

class _GhostBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(onTap: onTap,
          child: Container(height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)))));
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        child: Text('← Voltar',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)));
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
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ));
}
