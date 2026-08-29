import '../../shared/json_loader.dart';
import '../model/income.dart';

/// Loads the wiki-verified income tables.
///
/// Two assets back this:
///
/// * `assets/data/income.json` — every facility income effect, keyed by the
///   same facility id as `assets/data/facilities_jsons/*.json`, with the unit
///   the wiki printed kept in the channel name.
/// * `assets/data/performer_income.json` — concert performer earnings, keyed
///   by customer id.
///
/// Facilities absent from the map simply have no verified income; callers
/// must treat that as "no income", never as "zero because we couldn't parse
/// it". The two are the same number here only because a missing row means the
/// wiki printed no income effect for that facility at all.
class IncomeRepository {
  IncomeRepository._();

  static final IncomeRepository instance = IncomeRepository._();

  static const String facilityAsset = 'assets/data/income.json';
  static const String performerAsset = 'assets/data/performer_income.json';

  Map<String, List<IncomeEntry>>? _byFacilityId;
  Map<String, PerformerIncome>? _performers;
  String? _retrieved;

  Future<void>? _loadFuture;

  /// Date the wiki data was transcribed, for the "as of" line in the UI.
  String? get retrieved => _retrieved;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final decoded = await JsonLoader.load(facilityAsset);
      final root = decoded as Map<String, dynamic>;
      _retrieved = root['retrieved']?.toString();

      final facilities = (root['facilities'] as Map?) ?? const <String, dynamic>{};
      final out = <String, List<IncomeEntry>>{};
      facilities.forEach((key, value) {
        if (value is! List) return;
        final entries = <IncomeEntry>[];
        for (final raw in value) {
          if (raw is! Map) continue;
          final entry =
              IncomeEntry.tryFromJson(Map<String, dynamic>.from(raw));
          if (entry != null) entries.add(entry);
        }
        if (entries.isNotEmpty) out[key.toString()] = entries;
      });
      _byFacilityId = out;

      final perfDecoded = await JsonLoader.load(performerAsset);
      final perfRoot = perfDecoded as Map<String, dynamic>;
      final perfMap = (perfRoot['performers'] as Map?) ?? const <String, dynamic>{};
      final perfOut = <String, PerformerIncome>{};
      perfMap.forEach((key, value) {
        if (value is! Map) return;
        final p = PerformerIncome.tryFromJson(
          key.toString(),
          Map<String, dynamic>.from(value),
        );
        if (p != null) perfOut[key.toString()] = p;
      });
      _performers = perfOut;
    } catch (_) {
      _loadFuture = null; // allow a retry
      rethrow;
    }
  }

  /// Income effects for one facility id. Empty when the facility has none.
  List<IncomeEntry> forFacility(String id) =>
      _byFacilityId?[id] ?? const <IncomeEntry>[];

  /// Every facility id that has at least one verified income effect.
  Iterable<String> get facilityIdsWithIncome =>
      _byFacilityId?.keys ?? const <String>[];

  Map<String, PerformerIncome> get performers =>
      _performers ?? const <String, PerformerIncome>{};
}
