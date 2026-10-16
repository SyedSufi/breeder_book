import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../db/database.dart';
import '../db/repository.dart';
import 'photo_store.dart';

/// Creates ZIP backups containing the database JSON and available bird photos.
/// Legacy JSON-only backups remain supported for restore.
class BackupService {
  static const _manifestName = 'backup.json';

  /// Creates a shareable ZIP backup of all tables and available photos.
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
    final file = File(p.join(dir.path, 'birdsrecord_backup_$stamp.zip'));
    final encoder = ZipFileEncoder()..create(file.path);
    encoder
        .addArchiveFile(ArchiveFile.string(_manifestName, jsonEncode(payload)));

    final photoNames = <String>{
      for (final bird in tables['birds'] ?? const <Map<String, Object?>>[])
        if (bird['photo_file'] case final String name)
          if (_isSafeFileName(name)) name,
    };
    for (final name in photoNames) {
      final photo = File(PhotoStore.pathOf(name));
      if (await photo.exists()) {
        await encoder.addFile(photo, 'photos/$name');
      }
    }
    await encoder.close();
    return file;
  }

  /// Reads a backup file and replaces all current data with it.
  /// Throws [FormatException] with a readable message if the file is not valid.
  Future<void> restoreFromFile(Repo repo, String path) async {
    final file = File(path);
    final isZip = p.extension(path).toLowerCase() == '.zip';
    if (!isZip) {
      await _restoreJson(repo, await file.readAsString());
      return;
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    } catch (_) {
      throw const FormatException('This ZIP file is not a valid backup.');
    }

    final manifests = archive.files
        .where((entry) => entry.isFile && entry.name == _manifestName)
        .toList();
    if (manifests.length != 1) {
      throw const FormatException('Backup file is damaged (no data found).');
    }
    final manifestBytes = manifests.single.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('Backup file is damaged (no data found).');
    }
    final tables = _decodeTables(utf8.decode(manifestBytes));

    final stagedPhotos = <String, List<int>>{};
    for (final entry in archive.files.where((entry) => entry.isFile)) {
      if (!entry.name.startsWith('photos/')) continue;
      final name = entry.name.substring('photos/'.length);
      if (!_isSafeFileName(name)) {
        throw const FormatException('Backup contains an unsafe photo name.');
      }
      final bytes = entry.readBytes();
      if (bytes != null) stagedPhotos[name] = bytes;
    }

    // Database restore is transactional. Photos are staged in memory first, so
    // a corrupt ZIP cannot partially replace the user's records.
    await repo.restoreAll(tables);
    final photoDir = Directory(PhotoStore.directoryPath);
    if (!await photoDir.exists()) await photoDir.create(recursive: true);
    for (final photo in stagedPhotos.entries) {
      await File(PhotoStore.pathOf(photo.key)).writeAsBytes(
        photo.value,
        flush: true,
      );
    }
  }

  Future<void> _restoreJson(Repo repo, String text) async {
    await repo.restoreAll(_decodeTables(text));
  }

  Map<String, dynamic> _decodeTables(String text) {
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
    return Map<String, dynamic>.from(tables);
  }

  static bool _isSafeFileName(String name) =>
      name.isNotEmpty &&
      name == p.basename(name) &&
      name != '.' &&
      name != '..';
}
