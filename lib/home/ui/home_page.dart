import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:animal_restaurant_tracker/features/bank/ui/bank_page.dart';
import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';

import '../../features/search/data/search_index.dart';
import '../../features/shared/data/unlocked_store.dart';

import '../../features/customers/ui/customers_page.dart';

import '../../features/facilities/ui/facilities_page.dart' as fac;
import '../../features/facilities/ui/facility_detail_page.dart' as facdetail;

import '../../features/letters/ui/letters_page.dart';
import '../../features/mementos/ui/mementos_page.dart';
import '../../features/dishes/ui/dishes_page.dart' as recipes;      // ← alias
import '../../features/dishes/ui/dish_detail_page.dart' as detail;  // ← alias

import '../../features/customers/data/customers_repository.dart';

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
          MaterialPageRoute(builder: (_) => detail.DishDetailPage(dishId: h.id)),
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
          // Search card uses global CardTheme (cream bg, green border, radius)
          Card(
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _focus,
                  decoration: const InputDecoration(
                    hintText: 'Search customers, letters, recipes, facilities, mementos…',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: _onChanged,
                ),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_focus.hasFocus && _suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black12)),
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

          Text('Browse', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // Fixed 3-per-row, square nav tiles using global CardTheme
          GridView.count(
            crossAxisCount: 3, // ← EXACTLY 3 per row
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // ← square tiles
            children: [
              _navTile(context, Icons.people, 'Customers', const CustomersPage()),
              _navTile(context, Icons.store, 'Facilities', fac.FacilitiesPage()),
              _navTile(context, Icons.mail, 'Letters', const LettersPage()),
              _navTile(context, Icons.menu_book, 'Recipes', const recipes.DishesPage()),
              _navTile(context, Icons.attach_money, 'Bank', const BankPage()),
              _navTile(context, Icons.card_giftcard, 'Mementos', const MementosPage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label, Widget page) {
    return _NavTile(
      icon: icon,
      label: label,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }

  IconData _iconFor(HitType t) {
    switch (t) {
      case HitType.customer:
        return Icons.person;
      case HitType.letter:
        return Icons.mail;
      case HitType.dish:
        return Icons.menu_book;
      case HitType.facility:
        return Icons.store;
      case HitType.memento:
        return Icons.card_giftcard;
    }
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Card picks up border/radius/background from global CardTheme (app_theme.dart)
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scale icon to available height so we never overflow a square tile
            final iconSize = constraints.maxHeight * 0.38; // ~38% of tile height

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon scales with tile size
                  Icon(icon, size: iconSize),
                  const SizedBox(height: 8),
                  // Text can wrap and shrink 1pt at a time; Flexible prevents overflow
                  Flexible(
                    child: Center(
                      child: AutoSizeText(
                        label,
                        maxLines: 2,
                        wrapWords: true,
                        minFontSize: 8,
                        stepGranularity: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
