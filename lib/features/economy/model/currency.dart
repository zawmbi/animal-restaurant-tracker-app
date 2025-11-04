enum Currency { cod, plates, bells, film, buttons, diamonds }

extension CurrencyCodec on Currency {
  static Currency fromString(String s) {
    switch (s.toLowerCase()) {
      case 'cod': return Currency.cod;
      case 'plates': return Currency.plates;
      case 'bells': return Currency.bells;
      case 'film': return Currency.film;
      case 'buttons': return Currency.buttons;
      case 'diamonds': return Currency.diamonds;
      default: throw ArgumentError('Unknown currency: $s');
    }
  }

  String get key => toString().split('.').last; // e.g., "cod"
}