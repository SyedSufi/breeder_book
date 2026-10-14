import 'package:flutter/material.dart';

/// Motion tokens — Standard tier (300–450ms stagger, reduce-motion aware).
abstract final class AppMotion {
  static const Duration listEntrance = Duration(milliseconds: 400);
  static const Duration routeTransition = Duration(milliseconds: 250);
  static const Duration micro = Duration(milliseconds: 200);
  static const int maxStaggerItems = 12;
  static const Duration staggerStep = Duration(milliseconds: 60);

  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Soft fade page route; falls back to instant when reduce-motion is on.
  static Route<T> fadeRoute<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: routeTransition,
      reverseTransitionDuration: routeTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotionOf(context)) return child;
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

/// Staggered fade/slide entrance for the first paint of a list row.
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotionOf(context) ||
        index >= AppMotion.maxStaggerItems) {
      return child;
    }

    final delay = AppMotion.staggerStep * index;
    final total = AppMotion.listEntrance + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      // easeOutCubic — skill avoids spring overshoot on dense list/data UI.
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        final t = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
