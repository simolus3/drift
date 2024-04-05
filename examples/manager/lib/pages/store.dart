import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:manager/database.dart';
import 'package:manager/main.dart';

class StorePage extends HookConsumerWidget {
  const StorePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = useMemoized(() =>
        db.managers.store.all().watch().asyncMap((event) async {
          final owners = await db.managers.owner
              .filter((f) => f.stores((f) => f.id.isIn(event.map((e) => e.id))))
              .get();
          return event.map((e) {
            final owner = owners.firstWhere((element) => element.id == e.owner);
            return (owner, e);
          }).toList();
        }));
    final data = useStream(stream);

    final Widget body;
    var items = <(OwnerData, StoreData)>[];
    if (data.hasData) {
      items = data.data!;
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final (owner, store) = items[index];
          return ListTile(
            title: Text(store.name),
            subtitle: Text(owner.name),
            trailing: IconButton(
                onPressed: () {
                  db.managers.store.delete(store);
                },
                icon: const Icon(Icons.delete)),
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
                  final nameTextController = useTextEditingController();
                  final owner = useState<OwnerData?>(null);

                  return SimpleDialog(
                    title: const Text("Add Store"),
                    children: [
                      TextField(
                        controller: nameTextController,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      ListTile(
                          title: const Text("Owner"),
                          subtitle: Text(owner.value?.name ?? "Select Owner"),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                return HookBuilder(builder: (context) {
                                  final stream = useMemoized(
                                      () => db.managers.owner.all().watch());
                                  final data = useStream(stream);

                                  return SimpleDialog(
                                    title: const Text("Select Owner"),
                                    children: [
                                      if (data.hasData)
                                        for (final o in data.data!)
                                          ListTile(
                                            title: Text(o.name),
                                            onTap: () {
                                              owner.value = o;
                                              Navigator.of(ctx).pop(owner);
                                            },
                                          )
                                    ],
                                  );
                                });
                              },
                            );
                          }),
                      ElevatedButton(
                          onPressed: () {
                            db.managers.store.create((o) => o(
                                name: nameTextController.text,
                                owner: owner.value!.id));
                            Navigator.of(ctx).pop();
                          },
                          child: const Text("Add"))
                    ],
                  );
                });
              });
        },
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
