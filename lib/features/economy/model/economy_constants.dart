/// Fixed numbers the Animal Restaurant economy runs on.
///
/// Every constant here carries the source it was read from. Where the game
/// does not publish a number, there is no constant: the Bank page says
/// "not published" instead of showing a guess.
class EconomyConstants {
  const EconomyConstants._();

  // ---------------------------------------------------------------- Buffet

  /// The Buffet conveyor accrues for at most 12 hours.
  ///
  /// Source: the Buffet tutorial on the wiki — "The conveyor belt can work
  /// continuously for a maximum of 12 hours".
  static const int buffetMaxAccrualHours = 12;

  /// The Buffet ad pays a bonus of 40% of what the buffet has banked …
  ///
  /// Source: wiki Guide:Cod — "Ad bonus for the buffet is 40% of the buffet
  /// earning and capped at 1,000,000". The same guide's advice to watch the
  /// ad "before or as buffet earning reaches 2,500,000" is consistent:
  /// 0.40 * 2,500,000 = 1,000,000, exactly the cap.
  ///
  /// The Bank page previously used 1.5x capped at +1,500,000, which is not
  /// supported by any source found.
  static const double buffetAdBonusFraction = 0.40;

  /// … capped at this many cod.
  static const int buffetAdBonusCapCod = 1000000;

  /// Each friend working your buffet raises its revenue by 10% for 4 hours.
  ///
  /// Source: wiki Buffet page, "Working" section (Update 5.1). The number of
  /// friends who can work at once is not published, so the Bank page asks the
  /// player how many are working instead of assuming.
  static const double buffetFriendBonusFractionEach = 0.10;
  static const int buffetFriendBonusHours = 4;

  /// Working part-time pays the player a fixed 200 plates every 4 hours;
  /// Yolky earns the amount set by his raise level over the same period.
  ///
  /// Source: wiki Buffet page, Update v8.2.0.g notes.
  static const int buffetWorkPlayerPlatesPer4h = 200;

  // -------------------------------------------------------------- Tip jar

  /// The tip jar's ad doubles the collected tips.
  ///
  /// Source: wiki Guide:Cod — "Watch Ads: Double the tip jar income."
  static const double tipJarAdMultiplier = 2.0;

  // -------------------------------------------------------------- Terrace

  /// Gathers available on the Terrace per day.
  ///
  /// Source: wiki Terrace page — "Up to 6 gathers can be made on the Terrace
  /// per day."
  static const int terraceGathersPerDay = 6;

  /// Cooldown in minutes before gather #1..#6 (index 0 is the first gather).
  ///
  /// Source: wiki Terrace page cooldown table. A *rejected* gather has a
  /// cooldown of 1 to 50 minutes instead.
  static const List<int> terraceGatherCooldownMinutes = <int>[
    3,
    10,
    15,
    40,
    80,
    120,
  ];

  // -------------------------------------------------------------- Takeout

  /// Documented ceiling on takeout orders per day.
  ///
  /// Source: wiki Takeout page — "A maximum of 65 orders are possible every
  /// day, increased by upgrading Support Chef Meow and purchasing Provision
  /// Table facilities." The starting number of orders is not published, so
  /// the Bank page shows the ceiling and the facility contribution and does
  /// not invent a base.
  static const int takeoutMaxOrdersPerDay = 65;

  // -------------------------------------------------------------- Concert

  /// The Ticket Booth stops accepting income at these totals; anything the
  /// performers earn past them is lost.
  ///
  /// Source: wiki Concert page, "Ticket Booth" section.
  static const int ticketBoothCapCod = 10000000;
  static const int ticketBoothCapFilm = 100000;

  /// Free daily invites obtainable from Light facilities.
  ///
  /// Source: wiki Guide:Film — "Up to 20 can be earned via lights, up to 10
  /// from ads, up to 3 from Treasure Hunts." The individual Light rows on the
  /// wiki add up to more than 20, so the ceiling — not the sum — is what a
  /// player can actually claim.
  static const int concertMaxDailyInvitesFromLights = 20;
  static const int concertMaxDailyInvitesFromAds = 10;
  static const int concertMaxDailyInvitesFromTreasureHunts = 3;

  // ------------------------------------------------------------- Gachapon

  /// Documented ceiling on Gachapon draws per day.
  ///
  /// Source: wiki Gachapon page — "a maximum of 286 draws + 1 free draw on
  /// each side per day". Note the per-facility "+N Draws" rows on the same
  /// wiki add up to 292, so one of the two figures is stale; the Bank page
  /// shows both and says so.
  static const int gachaponMaxDrawsPerDay = 286;

  // --------------------------------------------------------- Fishing pond

  /// A leased booth pays out once every 5 minutes.
  ///
  /// Source: the "Paid (per 5 min)" column of the wiki's booth owner table.
  static const int boothPayoutIntervalMinutes = 5;

  /// How long a booth owner stays, from `assets/data/booth_owners.json`
  /// (`stayDurationMinutes`), is per-owner and is read from that file.

  /// Booth owners attracted by a rare fish have a 50% chance of paying 5
  /// diamonds. Rare fish spawn every 12 to 72 hours.
  ///
  /// Source: wiki Fishing Pond page, Update v8.5.8g notes.
  static const double rareFishDiamondChance = 0.50;
  static const int rareFishDiamondAmount = 5;
}
