import '../../shared/json_loader.dart';
import '../model/pet.dart';

class PetsRepository {
  PetsRepository._();
  static final PetsRepository instance = PetsRepository._();

  static const _asset = 'assets/data/pets.json';

  PetsData? _cache;

  Future<PetsData> load() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as Map<String, dynamic>;
    _cache = PetsData.fromJson(data);
    return _cache!;
  }
}
