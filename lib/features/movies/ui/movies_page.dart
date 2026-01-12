import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/movies_repository.dart';
import '../model/movie.dart';
import 'movies_detail_page.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  static const String _bucket = 'movie_act';
  final store = UnlockedStore.instance;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucket);
  }

  int _checkedCount(Movie m) {
    var c = 0;
    for (final k in m.allActKeys()) {
      if (store.isUnlocked(_bucket, k)) c++;
    }
    return c;
  }

  bool _isComplete(Movie m) => _checkedCount(m) == m.actCount;

  Future<void> _setAll(Movie m, bool value) async {
    for (final k in m.allActKeys()) {
      await store.setUnlocked(_bucket, k, value);
    }
  }

  // Map JSON currency keys -> actual asset filenames in assets/images/
  String _currencyAsset(String currencyKey) {
    switch (currencyKey) {
      case 'plates':
        return 'assets/images/plate.png';
      case 'diamonds':
        return 'assets/images/diamond.png';
      case 'bells':
        return 'assets/images/bell.png';
      case 'cod':
        return 'assets/images/cod.png';
      case 'film':
        return 'assets/images/film.png';
      case 'like':
        return 'assets/images/like.png';
      case 'star':
        return 'assets/images/star.png';
      default:
        return 'assets/images/$currencyKey.png';
    }
  }

  Widget _currencyIcon(String currencyKey, double size) {
    return Image.asset(
      _currencyAsset(currencyKey),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: FutureBuilder<List<Movie>>(
        future: MoviesRepository.instance.all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final movies = snap.data!;

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = movies[i];
                  final checked = _checkedCount(m);

                  return Card(
                    child: ListTile(
                      title: Text(m.name),
                      subtitle: Row(
                        children: [
                          Text('$checked / ${m.actCount} acts'),
                          if (m.reward != null && (m.reward!.amount > 0)) ...[
                            const SizedBox(width: 12),
                            _currencyIcon(m.reward!.currency, 16),
                            const SizedBox(width: 6),
                            Text('${m.reward!.amount}'),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Check all acts',
                            onPressed: () => _setAll(m, true),
                            icon: const Icon(Icons.done_all),
                          ),
                          IconButton(
                            tooltip: 'Clear all acts',
                            onPressed: () => _setAll(m, false),
                            icon: const Icon(Icons.clear_all),
                          ),
                          Checkbox(
                            value: _isComplete(m),
                            onChanged: (v) => _setAll(m, v ?? false),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(movieId: m.id),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
