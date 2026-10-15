import 'package:flutter/material.dart';

/// Outlined text / form field — shared chrome for all forms.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
    if (validator != null) {
      return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        enabled: enabled,
        onChanged: onChanged,
        decoration: decoration,
        validator: validator,
      );
    }
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      enabled: enabled,
      onChanged: onChanged,
      decoration: decoration,
    );
  }
}

/// Controlled dropdown for short enums (status, etc.).
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use — controlled by State
      value: value,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// Read-only form field that opens a picker screen on tap.
class PickerFormField extends StatelessWidget {
  final String label;
  final String? valueText;
  final String hint;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const PickerFormField({
    super.key,
    required this.label,
    required this.valueText,
    this.hint = 'Select…',
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = valueText != null && valueText!.isNotEmpty;

    return FormField<String>(
      key: ValueKey<String?>(valueText),
      initialValue: valueText,
      validator: validator,
      builder: (state) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            // Keep label on the outline border so it never stacks on the hint.
            isEmpty: false,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.chevron_right),
            ),
            child: Text(
              hasValue ? valueText! : hint,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: hasValue
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      },
    );
  }
}
