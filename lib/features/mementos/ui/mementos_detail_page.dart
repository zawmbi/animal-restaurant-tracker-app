import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../../shared/json_loader.dart';
import '../../shared/utils/entity_linker.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../shared/widgets/entity_chip.dart';
import '../data/mementos_index.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart';

/// Structured `requirements` objects from `assets/data/mementos.json`, keyed by
/// memento id.
///
/// This field is additive and is NOT populated for every memento, so a missing
/// entry just means "render the free-text `requirement` instead". Read here
/// rather than through MementosIndex because MementoEntry does not expose it
/// yet. Loaded once and shared; JsonLoader already caches the decode.
Future<Map<String, Map<String, dynamic>>>? _mementoRequirementsFuture;

Future<Map<String, Map<String, dynamic>>> _loadMementoRequirements() {
  final cached = _mementoRequirementsFuture;
  if (cached != null) return cached;
  final future = _readMementoRequirements();
  _mementoRequirementsFuture = future;
  return future;
}

Future<Map<String, Map<String, dynamic>>> _readMementoRequirements() async {
  final out = <String, Map<String, dynamic>>{};
  try {
    final raw = await JsonLoader.load('assets/data/mementos.json');
    if (raw is! List) return out;
    for (final entry in raw) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final requirements = entry['requirements'];
      if (requirements is Map) {
        out[id] = Map<String, dynamic>.from(requirements);
      }
    }
  } catch (_) {
    // Structured requirements are optional; the free-text line still renders.
  }
  return out;
}

/// Everything the requirements section needs, resolved once.
class _RequirementData {
  const _RequirementData(this.structured, this.customerNames);

  /// The memento's `requirements` object, or empty when it has none.
  final Map<String, dynamic> structured;

  /// customer id -> display name, for turning `card_playing_mouse` into
  /// "Card-Playing Mouse".
  final Map<String, String> customerNames;
}

/// Detail page for a single memento.
/// Navigate here from MementosPage with:
///   Navigator.of(context).push(
///     MaterialPageRoute(
///       builder: (_) => MementoDetailPage(memento: entry),
///     ),
///   );
class MementoDetailPage extends StatefulWidget {
  final MementoEntry memento;

  const MementoDetailPage({super.key, required this.memento});

  @override
  State<MementoDetailPage> createState() => _MementoDetailPageState();
}

class _MementoDetailPageState extends State<MementoDetailPage> {
  final store = UnlockedStore.instance;

  MementoEntry get memento => widget.memento;

  /// Every memento key belonging to this memento's customer, so the whole
  /// group can be checked off in one go.
  late final Future<List<String>> _customerMementoKeys;

  /// The structured requirement object for this memento (plus the names it
  /// refers to), or empty when the data does not carry one.
  late final Future<_RequirementData> _requirementData;

  @override
  void initState() {
    super.initState();
    _customerMementoKeys = _loadCustomerMementoKeys();
    _requirementData = _loadRequirementData();
  }

  Future<_RequirementData> _loadRequirementData() async {
    final index = await _loadMementoRequirements();
    final structured = index[memento.id] ?? const <String, dynamic>{};

    final names = <String, String>{};
    try {
      for (final c in await CustomersRepository.instance.all()) {
        names[c.id] = c.name;
      }
    } catch (_) {
      // Ids still render, just not as display names.
    }

    return _RequirementData(structured, names);
  }

  Future<List<String>> _loadCustomerMementoKeys() async {
    final customerId = memento.customerId;
    if (customerId == null) return const <String>[];

    try {
      final all = await MementosIndex.instance.all();
      final byId = <String, MementoEntry>{for (final e in all) e.id: e};

      // Keys come from MementosIndex only, so this group always matches what
      // the completion percentage counts. The customer's embedded `mementos`
      // array holds the same ids, not extra ones, so it is only used to catch
      // anything the customerId scan missed.
      final keys = <String>{};
      for (final e in all) {
        if (e.customerId == customerId) keys.add(e.key);
      }

      final customer = await CustomersRepository.instance.byId(customerId);
      if (customer != null) {
        for (final m in customer.mementos) {
          final entry = byId[m.id];
          if (entry != null) keys.add(entry.key);
        }
      }

      return keys.toList();
    } catch (_) {
      // The rest of the page still works without the group control.
      return const <String>[];
    }
  }

  List<String> get _tags => memento.tags;

  // Kinds
  bool get isPoster => _tags.contains('poster');
  bool get isDressUp =>
      _tags.contains('dress_up') || _tags.contains('wearable');

  // Dress-up sub-types
  bool get isClothing => _tags.contains('clothing');
  bool get isAccessory => _tags.contains('clothing_accessory');
  bool get isRestaurantDecoration => _tags.contains('restaurant_decoration');
  bool get isFishPondBoat => _tags.contains('fish_pond_boat');
  bool get isTakeoutCart => _tags.contains('takeout_cart');

  bool get _collected => store.isUnlocked('memento_collected', memento.key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(memento.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Top info: owned + basic details ----------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Owned checkbox
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Owned',
                              style: theme.textTheme.titleMedium,
                            ),
                            Checkbox(
                              value: _collected,
                              onChanged: (v) => store.setUnlocked(
                                'memento_collected',
                                memento.key,
                                v ?? false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ----- Memento Name -----
                        _sectionTitle(theme, 'Memento Name'),
                        Text(
                          memento.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // ----- Description -----
                        _sectionTitle(theme, 'Memento Description'),
                        if (memento.description.isNotEmpty) ...[
                          Text(
                            memento.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ] else ...[
                          Text(
                            '(No description provided)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ----- Requirements -----
                        _buildRequirementsSection(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ---------- Type-specific sections ----------
                if (!isDressUp && !isPoster)
                  _buildRegularMementoSection(context, theme),

                if (isDressUp) _buildDressUpSection(context, theme),

                if (isPoster) _buildPosterSection(context, theme),

                if (!isDressUp && !isPoster) const SizedBox(height: 16),

                // ---------- Rating + Hidden ----------
                _buildRatingAndHiddenSection(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style:
            theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // ----- Regular Mementos (non wearables, non posters) -----

  Widget _buildRegularMementoSection(BuildContext context, ThemeData theme) {
    final hasCustomer = (memento.customerName ?? '').isNotEmpty;
    final hasSource = (memento.source ?? '').isNotEmpty;
    final hasEvent = (memento.event ?? '').isNotEmpty;

    if (!hasCustomer && !hasSource && !hasEvent) {
      // Nothing extra to show beyond description + rating
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Memento Details'),

            // Customer: clickable → specific customer page
            if (hasCustomer)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openCustomer(context),
                child: Text(
                  'Customer: ${memento.customerName}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            // Whole-customer memento group, so you do not have to open every
            // memento one at a time.
            if (hasCustomer)
              FutureBuilder<List<String>>(
                future: _customerMementoKeys,
                builder: (context, snap) {
                  final keys = snap.data ?? const <String>[];
                  if (keys.length < 2) return const SizedBox.shrink();

                  final collected = keys
                      .where((k) => store.isUnlocked('memento_collected', k))
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mementos from this customer: '
                          '$collected/${keys.length}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      CheckAllButton(
                        bucket: 'memento_collected',
                        ids: keys,
                        groupLabel: '${memento.customerName} mementos',
                      ),
                    ],
                  );
                },
              ),

            // Source: clickable stub
            if (hasSource)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openSource(context),
                child: Text(
                  'Source: ${memento.source}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            // Event: clickable stub
            if (hasEvent)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openEvent(context),
                child: Text(
                  'Event: ${memento.event}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- Dress-Up Mementos -----

  Widget _buildDressUpSection(BuildContext context, ThemeData theme) {
    final hasSource = (memento.source ?? '').isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Dress-Up'),

            // Basic type info based on tags
            if (isClothing) ...[
              const Text('Type: Clothing'),
              const SizedBox(height: 8),
            ] else if (isAccessory) ...[
              const Text('Type: Clothing Accessory'),
              const SizedBox(height: 8),
            ] else if (isRestaurantDecoration) ...[
              const Text('Type: Restaurant Decoration'),
              const SizedBox(height: 8),
            ] else if (isFishPondBoat) ...[
              const Text('Type: Fish Pond Boat'),
              const SizedBox(height: 8),
            ] else if (isTakeoutCart) ...[
              const Text('Type: Takeout Cart'),
              const SizedBox(height: 8),
            ],

            // If the memento has a source in your JSON, show it.
            if (hasSource) ...[
              Text('Obtained from: ${memento.source}'),
            ],
          ],
        ),
      ),
    );
  }

  // ----- Poster Mementos -----

  Widget _buildPosterSection(BuildContext context, ThemeData theme) {
    final hasEvent = (memento.event ?? '').isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Poster'),
            const Text('Category: Courtyard Poster'),
            const SizedBox(height: 4),
            const Text('Can be displayed in the courtyard'),
            if (hasEvent)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openEvent(context),
                child: Text(
                  'Event: ${memento.event}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- Requirements / "Memento Requirements" -----

  Widget _buildRequirementsSection(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _structuredRequirement,
      builder: (context, snap) {
        final structured = snap.data ?? const <String, dynamic>{};
        final raw = memento.requirement.trim();

        final structuredRows =
            _structuredRequirementRows(context, theme, structured);

        if (structuredRows.isEmpty && raw.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Memento Requirements'),
            // Structured chips when the data has them, otherwise the
            // free-text requirement. A missing structured field must never
            // blank the section out.
            if (structuredRows.isNotEmpty)
              ...structuredRows
            else
              _rawRequirement(context, theme, raw),
          ],
        );
      },
    );
  }

  /// Renders a structured `requirements` object using the same chip vocabulary
  /// the rest of the app uses for linked entities.
  List<Widget> _structuredRequirementRows(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> structured,
  ) {
    final out = <Widget>[];
    if (structured.isEmpty) return out;

    final keys = structured.keys.toList()..sort();
    for (final key in keys) {
      final value = structured[key];
      final label = _prettyRequirementKey(key);

      if (value is List) {
        var items = value.map((e) => e.toString()).toList();

        // This memento's own customer is already stated by the "Customer: X"
        // link above; rendering it again as a requirement chip would be the
        // same fact twice on one page.
        if (_normalizeKey(key) == 'customers' && memento.customerId != null) {
          items = items.where((e) => e != memento.customerId).toList();
        }

        if (items.isEmpty) continue;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
        out.add(Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              EntityChip(
                label: item,
                onTap: _openerFor(context, key, item),
              ),
          ],
        ));
      } else if (value != null && value.toString().trim().isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('$label: $value', style: theme.textTheme.bodyMedium),
        ));
      }
    }

    return out;
  }

  /// Free-text requirement, with the app's existing link affordance when the
  /// line is one EntityLinker understands.
  Widget _rawRequirement(BuildContext context, ThemeData theme, String raw) {
    if (raw.isEmpty) return const SizedBox.shrink();

    final linker = EntityLinker.instance;
    if (!linker.looksLinkable(raw)) {
      return Text(raw, style: theme.textTheme.bodyMedium);
    }

    return InkWell(
      onTap: () => linker.openFromLine(context, raw),
      child: Row(
        children: [
          Expanded(child: Text(raw, style: theme.textTheme.bodyMedium)),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.open_in_new, size: 18),
          ),
        ],
      ),
    );
  }

  /// Normalised requirement key, e.g. 'requiredStars' -> 'requiredstars'.
  String _normalizeKey(String key) => key.toLowerCase();

  /// Reuses EntityLinker rather than inventing new navigation.
  VoidCallback? _openerFor(BuildContext context, String kind, String name) {
    final kind0 = _normalizeKey(kind);
    String? line;
    if (kind0 == 'recipes' ||
        kind0 == 'recipe' ||
        kind0 == 'dishes' ||
        kind0 == 'dish') {
      line = 'Learn recipe: $name';
    } else if (kind0 == 'facilities' || kind0 == 'facility') {
      line = 'Must unlock $name';
    }
    if (line == null) return null;

    final target = line;
    return () => EntityLinker.instance.openFromLine(context, target);
  }

  /// 'requiredStars' -> 'Required Stars'; 'customer_gift' -> 'Customer Gift'.
  String _prettyRequirementKey(String key) {
    final spaced = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ');

    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ----- Rating + Hidden section -----

  Widget _buildRatingAndHiddenSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memento.earnedStars > 0) ...[
              _sectionTitle(theme, 'Rating Bonus'),
              Row(
                children: [
                  Image.asset(
                    'assets/images/star.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bonus Rating +${memento.earnedStars}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle(theme, 'Hidden Memento'),
            Text(
              memento.hidden ? 'Yes (hidden memento)' : 'No',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ----- Click handling -----

  void _openCustomer(BuildContext context) async {
    final id = memento.customerId;
    if (id == null) return;

    // Look up the specific customer by ID
    final customer = await CustomersRepository.instance.byId(id);
    if (!mounted || customer == null) return;

    // Navigate to that customer's detail page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: customer),
      ),
    );
  }

  void _openSource(BuildContext context) {
    if (memento.source == null || memento.source!.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open source page: ${memento.source}')),
    );
  }

  void _openEvent(BuildContext context) {
    if (memento.event == null || memento.event!.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open event: ${memento.event}')),
    );
  }
}
