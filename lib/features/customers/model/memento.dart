class Memento {
  final String id;
  final String name;
  final String description;
  final int earnedStars;     // e.g., +5
  final String requirement;   // human text requirement
  final List<String> tags;    // e.g., ['customer_gift','logbook_default']
  final bool hidden;          // convenient flag (also mirror via a 'hidden' tag)
  final String? source;       // e.g., 'customer_gift','gachapon','wishing_well','poster','redemption_code'
  final List<String> equips;  // optional: which staff/slots it can equip
  final int? shareReward;     // optional: cod amount from sharing
  final String? event;        // optional: e.g., 'Anniversary 2022'

  const Memento({
    required this.id,
    required this.name,
    required this.description,
    required this.earnedStars,
    required this.requirement,
    this.tags = const [],
    this.hidden = false,
    this.source,
    this.equips = const [],
    this.shareReward,
    this.event,
  });

  factory Memento.fromJson(Map<String, dynamic> j) => Memento(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        earnedStars: j['earnedStars'] as int? ?? 0,
        requirement: j['requirement'] as String? ?? '',
        tags: (j['tags'] as List? ?? const []).cast<String>(),
        hidden: j['hidden'] as bool? ?? false,
        source: j['source'] as String?,
        equips: (j['equips'] as List? ?? const []).cast<String>(),
        shareReward: j['shareReward'] as int?,
        event: j['event'] as String?,
      );
}