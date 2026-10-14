import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database.dart';

/// One node of a pedigree tree. [bird] is null when the ancestor is unknown or
/// only known by a typed-in ring number ([ringText]).
class PedNode {
  final Bird? bird;
  final String? ringText;
  final PedNode? father;
  final PedNode? mother;

  const PedNode({this.bird, this.ringText, this.father, this.mother});
}

/// All database queries live here so screens stay simple.
class Repo {
  Future<Database> get _db => AppDatabase.instance.db;

  static const List<String> backupTables = [
    'species',
    'mutations',
    'birds',
    'pairs',
    'clutches',
    'eggs',
  ];

  // ---------------------------------------------------------------- species

  Future<List<Species>> species() async {
    final db = await _db;
    final rows = await db.query('species', orderBy: 'name COLLATE NOCASE');
    return rows.map(Species.fromMap).toList();
  }

  Future<int> addSpecies(String name, int incubationDays) async {
    final db = await _db;
    final existing = await db.query(
      'species',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return db.insert('species', {
      'name': name,
      'incubation_days': incubationDays,
    });
  }

  Future<void> updateSpecies(int id, String name, int days) async {
    final db = await _db;
    await db.update(
      'species',
      {'name': name, 'incubation_days': days},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> speciesInUse(int id) async {
    final db = await _db;
    final n = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM birds WHERE species_id = ?', [id]));
    return (n ?? 0) > 0;
  }

  Future<void> deleteSpecies(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('mutations', where: 'species_id = ?', whereArgs: [id]);
      await txn.delete('species', where: 'id = ?', whereArgs: [id]);
    });
  }

  // -------------------------------------------------------------- mutations

  Future<List<Mutation>> mutations({int? speciesId}) async {
    final db = await _db;
    final rows = await db.query(
      'mutations',
      where: speciesId == null ? null : 'species_id = ?',
      whereArgs: speciesId == null ? null : [speciesId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Mutation.fromMap).toList();
  }

  Future<int> addMutation(int speciesId, String name) async {
    final db = await _db;
    final existing = await db.query(
      'mutations',
      columns: ['id'],
      where: 'species_id = ? AND LOWER(name) = LOWER(?)',
      whereArgs: [speciesId, name],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return db.insert('mutations', {'species_id': speciesId, 'name': name});
  }

  Future<bool> mutationInUse(int id) async {
    final db = await _db;
    final n = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM birds WHERE mutation_id = ?', [id]));
    return (n ?? 0) > 0;
  }

  Future<void> deleteMutation(int id) async {
    final db = await _db;
    await db.delete('mutations', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ birds

  static const String _birdSelect =
      'SELECT b.*, s.name AS species_name, m.name AS mutation_name '
      'FROM birds b '
      'LEFT JOIN species s ON s.id = b.species_id '
      'LEFT JOIN mutations m ON m.id = b.mutation_id';

  Future<List<Bird>> birds({
    String? query,
    String? status,
    List<String>? genders,
    int? excludeId,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    final q = query?.trim() ?? '';
    if (q.isNotEmpty) {
      where.add(
          '(b.ring_no LIKE ? OR s.name LIKE ? OR m.name LIKE ? OR b.cage LIKE ?)');
      final like = '%$q%';
      args.addAll([like, like, like, like]);
    }
    if (status != null) {
      where.add('b.status = ?');
      args.add(status);
    }
    if (genders != null && genders.isNotEmpty) {
      where.add('b.gender IN (${List.filled(genders.length, '?').join(',')})');
      args.addAll(genders);
    }
    if (excludeId != null) {
      where.add('b.id != ?');
      args.add(excludeId);
    }

    final sql = '$_birdSelect'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}'
        ' ORDER BY b.id DESC';
    final rows = await db.rawQuery(sql, args);
    return rows.map(Bird.fromMap).toList();
  }

  Future<Bird?> getBird(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('$_birdSelect WHERE b.id = ?', [id]);
    if (rows.isEmpty) return null;
    return Bird.fromMap(rows.first);
  }

  /// Birds whose father or mother is [id].
  Future<List<Bird>> children(int id) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_birdSelect WHERE b.father_id = ? OR b.mother_id = ? '
      'ORDER BY b.hatch_date DESC, b.id DESC',
      [id, id],
    );
    return rows.map(Bird.fromMap).toList();
  }

  /// Insert (id == null) or update. Returns the bird id.
  Future<int> saveBird(Bird b) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final map = b.toMap()..remove('id');
    if (b.id == null) {
      map['created_at'] = now;
      map['updated_at'] = now;
      return db.insert('birds', map);
    }
    map['updated_at'] = now;
    await db.update('birds', map, where: 'id = ?', whereArgs: [b.id]);
    return b.id!;
  }

  Future<bool> ringExists(String ringNo, int? ringYear,
      {int? excludeId}) async {
    final db = await _db;
    final where = StringBuffer('LOWER(ring_no) = LOWER(?)');
    final args = <Object?>[ringNo];
    if (ringYear == null) {
      where.write(' AND ring_year IS NULL');
    } else {
      where.write(' AND ring_year = ?');
      args.add(ringYear);
    }
    if (excludeId != null) {
      where.write(' AND id != ?');
      args.add(excludeId);
    }
    final rows = await db.query(
      'birds',
      columns: ['id'],
      where: where.toString(),
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Deletes a bird but keeps its descendants' pedigree text: the deleted
  /// bird's ring number is copied into the children's "parent ring" text.
  Future<void> deleteBird(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE birds SET father_ring_no = COALESCE(father_ring_no, '
        '(SELECT ring_no FROM birds WHERE id = ?)), father_id = NULL '
        'WHERE father_id = ?',
        [id, id],
      );
      await txn.rawUpdate(
        'UPDATE birds SET mother_ring_no = COALESCE(mother_ring_no, '
        '(SELECT ring_no FROM birds WHERE id = ?)), mother_id = NULL '
        'WHERE mother_id = ?',
        [id, id],
      );
      await txn.rawUpdate(
          'UPDATE pairs SET male_id = NULL WHERE male_id = ?', [id]);
      await txn.rawUpdate(
          'UPDATE pairs SET female_id = NULL WHERE female_id = ?', [id]);
      await txn.rawUpdate(
          'UPDATE eggs SET chick_bird_id = NULL WHERE chick_bird_id = ?', [id]);
      await txn.delete('birds', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --------------------------------------------------------------- pedigree

  Future<PedNode> pedigree(Bird root, {int depth = 2}) =>
      _node(bird: root, ringText: null, depth: depth);

  Future<PedNode> _node({
    required Bird? bird,
    required String? ringText,
    required int depth,
  }) async {
    if (bird == null || depth == 0) {
      return PedNode(bird: bird, ringText: ringText);
    }
    Bird? f;
    Bird? m;
    if (bird.fatherId != null) f = await getBird(bird.fatherId!);
    if (bird.motherId != null) m = await getBird(bird.motherId!);
    final fn =
        await _node(bird: f, ringText: bird.fatherRingNo, depth: depth - 1);
    final mn =
        await _node(bird: m, ringText: bird.motherRingNo, depth: depth - 1);
    return PedNode(bird: bird, ringText: ringText, father: fn, mother: mn);
  }

  // ------------------------------------------------------------------ pairs

  static const String _pairSelect =
      'SELECT p.*, mb.ring_no AS male_ring, fb.ring_no AS female_ring '
      'FROM pairs p '
      'LEFT JOIN birds mb ON mb.id = p.male_id '
      'LEFT JOIN birds fb ON fb.id = p.female_id';

  Future<List<Pair>> pairs() async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_pairSelect ORDER BY CASE p.status WHEN 'active' THEN 0 ELSE 1 END, p.id DESC",
    );
    return rows.map(Pair.fromMap).toList();
  }

  Future<Pair?> getPair(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('$_pairSelect WHERE p.id = ?', [id]);
    if (rows.isEmpty) return null;
    return Pair.fromMap(rows.first);
  }

  Future<int> savePair(Pair p) async {
    final db = await _db;
    final map = p.toMap()..remove('id');
    if (p.id == null) return db.insert('pairs', map);
    await db.update('pairs', map, where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  /// Deletes the pair with its rounds and eggs. Chicks (birds) are kept.
  Future<void> deletePair(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawDelete(
        'DELETE FROM eggs WHERE clutch_id IN '
        '(SELECT id FROM clutches WHERE pair_id = ?)',
        [id],
      );
      await txn.delete('clutches', where: 'pair_id = ?', whereArgs: [id]);
      await txn.delete('pairs', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---------------------------------------------------------------- clutches

  Future<List<Clutch>> clutches(int pairId) async {
    final db = await _db;
    final rows = await db.query(
      'clutches',
      where: 'pair_id = ?',
      whereArgs: [pairId],
      orderBy: 'id',
    );
    return rows.map(Clutch.fromMap).toList();
  }

  Future<int> addClutch(int pairId, String startDate) async {
    final db = await _db;
    return db.insert('clutches', {'pair_id': pairId, 'start_date': startDate});
  }

  Future<void> deleteClutch(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('eggs', where: 'clutch_id = ?', whereArgs: [id]);
      await txn.delete('clutches', where: 'id = ?', whereArgs: [id]);
    });
  }

  // -------------------------------------------------------------------- eggs

  Future<List<Egg>> eggsForPair(int pairId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT e.* FROM eggs e JOIN clutches c ON c.id = e.clutch_id '
      'WHERE c.pair_id = ? ORDER BY e.lay_date, e.id',
      [pairId],
    );
    return rows.map(Egg.fromMap).toList();
  }

  Future<int> saveEgg(Egg e) async {
    final db = await _db;
    final map = e.toMap()..remove('id');
    if (e.id == null) return db.insert('eggs', map);
    await db.update('eggs', map, where: 'id = ?', whereArgs: [e.id]);
    return e.id!;
  }

  Future<void> deleteEgg(int id) async {
    final db = await _db;
    await db.delete('eggs', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ backup

  Future<Map<String, List<Map<String, Object?>>>> dumpAll() async {
    final db = await _db;
    final out = <String, List<Map<String, Object?>>>{};
    for (final t in backupTables) {
      out[t] = await db.query(t);
    }
    return out;
  }

  /// Replaces ALL data with the given tables (from a backup file).
  /// Runs in one transaction: if anything fails, nothing changes.
  Future<void> restoreAll(Map<String, dynamic> tables) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final t in backupTables.reversed) {
        await txn.delete(t);
      }
      final batch = txn.batch();
      for (final t in backupTables) {
        final rows = (tables[t] as List?) ?? const [];
        for (final r in rows) {
          batch.insert(t, Map<String, Object?>.from(r as Map));
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, int>> counts() async {
    final db = await _db;
    final out = <String, int>{};
    for (final t in ['birds', 'pairs', 'eggs']) {
      out[t] = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $t')) ??
          0;
    }
    return out;
  }
}
