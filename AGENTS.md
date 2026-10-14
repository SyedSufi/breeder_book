# BirdsRecord - Project Guide for AI coding agents (Cursor)

Read this file fully before changing anything. It is the single source of truth for what the app is, how it is built, the rules to follow, and what to work on next.

## 1. Product

**BirdsRecord** (package name: `breeder_book`) is an offline-first mobile app for bird breeders to record their birds: ring/band number, parents' ring numbers, mutation, species, hatch year/age, pairs, eggs and chicks, with a pedigree (family tree).

- Target users: hobby and professional bird breeders (first Pakistan: lovebirds, budgies, cockatiels, ringnecks, etc.; later worldwide).
- Owner: solo developer, working part-time. Prefer small, safe, easy-to-review changes.
- Domain: birdsrecord.com (owned). Planned store title: "BirdsRecord: Bird Breeding Manager".
- applicationId / namespace: `com.birdsrecord.breeder_book` (Android); iOS bundle `com.birdsrecord.breederBook`.
- Business direction (not built yet): free basic app, paid premium (cloud backup, PDF pedigree certificates, genetics calculator), later a marketplace with verified lineage.
- Competitors exist (AviLedger, BirdFlow, mBirdBreeder, FarmKeep...). Our edge: simple, Urdu/Roman Urdu support, local species/mutations, WhatsApp sharing, works fully offline.

## 2. Tech stack

- Flutter (Material 3), Dart >= 3.4. Android first, iOS later.
- Local DB: `sqflite` (plain SQL, no code generation). Photos: `image_picker` + files in the app folder.
- Backup: JSON export/import via `share_plus` + `file_picker`.
- State: **flutter_riverpod** (`ProviderScope`, feature providers). Screens are `ConsumerWidget` / `ConsumerStatefulWidget`. Do NOT swap to Bloc/GetIt unless the owner asks.
- Layout: feature-first under `lib/core/` + `lib/features/`.

## 3. Current status (IMPORTANT)

Phase 0 (build/run scaffolding) is largely done:

- `android/` and `ios/` exist; `flutter analyze` and `flutter test` should pass.
- Riverpod + feature-first migration is in place.
- Display name / `kAppName` is **BirdsRecord**.
- Backup tag is `birdsrecord_backup`; legacy `aviary_manager_backup` still imports.
- Photos are still **not** in backup (Phase 1).
- App icon / Play release signing not done yet.

Known version-drift spots:
- `DropdownButtonFormField(value: ...)` may be deprecated in newer Flutter; keep controlled `value` when State owns selection.
- `share_plus` is pinned (`Share.shareXFiles`). Newer majors changed the API; only upgrade deliberately.
- `Color.withValues(alpha:)` needs Flutter >= 3.27.

## 4. Project layout

```
lib/
  main.dart / app.dart       ProviderScope, theme, home
  core/
    constants.dart           kAppName, kBackupTag (+ legacy), status lists
    utils.dart               pure Dart date/age helpers (unit tested)
    providers.dart           repoProvider, backupServiceProvider
    models/models.dart       Bird, Species, Mutation, Pair, Clutch, Egg
    db/database.dart         schema, schemaVersion, migrations, seed data
    db/repository.dart       ALL SQL (instance Repo), pedigree, dump/restore
    services/                PhotoStore, BackupService
    widgets/helpers.dart     dialogs, date picker, bird picker, chips, avatar
  features/
    birds/presentation/      list, form, detail, pedigree + providers
    pairs/presentation/      list, form, detail + providers
    species/presentation/    species & mutations + providers
    backup/presentation/     settings / backup + providers
    shell/                   bottom navigation
test/widget_test.dart        unit tests for utils
```

## 5. Data model (SQLite, schema version 4)

- `species(id, name UNIQUE, incubation_days)`
- `mutations(id, species_id, name)`
- `birds(id, ring_no, ring_year, species_id, mutation_id, gender[male|female|unknown], hatch_date[ISO], father_id, mother_id, father_ring_no, mother_ring_no, cage, status[active|breeding|sold|dead], photo_file, notes, created_at, updated_at)`
- `pairs(id, male_id, female_id, cage, start_date, end_date, status[active|ended], notes)`
- `clutches(id, pair_id, start_date, notes)` = one breeding round
- `eggs(id, clutch_id, lay_date, status[laid|fertile|infertile|hatched|failed], hatch_date, chick_bird_id)`

Key rules:
- Family tree comes from `birds.father_id / mother_id`. If a parent is not in the app, typed ring goes into `father_ring_no / mother_ring_no`.
- When an egg hatches, a new `birds` row is created and its id stored in `eggs.chick_bird_id`; father/mother are pre-filled from the pair.
- Dates are ISO `yyyy-MM-dd`. `photo_file` is a file name, never a full path.
- No SQL FOREIGN KEY constraints; integrity is in `Repo` (`deleteBird`, `deletePair`, `deleteClutch`). Add FKs only via migration.
- Duplicate ring (same ring_no + ring_year) warns but is allowed.

## 6. Hard rules (do not break)

1. **Never lose user data.** Schema changes = bump `schemaVersion`, `if (oldVersion < N)` in `_onUpgrade` with `ALTER`/`CREATE`, update `_onCreate`. NEVER drop/recreate in `_onUpgrade`.
2. All SQL lives in `lib/core/db/repository.dart` (schema in `database.dart`). Screens must not run SQL.
3. Backup export/import must keep working after schema changes (backup `schema` = `AppDatabase.schemaVersion`; refuse newer schemas). Accept legacy backup tags.
4. Keep the app **offline-first**: no feature may require internet to add/view birds.
5. Do not add dependencies without asking. If needed, say why and pin a version.
6. Keep UI strings easy to find (Phase 2 localization). Use `kAppName`; do not hard-code the product name.
7. Do not commit secrets, keystores, or real `google-services.json` keys.
8. Small changes, one concern at a time. Run `flutter analyze` and `flutter test` before saying a task is done.
9. After mutations, invalidate the relevant Riverpod providers (birds/pairs/species/counts).

## 7. Coding conventions

- Follow `flutter_lints`. Zero analyzer errors; avoid new warnings.
- After `await`, check `if (!mounted) return;` / `context.mounted` before using `context`.
- Models: plain Dart with `fromMap`/`toMap`. Join fields are read-only.
- Prefer shared helpers in `core/widgets/helpers.dart` over copy-paste.
- Names: files `snake_case.dart`, classes `PascalCase`, private `_camelCase`.
- Keep comments short (why, not what).

## 8. Roadmap and tasks

Work in order. Do not start a phase before the previous one is accepted by the owner.

### Phase 0 - Build and run
- [x] `flutter create` platforms, `flutter pub get`
- [x] `flutter analyze` / `flutter test`
- [x] iOS photo plist keys; launcher name BirdsRecord; `kAppName`
- [x] Riverpod + feature-first layout
- [ ] Real-device `flutter run` + QA checklist (section 9)
- [ ] App icon (`flutter_launcher_icons` — ask owner first)

### Phase 1 - MVP polish (first 10-15 test breeders)
- [ ] Photos in backup (zip: JSON + `photos/`). Keep old JSON import working.
- [ ] Bird list: total count, sort (newest, ring no, age).
- [ ] Pair detail: hatch-rate %; "due soon" highlight (eggs within 3 days).
- [ ] Empty states / errors reviewed.
- [ ] Release APK/AAB checked; app size noted.
- Acceptance: breeder enters 20+ birds, 2 pairs, eggs, export/import without data loss.

### Phase 2 - Beta features
- [ ] Hatch reminders (`flutter_local_notifications`).
- [ ] Pedigree PDF/image for WhatsApp.
- [ ] Localization: English + Urdu + Roman Urdu (ARB); RTL for Urdu.
- [ ] CSV import.
- [ ] Cloud backup + login (Supabase or Firebase — owner decides). Local DB stays source of truth; design note first.
- [ ] Privacy policy (birdsrecord.com / GitHub Pages).

### Phase 3 - Growth
- [ ] Genetics calculator + inbreeding warning.
- [ ] Health records, weights, expenses/sales.
- [ ] Premium (IAP) and free-tier limits.
- [ ] Marketplace / verified lineage + QR (backend; design first).

### Store release checklist
- Signing key (never in git), applicationId `com.birdsrecord.breeder_book`, version bump.
- Play Console listing, screenshots, privacy URL, Data safety (on-device until cloud exists).

## 9. Manual QA checklist (run before every release)

1. Fresh install: starter species/mutations present.
2. Add bird with photo; edit; restart; data + photo remain.
3. Father + mother + chick; pedigree shows parents; tap opens bird.
4. Parents not in list (typed rings) -> pedigree "not in list".
5. Duplicate ring -> warning; "Save anyway" works.
6. Pair -> round -> eggs -> hatch with chick form prefilled -> egg linked.
7. Cancel chick form -> egg NOT marked hatched.
8. Delete parent -> chicks keep ring text; pair shows "(removed)".
9. Export -> uninstall -> restore -> records identical (photos later in Phase 1).
10. Non-backup import -> friendly error, data unchanged.
11. After schema change: old build data + upgrade -> data intact.

## 10. How to work (agent working agreement)

- Before coding: restate the task in 2-3 lines and list files you will touch.
- Smallest change that satisfies the task; no unrelated refactors.
- After coding: `flutter analyze` + `flutter test`; report honestly.
- Product decisions (naming, pricing, new dependency, backend): ask the owner.
- Prefer short answers in Roman Urdu/English mix.
