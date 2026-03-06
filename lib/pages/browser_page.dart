import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/site_model.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../widgets/site_icon_widget.dart';

// ── SVG icons for popup menu ──────────────────────────────────────────────────
const _svgHome = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M22.657,7.419L14.157,.768c-1.271-.994-3.043-.992-4.314,0L1.342,7.42c-.853,.669-1.342,1.674-1.342,2.756v13.824H24V10.176c0-1.082-.489-2.087-1.343-2.757Zm-1.657,13.581H3V10.176c0-.154,.07-.299,.192-.394L11.692,3.131c.182-.143,.436-.143,.615,0l8.499,6.65c.123,.096,.193,.24,.193,.395v10.824Z"/></svg>''';

const _svgBack = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M7.7,15.007a1.5,1.5,0,0,1-2.121,0L.858,10.282a2.932,2.932,0,0,1,0-4.145L5.583,1.412A1.5,1.5,0,0,1,7.7,3.533L4.467,6.7l14.213,0A5.325,5.325,0,0,1,24,12.019V18.7a5.323,5.323,0,0,1-5.318,5.318H5.318a1.5,1.5,0,1,1,0-3H18.681A2.321,2.321,0,0,0,21,18.7V12.019A2.321,2.321,0,0,0,18.68,9.7L4.522,9.7,7.7,12.886A1.5,1.5,0,0,1,7.7,15.007Z"/></svg>''';

const _svgForward = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M16.3,15.007a1.5,1.5,0,0,0,2.121,0l4.726-4.725a2.934,2.934,0,0,0,0-4.145L18.416,1.412A1.5,1.5,0,1,0,16.3,3.533L19.532,6.7,5.319,6.7A5.326,5.326,0,0,0,0,12.019V18.7a5.324,5.324,0,0,0,5.318,5.318H18.682a1.5,1.5,0,0,0,0-3H5.318A2.321,2.321,0,0,1,3,18.7V12.019A2.321,2.321,0,0,1,5.319,9.7l14.159,0L16.3,12.886A1.5,1.5,0,0,0,16.3,15.007Z"/></svg>''';

const _svgReload = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,0A12.013,12.013,0,0,0,2.513,4.513L0,2V9H7L4.343,6.343A9,9,0,1,1,3,12H0A12,12,0,1,0,12,0Z"/></svg>';

class BrowserPage extends StatefulWidget {
  final SiteModel site;
  final String? initialQuery;
  final bool freeNavigation;

  const BrowserPage({
    super.key,
    required this.site,
    this.initialQuery,
    this.freeNavigation = false,
  });

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _ctrl;
  double _progress = 0;
  bool _loading = true;
  bool _dialogOpen = false;
  Color _barColor = const Color(0xFF1E1E1E);

  static const _mediaJs = r"""
(function() {
  if (window.__pxInit) return;
  window.__pxInit = true;
  var _guard = false;

  function emit(data) {
    if (_guard) return;
    _guard = true;
    setTimeout(function() { _guard = false; }, 3000);
    try { window.flutter_inappwebview.callHandler('DL', JSON.stringify(data)); } catch(e) {}
  }

  function videoSrc(v) {
    var src = v.currentSrc || v.src || '';
    if (!src) {
      var ss = v.querySelectorAll('source');
      for (var i = 0; i < ss.length; i++) { if (ss[i].src) { src = ss[i].src; break; } }
    }
    return src || v.getAttribute('data-src') || v.getAttribute('data-url') || '';
  }

  function attachVideo(v) {
    if (v.__px) return; v.__px = true;
    var t = null;
    v.addEventListener('touchstart', function() {
      t = setTimeout(function() {
        var s = videoSrc(v);
        if (s && s.startsWith('http')) emit({ type:'video', src:s, thumb: v.poster||'' });
      }, 1200);
    }, { passive:true });
    v.addEventListener('touchend',   function() { clearTimeout(t); }, { passive:true });
    v.addEventListener('touchcancel',function() { clearTimeout(t); }, { passive:true });
    v.addEventListener('play', function() {
      var s = videoSrc(v);
      if (s && s.startsWith('http')) window.__lastV = { src:s, thumb: v.poster||'' };
    });
  }

  function attachImg(img) {
    if (img.__px) return; img.__px = true;
    var t = null;
    img.addEventListener('touchstart', function() {
      t = setTimeout(function() {
        var s = img.currentSrc || img.src || '';
        if (s && s.startsWith('http') && !s.startsWith('data:') && s.length > 20)
          emit({ type:'image', src:s, thumb:s });
      }, 1500);
    }, { passive:true });
    img.addEventListener('touchend',   function() { clearTimeout(t); }, { passive:true });
    img.addEventListener('touchcancel',function() { clearTimeout(t); }, { passive:true });
  }

  function scan() {
    document.querySelectorAll('video').forEach(attachVideo);
    document.querySelectorAll('img').forEach(attachImg);
  }
  scan();

  new MutationObserver(function(ms) {
    ms.forEach(function(m) {
      m.addedNodes.forEach(function(n) {
        if (!n.tagName) return;
        if (n.tagName === 'VIDEO') attachVideo(n);
        else if (n.tagName === 'IMG') attachImg(n);
        if (n.querySelectorAll) {
          n.querySelectorAll('video').forEach(attachVideo);
          n.querySelectorAll('img').forEach(attachImg);
        }
      });
    });
  }).observe(document.documentElement, { childList:true, subtree:true });

  document.addEventListener('contextmenu', function(e) {
    var t = e.target;
    if (t.tagName === 'VIDEO' || (t.closest && t.closest('video'))) {
      var v = t.tagName === 'VIDEO' ? t : t.closest('video');
      var s = videoSrc(v);
      if (s) { emit({ type:'video', src:s, thumb: v.poster||'' }); e.preventDefault(); }
    } else if (t.tagName === 'IMG') {
      var s = t.src || '';
      if (s && s.startsWith('http')) { emit({ type:'image', src:s, thumb:s }); e.preventDefault(); }
    }
  }, false);
})();
""";

  @override
  void initState() {
    super.initState();
    if (!widget.freeNavigation) _resolveColor();
  }

  Future<void> _resolveColor() async {
    final c = await FaviconService.instance.extractColor(widget.site);
    if (!mounted) return;
    final hsl = HSLColor.fromColor(c);
    final clamped = hsl
        .withLightness(hsl.lightness.clamp(0.12, 0.28))
        .withSaturation(hsl.saturation.clamp(0.0, 0.7));
    setState(() => _barColor = clamped.toColor());
  }

  bool _isAllowed(String url) {
    if (widget.freeNavigation || widget.site.allowedDomain.isEmpty) return true;
    try {
      final host = Uri.parse(url).host.toLowerCase();
      final domain = widget.site.allowedDomain.toLowerCase();
      return host == domain || host.endsWith('.$domain');
    } catch (_) {
      return false;
    }
  }

  void _onDlArgs(List<dynamic> args) {
    if (_dialogOpen || args.isEmpty) return;
    try {
      final data = _parseJson(args[0].toString());
      if (data == null) return;
      final src = data['src'] as String? ?? '';
      if (src.isEmpty) return;
      _showDownload(
        src: src,
        type: data['type'] as String? ?? 'video',
        thumb: data['thumb'] as String? ?? '',
      );
    } catch (_) {}
  }

  Map<String, dynamic>? _parseJson(String raw) {
    try {
      final result = <String, dynamic>{};
      final regex = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
      for (final m in regex.allMatches(raw)) {
        result[m.group(1)!] = m.group(2)!;
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  void _showDownload({required String src, required String type, required String thumb}) {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadSheet(src: src, type: type, thumb: thumb, site: widget.site),
    ).whenComplete(() {
      if (mounted) setState(() => _dialogOpen = false);
    });
  }

  String _guessType(String url) {
    final l = url.toLowerCase();
    if (l.contains('.mp4') || l.contains('.webm') || l.contains('.m4v') ||
        l.contains('.mov') || l.contains('.m3u8') || l.contains('video')) return 'video';
    return 'image';
  }

  void _handleMenu(_MenuAction action) async {
    switch (action) {
      case _MenuAction.back:
        if (_ctrl != null && await _ctrl!.canGoBack()) _ctrl!.goBack();
        break;
      case _MenuAction.forward:
        if (_ctrl != null && await _ctrl!.canGoForward()) _ctrl!.goForward();
        break;
      case _MenuAction.reload:
        _ctrl?.reload();
        break;
      case _MenuAction.mainPage:
        _ctrl?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.site.baseUrl)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _ProgressAppBar(
        barColor: _barColor,
        progress: _loading ? _progress : 1.0,
        isLoading: _loading,
        site: widget.site,
        onBack: () => Navigator.of(context).pop(),
        onMenu: _handleMenu,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.site.buildUrl(query: widget.initialQuery)),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useOnDownloadStart: true,
          useShouldOverrideUrlLoading: true,
          supportZoom: true,
          builtInZoomControls: false,
          displayZoomControls: false,
          cacheEnabled: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        ),
        onWebViewCreated: (ctrl) {
          _ctrl = ctrl;
          ctrl.addJavaScriptHandler(handlerName: 'DL', callback: _onDlArgs);
        },
        onLoadStart: (_, __) => setState(() { _loading = true; _progress = 0; }),
        onLoadStop: (ctrl, _) async {
          setState(() => _loading = false);
          await ctrl.evaluateJavascript(source: _mediaJs);
        },
        onProgressChanged: (_, p) => setState(() => _progress = p / 100),
        shouldOverrideUrlLoading: (ctrl, action) async {
          final url = action.request.url?.toString() ?? '';
          final lower = url.toLowerCase();
          final isMediaLink = lower.contains('.mp4') || lower.contains('.webm') ||
              lower.contains('.m4v') || lower.contains('.m3u8');
          if (isMediaLink && !_dialogOpen) {
            _showDownload(src: url, type: 'video', thumb: '');
            return NavigationActionPolicy.CANCEL;
          }
          if (!_isAllowed(url)) return NavigationActionPolicy.CANCEL;
          return NavigationActionPolicy.ALLOW;
        },
        onDownloadStartRequest: (_, req) {
          if (!_dialogOpen) {
            _showDownload(
              src: req.url.toString(),
              type: _guessType(req.url.toString()),
              thumb: '',
            );
          }
        },
        onPermissionRequest: (_, req) async => PermissionResponse(
          resources: req.resources,
          action: PermissionResponseAction.GRANT,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar that IS the progress bar
// ─────────────────────────────────────────────────────────────────────────────
enum _MenuAction { back, forward, reload, mainPage }

class _ProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color barColor;
  final double progress;
  final bool isLoading;
  final SiteModel site;
  final VoidCallback onBack;
  final ValueChanged<_MenuAction> onMenu;

  const _ProgressAppBar({
    required this.barColor,
    required this.progress,
    required this.isLoading,
    required this.site,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: const Color(0xFF1E1E1E), end: barColor),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      builder: (ctx, animColor, _) {
        final bg = animColor ?? const Color(0xFF1E1E1E);

        return Stack(
          children: [
            // ── Base AppBar ───────────────────────────────────────────────
            AppBar(
              backgroundColor: bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 52,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
                onPressed: onBack,
              ),
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                SiteIconWidget(site: site, size: 26, showShadow: false),
                const SizedBox(width: 10),
                Text(site.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ]),
              actions: [
                _MenuButton(bg: bg, onAction: onMenu),
                const SizedBox(width: 8),
              ],
            ),

            // ── Progress fill — slides from left to right at bottom ───────
            if (isLoading)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                left: 0,
                bottom: 0,
                width: screenW * progress,
                height: 2.5,
                child: AnimatedOpacity(
                  opacity: isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popup menu button (3-dot in circle)
// ─────────────────────────────────────────────────────────────────────────────
class _MenuButton extends StatefulWidget {
  final Color bg;
  final ValueChanged<_MenuAction> onAction;

  const _MenuButton({required this.bg, required this.onAction});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  OverlayEntry? _overlay;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0, upperBound: 1,
    );
  }

  @override
  void dispose() {
    _closeMenu();
    _scale.dispose();
    super.dispose();
  }

  void _toggle(BuildContext context) {
    _open ? _closeMenu() : _openMenu(context);
  }

  void _openMenu(BuildContext context) {
    final RenderBox btn = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = btn.localToGlobal(Offset.zero, ancestor: overlay);
    final size = btn.size;

    _overlay = OverlayEntry(
      builder: (_) => _PopupMenu(
        anchorRight: overlay.size.width - pos.dx - size.width,
        anchorTop: pos.dy + size.height + 6,
        onAction: (a) { _closeMenu(); widget.onAction(a); },
        onDismiss: _closeMenu,
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _closeMenu() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.forward(),
      onTapUp: (_) { _scale.reverse(); _toggle(context); },
      onTapCancel: () => _scale.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _scale.value * 0.12, child: child),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Center(
            child: Icon(
              _open ? Icons.close_rounded : Icons.more_horiz_rounded,
              color: Colors.white, size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated popup overlay
// ─────────────────────────────────────────────────────────────────────────────
class _PopupMenu extends StatefulWidget {
  final double anchorRight;
  final double anchorTop;
  final ValueChanged<_MenuAction> onAction;
  final VoidCallback onDismiss;

  const _PopupMenu({
    required this.anchorRight, required this.anchorTop,
    required this.onAction, required this.onDismiss,
  });

  @override
  State<_PopupMenu> createState() => _PopupMenuState();
}

class _PopupMenuState extends State<_PopupMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _opacity =
        CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _slide =
        Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  static const _items = [
    (_MenuAction.back,     _svgBack,    'Anterior'),
    (_MenuAction.forward,  _svgForward, 'Próxima'),
    (_MenuAction.reload,   _svgReload,  'Recarregar'),
    (_MenuAction.mainPage, _svgHome,    'Página principal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // dismiss layer
      Positioned.fill(
        child: GestureDetector(
          onTap: widget.onDismiss,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
      // card
      Positioned(
        right: widget.anchorRight,
        top: widget.anchorTop,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 210,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _items.asMap().entries.map((e) {
                        final idx = e.key;
                        final (action, svg, label) = e.value;
                        return Column(mainAxisSize: MainAxisSize.min, children: [
                          if (idx > 0)
                            Divider(height: 1,
                                color: Colors.white.withOpacity(0.06),
                                indent: 16, endIndent: 16),
                          _MenuItem(svg: svg, label: label,
                              onTap: () => widget.onAction(action)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MenuItem extends StatefulWidget {
  final String svg;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.svg, required this.label, required this.onTap});

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? Colors.white.withOpacity(0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          SvgPicture.string(widget.svg, width: 18, height: 18,
              colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
          const SizedBox(width: 14),
          Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _DownloadSheet extends StatefulWidget {
  final String src;
  final String type;
  final String thumb;
  final SiteModel site;

  const _DownloadSheet({
    required this.src, required this.type,
    required this.thumb, required this.site,
  });

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  bool _downloading = false;
  bool _done = false;
  String? _error;

  Future<void> _doDownload() async {
    setState(() { _downloading = true; _error = null; });
    final item = await DownloadService.instance.download(
        url: widget.src, type: widget.type, context: context);
    if (!mounted) return;
    if (item != null) {
      setState(() { _downloading = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _downloading = false; _error = 'Falhou. Tenta novamente.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.type == 'video';
    final hasThumb = widget.thumb.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Thumbnail preview
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasThumb
                ? CachedNetworkImage(
                    imageUrl: widget.thumb,
                    height: 160, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 100,
                        color: Colors.white.withOpacity(0.04)),
                    errorWidget: (_, __, ___) => _placeholder(isVideo),
                  )
                : _placeholder(isVideo),
          ),

          const SizedBox(height: 16),

          Row(children: [
            Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Baixar ${isVideo ? 'vídeo' : 'imagem'}',
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600))),
            Text('Privado', style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ]),

          const SizedBox(height: 16),

          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13))),

          if (_downloading)
            Column(children: [
              LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                borderRadius: BorderRadius.circular(6), minHeight: 5),
              const SizedBox(height: 10),
              Text('A baixar...', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ])
          else if (_done)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent.shade400, size: 22),
              const SizedBox(width: 8),
              const Text('Guardado!',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
            ])
          else
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24)),
                  child: const Center(child: Text('Cancelar',
                      style: TextStyle(color: Colors.white60,
                          fontWeight: FontWeight.w500)))),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: GestureDetector(
                onTap: _doDownload,
                child: Container(height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.download_rounded,
                        color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Text('Baixar ${isVideo ? 'vídeo' : 'imagem'}',
                        style: const TextStyle(color: Colors.black87,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              )),
            ]),
        ]),
      ),
    );
  }

  Widget _placeholder(bool isVideo) => Container(
    height: 90, width: double.infinity,
    color: Colors.white.withOpacity(0.04),
    child: Center(child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white24, size: 36)),
  );
}
