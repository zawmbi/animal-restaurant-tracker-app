class Letter {
  final String id;
  final String name;
  final String? series;
  final String? unlockRequirement;

  const Letter({
    required this.id,
    required this.name,
    this.series,
    this.unlockRequirement,
  });

  factory Letter.fromJson(Map<String, dynamic> j) => Letter(
        id: j['id'] as String,
        name: j['name'] as String,
        series: j['series'] as String?,
        unlockRequirement: j['unlockRequirement'] as String?,
      );
}