import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils.dart';
import 'helpers.dart';

IconData eggStatusIcon(String status) {
  switch (status) {
    case 'fertile':
      return Icons.check_circle_outline;
    case 'infertile':
      return Icons.block;
    case 'failed':
      return Icons.close;
    case 'hatched':
      return Icons.child_care;
    default:
      return Icons.egg_outlined;
  }
}

Color eggStatusColor(String status) {
  switch (status) {
    case 'fertile':
      return const Color(0xFF16A34A); // semantic, not brand CTA
    case 'infertile':
      return Colors.blueGrey;
    case 'failed':
      return Colors.red;
    case 'hatched':
      return const Color(0xFF0D9488); // distinct hatch cue
    default:
      return Colors.orange;
  }
}

class EggAction {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const EggAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });
}

/// Bottom sheet listing egg actions; [actions] built by the screen.
Future<void> showEggActionsSheet(
  BuildContext context, {
  required int eggNumber,
  required List<EggAction> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      void run(VoidCallback action) {
        Navigator.pop(ctx);
        action();
      }

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Egg $eggNumber',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final a in actions)
                ListTile(
                  leading: Icon(
                    a.icon,
                    color: a.destructive ? Colors.red : null,
                  ),
                  title: Text(
                    a.title,
                    style: a.destructive
                        ? const TextStyle(color: Colors.red)
                        : null,
                  ),
                  subtitle: a.subtitle == null ? null : Text(a.subtitle!),
                  onTap: () => run(a.onTap),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class EggListTile extends StatelessWidget {
  final int number;
  final Egg egg;
  final String? dueIso;
  final VoidCallback onTap;

  const EggListTile({
    super.key,
    required this.number,
    required this.egg,
    required this.onTap,
    this.dueIso,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        eggStatusIcon(egg.status),
        color: eggStatusColor(egg.status),
      ),
      title: Text('Egg $number'),
      subtitle: Text([
        'Laid ${showDate(egg.layDate)}',
        cap(egg.status),
        if (egg.status == 'hatched' && egg.hatchDate != null)
          'on ${showDate(egg.hatchDate)}',
        if (dueIso != null) 'due ${showDate(dueIso)}',
      ].join(' · ')),
      trailing: egg.chickBirdId != null
          ? const Icon(Icons.flutter_dash, size: 20)
          : const Icon(Icons.more_vert, size: 20),
      onTap: onTap,
    );
  }
}

class ClutchRoundCard extends StatelessWidget {
  final int roundNumber;
  final Clutch clutch;
  final List<Egg> eggs;
  final String? Function(Egg egg) dueDateFor;
  final VoidCallback onAddEgg;
  final VoidCallback onDeleteRound;
  final void Function(Egg egg, int number) onEggTap;

  const ClutchRoundCard({
    super.key,
    required this.roundNumber,
    required this.clutch,
    required this.eggs,
    required this.dueDateFor,
    required this.onAddEgg,
    required this.onDeleteRound,
    required this.onEggTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Round $roundNumber · started ${showDate(clutch.startDate)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') onDeleteRound();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete round'),
                  ),
                ],
              ),
            ],
          ),
          if (eggs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('No eggs yet'),
            ),
          for (var i = 0; i < eggs.length; i++)
            EggListTile(
              number: i + 1,
              egg: eggs[i],
              dueIso: dueDateFor(eggs[i]),
              onTap: () => onEggTap(eggs[i], i + 1),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddEgg,
              icon: const Icon(Icons.add),
              label: const Text('Add egg'),
            ),
          ),
        ],
      ),
    );
  }
}
