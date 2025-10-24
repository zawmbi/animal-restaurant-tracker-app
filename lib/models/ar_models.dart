// // lib/models/ar_models.dart
// final CustomerCategory category;
// final Requirements requirements;
// final String? description;
// final String? livesIn;
// final int? appearanceWeight;
// final List<String> requiredFood;
// final List<String> dishesOrdered;
// final List<EventTag> eventTags;
// final List<Memento> mementos;
// final Uri? wikiUrl;
// Customer({
// required this.id,
// required this.name,
// required this.category,
// this.requirements = const Requirements(),
// this.description,
// this.livesIn,
// this.appearanceWeight,
// this.requiredFood = const [],
// this.dishesOrdered = const [],
// this.eventTags = const [],
// this.mementos = const [],
// this.wikiUrl,
// });
// }


// enum LetterType { individual, series, newspaper, holiday, pricePermission }


// @immutable
// class Letter {
// final String id;
// final String title;
// final LetterType type;
// final String? series;
// const Letter({ required this.id, required this.title, required this.type, this.series });
// }


// String slugify(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+\$'), '');


// String rarityFromAppearanceWeight(int? w) {
// if (w == null) return 'Unknown';
// if (w >= 5000) return 'Very Common';
// if (w >= 1000) return 'Common';
// if (w >= 300) return 'Uncommon';
// if (w >= 100) return 'Rare';
// return 'Very Rare';
// }