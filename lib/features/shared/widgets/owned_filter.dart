// lib/features/shared/widgets/owned_filter.dart

import 'package:flutter/material.dart';

/// Show everything, only what is still missing, or only what is already had.
///
/// The collector's question — "what am I still missing?" — had no answer on
/// any list in the app. On 1,184 mementos or 613 customers that is the
/// difference between scanning and scrolling, and it was the most asked-for
/// thing across the player reviews.
enum OwnedFilter {
  all('All'),
  missing('Missing'),
  owned('Owned');

  const OwnedFilter(this.label);

  final String label;

  /// Whether a row in this state should be shown.
  bool allows(bool isOwned) => switch (this) {
        OwnedFilter.all => true,
        OwnedFilter.missing => !isOwned,
        OwnedFilter.owned => isOwned,
      };
}

/// A one-line control for [OwnedFilter], sized to sit beside a count.
class OwnedFilterDropdown extends StatelessWidget {
  const OwnedFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OwnedFilter value;
  final ValueChanged<OwnedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<OwnedFilter>(
      value: value,
      underline: const SizedBox.shrink(),
      // The label alone reads as a noun rather than a filter, and this sits
      // next to an "Owned: n/m" count that uses the same word.
      icon: const Icon(Icons.filter_list, size: 18),
      items: [
        for (final option in OwnedFilter.values)
          DropdownMenuItem<OwnedFilter>(
            value: option,
            child: Text(option.label),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
