import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:serviced/serviced.dart';

Widget _defaultLoginBuilder(BuildContext context, List<AuthMethod> methods) =>
    LoginScreen(authMethods: methods);

class ArcaneAuthConfig {
  final bool allowAnonymous;
  final Future<void> Function(UserMeta user)? onBind;
  final Future<void> Function()? onUnbind;
  final bool autoLink;
  final List<SocialSignInSiteConfig> signInConfigs;
  final List<AuthMethod> authMethods;
  final Widget Function(BuildContext, List<AuthMethod>) loginScreenBuilder;

  const ArcaneAuthConfig({
    this.allowAnonymous = false,
    this.onBind,
    this.onUnbind,
    this.autoLink = true,
    this.signInConfigs = const [],
    this.authMethods = const [],
    this.loginScreenBuilder = _defaultLoginBuilder,
  });
}

class _ArcaneAuthInitializer extends StatefulWidget {
  final PylonBuilder builder;
  final ArcaneAuthConfig config;

  const _ArcaneAuthInitializer({
    super.key,
    required this.builder,
    this.config = const ArcaneAuthConfig(),
  });

  @override
  State<_ArcaneAuthInitializer> createState() => _ArcaneAuthInitializerState();
}

class _ArcaneAuthInitializerState extends State<_ArcaneAuthInitializer> {
  late Future<void> _work;

  @override
  void initState() {
    services().register<AuthService>(
        () => AuthService(
              signInConfigs: widget.config.signInConfigs,
              onBind: widget.config.onBind,
              onUnbind: widget.config.onUnbind,
              allowAnonymous: widget.config.allowAnonymous,
              autoLink: widget.config.autoLink,
            ),
        lazy: false);
    _work = services().waitForStartup();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.config.authMethods.isNotEmpty,
        'No auth methods provided. Provide at least one auth method in AuthenticatedArcaneApp.autoConfig.authMethods');

    return _work.build((_) => Builder(builder: widget.builder),
        loading: FillScreen(
            child: Center(
          child: CircularProgressIndicator(),
        )));
  }
}

class AuthenticatedArcaneApp extends StatelessWidget {
  final ArcaneAuthConfig authConfig;
  final GlobalKey<NavigatorState>? navigatorKey;
  final AdaptiveScaling? scaling;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final String initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final NotificationListenerCallback<NavigationNotification>?
      onNavigationNotification;
  final List<NavigatorObserver>? navigatorObservers;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final RouterConfig<Object>? routerConfig;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final Color? color;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final bool debugShowMaterialGrid;
  final bool disableBrowserContextMenu;
  final ArcaneTheme? theme;

  const AuthenticatedArcaneApp({
    super.key,
    required this.authConfig,
    this.theme,
    this.navigatorKey,
    this.home,
    Map<String, WidgetBuilder> this.routes = const <String, WidgetBuilder>{},
    this.initialRoute = "/",
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.onNavigationNotification,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scaling,
    this.disableBrowserContextMenu = true,
  })  : routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null,
        routerConfig = null;

  const AuthenticatedArcaneApp.router({
    super.key,
    required this.authConfig,
    this.theme,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scaling,
    this.disableBrowserContextMenu = true,
  })  : assert(routerDelegate != null || routerConfig != null),
        navigatorObservers = null,
        navigatorKey = null,
        onGenerateRoute = null,
        home = null,
        onGenerateInitialRoutes = null,
        onUnknownRoute = null,
        routes = null,
        initialRoute = "/";

  @override
  Widget build(BuildContext context) => _ArcaneAuthInitializer(
      config: authConfig,
      builder: (context) => Pylon<ArcaneAuthProvider>(
          value: svc<AuthService>(),
          builder: (context) => svc<AuthService>().stream.build(
              (auth) => !$signedIn
                  ? ArcaneApp(
                      home: authConfig.loginScreenBuilder(
                          context, authConfig.authMethods),
                      title: title,
                      theme: theme,
                      builder: builder,
                      key: key,
                      scaling: scaling,
                      shortcuts: shortcuts,
                      color: color,
                      localizationsDelegates: localizationsDelegates,
                      actions: actions,
                      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                      debugShowMaterialGrid: debugShowMaterialGrid,
                      disableBrowserContextMenu: disableBrowserContextMenu,
                      locale: locale,
                      localeListResolutionCallback:
                          localeListResolutionCallback,
                      localeResolutionCallback: localeResolutionCallback,
                      onGenerateTitle: onGenerateTitle,
                      restorationScopeId: restorationScopeId,
                      showPerformanceOverlay: showPerformanceOverlay,
                      showSemanticsDebugger: showSemanticsDebugger,
                      supportedLocales: supportedLocales,
                    )
                  : usesRouter
                      ? ArcaneApp.router(
                          backButtonDispatcher: backButtonDispatcher,
                          routeInformationParser: routeInformationParser,
                          routeInformationProvider: routeInformationProvider,
                          routerConfig: routerConfig,
                          routerDelegate: routerDelegate,
                          title: title,
                          theme: theme,
                          onNavigationNotification: onNavigationNotification,
                          builder: builder,
                          key: key,
                          scaling: scaling,
                          shortcuts: shortcuts,
                          color: color,
                          localizationsDelegates: localizationsDelegates,
                          actions: actions,
                          debugShowCheckedModeBanner:
                              debugShowCheckedModeBanner,
                          debugShowMaterialGrid: debugShowMaterialGrid,
                          disableBrowserContextMenu: disableBrowserContextMenu,
                          locale: locale,
                          localeListResolutionCallback:
                              localeListResolutionCallback,
                          localeResolutionCallback: localeResolutionCallback,
                          onGenerateTitle: onGenerateTitle,
                          restorationScopeId: restorationScopeId,
                          showPerformanceOverlay: showPerformanceOverlay,
                          showSemanticsDebugger: showSemanticsDebugger,
                          supportedLocales: supportedLocales,
                        )
                      : ArcaneApp(
                          home: home,
                          title: title,
                          theme: theme,
                          navigatorKey: navigatorKey,
                          routes: routes ?? const <String, WidgetBuilder>{},
                          initialRoute: initialRoute,
                          onGenerateRoute: onGenerateRoute,
                          onGenerateInitialRoutes: onGenerateInitialRoutes,
                          onUnknownRoute: onUnknownRoute,
                          onNavigationNotification: onNavigationNotification,
                          navigatorObservers:
                              navigatorObservers ?? const <NavigatorObserver>[],
                          builder: builder,
                          key: key,
                          scaling: scaling,
                          shortcuts: shortcuts,
                          color: color,
                          localizationsDelegates: localizationsDelegates,
                          actions: actions,
                          debugShowCheckedModeBanner:
                              debugShowCheckedModeBanner,
                          debugShowMaterialGrid: debugShowMaterialGrid,
                          disableBrowserContextMenu: disableBrowserContextMenu,
                          locale: locale,
                          localeListResolutionCallback:
                              localeListResolutionCallback,
                          localeResolutionCallback: localeResolutionCallback,
                          onGenerateTitle: onGenerateTitle,
                          restorationScopeId: restorationScopeId,
                          showPerformanceOverlay: showPerformanceOverlay,
                          showSemanticsDebugger: showSemanticsDebugger,
                          supportedLocales: supportedLocales,
                        ),
              loading: SizedBox.shrink())));

  bool get usesRouter => routerDelegate != null || routerConfig != null;
}
