import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/repository.dart';
import '../../../core/models/models.dart';
import '../../../core/providers.dart';

class BirdsFilter {
  final String query;
  final String? status;

  const BirdsFilter({this.query = '', this.status});

  BirdsFilter copyWith({String? query, String? status, bool clearStatus = false}) {
    return BirdsFilter(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BirdsFilter && other.query == query && other.status == status;

  @override
  int get hashCode => Object.hash(query, status);
}

final birdsFilterProvider =
    StateProvider<BirdsFilter>((ref) => const BirdsFilter());

/// Debounced birds list (300ms) keyed off [birdsFilterProvider].
final birdsListProvider = FutureProvider.autoDispose<List<Bird>>((ref) async {
  final filter = ref.watch(birdsFilterProvider);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return ref.read(repoProvider).birds(
        query: filter.query,
        status: filter.status,
      );
});

final birdProvider =
    FutureProvider.autoDispose.family<Bird?, int>((ref, id) async {
  return ref.watch(repoProvider).getBird(id);
});

final birdChildrenProvider =
    FutureProvider.autoDispose.family<List<Bird>, int>((ref, id) async {
  return ref.watch(repoProvider).children(id);
});

final birdPedigreeProvider =
    FutureProvider.autoDispose.family<PedNode, int>((ref, id) async {
  final repo = ref.watch(repoProvider);
  final bird = await repo.getBird(id);
  if (bird == null) {
    return const PedNode();
  }
  return repo.pedigree(bird, depth: 2);
});

void invalidateBirdCaches(WidgetRef ref, {int? birdId}) {
  ref.invalidate(birdsListProvider);
  if (birdId != null) {
    ref.invalidate(birdProvider(birdId));
    ref.invalidate(birdChildrenProvider(birdId));
    ref.invalidate(birdPedigreeProvider(birdId));
  }
}
