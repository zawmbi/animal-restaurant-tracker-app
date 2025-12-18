// ignore_for_file: duplicate_import

import '../../customers/data/customers_repository.dart';
import '../../customers/model/memento.dart';
import '../../shared/json_loader.dart';

class MementoEntry {
  final String key;          // m:<customerId>/<mementoId> or x:<mementoId>
  final String id;
  final String name;
  final int stars;
  final String requirement;
  final String description;
  final String? customerId;
  final String? customerName;
  final List<String> tags;
  final bool hidden;
  final String? source;
  final String? event;

  const MementoEntry({
    required this.key,
    required this.id,
    required this.name,
    required this.stars,
    required this.requirement,
    required this.description,
    required this.customerId,
    required this.customerName,
    required this.tags,
    required this.hidden,
    required this.source,
    required this.event,
  });
}

String _ckey(String customerId, String mementoId) => 'm:$customerId/$mementoId';
String _xkey(String mementoId) => 'x:$mementoId';

class MementosIndex {
  MementosIndex._();
  static final MementosIndex instance = MementosIndex._();

  static const _mainAsset = 'assets/data/mementos.json';        // NEW
  static const _extrasAsset = 'assets/data/mementos_extra.json';

  Future<List<MementoEntry>> all({
    List<String>? includeTags,
    String? search,
    bool? hidden,
  }) async {
    final results = <MementoEntry>[];

    // For customerName lookup
    final customers = await CustomersRepository.instance.all();
    final customerById = {
      for (final c in customers) c.id: c,
    };

    // 1) From standalone mementos.json (NEW)
    final mainRaw = await JsonLoader.load(_mainAsset) as List<dynamic>;
    for (final e in mainRaw) {
      final map = e as Map<String, dynamic>;

      final id = map['id'] as String;
      final customerId = map['customerId'] as String?;
      final customerName =
          customerId != null ? customerById[customerId]?.name : null;

      final tags =
          (map['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>();
      final isHidden = (map['hidden'] as bool? ?? false) || tags.contains('hidden');

      results.add(
        MementoEntry(
          key: customerId != null ? _ckey(customerId, id) : _xkey(id),
          id: id,
          name: map['name'] as String,
          stars: map['stars'] as int? ?? 0,
          requirement: map['requirement'] as String? ?? '',
          description: map['description'] as String? ?? '',
          customerId: customerId,
          customerName: customerName,
          tags: tags,
          hidden: isHidden,
          source: map['source'] as String?,
          event: map['event'] as String?,
        ),
      );
    }

    // 2) From extras JSON (same as before)
    final extrasRaw = await JsonLoader.load(_extrasAsset) as List<dynamic>;
    for (final e in extrasRaw) {
      final m = Memento.fromJson(e as Map<String, dynamic>);
      final tags = m.tags;
      final isHidden = m.hidden || tags.contains('hidden');

      results.add(
        MementoEntry(
          key: _xkey(m.id),
          id: m.id,
          name: m.name,
          stars: m.stars,
          requirement: m.requirement,
          description: m.description,
          customerId: null,
          customerName: null,
          tags: tags,
          hidden: isHidden,
          source: m.source,
          event: m.event,
        ),
      );
    }

    // filtering (unchanged)
    Iterable<MementoEntry> out = results;
    if (includeTags != null && includeTags.isNotEmpty) {
      out = out.where((e) => e.tags.any(includeTags.contains));
    }
    if (hidden != null) {
      out = out.where((e) => e.hidden == hidden);
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      out = out.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          (e.customerName?.toLowerCase().contains(q) ?? false));
    }
    return out.toList();
  }
    Future<MementoEntry?> byId(String id) async {
    final list = await all(hidden: null); // include hidden too
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

}
