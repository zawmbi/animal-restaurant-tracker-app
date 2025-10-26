import 'dart:async';
import 'package:flutter/material.dart';

import '../../features/facilities/model/data/facilities_repository.dart';
import '../../features/search/data/search_index.dart';
import '../../features/shared/data/unlocked_store.dart';

import '../../features/customers/ui/customers_page.dart';

import '../../features/facilities/ui/facilities_page.dart' as fac;
import '../../features/facilities/ui/facility_detail_page.dart' as facdetail;

import '../../features/letters/ui/letters_page.dart';
import '../../features/mementos/ui/mementos_page.dart';
import '../../features/dishes/ui/dishes_page.dart';
import '../../features/dishes/ui/dish_detail_page.dart';

import '../../features/customers/data/customers_repository.dart';
import '../../features/facilities/data/facilities_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();
  final store = UnlockedStore.instance;
  List<SearchHit> _suggestions = const [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    SearchIndex.instance.preload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      setState(() => _loading = true);
      final res = await SearchIndex.instance.search(q);
      if (!mounted) return;
      setState(() {
        _suggestions = res.take(8).toList();
        _loading = false;
      });
    });
  }

  void _openHit(SearchHit h) async {
    switch (h.type) {
      case HitType.customer:
        final c = await CustomersRepository.instance.byId(h.id);
        if (c == null || !mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomersPage()),
        );
        break;

      case HitType.dish:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DishDetailPage(dishId: h.id)),
        );
        break;

      case HitType.facility:
        final f = await FacilitiesRepository.instance.byId(h.id);
        if (f == null || !mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => facdetail.FacilityDetailPage(facility: f)),
        );
        break;

      case HitType.letter:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LettersPage()),
        );
        break;

      case HitType.memento:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MementosPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _focus,
                  decoration: InputDecoration(
                    hintText: 'Search customers, letters, dishes, facilities, mementos…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _suggestions = const [];
                              });
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: _onChanged,
                ),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_focus.hasFocus && _suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, i) {
                        final h = _suggestions[i];

                        String? bucket;
                        switch (h.type) {
                          case HitType.customer:
                            bucket = 'customer';
                            break;
                          case HitType.letter:
                            bucket = 'letter';
                            break;
                          case HitType.dish:
                            bucket = 'dish';
                            break;
                          case HitType.facility:
                            bucket = 'facility_purchased';
                            break;
                          case HitType.memento:
                            bucket = 'memento_collected';
                            break;
                        }

                        final checked = bucket == null
                            ? false
                            : store.isUnlocked(bucket, h.key ?? h.id);

                        return InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          hoverColor: Theme.of(context).hoverColor.withOpacity(0.15),
                          onTap: () => _openHit(h),
                          child: ListTile(
                            leading: Icon(_iconFor(h.type)),
                            title: Text(h.title),
                            subtitle: h.subtitle != null ? Text(h.subtitle!) : null,
                            trailing: bucket == null
                                ? null
                                : Checkbox(
                                    value: checked,
                                    onChanged: (v) => store.setUnlocked(
                                      bucket!,
                                      h.key ?? h.id,
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
          ),
          const SizedBox(height: 20),

          _sectionTitle('Browse'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _navCard(context, Icons.people, 'Customers', const CustomersPage()),
              _navCard(context, Icons.store, 'Facilities', fac.FacilitiesPage()),
              _navCard(context, Icons.mail, 'Letters', const LettersPage()),
              _navCard(context, Icons.restaurant, 'Dishes', const DishesPage()),
              _navCard(context, Icons.card_giftcard, 'Mementos', const MementosPage()),
            ],
          ),

        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _navCard(BuildContext context, IconData icon, String label, Widget page) {
    return _HoverCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
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
    }
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _hover ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        child: Material(
          elevation: _hover ? 6 : 2,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
