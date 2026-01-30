import 'package:flutter/material.dart';

class RouterService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?>? push<T>(Widget page, {Duration duration = const Duration(milliseconds: 400)}) {
    return navigatorKey.currentState?.push<T>(_fadeRoute(page, duration: duration));
  }

  void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }

  Route<T> _fadeRoute<T>(Widget page, {required Duration duration}) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

final router = RouterService();
