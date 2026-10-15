import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import 'pill_chrome.dart';

export 'form_fields.dart' show PickerFormField;

/// One row in [OptionPickerScreen].
class SelectOption<T> {
  final T value;
  final String label;

  const SelectOption({required this.value, required this.label});
}

/// Distinguishes "user picked an option" (even if [value] is null) from cancel.
class OptionPick<T> {
  final T value;
  const OptionPick(this.value);
}

/// Opens a full-screen list. Returns null if the user backs out without
/// choosing; returns [OptionPick] when they tap a row (including a null value
/// such as "None / not sure").
Future<OptionPick<T>?> pickOption<T>(
  BuildContext context, {
  required String title,
  required List<SelectOption<T>> options,
  T? selected,
  bool searchable = true,
  String searchHint = 'Search …',
}) {
  return Navigator.of(context).push<OptionPick<T>>(
    AppMotion.fadeRoute(
      OptionPickerScreen<T>(
        title: title,
        options: options,
        selected: selected,
        searchable: searchable,
        searchHint: searchHint,
      ),
    ),
  );
}

/// Full-screen single-choice list. Highlights [selected] when reopened.
class OptionPickerScreen<T> extends StatefulWidget {
  final String title;
  final List<SelectOption<T>> options;
  final T? selected;
  final bool searchable;
  final String searchHint;

  const OptionPickerScreen({
    super.key,
    required this.title,
    required this.options,
    this.selected,
    this.searchable = true,
    this.searchHint = 'Search …',
  });

  @override
  State<OptionPickerScreen<T>> createState() => _OptionPickerScreenState<T>();
}

class _OptionPickerScreenState<T> extends State<OptionPickerScreen<T>> {
  String _query = '';

  List<SelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (o.label.toLowerCase().contains(q)) o,
    ];
  }

  bool _isSelected(SelectOption<T> o) => o.value == widget.selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: PillSearchField(
                hintText: widget.searchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No matches'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final o = list[i];
                      final selected = _isSelected(o);
                      return ListTile(
                        title: Text(o.label),
                        selected: selected,
                        selectedTileColor:
                            scheme.primaryContainer.withValues(alpha: 0.45),
                        trailing: selected
                            ? Icon(Icons.check, color: scheme.primary)
                            : null,
                        onTap: () =>
                            Navigator.pop(context, OptionPick<T>(o.value)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
