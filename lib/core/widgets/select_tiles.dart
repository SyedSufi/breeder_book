import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils.dart';
import 'helpers.dart';

/// Shared bird row for forms / detail (avatar, title, subtitle, chevron).
class BirdSelectTile extends StatelessWidget {
  final String title;
  final Bird? bird;
  final String? subtitle;
  final bool isMale;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool showChevronWhenEmpty;
  final EdgeInsetsGeometry contentPadding;

  const BirdSelectTile({
    super.key,
    required this.title,
    required this.bird,
    this.subtitle,
    this.isMale = true,
    this.onTap,
    this.onClear,
    this.showChevronWhenEmpty = true,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Convenience for pair form rows.
  factory BirdSelectTile.pairing({
    Key? key,
    required bool male,
    required Bird? bird,
    required VoidCallback onTap,
  }) {
    return BirdSelectTile(
      key: key,
      title: male ? 'Male' : 'Female',
      bird: bird,
      isMale: male,
      subtitle: bird == null
          ? 'Tap to select'
          : '${bird.label}  ${birdSubtitle(bird)}',
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gender = isMale ? 'male' : 'female';
    final color = genderColor(gender);
    final hasBird = bird != null;

    final Widget leading = hasBird
        ? BirdAvatar(bird: bird!)
        : CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isMale ? Icons.male : Icons.female,
              color: color,
            ),
          );

    Widget? trailing;
    if (onClear != null && hasBird) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      );
    } else if (onTap != null && (hasBird || showChevronWhenEmpty)) {
      trailing = const Icon(Icons.chevron_right);
    }

    final sub = subtitle?.trim();
    return ListTile(
      contentPadding: contentPadding,
      leading: leading,
      title: Text(title),
      subtitle: (sub == null || sub.isEmpty) ? null : Text(sub),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Date row that opens a date picker via [onTap].
class AppDateTile extends StatelessWidget {
  final String title;
  final String? isoDate;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const AppDateTile({
    super.key,
    required this.title,
    required this.isoDate,
    this.icon = Icons.event,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(showDate(isoDate)),
      trailing: isoDate == null || onClear == null
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
      onTap: onTap,
    );
  }
}
