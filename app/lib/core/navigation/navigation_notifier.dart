import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_state.dart';

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void navigateTo(NavigationRoute route, {Map<String, dynamic>? params}) {
    state = state.copyWith(currentRoute: route, routeParams: params);
  }

  void navigateToSplash() => navigateTo(NavigationRoute.splash);
  void navigateToLogin() => navigateTo(NavigationRoute.login);
  void navigateToHome() => navigateTo(NavigationRoute.home);
  void navigateToChecklist({Map<String, dynamic>? params}) =>
      navigateTo(NavigationRoute.checklist, params: params);
  void navigateToAbout() => navigateTo(NavigationRoute.about);
  void navigateToHelp() => navigateTo(NavigationRoute.help);
  void navigateToSettings() => navigateTo(NavigationRoute.settings);

  void goBack() {
    // Simple back navigation - could be enhanced with a navigation stack
    switch (state.currentRoute) {
      case NavigationRoute.login:
      case NavigationRoute.home:
        navigateToSplash();
        break;
      case NavigationRoute.checklist:
        navigateToHome();
        break;
      case NavigationRoute.about:
      case NavigationRoute.help:
      case NavigationRoute.settings:
        navigateToSplash();
        break;
      case NavigationRoute.splash:
        // Already at splash, do nothing
        break;
    }
  }
}
