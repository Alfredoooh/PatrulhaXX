import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _textCtrl  = TextEditingController();
  final _textFocus = FocusNode();
  final _picker    = ImagePicker();

  final List<_MediaItem> _media = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _textFocus.dispose();
    for (final m in _media) m.videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picked = await _picker.pickMedia();
    if (picked == null) return;
    final file    = File(picked.path);
    final isVideo = picked.mimeType?.startsWith('video') == true ||
        picked.path.endsWith('.mp4') ||
        picked.path.endsWith('.mov') ||
        picked.path.endsWith('.avi');

    VideoPlayerController? ctrl;
    if (isVideo) {
      ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      ctrl.setLooping(true);
    }

    setState(() => _media.add(_MediaItem(file: file, isVideo: isVideo, videoCtrl: ctrl)));
  }

  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final t          = AppTheme.current;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [

            // ── top bar ───────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, safeTop + 8, 16, 8),
              child: Row(
                children: [
                  // X
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(Icons.close, size: 22),
                  ),
                  const Spacer(),
                  // Rascunho
                  Text('Rascunho',
                      style: TextStyle(
                        color: const Color(0xFF1D9BF0),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 12),
                  // Publicar
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9BF0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Publicar'),
                  ),
                ],
              ),
            ),

            // ── área de escrita ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // avatar + campo de texto
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // avatar placeholder
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: t.thumbBg,
                          child: Icon(Icons.person_outline,
                              size: 20, color: t.iconSub),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            focusNode: _textFocus,
                            maxLines: null,
                            style: TextStyle(
                                fontSize: 18, color: t.text),
                            decoration: InputDecoration(
                              hintText: 'O que está acontecendo?',
                              hintStyle: TextStyle(
                                  fontSize: 18,
                                  color: t.textTertiary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // grid de media seleccionada
                    if (_media.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MediaGrid(media: _media),
                    ],

                    const SizedBox(height: 16),

                    // "Qualquer pessoa pode responder"
                    Row(
                      children: [
                        Icon(Icons.public,
                            size: 16,
                            color: const Color(0xFF1D9BF0)),
                        const SizedBox(width: 6),
                        Text('Qualquer pessoa pode responder',
                            style: TextStyle(
                              color: const Color(0xFF1D9BF0),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── galeria rápida ────────────────────────────────────────────
            _QuickGallery(onPick: _pickMedia),

            // ── barra de acções em baixo ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: t.bg,
                border: Border(top: BorderSide(color: t.divider, width: 0.6)),
              ),
              padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + safeBottom),
              child: Row(
                children: [
                  _ActionBtn(icon: Icons.image_outlined,
                      color: const Color(0xFF1D9BF0),
                      onTap: _pickMedia),
                  _ActionBtn(icon: Icons.gif_box_outlined,
                      color: const Color(0xFF1D9BF0),
                      onTap: () {}),
                  _ActionBtn(icon: Icons.bar_chart_outlined,
                      color: const Color(0xFF1D9BF0),
                      onTap: () {}),
                  _ActionBtn(icon: Icons.location_on_outlined,
                      color: const Color(0xFF1D9BF0),
                      onTap: () {}),
                  const Spacer(),
                  // círculo progresso (placeholder)
                  SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                      value: (_textCtrl.text.length / 280).clamp(0.0, 1.0),
                      strokeWidth: 2.5,
                      backgroundColor: t.divider,
                      color: const Color(0xFF1D9BF0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // botão +
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1D9BF0),
                    ),
                    child: const Icon(Icons.add,
                        size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}


// ── item de media ─────────────────────────────────────────────────────────────
class _MediaItem {
  final File file;
  final bool isVideo;
  final VideoPlayerController? videoCtrl;
  _MediaItem({required this.file, required this.isVideo, this.videoCtrl});
}


// ── grid de media seleccionada ────────────────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<_MediaItem> media;
  const _MediaGrid({required this.media});

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
          child: m.isVideo
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
        );
      },
    );
  }
}


// ── galeria rápida (thumbnails da galeria) ────────────────────────────────────
class _QuickGallery extends StatelessWidget {
  final VoidCallback onPick;
  const _QuickGallery({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // botão câmara
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 80,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: t.divider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.camera_alt_outlined,
                  size: 28,
                  color: const Color(0xFF1D9BF0)),
            ),
          ),
          // espaço para thumbnails reais (requer photo_manager)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: 6,
              itemBuilder: (_, i) => Container(
                width: 78,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: t.thumbBg,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── botão de acção (barra de baixo) ──────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}
