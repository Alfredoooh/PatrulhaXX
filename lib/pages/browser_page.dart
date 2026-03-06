import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/site_model.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../widgets/site_icon_widget.dart';

// ── SVG popup icons ──────────────────────────────────────────────────────────
const _svgHome = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M22.657,7.419L14.157,.768c-1.271-.994-3.043-.992-4.314,0L1.342,7.42c-.853,.669-1.342,1.674-1.342,2.756v13.824H24V10.176c0-1.082-.489-2.087-1.343-2.757Zm-1.657,13.581H3V10.176c0-.154,.07-.299,.192-.394L11.692,3.131c.182-.143,.436-.143,.615,0l8.499,6.65c.123,.096,.193,.24,.193,.395v10.824Z"/></svg>';
const _svgBack = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M7.7,15.007a1.5,1.5,0,0,1-2.121,0L.858,10.282a2.932,2.932,0,0,1,0-4.145L5.583,1.412A1.5,1.5,0,0,1,7.7,3.533L4.467,6.7l14.213,0A5.325,5.325,0,0,1,24,12.019V18.7a5.323,5.323,0,0,1-5.318,5.318H5.318a1.5,1.5,0,1,1,0-3H18.681A2.321,2.321,0,0,0,21,18.7V12.019A2.321,2.321,0,0,0,18.68,9.7L4.522,9.7,7.7,12.886A1.5,1.5,0,0,1,7.7,15.007Z"/></svg>';
const _svgFwd  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M16.3,15.007a1.5,1.5,0,0,0,2.121,0l4.726-4.725a2.934,2.934,0,0,0,0-4.145L18.416,1.412A1.5,1.5,0,1,0,16.3,3.533L19.532,6.7,5.319,6.7A5.326,5.326,0,0,0,0,12.019V18.7a5.324,5.324,0,0,0,5.318,5.318H18.682a1.5,1.5,0,0,0,0-3H5.318A2.321,2.321,0,0,1,3,18.7V12.019A2.321,2.321,0,0,1,5.319,9.7l14.159,0L16.3,12.886A1.5,1.5,0,0,0,16.3,15.007Z"/></svg>';
const _svgRld  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,0c-2.991,0-5.813,1.113-8,3.078V1c0-.553-.448-1-1-1s-1,.447-1,1V5c0,1.103,.897,2,2,2h4c.552,0,1-.447,1-1s-.448-1-1-1h-3.13c1.876-1.913,4.422-3,7.13-3,5.514,0,10,4.486,10,10s-4.486,10-10,10c-5.21,0-9.492-3.908-9.959-9.09-.049-.55-.526-.956-1.086-.906C.405,12.054,0,12.54,.049,13.09c.561,6.22,5.699,10.91,11.951,10.91,6.617,0,12-5.383,12-12S18.617,0,12,0Z"/></svg>';

class BrowserPage extends StatefulWidget {
  final SiteModel site;
  final String? initialQuery;
  final bool freeNavigation;

  const BrowserPage({super.key, required this.site, this.initialQuery, this.freeNavigation = false});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _ctrl;
  double _progress = 0;
  bool _loading = true;
  bool _dialogOpen = false;

  // Long-press detection state
  Offset? _pressStart;
  bool _moved = false;

  // JS: attach long-press handlers to video/img — fires only on deliberate hold
  static const _js = r"""
(function(){
  if(window.__px) return; window.__px=1;
  var g=false;
  function emit(d){ if(g)return; g=true; setTimeout(()=>{g=false;},3000);
    try{window.flutter_inappwebview.callHandler('DL',JSON.stringify(d));}catch(e){} }
  function vsrc(v){ var s=v.currentSrc||v.src||'';
    if(!s){var ss=v.querySelectorAll('source');for(var i=0;i<ss.length;i++){if(ss[i].src){s=ss[i].src;break;}}}
    return s||v.getAttribute('data-src')||''; }
  function av(v){ if(v.__px)return; v.__px=1; var t=null;
    v.addEventListener('touchstart',function(){
      t=setTimeout(function(){var s=vsrc(v);if(s&&s.startsWith('http'))emit({type:'video',src:s,thumb:v.poster||''});},1200);
    },{passive:true});
    v.addEventListener('touchend',  function(){clearTimeout(t);},{passive:true});
    v.addEventListener('touchcancel',function(){clearTimeout(t);},{passive:true}); }
  function ai(img){ if(img.__px)return; img.__px=1; var t=null;
    img.addEventListener('touchstart',function(){
      t=setTimeout(function(){var s=img.currentSrc||img.src||'';
        if(s&&s.startsWith('http')&&!s.startsWith('data:')&&s.length>20)
          emit({type:'image',src:s,thumb:s});},1500);
    },{passive:true});
    img.addEventListener('touchend',  function(){clearTimeout(t);},{passive:true});
    img.addEventListener('touchcancel',function(){clearTimeout(t);},{passive:true}); }
  function scan(){ document.querySelectorAll('video').forEach(av); document.querySelectorAll('img').forEach(ai); }
  scan();
  new MutationObserver(function(ms){ ms.forEach(function(m){ m.addedNodes.forEach(function(n){
    if(!n.tagName)return;
    if(n.tagName==='VIDEO')av(n); else if(n.tagName==='IMG')ai(n);
    if(n.querySelectorAll){n.querySelectorAll('video').forEach(av);n.querySelectorAll('img').forEach(ai);}
  });}); }).observe(document.documentElement,{childList:true,subtree:true});
  document.addEventListener('contextmenu',function(e){
    var t=e.target;
    if(t.tagName==='VIDEO'||(t.closest&&t.closest('video'))){
      var v=t.tagName==='VIDEO'?t:t.closest('video');var s=vsrc(v);
      if(s){emit({type:'video',src:s,thumb:v.poster||''});e.preventDefault();}
    } else if(t.tagName==='IMG'){
      var s=t.src||'';if(s&&s.startsWith('http')){emit({type:'image',src:s,thumb:s});e.preventDefault();}
    }
  },false);
})();
""";

  @override
  void initState() { super.initState(); }

  bool _isAllowed(String url) {
    if (widget.freeNavigation || widget.site.allowedDomain.isEmpty) return true;
    try {
      final h = Uri.parse(url).host.toLowerCase();
      final d = widget.site.allowedDomain.toLowerCase();
      return h == d || h.endsWith('.$d');
    } catch(_){ return false; }
  }

  void _onDl(List<dynamic> args) {
    if (_dialogOpen || args.isEmpty || _moved) return;
    try {
      final data = _json(args[0].toString());
      if (data == null) return;
      final src = data['src'] as String? ?? '';
      if (src.isEmpty) return;
      _showDl(src: src, type: data['type'] as String? ?? 'video', thumb: data['thumb'] as String? ?? '');
    } catch(_){}
  }

  Map<String,dynamic>? _json(String raw) {
    try {
      final r = <String,dynamic>{};
      final rx = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
      for (final m in rx.allMatches(raw)) r[m.group(1)!] = m.group(2)!;
      return r.isEmpty ? null : r;
    } catch(_){ return null; }
  }

  void _showDl({required String src, required String type, required String thumb}) {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _DlSheet(src: src, type: type, thumb: thumb, site: widget.site),
    ).whenComplete(() { if(mounted) setState(() => _dialogOpen = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _BlurAppBar(
        site: widget.site,
        progress: _loading ? _progress : 1.0,
        isLoading: _loading,
        onBack: () => Navigator.of(context).pop(),
        onMenu: _handleMenu,
      ),
      body: Listener(
        // Track scroll gestures to suppress accidental dialog
        onPointerDown: (e) { _pressStart = e.position; _moved = false; },
        onPointerMove: (e) {
          if (_pressStart != null) {
            final d = (e.position - _pressStart!).distance;
            if (d > 8) _moved = true;
          }
        },
        onPointerUp: (_) { _pressStart = null; },
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.site.buildUrl(query: widget.initialQuery))),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            useOnDownloadStart: true,
            useShouldOverrideUrlLoading: true,
            supportZoom: true, builtInZoomControls: false, displayZoomControls: false,
            cacheEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          ),
          onWebViewCreated: (ctrl) {
            _ctrl = ctrl;
            ctrl.addJavaScriptHandler(handlerName: 'DL', callback: _onDl);
          },
          onLoadStart: (_, __) => setState(() { _loading = true; _progress = 0; }),
          onLoadStop: (ctrl, _) async {
            setState(() => _loading = false);
            await ctrl.evaluateJavascript(source: _js);
          },
          onProgressChanged: (_, p) => setState(() => _progress = p / 100),
          shouldOverrideUrlLoading: (ctrl, action) async {
            final url = action.request.url?.toString() ?? '';
            final low = url.toLowerCase();
            if ((low.contains('.mp4')||low.contains('.webm')||low.contains('.m4v')||low.contains('.m3u8'))
                && !_dialogOpen) {
              _showDl(src: url, type: 'video', thumb: '');
              return NavigationActionPolicy.CANCEL;
            }
            if (!_isAllowed(url)) return NavigationActionPolicy.CANCEL;
            return NavigationActionPolicy.ALLOW;
          },
          onDownloadStartRequest: (_, req) {
            if (!_dialogOpen) {
              final url = req.url.toString();
              final low = url.toLowerCase();
              final type = (low.contains('.mp4')||low.contains('.webm')||
                  low.contains('video')||low.contains('.m3u8')) ? 'video' : 'image';
              _showDl(src: url, type: type, thumb: '');
            }
          },
          onPermissionRequest: (_, req) async =>
              PermissionResponse(resources: req.resources, action: PermissionResponseAction.GRANT),
        ),
      ),
    );
  }

  void _handleMenu(_MenuAct act) async {
    switch(act) {
      case _MenuAct.back:    if(await _ctrl?.canGoBack()    == true) _ctrl!.goBack(); break;
      case _MenuAct.fwd:     if(await _ctrl?.canGoForward() == true) _ctrl!.goForward(); break;
      case _MenuAct.reload:  _ctrl?.reload(); break;
      case _MenuAct.home:    _ctrl?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.site.baseUrl))); break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blur AppBar — white tone, progress line at bottom
// ─────────────────────────────────────────────────────────────────────────────
enum _MenuAct { back, fwd, reload, home }

class _BlurAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SiteModel site;
  final double progress;
  final bool isLoading;
  final VoidCallback onBack;
  final ValueChanged<_MenuAct> onMenu;

  const _BlurAppBar({required this.site, required this.progress,
      required this.isLoading, required this.onBack, required this.onMenu});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          color: Colors.white.withOpacity(0.88),
          child: SafeArea(
            bottom: false,
            child: Stack(children: [
              Row(children: [
                const SizedBox(width: 4),
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 22),
                  onPressed: onBack,
                ),
                // Favicon + name
                SiteIconWidget(site: site, size: 26, showShadow: false),
                const SizedBox(width: 8),
                Expanded(child: Text(site.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontSize: 15,
                        fontWeight: FontWeight.w600))),
                // Menu
                _MenuBtn(onMenu: onMenu),
                const SizedBox(width: 8),
              ]),
              // Progress line at very bottom
              if (isLoading)
                Positioned(
                  left: 0, bottom: 0,
                  width: w * progress, height: 2.5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popup menu button
// ─────────────────────────────────────────────────────────────────────────────
class _MenuBtn extends StatefulWidget {
  final ValueChanged<_MenuAct> onMenu;
  const _MenuBtn({required this.onMenu});
  @override
  State<_MenuBtn> createState() => _MenuBtnState();
}

class _MenuBtnState extends State<_MenuBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _sc;
  OverlayEntry? _ov;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _sc = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 150),
        lowerBound: 0, upperBound: 1);
  }

  @override
  void dispose() { _close(); _sc.dispose(); super.dispose(); }

  void _toggle(BuildContext ctx) { _open ? _close() : _open2(ctx); }

  void _open2(BuildContext ctx) {
    final btn = ctx.findRenderObject() as RenderBox;
    final ov  = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final pos = btn.localToGlobal(Offset.zero, ancestor: ov);
    _ov = OverlayEntry(builder: (_) => _PopMenu(
      right: ov.size.width - pos.dx - btn.size.width,
      top: pos.dy + btn.size.height + 4,
      onAct: (a) { _close(); widget.onMenu(a); },
      onDismiss: _close,
    ));
    Overlay.of(ctx).insert(_ov!);
    setState(() => _open = true);
  }

  void _close() {
    _ov?.remove(); _ov = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTapDown: (_) => _sc.forward(),
      onTapUp: (_) { _sc.reverse(); _toggle(ctx); },
      onTapCancel: () => _sc.reverse(),
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, ch) => Transform.scale(scale: 1 - _sc.value * 0.12, child: ch),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.08)),
          child: Center(child: Icon(
              _open ? Icons.close_rounded : Icons.more_horiz_rounded,
              color: Colors.black87, size: 18)),
        ),
      ),
    );
  }
}

class _PopMenu extends StatefulWidget {
  final double right, top;
  final ValueChanged<_MenuAct> onAct;
  final VoidCallback onDismiss;
  const _PopMenu({required this.right, required this.top, required this.onAct, required this.onDismiss});
  @override
  State<_PopMenu> createState() => _PopMenuState();
}

class _PopMenuState extends State<_PopMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _a;
  late final Animation<double> _op, _sc;
  late final Animation<Offset> _sl;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _op = CurvedAnimation(parent: _a, curve: Curves.easeOut);
    _sc = Tween(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _a, curve: Curves.easeOutCubic));
    _sl = Tween(begin: const Offset(0,-0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _a, curve: Curves.easeOutCubic));
    _a.forward();
  }

  @override
  void dispose() { _a.dispose(); super.dispose(); }

  static const _items = [
    (_MenuAct.back,   _svgBack, 'Anterior'),
    (_MenuAct.fwd,    _svgFwd,  'Próxima'),
    (_MenuAct.reload, _svgRld,  'Recarregar'),
    (_MenuAct.home,   _svgHome, 'Página principal'),
  ];

  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(child: GestureDetector(
        onTap: widget.onDismiss, behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand())),
    Positioned(
      right: widget.right, top: widget.top,
      child: FadeTransition(opacity: _op,
        child: SlideTransition(position: _sl,
          child: ScaleTransition(scale: _sc, alignment: Alignment.topRight,
            child: Material(color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 210,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                          blurRadius: 24, offset: const Offset(0,8))],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min,
                      children: _items.asMap().entries.map((e) {
                        final (act, svg, lbl) = e.value;
                        return Column(mainAxisSize: MainAxisSize.min, children: [
                          if (e.key > 0) Divider(height: 1,
                              color: Colors.black.withOpacity(0.08), indent:16, endIndent:16),
                          _PItem(svg: svg, label: lbl, onTap: () => widget.onAct(act)),
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
    ),
  ]);
}

class _PItem extends StatefulWidget {
  final String svg, label;
  final VoidCallback onTap;
  const _PItem({required this.svg, required this.label, required this.onTap});
  @override
  State<_PItem> createState() => _PItemState();
}

class _PItemState extends State<_PItem> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp:   (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      color: _p ? Colors.black.withOpacity(0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        SvgPicture.string(widget.svg, width: 18, height: 18,
            colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn)),
        const SizedBox(width: 14),
        Text(widget.label, style: const TextStyle(color: Colors.black87,
            fontSize: 14, fontWeight: FontWeight.w400)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Download sheet — compact image preview
// ─────────────────────────────────────────────────────────────────────────────
class _DlSheet extends StatefulWidget {
  final String src, type, thumb;
  final SiteModel site;
  const _DlSheet({required this.src, required this.type, required this.thumb, required this.site});
  @override
  State<_DlSheet> createState() => _DlSheetState();
}

class _DlSheetState extends State<_DlSheet> {
  bool _dl = false, _done = false;
  String? _err;

  Future<void> _go() async {
    setState(() { _dl = true; _err = null; });
    final item = await DownloadService.instance.download(
        url: widget.src, type: widget.type, context: context);
    if (!mounted) return;
    if (item != null) {
      setState(() { _dl = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _dl = false; _err = 'Falhou. Tenta novamente.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVid = widget.type == 'video';
    final hasThumb = widget.thumb.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),

          // Compact thumbnail — max height 120
          if (hasThumb)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: widget.thumb,
                height: 110, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 110,
                    color: Colors.white.withOpacity(0.04)),
                errorWidget: (_, __, ___) => _ph(isVid),
              ),
            )
          else
            _ph(isVid),

          const SizedBox(height: 14),

          Row(children: [
            Icon(isVid ? Icons.videocam_outlined : Icons.image_outlined,
                color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Baixar ${isVid ? 'vídeo' : 'imagem'}',
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600))),
            Text('Privado', style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ]),

          const SizedBox(height: 14),

          if (_err != null)
            Padding(padding: const EdgeInsets.only(bottom: 10),
                child: Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),

          if (_dl)
            Column(children: [
              LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Colors.white54),
                borderRadius: BorderRadius.circular(6), minHeight: 4),
              const SizedBox(height: 8),
              Text('A baixar...', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ])
          else if (_done)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent.shade400, size: 20),
              const SizedBox(width: 8),
              const Text('Guardado!', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
            ])
          else
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(height: 48,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24)),
                  child: const Center(child: Text('Cancelar',
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500)))),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: GestureDetector(
                onTap: _go,
                child: Container(height: 48,
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(24)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.download_rounded, color: Colors.black87, size: 18),
                    const SizedBox(width: 8),
                    Text('Baixar ${isVid ? 'vídeo' : 'imagem'}',
                        style: const TextStyle(color: Colors.black87,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              )),
            ]),
        ]),
      ),
    );
  }

  Widget _ph(bool isVid) => Container(
    height: 64, width: double.infinity,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10)),
    child: Center(child: Icon(
        isVid ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white24, size: 30)),
  );
}
