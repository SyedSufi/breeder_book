import 'package:flutter/material.dart';

/// Standard padding for form / detail list bodies.
const EdgeInsets kAppScreenPadding = EdgeInsets.all(16);

class AppSectionTitle extends StatelessWidget {
  final String text;

  const AppSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class AppLoadingBody extends StatelessWidget {
  const AppLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class AppPrimarySaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const AppPrimarySaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Label + value row used in bird detail info cards.
class AppKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const AppKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
