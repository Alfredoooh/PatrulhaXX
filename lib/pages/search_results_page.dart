import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'home_page.dart' show iosRoute;
import 'browser_page.dart';
import '../models/site_model.dart';
import 'search_page.dart' show FreeBrowserPage;

const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

const _ddgCss = '''
(function() {
  if (window.__ddgCssInjected) return;
  window.__ddgCssInjected = true;
  const s = document.createElement('style');
  s.textContent = `
    #header_wrapper, #header, .header--aside,
    .js-header-wrapper, .nav-menu, #duckbar,
    [class*="Header"], [id*="header"] { display: none !important; }
    ::-webkit-scrollbar { display: none !important; width: 0 !important; }
  `;
  document.head.appendChild(s);
})();
''';

// domínios DDG aceites dentro do WebView (não abrem no BrowserPage)
const _kDdgDomains = [
  'duckduckgo.com',
  'safe.duckduckgo.com',
];

bool _isDdgUrl(String url) {
  try {
    final host = Uri.parse(url).host.toLowerCase();
    return _kDdgDomains.any((d) => host == d || host.endsWith('.$d'));
  } catch (_) {
    return false;
  }
}

enum _WebTab { tudo, imagens, videos }

extension _WebTabX on _WebTab {
  String get label {
    switch (this) {
      case _WebTab.tudo:    return 'Tudo';
      case _WebTab.imagens: return 'Imagens';
      case _WebTab.videos:  return 'Vídeos';
    }
  }

  String url(String q) {
    final enc = Uri.encodeComponent(q);
    switch (this) {
      case _WebTab.tudo:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&ia=web&kaj=m';
      case _WebTab.imagens:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&iax=images&ia=images&kaj=m';
      case _WebTab.videos:
        return '';
    }
  }
}

// ─── Modelo de resultado de vídeo por scraping ────────────────────────────────
class _ScrapedVideo {
  final String title;
  final String link;
  final String thumb;
  final String siteName;
  final String faviconUrl;

  const _ScrapedVideo({
    required this.title,
    required this.link,
    required this.thumb,
    required this.siteName,
    required this.faviconUrl,
  });
}

class SearchResultsPage extends StatefulWidget {
  final void Function(FeedVideo)? onVideoTap;
  final String? query;
  const SearchResultsPage({super.key, this.query, this.onVideoTap});
  @override State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  late final TextEditingController _q;
  final _focus = FocusNode();

  bool _searching    = false;
  bool _editingQuery = false;

  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  _WebTab _activeTab = _WebTab.tudo;

  // vídeos scraping
  List<_ScrapedVideo> _scrapedVideos = [];
  bool _scrapingVideos = false;

  final Map<_WebTab, InAppWebViewController?> _webCtrls = {
    for (final t in _WebTab.values) t: null,
  };
  final Map<_WebTab, bool> _webLoading = {
    for (final t in _WebTab.values) t: false,
  };

  @override void initState() {
    super.initState();
    _q = TextEditingController(text: widget.query ?? '');
    _q.addListener(_onTyping);
    _loadHistory();
    if ((widget.query ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(widget.query!));
    }
  }

  @override void dispose() {
    _q.removeListener(_onTyping);
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _history = p.getStringList(_kHistory) ?? []);
  }

  Future<void> _saveHistory(String q) async {
    if (q.isEmpty) return;
    _history.remove(q); _history.insert(0, q);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
  }

  Future<void> _removeHistory(String q) async {
    _history.remove(q); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
  }

  Future<void> _clearHistory() async {
    _history.clear(); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHistory);
  }

  void _onTyping() {
    setState(() {});
    final q = _q.text.trim();
    if (q.length >= 2) _fetchSuggestions(q);
    else setState(() => _suggestions = []);
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      final uri = Uri.parse(
          'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeComponent(q)}');
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (!mounted) return;
      final data = jsonDecode(r.body);
      setState(() => _suggestions =
          (data[1] as List).map((e) => e.toString()).take(7).toList());
    } catch (_) {}
  }

  Future<void> _doSearch(String q) async {
    q = q.trim(); if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
    await _saveHistory(q);

    setState(() {
      _searching    = true;
      _editingQuery = false;
      _suggestions  = [];
      _activeTab    = _WebTab.tudo;
      _scrapedVideos = [];
    });

    for (final tab in [_WebTab.tudo, _WebTab.imagens]) {
      final ctrl = _webCtrls[tab];
      if (ctrl != null) {
        ctrl.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url(q))));
      }
    }

    _scrapeVideos(q);
  }

  // ── Scraping de vídeos nos sites de kSites ──────────────────────────────────
  Future<void> _scrapeVideos(String query) async {
    if (!mounted) return;
    setState(() => _scrapingVideos = true);

    final results = <_ScrapedVideo>[];
    final enc = Uri.encodeComponent(query);

    // Sites com estrutura conhecida para scraping básico via HTTP
    final targets = [
      (site: kSites.firstWhere((s) => s.id == 'xvideos'),
       searchUrl: 'https://www.xvideos.com/?k=$enc'),
      (site: kSites.firstWhere((s) => s.id == 'xnxx'),
       searchUrl: 'https://www.xnxx.com/search/$enc/1'),
      (site: kSites.firstWhere((s) => s.id == 'xhamster'),
       searchUrl: 'https://xhamster.com/search/$enc'),
      (site: kSites.firstWhere((s) => s.id == 'pornhub'),
       searchUrl: 'https://www.pornhub.com/video/search?search=$enc'),
      (site: kSites.firstWhere((s) => s.id == 'redtube'),
       searchUrl: 'https://www.redtube.com/?search=$enc'),
    ];

    await Future.wait(targets.map((t) async {
      try {
        final r = await http.get(
          Uri.parse(t.searchUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/124.0.0.0 Mobile Safari/537.36',
            'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
          },
        ).timeout(const Duration(seconds: 8));

        final body = r.body;
        final videos = _parseVideoResults(body, t.site, t.searchUrl);
        results.addAll(videos.take(6));
      } catch (_) {}
    }));

    if (mounted) {
      setState(() {
        _scrapedVideos = results;
        _scrapingVideos = false;
      });
    }
  }

  List<_ScrapedVideo> _parseVideoResults(
      String html, SiteModel site, String baseSearch) {
    final results = <_ScrapedVideo>[];

    // Regex genérico para extrair thumbnails e títulos
    // Cada site tem estrutura diferente mas todos têm og:image ou data-thumb
    final thumbRe = RegExp(
      r'(?:data-thumb(?:two)?|data-src|src)="(https?://[^"]+\.(?:jpg|jpeg|webp|png)[^"]*)"',
      caseSensitive: false,
    );
    final titleRe = RegExp(
      r'(?:title="([^"]{10,100})"|alt="([^"]{10,100})")',
      caseSensitive: false,
    );
    final linkRe = RegExp(
      r'href="(/(?:video[^"]{5,}|watch[^"]{5,}|[^"]{5,}\.html[^"]*|[^"]{5,}/\d+[^"]{0,30}))"',
      caseSensitive: false,
    );

    final thumbs = thumbRe.allMatches(html).map((m) => m.group(1)!).toSet().toList();
    final titles = titleRe.allMatches(html)
        .map((m) => (m.group(1) ?? m.group(2) ?? '').trim())
        .where((t) => t.length > 8)
        .toList();
    final links = linkRe.allMatches(html)
        .map((m) {
          final path = m.group(1)!;
          final domain = Uri.parse(site.baseUrl).origin;
          return '$domain$path';
        })
        .toSet()
        .toList();

    final count = [thumbs.length, titles.length, links.length].reduce(
        (a, b) => a < b ? a : b);

    for (var i = 0; i < count && results.length < 6; i++) {
      results.add(_ScrapedVideo(
        title: titles[i],
        link: links[i],
        thumb: thumbs[i],
        siteName: site.name,
        faviconUrl: site.faviconUrl,
      ));
    }

    return results;
  }

  void _activateEditing() {
    setState(() => _editingQuery = true);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focus.requestFocus();
    });
  }

  void _clearSearch() {
    _q.clear();
    setState(() {
      _searching    = false;
      _editingQuery = false;
      _suggestions  = [];
    });
    _focus.requestFocus();
  }

  Future<bool> _onWillPop() async {
    if (_searching && _activeTab != _WebTab.videos) {
      final ctrl = _webCtrls[_activeTab];
      if (ctrl != null && await ctrl.canGoBack()) {
        await ctrl.goBack();
        return false;
      }
    }
    return true;
  }

  void _goBack() => Navigator.pop(context);

  void _switchTab(_WebTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  // Abre link externo (não-DDG) no BrowserPage
  void _openInBrowser(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final host = uri.host.toLowerCase();
    // Tenta encontrar site correspondente em kSites
    final matched = kSites.cast<SiteModel?>().firstWhere(
      (s) => host == s!.allowedDomain || host.endsWith('.${s.allowedDomain}'),
      orElse: () => null,
    );
    final site = matched ?? SiteModel(
      id: 'ext',
      name: host,
      baseUrl: url,
      allowedDomain: host,
      searchUrl: url,
      primaryColor: const Color(0xFF2A2A2A),
    );
    Navigator.push(context, iosRoute(BrowserPage(site: site, initialUrl: url, freeNavigation: true)));
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (_, __) {
          final t          = AppTheme.current;
          final isDark     = t.statusBar == Brightness.light;
          final showEditable = !_searching || _editingQuery;
          final cardBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
          final mutedIc = isDark ? Colors.white30 : Colors.black26;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: t.statusBar),
            child: Scaffold(
              backgroundColor: t.bg,
              resizeToAvoidBottomInset: false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── AppBar ──────────────────────────────────────────────────
                  Container(
                    color: t.appBar,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topPad),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                          child: Row(children: [

                            // Botão voltar
                            GestureDetector(
                              onTap: _goBack,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: _SvgIcon(_iBack,
                                    color: isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Campo de pesquisa
                            Expanded(
                              child: GestureDetector(
                                onTap: showEditable ? null : _activateEditing,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFE8E8E8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: showEditable
                                      ? Row(children: [
                                          const SizedBox(width: 10),
                                          Icon(Icons.search, size: 16,
                                              color: isDark ? Colors.white38 : Colors.black38),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextField(
                                              controller: _q,
                                              focusNode: _focus,
                                              style: TextStyle(
                                                  color: t.text, fontSize: 15),
                                              decoration: InputDecoration(
                                                hintText: 'Pesquisar...',
                                                hintStyle: TextStyle(
                                                    color: isDark
                                                        ? Colors.white30
                                                        : Colors.black38),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              textInputAction: TextInputAction.search,
                                              onSubmitted: _doSearch,
                                            ),
                                          ),
                                          if (_q.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: _clearSearch,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Icon(Icons.close,
                                                    size: 16,
                                                    color: isDark ? Colors.white38 : Colors.black38),
                                              ),
                                            ),
                                        ])
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _q.text.isEmpty ? 'Pesquisar...' : _q.text,
                                              style: TextStyle(
                                                color: _q.text.isEmpty
                                                    ? (isDark ? Colors.white30 : Colors.black38)
                                                    : t.text,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ]),
                        ),

                        // Tabs (só quando pesquisando)
                        if (_searching)
                          _TabBar(
                            active: _activeTab,
                            onSwitch: _switchTab,
                            isDark: isDark,
                            accentColor: t.accent,
                          ),
                      ],
                    ),
                  ),

                  // ── Corpo ───────────────────────────────────────────────────
                  Expanded(
                    child: _editingQuery
                        ? _SuggestionsView(
                            query: _q.text.trim(),
                            history: _history,
                            suggestions: _suggestions,
                            textColor: t.text,
                            subColor: isDark ? Colors.white54 : Colors.black45,
                            divColor: isDark ? Colors.white12 : Colors.black12,
                            cardBg: cardBg,
                            mutedColor: mutedIc,
                            onSelect: _doSearch,
                            onFill: (s) { _q.text = s; _q.selection = TextSelection.collapsed(offset: s.length); },
                            onRemoveHistory: _removeHistory,
                            onClearHistory: _clearHistory,
                          )
                        : !_searching
                            ? _EmptyState(subColor: isDark ? Colors.white38 : Colors.black38)
                            : Stack(
                                children: [
                                  // WebViews (tudo + imagens) — sempre no DOM, só visibilidade muda
                                  for (final tab in [_WebTab.tudo, _WebTab.imagens])
                                    Offstage(
                                      offstage: _activeTab != tab,
                                      child: _WebPane(
                                        tab: tab,
                                        query: _q.text,
                                        isDark: isDark,
                                        loading: _webLoading[tab]!,
                                        bgColor: t.bg,
                                        bottomPad: bottomPad,
                                        onCreated: (ctrl) => _webCtrls[tab] = ctrl,
                                        onLoadStart: () => setState(() => _webLoading[tab] = true),
                                        onLoadStop: (ctrl) async {
                                          await ctrl.evaluateJavascript(source: _ddgCss);
                                          if (mounted) setState(() => _webLoading[tab] = false);
                                        },
                                        onExternalUrl: _openInBrowser,
                                      ),
                                    ),
                                  // Tab Vídeos — cards nativos scraping
                                  if (_activeTab == _WebTab.videos)
                                    _VideosPane(
                                      videos: _scrapedVideos,
                                      loading: _scrapingVideos,
                                      isDark: isDark,
                                      textColor: t.text,
                                      subColor: isDark ? Colors.white54 : Colors.black45,
                                      onTap: _openInBrowser,
                                    ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── TabBar ───────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final _WebTab active;
  final void Function(_WebTab) onSwitch;
  final bool isDark;
  final Color accentColor;

  const _TabBar({
    required this.active,
    required this.onSwitch,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: _WebTab.values.map((tab) {
          final isActive = tab == active;
          return GestureDetector(
            onTap: () => onSwitch(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isActive
                      ? accentColor
                      : (isDark ? Colors.white54 : Colors.black45),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── WebPane ──────────────────────────────────────────────────────────────────
class _WebPane extends StatelessWidget {
  final _WebTab tab;
  final String query;
  final bool isDark, loading;
  final Color bgColor;
  final double bottomPad;
  final void Function(InAppWebViewController) onCreated;
  final VoidCallback onLoadStart;
  final void Function(InAppWebViewController) onLoadStop;
  final void Function(String url) onExternalUrl;

  const _WebPane({
    super.key,
    required this.tab,
    required this.query,
    required this.isDark,
    required this.loading,
    required this.bgColor,
    required this.bottomPad,
    required this.onCreated,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onExternalUrl,
  });

  @override Widget build(BuildContext context) {
    return ColoredBox(
      // Fix linha branca: preenche o fundo antes do WebView renderizar
      color: bgColor,
      child: Padding(
        // Fix linha branca lateral e inferior: padding negativo equivalente via SizedBox
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Stack(children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(tab.url(query))),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/124.0.0.0 Mobile Safari/537.36',
              // Fix linha branca: useHybridComposition corrige o rendering
              // do AndroidView que deixa 1px de borda no lado direito e inferior
              useHybridComposition: true,
              transparentBackground: false,
              supportZoom: false,
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
            ),
            onWebViewCreated: onCreated,
            onLoadStart: (_, __) => onLoadStart(),
            onLoadStop: (ctrl, __) => onLoadStop(ctrl),
            onReceivedError: (_, __, ___) {
              if (loading) onLoadStart();
            },
            shouldOverrideUrlLoading: (ctrl, action) async {
              final url = action.request.url?.toString() ?? '';
              // Se não for DDG, abre no BrowserPage
              if (!_isDdgUrl(url)) {
                onExternalUrl(url);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),

          if (loading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppTheme.ytRed,
                minHeight: 2,
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── VideosPane — scraping nativo ─────────────────────────────────────────────
class _VideosPane extends StatelessWidget {
  final List<_ScrapedVideo> videos;
  final bool loading;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final void Function(String) onTap;

  const _VideosPane({
    required this.videos,
    required this.loading,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (videos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.videocam_off_rounded, size: 48, color: subColor.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('Nenhum vídeo encontrado', style: TextStyle(color: subColor, fontSize: 14)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final v = videos[i];
        return GestureDetector(
          onTap: () => onTap(v.link),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    v.thumb,
                    width: 130,
                    height: 80,
                    fit: BoxFit.cover,
                    headers: const {
                      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 130,
                      height: 80,
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                      child: Icon(Icons.play_circle_outline, color: subColor, size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Image.network(
                          v.faviconUrl,
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.public, size: 14, color: subColor),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          v.siteName,
                          style: TextStyle(color: subColor, fontSize: 11),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color subColor;
  const _EmptyState({required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, color: subColor.withOpacity(0.25), size: 48),
        const SizedBox(height: 14),
        Text('Pesquisa algo', style: TextStyle(color: subColor, fontSize: 14)),
      ]),
    );
  }
}

// ─── SuggestionsView — cards idênticos ao histórico do search_page ────────────
class _SuggestionsView extends StatelessWidget {
  final String query;
  final List<String> history, suggestions;
  final Color textColor, subColor, divColor, cardBg, mutedColor;
  final void Function(String) onSelect, onFill, onRemoveHistory;
  final VoidCallback onClearHistory;

  const _SuggestionsView({
    required this.query,
    required this.history,
    required this.suggestions,
    required this.textColor,
    required this.subColor,
    required this.divColor,
    required this.cardBg,
    required this.mutedColor,
    required this.onSelect,
    required this.onFill,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final showSuggestions = query.length >= 2 && suggestions.isNotEmpty;
    final items = showSuggestions ? suggestions : history;

    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, color: subColor.withOpacity(0.25), size: 48),
        const SizedBox(height: 14),
        Text('Pesquisa algo', style: TextStyle(color: subColor, fontSize: 14)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (!showSuggestions && history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Text('Pesquisas recentes',
                  style: TextStyle(color: subColor,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: onClearHistory,
                child: Text('Limpar tudo',
                    style: TextStyle(color: AppTheme.ytRed,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

        // Cards iOS-style idênticos ao search_page
        _IosGroupedList(
          bg: cardBg,
          mutedColor: mutedColor,
          textColor: textColor,
          items: items,
          isHistory: !showSuggestions,
          onTap: onSelect,
          onAction: showSuggestions ? onFill : onRemoveHistory,
        ),
      ],
    );
  }
}

// ─── IosGroupedList — idêntico ao search_page.dart ───────────────────────────
class _IosGroupedList extends StatelessWidget {
  final Color bg, textColor, mutedColor;
  final List<String> items;
  final bool isHistory;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onAction;

  const _IosGroupedList({
    required this.bg,
    required this.textColor,
    required this.mutedColor,
    required this.items,
    required this.isHistory,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length;

    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final label = e.value;
        final isOnly = total == 1;
        final isFirst = i == 0;
        final isLast = i == total - 1;

        const big = Radius.circular(12);
        const small = Radius.circular(6);

        final BorderRadius radius = isOnly
            ? const BorderRadius.all(big)
            : isFirst
                ? const BorderRadius.only(
                    topLeft: big, topRight: big,
                    bottomLeft: small, bottomRight: small)
                : isLast
                    ? const BorderRadius.only(
                        topLeft: small, topRight: small,
                        bottomLeft: big, bottomRight: big)
                    : const BorderRadius.all(small);

        final child = Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              color: bg,
              height: 58,
              child: GestureDetector(
                onTap: () => onTap(label),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Icon(
                      isHistory ? Icons.access_time : Icons.search,
                      size: 16,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          )),
                    ),
                    GestureDetector(
                      onTap: () => onAction(label),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          isHistory ? Icons.close : Icons.north_west,
                          size: 15,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );

        if (isHistory) {
          return Dismissible(
            key: ValueKey(label),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onAction(label),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white, size: 20),
            ),
            child: child,
          );
        }
        return child;
      }).toList(),
    );
  }
}

// ─── SvgIcon helper ───────────────────────────────────────────────────────────
class _SvgIcon extends StatelessWidget {
  final String svg;
  final Color color;
  const _SvgIcon(this.svg, {required this.color});

  @override
  Widget build(BuildContext context) {
    final colored = svg.replaceAll(
        '<path ', '<path fill="${_hexColor(color)}" ');
    return Image.memory(
      Uri.dataFromString(colored,
              mimeType: 'image/svg+xml', encoding: utf8)
          .data!
          .contentAsBytes(),
      fit: BoxFit.contain,
    );
  }

  String _hexColor(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}