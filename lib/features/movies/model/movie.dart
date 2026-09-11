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

/// One act of one movie, named the way the battle pass names it.
///
/// Battle pass rewards refer to a film act as `<movieId>_act_<roman>_fragment`
/// — `seaside_songstress_act_i_fragment`. Nothing else in the data uses roman
/// numerals, so the parsing lives here next to [Movie.actKey] rather than in a
/// UI file, and both the phase list and the tier detail read the same answer.
class MovieActRef {
  final String movieId;

  /// 1-based, matching [Movie.actKey].
  final int act;

  const MovieActRef(this.movieId, this.act);

  static const List<String> _roman = <String>[
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
  ];

  /// Parses a reward id, or returns null if it is not shaped like an act.
  ///
  /// Returning null rather than throwing keeps an unrecognised id rendering as
  /// its raw slug instead of crashing a battle pass page.
  static MovieActRef? tryParse(String rewardId) {
    const suffix = '_fragment';
    var s = rewardId.trim().toLowerCase();
    if (s.endsWith(suffix)) s = s.substring(0, s.length - suffix.length);

    final marker = s.lastIndexOf('_act_');
    if (marker <= 0) return null;

    final movieId = s.substring(0, marker);
    final actPart = s.substring(marker + '_act_'.length);
    if (movieId.isEmpty || actPart.isEmpty) return null;

    final roman = _roman.indexOf(actPart);
    if (roman != -1) return MovieActRef(movieId, roman + 1);

    final digits = int.tryParse(actPart);
    if (digits != null && digits > 0) return MovieActRef(movieId, digits);

    return null;
  }

  /// `I`, `II`, ... for display. Falls back to the number past the table.
  String get actLabel =>
      act >= 1 && act <= _roman.length ? _roman[act - 1].toUpperCase() : '$act';
}
