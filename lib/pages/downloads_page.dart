import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/download_service.dart';

// ── SVG icons do utilizador ───────────────────────────────────────────────────
const _svgSend = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="m4.034.282C2.981-.22,1.748-.037.893.749.054,1.521-.22,2.657.18,3.717l4.528,8.288L.264,20.288c-.396,1.061-.121,2.196.719,2.966.524.479,1.19.734,1.887.734.441,0,.895-.102,1.332-.312l19.769-11.678L4.034.282Zm-2.002,2.676c-.114-.381.108-.64.214-.736.095-.087.433-.348.895-.149l15.185,8.928H6.438L2.032,2.958Zm1.229,18.954c-.472.228-.829-.044-.928-.134-.105-.097-.329-.355-.214-.737l4.324-8.041h11.898L3.261,21.912Z"/></svg>''';

const _svgScanner = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="m23,13H1c-.552,0-1-.448-1-1s.448-1,1-1h22c.552,0,1,.448,1,1s-.448,1-1,1Zm-15,10c0-.552-.448-1-1-1h-2c-1.654,0-3-1.346-3-3v-2c0-.552-.448-1-1-1s-1,.448-1,1v2c0,2.757,2.243,5,5,5h2c.552,0,1-.448,1-1Zm16-4v-2c0-.552-.448-1-1-1s-1,.448-1,1v2c0,1.654-1.346,3-3,3h-2c-.552,0-1,.448-1,1s.448,1,1,1h2c2.757,0,5-2.243,5-5Zm0-12v-2c0-2.757-2.243-5-5-5h-2c-.552,0-1,.448-1,1s.448,1,1,1h2c1.654,0,3,1.346,3,3v2c0,.552.448,1,1,1s1-.448,1-1Zm-22,0v-2c0-1.654,1.346-3,3-3h2c.552,0,1-.448,1-1s-.448-1-1-1h-2C2.243,0,0,2.243,0,5v2c0,.552.448,1,1,1s1-.448,1-1Z"/></svg>''';

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
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _selectMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() { _selectMode = false; _selected.clear(); }),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
        title: Text(
          _selectMode ? '${_selected.length} selecionados' : 'Downloads',
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: _selectMode
          ? [
              if (_selected.isNotEmpty) ...[
                // Botão Enviar com SVG do utilizador
                GestureDetector(
                  onTap: _openSendSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: SvgPicture.string(_svgSend, width: 20, height: 20,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: _deleteSelected,
                ),
              ],
            ]
          : [
              // Botão Enviar (entra em modo seleção)
              GestureDetector(
                onTap: () => setState(() => _selectMode = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: SvgPicture.string(_svgSend, width: 20, height: 20,
                      colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.65), BlendMode.srcIn)),
                ),
              ),
              const SizedBox(width: 4),
            ],
      ),
      body: items.isEmpty
          ? _empty()
          : MasonryGridView.count(
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
                      if (_selected.contains(items[i].id)) {
                        _selected.remove(items[i].id);
                      } else {
                        _selected.add(items[i].id);
                      }
                      if (_selected.isEmpty) _selectMode = false;
                    });
                  } else {
                    _view(items[i]);
                  }
                },
                onLongPress: () {
                  setState(() {
                    _selectMode = true;
                    _selected.add(items[i].id);
                  });
                },
              ),
            ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.download_outlined, color: Colors.white.withOpacity(0.15), size: 56),
      const SizedBox(height: 12),
      Text('Sem downloads', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
    ]),
  );

  void _view(DownloadedItem item) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => _Viewer(item: item)));

  Future<void> _deleteSelected() async {
    for (final id in _selected.toList()) {
      await _svc.delete(id);
    }
    if (mounted) setState(() { _selectMode = false; _selected.clear(); });
  }

  void _openSendSheet() {
    final selected = _svc.items.where((i) => _selected.contains(i.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _SendSheet(items: selected),
    );
  }
}

// ── Send Sheet ────────────────────────────────────────────────────────────────
class _SendSheet extends StatefulWidget {
  final List<DownloadedItem> items;
  const _SendSheet({required this.items});

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  // Fase: 'choose' | 'qr_receive' | 'scan' | 'code_input'
  String _phase = 'choose';
  // Código de 10 caracteres gerado para receber
  late final String _receiveCode;

  @override
  void initState() {
    super.initState();
    _receiveCode = _genCode();
  }

  String _genCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buf = StringBuffer();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 10; i++) {
      buf.write(chars[(now + i * 7) % chars.length]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white12,
                borderRadius: BorderRadius.circular(2)))),

        if (_phase == 'choose') ...[
          const Text('Partilhar', style: TextStyle(color: Colors.white, fontSize: 17,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${widget.items.length} ficheiro(s) selecionado(s)',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _BigBtn(
              svg: _svgSend,
              label: 'Enviar',
              sub: 'Scan QR do recetor',
              onTap: () => setState(() => _phase = 'scan'),
            ),
            _BigBtn(
              svg: _svgScanner,
              label: 'Receber',
              sub: 'Mostra o teu QR',
              onTap: () => setState(() => _phase = 'qr_receive'),
            ),
          ]),
          const SizedBox(height: 24),
        ],

        if (_phase == 'qr_receive') ...[
          const Text('O teu código de receção', style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          // Placeholder QR visual
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.qr_code_rounded, size: 80, color: Colors.black),
              const SizedBox(height: 4),
              Text(_receiveCode, style: const TextStyle(color: Colors.black,
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ])),
          ),
          const SizedBox(height: 12),
          Text('Código: $_receiveCode',
              style: const TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Mostra este QR ou código à pessoa que vai enviar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 16),
          _TextBtn(label: '← Voltar', onTap: () => setState(() => _phase = 'choose')),
          const SizedBox(height: 16),
        ],

        if (_phase == 'scan') ...[
          const Text('Escanear QR do recetor', style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            height: 200, width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.string(_svgScanner, width: 44, height: 44,
                  colorFilter: const ColorFilter.mode(Colors.white30, BlendMode.srcIn)),
              const SizedBox(height: 12),
              const Text('Câmara para scan', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => _phase = 'code_input'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Inserir código manualmente'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _TextBtn(label: '← Voltar', onTap: () => setState(() => _phase = 'choose')),
          const SizedBox(height: 16),
        ],

        if (_phase == 'code_input') ...[
          const Text('Inserir código do recetor', style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  letterSpacing: 3, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLength: 10,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'xxxxxxxxxx',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2),
                    fontSize: 20, letterSpacing: 3),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          _TextBtn(label: 'Usar scanner', onTap: () => setState(() => _phase = 'scan')),
          _TextBtn(label: '← Voltar', onTap: () => setState(() => _phase = 'choose')),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String svg, label, sub;
  final VoidCallback onTap;
  const _BigBtn({required this.svg, required this.label,
      required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130, height: 110,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SvgPicture.string(svg, width: 30, height: 30,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final DownloadedItem item;
  final bool selected, selectMode;
  final VoidCallback onTap, onLongPress;
  const _Tile({required this.item, required this.selected,
      required this.selectMode, required this.onTap, required this.onLongPress});

  double get _ratio {
    final h = item.id.hashCode.abs() % 3;
    if (h == 0) return 3 / 4;
    if (h == 1) return 2 / 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    return GestureDetector(
      onTap: onTap, onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: isVideo ? 9 / 16 : _ratio,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: Colors.white.withOpacity(0.05)),
            if (!isVideo && file.existsSync())
              Image.file(file, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ph(isVideo)),
            if (isVideo)
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.55)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              )),
            if (selected)
              Container(
                color: Colors.blue.withOpacity(0.35),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.check_circle_rounded, color: Colors.blue, size: 20),
                  ),
                ),
              ),
            if (selectMode && !selected)
              Positioned(top: 4, right: 4,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                      color: Colors.black38),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _ph(bool isVideo) => Container(
    color: Colors.white.withOpacity(0.05),
    child: Center(child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white24, size: 24)),
  );
}

// ── Viewer ────────────────────────────────────────────────────────────────────
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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(item.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
      body: Center(
        child: isVideo
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam_rounded, color: Colors.white.withOpacity(0.2), size: 64),
                const SizedBox(height: 16),
                Text('Vídeo guardado', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ])
            : InteractiveViewer(
                child: Image.file(file,
                    errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
                        color: Colors.white.withOpacity(0.2), size: 64)),
              ),
      ),
    );
  }
}
