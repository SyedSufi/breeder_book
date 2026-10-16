import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps bird photos inside the app's own folder and stores only the file
/// NAME in the database (full paths can change after an app update on iOS).
class PhotoStore {
  PhotoStore._();

  static String _dir = '';

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'photos'));
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d.path;
  }

  static String pathOf(String fileName) => p.join(_dir, fileName);

  static String get directoryPath => _dir;

  static bool exists(String? fileName) {
    if (fileName == null || fileName.isEmpty) return false;
    return File(pathOf(fileName)).existsSync();
  }

  /// Lets the user pick/take a photo, copies it into the app folder and
  /// returns the saved file name (or null if cancelled).
  static Future<String?> pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (x == null) return null;
    final name =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}';
    await File(x.path).copy(pathOf(name));
    return name;
  }
}
