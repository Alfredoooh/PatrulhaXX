import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  File? _mediaFile;
  bool  _isVideo = false;
  bool  _showDesc = false;

  final _descController = TextEditingController();
  final _descFocus      = FocusNode();

  // rich text formatting state
  bool _bold      = false;
  bool _italic    = false;
  bool _underline = false;
  bool _strike    = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    // bottom sheet para escolher imagem ou vídeo
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(),
    );
    if (choice == null) return;

    XFile? picked;
    if (choice == 'image') {
      picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    } else {
      picked = await _picker.pickVideo(source: ImageSource.gallery);
    }
    if (picked == null) return;
    setState(() {
      _mediaFile = File(picked!.path);
      _isVideo   = choice == 'video';
    });
  }

  void _toggleDesc() {
    setState(() => _showDesc = !_showDesc);
    if (_showDesc) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _descFocus.requestFocus();
      });
    }
  }

  void _post() {
    // TODO: implementar lógica de publicação
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t          = AppTheme.current;
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

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
            SizedBox(
              height: safeTop + 52,
              child: Padding(
                padding: EdgeInsets.only(top: safeTop, left: 8, right: 8),
                child: Row(
                  children: [
                    _IconBtn(
                      icon: Icons.close,
                      color: t.icon,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: Icons.access_time_rounded,
                      color: t.icon,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── media area ────────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // fundo preto
                  Container(color: Colors.black),

                  // placeholder upload
                  if (_mediaFile == null)
                    Center(
                      child: GestureDetector(
                        onTap: _pickMedia,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_rounded,
                                size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 10),
                            Text('Carregar ficheiro',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),

                  // preview media — edge-to-edge
                  if (_mediaFile != null && !_isVideo)
                    Positioned.fill(
                      child: Image.file(
                        _mediaFile!,
                        fit: BoxFit.cover,
                      ),
                    ),

                  if (_mediaFile != null && _isVideo)
                    Positioned.fill(
                      child: _VideoPreview(file: _mediaFile!),
                    ),

                  // FABs — direita, centro vertical
                  if (_mediaFile != null)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _FabRow(
                              label: 'Editar',
                              child: const Icon(Icons.edit_rounded,
                                  size: 20, color: Colors.white),
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),
                            _FabRow(
                              label: 'Descrição',
                              child: const Text('Aa',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1)),
                              onTap: _toggleDesc,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── description editor ────────────────────────────────────────
            if (_showDesc)
              Container(
                decoration: BoxDecoration(
                  color: t.bg,
                  border: Border(
                    top: BorderSide(color: t.divider, width: 0.6),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // formatting toolbar
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: t.bg,
                        border: Border(
                          bottom: BorderSide(color: t.divider, width: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          _FmtBtn(
                            label: 'B',
                            bold: true,
                            active: _bold,
                            onTap: () => setState(() => _bold = !_bold),
                          ),
                          _FmtBtn(
                            label: 'I',
                            italic: true,
                            active: _italic,
                            onTap: () => setState(() => _italic = !_italic),
                          ),
                          _FmtBtn(
                            label: 'U',
                            underline: true,
                            active: _underline,
                            onTap: () => setState(() => _underline = !_underline),
                          ),
                          _FmtBtn(
                            label: 'S',
                            lineThrough: true,
                            active: _strike,
                            onTap: () => setState(() => _strike = !_strike),
                          ),
                        ],
                      ),
                    ),
                    // text field
                    TextField(
                      controller: _descController,
                      focusNode: _descFocus,
                      maxLines: 4,
                      minLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.text,
                        fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                        fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
                        decoration: _underline && _strike
                            ? TextDecoration.combine([
                                TextDecoration.underline,
                                TextDecoration.lineThrough
                              ])
                            : _underline
                                ? TextDecoration.underline
                                : _strike
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escreve uma descrição...',
                        hintStyle: TextStyle(
                            color: t.textTertiary, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

            // ── post button ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + safeBottom),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _post,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Postar',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.text,
                    foregroundColor: t.bg,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _PickerSheet
// ─────────────────────────────────────────────────────────────────────────────
class _PickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: t.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.image_rounded,
            label: 'Imagem',
            onTap: () => Navigator.pop(context, 'image'),
          ),
          const SizedBox(height: 8),
          _SheetOption(
            icon: Icons.videocam_rounded,
            label: 'Vídeo',
            onTap: () => Navigator.pop(context, 'video'),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: t.thumbBg,
      leading: Icon(icon, color: t.icon),
      title: Text(label,
          style: TextStyle(
              color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _VideoPreview  (controller simples sem package extra)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoPreview extends StatelessWidget {
  final File file;
  const _VideoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    // Mostra o thumbnail do ficheiro; player completo requer video_player package
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_fill_rounded,
            size: 64, color: Colors.white.withOpacity(0.8)),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40, height: 44,
        child: Center(child: Icon(icon, color: color, size: 22)),
      ),
    );
  }
}

class _FabRow extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _FabRow({required this.label, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
          const SizedBox(width: 8),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.35),
              border: Border.all(
                  color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _FmtBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool bold, italic, underline, lineThrough;
  final VoidCallback onTap;

  const _FmtBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.lineThrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE0E7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: active ? const Color(0xFF4338CA) : t.text,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              decoration: underline
                  ? TextDecoration.underline
                  : lineThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
              decorationColor: active ? const Color(0xFF4338CA) : t.text,
            ),
          ),
        ),
      ),
    );
  }
}
