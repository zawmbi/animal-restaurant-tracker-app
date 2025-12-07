class LetterCombination {
  final String slot1;
  final String slot2;
  final String slot3;

  const LetterCombination({
    required this.slot1,
    required this.slot2,
    required this.slot3,
  });

  factory LetterCombination.fromJson(Map<String, dynamic> j) {
    return LetterCombination(
      slot1: j['slot1'] as String,
      slot2: j['slot2'] as String,
      slot3: j['slot3'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'slot1': slot1,
        'slot2': slot2,
        'slot3': slot3,
      };
}

class Letter {
  final String id;
  final String name;
  final String? series;
  final String? unlockRequirement;

  final String? description;
  final String? bonus;
  final String? unlocks;
  final String? prerequisite;
  final String? imageAsset;
  final List<LetterCombination> combinations;

  const Letter({
    required this.id,
    required this.name,
    this.series,
    this.unlockRequirement,
    this.description,
    this.bonus,
    this.unlocks,
    this.prerequisite,
    this.imageAsset,
    this.combinations = const [],
  });

  factory Letter.fromJson(Map<String, dynamic> j) => Letter(
        id: j['id'] as String,
        name: j['name'] as String,
        series: j['series'] as String?,
        unlockRequirement: j['unlockRequirement'] as String?,
        description: j['description'] as String?,
        bonus: j['bonus'] as String?,
        unlocks: j['unlocks'] as String?,
        prerequisite: j['prerequisite'] as String?,
        imageAsset: j['imageAsset'] as String?,
        combinations: (j['combinations'] as List<dynamic>? ?? [])
            .map((e) => LetterCombination.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
