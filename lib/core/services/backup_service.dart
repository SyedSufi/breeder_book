import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../db/database.dart';
import '../db/repository.dart';

/// Backup = one JSON file with all records (photos are NOT included in the MVP).
class BackupService {
  /// Creates a shareable JSON backup of all tables via [repo].
  Future<File> createBackupFile(Repo repo) async {
    final tables = await repo.dumpAll();
    final payload = <String, Object?>{
      'app': kBackupTag,
      'schema': AppDatabase.schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tables,
    };
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
    final file = File(p.join(dir.path, 'birdsrecord_backup_$stamp.json'));
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  /// Reads a backup file and replaces all current data with it.
  /// Throws [FormatException] with a readable message if the file is not valid.
  Future<void> restoreFromFile(Repo repo, String path) async {
    final text = await File(path).readAsString();
    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      throw const FormatException('This file is not a valid backup.');
    }
    if (data is! Map || !isKnownBackupTag(data['app'])) {
      throw const FormatException('This file is not a backup from this app.');
    }
    final schema = data['schema'];
    if (schema is! int || schema > AppDatabase.schemaVersion) {
      throw const FormatException(
          'This backup is from a newer version of the app. Please update the app first.');
    }
    final tables = data['tables'];
    if (tables is! Map) {
      throw const FormatException('Backup file is damaged (no data found).');
    }
    await repo.restoreAll(Map<String, dynamic>.from(tables));
  }
}
