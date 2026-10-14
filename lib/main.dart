import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/services/photo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhotoStore.init();
  await AppDatabase.instance.db; // open (and create/migrate) the database
  runApp(const ProviderScope(child: BreederApp()));
}
