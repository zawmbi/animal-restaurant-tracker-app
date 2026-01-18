class Poster {
  final String id;
  final String name;
  final String description;

  final int earningIncreasePercent;

  // The performers that must be performing for bonus to apply
  final List<String> requiredPerformerIds;

  // Flexible requirements (strings only, no cross-feature coupling)
  final PosterRequirements requirements;

  Poster({
    required this.id,
    required this.name,
    required this.description,
    required this.earningIncreasePercent,
    required this.requiredPerformerIds,
    required this.requirements,
  });

  factory Poster.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    return Poster(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      earningIncreasePercent: (json['earningIncreasePercent'] is num)
          ? (json['earningIncreasePercent'] as num).toInt()
          : int.tryParse((json['earningIncreasePercent'] ?? '0').toString()) ??
              0,
      requiredPerformerIds: _stringList(json['requiredPerformerIds']),
      requirements: (json['requirements'] is Map)
          ? PosterRequirements.fromJson(
              Map<String, dynamic>.from(json['requirements'] as Map),
            )
          : PosterRequirements.empty(),
    );
  }
}

class PosterRequirements {
  final List<String> customers;   // Unlock <customer>
  final List<String> facilities;  // Unlock <facility/item>
  final List<String> notes;       // Free text like "Fulfill X call back condition"

  PosterRequirements({
    required this.customers,
    required this.facilities,
    required this.notes,
  });

  factory PosterRequirements.empty() => PosterRequirements(
        customers: const [],
        facilities: const [],
        notes: const [],
      );

  factory PosterRequirements.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    return PosterRequirements(
      customers: _stringList(json['customers']),
      facilities: _stringList(json['facilities']),
      notes: _stringList(json['notes']),
    );
  }

  bool get hasAny =>
      customers.isNotEmpty || facilities.isNotEmpty || notes.isNotEmpty;
}
