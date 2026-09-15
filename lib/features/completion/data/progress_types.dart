/// Every `UnlockedStore` type key ("bucket") that holds real tracked progress.
///
/// These are the buckets the pages read and write, gathered in one place so
/// the global completion percentage and the pages agree on spelling.
///
/// Note the two historical spellings still in the codebase:
///  * customers are stored under `customers` (plural) by CustomersPage,
///    CustomerDetailPage and BoothOwnersPage — NOT the `customer` entry in
///    UnlockedStore._defaultTypes,
///  * facilities are stored under `facility` by FacilitiesPage and
///    FacilityDetailPage — NOT the `facility_purchased` default type.
/// The `customer`, `facility_purchased`, `recipe_purchased` and `battle_pass`
/// buckets are legacy/unused and are deliberately not counted here.
class ProgressTypes {
  const ProgressTypes._();

  static const String customers = 'customers';
  static const String dish = 'dish';
  static const String letter = 'letter';
  static const String facility = 'facility';
  static const String courtyardFacility = 'courtyard_facility_purchased';
  static const String mementoCollected = 'memento_collected';
  static const String poster = 'poster';
  static const String movieAct = 'movie_act';
  static const String petOwned = 'pet_owned';
  static const String petMature = 'pet_mature';
  static const String petRoom = 'pet_room_unlocked';
  static const String petPhotoTask = 'pet_photo_task_done';
  static const String staffUnlocked = 'staff_unlocked';
  static const String battlePassClaimed = 'battle_pass_claimed';
  static const String battlePassPremium = 'battle_pass_premium';

  /// Passes the player actually took part in.
  ///
  /// Three of the four shipped passes are expired events. Their tiers cannot
  /// be claimed by anyone who was not there, so counting them made 573 of the
  /// ~7,500 collectibles permanently unreachable — 7.7% of a percentage that
  /// is supposed to be achievable. A pass joins the denominator when the
  /// player says they played it.
  static const String battlePassPlayed = 'battle_pass_played';
  static const String acorn = 'acorn';

  /// Which bucket a facility is tracked in, from the area it lives in.
  ///
  /// The courtyard, the concert stage and the pet yard are checked off on the
  /// Courtyard page and counted under [courtyardFacility]; the six scenes the
  /// Facilities page shows use [facility]. Global search shows both kinds in
  /// one list, and writing them all to [facility] meant ticking a courtyard
  /// item from search wrote to a set no other screen reads.
  static String facilityBucketFor(String areaName) {
    switch (areaName) {
      case 'courtyard':
      case 'courtyard_concert':
      case 'courtyard_pets':
        return courtyardFacility;
      default:
        return facility;
    }
  }

  /// Buckets that are not in `UnlockedStore._defaultTypes` and therefore have
  /// to be registered before their contents can be read back from storage.
  static const List<String> registerOnStartup = <String>[
    customers,
    facility,
    courtyardFacility,
    poster,
    movieAct,
    petOwned,
    petMature,
    petRoom,
    petPhotoTask,
    staffUnlocked,
    battlePassClaimed,
    battlePassPremium,
    battlePassPlayed,
    acorn,
  ];
}
