import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/customer.dart';

class CustomersRepository {
  static const _asset = 'assets/data/customers.json';
  CustomersRepository._();
  static final CustomersRepository instance = CustomersRepository._();
  List<Customer>? _cache;

  Future<List<Customer>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  Future<Customer?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Customer>> withTag(String tag) async {
    final list = await all();
  return list.where((c) => c.tags.contains(tag)).toList();
  }
}
