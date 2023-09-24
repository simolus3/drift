import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json.drift.dart';
import 'shared.dart' show BuyableItems;
import 'shared.drift.dart';

part 'json.g.dart';

typedef ShoppingCartWithItems = ({
  ShoppingCart cart,
  List<BuyableItem> items,
});

// #docregion tables
@DataClassName('ShoppingCart')
class ShoppingCarts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entries => text().map(ShoppingCartEntries.converter)();

  // we could also store some further information about the user creating
  // this cart etc.
}

@JsonSerializable()
class ShoppingCartEntries {
  final List<int> items;

  ShoppingCartEntries({required this.items});

  factory ShoppingCartEntries.fromJson(Map<String, Object?> json) =>
      _$ShoppingCartEntriesFromJson(json);

  Map<String, Object?> toJson() {
    return _$ShoppingCartEntriesToJson(this);
  }

  static JsonTypeConverter<ShoppingCartEntries, String> converter =
      TypeConverter.json(
    fromJson: (json) =>
        ShoppingCartEntries.fromJson(json as Map<String, Object?>),
    toJson: (entries) => entries.toJson(),
  );
}

// #enddocregion tables

@DriftDatabase(tables: [BuyableItems, ShoppingCarts])
class JsonBasedDatabase extends $JsonBasedDatabase {
  JsonBasedDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // #docregion createEmptyCart
  Future<ShoppingCartWithItems> createEmptyCart() async {
    final cart = await into(shoppingCarts)
        .insertReturning(const ShoppingCartsCompanion());

    // we set the items property to [] because we've just created the cart - it
    // will be empty
    return (cart: cart, items: <BuyableItem>[]);
  }
  // #enddocregion createEmptyCart

  // #docregion updateCart
  Future<void> updateCart(ShoppingCartWithItems entry) async {
    await update(shoppingCarts).replace(entry.cart.copyWith(
        entries: ShoppingCartEntries(items: [
      for (final item in entry.items) item.id,
    ])));
  }
  // #enddocregion updateCart

  // #docregion watchCart
  Stream<ShoppingCartWithItems> watchCart(int id) {
    final referencedItems = shoppingCarts.entries.jsonEach(this, r'#$.items');

    final cartWithEntries = select(shoppingCarts).join(
      [
        // Join every referenced item from the json array
        innerJoin(referencedItems, const Constant(true), useColumns: false),
        // And use that to join the items
        innerJoin(
          buyableItems,
          buyableItems.id.equalsExp(referencedItems.value.cast()),
        ),
      ],
    )..where(shoppingCarts.id.equals(id));

    return cartWithEntries.watch().map((rows) {
      late ShoppingCart cart;
      final entries = <BuyableItem>[];

      for (final row in rows) {
        cart = row.readTable(shoppingCarts);
        entries.add(row.readTable(buyableItems));
      }

      return (cart: cart, items: entries);
    });
  }
  // #enddocregion watchCart

  // #docregion watchAllCarts
  Stream<List<ShoppingCartWithItems>> watchAllCarts() {
    final referencedItems = shoppingCarts.entries.jsonEach(this, r'#$.items');

    final cartWithEntries = select(shoppingCarts).join(
      [
        // Join every referenced item from the json array
        innerJoin(referencedItems, const Constant(true), useColumns: false),
        // And use that to join the items
        innerJoin(
          buyableItems,
          buyableItems.id.equalsExp(referencedItems.value.cast()),
        ),
      ],
    );

    return cartWithEntries.watch().map((rows) {
      final entriesByCart = <ShoppingCart, List<BuyableItem>>{};

      for (final row in rows) {
        final cart = row.readTable(shoppingCarts);
        final item = row.readTable(buyableItems);

        entriesByCart.putIfAbsent(cart, () => []).add(item);
      }

      return [
        for (final entry in entriesByCart.entries)
          (cart: entry.key, items: entry.value)
      ];
    });
  }
  // #enddocregion watchAllCarts
}
