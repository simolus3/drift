import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:manager/database.dart';
import 'package:manager/main.dart';

class ListingPage extends HookConsumerWidget {
  const ListingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = useMemoized(() =>
        db.managers.listings.all().watch().asyncMap((event) async {
          final products = await db.managers.products
              .filter(
                  (f) => f.listings((f) => f.id.isIn(event.map((e) => e.id))))
              .get();
          final stores = await db.managers.store
              .filter(
                  (f) => f.listings((f) => f.id.isIn(event.map((e) => e.id))))
              .get();
          return event.map((e) {
            final product =
                products.firstWhere((element) => element.id == e.product);
            final store = stores.firstWhere((element) => element.id == e.store);
            return (product, store, e);
          }).toList();
        }));
    final data = useStream(stream);

    final Widget body;
    var items = <(Product, StoreData, Listing)>[];
    if (data.hasData) {
      items = data.data!;
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final (product, store, listing) = items[index];
          return ListTile(
            title: Text("${product.name} - ${store.name}"),
            subtitle: Text("${listing.price}"),
            trailing: IconButton(
                onPressed: () {
                  db.managers.products.delete(product);
                },
                icon: Icon(Icons.delete)),
            leading: CircleAvatar(
              backgroundColor: product.color,
            ),
          );
        },
      );
    } else {
      body = const Center(child: Text("No data"));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (ctx) {
                return HookBuilder(builder: (context) {
                  final priceTextController = useTextEditingController();
                  final product = useState<Product?>(null);
                  final store = useState<StoreData?>(null);

                  return SimpleDialog(
                    title: Text("Add Listing"),
                    children: [
                      TextField(
                        controller: priceTextController,
                        decoration: InputDecoration(labelText: "Price"),
                      ),
                      ListTile(
                        title: Text("Product"),
                        subtitle: product.value == null
                            ? null
                            : Text(product.value!.name),
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (ctx) {
                                return HookBuilder(builder: (context) {
                                  final data = useStream(
                                      db.managers.products.all().watch());
                                  final items = data.data ?? [];
                                  return SimpleDialog(
                                    title: Text("Select Product"),
                                    children: [
                                      ...items.map((e) => ListTile(
                                            title: Text(e.name),
                                            onTap: () {
                                              product.value = e;
                                              Navigator.of(ctx).pop();
                                            },
                                          ))
                                    ],
                                  );
                                });
                              });
                        },
                      ),
                      ListTile(
                        title: Text("Store"),
                        subtitle: store.value == null
                            ? null
                            : Text(store.value!.name),
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (ctx) {
                                return HookBuilder(builder: (context) {
                                  final data = useStream(
                                      db.managers.store.all().watch());
                                  final items = data.data ?? [];
                                  return SimpleDialog(
                                    title: Text("Select Store"),
                                    children: [
                                      ...items.map((e) => ListTile(
                                            title: Text(e.name),
                                            onTap: () {
                                              store.value = e;
                                              Navigator.of(ctx).pop();
                                            },
                                          ))
                                    ],
                                  );
                                });
                              });
                        },
                      ),
                      ElevatedButton(
                          onPressed: () {
                            db.managers.listings.create((o) => o(
                                price: double.parse(priceTextController.text),
                                product: product.value!.id,
                                store: store.value!.id));
                            Navigator.of(ctx).pop();
                          },
                          child: Text("Add"))
                    ],
                  );
                });
              });
        },
        child: Icon(Icons.add),
      ),
      body: body,
    );
  }
}
