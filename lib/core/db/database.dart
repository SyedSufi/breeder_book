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

  static const int schemaVersion = 2;
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
    // v2: fill starter mutations for species that shipped empty (or incomplete).
    // Does not delete/rename user-added mutations; only inserts missing names.
    if (oldVersion < 2) {
      await _ensureSeedMutations(db);
    }
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

  /// Inserts any seed mutations missing for existing species (by name).
  /// Used by upgrades so existing installs pick up new starter lists.
  Future<void> _ensureSeedMutations(Database db) async {
    for (final s in _seedSpecies) {
      final rows = await db.query(
        'species',
        columns: ['id'],
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [s.$1],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final speciesId = rows.first['id'] as int;
      for (final m in s.$3) {
        final existing = await db.query(
          'mutations',
          columns: ['id'],
          where: 'species_id = ? AND LOWER(name) = LOWER(?)',
          whereArgs: [speciesId, m],
          limit: 1,
        );
        if (existing.isEmpty) {
          await db.insert('mutations', {'species_id': speciesId, 'name': m});
        }
      }
    }
  }
}

/// (name, incubationDays, mutations). Mutations include common colour morphs
/// and, where breeders usually pick a type/breed instead, popular type names.
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
      'Double Factor Spangle',
      'Dominant Pied',
      'Recessive Pied',
      'Clearwing',
      'Greywing',
      'Yellowface',
      'Lutino',
      'Albino',
      'Lacewing',
      'Fallow',
      'Texas Clearbody',
      'Rainbow',
      'English',
      'American',
    ],
  ),
  (
    'Lovebird',
    23,
    [
      // Common types (Pakistan market often records type + colour together)
      'Peachface',
      "Fischer's",
      'Personata',
      'Black-cheeked',
      // Colour mutations
      'Green (Normal)',
      'Blue',
      'Turquoise',
      'Violet',
      'Lutino',
      'Albino',
      'Opaline',
      'Cinnamon',
      'Pied',
      'Dutch Pied',
      'Dilute',
      'Pallid',
      'Dark Factor',
      'Olive',
      'Aqua',
      'Orangeface',
      'Seagreen',
      'Slaty',
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
      'Whiteface Lutino (Albino)',
      'Cinnamon',
      'Cinnamon Pearl',
      'Yellowface',
      'Fallow',
      'Silver',
      'Pastel',
      'Emerald',
      'Olive',
    ],
  ),
  (
    'Ringneck Parakeet',
    24,
    [
      'Green (Normal)',
      'Blue',
      'Cobalt',
      'Mauve',
      'Violet',
      'Lutino',
      'Albino',
      'Cinnamon',
      'Grey',
      'Grey Green',
      'Olive',
      'Turquoise',
      'Aqua',
      'Pied',
      'Opaline',
      'Lacewing',
      'Fallow',
      'Clearhead',
      'Emerald',
      'Misty',
      'Dark Factor',
    ],
  ),
  (
    'Alexandrine Parakeet',
    28,
    [
      'Green (Normal)',
      'Blue',
      'Lutino',
      'Albino',
      'Cinnamon',
      'Grey',
      'Grey Green',
      'Olive',
      'Turquoise',
      'Violet',
      'Dark Factor',
      'Pied',
    ],
  ),
  (
    'African Grey',
    28,
    [
      'Congo',
      'Timneh',
      'Normal Grey',
      'F2',
    ],
  ),
  (
    'Macaw',
    26,
    [
      'Blue & Gold',
      'Scarlet',
      'Green-winged',
      'Military',
      'Hyacinth',
      'Catalina',
      'Harlequin',
      'Severe (Chestnut-fronted)',
    ],
  ),
  (
    'Conure',
    23,
    [
      'Sun Conure',
      'Green Cheek (Normal)',
      'Green Cheek Cinnamon',
      'Green Cheek Pineapple',
      'Green Cheek Turquoise',
      'Green Cheek Yellow-sided',
      'Green Cheek Pallid',
      'Jenday',
      'Nanday',
      'Mitred',
      'Blue Crown',
    ],
  ),
  (
    'Canary',
    13,
    [
      'Yellow',
      'White',
      'Red Factor',
      'Orange',
      'Green',
      'Agate',
      'Isabel',
      'Opal',
      'Satinette',
      'Lizard',
      'Gloster',
      'Border',
      'Yorkshire',
      'Norwich',
      'German Roller',
      'Spanish Timbrado',
    ],
  ),
  (
    'Zebra Finch',
    12,
    [
      'Normal Grey',
      'White',
      'Pied',
      'Fawn',
      'Chestnut Flanked White (CFW)',
      'Black Cheek',
      'Black Breast',
      'Orange Breast',
      'Penguin',
      'Isabel',
      'Dilute',
      'Dominant Silver',
    ],
  ),
  (
    'Gouldian Finch',
    14,
    [
      'Red Head',
      'Black Head',
      'Yellow Head',
      'Green Body',
      'Blue Body',
      'Yellow Body',
      'Dilute',
      'Silver',
      'White Breast',
      'Lilac Breast',
      'Purple Breast',
    ],
  ),
  (
    'Pigeon',
    18,
    [
      // Pakistan / desi flyer & fancy types commonly recorded
      'Lahori High Flyer',
      'High Flyer',
      'Racing Homer',
      'Fantail',
      'Jacobin',
      'Tumbler',
      'King',
      'Frillback',
      'English Carrier',
      'Pouter',
      'Modena',
      'Normal / Desi',
      'White',
      'Black',
      'Red',
      'Blue Bar',
      'Pied',
    ],
  ),
];
