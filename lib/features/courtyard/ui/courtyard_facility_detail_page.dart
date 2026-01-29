import 'package:flutter/material.dart';

import '../data/courtyard_facilities.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';
import '/features/aromatic_acorn/ui/aromatic_acorn_page.dart';

class CourtyardFacilityDetailPage extends StatefulWidget {
  const CourtyardFacilityDetailPage({
    super.key,
    required this.facility,
    required this.bucket,
  });

  final CourtyardFacility facility;
  final String bucket;

  @override
  State<CourtyardFacilityDetailPage> createState() =>
      _CourtyardFacilityDetailPageState();
}

class _CourtyardFacilityDetailPageState
    extends State<CourtyardFacilityDetailPage> {
  final _store = UnlockedStore.instance;

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final checked = _store.isUnlocked(widget.bucket, f.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    f.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Checkbox(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      _store.setUnlocked(widget.bucket, f.id, v ?? false);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (f.series != null && f.series!.isNotEmpty)
              Text(
                'Series: ${f.series}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            Text(
              'Group: ${f.group}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(f.description),
            const SizedBox(height: 12),
            if (f.requiredStars > 0 ||
                (f.requirementNote != null &&
                    f.requirementNote!.isNotEmpty)) ...[
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              if (f.requiredStars > 0)
                Text('Rating ${f.requiredStars}'),
              if (f.requirementNote != null &&
                  f.requirementNote!.isNotEmpty)
                Text(f.requirementNote!),
              const SizedBox(height: 12),
            ],
            if (f.price.isNotEmpty) ...[
              Text(
                'Price',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...f.price.map((p) => Text(_formatPrice(p))),
              const SizedBox(height: 12),
            ],
            if (f.effects.isNotEmpty) ...[
              Text(
                'Effects',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...f.effects.map((e) => Text(_formatEffect(e))),
              const SizedBox(height: 12),
            ],

            // Special linking: Certificates -> Aromatic Acorn page
            if (f.group == 'Certificate of Honor') ...[
              const Divider(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.emoji_events),
                label: const Text('Open Aromatic Acorn Judging'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AromaticAcornPage(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPrice(CourtyardPrice p) {
    final label = switch (p.currency) {
      'cod' => 'Cod',
      'film' => 'Film',
      'diamond' => 'Diamond',
      _ => p.currency,
    };
    return '$label ${p.amount}';
  }

  String _formatEffect(CourtyardEffect e) {
    switch (e.type) {
      case 'ratingBonus':
        return 'Rating +${e.amount ?? 0}';
      case 'incomePerMinute':
        final curLabel = switch (e.currency) {
          'cod' => 'Cod',
          'film' => 'Film',
          _ => e.currency,
        };
        return 'Income +${e.amount ?? 0} $curLabel / min';
      case 'friendLimitIncrease':
        return 'Friend limit +${e.friendSlots ?? 0}';
      default:
        return e.type;
    }
  }
}
