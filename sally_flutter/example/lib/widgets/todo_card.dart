import 'package:flutter/material.dart';
import 'package:sally_example/database.dart';
import 'package:sally_example/main.dart';

class TodoCard extends StatelessWidget {
  final TodoEntry entry;

  TodoCard(this.entry) : super(key: ObjectKey(entry.id));

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child: Text(entry.content)),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                DatabaseProvider.provideDb(context).deleteEntry(entry);
              },
            )
          ],
        ),
      ),
    );
  }
}
