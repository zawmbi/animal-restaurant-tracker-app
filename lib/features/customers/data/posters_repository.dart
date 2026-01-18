import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/poster.dart';

class PostersRepository {
  static const _asset = 'assets/data/posters.json';
  PostersRepository._();
  static final PostersRepository instance = PostersRepository._();

  List<Poster>? _cache;

  Future<List<Poster>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => Poster.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<Poster?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
