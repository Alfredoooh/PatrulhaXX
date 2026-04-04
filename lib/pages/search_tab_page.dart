import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animations/animations.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'search_page.dart';

class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Pesquisa',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const _SearchTrigger(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchTrigger  (tab pesquisa — 50 px)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger();

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 420),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: AppTheme.current.bg,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: t.inputBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: t.inputBorder),
          ),
          child: Row(children: [
            const SizedBox(width: 16),
            SvgPicture.asset('assets/icons/svg/search.svg',
                width: 18, height: 18,
                colorFilter:
                    ColorFilter.mode(t.inputHint, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text('Pesquisar vídeos, sites...',
                style: TextStyle(color: t.inputHint, fontSize: 15)),
          ]),
        ),
      ),
      openBuilder: (_, __) => const SearchPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchTriggerCompact — usado na appbar da home (exportado)
// ─────────────────────────────────────────────────────────────────────────────
class SearchTriggerCompact extends StatelessWidget {
  const SearchTriggerCompact({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 420),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: AppTheme.current.bg,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: t.inputBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: t.inputBorder),
          ),
          child: Row(children: [
            const SizedBox(width: 12),
            SvgPicture.asset('assets/icons/svg/search.svg',
                width: 16, height: 16,
                colorFilter:
                    ColorFilter.mode(t.inputHint, BlendMode.srcIn)),
            const SizedBox(width: 8),
            Text('Pesquisar...',
                style: TextStyle(color: t.inputHint, fontSize: 13.5)),
          ]),
        ),
      ),
      openBuilder: (_, __) => const SearchPage(),
    );
  }
}
