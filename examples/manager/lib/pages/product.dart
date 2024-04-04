import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:manager/database.dart';
import 'package:manager/main.dart';

class ProductPage extends HookConsumerWidget {
  const ProductPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = useMemoized(() => db.managers.products.all().watch());
    final data = useStream(stream);

    final Widget body;
    var items = <Product>[];
    if (data.hasData) {
      items = data.data!;
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text("${product.description} ${product.releaseDate}"),
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
                  final nameTextController = useTextEditingController();
                  final descriptionTextController = useTextEditingController();
                  final color = useState<Color?>(null);
                  final releaseDate = useState<DateTime?>(null);

                  return SimpleDialog(
                    title: Text("Add Product"),
                    children: [
                      TextField(
                        controller: nameTextController,
                        decoration: InputDecoration(labelText: "Name"),
                      ),
                      TextField(
                        controller: descriptionTextController,
                        decoration: InputDecoration(labelText: "Description"),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.value,
                        ),
                        title: Text("Color"),
                        onTap: () {
                          showColorPickerDialog(
                                  context, color.value ?? Colors.blue)
                              .then((value) => color.value = value);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_month),
                        title: Text("Date"),
                        subtitle: releaseDate.value != null
                            ? Text(releaseDate.value.toString())
                            : null,
                        onTap: () {
                          showDatePicker(
                            context: ctx,
                            initialDate: releaseDate.value ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ).then((value) {
                            releaseDate.value = value;
                          });
                        },
                      ),
                      ElevatedButton(
                          onPressed: () {
                            db.managers.products.create((o) => o(
                                color: color.value ?? Colors.red,
                                description: descriptionTextController.text,
                                name: nameTextController.text,
                                releaseDate: releaseDate.value!));
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
