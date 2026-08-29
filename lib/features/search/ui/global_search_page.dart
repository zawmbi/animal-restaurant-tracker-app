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
    setState(() {
      _hits = res;
      _loading = false;
    });
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
                hintText:
                    'Search customers, letters, dishes, facilities, mementos…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    setState(() => _hits = const []);
                  },
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

                // Bucket names must match the ones the feature pages write to,
                // otherwise this checkbox reads and writes a set nothing else
                // ever sees.
                String? bucketFor;
                switch (type) {
                  case HitType.customer:
                    bucketFor = 'customers';
                    break;
                  case HitType.letter:
                    bucketFor = 'letter';
                    break;
                  case HitType.dish:
                    bucketFor = 'dish';
                    break;
                  case HitType.facility:
                    bucketFor = 'facility';
                    break;
                  case HitType.memento:
                    bucketFor = 'memento_collected';
                    break;
                  case HitType.battlePass:
                    // Battle pass rewards are claimed per phase, so a single
                    // hit has no one bucket. Show the row without a checkbox
                    // rather than throwing inside the list builder.
                    bucketFor = null;
                    break;
                }

                // Hoisted into a final local so it promotes to non-null inside
                // the Checkbox callback below.
                final bucket = bucketFor;
                final key = h.key ?? h.id;
                final checked = bucket != null && store.isUnlocked(bucket, key);

                return InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  // ignore: deprecated_member_use
                  hoverColor:
                      Theme.of(context).hoverColor.withOpacity(0.2),
                  onTap: () => _open(context, h),
                  child: ListTile(
                    leading: Icon(_iconFor(type)),
                    title: Text(h.title),
                    subtitle:
                        h.subtitle != null ? Text(h.subtitle!) : null,
                    trailing: bucket == null
                        ? null
                        : Checkbox(
                            value: checked,
                            onChanged: (v) => store.setUnlocked(
                              bucket,
                              key,
                              v ?? false,
                            ),
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
      case HitType.customer:
        return Icons.person;
      case HitType.letter:
        return Icons.mail;
      case HitType.dish:
        return Icons.restaurant;
      case HitType.facility:
        return Icons.store;
      case HitType.memento:
        return Icons.card_giftcard;
      case HitType.battlePass:
        return Icons.workspace_premium;
    }
  }

  Future<void> _open(BuildContext context, SearchHit h) async {
    switch (h.type) {
      case HitType.customer:
        final c = await CustomersRepository.instance.byId(h.id);
        if (c == null) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer not found')),
          );
          return;
        }
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailPage(customer: c),
          ),
        );
        break;

      case HitType.dish:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DishDetailPage(dishId: h.id),
          ),
        );
        break;

      case HitType.facility:
        final f = await FacilitiesRepository.instance.byId(h.id);
        if (f == null) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facility not found')),
          );
          return;
        }
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FacilityDetailPage(facilityId: f.id), //  pass id, not object
          ),
        );
        break;

      case HitType.letter:
      case HitType.memento:
        // No dedicated screens yet; toggling via checkbox is the primary action.
        break;
      case HitType.battlePass:
        return Icons.workspace_premium;
    }
  }
}
