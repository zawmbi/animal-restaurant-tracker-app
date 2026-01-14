// lib/features/letters/data/letters_repository.dart
import '../../shared/json_loader.dart';
import '../model/letter.dart';

class LettersRepository {
  static const _asset = 'assets/data/letters.json';

  LettersRepository._();
  static final LettersRepository instance = LettersRepository._();

  List<Letter>? _cache;
  Future<Letter?> byId(String id) async {
    final list = await all();
    for (final l in list) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<List<Letter>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => Letter.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
