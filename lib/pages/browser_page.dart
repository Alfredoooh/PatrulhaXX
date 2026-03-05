import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ionicons/ionicons.dart';
import '../models/site_model.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../widgets/site_icon_widget.dart';

class BrowserPage extends StatefulWidget {
  final SiteModel site;
  final String? initialQuery;

  const BrowserPage({super.key, required this.site, this.initialQuery});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _wvCtrl;
  double _progress = 0;
  bool _loading = true;
  Color _barColor = const Color(0xFF111111);
  bool _colorResolved = false;

  static const _dlChannel = 'DownloadChannel';
  late final String _startUrl;

  @override
  void initState() {
    super.initState();
    _startUrl = widget.site.buildUrl(query: widget.initialQuery);
    _resolveColor();
  }

  Future<void> _resolveColor() async {
    final color = await FaviconService.instance.extractColor(widget.site);
    if (mounted) {
      setState(() {
        _barColor = color;
        _colorResolved = true;
      });
    }
  }

  bool _isAllowed(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      final domain = widget.site.allowedDomain.toLowerCase();
      return host == domain || host.endsWith('.$domain');
    } catch (_) {
      return false;
    }
  }

  // JS que detecta long-press em vídeos/imagens
  // Usamos r'...' (raw string) para evitar conflito com $ do Dart
  static const _mediaJs = r"""
(function() {
  if (window.__pxListening) return;
  window.__pxListening = true;

  function extractMedia(target) {
    if (!target) return null;
    if (target.tagName === 'VIDEO') {
      var src = target.currentSrc || target.src || '';
      if (src) return { type: 'video', src: src, thumb: target.poster || '' };
    }
    if (target.tagName === 'IMG') {
      var src = target.src || '';
      if (src && !src.startsWith('data:')) return { type: 'image', src: src, thumb: src };
    }
    var v = target.closest ? target.closest('video') : null;
    if (v) {
      var src = v.currentSrc || v.src || '';
      if (src) return { type: 'video', src: src, thumb: v.poster || '' };
    }
    var a = target.closest ? target.closest('a') : null;
    if (a && a.href) {
      var href = a.href.toLowerCase();
      if (/\.(mp4|webm|m4v|mov|avi|mkv)(\?|$)/.test(href)) {
        return { type: 'video', src: a.href, thumb: '' };
      }
      if (/\.(jpg|jpeg|png|gif|webp|avif)(\?|$)/.test(href)) {
        return { type: 'image', src: a.href, thumb: a.href };
      }
    }
    return null;
  }

  document.addEventListener('contextmenu', function(e) {
    var data = extractMedia(e.target);
    if (data && data.src) {
      try { window.flutter_inappwebview.callHandler('DownloadChannel', JSON.stringify(data)); } catch(_) {}
      e.preventDefault();
      return false;
    }
  }, true);

  var _timer = null;
  document.addEventListener('touchstart', function(e) {
    var t = e.target;
    _timer = setTimeout(function() {
      var data = extractMedia(t);
      if (data && data.src) {
        try { window.flutter_inappwebview.callHandler('DownloadChannel', JSON.stringify(data)); } catch(_) {}
      }
    }, 600);
  }, { passive: true });

  document.addEventListener('touchend', function() {
    if (_timer) { clearTimeout(_timer); _timer = null; }
  }, { passive: true });
})();
""";

  void _onMediaArgs(List<dynamic> args) {
    if (args.isEmpty) return;
    final raw = args[0].toString();
    try {
      final data = _parseJson(raw);
      if (data == null) return;
      final type = data['type'] as String? ?? 'video';
      final src = data['src'] as String? ?? '';
      if (src.isEmpty) return;
      final thumb = data['thumb'] as String? ?? '';
      _showDownloadSheet(src: src, type: type, thumb: thumb);
    } catch (_) {}
  }

  Map<String, dynamic>? _parseJson(String raw) {
    try {
      final cleaned = raw.trim();
      if (!cleaned.startsWith('{')) return null;
      final result = <String, dynamic>{};
      final inner = cleaned.substring(1, cleaned.length - 1);
      final regex = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
      for (final match in regex.allMatches(inner)) {
        result[match.group(1)!] = match.group(2)!;
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  void _showDownloadSheet({
    required String src,
    required String type,
    required String thumb,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadSheet(src: src, type: type, thumb: thumb, site: widget.site),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _AnimatedAppBar(
        color: _barColor,
        colorResolved: _colorResolved,
        site: widget.site,
        onBack: () async {
          if (_wvCtrl != null && await _wvCtrl!.canGoBack()) {
            _wvCtrl!.goBack();
          } else {
            Navigator.of(context).pop();
          }
        },
        onRefresh: () => _wvCtrl?.reload(),
        progress: _loading ? _progress : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          allowsAirPlayForMediaPlayback: true,
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
          _wvCtrl = ctrl;
          ctrl.addJavaScriptHandler(
            handlerName: _dlChannel,
            callback: _onMediaArgs,
          );
        },
        onLoadStart: (_, url) {
          setState(() {
            _loading = true;
            _progress = 0;
          });
        },
        onLoadStop: (ctrl, _) async {
          setState(() => _loading = false);
          await ctrl.evaluateJavascript(source: _mediaJs);
        },
        onProgressChanged: (_, p) {
          setState(() => _progress = p / 100);
        },
        shouldOverrideUrlLoading: (ctrl, action) async {
          final url = action.request.url?.toString() ?? '';
          if (_isAllowed(url)) return NavigationActionPolicy.ALLOW;
          return NavigationActionPolicy.CANCEL;
        },
        onDownloadStartRequest: (_, req) {
          _showDownloadSheet(
            src: req.url.toString(),
            type: _guessType(req.url.toString()),
            thumb: '',
          );
        },
        onPermissionRequest: (_, req) async {
          return PermissionResponse(
            resources: req.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
      ),
    );
  }

  String _guessType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.m4v') ||
        lower.contains('.mov') ||
        lower.contains('video')) return 'video';
    return 'image';
  }
}

// ── Animated AppBar ───────────────────────────────────────────────────────────
class _AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color color;
  final bool colorResolved;
  final SiteModel site;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final double? progress;

  const _AnimatedAppBar({
    required this.color,
    required this.colorResolved,
    required this.site,
    required this.onBack,
    required this.onRefresh,
    this.progress,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (progress != null ? 3.0 : 0.0));

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: const Color(0xFF111111), end: color),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      builder: (ctx, animColor, _) {
        final bg = animColor ?? const Color(0xFF111111);
        final lum = bg.computeLuminance();
        final fgColor = lum > 0.3 ? Colors.black87 : Colors.white;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 52,
              leading: IconButton(
                icon: Icon(Ionicons.chevron_back_outline, color: fgColor, size: 22),
                onPressed: onBack,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SiteIconWidget(site: site, size: 28, showShadow: false),
                  const SizedBox(width: 10),
                  Text(
                    site.name,
                    style: TextStyle(
                        color: fgColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Ionicons.refresh_outline, color: fgColor, size: 20),
                  onPressed: onRefresh,
                ),
                const SizedBox(width: 4),
              ],
            ),
            if (progress != null)
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor.withOpacity(0.5)),
              ),
          ],
        );
      },
    );
  }
}

// ── Download bottom sheet ─────────────────────────────────────────────────────
class _DownloadSheet extends StatefulWidget {
  final String src;
  final String type;
  final String thumb;
  final SiteModel site;

  const _DownloadSheet({
    required this.src,
    required this.type,
    required this.thumb,
    required this.site,
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
      url: widget.src,
      type: widget.type,
      context: context,
    );

    if (!mounted) return;

    if (item != null) {
      setState(() { _downloading = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _downloading = false; _error = 'Falhou. Tenta novamente.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.type == 'video';
    final icon = isVideo ? Ionicons.videocam_outline : Ionicons.image_outline;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: widget.site.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: widget.site.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Baixar ${isVideo ? 'vídeo' : 'imagem'}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('Guardado apenas neste app',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                widget.src,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10.5,
                    fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            if (_downloading)
              Column(children: [
                LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(widget.site.primaryColor),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
                const SizedBox(height: 10),
                Text('A baixar...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ])
            else if (_done)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Ionicons.checkmark_circle,
                    color: Colors.greenAccent.shade400, size: 20),
                const SizedBox(width: 8),
                const Text('Guardado!',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
              ])
            else
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('Cancelar',
                              style: TextStyle(color: Colors.white60,
                                  fontWeight: FontWeight.w500))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _doDownload,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          color: widget.site.primaryColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Ionicons.download_outline,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Baixar ${isVideo ? 'vídeo' : 'imagem'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
