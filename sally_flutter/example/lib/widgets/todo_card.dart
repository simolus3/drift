import 'package:flutter/material.dart';
import 'package:sally_example/database/database.dart';
import 'package:sally_example/main.dart';

/// Card that displays a todo entry and an icon button to delete that entry
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
                // We delete the entry here. Again, notice how we don't have to call setState() or
                // inform the parent widget. The animated list will take care of this automatically.
                DatabaseProvider.provideDb(context).deleteEntry(entry);
              },
            )
          ],
        ),
      ),
    );
  }
}
