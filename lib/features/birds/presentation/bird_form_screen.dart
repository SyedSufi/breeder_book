import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/services/photo_store.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/helpers.dart';
import '../../../core/widgets/option_picker.dart';
import '../../../core/widgets/section_chrome.dart';
import '../../../core/widgets/select_tiles.dart';
import '../../species/presentation/species_providers.dart';
import 'birds_providers.dart';

/// Add or edit a bird.
/// - [bird] == null            -> new empty bird
/// - [bird] with id == null    -> new bird with pre-filled values (e.g. a chick)
/// - [bird] with an id         -> edit
/// Pops with the saved bird id.
class BirdFormScreen extends ConsumerStatefulWidget {
  final Bird? bird;

  const BirdFormScreen({super.key, this.bird});

  @override
  ConsumerState<BirdFormScreen> createState() => _BirdFormScreenState();
}

class _BirdFormScreenState extends ConsumerState<BirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Bird _b;

  late final TextEditingController _ring;
  late final TextEditingController _year;
  late final TextEditingController _cage;
  late final TextEditingController _notes;
  late final TextEditingController _fatherRing;
  late final TextEditingController _motherRing;

  List<Species> _species = [];
  List<Mutation> _mutations = [];
  Bird? _father;
  Bird? _mother;
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => _b.id != null;

  @override
  void initState() {
    super.initState();
    _b = widget.bird?.copy() ?? Bird(ringNo: '');
    _ring = TextEditingController(text: _b.ringNo);
    _year = TextEditingController(text: _b.ringYear?.toString() ?? '');
    _cage = TextEditingController(text: _b.cage ?? '');
    _notes = TextEditingController(text: _b.notes ?? '');
    _fatherRing = TextEditingController(text: _b.fatherRingNo ?? '');
    _motherRing = TextEditingController(text: _b.motherRingNo ?? '');
    _load();
  }

  @override
  void dispose() {
    _ring.dispose();
    _year.dispose();
    _cage.dispose();
    _notes.dispose();
    _fatherRing.dispose();
    _motherRing.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final species = await repo.species();
    final mutations = _b.speciesId == null
        ? <Mutation>[]
        : await repo.mutations(speciesId: _b.speciesId);
    final father = _b.fatherId == null ? null : await repo.getBird(_b.fatherId!);
    final mother = _b.motherId == null ? null : await repo.getBird(_b.motherId!);
    if (!mounted) return;
    setState(() {
      _species = species;
      _mutations = mutations;
      _father = father;
      _mother = mother;
      _loading = false;
    });
  }

  Future<void> _reloadMutations() async {
    final m = _b.speciesId == null
        ? <Mutation>[]
        : await ref.read(repoProvider).mutations(speciesId: _b.speciesId);
    if (!mounted) return;
    setState(() => _mutations = m);
  }

  Future<void> _addSpecies() async {
    final id = await addSpeciesDialog(context, ref.read(repoProvider));
    if (id == null) return;
    invalidateSpeciesCaches(ref);
    final species = await ref.read(repoProvider).species();
    if (!mounted) return;
    setState(() {
      _species = species;
      _b.speciesId = id;
      _b.mutationId = null;
    });
    await _reloadMutations();
  }

  Future<void> _addMutation() async {
    if (_b.speciesId == null) {
      snack(context, 'Select a species first');
      return;
    }
    final name = await promptText(context,
        title: 'New mutation', label: 'Mutation name');
    if (name == null) return;
    final id = await ref.read(repoProvider).addMutation(_b.speciesId!, name);
    invalidateSpeciesCaches(ref);
    await _reloadMutations();
    if (!mounted) return;
    setState(() => _b.mutationId = id);
  }

  String? get _speciesLabel {
    for (final s in _species) {
      if (s.id == _b.speciesId) return s.name;
    }
    return null;
  }

  String get _mutationLabel {
    if (_b.mutationId == null) return 'None / not sure';
    for (final m in _mutations) {
      if (m.id == _b.mutationId) return m.name;
    }
    return 'None / not sure';
  }

  Future<void> _pickSpecies() async {
    final picked = await pickOption<int>(
      context,
      title: 'Select species',
      selected: _b.speciesId,
      options: [
        for (final s in _species)
          if (s.id != null) SelectOption(value: s.id!, label: s.name),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _b.speciesId = picked.value;
      _b.mutationId = null;
    });
    await _reloadMutations();
  }

  Future<void> _pickMutation() async {
    if (_b.speciesId == null) {
      snack(context, 'Select a species first');
      return;
    }
    final picked = await pickOption<int?>(
      context,
      title: 'Select mutation',
      selected: _b.mutationId,
      options: [
        const SelectOption(value: null, label: 'None / not sure'),
        for (final m in _mutations)
          if (m.id != null) SelectOption(value: m.id, label: m.name),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _b.mutationId = picked.value);
  }

  Future<void> _pickParent({required bool isFather}) async {
    final picked = await pickBird(
      context,
      repo: ref.read(repoProvider),
      title: isFather ? 'Select father' : 'Select mother',
      genders: isFather ? ['male', 'unknown'] : ['female', 'unknown'],
      excludeId: _b.id,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFather) {
        _father = picked;
        _b.fatherId = picked.id;
      } else {
        _mother = picked;
        _b.motherId = picked.id;
      }
    });
  }

  void _clearParent({required bool isFather}) {
    setState(() {
      if (isFather) {
        _father = null;
        _b.fatherId = null;
      } else {
        _mother = null;
        _b.motherId = null;
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final name = await PhotoStore.pick(source);
      if (name == null || !mounted) return;
      setState(() => _b.photoFile = name);
    } catch (e) {
      if (mounted) snack(context, 'Could not get the photo: $e');
    }
  }

  String? _clean(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_b.speciesId == null) {
      snack(context, 'Please select a species');
      return;
    }

    final ring = _ring.text.trim();
    final year = int.tryParse(_year.text.trim());
    final repo = ref.read(repoProvider);

    final duplicate = await repo.ringExists(ring, year, excludeId: _b.id);
    if (duplicate) {
      if (!mounted) return;
      final ok = await confirm(
        context,
        title: 'Ring number already exists',
        message:
            'A bird with ring $ring${year == null ? '' : ' ($year)'} is already saved. Save anyway?',
        okText: 'Save anyway',
      );
      if (!ok) return;
    }

    setState(() => _saving = true);
    _b.ringNo = ring;
    _b.ringYear = year;
    _b.cage = _clean(_cage.text);
    _b.notes = _clean(_notes.text);
    _b.fatherRingNo = _b.fatherId == null ? _clean(_fatherRing.text) : null;
    _b.motherRingNo = _b.motherId == null ? _clean(_motherRing.text) : null;

    try {
      final id = await repo.saveBird(_b);
      invalidateBirdCaches(ref, birdId: id);
      if (!mounted) return;
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      snack(context, 'Could not save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit bird' : 'Add bird'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingBody()
          : Form(
              key: _formKey,
              child: ListView(
                padding: kAppScreenPadding,
                children: [
                  _photoSection(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          controller: _ring,
                          label: 'Ring / band number *',
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ring number is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: _year,
                          label: 'Ring year',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return null;
                            final n = int.tryParse(t);
                            if (n == null || n < 1950 || n > 2100) {
                              return 'e.g. 2025';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PickerFormField(
                          label: 'Species *',
                          valueText: _speciesLabel,
                          hint: 'Select species',
                          onTap: _pickSpecies,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add species',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addSpecies,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PickerFormField(
                          label: 'Mutation',
                          valueText: _mutationLabel,
                          onTap: _pickMutation,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add mutation',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addMutation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Gender'),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'male',
                        label: Text('Male'),
                        icon: Icon(Icons.male),
                      ),
                      ButtonSegment(
                        value: 'female',
                        label: Text('Female'),
                        icon: Icon(Icons.female),
                      ),
                      ButtonSegment(
                        value: 'unknown',
                        label: Text('Unknown'),
                        icon: Icon(Icons.help_outline),
                      ),
                    ],
                    selected: {_b.gender},
                    onSelectionChanged: (s) =>
                        setState(() => _b.gender = s.first),
                  ),
                  const SizedBox(height: 8),
                  AppDateTile(
                    title: 'Hatch date',
                    isoDate: _b.hatchDate,
                    icon: Icons.cake_outlined,
                    onClear: _b.hatchDate == null
                        ? null
                        : () => setState(() => _b.hatchDate = null),
                    onTap: () async {
                      final d =
                          await pickDateIso(context, initial: _b.hatchDate);
                      if (d != null && mounted) {
                        setState(() => _b.hatchDate = d);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const AppSectionTitle('Parents'),
                  BirdSelectTile(
                    title: 'Father',
                    bird: _father,
                    isMale: true,
                    subtitle: _father?.label ?? 'Not selected',
                    onClear: _father == null
                        ? null
                        : () => _clearParent(isFather: true),
                    onTap: () => _pickParent(isFather: true),
                  ),
                  if (_b.fatherId == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppTextField(
                        controller: _fatherRing,
                        label: "Father's ring no (if not in your list)",
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  BirdSelectTile(
                    title: 'Mother',
                    bird: _mother,
                    isMale: false,
                    subtitle: _mother?.label ?? 'Not selected',
                    onClear: _mother == null
                        ? null
                        : () => _clearParent(isFather: false),
                    onTap: () => _pickParent(isFather: false),
                  ),
                  if (_b.motherId == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppTextField(
                        controller: _motherRing,
                        label: "Mother's ring no (if not in your list)",
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  AppDropdownField<String>(
                    value: _b.status,
                    label: 'Status',
                    items: [
                      for (final s in kBirdStatuses)
                        DropdownMenuItem<String>(
                          value: s,
                          child: Text(cap(s)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _b.status = v ?? 'active'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _cage,
                    label: 'Cage / location',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _notes,
                    label: 'Notes',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  AppPrimarySaveButton(
                    label: 'Save bird',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _photoSection() {
    final hasPhoto = PhotoStore.exists(_b.photoFile);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: hasPhoto
                ? Image.file(
                    File(PhotoStore.pathOf(_b.photoFile!)),
                    fit: BoxFit.cover,
                  )
                : Builder(
                    builder: (context) {
                      final scheme = Theme.of(context).colorScheme;
                      return Container(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        child: Icon(
                          Icons.photo_outlined,
                          size: 36,
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              if (_b.photoFile != null)
                TextButton(
                  onPressed: () => setState(() => _b.photoFile = null),
                  child: const Text('Remove'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
