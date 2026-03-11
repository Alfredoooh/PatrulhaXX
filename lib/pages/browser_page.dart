import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/site_model.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../widgets/site_icon_widget.dart';

// SVG X — o que foi fornecido
const _svgClose =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512.021 512.021">'
    '<path d="M301.258,256.01L502.645,54.645c12.501-12.501,12.501-32.769,0-45.269'
    'c-12.501-12.501-32.769-12.501-45.269,0L256.01,210.762L54.645,9.376'
    'c-12.501-12.501-32.769-12.501-45.269,0s-12.501,32.769,0,45.269L210.762,256.01'
    'L9.376,457.376c-12.501,12.501-12.501,32.769,0,45.269s32.769,12.501,45.269,0'
    'L256.01,301.258l201.365,201.387c12.501,12.501,32.769,12.501,45.269,0'
    'c12.501-12.501,12.501-32.769,0-45.269L301.258,256.01z"/>'
    '</svg>';

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
  InAppWebViewController? _wvCtrl;
  double _progress = 0;
  bool _loading = true;
  bool _dialogOpen = false;
  String _pageTitle = '';

  late final String _startUrl;

  // JS que detecta long-press em vídeos e imagens (raw string — sem conflito $)
  static const _mediaJs = r"""
(function() {
  if (window.__pxInit) return;
  window.__pxInit = true;

  var _dlShown = false;

  function send(data) {
    if (_dlShown) return;
    _dlShown = true;
    setTimeout(function() { _dlShown = false; }, 3000);
    try {
      window.flutter_inappwebview.callHandler('DownloadChannel', JSON.stringify(data));
    } catch(e) {}
  }

  function getVideoSrc(v) {
    var src = v.currentSrc || v.src || '';
    if (!src) {
      var ss = v.querySelectorAll('source');
      for (var i = 0; i < ss.length; i++) {
        if (ss[i].src) { src = ss[i].src; break; }
      }
    }
    if (!src) src = v.getAttribute('data-src') || v.getAttribute('data-url') || '';
    return src;
  }

  function attachVideo(v) {
    if (v.__pxDone) return;
    v.__pxDone = true;
    var timer = null;
    function go() {
      var src = getVideoSrc(v);
      if (src && src.startsWith('http')) {
        send({ type: 'video', src: src, thumb: v.poster || '' });
      }
    }
    v.addEventListener('touchstart', function() {
      timer = setTimeout(go, 1200);
    }, { passive: true });
    v.addEventListener('touchend', function() { if(timer) clearTimeout(timer); }, { passive:true });
    v.addEventListener('touchcancel', function() { if(timer) clearTimeout(timer); }, { passive:true });
    v.addEventListener('play', function() {
      var src = getVideoSrc(v);
      if (src && src.startsWith('http')) {
        window.__lastVideoSrc = { src: src, thumb: v.poster || '' };
      }
    });
  }

  function attachImg(img) {
    if (img.__pxDone) return;
    img.__pxDone = true;
    var timer = null;
    img.addEventListener('touchstart', function() {
      timer = setTimeout(function() {
        var src = img.currentSrc || img.src || '';
        if (src && !src.startsWith('data:') && src.indexOf('http') === 0 && src.length > 20) {
          send({ type: 'image', src: src, thumb: src });
        }
      }, 1500);
    }, { passive: true });
    img.addEventListener('touchend', function() { if(timer) clearTimeout(timer); }, { passive:true });
    img.addEventListener('touchcancel', function() { if(timer) clearTimeout(timer); }, { passive:true });
  }

  function scanAll() {
    document.querySelectorAll('video').forEach(attachVideo);
    document.querySelectorAll('img').forEach(attachImg);
  }

  scanAll();

  var obs = new MutationObserver(function(muts) {
    muts.forEach(function(m) {
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
  });

  obs.observe(document.documentElement, { childList: true, subtree: true });

  document.addEventListener('contextmenu', function(e) {
    var t = e.target;
    if (!t) return;
    if (t.tagName === 'VIDEO' || t.closest('video')) {
      var v = t.tagName === 'VIDEO' ? t : t.closest('video');
      var src = getVideoSrc(v);
      if (src) { send({ type:'video', src:src, thumb: v ? v.poster||'' : '' }); e.preventDefault(); }
    } else if (t.tagName === 'IMG') {
      var src = t.src || '';
      if (src && src.startsWith('http')) { send({ type:'image', src:src, thumb:src }); e.preventDefault(); }
    }
  }, false);
})();
""";

  @override
  void initState() {
    super.initState();
    _startUrl = widget.site.buildUrl(query: widget.initialQuery);
    _pageTitle = widget.site.name;
  }

  bool _isAllowed(String url) {
    if (widget.freeNavigation || widget.site.allowedDomain.isEmpty) return true;
    try {
      final host = Uri.parse(url).host.toLowerCase();
      final domain = widget.site.allowedDomain.toLowerCase();
      return host == domain || host.endsWith('.$domain');
    } catch (_) { return false; }
  }

  void _handleMediaArgs(List<dynamic> args) {
    if (_dialogOpen || args.isEmpty) return;
    final raw = args[0].toString();
    try {
      final data = _parseJson(raw);
      if (data == null) return;
      final type = data['type'] as String? ?? 'video';
      final src = data['src'] as String? ?? '';
      if (src.isEmpty) return;
      final thumb = data['thumb'] as String? ?? '';
      _showDownload(src: src, type: type, thumb: thumb);
    } catch (_) {}
  }

  Map<String, dynamic>? _parseJson(String raw) {
    try {
      final cleaned = raw.trim();
      if (!cleaned.startsWith('{')) return null;
      final result = <String, dynamic>{};
      final regex = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
      for (final m in regex.allMatches(cleaned)) {
        result[m.group(1)!] = m.group(2)!;
      }
      return result.isEmpty ? null : result;
    } catch (_) { return null; }
  }

  void _showDownload({required String src, required String type, required String thumb}) {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadSheet(src: src, type: type, thumb: thumb, site: widget.site),
    ).whenComplete(() => setState(() => _dialogOpen = false));
  }

  String _guessType(String url) {
    final l = url.toLowerCase();
    if (l.contains('.mp4') || l.contains('.webm') || l.contains('.m4v') ||
        l.contains('.mov') || l.contains('video') || l.contains('.m3u8')) return 'video';
    return 'image';
  }

  // AppBar sempre escuro — Android style
  Color get _appBarColor => const Color(0xFF111111);
  bool get _appBarIsLight => false;
  Color get _fg => Colors.white;

  // Label: máximo 16 chars para caber bem por baixo do ícone
  String get _shortLabel {
    final t = _pageTitle.isNotEmpty ? _pageTitle : widget.site.name;
    // Remove domínio e caracteres desnecessários
    final clean = t
        .replaceAll(RegExp(r'\s*[|\-–—]\s*.*'), '') // remove " | Subtitle"
        .trim();
    return clean.length > 16 ? '${clean.substring(0, 16)}…' : clean;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return PopScope(
      // Botão back do Android → navega no WebView, NUNCA fecha
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_wvCtrl != null && await _wvCtrl!.canGoBack()) {
          _wvCtrl!.goBack();
        }
        // Sem Navigator.pop — só o X fecha
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              _appBarIsLight ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Column(children: [

            // ── AppBar: cor do site, favicon centrado + label em baixo ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              color: _appBarColor,
              padding: EdgeInsets.only(top: topPad),
              child: SizedBox(
                height: 62,
                child: Stack(alignment: Alignment.center, children: [

                  // Centro: favicon + label em baixo
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SiteIconWidget(
                        site: widget.site,
                        size: 24,
                        showShadow: false,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _shortLabel,
                        style: TextStyle(
                          color: _fg.withOpacity(0.88),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Esquerda: botão X — fecha o WebView
                  Positioned(
                    left: 4,
                    child: IconButton(
                      icon: SvgPicture.string(
                        _svgClose,
                        width: 15, height: 15,
                        colorFilter: ColorFilter.mode(
                            _fg.withOpacity(0.82), BlendMode.srcIn),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 22,
                    ),
                  ),

                  // Direita: refresh
                  Positioned(
                    right: 4,
                    child: IconButton(
                      icon: Icon(Icons.refresh_rounded,
                          color: _fg.withOpacity(0.75), size: 20),
                      onPressed: () => _wvCtrl?.reload(),
                      splashRadius: 22,
                    ),
                  ),
                ]),
              ),
            ),

            // ── Barra de progresso ──────────────────────────────────────
            if (_loading)
              LinearProgressIndicator(
                value: _progress,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                    widget.site.primaryColor.withOpacity(0.9)),
              )
            else
              const SizedBox(height: 2.5),

            // ── WebView ─────────────────────────────────────────────────
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
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
                      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                ),
                onWebViewCreated: (ctrl) {
                  _wvCtrl = ctrl;
                  ctrl.addJavaScriptHandler(
                    handlerName: 'DownloadChannel',
                    callback: _handleMediaArgs,
                  );
                },
                onTitleChanged: (_, title) {
                  if (mounted && title != null && title.isNotEmpty) {
                    setState(() => _pageTitle = title);
                  }
                },
                onLoadStart: (_, url) =>
                    setState(() { _loading = true; _progress = 0; }),
                onLoadStop: (ctrl, _) async {
                  setState(() => _loading = false);
                  await ctrl.evaluateJavascript(source: _mediaJs);
                },
                onProgressChanged: (_, p) =>
                    setState(() => _progress = p / 100),
                shouldOverrideUrlLoading: (ctrl, action) async {
                  final url = action.request.url?.toString() ?? '';
                  final lower = url.toLowerCase();
                  final isMedia = lower.contains('.mp4') ||
                      lower.contains('.webm') || lower.contains('.m4v') ||
                      lower.contains('.mov') || lower.contains('.m3u8') ||
                      lower.contains('.ts?');
                  if (isMedia && !_dialogOpen) {
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
            ),
          ]),
        ),
      ),
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
          // Handle
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Preview
          if (hasThumb)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: widget.thumb,
                height: 160, width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 160,
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24)))),
                errorWidget: (_, __, ___) => Container(height: 80,
                    color: Colors.white.withOpacity(0.05),
                    child: Center(child: Icon(
                        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                        color: Colors.white24, size: 32))),
              ),
            )
          else
            Container(height: 80, width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: Icon(
                  isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                  color: Colors.white24, size: 32))),

          const SizedBox(height: 16),

          Row(children: [
            Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Baixar ${isVideo ? 'vídeo' : 'imagem'}',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            )),
            Text('Privado', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ]),

          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),

          if (_downloading)
            Column(children: [
              LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(widget.site.primaryColor),
                borderRadius: BorderRadius.circular(6), minHeight: 5),
              const SizedBox(height: 10),
              Text('A baixar...', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ])
          else if (_done)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent.shade400, size: 22),
              const SizedBox(width: 8),
              const Text('Guardado!', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
            ])
          else
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(24)),
                    child: const Center(child: Text('Cancelar',
                        style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2,
                child: GestureDetector(
                  onTap: _doDownload,
                  child: Container(height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.download_rounded, color: Colors.black87, size: 20),
                      const SizedBox(width: 8),
                      Text('Baixar ${isVideo ? 'vídeo' : 'imagem'}',
                          style: const TextStyle(color: Colors.black87,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
            ]),
        ]),
      ),
    );
  }
}
