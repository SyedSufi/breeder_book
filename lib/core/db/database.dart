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

  static const int schemaVersion = 4;
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
    // v2–v4: expand starter species + mutations (idempotent inserts only).
    // Never deletes/renames user-added rows.
    if (oldVersion < 4) {
      await _ensureSeedSpeciesAndMutations(db);
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

  /// Inserts any missing seed species + mutations (by name).
  /// Used by upgrades so existing installs pick up new starter lists.
  Future<void> _ensureSeedSpeciesAndMutations(Database db) async {
    for (final s in _seedSpecies) {
      final rows = await db.query(
        'species',
        columns: ['id'],
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [s.$1],
        limit: 1,
      );
      final int speciesId;
      if (rows.isEmpty) {
        speciesId = await db.insert('species', {
          'name': s.$1,
          'incubation_days': s.$2,
        });
      } else {
        speciesId = rows.first['id'] as int;
      }
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
      'Yellowface Type I',
      'Yellowface Type II',
      'Goldenface',
      'Lutino',
      'Albino',
      'Lacewing',
      'Fallow',
      'Texas Clearbody',
      'Rainbow',
      'Blackface',
      'Blackwing',
      'Double Black',
      'Hagoromo (Hogoromo)',
      'Crested',
      'Anthracite',
      'Slate',
      'Saddleback',
      'Opaline Spangle',
      'Opaline Cinnamon',
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
      'Roseicollis',
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
      'Yellowface',
      'Seagreen',
      'Slaty',
      'Euwing',
      'Marbled',
      'Pale',
      'NSL Ino',
      'Mask',
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
  // --- Common breeding species added for Pakistan / desi market ---
  (
    'Java Sparrow',
    16,
    [
      'Normal Grey',
      'White',
      'Pied',
      'Fawn',
      'Silver',
      'Cream',
      'Black',
      'Opaline',
    ],
  ),
  (
    'Dove',
    14,
    [
      'Diamond Dove',
      'Ring-necked Dove',
      'Laughing Dove',
      'Turtle Dove',
      'White Dove',
      'Pied',
      'Red Pied',
      'Blue Pied',
      'Silver Pied',
      'Fawn',
      'Silver',
      'Peach',
      'Whiteface',
      'Ivory',
      'Cinnamon',
    ],
  ),
  (
    'Cockatoo',
    28,
    [
      'Sulphur-crested',
      'Umbrella (White)',
      'Moluccan (Salmon-crested)',
      'Galah (Rose-breasted)',
      "Goffin's",
      'Citron-crested',
      'Bare-eyed (Little Corella)',
      'Lutino',
      'Albino',
    ],
  ),
  (
    'Lorikeet',
    25,
    [
      'Rainbow Lorikeet',
      'Red-collared',
      'Scaly-breasted',
      'Musk Lorikeet',
      'Lory (Black-capped)',
      'Green',
      'Blue',
      'Lutino',
      'Olive',
    ],
  ),
  (
    'Eclectus',
    28,
    [
      'Solomon Island',
      'Vosmaeri',
      'Red-sided',
      'Grand',
      'Normal',
    ],
  ),
  (
    'Parrotlet',
    18,
    [
      'Pacific (Celestial)',
      'Green-rumped',
      'Spectacled',
      'Blue',
      'Turquoise',
      'Yellow',
      'White',
      'Lutino',
      'Albino',
      'Fallow',
      'Dilute',
    ],
  ),
  (
    'Quaker Parakeet',
    24,
    [
      'Green (Normal)',
      'Blue',
      'Turquoise',
      'Lutino',
      'Albino',
      'Cinnamon',
      'Pallid',
      'Pied',
      'Grey Green',
    ],
  ),
  (
    'Plum-headed Parakeet',
    23,
    [
      'Green (Normal)',
      'Blue',
      'Lutino',
      'Albino',
      'Cinnamon',
      'Grey Green',
      'Opaline',
      'Dilute',
      'Pied',
    ],
  ),
  (
    'Amazon Parrot',
    26,
    [
      'Blue-fronted',
      'Yellow-crowned',
      'Orange-winged',
      'Double Yellow-head',
      'Red-lored',
      'Mealy',
      'Normal Green',
    ],
  ),
  (
    'Rosella',
    19,
    [
      'Eastern',
      'Western',
      'Crimson',
      'Pale-headed (Mealy)',
      'Green',
      'Yellow',
      'Blue',
      'Lutino',
      'Cinnamon',
      'Opaline',
    ],
  ),
  (
    'Society Finch',
    16,
    [
      'Chocolate Self',
      'Fawn Self',
      'White',
      'Pied',
      'Grey',
      'Crested',
      'Pearl',
      'Dilute',
    ],
  ),
  (
    'Owl Finch',
    14,
    [
      'Normal',
      'White',
      'Pied',
      'Fawn',
      'Isabel',
    ],
  ),
  (
    'Star Finch',
    14,
    [
      'Normal Red',
      'Yellow',
      'Orange',
      'Pied',
      'Dilute',
      'Fawn',
      'Silver',
      'Blue',
      'White',
      'Cream',
      'Isabel',
    ],
  ),
  (
    'Diamond Sparrow',
    14,
    [
      'Normal',
      'Yellow',
      'Pied',
      'White',
      'Fawn',
      'Silver',
    ],
  ),
  (
    "Hex Finch (Heck's)",
    15,
    [
      'Normal',
      'Fawn',
      'Cream',
      'White',
      'Pied',
      'Isabel',
      'Grey',
      'Pale-billed',
    ],
  ),
  (
    'Masked Finch',
    14,
    [
      'Normal',
      'Fawn',
      'White',
      'Pied',
      'Cream',
      'Isabel',
    ],
  ),
  (
    'Parrot Finch',
    14,
    [
      'Blue-faced (Normal)',
      'Red-throated',
      'Pin-tailed',
      'Green',
      'Blue',
      'Lutino',
      'Seagreen',
      'Dilute',
      'Pied',
      'Fawn',
    ],
  ),
  (
    'Indian Silverbill',
    12,
    [
      'Normal',
      'White',
      'Pied',
      'Fawn',
      'Cream',
    ],
  ),
  (
    'Munia',
    14,
    [
      'Scaly-breasted (Nutmeg)',
      'Black-headed',
      'White-headed',
      'Tri-coloured',
      'White',
      'Pied',
      'Fawn',
    ],
  ),
  (
    'Hill Myna',
    16,
    [
      'Common Hill Myna',
      'Greater Hill Myna',
      'Normal',
    ],
  ),
  (
    "Bourke's Parakeet",
    18,
    [
      'Normal Rose',
      'Rosa',
      'Lutino',
      'Cream',
      'Opaline',
      'Yellow',
      'Pink',
    ],
  ),
  (
    'Princess Parrot',
    19,
    [
      'Green (Normal)',
      'Blue',
      'Lutino',
      'Albino',
      'Olive',
      'Violet',
    ],
  ),
];
