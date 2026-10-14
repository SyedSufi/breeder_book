class Species {
  final int? id;
  final String name;
  final int incubationDays;

  const Species({this.id, required this.name, this.incubationDays = 18});

  factory Species.fromMap(Map<String, Object?> m) => Species(
        id: m['id'] as int?,
        name: m['name'] as String,
        incubationDays: (m['incubation_days'] as int?) ?? 18,
      );
}

class Mutation {
  final int? id;
  final int speciesId;
  final String name;

  const Mutation({this.id, required this.speciesId, required this.name});

  factory Mutation.fromMap(Map<String, Object?> m) => Mutation(
        id: m['id'] as int?,
        speciesId: m['species_id'] as int,
        name: m['name'] as String,
      );
}

class Bird {
  int? id;
  String ringNo;
  int? ringYear;
  int? speciesId;
  int? mutationId;
  String gender; // male | female | unknown
  String? hatchDate; // ISO yyyy-MM-dd
  int? fatherId;
  int? motherId;

  /// Used when the parent is not in the app (e.g. a bird you bought).
  String? fatherRingNo;
  String? motherRingNo;

  String? cage;
  String status; // active | breeding | sold | dead

  /// File name only (not a full path). Resolve with PhotoStore.pathOf().
  String? photoFile;
  String? notes;

  // Read-only values filled in by the JOIN query.
  String? speciesName;
  String? mutationName;

  Bird({
    this.id,
    required this.ringNo,
    this.ringYear,
    this.speciesId,
    this.mutationId,
    this.gender = 'unknown',
    this.hatchDate,
    this.fatherId,
    this.motherId,
    this.fatherRingNo,
    this.motherRingNo,
    this.cage,
    this.status = 'active',
    this.photoFile,
    this.notes,
    this.speciesName,
    this.mutationName,
  });

  factory Bird.fromMap(Map<String, Object?> m) => Bird(
        id: m['id'] as int?,
        ringNo: (m['ring_no'] as String?) ?? '',
        ringYear: m['ring_year'] as int?,
        speciesId: m['species_id'] as int?,
        mutationId: m['mutation_id'] as int?,
        gender: (m['gender'] as String?) ?? 'unknown',
        hatchDate: m['hatch_date'] as String?,
        fatherId: m['father_id'] as int?,
        motherId: m['mother_id'] as int?,
        fatherRingNo: m['father_ring_no'] as String?,
        motherRingNo: m['mother_ring_no'] as String?,
        cage: m['cage'] as String?,
        status: (m['status'] as String?) ?? 'active',
        photoFile: m['photo_file'] as String?,
        notes: m['notes'] as String?,
        speciesName: m['species_name'] as String?,
        mutationName: m['mutation_name'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'ring_no': ringNo,
        'ring_year': ringYear,
        'species_id': speciesId,
        'mutation_id': mutationId,
        'gender': gender,
        'hatch_date': hatchDate,
        'father_id': fatherId,
        'mother_id': motherId,
        'father_ring_no': fatherRingNo,
        'mother_ring_no': motherRingNo,
        'cage': cage,
        'status': status,
        'photo_file': photoFile,
        'notes': notes,
      };

  Bird copy() => Bird(
        id: id,
        ringNo: ringNo,
        ringYear: ringYear,
        speciesId: speciesId,
        mutationId: mutationId,
        gender: gender,
        hatchDate: hatchDate,
        fatherId: fatherId,
        motherId: motherId,
        fatherRingNo: fatherRingNo,
        motherRingNo: motherRingNo,
        cage: cage,
        status: status,
        photoFile: photoFile,
        notes: notes,
        speciesName: speciesName,
        mutationName: mutationName,
      );

  /// "A-123 · 2024" or just "A-123".
  String get label => ringYear == null ? ringNo : '$ringNo · $ringYear';
}

class Pair {
  int? id;
  int? maleId;
  int? femaleId;
  String? cage;
  String? startDate;
  String? endDate;
  String status; // active | ended
  String? notes;

  // Read-only values filled in by the JOIN query.
  String? maleRing;
  String? femaleRing;

  Pair({
    this.id,
    this.maleId,
    this.femaleId,
    this.cage,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.notes,
    this.maleRing,
    this.femaleRing,
  });

  factory Pair.fromMap(Map<String, Object?> m) => Pair(
        id: m['id'] as int?,
        maleId: m['male_id'] as int?,
        femaleId: m['female_id'] as int?,
        cage: m['cage'] as String?,
        startDate: m['start_date'] as String?,
        endDate: m['end_date'] as String?,
        status: (m['status'] as String?) ?? 'active',
        notes: m['notes'] as String?,
        maleRing: m['male_ring'] as String?,
        femaleRing: m['female_ring'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'male_id': maleId,
        'female_id': femaleId,
        'cage': cage,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'notes': notes,
      };
}

/// One breeding round of a pair (a group of eggs).
class Clutch {
  int? id;
  int pairId;
  String? startDate;
  String? notes;

  Clutch({this.id, required this.pairId, this.startDate, this.notes});

  factory Clutch.fromMap(Map<String, Object?> m) => Clutch(
        id: m['id'] as int?,
        pairId: m['pair_id'] as int,
        startDate: m['start_date'] as String?,
        notes: m['notes'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'pair_id': pairId,
        'start_date': startDate,
        'notes': notes,
      };
}

class Egg {
  int? id;
  int clutchId;
  String layDate;
  String status; // laid | fertile | infertile | hatched | failed
  String? hatchDate;
  int? chickBirdId;

  Egg({
    this.id,
    required this.clutchId,
    required this.layDate,
    this.status = 'laid',
    this.hatchDate,
    this.chickBirdId,
  });

  factory Egg.fromMap(Map<String, Object?> m) => Egg(
        id: m['id'] as int?,
        clutchId: m['clutch_id'] as int,
        layDate: (m['lay_date'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'laid',
        hatchDate: m['hatch_date'] as String?,
        chickBirdId: m['chick_bird_id'] as int?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'clutch_id': clutchId,
        'lay_date': layDate,
        'status': status,
        'hatch_date': hatchDate,
        'chick_bird_id': chickBirdId,
      };
}
