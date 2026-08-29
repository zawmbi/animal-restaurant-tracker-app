import '../../shared/json_loader.dart';
import '../model/battle_pass.dart';

class BattlePassRepository {
  BattlePassRepository._();
  static final BattlePassRepository instance = BattlePassRepository._();

  static const Map<String, String> _assetsById = {
    'fantastical_party': 'assets/data/battle_passes/fantastical_party.json',
    'deep_sea_ballad': 'assets/data/battle_passes/deep_sea_ballad.json',
    'midsummer_birdsong': 'assets/data/battle_passes/midsummer_birdsong.json',
    'slumberous_nights': 'assets/data/battle_passes/slumberous_nights.json',
  };

  final Map<String, BattlePass> _cacheById = {};

  /// Cached *futures*, so two widgets asking for the same pass before the
  /// first load finishes share one load + parse instead of racing.
  final Map<String, Future<BattlePass>> _futuresById = {};

  // Kept `async` so an unknown id surfaces as a failed Future, exactly as
  // before, rather than throwing synchronously inside a caller's build().
  Future<BattlePass> byId(String id) async {
    final cached = _cacheById[id];
    if (cached != null) return cached;

    final asset = _assetsById[id];
    if (asset == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Unknown battle pass id. Add it to BattlePassRepository._assetsById.',
      );
    }

    return _futuresById[id] ??= _load(id, asset);
  }

  Future<BattlePass> _load(String id, String asset) async {
    try {
      final raw = await JsonLoader.load(asset) as Map<String, dynamic>;
      final pass = BattlePass.fromJson(raw);
      // Sole consumer of this asset; the parsed model replaces the raw maps.
      JsonLoader.evict(asset);
      _cacheById[id] = pass;
      return pass;
    } catch (_) {
      _futuresById.remove(id); // allow a retry
      rethrow;
    }
  }

  Future<BattlePass> fantasticalParty() => byId('fantastical_party');
  Future<BattlePass> deepSeaBallad() => byId('deep_sea_ballad');
  Future<BattlePass> midsummerBirdsong() => byId('midsummer_birdsong');
  Future<BattlePass> slumberousNights() => byId('slumberous_nights');

  List<String> get availableIds =>
      _assetsById.keys.toList(growable: false);

  Future<void> reload() async {
    _cacheById.clear();
    _futuresById.clear();
  }
}
