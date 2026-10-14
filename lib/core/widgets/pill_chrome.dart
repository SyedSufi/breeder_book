import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Shared dark + lime chrome used by floating nav, search, and filter pills
/// (reference: Supplement Library / sample pill nav).
abstract final class PillChrome {
  static const Color surface = Color(0xFF3E4059);
  static const Color surfaceDeep = Color(0xFF2B2D45);
  static const Color border = Color(0xFFB8B9D0);
  static const Color activeFill = Color(0xFFA4D166);
  static const Color activeInk = Color(0xFF1A1B2E);
  static const Color inactiveFill = Color(0xFF4A4C66);
  static const Color inactiveInk = Color(0xFFFFFFFF);
  static const Color hint = Color(0xFFA0A2B8);
  static const Color icon = Color(0xFFE8E9F2);
}

/// Pill-shaped search field matching the reference screenshot.
class PillSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const PillSearchField({
    super.key,
    this.hintText = 'Search ...',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: PillChrome.surfaceDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PillChrome.border, width: 1.2),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: PillChrome.inactiveInk,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: PillChrome.activeFill,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search,
            color: PillChrome.icon,
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: PillChrome.hint,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of capsule filter pills (lime active / muted inactive).
class PillFilterBar extends StatelessWidget {
  final List<PillFilterOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const PillFilterBar({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final opt = options[i];
          final selected = opt.id == selectedId;
          return PillFilterChip(
            label: opt.label,
            selected: selected,
            onTap: () => onSelected(opt.id),
          );
        },
      ),
    );
  }
}

class PillFilterOption {
  final String? id;
  final String label;

  const PillFilterOption({required this.id, required this.label});
}

class PillFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PillFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotionOf(context);
    final duration = reduce ? Duration.zero : AppMotion.micro;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? PillChrome.activeFill : PillChrome.inactiveFill,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? PillChrome.activeInk : PillChrome.inactiveInk,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
