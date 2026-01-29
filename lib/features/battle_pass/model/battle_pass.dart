import 'package:flutter/foundation.dart';

enum BattlePassRewardType {
  facility,
  memento,
  currency,
  rating,
  item, // flowers, fish, etc.
  gachaDraw,
  promoteFree,
  chest,
  text,
}

@immutable
class BattlePassReward {
  final BattlePassRewardType type;

  // For facility/memento/item/chest
  final String? id;

  // For currency
  final String? currency; // cod, film, plates, bells, diamonds, etc.
  final int? amount;

  // For rating
  final int? earnedStars;

  // For items (flowers/fish/etc)
  final String? itemType; // flower, fish, etc.
  final int? level; // flower level, etc.
  final int? qty;

  // For display-only notes
  final String? text;

  const BattlePassReward({
    required this.type,
    this.id,
    this.currency,
    this.amount,
    this.earnedStars,
    this.itemType,
    this.level,
    this.qty,
    this.text,
  });

  factory BattlePassReward.fromJson(Map<String, dynamic> j) {
    final t = (j['type'] as String).trim();
    final type = _parseType(t);

    return BattlePassReward(
      type: type,
      id: j['id'] as String?,
      currency: j['currency'] as String?,
      amount: (j['amount'] as num?)?.toInt(),
      earnedStars: (j['earnedStars'] as num?)?.toInt(),
      itemType: j['itemType'] as String?,
      level: (j['level'] as num?)?.toInt(),
      qty: (j['qty'] as num?)?.toInt(),
      text: j['text'] as String?,
    );
  }

  static BattlePassRewardType _parseType(String s) {
    switch (s) {
      case 'facility':
        return BattlePassRewardType.facility;
      case 'memento':
        return BattlePassRewardType.memento;
      case 'currency':
        return BattlePassRewardType.currency;
      case 'rating':
        return BattlePassRewardType.rating;
      case 'item':
        return BattlePassRewardType.item;
      case 'gacha_draw':
        return BattlePassRewardType.gachaDraw;
      case 'promote_free':
        return BattlePassRewardType.promoteFree;
      case 'chest':
        return BattlePassRewardType.chest;
      case 'text':
      default:
        return BattlePassRewardType.text;
    }
  }
}

@immutable
class BattlePassTier {
  final int exp;
  final List<BattlePassReward> normalRewards;
  final List<BattlePassReward> superRewards;

  const BattlePassTier({
    required this.exp,
    required this.normalRewards,
    required this.superRewards,
  });

  factory BattlePassTier.fromJson(Map<String, dynamic> j) {
    final n = (j['normalRewards'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(BattlePassReward.fromJson)
        .toList();

    final s = (j['superRewards'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(BattlePassReward.fromJson)
        .toList();

    return BattlePassTier(
      exp: (j['exp'] as num).toInt(),
      normalRewards: n,
      superRewards: s,
    );
  }
}

@immutable
class BattlePassPhase {
  final String id; // phase_1, phase_2, phase_3
  final String name; // Fantastical Party Phase 1...
  final String start; // "2023-08-18 06:00"
  final String end; // "2023-10-19 06:00"
  final String completionNote; // optional description
  final List<BattlePassTier> tiers;
  final Map<String, dynamic>? extra; // stash extra notes if you want later

  const BattlePassPhase({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.completionNote,
    required this.tiers,
    required this.extra,
  });

  factory BattlePassPhase.fromJson(Map<String, dynamic> j) {
    final tiers = (j['tiers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(BattlePassTier.fromJson)
        .toList();

    return BattlePassPhase(
      id: j['id'] as String,
      name: j['name'] as String,
      start: j['start'] as String? ?? '',
      end: j['end'] as String? ?? '',
      completionNote: j['completionNote'] as String? ?? '',
      tiers: tiers,
      extra: j['extra'] as Map<String, dynamic>?,
    );
  }
}

@immutable
class BattlePass {
  final String id; // fantastical_party
  final String name; // Fantastical Party
  final String introducedInVersion; // v9.7.0
  final int seasonDays; // 62
  final String overview;
  final String eventRule;
  final List<String> notes;
  final List<BattlePassPhase> phases;

  const BattlePass({
    required this.id,
    required this.name,
    required this.introducedInVersion,
    required this.seasonDays,
    required this.overview,
    required this.eventRule,
    required this.notes,
    required this.phases,
  });

  factory BattlePass.fromJson(Map<String, dynamic> j) {
    return BattlePass(
      id: j['id'] as String,
      name: j['name'] as String,
      introducedInVersion: j['introducedInVersion'] as String? ?? '',
      seasonDays: (j['seasonDays'] as num?)?.toInt() ?? 0,
      overview: j['overview'] as String? ?? '',
      eventRule: j['eventRule'] as String? ?? '',
      notes: (j['notes'] as List<dynamic>? ?? const []).cast<String>(),
      phases: (j['phases'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(BattlePassPhase.fromJson)
          .toList(),
    );
  }
}
