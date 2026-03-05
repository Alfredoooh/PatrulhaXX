import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back_outline,
              color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Definições',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _Section(title: 'Privacidade', children: [
            _Tile(
              icon: Ionicons.refresh_outline,
              iconColor: const Color(0xFF4A9EFF),
              title: 'Recarregar ícones',
              subtitle: 'Limpa e baixa novamente os favicons',
              onTap: () async {
                await FaviconService.instance.clearAll();
                await FaviconService.instance.preloadAll();
                if (context.mounted) {
                  _snack(context, 'Ícones recarregados');
                }
              },
            ),
            _Tile(
              icon: Ionicons.trash_outline,
              iconColor: Colors.redAccent,
              title: 'Limpar downloads',
              subtitle: 'Apaga todos os ficheiros baixados',
              onTap: () => _confirmClearDownloads(context),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Sobre', children: [
            _Tile(
              icon: Ionicons.shield_checkmark_outline,
              iconColor: Colors.greenAccent,
              title: 'patrulhaXX',
              subtitle: 'Versão 1.0.0 · Navegação privada',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1C1C1C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmClearDownloads(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Limpar downloads?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Todos os vídeos e imagens serão apagados permanentemente.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.white70))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final items = DownloadService.instance.items.toList();
                    for (final item in items) {
                      await DownloadService.instance.delete(item.id);
                    }
                    if (context.mounted) _snack(context, 'Downloads limpos');
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: Text('Apagar tudo',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600))),
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

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Ionicons.chevron_forward_outline,
                  color: Colors.white12, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
