import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_results_page.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../services/theme_service.dart';
import 'exibicao_page.dart';
import '../theme/app_theme.dart';

const kPrimaryColor = Color(0xFFFF9000);

const svgExibicaoOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <rect x="2" y="3" width="20" height="14" rx="2"/>
  <path d="M8 21h8M12 17v4"/>
  <polygon points="10,8 16,11 10,14" fill="currentColor" stroke="none"/>
</svg>
''';


const _shortsJs = r"""
(function() {
  if (window.__pxShortsInit) return;
  window.__pxShortsInit = true;
  var d = new Date(); d.setFullYear(d.getFullYear() + 2);
  var exp = '; expires=' + d.toUTCString() + '; path=/';
  ['age_verified=1','platform=pc','_tc=1','hasVisited=1',
   'cookieConsent=1','accessAgeDisclaimerPH=1','accessPH=1'].forEach(function(c){
    document.cookie = c + exp;
  });
  function cleanPage() {
    document.querySelectorAll(
      '.age-gate,#age-gate,.AgeGate,[class*="ageGate"],[class*="age-gate"],' +
      '[id*="age-gate"],.cookieBanner,.cookie-banner,[class*="cookie-banner"],' +
      '.gdpr-banner,[class*="gdpr"],[class*="consent"],[class*="Consent"],' +
      '.limited-functionality,.tabs-container,.age-wall,[class*="ageWall"]'
    ).forEach(function(el) { el.remove(); });
    document.body.style.overflow = '';
    document.documentElement.style.overflow = '';
    document.body.style.background = '#000';
    document.documentElement.style.background = '#000';
    var style = document.getElementById('__px_style');
    if (!style) {
      style = document.createElement('style');
      style.id = '__px_style';
      style.textContent = '* { text-decoration: none !important; } a { text-decoration: none !important; }';
      document.head.appendChild(style);
    }
    ['header','footer','.header','.footer','nav#top','#header'].forEach(function(s) {
      var el = document.querySelector(s);
      if (el) el.style.display = 'none';
    });
    (function walkText(node) {
      if (node.nodeType === 3) {
        node.textContent = node.textContent.replace(/PornHub|Pornhub|pornhub/g, 'patrulhaXX');
      } else if (node.nodeType === 1 &&
          !['SCRIPT','STYLE','INPUT','TEXTAREA'].includes(node.tagName)) {
        node.childNodes.forEach(walkText);
      }
    })(document.body);
    document.querySelectorAll('img').forEach(function(img) {
      var src = (img.getAttribute('src') || '').toLowerCase();
      if (src.includes('logo')) img.style.visibility = 'hidden';
    });
  }
  cleanPage();
  new MutationObserver(function() { cleanPage(); })
    .observe(document.documentElement, { childList: true, subtree: true });
  function tryClickAgeBtn() {
    ['[data-role="age-gate-submit"]','.age-gate__submit','.button-cta',
     'button[class*="confirm"]','button[class*="accept"]','button.bg-primary',
     'button[class*="enter"]','.enter-btn','.js-accept'].forEach(function(sel) {
      var btn = document.querySelector(sel);
      if (btn) btn.click();
    });
    cleanPage();
  }
  setTimeout(tryClickAgeBtn, 300);
  setTimeout(tryClickAgeBtn, 900);
  setTimeout(cleanPage, 2000);
  setTimeout(cleanPage, 4000);
})();
""";

Route<T> _iosRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      final pushSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      return SlideTransition(
        position: pushSlide,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 1;
  int _previousTab = 1;
  String? _selectedEmbedUrl;
  FeedVideo? _selectedVideo;
  bool _miniPlayerActive = false;
  late final AnimationController _fadeIn;
  late final AnimationController _tabAnim;

  Color _wallpaperColor = Colors.black;

  static const _kNavH = 62.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _tabAnim.value = 1.0;
    final saved = ThemeService.instance.wallpaperColor;
    if (saved != null) _wallpaperColor = saved;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) {
        _fadeIn.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeIn.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  void _openSite(SiteModel site) => Navigator.push(
      context, _iosRoute(BrowserPage(site: site)));

  void _onColorExtracted(Color c) {
    if (mounted) {
      setState(() => _wallpaperColor = c);
      ThemeService.instance.setWallpaperColor(c);
    }
  }

  void _openDownloads() => Navigator.push(context,
      _iosRoute(const DownloadsPage()));

  void _openSettings() => Navigator.push(context,
      _iosRoute(const SettingsPage()));

  void _switchTab(int i) {
    if (i == _tab) return;
    setState(() {
      _previousTab = _tab;
      if (i != 2 && _tab == 2 && _selectedVideo != null) {
        _miniPlayerActive = true;
      } else if (i == 2) {
        _miniPlayerActive = false;
      }
      _tab = i;
    });
    _tabAnim.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.current.statusBar,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: false,
        backgroundColor: AppTheme.current.bg,
        drawer: _NavDrawer(
          onDownloads: () { _scaffoldKey.currentState?.closeDrawer(); _openDownloads(); },
          onSettings: () { _scaffoldKey.currentState?.closeDrawer(); _openSettings(); },
        ),
        body: Stack(children: [
          Column(children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            _TopBar(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
            Expanded(child: IndexedStack(index: _tab, children: [
              _SitesTab(onOpenSite: _openSite, onColorExtracted: _onColorExtracted),
              _FeedTab(
                onVideoSelected: (url, video) {
                  setState(() {
                    _selectedEmbedUrl = url;
                    _selectedVideo = video;
                    _miniPlayerActive = false;
                  });
                  _switchTab(2);
                },
              ),
              ExibicaoPage(
                embedUrl: _selectedEmbedUrl,
                video: _selectedVideo,
                onClose: () => _switchTab(_previousTab),
              ),
            ])),
          ]),
          Positioned(left: 0, right: 0, bottom: safeBottom,
            child: _BottomNav(
              currentTab: _tab,
              onTabChanged: _switchTab,
              tabAnimController: _tabAnim,
            )),
          if (_miniPlayerActive && _selectedVideo != null)
            Positioned(
              left: 12, bottom: safeBottom + _kNavH + 10, right: 12,
              child: _MiniPlayer(
                video: _selectedVideo!,
                onTap: () => _switchTab(2),
                onClose: () => setState(() {
                  _miniPlayerActive = false;
                  _selectedVideo = null;
                  _selectedEmbedUrl = null;
                }),
              ),
            ),
        ]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _TopBar({required this.onMenuTap});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.divider, width: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onMenuTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.menu_rounded, color: t.icon, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        Text('PixlHub',
            style: TextStyle(color: t.text, fontSize: 20,
                fontWeight: FontWeight.w700)),
        const Spacer(),
      ]),
    );
  }
}

class _NavDrawer extends StatelessWidget {
  final VoidCallback onDownloads, onSettings;
  const _NavDrawer({required this.onDownloads, required this.onSettings});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final safeTop = MediaQuery.of(context).padding.top;
    return Drawer(
      backgroundColor: t.surface,
      child: Column(children: [
        SizedBox(height: safeTop + 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('Menu', style: TextStyle(color: t.text, fontSize: 22,
                fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 20),
        _DrawerItem(
          icon: Icons.download_rounded,
          label: 'Downloads',
          onTap: onDownloads,
        ),
        _DrawerItem(
          icon: Icons.settings_rounded,
          label: 'Configurações',
          onTap: onSettings,
        ),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, color: t.icon, size: 24),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: t.text, fontSize: 15.5,
              fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentTab;
  final void Function(int) onTabChanged;
  final AnimationController tabAnimController;
  const _BottomNav({
    required this.currentTab,
    required this.onTabChanged,
    required this.tabAnimController,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.divider, width: 0.5)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavButton(
          icon: Icons.apps_rounded,
          label: 'Sites',
          isActive: currentTab == 0,
          onTap: () => onTabChanged(0),
          animController: tabAnimController,
        ),
        _NavButton(
          icon: Icons.video_library_rounded,
          label: 'Feed',
          isActive: currentTab == 1,
          onTap: () => onTabChanged(1),
          animController: tabAnimController,
        ),
        _NavButton(
          icon: Icons.play_circle_filled_rounded,
          label: 'Exibição',
          isActive: currentTab == 2,
          onTap: () => onTabChanged(2),
          animController: tabAnimController,
        ),
      ]),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController animController;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.animController,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleController.forward().then((_) => _scaleController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final color = widget.isActive ? kPrimaryColor : t.iconSub;
    
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(widget.label,
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap, onClose;
  const _MiniPlayer({required this.video, required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(Icons.play_circle_filled_rounded, color: kPrimaryColor, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(video.title,
                  style: TextStyle(color: t.text, fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(video.sourceLabel,
                  style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ],
          )),
          GestureDetector(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.close_rounded, color: t.iconSub, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SitesTab extends StatelessWidget {
  final void Function(SiteModel) onOpenSite;
  final void Function(Color) onColorExtracted;
  const _SitesTab({required this.onOpenSite, required this.onColorExtracted});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _SitesRow(sites: _allSites, onTap: onOpenSite),
      ],
    );
  }
}

final _allSites = <SiteModel>[
  SiteModel(
    id: 'eporner',
    name: 'Eporner',
    baseUrl: 'https://www.eporner.com',
    allowedDomain: 'eporner.com',
    searchUrl: 'https://www.eporner.com/search/',
    primaryColor: const Color(0xFFE74C3C),
  ),
  SiteModel(
    id: 'pornhub',
    name: 'Pornhub',
    baseUrl: 'https://www.pornhub.com',
    allowedDomain: 'pornhub.com',
    searchUrl: 'https://www.pornhub.com/video/search?search=',
    primaryColor: const Color(0xFFFFA500),
  ),
];

class _FeedTab extends StatefulWidget {
  final void Function(String embedUrl, FeedVideo video) onVideoSelected;
  const _FeedTab({required this.onVideoSelected});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final _fetcher = FeedFetcher();
  final _videos = <FeedVideo>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final newVideos = await _fetcher.fetchMixed();
      if (mounted) setState(() {
        _videos.addAll(newVideos);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, color: t.iconSub, size: 48),
        const SizedBox(height: 12),
        Text('Erro ao carregar vídeos',
            style: TextStyle(color: t.text, fontSize: 15)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loadVideos,
          child: const Text('Tentar novamente'),
        ),
      ]));
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.all(12),
      itemCount: _videos.length + (_loading ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= _videos.length) return _FeedCardShimmer();
        return _FeedCard(
          video: _videos[i],
          onTap: () => widget.onVideoSelected(_videos[i].embedUrl, _videos[i]),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _FeedCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                video.thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: t.thumbBg,
                  child: Center(child: Icon(Icons.play_circle_outline_rounded,
                      color: t.iconSub, size: 40)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(video.title,
                  style: TextStyle(color: t.text, fontSize: 13,
                      fontWeight: FontWeight.w500, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(video.sourceLabel,
                  style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FeedCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(color: t.thumbBg),
        ),
        const SizedBox(height: 10),
        Container(height: 12, color: t.thumbBg, margin: const EdgeInsets.symmetric(horizontal: 10)),
        const SizedBox(height: 6),
        Container(height: 10, width: 80, color: t.thumbBg, margin: const EdgeInsets.only(left: 10)),
        const SizedBox(height: 10),
      ]),
    );
  }
}

enum VideoSource { eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang, bravotube, drtuber, txxx, gotporn, porndig }

String faviconForSource(VideoSource s) {
  final map = {
    VideoSource.eporner: 'https://www.eporner.com/favicon.ico',
    VideoSource.pornhub: 'https://www.pornhub.com/favicon.ico',
    VideoSource.redtube: 'https://www.redtube.com/favicon.ico',
    VideoSource.youporn: 'https://www.youporn.com/favicon.ico',
    VideoSource.xvideos: 'https://www.xvideos.com/favicon.ico',
    VideoSource.xhamster: 'https://xhamster.com/favicon.ico',
    VideoSource.spankbang: 'https://spankbang.com/favicon.ico',
    VideoSource.bravotube: 'https://www.bravotube.net/favicon.ico',
    VideoSource.drtuber: 'https://www.drtuber.com/favicon.ico',
    VideoSource.txxx: 'https://www.txxx.com/favicon.ico',
    VideoSource.gotporn: 'https://www.gotporn.com/favicon.ico',
    VideoSource.porndig: 'https://www.porndig.com/favicon.ico',
  };
  return map[s] ?? '';
}

class FeedVideo {
  final String title, thumb, embedUrl, duration, views, sourceLabel;
  final VideoSource source;
  FeedVideo({
    required this.title,
    required this.thumb,
    required this.embedUrl,
    required this.duration,
    required this.views,
    required this.sourceLabel,
    required this.source,
  });

  static const _feedTerms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
  ];
}

class FeedFetcher {
  final _rng = Random();

  Future<List<FeedVideo>> fetchMixed() async {
    final term = FeedVideo._feedTerms[_rng.nextInt(FeedVideo._feedTerms.length)];
    try {
      return await _fetchEporner(term);
    } catch (_) {
      return [];
    }
  }

  Future<List<FeedVideo>> _fetchEporner(String term) async {
    final url = 'https://www.eporner.com/api/v2/video/search/?query=$term&per_page=20&thumbsize=big&order=top-weekly&gay=0&lq=1&format=json';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception('Eporner fetch failed');
    final data = jsonDecode(res.body);
    final videos = (data['videos'] as List?) ?? [];
    return videos.map((v) {
      final id = v['id'] ?? '';
      final embedUrl = 'https://www.eporner.com/embed/$id';
      return FeedVideo(
        title: v['title'] ?? 'Sem título',
        thumb: v['default_thumb']?['src'] ?? '',
        embedUrl: embedUrl,
        duration: _formatDuration(v['length_sec']),
        views: _formatViews(v['views']),
        sourceLabel: 'Eporner',
        source: VideoSource.eporner,
      );
    }).toList();
  }

  String _formatDuration(dynamic sec) {
    if (sec == null) return '';
    final s = (sec is int) ? sec : int.tryParse(sec.toString()) ?? 0;
    final m = s ~/ 60;
    final ss = s % 60;
    return '$m:${ss.toString().padLeft(2, '0')}';
  }

  String _formatViews(dynamic v) {
    if (v == null) return '';
    final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _SitesRow extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SitesRow({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sites.length,
        itemBuilder: (_, i) => _SiteCell(site: sites[i], onTap: () => onTap(sites[i])),
      ),
    );
  }
}

class _SiteCell extends StatefulWidget {
  final SiteModel site;
  final VoidCallback onTap;
  const _SiteCell({required this.site, required this.onTap});
  @override
  State<_SiteCell> createState() => _SiteCellState();
}

class _SiteCellState extends State<_SiteCell> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 200),
        lowerBound: 0, upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 52;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SiteIconWidget(site: widget.site, size: iconSize, showShadow: true),
            const SizedBox(height: 5),
            SizedBox(
              width: iconSize + 10,
              child: Text(widget.site.name,
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppTheme.current.iconSub,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}

class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(
          id: 'free', name: title, baseUrl: url,
          allowedDomain: '', searchUrl: url, primaryColor: kPrimaryColor),
      freeNavigation: true,
    );
  }
}
