import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/helpers.dart';
import '../../species/presentation/species_screen.dart';
import 'backup_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final file = await ref
          .read(backupServiceProvider)
          .createBackupFile(ref.read(repoProvider));
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '$kAppName backup',
        text:
            'Backup of my birds. Keep this file safe (Drive / WhatsApp to yourself).',
      );
    } catch (e) {
      if (mounted) snack(context, 'Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final ok = await confirm(
      context,
      title: 'Restore backup?',
      message:
          'This REPLACES all birds, pairs and eggs currently in the app with the data from the backup file.',
      okText: 'Restore',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(backupServiceProvider)
          .restoreFromFile(ref.read(repoProvider), path);
      invalidateAfterRestore(ref);
      if (mounted) snack(context, 'Backup restored.');
    } on FormatException catch (e) {
      if (mounted) snack(context, e.message);
    } catch (e) {
      if (mounted) snack(context, 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(countsProvider).valueOrNull ?? const {};
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Backup')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              kFloatingNavClearance,
            ),
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.cloud_off_outlined,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Offline on this phone',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your data stays on this device. Export a backup regularly and keep the file in Drive or WhatsApp.\n\n'
                      'You now have ${counts['birds'] ?? 0} birds, ${counts['pairs'] ?? 0} pairs and ${counts['eggs'] ?? 0} eggs saved.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppSurfaceCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.upload_file, color: scheme.primary),
                      title: const Text('Export backup'),
                      subtitle:
                          const Text('Save all records to a file and share it'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: _busy ? null : _export,
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    ListTile(
                      leading: Icon(Icons.download, color: scheme.primary),
                      title: const Text('Restore from backup'),
                      subtitle: const Text(
                          'Replaces current data with a backup file'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: _busy ? null : _import,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppSurfaceCard(
                child: ListTile(
                  leading: Icon(Icons.list_alt, color: scheme.primary),
                  title: const Text('Species & mutations'),
                  subtitle: const Text(
                      'Add your own species, mutations and incubation days'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () => Navigator.of(context).push(
                    AppMotion.fadeRoute<void>(const SpeciesScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppSurfaceCard(
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: scheme.onSurfaceVariant,
                  ),
                  title: const Text(kAppName),
                  subtitle: const Text(
                      'Version 0.1.0 (MVP). Photos are not included in backup files yet.'),
                ),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.35),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
