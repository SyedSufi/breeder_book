import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Backup')),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Your data is stored only on this phone. If the phone is lost, reset or the app is uninstalled, the data is gone - so export a backup regularly and keep the file in Google Drive or send it to yourself on WhatsApp.\n\n'
                      'You now have ${counts['birds'] ?? 0} birds, ${counts['pairs'] ?? 0} pairs and ${counts['eggs'] ?? 0} eggs saved.',
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Export backup'),
                subtitle: const Text('Save all records to a file and share it'),
                onTap: _busy ? null : _export,
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Restore from backup'),
                subtitle:
                    const Text('Replaces current data with a backup file'),
                onTap: _busy ? null : _import,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Species & mutations'),
                subtitle: const Text(
                    'Add your own species, mutations and incubation days'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SpeciesScreen()),
                ),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(kAppName),
                subtitle: Text(
                    'Version 0.1.0 (MVP). Photos are not included in backup files yet.'),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
