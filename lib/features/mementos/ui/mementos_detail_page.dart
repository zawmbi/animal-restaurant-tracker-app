import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/mementos_index.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart';

/// Detail page for a single memento.
/// Navigate here from MementosPage with:
///   Navigator.of(context).push(
///     MaterialPageRoute(
///       builder: (_) => MementoDetailPage(memento: entry),
///     ),
///   );
class MementoDetailPage extends StatefulWidget {
  final MementoEntry memento;

  const MementoDetailPage({super.key, required this.memento});

  @override
  State<MementoDetailPage> createState() => _MementoDetailPageState();
}

class _MementoDetailPageState extends State<MementoDetailPage> {
  final store = UnlockedStore.instance;

  MementoEntry get memento => widget.memento;

  List<String> get _tags => memento.tags;

  // Kinds
  bool get isPoster => _tags.contains('poster');
  bool get isDressUp =>
      _tags.contains('dress_up') || _tags.contains('wearable');

  // Dress-up sub-types
  bool get isClothing => _tags.contains('clothing');
  bool get isAccessory => _tags.contains('clothing_accessory');
  bool get isRestaurantDecoration => _tags.contains('restaurant_decoration');
  bool get isFishPondBoat => _tags.contains('fish_pond_boat');
  bool get isTakeoutCart => _tags.contains('takeout_cart');

  bool get _collected => store.isUnlocked('memento_collected', memento.key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(memento.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Top info: owned + basic details ----------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Owned checkbox
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Owned',
                              style: theme.textTheme.titleMedium,
                            ),
                            Checkbox(
                              value: _collected,
                              onChanged: (v) => store.setUnlocked(
                                'memento_collected',
                                memento.key,
                                v ?? false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ----- Memento Name -----
                        _sectionTitle(theme, 'Memento Name'),
                        Text(
                          memento.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // ----- Description -----
                        _sectionTitle(theme, 'Memento Description'),
                        if (memento.description.isNotEmpty) ...[
                          Text(
                            memento.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ] else ...[
                          Text(
                            '(No description provided)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ----- Requirements -----
                        _buildRequirementsSection(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ---------- Type-specific sections ----------
                if (!isDressUp && !isPoster)
                  _buildRegularMementoSection(context, theme),

                if (isDressUp) _buildDressUpSection(context, theme),

                if (isPoster) _buildPosterSection(context, theme),

                if (!isDressUp && !isPoster) const SizedBox(height: 16),

                // ---------- Rating + Hidden ----------
                _buildRatingAndHiddenSection(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style:
            theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // ----- Regular Mementos (non wearables, non posters) -----

  Widget _buildRegularMementoSection(BuildContext context, ThemeData theme) {
    final hasCustomer = (memento.customerName ?? '').isNotEmpty;
    final hasSource = (memento.source ?? '').isNotEmpty;
    final hasEvent = (memento.event ?? '').isNotEmpty;

    if (!hasCustomer && !hasSource && !hasEvent) {
      // Nothing extra to show beyond description + rating
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Memento Details'),

            // Customer: clickable → specific customer page
            if (hasCustomer)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openCustomer(context),
                child: Text(
                  'Customer: ${memento.customerName}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            // Source: clickable stub
            if (hasSource)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openSource(context),
                child: Text(
                  'Source: ${memento.source}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            // Event: clickable stub
            if (hasEvent)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openEvent(context),
                child: Text(
                  'Event: ${memento.event}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- Dress-Up Mementos -----

  Widget _buildDressUpSection(BuildContext context, ThemeData theme) {
    final hasSource = (memento.source ?? '').isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Dress-Up'),

            // Basic type info based on tags
            if (isClothing) ...[
              const Text('Type: Clothing'),
              const SizedBox(height: 8),
            ] else if (isAccessory) ...[
              const Text('Type: Clothing Accessory'),
              const SizedBox(height: 8),
            ] else if (isRestaurantDecoration) ...[
              const Text('Type: Restaurant Decoration'),
              const SizedBox(height: 8),
            ] else if (isFishPondBoat) ...[
              const Text('Type: Fish Pond Boat'),
              const SizedBox(height: 8),
            ] else if (isTakeoutCart) ...[
              const Text('Type: Takeout Cart'),
              const SizedBox(height: 8),
            ],

            // If the memento has a source in your JSON, show it.
            if (hasSource) ...[
              Text('Obtained from: ${memento.source}'),
            ],
          ],
        ),
      ),
    );
  }

  // ----- Poster Mementos -----

  Widget _buildPosterSection(BuildContext context, ThemeData theme) {
    final hasEvent = (memento.event ?? '').isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Poster'),
            const Text('Category: Courtyard Poster'),
            const SizedBox(height: 4),
            const Text('Can be displayed in the courtyard'),
            if (hasEvent)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openEvent(context),
                child: Text(
                  'Event: ${memento.event}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- Requirements / "Memento Requirements" -----

  Widget _buildRequirementsSection(ThemeData theme) {
    final req = memento.requirement.trim();
    if (req.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Memento Requirements'),
        Text(
          req,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  // ----- Rating + Hidden section -----

  Widget _buildRatingAndHiddenSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memento.stars > 0) ...[
              _sectionTitle(theme, 'Rating Bonus'),
              Row(
                children: [
                  Image.asset(
                    'assets/images/star.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bonus Rating +${memento.stars}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle(theme, 'Hidden Memento'),
            Text(
              memento.hidden ? 'Yes (hidden memento)' : 'No',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ----- Click handling -----

  void _openCustomer(BuildContext context) async {
    final id = memento.customerId;
    if (id == null) return;

    // Look up the specific customer by ID
    final customer = await CustomersRepository.instance.byId(id);
    if (!mounted || customer == null) return;

    // Navigate to that customer's detail page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: customer),
      ),
    );
  }

  void _openSource(BuildContext context) {
    if (memento.source == null || memento.source!.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open source page: ${memento.source}')),
    );
  }

  void _openEvent(BuildContext context) {
    if (memento.event == null || memento.event!.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open event: ${memento.event}')),
    );
  }

  void _openRecipeFromMemento(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open vegetable garden recipe page (to be wired).'),
      ),
    );
  }

  void _openStaffChooser(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open staff member(s) that can wear this (to be wired).'),
      ),
    );
  }
}
