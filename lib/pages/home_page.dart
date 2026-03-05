import 'package:flutter/material.dart';
import 'webview_page.dart';

// ─── Modelo de cada app ───────────────────────────────────────────────────────
class AppItem {
  final String name;
  final String url;
  final String iconAsset; // PNG 512x512 circular em assets/icons/

  const AppItem({
    required this.name,
    required this.url,
    required this.iconAsset,
  });
}

// ─── Lista dos 8 apps ─────────────────────────────────────────────────────────
const List<AppItem> apps = [
  // ── Linha de cima ──
  AppItem(
    name: 'YouCube',
    url: 'https://www.youcube.com',
    iconAsset: 'assets/icons/youcube.png',
  ),
  AppItem(
    name: 'MySelf',
    url: 'https://www.myself.com',
    iconAsset: 'assets/icons/myself.png',
  ),
  AppItem(
    name: 'US News',
    url: 'https://www.us-news.com',
    iconAsset: 'assets/icons/us_news.png',
  ),
  AppItem(
    name: "Today's War",
    url: 'https://www.todays-war.com',
    iconAsset: 'assets/icons/todays_war.png',
  ),

  // ── Linha de baixo ── (substitua nome/url/ícone quando tiver os links)
  AppItem(
    name: 'App 5',
    url: 'https://www.exemplo5.com',
    iconAsset: 'assets/icons/app5.png',
  ),
  AppItem(
    name: 'App 6',
    url: 'https://www.exemplo6.com',
    iconAsset: 'assets/icons/app6.png',
  ),
  AppItem(
    name: 'App 7',
    url: 'https://www.exemplo7.com',
    iconAsset: 'assets/icons/app7.png',
  ),
  AppItem(
    name: 'App 8',
    url: 'https://www.exemplo8.com',
    iconAsset: 'assets/icons/app8.png',
  ),
];

// ─── Home Page ────────────────────────────────────────────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openApp(BuildContext context, AppItem app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(title: app.name, url: app.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────────
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),

          // ── Overlay escuro suave para legibilidade ────────────────────────
          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          // ── Conteúdo ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Logo / título do app
                const Text(
                  'patrulhaXX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Color(0xFFFF1493),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Grid: linha de cima (apps 0-3) ───────────────────────
                _AppRow(items: apps.sublist(0, 4), onTap: _openApp),

                const SizedBox(height: 32),

                // ── Grid: linha de baixo (apps 4-7) ──────────────────────
                _AppRow(items: apps.sublist(4, 8), onTap: _openApp),

                const Spacer(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de 4 ícones ────────────────────────────────────────────────────────
class _AppRow extends StatelessWidget {
  final List<AppItem> items;
  final void Function(BuildContext, AppItem) onTap;

  const _AppRow({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((app) => _AppIcon(app: app, onTap: () => onTap(context, app)))
            .toList(),
      ),
    );
  }
}

// ─── Ícone circular individual ────────────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  final AppItem app;
  final VoidCallback onTap;

  const _AppIcon({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double iconSize = MediaQuery.of(context).size.width * 0.18;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone circular com sombra
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1493).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                app.iconAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFFF1493),
                  child: Center(
                    child: Text(
                      app.name[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: iconSize * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Nome do app
          SizedBox(
            width: iconSize + 8,
            child: Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
