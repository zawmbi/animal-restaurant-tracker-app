import 'package:flutter/material.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

class AromaticAcornPage extends StatefulWidget {
  const AromaticAcornPage({super.key});

  @override
  State<AromaticAcornPage> createState() => _AromaticAcornPageState();
}

/// Simple checkable item (either a requirement or a task).
class _CheckItem {
  final String id; // unique key for UnlockedStore
  final String label;

  const _CheckItem({required this.id, required this.label});
}

/// One judging stage (Entrance Exam, 1★, 2★, ... 7★).
class _AcornStage {
  final String id;
  final String name;
  final List<_CheckItem> requirements;
  final List<_CheckItem> tasks;
  final String rewardSummary;

  const _AcornStage({
    required this.id,
    required this.name,
    required this.requirements,
    required this.tasks,
    required this.rewardSummary,
  });

  int get totalItems => requirements.length + tasks.length;
}

const List<_AcornStage> _stages = [
  _AcornStage(
    id: 'entrance_exam',
    name: 'Aromatic Acorn Entrance Exam',
    requirements: [
      _CheckItem(
        id: 'entrance_exam_req_rating_2000',
        label: 'Rating at least 2,000',
      ),
      _CheckItem(
        id: 'entrance_exam_req_complete_in_3_days',
        label: 'Complete the judging within 3 days from participation',
      ),
      _CheckItem(
        id: 'entrance_exam_req_unlock_river_god_pond',
        label: 'Unlock River God Pond',
      ),
      _CheckItem(
        id: 'entrance_exam_req_unlock_slab_path',
        label: 'Unlock Slab Path',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'entrance_exam_task_earn_2500000_cod',
        label: 'Earn more than 2,500,000 Cod',
      ),
      _CheckItem(
        id: 'entrance_exam_task_serve_150_village_radio',
        label:
            'Serve 150 Radio Promo customers from Village (Icon-Radio Promo)',
      ),
      _CheckItem(
        id: 'entrance_exam_task_serve_100_town_tv',
        label: 'Serve 100 TV Promo customers from Town (Icon-TV Promo)',
      ),
      _CheckItem(
        id: 'entrance_exam_task_sell_70_taiyaki',
        label: 'Sell 70 Taiyakis',
      ),
    ],
    rewardSummary: 'Rewards: 10 Diamonds, 500,000 Cod',
  ),

  _AcornStage(
    id: 'star_1',
    name: 'Aromatic Acorn 1-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star1_req_rating_5000',
        label: 'Rating at least 5,000',
      ),
      _CheckItem(
        id: 'star1_req_complete_entrance',
        label: 'Complete Aromatic Acorn Entrance Exam',
      ),
      _CheckItem(
        id: 'star1_req_complete_in_7_days',
        label: 'Complete the judging within 7 days from participation',
      ),
      _CheckItem(
        id: 'star1_req_unlock_moss_path',
        label: 'Unlock Moss Path',
      ),
      _CheckItem(
        id: 'star1_req_learn_rice_pudding',
        label: 'Learn recipe: Rice Pudding',
      ),
      _CheckItem(
        id: 'star1_req_learn_chicken_burger',
        label: 'Learn recipe: Chicken Burger',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star1_task_earn_1500000_cod',
        label: 'Earn more than 1,500,000 Cod',
      ),
      _CheckItem(
        id: 'star1_task_serve_500_village_radio',
        label: 'Serve 500 Radio Promo customers from Village',
      ),
      _CheckItem(
        id: 'star1_task_sell_150_taiyaki',
        label: 'Sell 150 Taiyakis',
      ),
      _CheckItem(
        id: 'star1_task_gather_15',
        label: 'Gather customers 15 times',
      ),
      _CheckItem(
        id: 'star1_task_play_game_machine_5',
        label: 'Play Game Machine 5 times',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 1-Star Certificate, 20 Diamonds, 1,000,000 Cod',
  ),

  _AcornStage(
    id: 'star_2',
    name: 'Aromatic Acorn 2-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star2_req_rating_15000',
        label: 'Rating at least 15,000',
      ),
      _CheckItem(
        id: 'star2_req_complete_star1',
        label: 'Complete Aromatic Acorn 1-Star Judging',
      ),
      _CheckItem(
        id: 'star2_req_complete_in_18_days',
        label: 'Complete the judging within 18 days from participation',
      ),
      _CheckItem(
        id: 'star2_req_unlock_hanging_honors',
        label: 'Unlock Hanging Honors',
      ),
      _CheckItem(
        id: 'star2_req_unlock_message_bottle',
        label: 'Unlock Message Bottle',
      ),
      _CheckItem(
        id: 'star2_req_learn_strawberry_shaved_ice',
        label: 'Learn recipe: Strawberry Shaved Ice',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star2_task_serve_800_village_radio',
        label: 'Serve 800 Radio Promo customers from Village',
      ),
      _CheckItem(
        id: 'star2_task_500_flower_viewing',
        label: 'Have 500 flower viewing customers',
      ),
      _CheckItem(
        id: 'star2_task_plant_60_daisy',
        label: 'Plant 60 Daisy (any level)',
      ),
      _CheckItem(
        id: 'star2_task_plant_30_bluebell',
        label: 'Plant 30 Bluebell (any level)',
      ),
      _CheckItem(
        id: 'star2_task_make_80_wishes',
        label: 'Make 80 wishes',
      ),
      _CheckItem(
        id: 'star2_task_send_hedwig_15',
        label: 'Send Hedwig out 15 times',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 2-Star Certificate, 30 Diamonds, 800 Plates',
  ),

  _AcornStage(
    id: 'star_3',
    name: 'Aromatic Acorn 3-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star3_req_rating_30000',
        label: 'Rating at least 30,000',
      ),
      _CheckItem(
        id: 'star3_req_complete_star2',
        label: 'Complete Aromatic Acorn 2-Star Judging',
      ),
      _CheckItem(
        id: 'star3_req_complete_in_25_days',
        label: 'Complete the judging within 25 days from participation',
      ),
      _CheckItem(
        id: 'star3_req_unlock_flag_of_spoils',
        label: 'Unlock Flag of Spoils',
      ),
      _CheckItem(
        id: 'star3_req_unlock_fruity_counter',
        label: 'Unlock Fruity Counter',
      ),
      _CheckItem(
        id: 'star3_req_learn_buckwheat_noodles',
        label: 'Learn recipe: Buckwheat Noodles',
      ),
      _CheckItem(
        id: 'star3_req_learn_snail_noodles',
        label: 'Learn recipe: Snail Noodles',
      ),
      _CheckItem(
        id: 'star3_req_learn_conveyor_miso_soup',
        label: 'Learn buffet recipe: Conveyor Miso Soup',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star3_task_earn_130000000_cod',
        label: 'Earn 130,000,000 Cod',
      ),
      _CheckItem(
        id: 'star3_task_attract_120_booth_owners',
        label: 'Attract 120 Booth Owners',
      ),
      _CheckItem(
        id: 'star3_task_catch_8_sharks',
        label: 'Catch 8 Sharks',
      ),
      _CheckItem(
        id: 'star3_task_catch_25_flounders',
        label: 'Catch 25 Flounders',
      ),
      _CheckItem(
        id: 'star3_task_tap_promo_6400',
        label: 'Tap Promo 6,400 times',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 3-Star Certificate, 30 Diamonds, Golden Spatula',
  ),

  _AcornStage(
    id: 'star_4',
    name: 'Aromatic Acorn 4-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star4_req_rating_50000',
        label: 'Rating at least 50,000',
      ),
      _CheckItem(
        id: 'star4_req_complete_star3',
        label: 'Complete Aromatic Acorn 3-Star Judging',
      ),
      _CheckItem(
        id: 'star4_req_complete_in_35_days',
        label: 'Complete the judging within 35 days from participation',
      ),
      _CheckItem(
        id: 'star4_req_unlock_beach_impression',
        label: 'Unlock Beach Impression',
      ),
      _CheckItem(
        id: 'star4_req_unlock_handcart_sweets',
        label: 'Unlock Handcart Sweets',
      ),
      _CheckItem(
        id: 'star4_req_learn_black_sesame_paste',
        label: 'Learn recipe: Black Sesame Paste',
      ),
      _CheckItem(
        id: 'star4_req_learn_mapo_tofu',
        label: 'Learn recipe: Mapo Tofu',
      ),
      _CheckItem(
        id: 'star4_req_learn_pearl_milk_tea',
        label: 'Learn recipe: Pearl Milk Tea',
      ),
      _CheckItem(
        id: 'star4_req_learn_conveyor_custard',
        label: 'Learn buffet recipe: Conveyor Custard',
      ),
      _CheckItem(
        id: 'star4_req_learn_conveyor_potstickers',
        label: 'Learn buffet recipe: Conveyor Potstickers',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star4_task_serve_1500_town_tv',
        label: 'Serve 1,500 TV Promo customers from Town',
      ),
      _CheckItem(
        id: 'star4_task_catch_40_clownfish',
        label: 'Catch 40 Clownfish',
      ),
      _CheckItem(
        id: 'star4_task_catch_35_squid',
        label: 'Catch 35 Squid',
      ),
      _CheckItem(
        id: 'star4_task_deliver_60_takeouts',
        label: 'Deliver 60 takeouts',
      ),
      _CheckItem(
        id: 'star4_task_sweep_40_trash',
        label: 'Sweep up trash 40 times',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 4-Star Certificate, 50 Diamonds, Kitty Dish',
  ),

  _AcornStage(
    id: 'star_5',
    name: 'Aromatic Acorn 5-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star5_req_rating_100000',
        label: 'Rating at least 100,000',
      ),
      _CheckItem(
        id: 'star5_req_complete_star4',
        label: 'Complete Aromatic Acorn 4-Star Judging',
      ),
      _CheckItem(
        id: 'star5_req_complete_in_45_days',
        label: 'Complete the judging within 45 days from participation',
      ),
      _CheckItem(
        id: 'star5_req_unlock_seashell_counter',
        label: 'Unlock Seashell Counter',
      ),
      _CheckItem(
        id: 'star5_req_unlock_octopus_coffee',
        label: 'Unlock Octopus Coffee',
      ),
      _CheckItem(
        id: 'star5_req_unlock_yacht_counter',
        label: 'Unlock Yacht Counter',
      ),
      _CheckItem(
        id: 'star5_req_learn_eight_treasure_rice_pudding',
        label: 'Learn recipe: Eight Treasure Rice Pudding',
      ),
      _CheckItem(
        id: 'star5_req_learn_strawberry_pudding',
        label: 'Learn recipe: Strawberry Pudding',
      ),
      _CheckItem(
        id: 'star5_req_learn_mugwort_dumpling',
        label: 'Learn recipe: Mugwort Dumpling',
      ),
      _CheckItem(
        id: 'star5_req_learn_tuna_sushi',
        label: 'Learn buffet recipe: Tuna Sushi',
      ),
      _CheckItem(
        id: 'star5_req_learn_fried_chicken_skin',
        label: 'Learn buffet recipe: Fried Chicken Skin',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star5_task_serve_2000_town_tv',
        label: 'Serve 2,000 TV Promo customers from Town',
      ),
      _CheckItem(
        id: 'star5_task_gamble_card_mouse_25',
        label: 'Gamble with Card-Playing Mouse 25 times',
      ),
      _CheckItem(
        id: 'star5_task_sweep_60_trash',
        label: 'Sweep up trash 60 times',
      ),
      _CheckItem(
        id: 'star5_task_1500_flower_viewing',
        label: 'Have 1,500 flower viewing customers',
      ),
      _CheckItem(
        id: 'star5_task_earn_650000000_cod',
        label: 'Earn 650,000,000 Cod',
      ),
      _CheckItem(
        id: 'star5_task_sell_50_seaweed_rice_ball',
        label: 'Sell 50 Seaweed Rice Balls',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 5-Star Certificate, 50 Diamonds, Rising Star',
  ),

  _AcornStage(
    id: 'star_6',
    name: 'Aromatic Acorn 6-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star6_req_rating_200000',
        label: 'Rating at least 200,000',
      ),
      _CheckItem(
        id: 'star6_req_complete_star5',
        label: 'Complete Aromatic Acorn 5-Star Judging',
      ),
      _CheckItem(
        id: 'star6_req_complete_in_55_days',
        label: 'Complete the judging within 55 days from participation',
      ),
      _CheckItem(
        id: 'star6_req_unlock_banana_peel_capsule',
        label: 'Unlock Banana Peel Capsule Machine',
      ),
      _CheckItem(
        id: 'star6_req_learn_crispy_fried_meat',
        label: 'Learn recipe: Crispy Fried Meat',
      ),
      _CheckItem(
        id: 'star6_req_learn_japanese_ramen',
        label: 'Learn buffet recipe: Japanese Ramen',
      ),
      _CheckItem(
        id: 'star6_req_learn_meat_floss_sushi',
        label: 'Learn buffet recipe: Meat Floss Sushi',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star6_task_serve_2800_city_cellphone',
        label:
            'Serve 2,800 Cellphone Promo customers from the City (Icon-Cellphone Promo)',
      ),
      _CheckItem(
        id: 'star6_task_1500_flower_viewing',
        label: 'Have 1,500 flower viewing customers',
      ),
      _CheckItem(
        id: 'star6_task_send_hedwig_40',
        label: 'Send Hedwig out 40 times',
      ),
      _CheckItem(
        id: 'star6_task_attract_15_booth_types',
        label: 'Attract 15 different types of Booth Owners',
      ),
      _CheckItem(
        id: 'star6_task_sweep_80_trash',
        label: 'Sweep up trash 80 times',
      ),
      _CheckItem(
        id: 'star6_task_catch_18_sharks',
        label: 'Catch 18 Sharks',
      ),
      _CheckItem(
        id: 'star6_task_play_game_machine_40',
        label: 'Play the Game Machine 40 times',
      ),
      _CheckItem(
        id: 'star6_task_plant_50_bluebell',
        label: 'Plant 50 Bluebell (any level)',
      ),
      _CheckItem(
        id: 'star6_task_make_110_wishes',
        label: 'Make 110 wishes',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 6-Star Certificate, 80 Diamonds, Glorious Barrette',
  ),

  _AcornStage(
    id: 'star_7',
    name: 'Aromatic Acorn 7-Star Judging',
    requirements: [
      _CheckItem(
        id: 'star7_req_rating_350000',
        label: 'Rating at least 350,000',
      ),
      _CheckItem(
        id: 'star7_req_complete_star6',
        label: 'Complete Aromatic Acorn 6-Star Judging',
      ),
      _CheckItem(
        id: 'star7_req_complete_in_65_days',
        label: 'Complete the judging within 65 days from participation',
      ),
    ],
    tasks: [
      _CheckItem(
        id: 'star7_task_serve_4800_city_cellphone',
        label:
            'Serve 4,800 Cellphone Promo customers from the City (Icon-Cellphone Promo)',
      ),
      _CheckItem(
        id: 'star7_task_earn_900000000_cod',
        label: 'Earn 900,000,000 Cod',
      ),
      _CheckItem(
        id: 'star7_task_sell_120_taiyaki',
        label: 'Sell 120 Taiyakis',
      ),
      _CheckItem(
        id: 'star7_task_gamble_card_mouse_35',
        label: 'Gamble with Card-Playing Mouse 35 times',
      ),
      _CheckItem(
        id: 'star7_task_tap_promo_15000',
        label: 'Tap Promo 15,000 times',
      ),
      _CheckItem(
        id: 'star7_task_make_800_wishes',
        label: 'Make 800 wishes',
      ),
      _CheckItem(
        id: 'star7_task_plant_80_rose',
        label: 'Plant 80 Rose (any level)',
      ),
      _CheckItem(
        id: 'star7_task_deliver_150_takeouts',
        label: 'Deliver 150 takeouts',
      ),
      _CheckItem(
        id: 'star7_task_attract_25_booth_types',
        label: 'Attract 25 different types of Booth Owners',
      ),
      _CheckItem(
        id: 'star7_task_gather_150',
        label: 'Gather customers 150 times',
      ),
      _CheckItem(
        id: 'star7_task_sweep_80_trash',
        label: 'Sweep up trash 80 times',
      ),
      _CheckItem(
        id: 'star7_task_send_hedwig_50',
        label: 'Send Hedwig out 50 times',
      ),
      _CheckItem(
        id: 'star7_task_2200_flower_viewing',
        label: 'Have 2,200 flower viewing customers',
      ),
      _CheckItem(
        id: 'star7_task_play_game_machine_45',
        label: 'Play the Game Machine 45 times',
      ),
    ],
    rewardSummary:
        'Rewards: Aromatic Acorn 7-Star Certificate, 100 Diamonds, Mew-chelin Recipes',
  ),
];

class _AromaticAcornPageState extends State<AromaticAcornPage> {
  final _store = UnlockedStore.instance;
  static const _bucket = 'aromatic_acorn';

  bool _isItemChecked(_CheckItem item) =>
      _store.isUnlocked(_bucket, item.id);

  void _setItemChecked(_CheckItem item, bool value) {
    _store.setUnlocked(_bucket, item.id, value);
  }

  bool _isStageComplete(_AcornStage stage) {
    for (final r in stage.requirements) {
      if (!_isItemChecked(r)) return false;
    }
    for (final t in stage.tasks) {
      if (!_isItemChecked(t)) return false;
    }
    return true;
  }

  int _completedCount(_AcornStage stage) {
    var count = 0;
    for (final r in stage.requirements) {
      if (_isItemChecked(r)) count++;
    }
    for (final t in stage.tasks) {
      if (_isItemChecked(t)) count++;
    }
    return count;
  }

  bool get _allStagesComplete =>
      _stages.every(_isStageComplete);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aromatic Acorn Judging'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Aromatic Acorn Judging',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Once the participation requirements are met, you can start the Aromatic Acorn Judging event. '
                    'Use this page to manually check off each requirement and task. '
                    'When all boxes for a stage are checked, that stage is considered completed.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _allStagesComplete
                        ? 'All stages completed! 🎉'
                        : 'Progress: ${_stages.where(_isStageComplete).length} of ${_stages.length} stages completed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._stages.map(_buildStageCard),
        ],
      ),
    );
  }

  Widget _buildStageCard(_AcornStage stage) {
    final complete = _isStageComplete(stage);
    final done = _completedCount(stage);
    final total = stage.totalItems;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(
          complete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: complete ? Colors.green : null,
        ),
        title: Text(stage.name),
        subtitle: Text('$done / $total steps completed'),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          if (stage.rewardSummary.isNotEmpty) ...[
            Text(
              stage.rewardSummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],
          if (stage.requirements.isNotEmpty) ...[
            Text(
              'Stage Requirements',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...stage.requirements.map(_buildCheckItemTile),
            const SizedBox(height: 8),
          ],
          if (stage.tasks.isNotEmpty) ...[
            Text(
              'Stage Tasks',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...stage.tasks.map(_buildCheckItemTile),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildCheckItemTile(_CheckItem item) {
    final checked = _isItemChecked(item);
    return CheckboxListTile(
      value: checked,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.label,
        style: TextStyle(
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      onChanged: (v) {
        setState(() {
          _setItemChecked(item, v ?? false);
        });
      },
    );
  }
}
