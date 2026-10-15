import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import '../../../core/widgets/pill_chrome.dart';
import '../../../core/widgets/section_chrome.dart';
import 'bird_detail_screen.dart';
import 'bird_form_screen.dart';
import 'birds_providers.dart';

class BirdsListScreen extends ConsumerWidget {
  const BirdsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(birdsFilterProvider);
    final asyncBirds = ref.watch(birdsListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Birds')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kFabNavClearance),
        child: FloatingActionButton.extended(
          backgroundColor: PillChrome.activeFill,
          foregroundColor: PillChrome.activeInk,
          onPressed: () async {
            await Navigator.of(context).push(
              AppMotion.fadeRoute<int>(const BirdFormScreen()),
            );
            invalidateBirdCaches(ref);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add bird'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PillSearchField(
              hintText: 'Search ...',
              onChanged: (v) {
                ref.read(birdsFilterProvider.notifier).state =
                    filter.copyWith(query: v);
              },
            ),
          ),
          PillFilterBar(
            selectedId: filter.status,
            onSelected: (id) {
              if (id == null) {
                ref.read(birdsFilterProvider.notifier).state =
                    filter.copyWith(clearStatus: true);
              } else {
                ref.read(birdsFilterProvider.notifier).state =
                    filter.copyWith(status: id);
              }
            },
            options: [
              const PillFilterOption(id: null, label: 'All'),
              for (final s in kBirdStatuses)
                PillFilterOption(id: s, label: cap(s)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: asyncBirds.when(
              loading: () => const AppLoadingBody(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.pets,
                    message: filter.query.isEmpty && filter.status == null
                        ? 'No birds yet.\nTap "Add bird" to save your first bird.'
                        : 'No birds match your search.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    kFloatingNavClearance + 56,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return StaggeredListItem(
                      index: i,
                      child: AppSurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        onTap: () async {
                          await Navigator.of(context).push(
                            AppMotion.fadeRoute<void>(
                              BirdDetailScreen(birdId: b.id!),
                            ),
                          );
                          invalidateBirdCaches(ref, birdId: b.id);
                        },
                        child: ListTile(
                          leading: Hero(
                            tag: 'bird-avatar-${b.id}',
                            child: BirdAvatar(bird: b),
                          ),
                          title: Text(
                            b.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(birdSubtitle(b)),
                          trailing: b.status == 'active'
                              ? Icon(
                                  Icons.chevron_right,
                                  color: scheme.onSurfaceVariant,
                                )
                              : StatusChip(
                                  text: cap(b.status),
                                  color: birdStatusColor(b.status),
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
