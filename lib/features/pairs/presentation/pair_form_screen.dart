import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/helpers.dart';
import '../../../core/widgets/section_chrome.dart';
import '../../../core/widgets/select_tiles.dart';
import 'pairs_providers.dart';

/// Create or edit a breeding pair. Pops with the saved pair id.
class PairFormScreen extends ConsumerStatefulWidget {
  final Pair? pair;

  const PairFormScreen({super.key, this.pair});

  @override
  ConsumerState<PairFormScreen> createState() => _PairFormScreenState();
}

class _PairFormScreenState extends ConsumerState<PairFormScreen> {
  late Pair _p;
  Bird? _male;
  Bird? _female;
  late final TextEditingController _cage;
  late final TextEditingController _notes;
  bool _loading = true;

  bool get _isEdit => _p.id != null;

  @override
  void initState() {
    super.initState();
    final src = widget.pair;
    _p = Pair(
      id: src?.id,
      maleId: src?.maleId,
      femaleId: src?.femaleId,
      cage: src?.cage,
      startDate: src?.startDate ?? todayIso(),
      endDate: src?.endDate,
      status: src?.status ?? 'active',
      notes: src?.notes,
    );
    _cage = TextEditingController(text: _p.cage ?? '');
    _notes = TextEditingController(text: _p.notes ?? '');
    _load();
  }

  @override
  void dispose() {
    _cage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final male = _p.maleId == null ? null : await repo.getBird(_p.maleId!);
    final female =
        _p.femaleId == null ? null : await repo.getBird(_p.femaleId!);
    if (!mounted) return;
    setState(() {
      _male = male;
      _female = female;
      _loading = false;
    });
  }

  Future<void> _pick({required bool male}) async {
    final b = await pickBird(
      context,
      repo: ref.read(repoProvider),
      title: male ? 'Select male' : 'Select female',
      genders: male ? ['male', 'unknown'] : ['female', 'unknown'],
    );
    if (b == null || !mounted) return;
    setState(() {
      if (male) {
        _male = b;
        _p.maleId = b.id;
      } else {
        _female = b;
        _p.femaleId = b.id;
      }
    });
  }

  Future<void> _save() async {
    if (_p.maleId == null || _p.femaleId == null) {
      snack(context, 'Please select both a male and a female');
      return;
    }
    _p.cage = _cage.text.trim().isEmpty ? null : _cage.text.trim();
    _p.notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final id = await ref.read(repoProvider).savePair(_p);
    invalidatePairCaches(ref, pairId: id);
    if (!mounted) return;
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit pair' : 'New pair'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: _loading
          ? const AppLoadingBody()
          : ListView(
              padding: kAppScreenPadding,
              children: [
                AppSurfaceCard(
                  child: BirdSelectTile.pairing(
                    male: true,
                    bird: _male,
                    onTap: () => _pick(male: true),
                  ),
                ),
                const SizedBox(height: 8),
                AppSurfaceCard(
                  child: BirdSelectTile.pairing(
                    male: false,
                    bird: _female,
                    onTap: () => _pick(male: false),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _cage,
                  label: 'Cage / location',
                ),
                const SizedBox(height: 8),
                AppDateTile(
                  title: 'Pairing date',
                  isoDate: _p.startDate,
                  onTap: () async {
                    final d = await pickDateIso(context, initial: _p.startDate);
                    if (d != null && mounted) setState(() => _p.startDate = d);
                  },
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _notes,
                  label: 'Notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                AppPrimarySaveButton(
                  label: 'Save pair',
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
