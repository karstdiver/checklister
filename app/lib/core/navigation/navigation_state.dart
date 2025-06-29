enum NavigationRoute { splash, login, home, checklist, about, help, settings }

class NavigationState {
  final NavigationRoute currentRoute;
  final Map<String, dynamic>? routeParams;

  const NavigationState({
    this.currentRoute = NavigationRoute.splash,
    this.routeParams,
  });

  NavigationState copyWith({
    NavigationRoute? currentRoute,
    Map<String, dynamic>? routeParams,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      routeParams: routeParams ?? this.routeParams,
    );
  }

  String get routeName {
    switch (currentRoute) {
      case NavigationRoute.splash:
        return '/';
      case NavigationRoute.login:
        return '/login';
      case NavigationRoute.home:
        return '/home';
      case NavigationRoute.checklist:
        return '/checklist';
      case NavigationRoute.about:
        return '/about';
      case NavigationRoute.help:
        return '/help';
      case NavigationRoute.settings:
        return '/settings';
    }
  }
}
