import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/customer.dart';

class CustomersRepository {
  static const _asset = 'assets/data/customers.json';
  static const _boothOwnerAsset = 'assets/data/booth_owners.json';
  CustomersRepository._();
  static final CustomersRepository instance = CustomersRepository._();

  List<Customer>? _cache;

  /// Cached *future*, so concurrent callers (the search index preloading from
  /// the home page, plus whichever page the user opens) share one load and one
  /// parse of the 315 KB customers.json instead of each doing their own.
  /// Returning a stable Future also stops `FutureBuilder`s that call `all()`
  /// straight from `build()` from re-subscribing on every rebuild.
  Future<List<Customer>>? _future;

  // Derived views, memoised so a rebuild does not re-filter 564 customers.
  final Map<String, Future<List<Customer>>> _byTag = {};
  Future<List<Customer>>? _seasonal;

  Future<List<Customer>> all() => _future ??= _load();

  Future<List<Customer>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final boothData =
          await JsonLoader.load(_boothOwnerAsset) as Map<String, dynamic>;
      final out = data.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final id = map['id']?.toString() ?? '';
        if (boothData.containsKey(id)) {
          map['boothOwner'] = boothData[id];
        }
        return Customer.fromJson(map);
      }).toList();

      // The raw maps are no longer needed: this repository is the only
      // consumer of these two assets and it now holds the parsed models.
      JsonLoader.evict(_asset);
      JsonLoader.evict(_boothOwnerAsset);

      _cache = out;
      return out;
    } catch (_) {
      _future = null; // allow a retry
      rethrow;
    }
  }

  /// Synchronously available once [all] has completed.
  List<Customer>? get cached => _cache;

  Future<Customer?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Customer>> withTag(String tag) => _byTag[tag] ??= _withTag(tag);

  Future<List<Customer>> _withTag(String tag) async {
    try {
      final list = await all();
      return list.where((c) => c.tags.contains(tag)).toList();
    } catch (_) {
      _byTag.remove(tag); // allow a retry
      rethrow;
    }
  }

  Future<List<Customer>> seasonal() => _seasonal ??= _seasonalImpl();

  Future<List<Customer>> _seasonalImpl() async {
    try {
      final list = await all();
      return list.where((c) => c.season != null).toList();
    } catch (_) {
      _seasonal = null; // allow a retry
      rethrow;
    }
  }
}
