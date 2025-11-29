import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/mementos_index.dart';

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

  bool get isDressUp => _tags.contains('dress_up') || _tags.contains('wearable');

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
                // Collected checkbox (like on other pages)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collected',
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

                // Rating line – NOT clickable.
                if (memento.stars > 0) ...[
                  Text(
                    'Increase Rating ★ +${memento.stars}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                if (memento.description.isNotEmpty) ...[
                  Text(
                    memento.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isDressUp && !isPoster)
                  _buildRegularMementoSection(context, theme),

                if (isDressUp)
                  _buildDressUpSection(context, theme),

                if (isPoster)
                  _buildPosterSection(context, theme),

                const SizedBox(height: 24),
                _buildRequirementsSection(theme),
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
        style: theme.textTheme.titleMedium!
            .copyWith(fontWeight: FontWeight.bold),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Memento'),

        // Customer: clickable
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

        const SizedBox(height: 16),
      ],
    );
  }

  // ----- Dress-Up Mementos -----

  Widget _buildDressUpSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Dress-Up'),

        // Sub-type: Clothing
        if (isClothing) ...[
          Text('Type: Clothing'),
          const SizedBox(height: 8),
          const Text('Obtained from: Vegetable Garden'),
          const SizedBox(height: 4),
          const Text('Costs BUTTONS.'),
          const SizedBox(height: 12),

          _sectionTitle(theme, 'Source of Inspiration'),
          // Clickable – wire this to your vegetable garden recipe page later.
          TextButton(
            onPressed: () => _openRecipeFromMemento(context),
            child: const Text('View vegetable garden recipe'),
          ),
          const SizedBox(height: 16),
        ]

        // Clothing Accessories
        else if (isAccessory) ...[
          Text('Type: Clothing Accessory'),
          const SizedBox(height: 8),
          const Text('Costs BUTTONS.'),
          const SizedBox(height: 16),
        ]

        // Restaurant decorations / Fish pond boat / Takeout cart
        else if (isRestaurantDecoration || isFishPondBoat || isTakeoutCart) ...[
          if (isRestaurantDecoration) Text('Type: Restaurant Decoration'),
          if (isFishPondBoat) Text('Type: Fish Pond Boat'),
          if (isTakeoutCart) Text('Type: Takeout Cart'),
          const SizedBox(height: 8),
          const Text('Can be displayed in the restaurant'),
          const SizedBox(height: 16),
        ],

        // "Can be worn by" section
        if (isTakeoutCart) ...[
          _sectionTitle(theme, 'Can be worn by:'),
          // Exactly what you specified:
          const Text('Delivery Boy Tate'),
          const Text('Delivery Girl Tate'),
          const SizedBox(height: 16),
        ] else ...[
          // Placeholder section for other dress-up mementos.
          // Once you add staff info to the model, replace this with real data.
          _sectionTitle(theme, 'Can be worn by:'),
          TextButton(
            onPressed: () => _openStaffChooser(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              '(Staff member – to be linked from data)',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ----- Poster Mementos -----

  Widget _buildPosterSection(BuildContext context, ThemeData theme) {
    final hasEvent = (memento.event ?? '').isNotEmpty;

    return Column(
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
        const SizedBox(height: 16),
      ],
    );
  }

  // ----- Requirements / How to obtain -----

  Widget _buildRequirementsSection(ThemeData theme) {
    final req = memento.requirement.trim();
    if (req.isEmpty) return const SizedBox.shrink();

    // Examples:
    // "Serve White Bunny 350 times."
    // "Serve White Bunny 1500 times. Sell 2000 Taiyaki."
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'How to obtain'),
        Text(
          req,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  // ----- Click handling stubs -----
  // These compile now, and you can later wire them to real pages/routes.

  void _openCustomer(BuildContext context) {
    if (memento.customerId == null) return;

    // TODO: Replace with your real customer page navigation.
    // Example:
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => CustomerDetailPage(customerId: memento.customerId!),
    //   ),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open customer page: ${memento.customerName}')),
    );
  }

  void _openSource(BuildContext context) {
    if (memento.source == null || memento.source!.isEmpty) return;

    // TODO: Route to wishing well / gachapon / etc. based on memento.source.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open source page: ${memento.source}')),
    );
  }

  void _openEvent(BuildContext context) {
    if (memento.event == null || memento.event!.isEmpty) return;

    // TODO: Route to event / storyline view.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open event: ${memento.event}')),
    );
  }

  void _openRecipeFromMemento(BuildContext context) {
    // TODO: Wire to your real vegetable garden recipe view.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open vegetable garden recipe page (to be wired).'),
      ),
    );
  }

  void _openStaffChooser(BuildContext context) {
    // TODO: When you have staff data on the memento, navigate to staff detail.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open staff member(s) that can wear this (to be wired).'),
      ),
    );
  }
}
