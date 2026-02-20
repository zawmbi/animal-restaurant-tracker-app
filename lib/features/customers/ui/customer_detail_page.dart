import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../data/posters_repository.dart';
import '../model/customer.dart';
import '../model/poster.dart';
import 'poster_detail_page.dart';

import '../../dishes/ui/dish_detail_page.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../letters/ui/letter_detail_page.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../mementos/data/mementos_index.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../shared/data/unlocked_store.dart';
import '../../mementos/ui/mementos_detail_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final store = UnlockedStore.instance;

  static const String _bucketCustomers = 'customers';
  static const String _bucketDish = 'dish';
  static const String _bucketLetter = 'letter';
  static const String _bucketFacility = 'facility';
  static const String _bucketMementoCollected = 'memento_collected';

  Customer get customer => widget.customer;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);
  }

  bool get _isCustomerUnlocked =>
      store.isUnlocked(_bucketCustomers, customer.id);

  Future<void> _setCustomerUnlocked(bool v) async {
    await store.setUnlocked(_bucketCustomers, customer.id, v);
    if (mounted) setState(() {});
  }

  Color _ownedFill(BuildContext context) => Colors.green.withOpacity(0.18);

  Future<void> _openCustomerById(BuildContext context, String id) async {
    final found = await CustomersRepository.instance.byId(id);
    if (!context.mounted || found == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: found),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openPosterById(BuildContext context, String posterId) async {
    final Poster? p = await PostersRepository.instance.byId(posterId);
    if (!context.mounted || p == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosterDetailPage(posterId: posterId),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = customer.requirements;
    final ownedFill = _ownedFill(context);

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unlocked'),
            value: _isCustomerUnlocked,
            onChanged: (v) {
              if (v == null) return;
              _setCustomerUnlocked(v);
            },
          ),

          Text(customer.customerDescription),

          const SizedBox(height: 16),
          if (customer.livesIn != null)
            _section('Lives In', Text(customer.livesIn!)),
          if (customer.appearanceWeight != null)
            _section(
              'Appearance Weight',
              Text(customer.appearanceWeight.toString()),
            ),

          if (customer.boothOwner != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Booth Owner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _boothOwnerSection(customer.boothOwner!),
          ],

          if (customer.performer != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Performer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _performerSection(context, customer.performer!),
          ],

          if (r != null && r.hasAny) ...[
            const SizedBox(height: 24),
            const Text(
              'Requirements to invite customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            if (r.requiredStars != null)
              _section('Rating', Text(r.requiredStars.toString())),

            if (r.recipes.isNotEmpty)
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Required Recipes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.recipes.map((id) {
                  final owned = store.isUnlocked(_bucketDish, id.toString());
                  final s = id.toString();
                  final label = s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
                  return EntityChip(
                  label: label,
                  fillColor: owned ? ownedFill : null,
                  onTap: () async {
                    await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DishDetailPage(dishId: id.toString()),
                    ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
                  );
                }).toList(),
                ),
              ],
              ),

            _simpleLinks(
              context: context,
              title: 'Required Facilities',
              ids: r.facilities,
              isOwned: (id) =>
                  store.isUnlocked(_bucketFacility, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FacilityDetailPage(facilityId: id.toString()),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            _simpleLinks(
              context: context,
              title: 'Required Letters',
              ids: r.letters,
              isOwned: (id) => store.isUnlocked(_bucketLetter, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) async {
                final Letter? letter =
                    await LettersRepository.instance.byId(id.toString());
                if (!mounted || letter == null) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LetterDetailPage(letter: letter),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            _simpleLinks(
              context: context,
              title: 'Prerequisite Customers',
              ids: r.customers,
              isOwned: (id) =>
                  store.isUnlocked(_bucketCustomers, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) => _openCustomerById(context, id.toString()),
            ),
          ],

          if (customer.mementos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Mementos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customer.mementos.map((m) {
                return FutureBuilder(
                  future: MementosIndex.instance.byId(m.id),
                  builder: (context, snap) {
                    final entry = snap.data;

                    final collected = (entry != null)
                        ? store.isUnlocked(_bucketMementoCollected, entry.key)
                        : false;

                    return EntityChip(
                      label: m.name,
                      fillColor:
                          collected ? Colors.green.withOpacity(0.18) : null,
                      onTap: () async {
                        final real =
                            entry ?? await MementosIndex.instance.byId(m.id);
                        if (real == null || !context.mounted) return;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MementoDetailPage(memento: real),
                          ),
                        );

                        if (mounted) setState(() {});
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boothOwnerSection(BoothOwnerInfo b) {
    final lines = <Widget>[];

    if (b.timeRange == null) {
      lines.add(_section('Time Range', const Text('Any Time')));
    } else {
      lines.add(_section(
        'Time Range',
        Text('${b.timeRange!.start} to ${b.timeRange!.end}'),
      ));
    }

    if (b.stayDurationMinutes != null) {
      lines.add(_section(
        'Stay Duration',
        Text(
          '${b.stayDurationMinutes!.min} min to ${b.stayDurationMinutes!.max} min',
        ),
      ));
    }

    if (b.requiredFishIds.isNotEmpty) {
      lines.add(_section('Required Fish', Text(b.requiredFishIds.join(', '))));
    }

    if (b.customerDrop != null) {
      lines.add(_section(
        'Customer Drop',
        Text(
          '${b.customerDrop!.currency}: ${b.customerDrop!.min} ~ ${b.customerDrop!.max}',
        ),
      ));
    }

    if (b.incomeEvery5Min.isNotEmpty) {
      lines.add(const SizedBox(height: 8));
      lines.add(const Text(
        'Income every 5 min',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      for (final r in b.incomeEvery5Min) {
        final pct = (r.chance * 100).toStringAsFixed(0);
        lines.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$pct% chance to get ${r.currency} ${r.amount}'),
        ));
      }
    }

    if (b.appearanceRatesByFish.isNotEmpty) {
      lines.add(const SizedBox(height: 8));
      lines.add(const Text(
        'Appearance probability',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('06:00-12:00 / 12:00-19:00 / 19:00-06:00'),
      ));
      for (final row in b.appearanceRatesByFish) {
        lines.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${row.fishId}: '
            '${row.morning?.toStringAsFixed(2) ?? '-'} / '
            '${row.afternoon?.toStringAsFixed(2) ?? '-'} / '
            '${row.night?.toStringAsFixed(2) ?? '-'}',
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _performerSection(BuildContext context, PerformerInfo p) {
    final lines = <Widget>[];

    if (p.band != null && p.band!.trim().isNotEmpty) {
      lines.add(_section('Band', Text(p.band!)));
    }

    if (p.showDurationMinutes != null) {
      lines.add(_section('Show Duration', Text('${p.showDurationMinutes} mins')));
    }

    if (p.callbackRequirementHours != null) {
      lines.add(_section('Callback Requirement', Text('${p.callbackRequirementHours} hours')));
    }

    if (p.baseEarnings != null) {
      lines.add(_section(
        'Base Earnings',
        Text('${p.baseEarnings!.currency}+${p.baseEarnings!.amountPerMinute}/min'),
      ));
    }

    if (p.fansCustomerIds.isNotEmpty) {
      lines.add(const Text('Fans', style: TextStyle(fontWeight: FontWeight.bold)));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.fansCustomerIds.map((id) {
          return EntityChip(
            label: id,
            onTap: () => _openCustomerById(context, id),
          );
        }).toList(),
      ));
      lines.add(const SizedBox(height: 12));
    }

    if (p.canInviteThis.isNotEmpty) {
      lines.add(const Text(
        'Performers who can invite this performer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.canInviteThis.map((e) {
          return EntityChip(
            label: '${e.performerId} (${e.chancePercent.toStringAsFixed(2)}%)',
            onTap: () => _openCustomerById(context, e.performerId),
          );
        }).toList(),
      ));
      lines.add(const SizedBox(height: 12));
    }

    if (p.canBeInvitedBy.isNotEmpty) {
      lines.add(const Text(
        'Performers who can be invited by this performer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.canBeInvitedBy.map((e) {
          return EntityChip(
            label: '${e.performerId} (${e.chancePercent.toStringAsFixed(2)}%)',
            onTap: () => _openCustomerById(context, e.performerId),
          );
        }).toList(),
      ));
    }

    if (p.posterIds.isNotEmpty) {
      lines.add(const SizedBox(height: 12));
      lines.add(const Text(
        'Poster Featured',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.posterIds.map((pid) {
          return EntityChip(
            label: pid,
            onTap: () => _openPosterById(context, pid),
          );
        }).toList(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _simpleLinks({
    required BuildContext context,
    required String title,
    required List ids,
    required bool Function(dynamic id) isOwned,
    required Color fillIfOwned,
    Future<void> Function(dynamic id)? onTap,
  }) {
    if (ids.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ids.map((id) {
            final owned = isOwned(id);
            return EntityChip(
              label: id.toString(),
              fillColor: owned ? fillIfOwned : null,
              onTap: onTap == null ? null : () => onTap(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
