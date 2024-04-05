import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:manager/database.dart';
import 'package:manager/main.dart';

class OwnersPage extends HookConsumerWidget {
  const OwnersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = useMemoized(() => db.managers.owner.all().watch());
    final data = useStream(stream);

    final Widget body;
    var items = <OwnerData>[];
    if (data.hasData) {
      items = data.data!;
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            trailing: IconButton(
                onPressed: () {
                  db.managers.owner.delete(product);
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

                  return SimpleDialog(
                    title: const Text("Add Owner"),
                    children: [
                      TextField(
                        controller: nameTextController,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            db.managers.owner.create((o) => o(
                                  name: nameTextController.text,
                                ));
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
