import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/customer.dart';

class CustomersRepository {
  static const _asset = 'assets/data/customers.json';
  static const _boothOwnerAsset = 'assets/data/booth_owners.json';
  CustomersRepository._();
  static final CustomersRepository instance = CustomersRepository._();
  List<Customer>? _cache;

  Future<List<Customer>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    final boothData = await JsonLoader.load(_boothOwnerAsset) as Map<String, dynamic>;
    _cache = data.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final id = map['id']?.toString() ?? '';
      if (boothData.containsKey(id)) {
        map['boothOwner'] = boothData[id];
      }
      return Customer.fromJson(map);
    }).toList();
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

  Future<List<Customer>> seasonal() async {
    final list = await all();
    return list.where((c) => c.season != null).toList();
  }
}
