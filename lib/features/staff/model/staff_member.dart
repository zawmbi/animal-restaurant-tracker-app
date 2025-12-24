class StaffMember {
  final String id;
  final String name;
  final String? series;
  final String? blurb;
  final String? unlocking;
  final String? job;

  final List<StaffWearableMemento> wearableMementos;
  final List<StaffRaiseUpgrade> raiseUpgrades;

  const StaffMember({
    required this.id,
    required this.name,
    this.series,
    this.blurb,
    this.unlocking,
    this.job,
    this.wearableMementos = const [],
    this.raiseUpgrades = const [],
  });

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: j['id'] as String,
        name: j['name'] as String,
        series: j['series'] as String?,
        blurb: j['blurb'] as String?,
        unlocking: j['unlocking'] as String?,
        job: j['job'] as String?,
        wearableMementos: (j['wearableMementos'] as List<dynamic>? ?? const [])
            .map((e) => StaffWearableMemento.fromJson(e as Map<String, dynamic>))
            .toList(),
        raiseUpgrades: (j['raiseUpgrades'] as List<dynamic>? ?? const [])
            .map((e) => StaffRaiseUpgrade.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StaffWearableMemento {
  final String mementoId;

  // numeric rating bonus (e.g. 15)
  final int? bonusRating;

  final String? requirements;

  const StaffWearableMemento({
    required this.mementoId,
    this.bonusRating,
    this.requirements,
  });

  factory StaffWearableMemento.fromJson(Map<String, dynamic> j) =>
      StaffWearableMemento(
        mementoId: j['mementoId'] as String,
        bonusRating: _toIntOrNull(j['bonusRating']),
        requirements: j['requirements'] as String?,
      );
}

class StaffRaiseUpgrade {
  final int level;

  // as-is string like "58min", "6hrs"
  final String? required;

  // bonus rating at that level
  final int? ratingBonus;

  // structured cost: currency key + numeric amount
  final StaffCost? cost;

  final Map<String, String> perks;

  const StaffRaiseUpgrade({
    required this.level,
    this.required,
    this.ratingBonus,
    this.cost,
    this.perks = const {},
  });

  factory StaffRaiseUpgrade.fromJson(Map<String, dynamic> j) => StaffRaiseUpgrade(
        level: _toInt(j['level']),
        required: j['required'] as String?,
        ratingBonus: _toIntOrNull(j['ratingBonus']),
        cost: j['cost'] == null
            ? null
            : StaffCost.fromJson(j['cost'] as Map<String, dynamic>),
        perks: (j['perks'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

class StaffCost {
  // "cod", "plates", "bells", "film", "buttons", "diamonds"
  final String currency;

  // numeric amount (e.g. 19000)
  final int amount;

  const StaffCost({
    required this.currency,
    required this.amount,
  });

  factory StaffCost.fromJson(Map<String, dynamic> j) => StaffCost(
        currency: (j['currency'] as String).toLowerCase().trim(),
        amount: _toInt(j['amount']),
      );
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.parse(v.trim());
  throw ArgumentError('Expected int, got: $v');
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }
  return null;
}
