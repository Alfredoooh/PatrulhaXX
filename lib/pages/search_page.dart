import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import 'search_results_page.dart';
import 'home_page.dart' show iosRoute;

// ─────────────────────────────────────────────────────────────────────────────
// SearchPage
// ─────────────────────────────────────────────────────────────────────────────
class SearchPage extends StatefulWidget {
  final List<FeedVideo> allVideos;
  const SearchPage({super.key, this.allVideos = const []});
  @override State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  bool get _hasQuery => _ctrl.text.trim().isNotEmpty;

  static const _suggestions = [
    'amador português', 'milf', 'latina', 'caseiro', 'teen',
    'loira', 'morena', 'asiática', 'lésbicas', 'threesome',
    'maduro', 'college', 'office', 'massage', 'outdoor',
    'boquete', 'anal', 'gangbang', 'squirt', 'compilação',
  ];

  // vídeos em destaque: mais de 300k visualizações
  List<FeedVideo> get _trending => widget.allVideos
      .where((v) {
        final n = int.tryParse(v.views.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        // suporta já formatados com K/M
        if (v.views.toLowerCase().contains('m')) return true;
        if (v.views.toLowerCase().contains('k')) {
          final k = double.tryParse(
              v.views.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return k >= 300;
        }
        return n >= 300000;
      })
      .take(10)
      .toList();

  @override void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _searchFor(String q) {
    _ctrl.text = q;
    setState(() {});
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _showSearchEngines() {
    final t = AppTheme.current;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final engines = [
          _SearchEngine('Google',  'https://www.google.com/search?q=',      _googleSvg),
          _SearchEngine('Bing',    'https://www.bing.com/search?q=',         _bingSvg),
          _SearchEngine('DuckDuckGo', 'https://duckduckgo.com/?q=',          _ddgSvg),
          _SearchEngine('Yahoo',   'https://search.yahoo.com/search?p=',     _yahooSvg),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: t.divider, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 16),
            Text('Pesquisar com',
              style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...engines.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SvgPicture.string(e.svg, width: 28, height: 28),
              title: Text(e.name,
                style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                final q = _ctrl.text.trim();
                if (q.isNotEmpty) {
                  // abre no browser externo
                  _launchUrl('${e.baseUrl}${Uri.encodeComponent(q)}');
                }
              },
            )),
          ]),
        );
      });
  }

  void _launchUrl(String url) {
    // usa url_launcher se disponível, senão ignora silenciosamente
    try {
      // ignore: deprecated_member_use
      // url_launcher: launchUrl(Uri.parse(url));
      // Se não tiveres url_launcher, substitui aqui
    } catch (_) {}
  }

  @override Widget build(BuildContext context) {
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;
    final trending = _trending;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(children: [
          SizedBox(height: topPad + 10),

          // ── Barra de pesquisa estilo TikTok ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              // Ícone Google → popup motores
              GestureDetector(
                onTap: _showSearchEngines,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: t.btnGhost,
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: SvgPicture.string(_googleSvg, width: 24, height: 24)),
                ),
              ),
              const SizedBox(width: 10),

              // Input estilo TikTok: fundo cinzento, sem borda, search icon dentro
              Expanded(
                child: GestureDetector(
                  onTap: () => _focus.requestFocus(),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          style: TextStyle(
                              color: t.inputText,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                          textInputAction: TextInputAction.search,
                          cursorColor: AppTheme.ytRed,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Pesquisar...',
                            hintStyle: TextStyle(
                                color: isDark ? Colors.white30 : Colors.black38,
                                fontSize: 15),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      if (_hasQuery) ...[
                        GestureDetector(
                          onTap: () { _ctrl.clear(); setState(() {}); },
                          child: Icon(Icons.close_rounded,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black38)),
                        const SizedBox(width: 8),
                      ] else
                        const SizedBox(width: 8),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Botão cancelar / pesquisar
              GestureDetector(
                onTap: _hasQuery ? _search : () => Navigator.pop(context),
                child: Text(
                  _hasQuery ? 'Pesquisar' : 'Cancelar',
                  style: TextStyle(
                    color: _hasQuery ? AppTheme.ytRed : t.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ── Sugestões em lista com bordas agrupadas ──
                Text('Sugestões',
                  style: TextStyle(
                    color: t.textSecondary, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                _SuggestionList(
                  suggestions: _suggestions,
                  onTap: _searchFor,
                ),

                if (trending.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Em alta',
                    style: TextStyle(
                      color: t.textSecondary, fontSize: 12,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  ...trending.asMap().entries.map((e) =>
                    _TrendingItem(
                      video: e.value,
                      index: e.key,
                      total: trending.length,
                      onTap: () => _searchFor(e.value.title),
                    )),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Lista de sugestões agrupada ──────────────────────────────────────────────
class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionList({required this.suggestions, required this.onTap});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Column(
      children: suggestions.asMap().entries.map((e) {
        final i     = e.key;
        final s     = e.value;
        final first = i == 0;
        final last  = i == suggestions.length - 1;

        final radius = BorderRadius.only(
          topLeft:     Radius.circular(first ? 14 : 4),
          topRight:    Radius.circular(first ? 14 : 4),
          bottomLeft:  Radius.circular(last  ? 14 : 4),
          bottomRight: Radius.circular(last  ? 14 : 4),
        );

        return GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            margin: EdgeInsets.only(bottom: first || !last ? 1 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: t.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
              borderRadius: radius,
              border: Border(
                bottom: last
                    ? BorderSide.none
                    : BorderSide(color: t.divider, width: 0.5)),
            ),
            child: Row(children: [
              Icon(Icons.search_rounded, size: 16,
                  color: t.isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s,
                  style: TextStyle(
                    color: t.text, fontSize: 14,
                    fontWeight: FontWeight.w400))),
              Icon(Icons.north_west_rounded, size: 14,
                  color: t.isDark ? Colors.white24 : Colors.black26),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Item em alta ─────────────────────────────────────────────────────────────
class _TrendingItem extends StatelessWidget {
  final FeedVideo video;
  final int index;
  final int total;
  final VoidCallback onTap;
  const _TrendingItem({
    required this.video, required this.index,
    required this.total, required this.onTap});

  String _formatViews(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains(RegExp(r'[KkMmBb]'))) return raw;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  @override Widget build(BuildContext context) {
    final t     = AppTheme.current;
    final first = index == 0;
    final last  = index == total - 1;
    final radius = BorderRadius.only(
      topLeft:     Radius.circular(first ? 14 : 4),
      topRight:    Radius.circular(first ? 14 : 4),
      bottomLeft:  Radius.circular(last  ? 14 : 4),
      bottomRight: Radius.circular(last  ? 14 : 4),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: last ? 0 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
          borderRadius: radius,
          border: Border(
            bottom: last
                ? BorderSide.none
                : BorderSide(color: t.divider, width: 0.5)),
        ),
        child: Row(children: [
          // thumbnail mini
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 52, height: 36,
              child: video.thumb.isEmpty
                  ? Container(color: t.thumbBg)
                  : Image.network(video.thumb, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: t.thumbBg)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(video.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.text, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${_formatViews(video.views)} vis.',
                style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ])),
          Icon(Icons.local_fire_department_rounded,
              size: 16, color: AppTheme.ytRed),
        ]),
      ),
    );
  }
}

// ─── Motor de pesquisa ────────────────────────────────────────────────────────
class _SearchEngine {
  final String name;
  final String baseUrl;
  final String svg;
  const _SearchEngine(this.name, this.baseUrl, this.svg);
}

// ─── SVGs inline ─────────────────────────────────────────────────────────────
const _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

const _bingSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <path fill="#008373" d="M8 3l6 2v18l-4-2-2 3 10 6 8-5V14l-14-5z"/>
</svg>''';

const _ddgSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="16" fill="#DE5833"/>
  <text x="16" y="21" text-anchor="middle" fill="white" font-size="14" font-weight="bold">D</text>
</svg>''';

const _yahooSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="6" fill="#6001D2"/>
  <text x="16" y="22" text-anchor="middle" fill="white" font-size="13" font-weight="bold">Y!</text>
</svg>''';