import '../../shared/json_loader.dart';
import '../model/letter.dart';

class LettersRepository {
  static const _asset = 'assets/data/letters.json';
  LettersRepository._();
  static final LettersRepository instance = LettersRepository._();
  List<Letter>? _cache;

  Future<List<Letter>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => Letter.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}