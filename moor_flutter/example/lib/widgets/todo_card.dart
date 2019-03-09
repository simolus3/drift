import 'package:flutter/material.dart';
import 'package:moor_example/database/database.dart';
import 'package:moor_example/main.dart';
import 'package:moor_example/widgets/todo_edit_dialog.dart';
import 'package:intl/intl.dart';

final DateFormat _format = DateFormat.yMMMd();

/// Card that displays an entry and an icon button to delete that entry
class TodoCard extends StatelessWidget {
  final TodoEntry entry;

  TodoCard(this.entry) : super(key: ObjectKey(entry.id));

  @override
  Widget build(BuildContext context) {
    Widget dueDate;
    if (entry.targetDate == null) {
      dueDate = const Text(
        'No due date set',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else {
      dueDate = Text(
        _format.format(entry.targetDate),
        style: const TextStyle(fontSize: 12),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.content),
                  dueDate,
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: Colors.green,
              onPressed: () async {
                final dateTime = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2019),
                    lastDate: DateTime(3038));

                await BlocProvider.provideBloc(context)
                    .db
                    .updateDate(entry.id, dateTime);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              color: Colors.blue,
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => TodoEditDialog(
                        entry: entry,
                      ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                // We delete the entry here. Again, notice how we don't have to call setState() or
                // inform the parent widget. The animated list will take care of this automatically.
                BlocProvider.provideBloc(context).db.deleteEntry(entry);
              },
            )
          ],
        ),
      ),
    );
  }
}
