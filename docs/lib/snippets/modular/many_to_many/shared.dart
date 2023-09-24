import 'package:drift/drift.dart';

import 'shared.drift.dart';

abstract class ShoppingCart {
  int get id;

  const ShoppingCart();
}

// #docregion interface
typedef ShoppingCartWithItems = ({
  ShoppingCart cart,
  List<BuyableItem> items,
});

abstract class CartRepository {
  Future<ShoppingCartWithItems> createEmptyCart();
  Future<void> updateCart(ShoppingCartWithItems entry);

  Stream<ShoppingCartWithItems> watchCart(int id);
  Stream<ShoppingCartWithItems> watchAllCarts();
}
// #enddocregion interface

// #docregion buyable_items
class BuyableItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  IntColumn get price => integer()();
  // we could add more columns as we wish.
}
// #enddocregion buyable_items
