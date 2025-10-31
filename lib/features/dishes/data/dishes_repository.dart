import '../../shared/json_loader.dart';
import '../model/dish.dart';

class DishesRepository {
  static const _asset = 'assets/data/dishes.json';
  DishesRepository._();
  static final DishesRepository instance = DishesRepository._();
  List<Dish>? _cache;

  Future<List<Dish>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  Future<Dish?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
