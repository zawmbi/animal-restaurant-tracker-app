import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/movies_repository.dart';
import '../model/movie.dart';

class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({super.key, required this.movieId});
  final String movieId;

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  static const String _bucket = 'movie_act';
  final store = UnlockedStore.instance;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucket);
  }

  Future<void> _setAll(Movie m, bool value) async {
    for (final k in m.allActKeys()) {
      await store.setUnlocked(_bucket, k, value);
    }
  }

  bool _isComplete(Movie m) {
    for (final k in m.allActKeys()) {
      if (!store.isUnlocked(_bucket, k)) return false;
    }
    return true;
  }

  int _checkedCount(Movie m) {
    var c = 0;
    for (final k in m.allActKeys()) {
      if (store.isUnlocked(_bucket, k)) c++;
    }
    return c;
  }

  Widget _currencyIcon(String currencyKey, double size) {
    return Image.asset(
      'assets/images/$currencyKey.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Movie?>(
      future: MoviesRepository.instance.byId(widget.movieId),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Movie')),
              body: Center(child: Text('Error: ${snap.error}')),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final movie = snap.data;
        if (movie == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Movie')),
            body: const Center(child: Text('Movie not found')),
          );
        }

        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final checked = _checkedCount(movie);

            return Scaffold(
              appBar: AppBar(
                title: Text(movie.name),
                actions: [
                  IconButton(
                    tooltip: 'Check all acts',
                    onPressed: () => _setAll(movie, true),
                    icon: const Icon(Icons.done_all),
                  ),
                  IconButton(
                    tooltip: 'Clear all acts',
                    onPressed: () => _setAll(movie, false),
                    icon: const Icon(Icons.clear_all),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: ListTile(
                      title: Text('Progress: $checked / ${movie.actCount}'),
                      subtitle: (movie.reward != null && movie.reward!.amount > 0)
                          ? Row(
                              children: [
                                const Text('Reward: '),
                                _currencyIcon(movie.reward!.currency, 16),
                                const SizedBox(width: 6),
                                Text('${movie.reward!.amount}'),
                              ],
                            )
                          : null,
                      trailing: Checkbox(
                        value: _isComplete(movie),
                        onChanged: (v) => _setAll(movie, v ?? false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(movie.actCount, (i) {
                    final actNum = i + 1;
                    final key = movie.actKey(actNum);
                    final isOn = store.isUnlocked(_bucket, key);

                    return Card(
                      child: CheckboxListTile(
                        value: isOn,
                        onChanged: (v) => store.setUnlocked(_bucket, key, v ?? false),
                        title: Text('Act $actNum'),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
