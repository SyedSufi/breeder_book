import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import '../../../core/widgets/pill_chrome.dart';
import '../../../core/widgets/section_chrome.dart';
import 'pair_detail_screen.dart';
import 'pair_form_screen.dart';
import 'pairs_providers.dart';

class PairsScreen extends ConsumerWidget {
  const PairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPairs = ref.watch(pairsListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Breeding Pairs')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kFabNavClearance),
        child: FloatingActionButton.extended(
          backgroundColor: PillChrome.activeFill,
          foregroundColor: PillChrome.activeInk,
          onPressed: () async {
            final id = await Navigator.of(context).push<int>(
              AppMotion.fadeRoute<int>(const PairFormScreen()),
            );
            if (!context.mounted) return;
            if (id != null) {
              await Navigator.of(context).push(
                AppMotion.fadeRoute<void>(PairDetailScreen(pairId: id)),
              );
            }
            invalidatePairCaches(ref, pairId: id);
          },
          icon: const Icon(Icons.add),
          label: const Text('New pair'),
        ),
      ),
      body: asyncPairs.when(
        loading: () => const AppLoadingBody(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_outline,
              message:
                  'No pairs yet.\nAdd your birds first, then tap "New pair" to record a breeding pair, its eggs and chicks.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              kFloatingNavClearance + 56,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              final parts = <String>[
                if ((p.cage ?? '').isNotEmpty) 'Cage ${p.cage}',
                if (p.startDate != null) 'Since ${showDate(p.startDate)}',
              ];
              return StaggeredListItem(
                index: i,
                child: AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () async {
                    await Navigator.of(context).push(
                      AppMotion.fadeRoute<void>(
                        PairDetailScreen(pairId: p.id!),
                      ),
                    );
                    invalidatePairCaches(ref, pairId: p.id);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.favorite,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      '♂ ${p.maleRing ?? '?'}  ×  ♀ ${p.femaleRing ?? '?'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(parts.join(' · ')),
                    trailing: p.status == 'active'
                        ? Icon(
                            Icons.chevron_right,
                            color: scheme.onSurfaceVariant,
                          )
                        : StatusChip(
                            text: cap(p.status),
                            color: scheme.onSurfaceVariant,
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
