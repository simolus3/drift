import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import 'shared.dart' show BuyableItems;
import 'shared.drift.dart';

import 'relational.drift.dart';

typedef ShoppingCartWithItems = ({
  ShoppingCart cart,
  List<BuyableItem> items,
});

// #docregion cart_tables
class ShoppingCarts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // we could also store some further information about the user creating
  // this cart etc.
}

@DataClassName('ShoppingCartEntry')
class ShoppingCartEntries extends Table {
  // id of the cart that should contain this item.
  IntColumn get shoppingCart => integer().references(ShoppingCarts, #id)();
  // id of the item in this cart
  IntColumn get item => integer().references(BuyableItems, #id)();
  // again, we could store additional information like when the item was
  // added, an amount, etc.
}
// #enddocregion cart_tables

@DriftDatabase(tables: [BuyableItems, ShoppingCarts, ShoppingCartEntries])
class RelationalDatabase extends $RelationalDatabase {
  RelationalDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // #docregion updateCart
  Future<void> updateCart(ShoppingCartWithItems entry) {
    return transaction(() async {
      final cart = entry.cart;

      // first, we write the shopping cart
      await update(shoppingCarts).replace(cart);

      // we replace the entries of the cart, so first delete the old ones
      await (delete(shoppingCartEntries)
            ..where((entry) => entry.shoppingCart.equals(cart.id)))
          .go();

      // And write the new ones
      for (final item in entry.items) {
        await into(shoppingCartEntries)
            .insert(ShoppingCartEntry(shoppingCart: cart.id, item: item.id));
      }
    });
  }
  // #enddocregion updateCart

  // #docregion createEmptyCart
  Future<ShoppingCartWithItems> createEmptyCart() async {
    final cart = await into(shoppingCarts)
        .insertReturning(const ShoppingCartsCompanion());
    // we set the items property to [] because we've just created the cart - it
    // will be empty
    return (cart: cart, items: <BuyableItem>[]);
  }
  // #enddocregion createEmptyCart

  // #docregion watchCart
  Stream<ShoppingCartWithItems> watchCart(int id) {
    // load information about the cart
    final cartQuery = select(shoppingCarts)
      ..where((cart) => cart.id.equals(id));

    // and also load information about the entries in this cart
    final contentQuery = select(shoppingCartEntries).join(
      [
        innerJoin(
          buyableItems,
          buyableItems.id.equalsExp(shoppingCartEntries.item),
        ),
      ],
    )..where(shoppingCartEntries.shoppingCart.equals(id));

    final cartStream = cartQuery.watchSingle();

    final contentStream = contentQuery.watch().map((rows) {
      // we join the shoppingCartEntries with the buyableItems, but we
      // only care about the item here.
      return rows.map((row) => row.readTable(buyableItems)).toList();
    });

    // now, we can merge the two queries together in one stream
    return Rx.combineLatest2(cartStream, contentStream,
        (ShoppingCart cart, List<BuyableItem> items) {
      return (cart: cart, items: items);
    });
  }
  // #enddocregion watchCart

  // #docregion watchAllCarts
  Stream<List<ShoppingCartWithItems>> watchAllCarts() {
    // start by watching all carts
    final cartStream = select(shoppingCarts).watch();

    return cartStream.switchMap((carts) {
      // this method is called whenever the list of carts changes. For each
      // cart, now we want to load all the items in it.
      // (we create a map from id to cart here just for performance reasons)
      final idToCart = {for (var cart in carts) cart.id: cart};
      final ids = idToCart.keys;

      // select all entries that are included in any cart that we found
      final entryQuery = select(shoppingCartEntries).join(
        [
          innerJoin(
            buyableItems,
            buyableItems.id.equalsExp(shoppingCartEntries.item),
          )
        ],
      )..where(shoppingCartEntries.shoppingCart.isIn(ids));

      return entryQuery.watch().map((rows) {
        // Store the list of entries for each cart, again using maps for faster
        // lookups.
        final idToItems = <int, List<BuyableItem>>{};

        // for each entry (row) that is included in a cart, put it in the map
        // of items.
        for (final row in rows) {
          final item = row.readTable(buyableItems);
          final id = row.readTable(shoppingCartEntries).shoppingCart;

          idToItems.putIfAbsent(id, () => []).add(item);
        }

        // finally, all that's left is to merge the map of carts with the map of
        // entries
        return [
          for (var id in ids) (cart: idToCart[id]!, items: idToItems[id] ?? []),
        ];
      });
    });
  }
  // #enddocregion watchAllCarts
}
