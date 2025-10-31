import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';
import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../../customers/ui/customer_detail_page.dart';
import '../../dishes/ui/dish_detail_page.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../customers/data/customers_repository.dart';
import '../../facilities/data/facilities_repository.dart';
import '../data/search_index.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});
  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _ctrl = TextEditingController();
  final store = UnlockedStore.instance;
  List<SearchHit> _hits = const [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    final res = await SearchIndex.instance.search(q);
    if (!mounted) return;
    setState(() { _hits = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search customers, letters, dishes, facilities, mementos…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () { _ctrl.clear(); setState(() => _hits = const []); },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _runSearch,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.separated(
              itemCount: _hits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final h = _hits[i];
                final type = h.type;

                String? bucket;
                switch (type) {
                  case HitType.customer: bucket = 'customer'; break;
                  case HitType.letter: bucket = 'letter'; break;
                  case HitType.dish: bucket = 'dish'; break;
                  case HitType.facility: bucket = 'facility_purchased'; break;
                  case HitType.memento: bucket = 'memento_collected'; break;
                }

                final checked = bucket == null ? false : store.isUnlocked(bucket, h.key ?? h.id);

                return InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: Theme.of(context).hoverColor.withOpacity(0.2),
                  onTap: () => _open(context, h),
                  child: ListTile(
                    leading: Icon(_iconFor(type)),
                    title: Text(h.title),
                    subtitle: h.subtitle != null ? Text(h.subtitle!) : null,
                    trailing: bucket == null
                        ? null
                        : Checkbox(
                            value: checked,
                            onChanged: (v) => store.setUnlocked(bucket!, h.key ?? h.id, v ?? false),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(HitType t) {
    switch (t) {
      case HitType.customer: return Icons.person;
      case HitType.letter: return Icons.mail;
      case HitType.dish: return Icons.restaurant;
      case HitType.facility: return Icons.store;
      case HitType.memento: return Icons.card_giftcard;
    }
  }

  Future<void> _open(BuildContext context, SearchHit h) async {
    switch (h.type) {
      case HitType.customer:
        final c = await CustomersRepository.instance.byId(h.id);
        if (c == null) {
          if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer not found')));
          return;
        }
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CustomerDetailPage(customer: c),
        ));
        break;
      case HitType.dish:
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DishDetailPage(dishId: h.id),
        ));
        break;
      case HitType.facility:
        final f = await FacilitiesRepository.instance.byId(h.id);
        if (f == null) {
          if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facility not found')));
          return;
        }
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FacilityDetailPage(facility: f),
        ));
        break;
      case HitType.letter:
      case HitType.memento:
        // No dedicated screens yet; toggling via checkbox is the primary action.
        break;
    }
  }
}
