import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _hasQuery = false;
  late final AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final has = _searchController.text.trim().isNotEmpty;
      if (has != _hasQuery) setState(() => _hasQuery = has);
    });
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  void _openSite(SiteModel site) {
    final query = _hasQuery ? _searchController.text.trim() : null;
    Navigator.of(context).push(_smoothRoute(
      BrowserPage(site: site, initialQuery: query),
    ));
  }

  Route _smoothRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, anim, __) => page,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
          // ── Overlay escuro para legibilidade ─────────────────────────
          Container(color: Colors.black.withOpacity(0.55)),
          // ── Conteúdo ─────────────────────────────────────────────────
          FadeTransition(
        opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onDownloads: () => Navigator.push(
                  context,
                  _smoothRoute(const DownloadsPage()),
                ),
                onSettings: () => Navigator.push(
                  context,
                  _smoothRoute(const SettingsPage()),
                ),
              ),
              const SizedBox(height: 20),
              _SearchBar(
                controller: _searchController,
                hasQuery: _hasQuery,
                onClear: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
              if (_hasQuery) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Toca num site para pesquisar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Expanded(
                child: _SitesGrid(
                  sites: kSites,
                  onTap: _openSite,
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onDownloads;
  final VoidCallback onSettings;

  const _TopBar({required this.onDownloads, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          _IconBtn(icon: Ionicons.download_outline, onTap: onDownloads),
          const Spacer(),
          Column(
            children: [
              const Text(
                'patrulhaXX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(icon: Ionicons.settings_outline, onTap: onSettings),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

// ── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasQuery;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hasQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasQuery
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Ionicons.search_outline,
              color: Colors.white.withOpacity(hasQuery ? 0.7 : 0.35),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                cursorColor: Colors.white70,
              ),
            ),
            if (hasQuery) ...[
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Ionicons.close_circle,
                    color: Colors.white.withOpacity(0.4),
                    size: 18,
                  ),
                ),
              ),
            ] else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

// ── Sites grid ───────────────────────────────────────────────────────────────
class _SitesGrid extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;

  const _SitesGrid({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 2 linhas de 5
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Row(sites: sites.sublist(0, 5), onTap: onTap),
          const SizedBox(height: 28),
          _Row(sites: sites.sublist(5, 10), onTap: onTap),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;

  const _Row({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sites.map((s) => _SiteCell(site: s, onTap: () => onTap(s))).toList(),
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

class _SiteCellState extends State<_SiteCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = MediaQuery.of(context).size.width * 0.14;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiteIconWidget(site: widget.site, size: iconSize),
            const SizedBox(height: 7),
            SizedBox(
              width: iconSize + 8,
              child: Text(
                widget.site.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
