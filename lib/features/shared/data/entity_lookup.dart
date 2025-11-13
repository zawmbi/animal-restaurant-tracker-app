import 'package:flutter/material.dart';

import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart';
import '../../customers/model/customer.dart';
import '../../customers/model/memento.dart';

import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../dishes/ui/dish_detail_page.dart';

import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../facilities/ui/facility_detail_page.dart';

import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../letters/ui/letters_page.dart';

/// Global lookup for any entity by ID.
///
/// This allows clickable chips everywhere:
/// - recipes
/// - facilities
/// - letters
/// - customers
/// - mementos
/// - etc.
class EntityLookup {
  static final _customers = CustomersRepository.instance;
  static final _dishes = DishesRepository.instance;
  static final _facilities = FacilitiesRepository.instance;
  static final _letters = LettersRepository.instance;

  /// Find any entity by its ID.
  static Future<dynamic> findById(String id) async {
    // Customer
    final customer = await _customers.findById(id);
    if (customer != null) return customer;

    // Dish / recipe
    final dish = await _dishes.findById(id);
    if (dish != null) return dish;

    // Facility
    final facility = await _facilities.findById(id);
    if (facility != null) return facility;

    // Letter
    final letter = await _letters.findById(id);
    if (letter != null) return letter;

    // Memento (search through all customers)
    final memOwner = await findMementoOwner(id);
    if (memOwner != null) {
      final mem = memOwner.mementos.firstWhere(
        (m) => m.id == id,
        orElse: () => Memento(id: id, name: id, stars: 0),
      );
      return mem;
    }

    return null;
  }

  /// Try to locate which customer owns a specific memento ID.
  static Future<Customer?> findMementoOwner(String mementoId) async {
    final all = await _customers.all();
    for (final c in all) {
      if (c.mementos.any((m) => m.id == mementoId)) {
        return c;
      }
    }
    return null;
  }

  /// Returns the proper display name for an entity ID.
  static Future<String> resolveName(String id) async {
    final e = await findById(id);
    if (e == null) return id;

    if (e is Customer) return e.name;
    if (e is Dish) return e.name;
    if (e is Facility) return e.name;
    if (e is Letter) return e.title;
    if (e is Memento) return e.name;

    return id;
  }

  /// Opens the correct detail page depending on entity type.
  static Future<void> openEntity(BuildContext context, String id) async {
    final e = await findById(id);
    if (e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not found: $id')),
      );
      return;
    }

    Widget page;

    if (e is Customer) {
      page = CustomerDetailPage(customer: e);
    } else if (e is Dish) {
      page = DishDetailPage(dish: e);
    } else if (e is Facility) {
      page = FacilityDetailPage(facility: e);
    } else if (e is Letter) {
      page = LetterDetailPage(letter: e);
    } else if (e is Memento) {
      final owner = await findMementoOwner(id);
      if (owner != null) {
        page = CustomerDetailPage(customer: owner);
      } else {
        return;
      }
    } else {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
