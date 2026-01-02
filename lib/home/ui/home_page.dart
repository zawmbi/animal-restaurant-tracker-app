// ignore_for_file: unused_element

import 'dart:async';
import 'package:animal_restaurant_tracker/features/mementos/ui/mementos_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:animal_restaurant_tracker/features/battle_pass/data/battle_pass_repository.dart';

import 'package:animal_restaurant_tracker/features/bank/ui/bank_page.dart';
import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart'
    as facrepo;

//  Battle Pass
import 'package:animal_restaurant_tracker/features/battle_pass/ui/battle_pass_page.dart';

import '../../features/search/data/search_index.dart';
import '../../features/shared/data/unlocked_store.dart';

import '../../features/customers/ui/customers_page.dart';

import '../../features/facilities/ui/facilities_page.dart' as fac;
import '../../features/facilities/ui/facility_detail_page.dart' as facdetail;
import 'package:animal_restaurant_tracker/features/timers/ui/timers_page.dart';
import '../../features/redemption_codes/ui/redemption_codes_page.dart';
import 'package:animal_restaurant_tracker/features/courtyard/ui/courtyard_page.dart';
import 'package:animal_restaurant_tracker/features/aromatic_acorn/ui/aromatic_acorn_page.dart';
import 'package:animal_restaurant_tracker/features/staff/ui/staff_page.dart';

import '../../features/letters/ui/letters_page.dart';
import '../../features/mementos/ui/mementos_page.dart';
import '../../features/dishes/ui/dishes_page.dart' as recipes;
import '../../features/dishes/ui/dish_detail_page.dart' as detail;
import '../../features/settings/ui/settings_page.dart';

import '../../features/customers/data/customers_repository.dart';
import 'package:animal_restaurant_tracker/features/mementos/data/mementos_index.dart';

// ^ if your file is named differently (ex: mementos_detail_page.dart), use that instead.

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

  // Convert a display name -> your underscored id format.
  // Example:
  //   "Teddy Bear Stove" -> "teddy_bear_stove"
  //   "Gumi's Custom Doors" -> "gumis_custom_doors"
  //   "Vibrant Flower Long 2" -> "vibrant_flower_long_2"

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
          MaterialPageRoute(
            builder: (_) => detail.DishDetailPage(dishId: h.id),
          ),
        );
        break;

      case HitType.facility:
        final f = await facrepo.FacilitiesRepository.instance.byId(h.id);
        if (f == null || !mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => facdetail.FacilityDetailPage(
              facilityId: f.id,
            ),
          ),
        );
        break;

      case HitType.letter:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LettersPage()),
        );
        break;

      case HitType.memento:
        final entry = await MementosIndex.instance.byId(h.id);
        if (entry == null || !mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MementoDetailPage(memento: entry),
          ),
        );
        break;

      //  Battle Pass (if your SearchIndex supports it)
      case HitType.battlePass:
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BattlePassPage()),
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
          // Search card
          Card(
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _focus,
                  decoration: const InputDecoration(
                    hintText:
                        'Search customers, letters, recipes, facilities, mementos, battle pass…',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: _onChanged,
                ),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_focus.hasFocus && _suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black12),
                      ),
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

                          //  Battle Pass progress tracking bucket (only if you want checkboxes here)
                          case HitType.battlePass:
                            bucket = 'battle_pass';
                            break;
                        }

                        final checked =
                            store.isUnlocked(bucket, h.key ?? h.id);

                        return InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          onTap: () => _openHit(h),
                          child: ListTile(
                            leading: Icon(_iconFor(h.type)),
                            title: Text(h.title),
                            subtitle:
                                h.subtitle != null ? Text(h.subtitle!) : null,
                            trailing: Checkbox(
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

          // 3-per-row nav tiles
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _navTile(
                context,
                Icons.cruelty_free,
                'Customers',
                const CustomersPage(),
              ),
              _navTile(
                context,
                Icons.yard_outlined,
                'Courtyard',
                const CourtyardPage(),
              ),
              _navTile(
                context,
                Icons.store,
                'Facilities',
                fac.FacilitiesPage(),
              ),
              _navTile(
                context,
                Icons.mail,
                'Letters',
                const LettersPage(),
              ),
              _navTile(
                context,
                Symbols.menu_book_2,
                'Recipes',
                const recipes.DishesPage(),
              ),
              _navTile(
                context,
                Icons.attach_money,
                'Bank',
                const BankPage(),
              ),
              _navTile(
                context,
                Icons.card_giftcard,
                'Mementos',
                const MementosPage(),
              ),

              //  Battle Pass tile
              _navTile(
                context,
                Icons.confirmation_num,
                'Battle Pass',
                const BattlePassPage(),
              ),

              _navTile(
                context,
                Symbols.owl,
                'Staff',
                const StaffPage(),
              ),
              _navTile(
                context,
                Symbols.menu_book,
                'Redemption Codes',
                const RedemptionCodesPage(),
              ),
              _navTile(
                context,
                Icons.emoji_events,
                'Aromatic Acorn Judging',
                const AromaticAcornPage(),
              ),
              _navTile(
                context,
                Icons.timer,
                'Timers',
                const TimersPage(),
              ),
              _navTile(
                context,
                Icons.settings,
                'Settings',
                const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return _NavTile(
      icon: icon,
      label: label,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
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
        return Icons.menu_book;
      case HitType.facility:
        return Icons.store;
      case HitType.memento:
        return Icons.card_giftcard;
      case HitType.battlePass:
        return Icons.confirmation_num;
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxHeight * 0.38;

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Center(
                      child: AutoSizeText(
                        label,
                        maxLines: 2,
                        wrapWords: true,
                        minFontSize: 12,
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

// Temp page so the Aromatic Acorn tile works until you build the real one.
class _AromaticAcornPlaceholderPage extends StatelessWidget {
  const _AromaticAcornPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aromatic Acorn Judging')),
      body: const Center(
        child: Text(
          'Aromatic Acorn Judging.\n'
          'Not done yet.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
