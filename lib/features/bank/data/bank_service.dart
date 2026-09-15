import '../../economy/data/income_repository.dart';
import '../../economy/data/side_income_repository.dart';
import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/income.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../shared/data/unlocked_store.dart';

/// Everything the Bank page needs, computed once per load.
///
/// The numbers come from `assets/data/income.json`, which was transcribed
/// from the wiki facility tables with the printed units intact. The previous
/// version of this service read `facilities_jsons/*.json` instead, where the
/// Buffet's "+4,200/h" rows had been stored as `incomePerMinute`; multiplying
/// those by 60 produced a buffet rate about 38x too high, while the tip jar
/// rate came out ~700x too low because the restaurant, kitchen, garden and
/// takeout "+N/min" rows were missing from that file entirely.
class BankStats {
  const BankStats({
    required this.owned,
    required this.everything,
    required this.ownedFacilityCount,
    required this.facilitiesWithIncome,
    required this.totalFacilityCount,
    required this.dataRetrieved,
    required this.booths,
    required this.staff,
    required this.performers,
  });

  /// Totals from the facilities the player has ticked off.
  final IncomeSummary owned;

  /// Totals if every facility with a verified income effect were owned.
  final IncomeSummary everything;

  /// How many facilities the player has ticked off, across every bucket.
  final int ownedFacilityCount;

  /// How many facilities in the game have a verified income effect.
  final int facilitiesWithIncome;

  /// How many facilities exist in the app's data at all.
  final int totalFacilityCount;

  /// Date the wiki income table was transcribed.
  final String? dataRetrieved;

  /// Fishing-pond booths that pay out, id ascending.
  final List<BoothIncome> booths;

  /// Staff whose raise levels carry an income figure, keyed by staff id.
  final Map<String, StaffIncome> staff;

  /// Concert performers, sorted by band then by name.
  final List<PerformerIncome> performers;

  bool get hasAnyOwned => owned.facilitiesCounted > 0;
}

class BankService {
  final FacilitiesRepository _facilities = FacilitiesRepository.instance;
  final IncomeRepository _income = IncomeRepository.instance;
  final SideIncomeRepository _side = SideIncomeRepository.instance;
  final UnlockedStore _store = UnlockedStore.instance;

  /// Progress buckets that hold facility ids.
  ///
  /// The Facilities page writes `facility`; the Courtyard page writes
  /// `courtyard_facility_purchased` for the very same ids; and
  /// `facility_purchased` is the legacy spelling kept so old saves still
  /// load. Reading only the first, as this service used to, silently ignored
  /// every Courtyard purchase. Ids are de-duplicated before they are summed,
  /// so a facility recorded in two buckets is still counted once.
  static const List<String> facilityBuckets = <String>[
    'facility',
    'courtyard_facility_purchased',
    'facility_purchased',
  ];

  Future<BankStats> compute() async {
    // init() memoises its own future, so this is a no-op once the app has
    // started up; without it a cold start would read an empty store.
    await _store.init();
    await _income.ensureLoaded();
    await _side.ensureLoaded();
    final allFacilities = await _facilities.all();

    final ownedIds = <String>{};
    for (final bucket in facilityBuckets) {
      ownedIds.addAll(_store.ids(bucket));
    }

    final owned = EarningsCalculator.summarize(
      facilityIds: ownedIds,
      repository: _income,
    );
    final everything = EarningsCalculator.summarize(
      facilityIds: _income.facilityIdsWithIncome,
      repository: _income,
    );

    final performers = _income.performers.values.toList();
    // Explicit total order: List.sort is not stable in Dart, so the tie-break
    // on name is what keeps this list from reshuffling between builds.
    performers.sort((a, b) {
      final band = (a.band ?? '').compareTo(b.band ?? '');
      if (band != 0) return band;
      return a.name.compareTo(b.name);
    });

    return BankStats(
      owned: owned,
      everything: everything,
      ownedFacilityCount: ownedIds.length,
      facilitiesWithIncome: _income.facilityIdsWithIncome.length,
      totalFacilityCount: allFacilities.length,
      dataRetrieved: _income.retrieved,
      booths: _side.payingBooths,
      staff: _side.staff,
      performers: performers,
    );
  }

  /// The facilities that contribute to one channel, best first.
  ///
  /// Used by the Bank page's "what is feeding this number" breakdowns.
  Future<List<FacilityContribution>> contributors(
    IncomeChannel channel, {
    bool ownedOnly = true,
    int limit = 10,
  }) async {
    await _store.init();
    await _income.ensureLoaded();
    final all = await _facilities.all();

    final ownedIds = <String>{};
    for (final bucket in facilityBuckets) {
      ownedIds.addAll(_store.ids(bucket));
    }

    final byId = <String, Facility>{for (final f in all) f.id: f};
    final out = <FacilityContribution>[];
    for (final id in _income.facilityIdsWithIncome) {
      if (ownedOnly && !ownedIds.contains(id)) continue;
      for (final e in _income.forFacility(id)) {
        if (e.channel != channel) continue;
        final f = byId[id];
        out.add(FacilityContribution(
          facilityId: id,
          name: f?.name ?? id,
          group: f?.group ?? '',
          minAmount: e.minAmount,
          maxAmount: e.maxAmount,
        ));
      }
    }
    out.sort((a, b) {
      final byAmount = b.maxAmount.compareTo(a.maxAmount);
      if (byAmount != 0) return byAmount;
      return a.facilityId.compareTo(b.facilityId);
    });
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  /// Unowned facilities in [channel], best value first.
  ///
  /// income.json knows what 2,794 facilities pay and the shards know what
  /// 3,823 of them cost, but nothing joined the two, so "what should I buy
  /// next" could not be answered anywhere in the app. The spread is not
  /// subtle: across the buffet's cod-per-hour facilities the best buy returns
  /// over 500x more per cod than the worst.
  ///
  /// Only cod prices are ranked. A facility sold for diamonds or film is not
  /// comparable on the same scale, and inventing an exchange rate between
  /// them would be making up the answer.
  Future<List<FacilityValue>> bestValue(
    IncomeChannel channel, {
    int limit = 5,
  }) async {
    await _store.init();
    await _income.ensureLoaded();
    final all = await _facilities.all();

    final ownedIds = <String>{};
    for (final bucket in facilityBuckets) {
      ownedIds.addAll(_store.ids(bucket));
    }

    final out = <FacilityValue>[];
    for (final f in all) {
      if (ownedIds.contains(f.id)) continue;

      var cod = 0;
      for (final price in f.price) {
        if (price.currency == MoneyCurrency.cod) cod += price.amount;
      }
      if (cod <= 0) continue;

      for (final e in _income.forFacility(f.id)) {
        if (e.channel != channel) continue;
        if (e.maxAmount <= 0) continue;
        out.add(FacilityValue(
          facilityId: f.id,
          name: f.name,
          group: f.group,
          amount: e.maxAmount,
          codPrice: cod,
        ));
      }
    }

    out.sort((a, b) {
      final byValue = b.perCod.compareTo(a.perCod);
      if (byValue != 0) return byValue;
      return a.facilityId.compareTo(b.facilityId);
    });
    return out.length > limit ? out.sublist(0, limit) : out;
  }
}

/// One facility's share of a channel.
/// An unowned facility, and what it pays back per cod spent.
class FacilityValue {
  const FacilityValue({
    required this.facilityId,
    required this.name,
    required this.group,
    required this.amount,
    required this.codPrice,
  });

  final String facilityId;
  final String name;
  final String group;

  /// The facility's income in this channel, in that channel's own units.
  final double amount;

  final int codPrice;

  /// Income per cod spent. The whole point of the ranking.
  double get perCod => codPrice == 0 ? 0 : amount / codPrice;
}

class FacilityContribution {
  const FacilityContribution({
    required this.facilityId,
    required this.name,
    required this.group,
    required this.minAmount,
    required this.maxAmount,
  });

  final String facilityId;
  final String name;
  final String group;
  final double minAmount;
  final double maxAmount;

  bool get isRange => (maxAmount - minAmount).abs() > 1e-9;
}
