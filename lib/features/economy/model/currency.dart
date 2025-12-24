// ignore_for_file: deprecated_member_use, constant_identifier_names, unnecessary_cast

import 'package:flutter/foundation.dart';

/// Payment types seen across AR.
enum MoneyCurrency { cod, plates, bells, film, buttons, diamonds }

extension MoneyCurrencyKey on MoneyCurrency {
  String get key => describeEnum(this);
}

extension MoneyCurrencyIcon on MoneyCurrency {
  /// Always points to: assets/images/<currency>.png
  /// Make sure you actually have these files:
  /// cod.png, plate.png, bell.png, film.png, button.png, diamond.png
  String get assetPath {
    switch (this) {
      case MoneyCurrency.cod:
        return 'imagescod.png';
      case MoneyCurrency.plates:
        return 'images/plate.png';
      case MoneyCurrency.bells:
        return 'images/bell.png';
      case MoneyCurrency.film:
        return 'images/film.png';
      case MoneyCurrency.buttons:
        return 'images/button.png';
      case MoneyCurrency.diamonds:
        return 'images/diamond.png';
    }
  }
}
