
enum RewardKind {
  facility,
  memento,
  currency,
  rating,
  // Add later if you want: furniture, customer, dish, letter, fish, flower...
}

class RewardRef {
  final RewardKind kind;

  // For linkable entities:
  final String? id;

  // For currency:
  final String? currency;
  final int? amount;

  // For rating:
  final int? earnedStars;

  const RewardRef._({
    required this.kind,
    this.id,
    this.currency,
    this.amount,
    this.earnedStars,
  });

  factory RewardRef.fromJson(Map<String, dynamic> j) {
    final kindStr = (j['kind'] as String).trim();
    final kind = RewardKind.values.firstWhere(
      (e) => e.name == kindStr,
      orElse: () => RewardKind.currency, // safe fallback
    );

    switch (kind) {
      case RewardKind.facility:
      case RewardKind.memento:
        return RewardRef._(kind: kind, id: j['id'] as String);
      case RewardKind.currency:
        return RewardRef._(
          kind: kind,
          currency: j['currency'] as String,
          amount: (j['amount'] as num).toInt(),
        );
      case RewardKind.rating:
        return RewardRef._(
          kind: kind,
          earnedStars: (j['amount'] as num).toInt(),
        );
    }
  }
}
