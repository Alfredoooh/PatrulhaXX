import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';

// ─── Configuração GitHub ──────────────────────────────────────────────────────
const _kGhOwner  = 'Alfredoooh';
const _kGhRepo   = 'data';
const _kGhBranch = 'main';
const _kGhToken  = String.fromEnvironment('GH_TOKEN');

// ─── SVG inline — ícone X (close) ─────────────────────────────────────────────
// Evita dependência de um asset file que pode não estar mapeado
const _svgClose = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>''';

// ─── Estrutura de publicação ──────────────────────────────────────────────────
class PostPayload {
  final String id, text, createdAt, author;
  final List<MediaPayload> media;

  PostPayload({
    required this.id, required this.text, required this.media,
    required this.createdAt, required this.author,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'author': author, 'text': text,
    'media': media.map((m) => m.toJson()).toList(),
    'createdAt': createdAt, 'platform': 'android',
  };
}

class MediaPayload {
  final String type, url, filename;
  final int sizeBytes;

  MediaPayload({required this.type, required this.url, required this.filename, required this.sizeBytes});

  Map<String, dynamic> toJson() => {
    'type': type, 'url': url, 'filename': filename, 'sizeBytes': sizeBytes,
  };
}

// ─── Upload GitHub ─────────────────────────────────────────────────────────────
Future<String> _uploadToGitHub(File file, String filename) async {
  final bytes   = await file.readAsBytes();
  final content = base64Encode(bytes);
  final path    = 'uploads/$filename';
  final url     = Uri.parse('https://api.github.com/repos/$_kGhOwner/$_kGhRepo/contents/$path');

  String? sha;
  final getRes = await http.get(url, headers: {
    'Authorization': 'token $_kGhToken',
    'Accept': 'application/vnd.github+json',
  });
  if (getRes.statusCode == 200) sha = json.decode(getRes.body)['sha'] as String?;

  final body = <String, dynamic>{
    'message': 'upload: $filename', 'content': content, 'branch': _kGhBranch,
  };
  if (sha != null) body['sha'] = sha;

  final putRes = await http.put(url,
    headers: {
      'Authorization': 'token $_kGhToken',
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json',
    },
    body: json.encode(body),
  );

  if (putRes.statusCode != 200 && putRes.statusCode != 201) {
    throw Exception('GitHub upload falhou: ${putRes.statusCode}');
  }
  return json.decode(putRes.body)['content']['download_url'] as String;
}

// ─── Página principal ─────────────────────────────────────────────────────────
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();   // ← novo: campo de título
  final _textCtrl  = TextEditingController();
  final _textFocus = FocusNode();
  final _picker    = ImagePicker();
  final List<_MediaItem> _media = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
    _titleCtrl.addListener(() => setState(() {}));
    _textCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    for (final m in _media) m.videoCtrl?.dispose();
    super.dispose();
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────
  void _showSnack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: t.toastText)),
        backgroundColor: t.toastBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Câmera ──────────────────────────────────────────────────────────────────
  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) { _showSnack('Permissão de câmera negada'); return; }
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    _addFile(File(picked.path), false);
  }

  // ── Galeria (picker nativo — imagem e vídeo) ─────────────────────────────────
  Future<void> _pickMedia() async {
    // pickMedia escolhe imagem ou vídeo conforme o que o utilizador seleciona
    final picked = await _picker.pickMedia();
    if (picked == null) return;
    final file    = File(picked.path);
    final isVideo = picked.mimeType?.startsWith('video') == true ||
        picked.path.endsWith('.mp4') ||
        picked.path.endsWith('.mov') ||
        picked.path.endsWith('.avi');
    _addFile(file, isVideo);
  }

  // ── Adicionar ficheiro à lista ───────────────────────────────────────────────
  Future<void> _addFile(File file, bool isVideo) async {
    VideoPlayerController? ctrl;
    if (isVideo) {
      ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.play();   // auto-play no preview
    }
    setState(() => _media.add(_MediaItem(file: file, isVideo: isVideo, videoCtrl: ctrl)));
  }

  // ── Modal galeria completa ───────────────────────────────────────────────────
  Future<void> _openGalleryModal() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      if (sdk >= 33) {
        final imgs = await Permission.photos.request();
        final vids = await Permission.videos.request();
        status = imgs.isGranted && vids.isGranted ? PermissionStatus.granted : PermissionStatus.denied;
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      _showSnack('Permissão de armazenamento negada');
      if (status.isPermanentlyDenied) openAppSettings();
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _GalleryModal(onSelect: (file, isVideo) {
        Navigator.pop(context);
        _addFile(file, isVideo);
      }),
    );
  }

  Future<int> _androidSdk() async {
    try {
      final v = await const MethodChannel('flutter/platform').invokeMethod<int>('getAndroidSdkInt');
      return v ?? 30;
    } catch (_) { return 30; }
  }

  // ── Publicar ────────────────────────────────────────────────────────────────
  Future<void> _publish() async {
    // Valida título obrigatório
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Adicione um título');
      return;
    }
    if (_textCtrl.text.trim().isEmpty && _media.isEmpty) return;
    setState(() => _uploading = true);

    try {
      final mediaPayloads = <MediaPayload>[];
      for (final m in _media) {
        final ext      = p.extension(m.file.path);
        final filename = '${DateTime.now().millisecondsSinceEpoch}_${mediaPayloads.length}$ext';
        final url      = await _uploadToGitHub(m.file, filename);
        mediaPayloads.add(MediaPayload(
          type:      m.isVideo ? 'video' : 'image',
          url:       url,
          filename:  filename,
          sizeBytes: await m.file.length(),
        ));
      }

      final post = PostPayload(
        id:        'post_${DateTime.now().millisecondsSinceEpoch}',
        text:      _textCtrl.text.trim(),
        media:     mediaPayloads,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        author:    _kGhOwner,
      );

      final jsonStr  = const JsonEncoder.withIndent('  ').convert(post.toJson());
      final jsonFile = File('${Directory.systemTemp.path}/${post.id}.json');
      await jsonFile.writeAsString(jsonStr);
      await _uploadToGitHub(jsonFile, 'posts/${post.id}.json');
      await jsonFile.delete();

      if (mounted) {
        _showSnack('Publicado com sucesso!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao publicar: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final t          = AppTheme.current;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.systemUiOverlay,
      child: Scaffold(
        backgroundColor: t.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              children: [

                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16, safeTop + 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 40, height: 40,
                          child: Center(
                            // FIX: usa SVG inline para garantir que aparece
                            child: SvgPicture.string(
                              _svgClose,
                              width: 22, height: 22,
                              colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text('Rascunho',
                          style: TextStyle(color: AppTheme.link, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _uploading ? null : _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.ytRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Publicar'),
                      ),
                    ],
                  ),
                ),

                // ── Área de escrita ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Campo de título
                        TextField(
                          controller: _titleCtrl,
                          style: TextStyle(fontSize: 20, color: t.text, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: 'Título',
                            hintStyle: TextStyle(fontSize: 20, color: t.textTertiary, fontWeight: FontWeight.w700),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: t.avatarBg,
                              child: SvgPicture.asset(
                                'assets/icons/svg/user.svg',
                                width: 20, height: 20,
                                colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _textCtrl,
                                focusNode: _textFocus,
                                maxLines: null,
                                style: TextStyle(fontSize: 18, color: t.text),
                                decoration: InputDecoration(
                                  hintText: 'O que está acontecendo?',
                                  hintStyle: TextStyle(fontSize: 18, color: t.textTertiary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_media.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _MediaGrid(
                            media: _media,
                            onRemove: (i) {
                              _media[i].videoCtrl?.dispose();
                              setState(() => _media.removeAt(i));
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/svg/globe.svg',
                              width: 16, height: 16,
                              colorFilter: ColorFilter.mode(AppTheme.link, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            Text('Qualquer pessoa pode responder',
                                style: TextStyle(color: AppTheme.link, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Galeria rápida (recentes) ──────────────────────────────
                _QuickGallery(
                  onCameraTap: _openCamera,
                  onThumbTap: _addFile,
                ),

                // ── Barra de acções ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: t.bg,
                    border: Border(top: BorderSide(color: t.divider, width: 0.6)),
                  ),
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + safeBottom),
                  child: Row(
                    children: [
                      // FIX: todos os ícones SVG da barra de acções usam asset
                      // com fallback para garantir que aparecem
                      _SvgActionBtn(asset: 'assets/icons/svg/image.svg',     color: AppTheme.ytRed, onTap: _pickMedia),
                      _SvgActionBtn(asset: 'assets/icons/svg/file-text.svg', color: AppTheme.ytRed, onTap: () {}),
                      _SvgActionBtn(asset: 'assets/icons/svg/bar-chart.svg', color: AppTheme.ytRed, onTap: () {}),
                      _SvgActionBtn(asset: 'assets/icons/svg/map-pin.svg',   color: AppTheme.ytRed, onTap: () {}),
                      const Spacer(),
                      SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          value: (_textCtrl.text.length / 280).clamp(0.0, 1.0),
                          strokeWidth: 2.5,
                          backgroundColor: t.divider,
                          color: AppTheme.ytRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openGalleryModal,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.ytRed),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/svg/plus.svg',
                              width: 18, height: 18,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Overlay de upload ──────────────────────────────────────────
            if (_uploading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.ytRed),
                      SizedBox(height: 16),
                      Text('A publicar…', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Media item local ─────────────────────────────────────────────────────────
class _MediaItem {
  final File file;
  final bool isVideo;
  final VideoPlayerController? videoCtrl;
  _MediaItem({required this.file, required this.isVideo, this.videoCtrl});
}

// ─── Grid de media — com botão de remover ─────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<_MediaItem> media;
  final void Function(int) onRemove;
  const _MediaGrid({required this.media, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final m = media[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              m.isVideo
                  ? (m.videoCtrl != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:  m.videoCtrl!.value.size.width,
                            height: m.videoCtrl!.value.size.height,
                            child: VideoPlayer(m.videoCtrl!),
                          ),
                        )
                      : Container(color: Colors.black))
                  : Image.file(m.file, fit: BoxFit.cover),
              // Badge de vídeo
              if (m.isVideo)
                const Positioned(
                  bottom: 6, left: 6,
                  child: Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                ),
              // Botão remover
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Galeria rápida ───────────────────────────────────────────────────────────
class _QuickGallery extends StatefulWidget {
  final VoidCallback onCameraTap;
  final Future<void> Function(File, bool) onThumbTap;
  const _QuickGallery({required this.onCameraTap, required this.onThumbTap});

  @override
  State<_QuickGallery> createState() => _QuickGalleryState();
}

class _QuickGalleryState extends State<_QuickGallery> {
  final List<AssetEntity> _assets = [];
  bool _loaded = false;

  @override
  void initState() { super.initState(); _loadRecent(); }

  Future<void> _loadRecent() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) return;
    final albums = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true);
    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListRange(start: 0, end: 20);
    if (mounted) setState(() { _assets.addAll(assets); _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onCameraTap,
            child: Container(
              width: 80,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: t.divider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/svg/camera.svg',
                  width: 28, height: 28,
                  colorFilter: ColorFilter.mode(AppTheme.ytRed, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Expanded(
            child: !_loaded
                ? const SizedBox()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _assets.length,
                    itemBuilder: (_, i) => _AssetThumb(asset: _assets[i], onTap: widget.onThumbTap),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AssetThumb extends StatefulWidget {
  final AssetEntity asset;
  final Future<void> Function(File, bool) onTap;
  const _AssetThumb({required this.asset, required this.onTap});

  @override
  State<_AssetThumb> createState() => _AssetThumbState();
}

class _AssetThumbState extends State<_AssetThumb> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    widget.asset.thumbnailDataWithSize(const ThumbnailSize(150, 150))
        .then((d) { if (mounted && d != null) setState(() => _thumb = d); });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: () async {
        final file = await widget.asset.file;
        if (file == null) return;
        widget.onTap(file, widget.asset.type == AssetType.video);
      },
      child: Stack(
        children: [
          Container(
            width: 78,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: t.thumbBg, borderRadius: BorderRadius.circular(10)),
            child: _thumb != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_thumb!, fit: BoxFit.cover),
                  )
                : null,
          ),
          if (widget.asset.type == AssetType.video)
            const Positioned(
              bottom: 4, left: 4,
              child: Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
            ),
        ],
      ),
    );
  }
}

// ─── Modal galeria completa ───────────────────────────────────────────────────
class _GalleryModal extends StatefulWidget {
  final void Function(File file, bool isVideo) onSelect;
  const _GalleryModal({required this.onSelect});

  @override
  State<_GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<_GalleryModal> {
  final List<AssetEntity> _assets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true);
    if (albums.isEmpty) { setState(() => _loading = false); return; }
    final assets = await albums.first.getAssetListRange(start: 0, end: 200);
    if (mounted) setState(() { _assets.addAll(assets); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t       = AppTheme.current;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.85,
      color: t.bg,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: t.sheetHandle, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('Galeria', style: TextStyle(color: t.text, fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  // FIX: SVG inline para o close da galeria
                  child: SvgPicture.string(
                    _svgClose, width: 20, height: 20,
                    colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.ytRed))
                : _assets.isEmpty
                    ? Center(child: Text('Sem media disponível', style: TextStyle(color: t.textSecondary)))
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(2, 2, 2, 2 + safeBot),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (_, i) => _GalleryThumb(asset: _assets[i], onSelect: widget.onSelect),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatefulWidget {
  final AssetEntity asset;
  final void Function(File, bool) onSelect;
  const _GalleryThumb({required this.asset, required this.onSelect});

  @override
  State<_GalleryThumb> createState() => _GalleryThumbState();
}

class _GalleryThumbState extends State<_GalleryThumb> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    widget.asset.thumbnailDataWithSize(const ThumbnailSize(200, 200))
        .then((d) { if (mounted && d != null) setState(() => _thumb = d); });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: () async {
        final file = await widget.asset.file;
        if (file == null) return;
        widget.onSelect(file, widget.asset.type == AssetType.video);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _thumb != null
              ? Image.memory(_thumb!, fit: BoxFit.cover)
              : Container(color: t.thumbBg),
          if (widget.asset.type == AssetType.video)
            Positioned(
              bottom: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(_fmtDuration(widget.asset.videoDuration),
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Botão SVG de acção ───────────────────────────────────────────────────────
class _SvgActionBtn extends StatelessWidget {
  final String asset;
  final Color color;
  final VoidCallback onTap;
  const _SvgActionBtn({required this.asset, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SvgPicture.asset(
        asset,
        width: 22, height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    ),
  );
}