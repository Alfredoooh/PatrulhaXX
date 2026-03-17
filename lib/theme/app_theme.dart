import 'package:flutter/material.dart';
import '../services/theme_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// AppTheme — Sistema completo de cores do YouTube
// Uso:  final t = AppTheme.current;
// ═════════════════════════════════════════════════════════════════════════════
class AppTheme {
  final bool isDark;
  const AppTheme._(this.isDark);

  static AppTheme get current => AppTheme._(ThemeService.instance.isDark);

  // ══════════════════════════════════════════════════════════════════════════
  // FUNDOS PRINCIPAIS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Background principal da app (tela de fundo)
  Color get bg => isDark 
    ? const Color(0xFF0F0F0F)  // YouTube dark background
    : const Color(0xFFF9F9F9); // YouTube light background

  /// Background do AppBar/TopBar
  Color get appBar => isDark 
    ? const Color(0xFF0F0F0F) 
    : const Color(0xFFFFFFFF);

  /// Background de cards/containers principais
  Color get card => isDark 
    ? const Color(0xFF212121)  // YouTube dark card
    : const Color(0xFFFFFFFF); // YouTube light card

  /// Background alternativo para cards (hover, selected)
  Color get cardAlt => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFF2F2F2);

  /// Background de cards em destaque/elevated
  Color get cardElevated => isDark 
    ? const Color(0xFF282828) 
    : const Color(0xFFFFFFFF);

  /// Background do bottom navigation
  Color get navBg => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background de popups/dialogs
  Color get popup => isDark 
    ? const Color(0xFF282828) 
    : const Color(0xFFFFFFFF);

  /// Background de bottom sheets
  Color get sheet => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background do drawer/menu lateral
  Color get drawerBg => isDark 
    ? const Color(0xFF0F0F0F) 
    : const Color(0xFFFFFFFF);

  /// Background para chips/tags
  Color get chipBg => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFF2F2F2);

  /// Background hover/pressed para botões e items
  Color get hoverBg => isDark 
    ? const Color(0xFF3D3D3D) 
    : const Color(0xFFE5E5E5);

  /// Background de overlay (ex: sobre vídeo)
  Color get overlay => isDark 
    ? const Color(0xCC000000)  // 80% black
    : const Color(0xCC000000);

  /// Background de scrim (fundo escurecido atrás de modals)
  Color get scrim => isDark 
    ? const Color(0x99000000)  // 60% black
    : const Color(0x99000000);

  // ══════════════════════════════════════════════════════════════════════════
  // TEXTOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Texto principal (títulos, corpo)
  Color get text => isDark 
    ? const Color(0xFFF1F1F1)  // YouTube dark text
    : const Color(0xFF030303); // YouTube light text

  /// Texto secundário (subtítulos, metadados)
  Color get textSub => isDark 
    ? const Color(0xFFAAAAAA)  // YouTube dark secondary
    : const Color(0xFF606060); // YouTube light secondary

  /// Texto terciário (hints, placeholders)
  Color get textHint => isDark 
    ? const Color(0xFF717171) 
    : const Color(0xFF909090);

  /// Texto desabilitado
  Color get textDisabled => isDark 
    ? const Color(0xFF4D4D4D) 
    : const Color(0xFFBDBDBD);

  /// Texto invertido (branco em dark, preto em light)
  Color get textInverted => isDark 
    ? const Color(0xFF030303) 
    : const Color(0xFFF1F1F1);

  /// Texto em botões primários
  Color get textOnAccent => const Color(0xFF030303);

  /// Texto de erro
  Color get textError => isDark 
    ? const Color(0xFFFF6B6B) 
    : const Color(0xFFCC0000);

  /// Texto de sucesso
  Color get textSuccess => isDark 
    ? const Color(0xFF3EA6FF) 
    : const Color(0xFF065FD4);

  /// Texto de avisos
  Color get textWarning => isDark 
    ? const Color(0xFFFFD600) 
    : const Color(0xFFF9AB00);

  /// Texto sobre thumbnails (ex: duração do vídeo)
  Color get textOnThumb => const Color(0xFFFFFFFF);

  /// Texto do drawer
  Color get drawerText => text;

  // ══════════════════════════════════════════════════════════════════════════
  // ÍCONES
  // ══════════════════════════════════════════════════════════════════════════

  /// Ícones principais
  Color get icon => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  /// Ícones secundários
  Color get iconSub => isDark 
    ? const Color(0xFFAAAAAA) 
    : const Color(0xFF606060);

  /// Ícones terciários (muito sutis)
  Color get iconHint => isDark 
    ? const Color(0xFF717171) 
    : const Color(0xFF909090);

  /// Ícones desabilitados
  Color get iconDisabled => isDark 
    ? const Color(0xFF4D4D4D) 
    : const Color(0xFFBDBDBD);

  /// Ícone ativo (selecionado)
  Color get iconActive => isDark 
    ? const Color(0xFFFFFFFF) 
    : const Color(0xFF030303);

  /// Ícone sobre thumbnails
  Color get thumbIcon => isDark 
    ? const Color(0xFFFFFFFF) 
    : const Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // BORDAS E DIVISORES
  // ══════════════════════════════════════════════════════════════════════════

  /// Divisor padrão (linhas entre items)
  Color get divider => isDark 
    ? const Color(0xFF3F3F3F) 
    : const Color(0xFFE5E5E5);

  /// Borda padrão
  Color get border => isDark 
    ? const Color(0xFF3F3F3F) 
    : const Color(0xFFCCCCCC);

  /// Borda sutil (quase invisível)
  Color get borderSubtle => isDark 
    ? const Color(0x1AFFFFFF)  // 10% white
    : const Color(0x14000000); // 8% black

  /// Borda do navigation
  Color get navBorder => isDark 
    ? Colors.transparent 
    : const Color(0xFFE5E5E5);

  /// Borda de inputs em focus
  Color get borderFocused => isDark 
    ? const Color(0xFF3EA6FF) 
    : const Color(0xFF065FD4);

  /// Borda de erro
  Color get borderError => isDark 
    ? const Color(0xFFFF6B6B) 
    : const Color(0xFFCC0000);

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Item ativo na bottom nav
  Color get navActive => isDark 
    ? const Color(0xFFFFFFFF) 
    : const Color(0xFF030303);

  /// Item inativo na bottom nav
  Color get navInactive => isDark 
    ? const Color(0xFF717171) 
    : const Color(0xFF606060);

  /// Indicador da bottom nav (linha/dot)
  Color get navIndicator => isDark 
    ? const Color(0xFFFFFFFF) 
    : const Color(0xFF030303);

  // ══════════════════════════════════════════════════════════════════════════
  // INPUTS (TextField, SearchBar, etc)
  // ══════════════════════════════════════════════════════════════════════════

  /// Background de inputs
  Color get inputBg => isDark 
    ? const Color(0xFF121212) 
    : const Color(0xFFF0F0F0);

  /// Background de input em focus
  Color get inputBgFocused => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Borda de inputs
  Color get inputBorder => isDark 
    ? const Color(0xFF303030) 
    : const Color(0xFFCCCCCC);

  /// Texto em inputs
  Color get inputText => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  /// Placeholder/hint em inputs
  Color get inputHint => isDark 
    ? const Color(0xFF717171) 
    : const Color(0xFF909090);

  /// Cursor em inputs
  Color get inputCursor => isDark 
    ? const Color(0xFF3EA6FF) 
    : const Color(0xFF065FD4);

  // ══════════════════════════════════════════════════════════════════════════
  // THUMBNAILS E FEED
  // ══════════════════════════════════════════════════════════════════════════

  /// Background de thumbnails carregando
  Color get thumbBg => isDark 
    ? const Color(0xFF1C1C1C) 
    : const Color(0xFFE5E5E5);

  /// Background de preview badges (LIVE, NEW, etc)
  Color get badgeBg => isDark 
    ? const Color(0xCC000000)  // 80% black
    : const Color(0xCC000000);

  /// Texto em badges
  Color get badgeText => const Color(0xFFFFFFFF);

  /// Background da duração do vídeo
  Color get durationBg => const Color(0xCC000000);

  /// Texto da duração
  Color get durationText => const Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // MINI PLAYER
  // ══════════════════════════════════════════════════════════════════════════

  /// Background do mini player
  Color get miniPlayerBg => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background dos controles do mini player
  Color get miniPlayerControls => isDark 
    ? const Color(0x33FFFFFF)  // 20% white
    : const Color(0x14000000); // 8% black

  // ══════════════════════════════════════════════════════════════════════════
  // SKELETON LOADING / SHIMMER
  // ══════════════════════════════════════════════════════════════════════════

  /// Cores do shimmer effect
  List<Color> get shimmer => isDark
    ? const [
        Color(0xFF1C1C1C),
        Color(0xFF2C2C2C),
        Color(0xFF1C1C1C),
      ]
    : const [
        Color(0xFFE5E5E5),
        Color(0xFFF2F2F2),
        Color(0xFFE5E5E5),
      ];

  /// Cor base do skeleton
  Color get skeletonBase => isDark 
    ? const Color(0xFF1C1C1C) 
    : const Color(0xFFE5E5E5);

  /// Cor de highlight do skeleton
  Color get skeletonHighlight => isDark 
    ? const Color(0xFF2C2C2C) 
    : const Color(0xFFF2F2F2);

  // ══════════════════════════════════════════════════════════════════════════
  // PLAYER DE VÍDEO
  // ══════════════════════════════════════════════════════════════════════════

  /// Background do player
  Color get playerBg => const Color(0xFF000000);

  /// Background dos controles do player
  Color get playerControlsBg => const Color(0x66000000);  // 40% black

  /// Texto/ícones dos controles
  Color get playerControls => const Color(0xFFFFFFFF);

  /// Barra de progresso (parte assistida)
  Color get playerProgressWatched => const Color(0xFFFF0000);  // YouTube red

  /// Barra de progresso (buffer)
  Color get playerProgressBuffer => const Color(0x80FFFFFF);  // 50% white

  /// Barra de progresso (não assistido)
  Color get playerProgressUnwatched => const Color(0x40FFFFFF);  // 25% white

  /// Background da timeline
  Color get playerTimelineBg => const Color(0x40FFFFFF);

  /// Dot de scrubbing
  Color get playerScrubber => const Color(0xFFFF0000);

  // ══════════════════════════════════════════════════════════════════════════
  // BOTÕES
  // ══════════════════════════════════════════════════════════════════════════

  /// Background de botão primário
  Color get buttonPrimary => isDark 
    ? const Color(0xFF3EA6FF)  // YouTube blue
    : const Color(0xFF065FD4);

  /// Background de botão secundário
  Color get buttonSecondary => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFF2F2F2);

  /// Background de botão de perigo (delete, etc)
  Color get buttonDanger => isDark 
    ? const Color(0xFFFF6B6B) 
    : const Color(0xFFCC0000);

  /// Texto em botão primário
  Color get buttonPrimaryText => const Color(0xFF030303);

  /// Texto em botão secundário
  Color get buttonSecondaryText => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  /// Background de botão desabilitado
  Color get buttonDisabled => isDark 
    ? const Color(0xFF1C1C1C) 
    : const Color(0xFFE5E5E5);

  /// Texto de botão desabilitado
  Color get buttonDisabledText => isDark 
    ? const Color(0xFF4D4D4D) 
    : const Color(0xFFBDBDBD);

  // ══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Background da seção de comentários
  Color get commentsBg => isDark 
    ? const Color(0xFF0F0F0F) 
    : const Color(0xFFF9F9F9);

  /// Background de um comentário individual
  Color get commentCard => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background de resposta (nested comment)
  Color get commentReply => isDark 
    ? const Color(0xFF1C1C1C) 
    : const Color(0xFFF2F2F2);

  /// Botão de like ativo
  Color get likeActive => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  /// Botão de dislike ativo
  Color get dislikeActive => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  // ══════════════════════════════════════════════════════════════════════════
  // CHANNEL PAGE
  // ══════════════════════════════════════════════════════════════════════════

  /// Background do header do canal
  Color get channelHeaderBg => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background das tabs do canal
  Color get channelTabsBg => isDark 
    ? const Color(0xFF0F0F0F) 
    : const Color(0xFFFFFFFF);

  /// Indicador da tab ativa
  Color get channelTabIndicator => isDark 
    ? const Color(0xFFFFFFFF) 
    : const Color(0xFF030303);

  /// Botão "Subscribe" (não inscrito)
  Color get subscribeBg => isDark 
    ? const Color(0xFFCC0000)  // YouTube red
    : const Color(0xFFCC0000);

  /// Botão "Subscribed"
  Color get subscribedBg => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFF2F2F2);

  /// Texto do botão subscribe
  Color get subscribeText => const Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICAÇÕES E BADGES
  // ══════════════════════════════════════════════════════════════════════════

  /// Badge de notificação (número)
  Color get notificationBadge => const Color(0xFFCC0000);

  /// Texto em badge de notificação
  Color get notificationBadgeText => const Color(0xFFFFFFFF);

  /// Background de notificação não lida
  Color get notificationUnread => isDark 
    ? const Color(0xFF1C1C1C) 
    : const Color(0xFFF0F0F0);

  /// Background de notificação lida
  Color get notificationRead => isDark 
    ? const Color(0xFF0F0F0F) 
    : const Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // PREMIUM / MEMBROS
  // ══════════════════════════════════════════════════════════════════════════

  /// Badge de membro (YouTube Member)
  Color get memberBadge => const Color(0xFF3EA6FF);

  /// Badge de verificado (checkmark)
  Color get verifiedBadge => const Color(0xFFAAAAAA);

  /// Background de conteúdo premium
  Color get premiumBg => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFFFF8E1);

  /// Ícone premium
  Color get premiumIcon => const Color(0xFFFFD600);

  // ══════════════════════════════════════════════════════════════════════════
  // FILTROS E CHIPS
  // ══════════════════════════════════════════════════════════════════════════

  /// Chip selecionado
  Color get chipSelected => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  /// Texto em chip selecionado
  Color get chipSelectedText => isDark 
    ? const Color(0xFF030303) 
    : const Color(0xFFFFFFFF);

  /// Chip não selecionado
  Color get chipUnselected => isDark 
    ? const Color(0xFF272727) 
    : const Color(0xFFF2F2F2);

  /// Texto em chip não selecionado
  Color get chipUnselectedText => isDark 
    ? const Color(0xFFF1F1F1) 
    : const Color(0xFF030303);

  // ══════════════════════════════════════════════════════════════════════════
  // PESQUISA
  // ══════════════════════════════════════════════════════════════════════════

  /// Background da barra de pesquisa
  Color get searchBg => isDark 
    ? const Color(0xFF121212) 
    : const Color(0xFFF0F0F0);

  /// Borda da barra de pesquisa
  Color get searchBorder => isDark 
    ? const Color(0xFF303030) 
    : const Color(0xFFCCCCCC);

  /// Background de pesquisa em foco
  Color get searchBgFocused => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Background de sugestões de pesquisa
  Color get searchSuggestionBg => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFFFFFFF);

  /// Item de sugestão em hover
  Color get searchSuggestionHover => isDark 
    ? const Color(0xFF3D3D3D) 
    : const Color(0xFFF2F2F2);

  // ══════════════════════════════════════════════════════════════════════════
  // PLAYLISTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Background do overlay de playlist
  Color get playlistOverlay => const Color(0xCC000000);

  /// Ícone de playlist
  Color get playlistIcon => const Color(0xFFFFFFFF);

  /// Contador de vídeos na playlist
  Color get playlistCount => const Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // LIVE STREAMING
  // ══════════════════════════════════════════════════════════════════════════

  /// Badge "LIVE"
  Color get liveBadge => const Color(0xFFCC0000);

  /// Texto do badge LIVE
  Color get liveBadgeText => const Color(0xFFFFFFFF);

  /// Contador de viewers ao vivo
  Color get liveViewers => isDark 
    ? const Color(0xFFAAAAAA) 
    : const Color(0xFF606060);

  // ══════════════════════════════════════════════════════════════════════════
  // DESCRIÇÃO E METADADOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Background da descrição expandida
  Color get descriptionBg => isDark 
    ? const Color(0xFF212121) 
    : const Color(0xFFF2F2F2);

  /// Links na descrição
  Color get descriptionLink => isDark 
    ? const Color(0xFF3EA6FF) 
    : const Color(0xFF065FD4);

  /// Timestamp clicável
  Color get timestampLink => isDark 
    ? const Color(0xFF3EA6FF) 
    : const Color(0xFF065FD4);

  // ══════════════════════════════════════════════════════════════════════════
  // STATUS BAR
  // ══════════════════════════════════════════════════════════════════════════

  /// Brightness da status bar
  Brightness get statusBar => isDark 
    ? Brightness.light 
    : Brightness.dark;

  // ══════════════════════════════════════════════════════════════════════════
  // CORES DE DESTAQUE E ACCENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Cor principal de destaque (YouTube brand)
  static const Color accent = Color(0xFFFF0000);  // YouTube Red

  /// Cor secundária (YouTube Blue para links e ações)
  static const Color accentBlue = Color(0xFF3EA6FF);  // Dark mode blue
  static const Color accentBlueDark = Color(0xFF065FD4);  // Light mode blue

  /// Cor de erro
  static const Color error = Color(0xFFCC0000);

  /// Cor de sucesso
  static const Color success = Color(0xFF00C853);

  /// Cor de aviso
  static const Color warning = Color(0xFFF9AB00);

  /// Cor de informação
  static const Color info = Color(0xFF3EA6FF);

  // ══════════════════════════════════════════════════════════════════════════
  // CORES ESPECIAIS
  // ══════════════════════════════════════════════════════════════════════════

  /// Sombra padrão
  Color get shadow => isDark 
    ? const Color(0x80000000)  // 50% black
    : const Color(0x1A000000); // 10% black

  /// Sombra elevada
  Color get shadowElevated => isDark 
    ? const Color(0xCC000000)  // 80% black
    : const Color(0x33000000); // 20% black

  /// Ripple effect color
  Color get ripple => isDark 
    ? const Color(0x1AFFFFFF)  // 10% white
    : const Color(0x14000000); // 8% black

  /// Splash color para interações
  Color get splash => isDark 
    ? const Color(0x33FFFFFF)  // 20% white
    : const Color(0x14000000); // 8% black

  /// Highlight color
  Color get highlight => isDark 
    ? const Color(0x1AFFFFFF) 
    : const Color(0x0A000000);
}

// ═════════════════════════════════════════════════════════════════════════════
// Widget que reconstrói automaticamente quando o tema muda
// ═════════════════════════════════════════════════════════════════════════════
class AppThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AppTheme) builder;
  const AppThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ThemeService.instance,
    builder: (ctx, _) => builder(ctx, AppTheme.current),
  );
}
