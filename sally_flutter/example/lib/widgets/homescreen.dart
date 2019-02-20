import 'package:flutter/material.dart';
import 'package:sally_example/database.dart';
import 'package:sally_example/main.dart';
import 'package:sally_example/widgets/todo_card.dart';
import 'package:sally_flutter/sally_flutter.dart';

// ignore_for_file: prefer_const_constructors

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
  Database get db => DatabaseProvider.provideDb(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo list'),
      ),
      body: SallyAnimatedList<TodoEntry>(
        stream: db.allEntries(),
        itemBuilder: (ctx, dynamic item, animation) {
          return SizeTransition(
            key: ObjectKey((item as TodoEntry).id),
            sizeFactor: animation,
            axis: Axis.vertical,
            child: TodoCard(item as TodoEntry),
          );
        },
        removedItemBuilder: (ctx, dynamic item, animation) {
          return SizeTransition(
            key: ObjectKey((item as TodoEntry).id),
            sizeFactor: animation,
            axis: Axis.vertical,
            child: TodoCard(item as TodoEntry),
          );
        },
      ),
      bottomSheet: Material(
        elevation: 12.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('What needs to be done?'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => _createTodoEntry(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    color: Theme.of(context).accentColor,
                    onPressed: _createTodoEntry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createTodoEntry() {
    if (controller.text.isNotEmpty) {
      // We write the entry here. Notice how we don't have to call setState()
      // or anything - sally will take care of updating the list automatically.
      db.addEntry(TodoEntry(content: controller.text));
      controller.clear();
    }
  }
}
