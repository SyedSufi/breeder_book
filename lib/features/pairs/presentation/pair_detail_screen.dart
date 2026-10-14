import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import '../../birds/presentation/bird_detail_screen.dart';
import '../../birds/presentation/bird_form_screen.dart';
import '../../birds/presentation/birds_providers.dart';
import 'pair_form_screen.dart';
import 'pairs_providers.dart';

class PairDetailScreen extends ConsumerWidget {
  final int pairId;

  const PairDetailScreen({super.key, required this.pairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(pairDetailProvider(pairId));

    return asyncDetail.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (data) {
        if (data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _PairDetailBody(pairId: pairId, data: data);
      },
    );
  }
}

class _PairDetailBody extends ConsumerWidget {
  final int pairId;
  final PairDetailData data;

  const _PairDetailBody({required this.pairId, required this.data});

  Future<void> _refresh(WidgetRef ref) async {
    invalidatePairCaches(ref, pairId: pairId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = data.pair;
    final eggs = data.eggs;
    final clutches = data.clutches;
    final male = data.male;
    final female = data.female;
    final incubationDays = data.incubationDays;
    final speciesId = data.speciesId;

    final hatched = eggs.where((e) => e.status == 'hatched').length;
    final fertile = eggs.where((e) => e.status == 'fertile').length;
    final infertile = eggs.where((e) => e.status == 'infertile').length;

    Future<void> editPair() async {
      await Navigator.of(context).push(
        MaterialPageRoute<int>(builder: (_) => PairFormScreen(pair: p)),
      );
      await _refresh(ref);
    }

    Future<void> deletePair() async {
      final ok = await confirm(
        context,
        title: 'Delete pair?',
        message:
            'This deletes the pair with all its rounds and eggs. The chicks you already saved as birds are kept.',
        okText: 'Delete',
      );
      if (!ok) return;
      await ref.read(repoProvider).deletePair(pairId);
      invalidatePairCaches(ref, pairId: pairId);
      if (context.mounted) Navigator.pop(context);
    }

    Future<void> toggleStatus() async {
      if (p.status == 'active') {
        p.status = 'ended';
        p.endDate = todayIso();
      } else {
        p.status = 'active';
        p.endDate = null;
      }
      await ref.read(repoProvider).savePair(p);
      await _refresh(ref);
    }

    Future<void> addClutch() async {
      await ref.read(repoProvider).addClutch(pairId, todayIso());
      await _refresh(ref);
    }

    Future<void> deleteClutch(Clutch c) async {
      final ok = await confirm(
        context,
        title: 'Delete this round?',
        message: 'All eggs in this round will be deleted.',
        okText: 'Delete',
      );
      if (!ok) return;
      await ref.read(repoProvider).deleteClutch(c.id!);
      await _refresh(ref);
    }

    Future<void> addEgg(Clutch c) async {
      final d = await pickDateIso(context, initial: todayIso());
      if (d == null) return;
      await ref.read(repoProvider).saveEgg(Egg(clutchId: c.id!, layDate: d));
      await _refresh(ref);
    }

    String? dueDate(Egg e) {
      if (e.status != 'laid' && e.status != 'fertile') return null;
      final d = parseIso(e.layDate);
      if (d == null) return null;
      return toIso(d.add(Duration(days: incubationDays)));
    }

    Future<void> setStatus(Egg e, String status) async {
      e.status = status;
      e.hatchDate = null;
      e.chickBirdId = null;
      await ref.read(repoProvider).saveEgg(e);
      await _refresh(ref);
    }

    Future<void> hatch(Egg e, {required bool createBird}) async {
      int? chickId;
      if (createBird) {
        final prefill = Bird(
          ringNo: '',
          speciesId: speciesId,
          gender: 'unknown',
          hatchDate: todayIso(),
          fatherId: p.maleId,
          motherId: p.femaleId,
          cage: p.cage,
        );
        chickId = await Navigator.of(context).push<int>(
          MaterialPageRoute<int>(
            builder: (_) => BirdFormScreen(bird: prefill),
          ),
        );
        if (chickId == null) return;
        invalidateBirdCaches(ref, birdId: chickId);
      }
      e.status = 'hatched';
      e.hatchDate = todayIso();
      e.chickBirdId = chickId;
      await ref.read(repoProvider).saveEgg(e);
      await _refresh(ref);
    }

    Future<void> changeLayDate(Egg e) async {
      final d = await pickDateIso(context, initial: e.layDate);
      if (d == null) return;
      e.layDate = d;
      await ref.read(repoProvider).saveEgg(e);
      await _refresh(ref);
    }

    Future<void> deleteEgg(Egg e) async {
      final ok = await confirm(
        context,
        title: 'Delete egg?',
        message: 'The egg record will be removed.',
        okText: 'Delete',
      );
      if (!ok) return;
      await ref.read(repoProvider).deleteEgg(e.id!);
      await _refresh(ref);
    }

    void openBird(int id) {
      Navigator.of(context)
          .push(
        MaterialPageRoute<void>(builder: (_) => BirdDetailScreen(birdId: id)),
      )
          .then((_) {
        _refresh(ref);
      });
    }

    Future<void> eggActions(Egg e, int number) async {
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          void run(VoidCallback action) {
            Navigator.pop(ctx);
            action();
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Egg $number',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ListTile(
                    leading: const Icon(Icons.child_care),
                    title: const Text('Hatched - add chick as a bird'),
                    subtitle:
                        const Text('Parents are filled in automatically'),
                    onTap: () => run(() => hatch(e, createBird: true)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.child_care_outlined),
                    title: const Text('Hatched - without bird record'),
                    onTap: () => run(() => hatch(e, createBird: false)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Fertile'),
                    onTap: () => run(() => setStatus(e, 'fertile')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Infertile'),
                    onTap: () => run(() => setStatus(e, 'infertile')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Failed / dead in shell'),
                    onTap: () => run(() => setStatus(e, 'failed')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restart_alt),
                    title: const Text('Reset to "laid"'),
                    onTap: () => run(() => setStatus(e, 'laid')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Change lay date'),
                    onTap: () => run(() => changeLayDate(e)),
                  ),
                  if (e.chickBirdId != null)
                    ListTile(
                      leading: const Icon(Icons.open_in_new),
                      title: const Text('Open chick'),
                      onTap: () => run(() => openBird(e.chickBirdId!)),
                    ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete egg',
                        style: TextStyle(color: Colors.red)),
                    onTap: () => run(() => deleteEgg(e)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    IconData eggIcon(String status) {
      switch (status) {
        case 'fertile':
          return Icons.check_circle_outline;
        case 'infertile':
          return Icons.block;
        case 'failed':
          return Icons.close;
        case 'hatched':
          return Icons.child_care;
        default:
          return Icons.egg_outlined;
      }
    }

    Color eggColor(String status) {
      switch (status) {
        case 'fertile':
          return Colors.green;
        case 'infertile':
          return Colors.grey;
        case 'failed':
          return Colors.red;
        case 'hatched':
          return Colors.teal;
        default:
          return Colors.orange;
      }
    }

    Widget parentTile(Bird? b, String title, bool isMale) {
      final color = genderColor(isMale ? 'male' : 'female');
      return ListTile(
        leading: b == null
            ? CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(isMale ? Icons.male : Icons.female, color: color),
              )
            : BirdAvatar(bird: b),
        title: Text(b == null ? '$title (removed)' : '$title: ${b.label}'),
        subtitle: b == null ? null : Text(birdSubtitle(b)),
        trailing: b == null ? null : const Icon(Icons.chevron_right),
        onTap: b == null ? null : () => openBird(b.id!),
      );
    }

    Widget clutchCard(Clutch c, int number) {
      final clutchEggs = eggs.where((e) => e.clutchId == c.id).toList();
      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Round $number · started ${showDate(c.startDate)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') deleteClutch(c);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete round'),
                      ),
                    ],
                  ),
                ],
              ),
              if (clutchEggs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('No eggs yet'),
                ),
              for (var i = 0; i < clutchEggs.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(eggIcon(clutchEggs[i].status),
                      color: eggColor(clutchEggs[i].status)),
                  title: Text('Egg ${i + 1}'),
                  subtitle: Text([
                    'Laid ${showDate(clutchEggs[i].layDate)}',
                    cap(clutchEggs[i].status),
                    if (clutchEggs[i].status == 'hatched' &&
                        clutchEggs[i].hatchDate != null)
                      'on ${showDate(clutchEggs[i].hatchDate)}',
                    if (dueDate(clutchEggs[i]) != null)
                      'due ${showDate(dueDate(clutchEggs[i]))}',
                  ].join(' · ')),
                  trailing: clutchEggs[i].chickBirdId != null
                      ? const Icon(Icons.flutter_dash, size: 20)
                      : const Icon(Icons.more_vert, size: 20),
                  onTap: () => eggActions(clutchEggs[i], i + 1),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => addEgg(c),
                  icon: const Icon(Icons.add),
                  label: const Text('Add egg'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: editPair,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: deletePair,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                parentTile(male, 'Male', true),
                parentTile(female, 'Female', false),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(
                      (p.cage ?? '').isEmpty ? 'No cage set' : 'Cage ${p.cage}'),
                  subtitle: Text(
                      'Paired ${showDate(p.startDate)}${p.endDate == null ? '' : ' · Ended ${showDate(p.endDate)}'}'),
                  trailing: TextButton(
                    onPressed: toggleStatus,
                    child:
                        Text(p.status == 'active' ? 'End pair' : 'Re-activate'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Eggs: ${eggs.length} · Fertile: $fertile · Infertile: $infertile · Hatched: $hatched',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Expected incubation: $incubationDays days',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Rounds (${clutches.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              FilledButton.tonalIcon(
                onPressed: addClutch,
                icon: const Icon(Icons.add),
                label: const Text('New round'),
              ),
            ],
          ),
          if (clutches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  'No rounds yet. Tap "New round" when the hen starts laying, then add each egg.'),
            ),
          for (var i = 0; i < clutches.length; i++)
            clutchCard(clutches[i], i + 1),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
