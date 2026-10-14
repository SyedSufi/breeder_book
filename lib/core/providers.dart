import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/repository.dart';
import 'services/backup_service.dart';

final repoProvider = Provider<Repo>((ref) => Repo());

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());
