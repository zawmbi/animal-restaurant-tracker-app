class MovieReward {
  final String currency; // 'cod', 'film', 'bells', 'plates', 'diamonds'
  final int amount;

  const MovieReward({
    required this.currency,
    required this.amount,
  });

  factory MovieReward.fromJson(Map<String, dynamic> json) {
    return MovieReward(
      currency: (json['currency'] as String?) ?? 'cod',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'amount': amount,
      };
}

class Movie {
  final String id;
  final String name;
  final int actCount;
  final MovieReward? reward;

  const Movie({
    required this.id,
    required this.name,
    required this.actCount,
    required this.reward,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      name: json['name'] as String,
      actCount: (json['actCount'] as num).toInt(),
      reward: json['reward'] == null
          ? null
          : MovieReward.fromJson(json['reward'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'actCount': actCount,
        'reward': reward?.toJson(),
      };

  /// Key used in UnlockedStore for an act
  String actKey(int actIndex1Based) => 'movie:$id:act:$actIndex1Based';

  List<String> allActKeys() =>
      List<String>.generate(actCount, (i) => actKey(i + 1));
}
