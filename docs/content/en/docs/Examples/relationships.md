---
title: "Many to many relationships"
description: An example that models a shopping cart system with moor.
---

## Defining the model

In this example, we're going to model a shopping system and some of its
queries in moor. First, we need to store some items that can be bought:
```dart
class BuyableItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  IntColumn get price => integer()();
  // we could add more columns as we wish.
}
```

We're going to define two tables for shopping carts: One for the cart
itself, and another one to store the entries in the cart:
```dart
class ShoppingCarts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // we could also store some further information about the user creating
  // this cart etc.
}

@DataClassName('ShoppingCartEntry')
class ShoppingCartEntries extends Table {
  // id of the cart that should contain this item.
  IntColumn get shoppingCart => integer()();
  // id of the item in this cart
  IntColumn get item => integer()();
  // again, we could store additional information like when the item was
  // added, an amount, etc.
}
```

Moor will generate matching classes for the three tables. But having to use
three different classes to model a shopping cart in our application would be
quite annoying. Let's write a single class to represent an entire shopping
cart that:
```dart
/// Represents a full shopping cart with all its items.
class CartWithItems {
  final ShoppingCart cart;
  final List<BuyableItem> items;

  CartWithItems(this.cart, this.items);
}
```

## Inserts
We want to write a `CartWithItems` instance into the database. We assume that
all the `BuyableItem`s included already exist in the database (we could store
them via `into(buyableItems).insert(BuyableItemsCompanion(...))`). Then,
we can insert a full cart with
```dart
Future<void> writeShoppingCart(CartWithItems entry) {
  return transaction((_) async {
    final cart = entry.cart;

    // first, we write the shopping cart
    await into(shoppingCarts).insert(cart, orReplace: true);

    // we replace the entries of the cart, so first delete the old ones
    await (delete(shoppingCartEntries)
        ..where((entry) => entry.shoppingCart.equals(cart.id)))
        .go();

    // And write the new ones
    await into(shoppingCartEntries).insertAll([
      for (var item in entry.items) ShoppingCartEntry(shoppingCart: cart.id, item: item.id)
    ]);
  });
}
```

We could also define a helpful method to create a new, empty shopping cart:
```dart
Future<CartWithItems> createEmptyCart() async {
  final id = await into(shoppingCarts).insert(const ShoppingCartsCompanion());
  final cart = ShoppingCart(id: id);
  // we set the items property to [] because we've just created the cart - it will be empty
  return CartWithItems(cart, []);
}
```

## Selecting a cart
As our `CartWithItems` class consists of multiple components that are separated in the
database (information about the cart, and information about the added items), we'll have
to merge two streams together. The `rxdart` library helps here by providing the 
`combineLatest2` method, allowing us to write
```dart
Stream<CartWithItems> watchCart(int id) {
  // load information about the cart
  final cartQuery = select(shoppingCarts)..where((cart) => cart.id.equals(id));

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
  return Observable.combineLatest2(cartStream, contentStream,
      (ShoppingCart cart, List<BuyableItem> items) {
    return CartWithItems(cart, items);
  });
}
```

## Selecting all carts
Instead of watching a single cart and all associated entries, we
now watch all carts and load all entries for each cart. For this
type of transformation, RxDart's `switchMap` comes in handy:
```dart
Stream<List<CartWithItems>> watchAllCarts() {
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
      for (var row in rows) {
        final item = row.readTable(buyableItems);
        final id = row.readTable(shoppingCartEntries).shoppingCart;

        idToItems.putIfAbsent(id, () => []).add(item);
      }

      // finally, all that's left is to merge the map of carts with the map of
      // entries
      return [
        for (var id in ids)
          CartWithItems(idToCart[id], idToItems[id] ?? []),
      ];
    });
  });
}
```