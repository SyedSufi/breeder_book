import 'dart:io';

import 'package:flutter/material.dart';

import '../db/repository.dart';
import '../models/models.dart';
import '../services/photo_store.dart';
import '../utils.dart';

Color genderColor(String gender) {
  switch (gender) {
    case 'male':
      return Colors.blue;
    case 'female':
      return Colors.pink;
    default:
      return Colors.grey;
  }
}

IconData genderIcon(String gender) {
  switch (gender) {
    case 'male':
      return Icons.male;
    case 'female':
      return Icons.female;
    default:
      return Icons.help_outline;
  }
}

/// "Budgerigar · Opaline · Male · 2y 3m"
String birdSubtitle(Bird b) {
  final parts = <String>[
    if (b.speciesName != null) b.speciesName!,
    if (b.mutationName != null) b.mutationName!,
    if (b.gender != 'unknown') cap(b.gender),
    if (ageText(b.hatchDate).isNotEmpty) ageText(b.hatchDate),
  ];
  return parts.join(' · ');
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class BirdAvatar extends StatelessWidget {
  final Bird bird;
  final double radius;

  const BirdAvatar({super.key, required this.bird, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final color = genderColor(bird.gender);
    if (PhotoStore.exists(bird.photoFile)) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(PhotoStore.pathOf(bird.photoFile!))),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(Icons.flutter_dash, color: color, size: radius * 1.1),
    );
  }
}

Future<String?> pickDateIso(BuildContext context, {String? initial}) async {
  final first = DateTime(1990);
  final last = DateTime.now().add(const Duration(days: 365));
  var init = parseIso(initial) ?? DateTime.now();
  if (init.isBefore(first)) init = first;
  if (init.isAfter(last)) init = last;
  final d = await showDatePicker(
    context: context,
    initialDate: init,
    firstDate: first,
    lastDate: last,
  );
  return d == null ? null : toIso(d);
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? label,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String okText = 'OK',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a species name + incubation days. Returns the new species id
/// (or null if cancelled).
Future<int?> addSpeciesDialog(BuildContext context, Repo repo) async {
  final nameCtrl = TextEditingController();
  final daysCtrl = TextEditingController(text: '18');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New species'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Species name'),
          ),
          TextField(
            controller: daysCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Incubation days',
              helperText: 'Used to show the expected hatch date',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  final name = nameCtrl.text.trim();
  final days = int.tryParse(daysCtrl.text.trim()) ?? 18;
  if (ok != true || name.isEmpty) return null;
  return repo.addSpecies(name, days);
}

/// Bottom sheet to pick an existing bird. [genders] limits the list
/// (e.g. ['male', 'unknown'] when choosing a father).
Future<Bird?> pickBird(
  BuildContext context, {
  required Repo repo,
  required String title,
  List<String>? genders,
  int? excludeId,
}) {
  return showModalBottomSheet<Bird>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BirdPickerSheet(
      repo: repo,
      title: title,
      genders: genders,
      excludeId: excludeId,
    ),
  );
}

class _BirdPickerSheet extends StatefulWidget {
  final Repo repo;
  final String title;
  final List<String>? genders;
  final int? excludeId;

  const _BirdPickerSheet({
    required this.repo,
    required this.title,
    this.genders,
    this.excludeId,
  });

  @override
  State<_BirdPickerSheet> createState() => _BirdPickerSheetState();
}

class _BirdPickerSheetState extends State<_BirdPickerSheet> {
  String _query = '';
  late Future<List<Bird>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Bird>> _fetch() => widget.repo.birds(
        query: _query,
        genders: widget.genders,
        excludeId: widget.excludeId,
      );

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search ring no, species, mutation',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                  _future = _fetch();
                }),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Bird>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const Center(child: Text('No matching birds'));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final b = list[i];
                      return ListTile(
                        leading: BirdAvatar(bird: b),
                        title: Text(b.label),
                        subtitle: Text(birdSubtitle(b)),
                        onTap: () => Navigator.pop(context, b),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small coloured chip used for status labels.
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const StatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

Color birdStatusColor(String status) {
  switch (status) {
    case 'breeding':
      return Colors.green;
    case 'sold':
      return Colors.orange;
    case 'dead':
      return Colors.red;
    default:
      return Colors.teal;
  }
}
