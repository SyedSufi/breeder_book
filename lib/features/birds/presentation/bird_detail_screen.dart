import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/services/photo_store.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/helpers.dart';
import 'bird_form_screen.dart';
import 'birds_providers.dart';
import 'pedigree_tree.dart';

class BirdDetailScreen extends ConsumerWidget {
  final int birdId;

  const BirdDetailScreen({super.key, required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBird = ref.watch(birdProvider(birdId));
    final asyncChildren = ref.watch(birdChildrenProvider(birdId));

    return asyncBird.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (b) {
        if (b == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Bird not found')),
          );
        }

        final children = asyncChildren.valueOrNull ?? const [];

        return Scaffold(
          appBar: AppBar(
            title: Text(b.label),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    AppMotion.fadeRoute<int>(BirdFormScreen(bird: b)),
                  );
                  invalidateBirdCaches(ref, birdId: birdId);
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirm(
                    context,
                    title: 'Delete bird?',
                    message:
                        'Delete ${b.label}? Its chicks keep this ring number as their parent text. This cannot be undone.',
                    okText: 'Delete',
                  );
                  if (!ok) return;
                  await ref.read(repoProvider).deleteBird(b.id!);
                  invalidateBirdCaches(ref, birdId: birdId);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(bird: b),
              const SizedBox(height: 16),
              _InfoCard(bird: b),
              const SizedBox(height: 16),
              Text('Pedigree', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              PedigreeTree(
                root: b,
                onOpen: (other) {
                  if (other.id == birdId) return;
                  Navigator.of(context)
                      .push(
                    AppMotion.fadeRoute<void>(
                      BirdDetailScreen(birdId: other.id!),
                    ),
                  )
                      .then((_) {
                    invalidateBirdCaches(ref, birdId: birdId);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a box to open that bird. Blue = male, pink = female.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Chicks (${children.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No chicks recorded from this bird yet.'),
                ),
              for (final c in children)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: BirdAvatar(bird: c),
                  title: Text(c.label),
                  subtitle: Text(birdSubtitle(c)),
                  onTap: () {
                    Navigator.of(context)
                        .push(
                      AppMotion.fadeRoute<void>(
                        BirdDetailScreen(birdId: c.id!),
                      ),
                    )
                        .then((_) {
                      invalidateBirdCaches(ref, birdId: birdId);
                    });
                  },
                ),
              if ((b.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(b.notes!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Bird bird;

  const _Header({required this.bird});

  @override
  Widget build(BuildContext context) {
    final b = bird;
    final hasPhoto = PhotoStore.exists(b.photoFile);
    return Row(
      children: [
        Hero(
          tag: 'bird-avatar-${b.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 110,
              height: 110,
              child: hasPhoto
                  ? Image.file(File(PhotoStore.pathOf(b.photoFile!)),
                      fit: BoxFit.cover)
                  : Container(
                      color: genderColor(b.gender).withValues(alpha: 0.12),
                      child: Icon(Icons.flutter_dash,
                          size: 56, color: genderColor(b.gender)),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.label, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(birdSubtitle(b)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  StatusChip(
                      text: cap(b.status), color: birdStatusColor(b.status)),
                  StatusChip(text: cap(b.gender), color: genderColor(b.gender)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Bird bird;

  const _InfoCard({required this.bird});

  @override
  Widget build(BuildContext context) {
    final b = bird;
    String parentText(int? id, String? ringText) {
      if (id != null) return 'In your list';
      if (ringText != null && ringText.isNotEmpty) return ringText;
      return 'Unknown';
    }

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(k, style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(child: Text(v)),
            ],
          ),
        );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          row('Ring no', b.ringNo),
          row('Ring year', b.ringYear?.toString() ?? '-'),
          row('Species', b.speciesName ?? '-'),
          row('Mutation', b.mutationName ?? '-'),
          row('Hatch date', showDate(b.hatchDate)),
          row('Age',
              ageText(b.hatchDate).isEmpty ? '-' : ageText(b.hatchDate)),
          row('Father', parentText(b.fatherId, b.fatherRingNo)),
          row('Mother', parentText(b.motherId, b.motherRingNo)),
          row('Cage', b.cage ?? '-'),
        ],
      ),
    );
  }
}
