import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';
import '../../search/ui/global_search_page.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final repo = CustomersRepository.instance;
  final store = UnlockedStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background, AppBar colors, text colors, etc. come from app_theme.dart
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Customer>>(
        future: repo.all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snap.data!;
          final allTags = customers.expand((c) => c.tags).toSet().cast<String>();
          final tagsToShow = _orderedTags(allTags);

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _section(context, 'All', customers),
                    for (final tag in tagsToShow)
                      _section(
                        context,
                        _titleFromTag(tag),
                        customers.where((c) => c.tags.contains(tag)).toList(),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Convert snake_case tag → Title Case
  String _titleFromTag(String tag) => tag
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // Decide section order and filter
  List<String> _orderedTags(Set<String> all) {
    const exclude = {'customer', 'logbook_default'};
    const preferred = [
      'restaurant',
      'special',
      'booth_owner',
      'seasonal',
      'performer',
      'nearby',
      'village',
      'very_common',
      'holiday',
      'halloween',
    ];

    final picked = <String>[];
    for (final t in preferred) {
      if (all.contains(t) && !exclude.contains(t)) picked.add(t);
    }
    final remaining = all
        .difference(picked.toSet())
        .where((t) => !exclude.contains(t))
        .toList()
      ..sort();
    return [...picked, ...remaining];
  }

  Widget _section(BuildContext context, String title, List<Customer> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    // ExpansionTile styles (colors, icons, padding) come from app_theme.dart
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,     // EXACTLY 3 per row
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // square tiles
          ),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            final isUnlocked = store.isUnlocked('customer', c.id);
            return _CustomerTile(
              name: c.name,
              isUnlocked: isUnlocked,
              onCheckChanged: (v) => store.setUnlocked('customer', c.id, v),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(customer: c),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.name,
    required this.isUnlocked,
    required this.onCheckChanged,
    required this.onTap,
  });

  final String name;
  final bool isUnlocked;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use Card so color/border/radius come from CardTheme in app_theme.dart
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Centered autosizing name (text color from TextTheme in app_theme.dart)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: AutoSizeText(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    wrapWords: true,
                    minFontSize: 10,
                    stepGranularity: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            // Checkbox (top-right) styled by CheckboxTheme in app_theme.dart
            Positioned(
              top: 4,
              right: 4,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: isUnlocked,
                  onChanged: (v) => onCheckChanged(v ?? false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
