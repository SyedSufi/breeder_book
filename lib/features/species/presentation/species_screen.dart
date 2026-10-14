import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/helpers.dart';
import 'species_providers.dart';

/// Manage the species list (with incubation days) and each species' mutations.
class SpeciesScreen extends ConsumerWidget {
  const SpeciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCatalog = ref.watch(speciesCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Species & mutations'),
        actions: [
          IconButton(
            tooltip: 'Add species',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await addSpeciesDialog(context, ref.read(repoProvider));
              invalidateSpeciesCaches(ref);
            },
          ),
        ],
      ),
      body: asyncCatalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (catalog) {
          return ListView(
            children: [
              for (final s in catalog.species)
                _SpeciesTile(
                  species: s,
                  mutations: catalog.mutations
                      .where((m) => m.speciesId == s.id)
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SpeciesTile extends ConsumerWidget {
  final Species species;
  final List<Mutation> mutations;

  const _SpeciesTile({required this.species, required this.mutations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = species;
    final muts = mutations;

    Future<void> addMutation() async {
      final name = await promptText(context,
          title: 'New mutation for ${s.name}', label: 'Mutation name');
      if (name == null) return;
      await ref.read(repoProvider).addMutation(s.id!, name);
      invalidateSpeciesCaches(ref);
    }

    Future<void> deleteMutation(Mutation m) async {
      if (await ref.read(repoProvider).mutationInUse(m.id!)) {
        if (context.mounted) {
          snack(context,
              'This mutation is used by some birds, so it cannot be deleted.');
        }
        return;
      }
      await ref.read(repoProvider).deleteMutation(m.id!);
      invalidateSpeciesCaches(ref);
    }

    Future<void> editIncubation() async {
      final text = await promptText(
        context,
        title: 'Incubation days for ${s.name}',
        label: 'Days',
        initial: s.incubationDays.toString(),
      );
      final days = int.tryParse(text ?? '');
      if (days == null || days < 5 || days > 60) return;
      await ref.read(repoProvider).updateSpecies(s.id!, s.name, days);
      invalidateSpeciesCaches(ref);
    }

    Future<void> deleteSpecies() async {
      if (await ref.read(repoProvider).speciesInUse(s.id!)) {
        if (context.mounted) {
          snack(context,
              'Some birds use this species, so it cannot be deleted.');
        }
        return;
      }
      if (!context.mounted) return;
      final ok = await confirm(
        context,
        title: 'Delete ${s.name}?',
        message: 'The species and its mutations will be removed.',
        okText: 'Delete',
      );
      if (!ok) return;
      await ref.read(repoProvider).deleteSpecies(s.id!);
      invalidateSpeciesCaches(ref);
    }

    return ExpansionTile(
      title: Text(s.name),
      subtitle:
          Text('Incubation ${s.incubationDays} days · ${muts.length} mutations'),
      children: [
        for (final m in muts)
          ListTile(
            dense: true,
            title: Text(m.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => deleteMutation(m),
            ),
          ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.add),
          title: const Text('Add mutation'),
          onTap: addMutation,
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Edit incubation days'),
          onTap: editIncubation,
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete species',
              style: TextStyle(color: Colors.red)),
          onTap: deleteSpecies,
        ),
      ],
    );
  }
}
