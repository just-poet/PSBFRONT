import 'package:flutter/material.dart';

/// A plain cross-fade route. No slide, no zoom — the splash brief is explicit
/// that the hand-off must not move the frame.
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 400),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
            child: child,
          ),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );
}
