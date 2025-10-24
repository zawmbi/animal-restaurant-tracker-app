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

  static const _extrasAsset = 'assets/data/mementos_extra.json';

  Future<List<MementoEntry>> all({
    List<String>? includeTags,
    String? search,
    bool? hidden,
  }) async {
    final results = <MementoEntry>[];

    // 1) From customers
    final customers = await CustomersRepository.instance.all();
    for (final c in customers) {
      for (final m in c.mementos) {
        final entry = MementoEntry(
          key: _ckey(c.id, m.id),
          id: m.id,
          name: m.name,
          stars: m.stars,
          requirement: m.requirement,
          description: m.description,
          customerId: c.id,
          customerName: c.name,
          tags: m.tags,
          hidden: m.hidden || m.tags.contains('hidden'),
          source: m.source,
          event: m.event,
        );
        results.add(entry);
      }
    }

    // 2) From extras JSON
    final extrasRaw = await JsonLoader.load(_extrasAsset) as List<dynamic>;
    for (final e in extrasRaw) {
      final m = Memento.fromJson(e as Map<String, dynamic>);
      results.add(MementoEntry(
        key: _xkey(m.id),
        id: m.id,
        name: m.name,
        stars: m.stars,
        requirement: m.requirement,
        description: m.description,
        customerId: null,
        customerName: null,
        tags: m.tags,
        hidden: m.hidden || m.tags.contains('hidden'),
        source: m.source,
        event: m.event,
      ));
    }

    // filtering
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
}