# BirdsRecord (MVP)

Offline bird-breeding record keeper built with Flutter (`breeder_book`). Everything is stored on the phone (SQLite). No login, no server.

See [AGENTS.md](AGENTS.md) for product rules, architecture, and roadmap.

## What is inside

- **Birds**: ring no + ring year, species, mutation, gender, hatch date (age is calculated), father / mother, cage, status (active / breeding / sold / dead), photo, notes. Search + status filter.
- **Parents**: pick them from your own birds, or type a ring number if the parent is not in your list (bought birds).
- **Pedigree**: 3-generation tree (bird, parents, grandparents). Tap a box to open that bird.
- **Pairs**: male + female, cage, pairing date, end / re-activate.
- **Rounds, eggs, hatching**: add rounds and eggs, mark fertile / infertile / failed. "Hatched" opens the add-bird form with species, hatch date and both parents already filled in. Expected hatch date is shown from the species' incubation days.
- **Species & mutations**: starter list included (Budgerigar, Lovebird, Cockatiel, Ringneck, ...). Add your own, edit incubation days.
- **Backup**: export all records to one JSON file (share to WhatsApp / Drive) and restore from it.
- Duplicate ring-number warning, delete keeps the pedigree text of the deleted bird's chicks.

## Run it

```bash
cd breeder_book
flutter create . --platforms=android,ios   # generates android/ and ios/ folders (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run
```

If `flutter create` adds `test/widget_test.dart`, keep the one from this project (it tests the age/date helpers): `flutter test`.

### Platform notes

- **iOS** needs these two keys in `ios/Runner/Info.plist` (photo picking):
  `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` (any short text).
- **Android** needs nothing extra for photos/backup.

## Changing the database later (important)

A normal app update never deletes the database. But if you change tables you must migrate:

1. Bump `schemaVersion` in `lib/core/db/database.dart`.
2. Add an `if (oldVersion < N) { await db.execute('ALTER TABLE ...'); }` block in `_onUpgrade`.
3. Update `_onCreate` so new installs get the same structure.

Never drop and recreate tables in `_onUpgrade`.

## Known limits of this MVP

- Photos are **not** included in backup files (records only). Photos live in the app's own folder.
- Offline only: if the phone is lost or the app is uninstalled, data is gone unless a backup file exists.
- Cage is a plain text field (no separate cages table yet).
- English UI only (Urdu / Roman Urdu comes later).
- No genetics calculator, health records, finances or marketplace yet.

## Rename the app

Change `kAppName` in `lib/core/constants.dart` (title inside the app). For the Android/iOS launcher name edit `android/app/src/main/AndroidManifest.xml` (`android:label`) and `ios/Runner/Info.plist` (`CFBundleDisplayName`).

## Project layout

```
lib/
  main.dart / app.dart     ProviderScope, theme, home
  core/
    constants.dart         app name, status lists
    utils.dart             date / age helpers (unit tested)
    providers.dart         repoProvider, backupServiceProvider
    models/                Bird, Species, Mutation, Pair, Clutch, Egg
    db/                    SQLite schema + Repo (instance)
    services/              photo storage, backup export / import
    widgets/               shared dialogs, bird picker, chips
  features/
    birds/presentation/    list, form, detail, pedigree + providers
    pairs/presentation/    list, form, detail + providers
    species/presentation/  species & mutations + providers
    backup/presentation/   settings / backup + providers
    shell/                 bottom navigation home
```
