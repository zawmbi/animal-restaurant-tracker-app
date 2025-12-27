import '../../shared/json_loader.dart';
import '../model/battle_pass.dart';

class BattlePassRepository {
  BattlePassRepository._();
  static final BattlePassRepository instance = BattlePassRepository._();

  static const String _asset = 'assets/data/battle_passes/fantastical_party.json';

  BattlePass? _cache;

  Future<BattlePass> fantasticalParty() async {
    if (_cache != null) return _cache!;
    final raw = await JsonLoader.load(_asset) as Map<String, dynamic>;
    _cache = BattlePass.fromJson(raw);
    return _cache!;
  }

  Future<void> reload() async {
    _cache = null;
  }
}
