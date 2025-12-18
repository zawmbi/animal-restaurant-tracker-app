class AromaticAcornStage {
  final String id; // e.g. "entrance", "1", "2"...
  final String title; // e.g. "Aromatic Acorn 1-Star Judging"
  final List<String> requirements;
  final List<String> tasks;
  final List<String> rewards;

  const AromaticAcornStage({
    required this.id,
    required this.title,
    required this.requirements,
    required this.tasks,
    required this.rewards,
  });
}
