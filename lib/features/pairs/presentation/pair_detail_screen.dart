import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/egg_clutch_widgets.dart';
import '../../../core/widgets/helpers.dart';
import '../../../core/widgets/section_chrome.dart';
import '../../../core/widgets/select_tiles.dart';
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
        body: const AppLoadingBody(),
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
            body: const AppLoadingBody(),
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
        AppMotion.fadeRoute<int>(PairFormScreen(pair: p)),
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
          AppMotion.fadeRoute<int>(BirdFormScreen(bird: prefill)),
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
        AppMotion.fadeRoute<void>(BirdDetailScreen(birdId: id)),
      )
          .then((_) {
        _refresh(ref);
      });
    }

    Future<void> eggActions(Egg e, int number) async {
      await showEggActionsSheet(
        context,
        eggNumber: number,
        actions: [
          EggAction(
            icon: Icons.child_care,
            title: 'Hatched - add chick as a bird',
            subtitle: 'Parents are filled in automatically',
            onTap: () => hatch(e, createBird: true),
          ),
          EggAction(
            icon: Icons.child_care_outlined,
            title: 'Hatched - without bird record',
            onTap: () => hatch(e, createBird: false),
          ),
          EggAction(
            icon: Icons.check_circle_outline,
            title: 'Fertile',
            onTap: () => setStatus(e, 'fertile'),
          ),
          EggAction(
            icon: Icons.block,
            title: 'Infertile',
            onTap: () => setStatus(e, 'infertile'),
          ),
          EggAction(
            icon: Icons.close,
            title: 'Failed / dead in shell',
            onTap: () => setStatus(e, 'failed'),
          ),
          EggAction(
            icon: Icons.restart_alt,
            title: 'Reset to "laid"',
            onTap: () => setStatus(e, 'laid'),
          ),
          EggAction(
            icon: Icons.event,
            title: 'Change lay date',
            onTap: () => changeLayDate(e),
          ),
          if (e.chickBirdId != null)
            EggAction(
              icon: Icons.open_in_new,
              title: 'Open chick',
              onTap: () => openBird(e.chickBirdId!),
            ),
          EggAction(
            icon: Icons.delete_outline,
            title: 'Delete egg',
            destructive: true,
            onTap: () => deleteEgg(e),
          ),
        ],
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
        padding: kAppScreenPadding,
        children: [
          AppSurfaceCard(
            child: Column(
              children: [
                BirdSelectTile(
                  title: male == null ? 'Male (removed)' : 'Male: ${male.label}',
                  bird: male,
                  isMale: true,
                  subtitle: male == null ? null : birdSubtitle(male),
                  showChevronWhenEmpty: false,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onTap: male == null ? null : () => openBird(male.id!),
                ),
                BirdSelectTile(
                  title: female == null
                      ? 'Female (removed)'
                      : 'Female: ${female.label}',
                  bird: female,
                  isMale: false,
                  subtitle: female == null ? null : birdSubtitle(female),
                  showChevronWhenEmpty: false,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onTap: female == null ? null : () => openBird(female.id!),
                ),
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
                child: AppSectionTitle('Rounds (${clutches.length})'),
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
            ClutchRoundCard(
              roundNumber: i + 1,
              clutch: clutches[i],
              eggs: eggs.where((e) => e.clutchId == clutches[i].id).toList(),
              dueDateFor: dueDate,
              onAddEgg: () => addEgg(clutches[i]),
              onDeleteRound: () => deleteClutch(clutches[i]),
              onEggTap: eggActions,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
