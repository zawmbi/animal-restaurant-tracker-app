// lib/features/shared/data/progress_links.dart
//
// Ties together ids that two pages track separately but that are the same
// thing in the game, so checking it on one page checks it on the other.

import '../../customers/data/posters_repository.dart';
import '../../mementos/data/mementos_index.dart';
import 'unlocked_store.dart';

/// Every poster on the Posters page that also appears on the Mementos page's
/// Poster tab, as (posterBucket, posterId, mementoBucket, mementoKey).
///
/// Posters are matched to mementos tagged 'poster' by id. Posters with no
/// memento entry are simply left unlinked.
Future<List<(String, String, String, String)>> posterMementoPairs() async {
  final posters = await PostersRepository.instance.all();
  final mementos = await MementosIndex.instance.all(hidden: null);

  final keysById = <String, List<String>>{};
  for (final m in mementos) {
    if (!m.tags.contains('poster')) continue;
    (keysById[m.id] ??= <String>[]).add(m.key);
  }

  return <(String, String, String, String)>[
    for (final p in posters)
      for (final key in keysById[p.id] ?? const <String>[])
        ('poster', p.id, 'memento_collected', key),
  ];
}

/// Registers every link with [UnlockedStore]. Safe to call more than once.
Future<void> registerProgressLinks() async {
  await UnlockedStore.instance.linkIds(await posterMementoPairs());
}
