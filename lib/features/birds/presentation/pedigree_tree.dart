import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/repository.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/helpers.dart';
import 'birds_providers.dart';

/// 3-generation pedigree: bird | parents | grandparents.
class PedigreeTree extends ConsumerWidget {
  final Bird root;
  final void Function(Bird bird) onOpen;

  const PedigreeTree({super.key, required this.root, required this.onOpen});

  static const double _rowHeight = 76;

  List<PedNode?> _level(PedNode? n, int depth) {
    if (depth == 0) return [n];
    return [..._level(n?.father, depth - 1), ..._level(n?.mother, depth - 1)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTree = ref.watch(birdPedigreeProvider(root.id!));

    return asyncTree.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(height: 80, child: Center(child: Text('$e'))),
      data: (tree) {
        final columns = <List<PedNode?>>[
          _level(tree, 0),
          _level(tree, 1),
          _level(tree, 2),
        ];
        return SizedBox(
          height: _rowHeight * 4,
          child: Row(
            children: [
              for (final col in columns)
                Expanded(
                  child: Column(
                    children: [
                      for (final n in col) Expanded(child: _box(context, n)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _box(BuildContext context, PedNode? n) {
    final bird = n?.bird;
    final ringText = n?.ringText;

    Color color = Colors.grey;
    String title = '?';
    String? sub;
    if (bird != null) {
      color = genderColor(bird.gender);
      title = bird.label;
      sub = bird.mutationName ?? bird.speciesName;
    } else if (ringText != null && ringText.isNotEmpty) {
      title = ringText;
      sub = 'not in list';
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: bird == null ? null : () => onOpen(bird),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: bird == null ? 0.04 : 0.1),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              if (sub != null)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
