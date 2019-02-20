import 'package:flutter/material.dart';
import 'package:sally_example/database.dart';
import 'package:sally_example/main.dart';
import 'package:sally_example/widgets/todo_card.dart';
import 'package:sally_flutter/sally_flutter.dart';

// ignore_for_file: prefer_const_constructors

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = DatabaseProvider.provideDb(context);

    return Scaffold(
      appBar: AppBar(title: Text('Todo list'),),
      body: SallyAnimatedList<TodoEntry>(
        stream: db.allEntries(),
        itemBuilder: (ctx, TodoEntry item, animation) {
          return SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            child: TodoCard(item),
          );
        },
        removedItemBuilder: (_, __, ___) => Container(),
      ),
      bottomSheet: Material(
        elevation: 12.0,
        child: TextField(
          onSubmitted: (content) {
            db.addEntry(TodoEntry(content: content));
          },
        ),
      ),
    );
  }
}
