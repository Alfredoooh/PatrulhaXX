import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/download_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

// ── Helpers de tema reactivos ─────────────────────────────────────────────────
AppTheme get _t          => AppTheme.current;
Color get _bg            => _t.bg;
Color get _textPrimary   => _t.text;
Color get _textSub       => _t.textSub;
Color get _textHint      => _t.textHint;
Color get _divider       => _t.divider;
Color get _iconSub       => _t.iconSub;
Color get _accent        => AppTheme.accent;

const _svgDownload =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">'
    '<g><path d="M210.731,386.603c24.986,25.002,65.508,25.015,90.51,0.029'
    'c0.01-0.01,0.019-0.019,0.029-0.029l68.501-68.501'
    'c7.902-8.739,7.223-22.23-1.516-30.132c-8.137-7.357-20.527-7.344-28.649,0.03'
    'l-62.421,62.443l0.149-329.109C277.333,9.551,267.782,0,256,0l0,0'
    'c-11.782,0-21.333,9.551-21.333,21.333l-0.192,328.704L172.395,288'
    'c-8.336-8.33-21.846-8.325-30.176,0.011c-8.33,8.336-8.325,21.846,0.011,30.176'
    'L210.731,386.603z"/>'
    '<path d="M490.667,341.333L490.667,341.333c-11.782,0-21.333,9.551-21.333,21.333V448'
    'c0,11.782-9.551,21.333-21.333,21.333H64c-11.782,0-21.333-9.551-21.333-21.333'
    'v-85.333c0-11.782-9.551-21.333-21.333-21.333l0,0C9.551,341.333,0,350.885,0,362.667V448'
    'c0,35.346,28.654,64,64,64h384c35.346,0,64-28.654,64-64v-85.333'
    'C512,350.885,502.449,341.333,490.667,341.333z"/></g></svg>';

const _svgClose =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2" '
    'stroke-linecap="round"/></svg>';

// ─────────────────────────────────────────────────────────────────────────────
// DownloadListPage
// ─────────────────────────────────────────────────────────────────────────────
class DownloadListPage extends StatelessWidget {
  const DownloadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _t.statusBar,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: ListenableBuilder(
            listenable: DownloadService.instance,
            builder: (context, _) {
              final active = DownloadService.instance.activeList;

              return Column(children: [
                SizedBox(height: topPad),

                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: _t.isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: _textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Downloads em curso',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (active.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          active.length > 9 ? '9+' : '${active.length}',
                          // sempre branco — texto sobre fundo vermelho
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ]),
                ),

                Divider(color: _divider, height: 1),

                Expanded(
                  child: active.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.string(_svgDownload,
                                  width: 48, height: 48,
                                  colorFilter: ColorFilter.mode(
                                      _textPrimary.withOpacity(0.12),
                                      BlendMode.srcIn)),
                              const SizedBox(height: 14),
                              Text('Nenhum download em curso',
                                  style: TextStyle(
                                      color: _textHint, fontSize: 13.5)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: active.length,
                          itemBuilder: (_, i) =>
                              _ActiveDownloadCard(item: active[i]),
                        ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

// ─── Card de download activo ──────────────────────────────────────────────────
class _ActiveDownloadCard extends StatelessWidget {
  final ActiveDownload item;
  const _ActiveDownloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder aqui para reagir a mudanças de tema dentro do card
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 120, height: 68,
              child: item.thumbUrl != null
                  ? Image.network(item.thumbUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder())
                  : _thumbPlaceholder(),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
                const SizedBox(height: 6),

                ValueListenableBuilder<DownloadStatus>(
                  valueListenable: item.status,
                  builder: (_, status, __) {
                    if (status == DownloadStatus.done) {
                      return Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF34C759), size: 14),
                        const SizedBox(width: 5),
                        Text('Concluído',
                            style: TextStyle(color: _textSub, fontSize: 11)),
                      ]);
                    }
                    if (status == DownloadStatus.error) {
                      return Row(children: [
                        const Icon(Icons.error_rounded,
                            color: Color(0xFFFF3B30), size: 14),
                        const SizedBox(width: 5),
                        Text('Erro',
                            style: TextStyle(color: _textSub, fontSize: 11)),
                      ]);
                    }
                    if (status == DownloadStatus.cancelled) {
                      return Row(children: [
                        Icon(Icons.cancel_rounded,
                            color: _textHint, size: 14),
                        const SizedBox(width: 5),
                        Text('Cancelado',
                            style: TextStyle(color: _textHint, fontSize: 11)),
                      ]);
                    }
                    // downloading
                    return ValueListenableBuilder<double>(
                      valueListenable: item.progress,
                      builder: (_, p, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: p > 0 ? p : null,
                              minHeight: 3,
                              backgroundColor: _t.isDark
                                  ? Colors.white12
                                  : Colors.black.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(_accent),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p > 0
                                ? '${(p * 100).toStringAsFixed(0)}%'
                                : 'A iniciar...',
                            style: TextStyle(color: _textHint, fontSize: 10.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Botão cancelar
          GestureDetector(
            onTap: () => DownloadService.instance.cancel(item.id),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, left: 8),
              child: SvgPicture.string(_svgClose,
                  width: 18, height: 18,
                  colorFilter: ColorFilter.mode(_iconSub, BlendMode.srcIn)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: _t.card,
        child: Center(
          child: Icon(Icons.video_file_rounded, color: _iconSub, size: 28),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DownloadListBadge — badge para usar no botão de acesso à lista
// ─────────────────────────────────────────────────────────────────────────────
class DownloadListBadge extends StatelessWidget {
  final Widget child;
  const DownloadListBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DownloadService.instance,
      builder: (_, __) {
        final count = DownloadService.instance.activeCount;
        return Stack(clipBehavior: Clip.none, children: [
          child,
          if (count > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,   // sempre branco sobre vermelho
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
