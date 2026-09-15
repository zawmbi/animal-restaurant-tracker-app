// lib/features/shared/widgets/filter_drawer.dart

import 'package:flutter/material.dart';

/// The list of themes or series to filter a page by, in a panel that slides
/// over the content instead of standing beside it.
///
/// Courtyard and Facilities both used to pin this list to the left of their
/// grid at a fixed 120pt. That is 31% of a 390pt phone, permanently, and the
/// grid behind it was left with 229pt — less than two tiles wide however the
/// column count is computed. Replacing it with a dropdown fixed the width and
/// lost what was good about it: you could see every option at once and switch
/// without opening anything.
///
/// A panel keeps the list and costs no width when closed, and at ~300pt open
/// it shows names the rail always truncated — "Of Coconut Trees and the Sea
/// Breeze" is 35 characters against the 12 the rail could fit.
class FilterDrawer extends StatelessWidget {
  const FilterDrawer({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.allLabel = 'All',
  });

  /// What is being filtered, e.g. 'Theme' or 'Series'.
  final String title;

  /// The options, without the "all" entry — this widget adds that itself.
  final List<String> options;

  /// The current choice, or null for [allLabel].
  final String? selected;

  /// Called with null when [allLabel] is picked. The drawer closes itself
  /// first, so callers only have to update their own state.
  final ValueChanged<String?> onSelect;

  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void pick(String? value) {
      Navigator.of(context).pop();
      onSelect(value);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: options.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ListTile(
                      title: Text(allLabel),
                      selected: selected == null,
                      onTap: () => pick(null),
                    );
                  }
                  final option = options[i - 1];
                  return ListTile(
                    title: Text(option),
                    selected: option == selected,
                    onTap: () => pick(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app-bar control that opens a [FilterDrawer].
///
/// It names the current filter rather than showing a bare icon, so the page
/// still says what it is filtered by without the list being on screen — the
/// one thing a pinned rail did for free.
class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.selected,
    required this.onPressed,
    this.allLabel = 'All',
  });

  final String? selected;
  final VoidCallback onPressed;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(active ? Icons.filter_alt : Icons.filter_alt_outlined,
            size: 20, color: scheme.primary),
        label: ConstrainedBox(
          // Names run to 35 characters; the button must not push the title
          // off the bar to show one.
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            active ? selected! : allLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
