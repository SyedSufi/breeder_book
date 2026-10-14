import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import 'bird_detail_screen.dart';
import 'bird_form_screen.dart';
import 'birds_providers.dart';

class BirdsListScreen extends ConsumerWidget {
  const BirdsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(birdsFilterProvider);
    final asyncBirds = ref.watch(birdsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Birds')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<int>(builder: (_) => const BirdFormScreen()),
          );
          invalidateBirdCaches(ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add bird'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search ring no, species, mutation, cage',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                ref.read(birdsFilterProvider.notifier).state =
                    filter.copyWith(query: v);
              },
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: filter.status == null,
                    onSelected: (_) {
                      ref.read(birdsFilterProvider.notifier).state =
                          filter.copyWith(clearStatus: true);
                    },
                  ),
                ),
                for (final s in kBirdStatuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cap(s)),
                      selected: filter.status == s,
                      onSelected: (_) {
                        ref.read(birdsFilterProvider.notifier).state =
                            filter.copyWith(status: s);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncBirds.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flutter_dash, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            filter.query.isEmpty && filter.status == null
                                ? 'No birds yet.\nTap "Add bird" to save your first bird.'
                                : 'No birds match your search.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return ListTile(
                      leading: BirdAvatar(bird: b),
                      title: Text(b.label),
                      subtitle: Text(birdSubtitle(b)),
                      trailing: b.status == 'active'
                          ? null
                          : StatusChip(
                              text: cap(b.status),
                              color: birdStatusColor(b.status),
                            ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BirdDetailScreen(birdId: b.id!),
                          ),
                        );
                        invalidateBirdCaches(ref, birdId: b.id);
                      },
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
