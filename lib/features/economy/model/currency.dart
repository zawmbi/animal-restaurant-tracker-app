/// Canonical currency type for the app.
///
/// This file used to declare a *second* `MoneyCurrency` enum, identical in
/// shape to the one in `lib/features/facilities/model/facility.dart` but with
/// a broken icon mapping (`'imagescod.png'` with no slash, and `'images/...'`
/// paths missing the `assets/` prefix). Nothing imported it, so the two never
/// collided at run time, but any file importing both would not have compiled
/// and any UI that had used its `assetPath` would have shown no artwork.
///
/// `facility.dart` is depended on across the app and owns the working mapping,
/// so it stays the single definition and this file is now a re-export of it.
/// Import either one; they name the same type.
library;

import '../../facilities/model/facility.dart';

export '../../facilities/model/facility.dart'
    show MoneyCurrency, MoneyCurrencyKey, MoneyCurrencyIcon;

/// Human-readable labels, for headings and per-currency rows.
extension MoneyCurrencyLabel on MoneyCurrency {
  /// Plural label, e.g. "Cod", "Plates".
  String get label {
    switch (this) {
      case MoneyCurrency.cod:
        return 'Cod';
      case MoneyCurrency.plates:
        return 'Plates';
      case MoneyCurrency.bells:
        return 'Bells';
      case MoneyCurrency.film:
        return 'Film';
      case MoneyCurrency.buttons:
        return 'Buttons';
      case MoneyCurrency.diamonds:
        return 'Diamonds';
    }
  }
}

/// Parses a currency name as it appears in the JSON data assets.
///
/// Returns null rather than throwing for anything unknown, because some data
/// files carry non-currency payout kinds (booth owners can pay out `rating`,
/// which is a star rating and not money) and those must be skipped, not
/// crash a whole page.
MoneyCurrency? parseMoneyCurrency(String? raw) {
  if (raw == null) return null;
  switch (raw.trim().toLowerCase()) {
    case 'cod':
      return MoneyCurrency.cod;
    case 'plate':
    case 'plates':
      return MoneyCurrency.plates;
    case 'bell':
    case 'bells':
      return MoneyCurrency.bells;
    case 'film':
    case 'films':
      return MoneyCurrency.film;
    case 'button':
    case 'buttons':
      return MoneyCurrency.buttons;
    case 'diamond':
    case 'diamonds':
      return MoneyCurrency.diamonds;
    default:
      return null;
  }
}
