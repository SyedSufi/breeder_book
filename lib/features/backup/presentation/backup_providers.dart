import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../birds/presentation/birds_providers.dart';
import '../../pairs/presentation/pairs_providers.dart';
import '../../species/presentation/species_providers.dart';

final countsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(repoProvider).counts();
});

void invalidateAfterRestore(WidgetRef ref) {
  ref.invalidate(countsProvider);
  ref.invalidate(birdsListProvider);
  ref.invalidate(pairsListProvider);
  ref.invalidate(speciesCatalogProvider);
  ref.invalidate(speciesListProvider);
}
