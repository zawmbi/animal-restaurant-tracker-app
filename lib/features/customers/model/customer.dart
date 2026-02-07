class Customer {
  final String id;
  final String name;
  final List<String> tags;

  final String? livesIn;
  final int? appearanceWeight;

  final String customerDescription;

  // REQUIRED by DishDetailPage
  final String? requiredFoodId;

  // REQUIRED by DishDetailPage
  final List<String> dishesOrderedIds;

  final CustomerRequirements? requirements;
  final List<CustomerMemento> mementos;

  // Optional expansions
  final BoothOwnerInfo? boothOwner;
  final PerformerInfo? performer;

  // Seasonal grouping (e.g. "summer", "halloween", "christmas", "winter")
  final String? season;

  Customer({
    required this.id,
    required this.name,
    required this.tags,
    required this.customerDescription,
    this.livesIn,
    this.appearanceWeight,
    this.requiredFoodId,
    required this.dishesOrderedIds,
    this.requirements,
    required this.mementos,
    this.boothOwner,
    this.performer,
    this.season,
  });

  bool hasTag(String t) => tags.contains(t);

  factory Customer.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    int? _nullableInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return Customer(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      tags: _stringList(json['tags']),
      livesIn: json['livesIn']?.toString(),
      appearanceWeight: _nullableInt(json['appearanceWeight']),
      customerDescription: (json['customerDescription'] ?? '').toString(),

      // Keep DishDetailPage working
      requiredFoodId: json['requiredFoodId']?.toString(),
      dishesOrderedIds: _stringList(json['dishesOrderedIds']),

      requirements: (json['requirements'] is Map)
          ? CustomerRequirements.fromJson(
              Map<String, dynamic>.from(json['requirements'] as Map),
            )
          : null,

      mementos: (json['mementos'] is List)
          ? (json['mementos'] as List)
              .whereType<Map>()
              .map((e) => CustomerMemento.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const <CustomerMemento>[],

      boothOwner: (json['boothOwner'] is Map)
          ? BoothOwnerInfo.fromJson(
              Map<String, dynamic>.from(json['boothOwner'] as Map),
            )
          : null,

      performer: (json['performer'] is Map)
          ? PerformerInfo.fromJson(
              Map<String, dynamic>.from(json['performer'] as Map),
            )
          : null,

      season: json['season']?.toString(),
    );
  }
}

class CustomerRequirements {
  final int? requiredStars;

  // DishDetailPage uses requirements.recipes (strings) and lowercases them
  final List<String> recipes;

  final List<String> facilities;
  final List<String> letters;

  // optional prereq customers
  final List<String> customers;

  CustomerRequirements({
    required this.requiredStars,
    required this.recipes,
    required this.facilities,
    required this.letters,
    required this.customers,
  });

  bool get hasAny =>
      requiredStars != null ||
      recipes.isNotEmpty ||
      facilities.isNotEmpty ||
      letters.isNotEmpty ||
      customers.isNotEmpty;

  factory CustomerRequirements.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    int? _nullableInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return CustomerRequirements(
      requiredStars: _nullableInt(json['requiredStars']),
      recipes: _stringList(json['recipes']),
      facilities: _stringList(json['facilities']),
      letters: _stringList(json['letters']),
      customers: _stringList(json['customers']),
    );
  }
}

class CustomerMemento {
  final String id;
  final String name;

  CustomerMemento({required this.id, required this.name});

  factory CustomerMemento.fromJson(Map<String, dynamic> json) {
    return CustomerMemento(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

/// ---------------- BOOTH OWNER MODELS ----------------

class BoothOwnerInfo {
  final BoothTimeRange? timeRange; // null = Any Time
  final MinMaxInt? stayDurationMinutes;
  final List<String> requiredFishIds;

  final List<IncomeRule> incomeEvery5Min;
  final DropRange? customerDrop;

  final List<AppearanceRateRow> appearanceRatesByFish;

  BoothOwnerInfo({
    required this.timeRange,
    required this.stayDurationMinutes,
    required this.requiredFishIds,
    required this.incomeEvery5Min,
    required this.customerDrop,
    required this.appearanceRatesByFish,
  });

  factory BoothOwnerInfo.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    return BoothOwnerInfo(
      timeRange: (json['timeRange'] is Map)
          ? BoothTimeRange.fromJson(
              Map<String, dynamic>.from(json['timeRange'] as Map),
            )
          : null,
      stayDurationMinutes: (json['stayDurationMinutes'] is Map)
          ? MinMaxInt.fromJson(
              Map<String, dynamic>.from(json['stayDurationMinutes'] as Map),
            )
          : null,
      requiredFishIds: _stringList(json['requiredFishIds']),
      incomeEvery5Min: (json['incomeEvery5Min'] is List)
          ? (json['incomeEvery5Min'] as List)
              .whereType<Map>()
              .map((e) => IncomeRule.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const <IncomeRule>[],
      customerDrop: (json['customerDrop'] is Map)
          ? DropRange.fromJson(
              Map<String, dynamic>.from(json['customerDrop'] as Map),
            )
          : null,
      appearanceRatesByFish: (json['appearanceRatesByFish'] is List)
          ? (json['appearanceRatesByFish'] as List)
              .whereType<Map>()
              .map((e) => AppearanceRateRow.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const <AppearanceRateRow>[],
    );
  }
}

class BoothTimeRange {
  final String start;
  final String end;
  BoothTimeRange({required this.start, required this.end});

  factory BoothTimeRange.fromJson(Map<String, dynamic> json) {
    return BoothTimeRange(
      start: (json['start'] ?? '').toString(),
      end: (json['end'] ?? '').toString(),
    );
  }
}

class MinMaxInt {
  final int min;
  final int max;
  MinMaxInt({required this.min, required this.max});

  factory MinMaxInt.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    return MinMaxInt(
      min: _toInt(json['min']),
      max: _toInt(json['max']),
    );
  }
}

class IncomeRule {
  final String currency; // cod / plates / rating / film etc
  final double amount;
  final double chance;

  IncomeRule({
    required this.currency,
    required this.amount,
    required this.chance,
  });

  factory IncomeRule.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '0').toString()) ?? 0.0;
    }

    return IncomeRule(
      currency: (json['currency'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      chance: _toDouble(json['chance']),
    );
  }
}

class DropRange {
  final String currency;
  final int min;
  final int max;

  DropRange({required this.currency, required this.min, required this.max});

  factory DropRange.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    return DropRange(
      currency: (json['currency'] ?? '').toString(),
      min: _toInt(json['min']),
      max: _toInt(json['max']),
    );
  }
}

class AppearanceRateRow {
  final String fishId;
  final double? morning;
  final double? afternoon;
  final double? night;

  AppearanceRateRow({
    required this.fishId,
    required this.morning,
    required this.afternoon,
    required this.night,
  });

  factory AppearanceRateRow.fromJson(Map<String, dynamic> json) {
    double? _toNullableDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return AppearanceRateRow(
      fishId: (json['fishId'] ?? '').toString(),
      morning: _toNullableDouble(json['morning']),
      afternoon: _toNullableDouble(json['afternoon']),
      night: _toNullableDouble(json['night']),
    );
  }
}

/// ---------------- PERFORMER MODELS ----------------

class PerformerInfo {
  final String? band;
  final int? showDurationMinutes;
  final int? callbackRequirementHours;

  // ex: Film +10/min
  final PerformerEarnings? baseEarnings;

  // customer ids (fans)
  final List<String> fansCustomerIds;

  // performer links with chances
  final List<PerformerChanceLink> canBeInvitedBy; // invited by THIS performer
  final List<PerformerChanceLink> canInviteThis; // can invite THIS performer

  // posters (ids/keys, displayed as chips)
  final List<String> posterIds;

  PerformerInfo({
    required this.band,
    required this.showDurationMinutes,
    required this.callbackRequirementHours,
    required this.baseEarnings,
    required this.fansCustomerIds,
    required this.canBeInvitedBy,
    required this.canInviteThis,
    required this.posterIds,
  });

  factory PerformerInfo.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    List<PerformerChanceLink> _linkList(dynamic v) {
      if (v is! List) return const <PerformerChanceLink>[];
      return v
          .whereType<Map>()
          .map((e) => PerformerChanceLink.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    int? _nullableInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return PerformerInfo(
      band: json['band']?.toString(),
      showDurationMinutes: _nullableInt(json['showDurationMinutes']),
      callbackRequirementHours: _nullableInt(json['callbackRequirementHours']),
      baseEarnings: (json['baseEarnings'] is Map)
          ? PerformerEarnings.fromJson(
              Map<String, dynamic>.from(json['baseEarnings'] as Map),
            )
          : null,
      fansCustomerIds: _stringList(json['fansCustomerIds']),
      canBeInvitedBy: _linkList(json['canBeInvitedBy']),
      canInviteThis: _linkList(json['canInviteThis']),
      posterIds: _stringList(json['posterIds']),
    );
  }
}

class PerformerEarnings {
  final String currency; // film, cod, etc
  final double amountPerMinute;

  PerformerEarnings({
    required this.currency,
    required this.amountPerMinute,
  });

  factory PerformerEarnings.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '0').toString()) ?? 0.0;
    }

    return PerformerEarnings(
      currency: (json['currency'] ?? '').toString(),
      amountPerMinute: _toDouble(json['amountPerMinute']),
    );
  }
}

class PerformerChanceLink {
  final String performerId; // customer id of performer
  final double chancePercent; // store as 54.00 (percent)

  PerformerChanceLink({
    required this.performerId,
    required this.chancePercent,
  });

  factory PerformerChanceLink.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '0').toString()) ?? 0.0;
    }

    return PerformerChanceLink(
      performerId: (json['performerId'] ?? '').toString(),
      chancePercent: _toDouble(json['chancePercent']),
    );
  }
}
