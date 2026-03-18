import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — sistema de cores YouTube completo (dark + light)
// Uso:  final t = AppTheme.current;
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  final bool isDark;
  const AppTheme._(this.isDark);

  static AppTheme get current => AppTheme._(ThemeService.instance.isDark);

  // ════════════════════════════════════════════════════════════════════════════
  // CORES ESTÁTICAS (iguais em dark e light)
  // ════════════════════════════════════════════════════════════════════════════

  // ── YouTube Brand ──────────────────────────────────────────────────────────
  static const Color ytRed           = Color(0xFFFF0000); // vermelho principal
  static const Color ytRedDark       = Color(0xFFCC0000); // vermelho escuro (hover/press)
  static const Color ytRedLight      = Color(0xFFFF4444); // vermelho suave
  static const Color ytRedDeep       = Color(0xFFBF0000); // vermelho profundo
  static const Color ytWhite         = Color(0xFFFFFFFF);
  static const Color ytBlack         = Color(0xFF000000);

  // ── Live / Shorts ──────────────────────────────────────────────────────────
  static const Color live            = Color(0xFFFF0000); // badge "AO VIVO"
  static const Color liveText        = Color(0xFFFFFFFF);
  static const Color shortsRed       = Color(0xFFFF0033); // Shorts ícone
  static const Color shortsRedDark   = Color(0xFFCC0029);

  // ── Membership / Sponsor ──────────────────────────────────────────────────
  static const Color membership      = Color(0xFF1565C0); // azul membership
  static const Color membershipLight = Color(0xFF1976D2);
  static const Color sponsor         = Color(0xFF00695C); // verde sponsor

  // ── Super Chat / Sticker ──────────────────────────────────────────────────
  static const Color superChatBlue   = Color(0xFF1565C0);
  static const Color superChatCyan   = Color(0xFF0097A7);
  static const Color superChatGreen  = Color(0xFF00897B);
  static const Color superChatYellow = Color(0xFFF9A825);
  static const Color superChatOrange = Color(0xFFEF6C00);
  static const Color superChatPink   = Color(0xFFC62828);
  static const Color superChatRed    = Color(0xFFB71C1C);

  // ── Progress / Seek Bar ───────────────────────────────────────────────────
  static const Color progressPlayed  = Color(0xFFFF0000); // parte assistida
  static const Color progressBuffer  = Color(0xFF909090); // buffer carregado
  static const Color progressBg      = Color(0xFF535353); // fundo da barra
  static const Color progressThumb   = Color(0xFFFF0000); // bolinha

  // ── Badges de qualidade ───────────────────────────────────────────────────
  static const Color badge4K         = Color(0xFF4CAF50);
  static const Color badgeHD         = Color(0xFF2196F3);
  static const Color badgeSDR        = Color(0xFF9E9E9E);
  static const Color badgeHDR        = Color(0xFFFFC107);
  static const Color badge360        = Color(0xFF9C27B0);
  static const Color badgeCC         = Color(0xFFFFFFFF); // legenda

  // ── Links ─────────────────────────────────────────────────────────────────
  static const Color link            = Color(0xFF3EA6FF); // azul link (ambos modos)
  static const Color linkVisited     = Color(0xFF9575CD);

  // ── Verificado / Check ────────────────────────────────────────────────────
  static const Color verified        = Color(0xFFAAAAAA); // check canal verificado
  static const Color verifiedPremium = Color(0xFFFFD600); // check premium/oficial

  // ── Notificação ───────────────────────────────────────────────────────────
  static const Color notifBadge      = Color(0xFFFF0000);
  static const Color notifBadgeText  = Color(0xFFFFFFFF);

  // ── Anúncio / Ad ──────────────────────────────────────────────────────────
  static const Color adBadge         = Color(0xFFFFD700); // badge "Anúncio"
  static const Color adBadgeText     = Color(0xFF000000);
  static const Color adSkipBtn       = Color(0xFF212121); // botão "Pular"
  static const Color adSkipText      = Color(0xFFFFFFFF);

  // ── Legendas / Subtitles ──────────────────────────────────────────────────
  static const Color captionBg       = Color(0xBF000000); // fundo legenda (75% opaco)
  static const Color captionText     = Color(0xFFFFFFFF);

  // ── Erro / Aviso / Sucesso ────────────────────────────────────────────────
  static const Color error           = Color(0xFFFF4444);
  static const Color errorDark       = Color(0xFFCC0000);
  static const Color warning         = Color(0xFFFFC107);
  static const Color warningDark     = Color(0xFFF57F17);
  static const Color success         = Color(0xFF4CAF50);
  static const Color successDark     = Color(0xFF2E7D32);
  static const Color info            = Color(0xFF3EA6FF);

  // ════════════════════════════════════════════════════════════════════════════
  // CORES DINÂMICAS (mudam com dark/light)
  // ════════════════════════════════════════════════════════════════════════════

  // ── Fundos principais ─────────────────────────────────────────────────────
  Color get bg           => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get bgSecondary  => isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2);
  Color get bgTertiary   => isDark ? const Color(0xFF212121) : const Color(0xFFE5E5E5);
  Color get bgQuaternary => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD9D9D9);

  // ── Superfícies / Cards ───────────────────────────────────────────────────
  Color get surface      => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get surfaceAlt   => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9F9F9);
  Color get card         => isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF);
  Color get cardHover    => isDark ? const Color(0xFF272727) : const Color(0xFFF0F0F0);
  Color get cardPressed  => isDark ? const Color(0xFF303030) : const Color(0xFFE8E8E8);
  Color get cardAlt      => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
  Color get cardSelected => isDark ? const Color(0xFF263238) : const Color(0xFFE3F2FD);

  // ── AppBar / TopBar ───────────────────────────────────────────────────────
  Color get appBar       => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get appBarBorder => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Color get navBg        => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get navBorder    => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
  Color get navActive    => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get navInactive  => isDark ? const Color(0xFFAAAAAA) : const Color(0xFF606060);
  Color get navIndicator => isDark ? const Color(0xFF303030) : const Color(0xFFEEEEEE);

  // ── Side Navigation / Drawer ──────────────────────────────────────────────
  Color get drawerBg          => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get drawerItemBg      => Colors.transparent;
  Color get drawerItemHover   => isDark ? const Color(0xFF272727) : const Color(0xFFF2F2F2);
  Color get drawerItemActive  => isDark ? const Color(0xFF303030) : const Color(0xFFE8E8E8);
  Color get drawerDivider     => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
  Color get drawerText        => text;
  Color get drawerHeader      => isDark ? const Color(0xFF181818) : const Color(0xFFF9F9F9);

  // ── Texto ─────────────────────────────────────────────────────────────────
  Color get text         => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get textSecondary=> isDark ? const Color(0xFFAAAAAA) : const Color(0xFF606060);
  Color get textTertiary => isDark ? const Color(0xFF717171) : const Color(0xFF909090);
  Color get textHint     => isDark ? const Color(0xFF535353) : const Color(0xFFBDBDBD);
  Color get textDisabled => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get textOnAccent => const Color(0xFFFFFFFF);
  Color get textInvert   => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get textSub      => textSecondary; // alias compatibilidade
  Color get textHintAlt  => textTertiary;  // alias compatibilidade

  // ── Estado vazio / placeholder ────────────────────────────────────────────
  Color get emptyIcon    => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get emptyText    => isDark ? const Color(0xFF717171) : const Color(0xFF909090);
  Color get emptyLinkText=> isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4);
  // ── Ícones ────────────────────────────────────────────────────────────────
  Color get icon         => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get iconSub      => isDark ? const Color(0xFFAAAAAA) : const Color(0xFF606060);
  Color get iconTertiary => isDark ? const Color(0xFF717171) : const Color(0xFF909090);
  Color get iconDisabled => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get iconOnDark   => const Color(0xFFFFFFFF);

  // ── Bordas / Divisores ────────────────────────────────────────────────────
  Color get divider      => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
  Color get dividerSoft  => isDark ? const Color(0xFF272727) : const Color(0xFFEEEEEE);
  Color get border       => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get borderSoft   => isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.black.withOpacity(0.06);
  Color get borderFocus  => ytRed;

  // ── Input / Search Bar ────────────────────────────────────────────────────
  Color get inputBg       => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  Color get inputBorder   => isDark ? const Color(0xFF303030) : const Color(0xFFCCCCCC);
  Color get inputBorderFocus => ytRed;
  Color get inputText     => text;
  Color get inputHint     => textHint;
  Color get inputIconBg   => isDark ? const Color(0xFF303030) : const Color(0xFFF2F2F2);
  Color get inputCursor   => ytRed;
  Color get inputSelection=> ytRed.withOpacity(0.30);

  // ── Chip / Filtro / Pill ──────────────────────────────────────────────────
  Color get chipBg        => isDark ? const Color(0xFF272727) : const Color(0xFFE8E8E8);
  Color get chipBgActive  => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get chipText      => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get chipTextActive=> isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get chipBorder    => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get chipBorderActive => Colors.transparent;

  // ── Botões ────────────────────────────────────────────────────────────────
  // Primário (vermelho)
  Color get btnPrimary        => ytRed;
  Color get btnPrimaryHover   => ytRedDark;
  Color get btnPrimaryText    => const Color(0xFFFFFFFF);
  Color get btnPrimaryPressed => ytRedDeep;

  // Secundário (Subscribe escuro)
  Color get btnSecondary      => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);
  Color get btnSecondaryText  => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get btnSecondaryHover => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF272727);

  // Terciário / Ghost
  Color get btnGhost          => isDark
      ? Colors.white.withOpacity(0.10)
      : Colors.black.withOpacity(0.06);
  Color get btnGhostHover     => isDark
      ? Colors.white.withOpacity(0.16)
      : Colors.black.withOpacity(0.10);
  Color get btnGhostText      => text;

  // Like / Dislike
  Color get btnLike           => isDark ? const Color(0xFF272727) : const Color(0xFFEEEEEE);
  Color get btnLikeActive     => isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4);
  Color get btnLikeActiveText => isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4);
  Color get btnLikeText       => text;

  // Inscrever-se
  Color get btnSubscribe      => ytRed;
  Color get btnSubscribeText  => const Color(0xFFFFFFFF);
  Color get btnSubscribed     => isDark ? const Color(0xFF272727) : const Color(0xFFEEEEEE);
  Color get btnSubscribedText => text;

  // Notificação de sino
  Color get btnBell           => isDark ? const Color(0xFF272727) : const Color(0xFFEEEEEE);
  Color get btnBellText       => text;

  // ── Overlay / Scrim ───────────────────────────────────────────────────────
  Color get overlay          => Colors.black.withOpacity(0.70);
  Color get overlayLight     => Colors.black.withOpacity(0.40);
  Color get scrim            => Colors.black.withOpacity(0.50);
  Color get popupScrim       => Colors.black.withOpacity(0.60);

  // ── Popup / BottomSheet / Dialog ─────────────────────────────────────────
  Color get popup            => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get popupBorder      => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);
  Color get sheet            => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get sheetHandle      => isDark ? const Color(0xFF535353) : const Color(0xFFCCCCCC);
  Color get dialogBg         => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get dialogBarrier    => Colors.black.withOpacity(0.60);

  // ── Tooltip ───────────────────────────────────────────────────────────────
  Color get tooltipBg        => isDark ? const Color(0xFF616161) : const Color(0xFF212121);
  Color get tooltipText      => const Color(0xFFFFFFFF);

  // ── Snackbar / Toast ──────────────────────────────────────────────────────
  Color get toastBg          => isDark ? const Color(0xFF323232) : const Color(0xFF323232);
  Color get toastText        => const Color(0xFFFFFFFF);
  Color get toastAction      => ytRed;

  // ── Thumbnail / Feed ──────────────────────────────────────────────────────
  Color get thumbBg          => isDark ? const Color(0xFF272727) : const Color(0xFFE8E8E8);
  Color get thumbIcon        => isDark ? Colors.white24 : Colors.black26;
  Color get thumbOverlay     => Colors.black.withOpacity(0.30);
  Color get thumbDuration    => const Color(0xFF000000);
  Color get thumbDurationText=> const Color(0xFFFFFFFF);
  Color get thumbShimmer1    => isDark ? const Color(0xFF272727) : const Color(0xFFE8E8E8);
  Color get thumbShimmer2    => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF2F2F2);

  // ── Avatar / Channel Art ──────────────────────────────────────────────────
  Color get avatarBg         => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFCCCCCC);
  Color get avatarText       => const Color(0xFFFFFFFF);
  Color get avatarBorder     => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get channelBannerBg  => isDark ? const Color(0xFF272727) : const Color(0xFFE8E8E8);

  // ── Player ────────────────────────────────────────────────────────────────
  Color get playerBg            => const Color(0xFF000000);
  Color get playerControls      => const Color(0xFFFFFFFF);
  Color get playerControlsBg    => Colors.black.withOpacity(0.60);
  Color get playerProgressPlayed=> ytRed;
  Color get playerProgressBuffer=> const Color(0xFF909090);
  Color get playerProgressBg    => const Color(0xFF535353);
  Color get playerProgressThumb => ytRed;
  Color get playerTimestamp     => const Color(0xFFFFFFFF);
  Color get playerTimestampBg   => Colors.black.withOpacity(0.60);
  Color get playerQualityBadge  => const Color(0xFF212121);
  Color get playerQualityText   => const Color(0xFFFFFFFF);
  Color get playerEndscreenBg   => Colors.black.withOpacity(0.70);

  // ── Mini Player ───────────────────────────────────────────────────────────
  Color get miniPlayerBg        => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get miniPlayerProgress  => ytRed;
  Color get miniPlayerDivider   => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);

  // ── Comments ──────────────────────────────────────────────────────────────
  Color get commentBg       => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get commentHighlight=> isDark ? const Color(0xFF1A2733) : const Color(0xFFE8F4FE);
  Color get commentPinned   => isDark ? const Color(0xFF1F2820) : const Color(0xFFE8F5E9);
  Color get commentHeart    => ytRed;
  Color get commentAuthorBg => isDark ? const Color(0xFF272727) : const Color(0xFFEEEEEE);

  // ── Hashtag / Tags ────────────────────────────────────────────────────────
  Color get hashtagText  => isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4);

  // ── Chapter / Seção ──────────────────────────────────────────────────────
  Color get chapterBg       => isDark ? const Color(0xFF272727) : const Color(0xFFF2F2F2);
  Color get chapterActive   => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);
  Color get chapterText     => text;
  Color get chapterTime     => textSecondary;

  // ── Playlist ──────────────────────────────────────────────────────────────
  Color get playlistBg      => isDark ? const Color(0xFF181818) : const Color(0xFFF9F9F9);
  Color get playlistHeader  => isDark ? const Color(0xFF212121) : const Color(0xFFEEEEEE);
  Color get playlistActive  => isDark ? const Color(0xFF272727) : const Color(0xFFE8E8E8);
  Color get playlistNumber  => textSecondary;

  // ── Shorts ────────────────────────────────────────────────────────────────
  Color get shortsBg        => const Color(0xFF000000);
  Color get shortsText      => const Color(0xFFFFFFFF);
  Color get shortsIcon      => const Color(0xFFFFFFFF);
  Color get shortsProgress  => shortsRed;
  Color get shortsLikeActive=> const Color(0xFFFF4E45);

  // ── Studio / Creator ──────────────────────────────────────────────────────
  Color get studioBg        => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9);
  Color get studioCard      => isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);
  Color get studioHeader    => isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2);
  Color get studioAccent    => ytRed;
  Color get studioPublished => const Color(0xFF4CAF50);
  Color get studioDraft     => const Color(0xFFFFC107);
  Color get studioPrivate   => isDark ? const Color(0xFF717171) : const Color(0xFF909090);

  // ── Analytics / Gráficos ─────────────────────────────────────────────────
  Color get chartLine       => ytRed;
  Color get chartFill       => ytRed.withOpacity(0.15);
  Color get chartGrid       => isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
  Color get chartLabel      => textSecondary;
  Color get chartTooltipBg  => isDark ? const Color(0xFF3D3D3D) : const Color(0xFF212121);
  Color get chartBar        => ytRed;
  Color get chartBarAlt     => isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4);

  // ── Skeleton / Shimmer ────────────────────────────────────────────────────
  List<Color> get shimmer => isDark
      ? const [Color(0xFF272727), Color(0xFF3D3D3D), Color(0xFF272727)]
      : const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Color(0xFFE8E8E8)];

  // ── Sombras ───────────────────────────────────────────────────────────────
  Color get shadow      => isDark ? Colors.black.withOpacity(0.60) : Colors.black.withOpacity(0.15);
  Color get shadowSoft  => isDark ? Colors.black.withOpacity(0.40) : Colors.black.withOpacity(0.08);
  Color get shadowHard  => Colors.black.withOpacity(0.80);

  // ── Status Bar / System UI ────────────────────────────────────────────────
  Brightness get statusBar       => isDark ? Brightness.light : Brightness.dark;
  Color get statusBarColor       => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  Color get systemNavBar         => isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF);
  SystemUiOverlayStyle get systemUiOverlay => isDark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: systemNavBar,
          systemNavigationBarIconBrightness: Brightness.light,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: systemNavBar,
          systemNavigationBarIconBrightness: Brightness.dark,
        );

  // ── Gradientes ────────────────────────────────────────────────────────────
  LinearGradient get gradientBrand => const LinearGradient(
    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  LinearGradient get gradientThumb => LinearGradient(
    colors: [Colors.transparent, Colors.black.withOpacity(0.70)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  LinearGradient get gradientFade => LinearGradient(
    colors: [bg.withOpacity(0.0), bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  LinearGradient get gradientFadeH => LinearGradient(
    colors: [bg.withOpacity(0.0), bg],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  LinearGradient get gradientBanner => LinearGradient(
    colors: [isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE3F2FD), bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── MaterialTheme builder ──────────────────────────────────────────────────
  ThemeData get themeData => ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: ytRed,
      onPrimary: Colors.white,
      primaryContainer: ytRedDark,
      onPrimaryContainer: Colors.white,
      secondary: isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF263238) : const Color(0xFFE3F2FD),
      onSecondaryContainer: isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4),
      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF1F2820) : const Color(0xFFE8F5E9),
      onTertiaryContainer: success,
      error: error,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFEBEE),
      onErrorContainer: error,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: cardAlt,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: divider,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: isDark ? Colors.white : const Color(0xFF0F0F0F),
      onInverseSurface: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      inversePrimary: ytRedLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: appBar,
      foregroundColor: icon,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: icon),
      systemOverlayStyle: systemUiOverlay,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: navBg,
      selectedItemColor: navActive,
      unselectedItemColor: navInactive,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBg,
      indicatorColor: navIndicator,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: navActive);
        }
        return IconThemeData(color: navInactive);
      }),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: drawerBg,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBg,
      hintStyle: TextStyle(color: inputHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: inputBorderFocus, width: 2),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: inputCursor,
      selectionColor: inputSelection,
      selectionHandleColor: ytRed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: chipBg,
      selectedColor: chipBgActive,
      labelStyle: TextStyle(color: chipText, fontSize: 14),
      side: BorderSide(color: chipBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: toastBg,
      contentTextStyle: TextStyle(color: toastText),
      actionTextColor: toastAction,
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tooltipBg,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(color: tooltipText, fontSize: 12),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ytRed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ytRed,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnPrimary,
        foregroundColor: btnPrimaryText,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFF3EA6FF) : const Color(0xFF065FD4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: icon),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: popup,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: popupBorder),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sheet,
      dragHandleColor: sheetHandle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );

}

// ─────────────────────────────────────────────────────────────────────────────
// Widget que reconstrói automaticamente quando o tema muda
// ─────────────────────────────────────────────────────────────────────────────
class AppThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AppTheme) builder;
  const AppThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (ctx, _) => builder(ctx, AppTheme.current),
      );
}
