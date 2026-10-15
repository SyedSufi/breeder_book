import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/pill_chrome.dart';

/// Floating capsule nav: dark biophilic bar + brand-green active chip.
class FloatingPillNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingPillDestination> destinations;

  const FloatingPillNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  static const Color bar = PillChrome.surface;
  static const Color barBorder = AppColors.darkSecondary;
  static const Color activeFill = PillChrome.activeFill;
  static const Color activeInk = PillChrome.activeInk;
  static const Color inactiveIcon = PillChrome.inactiveInk;
  static const Color inactiveWell = Color(0x33FFFFFF);

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotionOf(context);
    final duration = reduce ? Duration.zero : AppMotion.micro;

    return Semantics(
      container: true,
      label: 'Main navigation',
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bar,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: barBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              if (i == selectedIndex)
                Expanded(
                  child: _ActivePill(
                    destination: destinations[i],
                    duration: duration,
                    onTap: () => onDestinationSelected(i),
                  ),
                )
              else
                _InactiveCircle(
                  destination: destinations[i],
                  duration: duration,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class FloatingPillDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const FloatingPillDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
}

class _ActivePill extends StatelessWidget {
  final FloatingPillDestination destination;
  final Duration duration;
  final VoidCallback onTap;

  const _ActivePill({
    required this.destination,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = destination.selectedIcon ?? destination.icon;

    return Semantics(
      button: true,
      selected: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(27),
          splashColor: FloatingPillNav.activeFill.withValues(alpha: 0.3),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: FloatingPillNav.activeFill,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: FloatingPillNav.activeInk),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FloatingPillNav.activeInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InactiveCircle extends StatelessWidget {
  final FloatingPillDestination destination;
  final Duration duration;
  final VoidCallback onTap;

  const _InactiveCircle({
    required this.destination,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: false,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: FloatingPillNav.inactiveWell,
              shape: BoxShape.circle,
            ),
            child: Icon(
              destination.icon,
              size: 22,
              color: FloatingPillNav.inactiveIcon,
            ),
          ),
        ),
      ),
    );
  }
}
