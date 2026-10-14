import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';

class PairDetailData {
  final Pair pair;
  final Bird? male;
  final Bird? female;
  final List<Clutch> clutches;
  final List<Egg> eggs;
  final int? speciesId;
  final int incubationDays;

  const PairDetailData({
    required this.pair,
    required this.male,
    required this.female,
    required this.clutches,
    required this.eggs,
    required this.speciesId,
    required this.incubationDays,
  });
}

final pairsListProvider = FutureProvider.autoDispose<List<Pair>>((ref) async {
  return ref.watch(repoProvider).pairs();
});

final pairDetailProvider =
    FutureProvider.autoDispose.family<PairDetailData?, int>((ref, pairId) async {
  final repo = ref.watch(repoProvider);
  final pair = await repo.getPair(pairId);
  if (pair == null) return null;

  final male = pair.maleId == null ? null : await repo.getBird(pair.maleId!);
  final female =
      pair.femaleId == null ? null : await repo.getBird(pair.femaleId!);
  final clutches = await repo.clutches(pair.id!);
  final eggs = await repo.eggsForPair(pair.id!);
  final species = await repo.species();
  final sid = male?.speciesId ?? female?.speciesId;
  var days = 18;
  for (final s in species) {
    if (s.id == sid) days = s.incubationDays;
  }

  return PairDetailData(
    pair: pair,
    male: male,
    female: female,
    clutches: clutches,
    eggs: eggs,
    speciesId: sid,
    incubationDays: days,
  );
});

void invalidatePairCaches(WidgetRef ref, {int? pairId}) {
  ref.invalidate(pairsListProvider);
  if (pairId != null) {
    ref.invalidate(pairDetailProvider(pairId));
  }
}
