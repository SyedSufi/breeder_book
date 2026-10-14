import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database.
///
/// IMPORTANT (data safety): a normal app update NEVER deletes this database.
/// When you change the tables in a later version:
///   1. bump [schemaVersion]
///   2. add an `if (oldVersion < N)` block in [_onUpgrade] that ALTERs the tables
///   3. update [_onCreate] so fresh installs get the same structure
/// Never drop/recreate tables in [_onUpgrade] - that is what wipes user data.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const int schemaVersion = 1;
  static const String _fileName = 'breeder_book.db';

  Future<Database>? _opening;
  Future<Database> get db => _opening ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example for the future (version 2 adds a column):
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE birds ADD COLUMN weight_g REAL');
    // }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE species (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        incubation_days INTEGER NOT NULL DEFAULT 18
      )''');
    await db.execute('''
      CREATE TABLE mutations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species_id INTEGER NOT NULL,
        name TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE birds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ring_no TEXT NOT NULL,
        ring_year INTEGER,
        species_id INTEGER,
        mutation_id INTEGER,
        gender TEXT NOT NULL DEFAULT 'unknown',
        hatch_date TEXT,
        father_id INTEGER,
        mother_id INTEGER,
        father_ring_no TEXT,
        mother_ring_no TEXT,
        cage TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        photo_file TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');
    await db.execute('CREATE INDEX idx_birds_ring ON birds(ring_no, ring_year)');
    await db.execute('CREATE INDEX idx_birds_father ON birds(father_id)');
    await db.execute('CREATE INDEX idx_birds_mother ON birds(mother_id)');
    await db.execute('''
      CREATE TABLE pairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        male_id INTEGER,
        female_id INTEGER,
        cage TEXT,
        start_date TEXT,
        end_date TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE clutches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pair_id INTEGER NOT NULL,
        start_date TEXT,
        notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE eggs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clutch_id INTEGER NOT NULL,
        lay_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'laid',
        hatch_date TEXT,
        chick_bird_id INTEGER
      )''');
    await db.execute('CREATE INDEX idx_eggs_clutch ON eggs(clutch_id)');
    await db.execute('CREATE INDEX idx_clutches_pair ON clutches(pair_id)');

    await _seed(db);
  }

  /// Starter species + common mutations. Incubation days are typical values and
  /// can be edited in the app (Settings > Species & mutations).
  Future<void> _seed(Database db) async {
    for (final s in _seedSpecies) {
      final id = await db.insert('species', {
        'name': s.$1,
        'incubation_days': s.$2,
      });
      for (final m in s.$3) {
        await db.insert('mutations', {'species_id': id, 'name': m});
      }
    }
  }
}

const List<(String, int, List<String>)> _seedSpecies = [
  (
    'Budgerigar',
    18,
    [
      'Normal (Light Green)',
      'Dark Green',
      'Olive',
      'Skyblue',
      'Cobalt',
      'Mauve',
      'Violet',
      'Grey',
      'Grey Green',
      'Opaline',
      'Cinnamon',
      'Spangle',
      'Dominant Pied',
      'Recessive Pied',
      'Clearwing',
      'Greywing',
      'Yellowface',
      'Lutino',
      'Albino',
      'Lacewing',
    ],
  ),
  (
    'Lovebird',
    23,
    [
      'Green (Normal)',
      'Blue',
      'Violet',
      'Lutino',
      'Albino',
      'Opaline',
      'Cinnamon',
      'Pied',
      'Dilute',
      'Pallid',
      'Dark Factor',
      'Personata',
      "Fischer's",
    ],
  ),
  (
    'Cockatiel',
    18,
    [
      'Normal Grey',
      'Lutino',
      'Albino',
      'Pearl',
      'Pied',
      'Pearl Pied',
      'Whiteface',
      'Cinnamon',
      'Yellowface',
    ],
  ),
  (
    'Ringneck Parakeet',
    24,
    [
      'Green (Normal)',
      'Blue',
      'Lutino',
      'Albino',
      'Violet',
      'Grey',
      'Cinnamon',
      'Turquoise',
      'Pied',
      'Olive',
    ],
  ),
  ('Alexandrine Parakeet', 28, []),
  ('African Grey', 28, []),
  ('Macaw', 26, []),
  ('Conure', 23, []),
  ('Canary', 13, []),
  ('Zebra Finch', 12, []),
  ('Gouldian Finch', 14, []),
  ('Pigeon', 18, []),
];
