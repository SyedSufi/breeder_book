/// Change this one line to rename the app inside the UI.
const String kAppName = 'BirdsRecord';

/// Bottom inset so tab content clears the floating rounded nav card.
const double kFloatingNavClearance = 96;

/// Marker written into backup files so we can recognise them on import.
const String kBackupTag = 'birdsrecord_backup';

/// Older MVP exports used this tag; still accepted on restore.
const String kBackupTagLegacy = 'aviary_manager_backup';

bool isKnownBackupTag(Object? tag) =>
    tag == kBackupTag || tag == kBackupTagLegacy;

const List<String> kGenders = ['male', 'female', 'unknown'];
const List<String> kBirdStatuses = ['active', 'breeding', 'sold', 'dead'];
const List<String> kEggStatuses = [
  'laid',
  'fertile',
  'infertile',
  'hatched',
  'failed',
];
const List<String> kPairStatuses = ['active', 'ended'];
