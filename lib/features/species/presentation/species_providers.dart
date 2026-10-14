import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';

class SpeciesCatalog {
  final List<Species> species;
  final List<Mutation> mutations;

  const SpeciesCatalog({required this.species, required this.mutations});
}

final speciesCatalogProvider =
    FutureProvider.autoDispose<SpeciesCatalog>((ref) async {
  final repo = ref.watch(repoProvider);
  final species = await repo.species();
  final mutations = await repo.mutations();
  return SpeciesCatalog(species: species, mutations: mutations);
});

final speciesListProvider = FutureProvider.autoDispose<List<Species>>((ref) async {
  return ref.watch(repoProvider).species();
});

final mutationsForSpeciesProvider =
    FutureProvider.autoDispose.family<List<Mutation>, int?>((ref, speciesId) async {
  if (speciesId == null) return const [];
  return ref.watch(repoProvider).mutations(speciesId: speciesId);
});

void invalidateSpeciesCaches(WidgetRef ref) {
  ref.invalidate(speciesCatalogProvider);
  ref.invalidate(speciesListProvider);
}
