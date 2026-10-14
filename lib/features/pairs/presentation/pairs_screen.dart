import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import 'pair_detail_screen.dart';
import 'pair_form_screen.dart';
import 'pairs_providers.dart';

class PairsScreen extends ConsumerWidget {
  const PairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPairs = ref.watch(pairsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Breeding Pairs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final id = await Navigator.of(context).push<int>(
            MaterialPageRoute<int>(builder: (_) => const PairFormScreen()),
          );
          if (!context.mounted) return;
          if (id != null) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PairDetailScreen(pairId: id),
              ),
            );
          }
          invalidatePairCaches(ref, pairId: id);
        },
        icon: const Icon(Icons.add),
        label: const Text('New pair'),
      ),
      body: asyncPairs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No pairs yet.\nAdd your birds first, then tap "New pair" to record a breeding pair, its eggs and chicks.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = list[i];
              final parts = <String>[
                if ((p.cage ?? '').isNotEmpty) 'Cage ${p.cage}',
                if (p.startDate != null) 'Since ${showDate(p.startDate)}',
              ];
              return ListTile(
                leading:
                    const CircleAvatar(child: Icon(Icons.favorite_outline)),
                title:
                    Text('♂ ${p.maleRing ?? '?'}  ×  ♀ ${p.femaleRing ?? '?'}'),
                subtitle: Text(parts.join(' · ')),
                trailing: p.status == 'active'
                    ? null
                    : StatusChip(text: cap(p.status), color: Colors.grey),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PairDetailScreen(pairId: p.id!),
                    ),
                  );
                  invalidatePairCaches(ref, pairId: p.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
