import 'package:flutter/material.dart' hide Column;
import 'package:flutter/widgets.dart' as f show Column;
import 'package:moor_example/bloc.dart';
import 'package:moor_example/database/database.dart';
import 'package:moor_example/main.dart';
import 'package:moor_example/widgets/todo_card.dart';
import 'package:moor_flutter/moor_flutter.dart';

// ignore_for_file: prefer_const_constructors

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() {
    return HomeScreenState();
  }
}

/// Shows a list of todos and displays a text input to add another one
class HomeScreenState extends State<HomeScreen> {
  // we only use this to reset the input field at the bottom when a entry has been added
  final TextEditingController controller = TextEditingController();

  TodoAppBloc get bloc => BlocProvider.provideBloc(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo list'),
      ),
      // A moorAnimatedList automatically animates incoming and leaving items, we only
      // have to tell it what data to display and how to turn data into widgets.
      body: MoorAnimatedList<TodoEntry>(
        stream: bloc
            .allEntries, // we want to show an updating stream of all entries
        // consider items equal if their id matches. Otherwise, we'd get an
        // animation of an old item leaving and another one coming in every time
        // the content of an item changed!
        equals: (a, b) => a.id == b.id,
        itemBuilder: (ctx, item, animation) {
          // When a new item arrives, it will expand vertically
          return SizeTransition(
            key: ObjectKey(item.id),
            sizeFactor: animation,
            axis: Axis.vertical,
            child: TodoCard(item),
          );
        },
        removedItemBuilder: (ctx, item, animation) {
          // and it will leave the same way after being deleted.
          return SizeTransition(
            key: ObjectKey(item.id),
            sizeFactor: animation,
            axis: Axis.vertical,
            child: AnimatedBuilder(
                animation:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: TodoCard(item),
                builder: (context, child) {
                  return Opacity(
                    opacity: animation.value,
                    child: child,
                  );
                }),
          );
        },
      ),
      bottomSheet: Material(
        elevation: 12.0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: f.Column(
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
      ),
    );
  }

  void _createTodoEntry() {
    if (controller.text.isNotEmpty) {
      // We write the entry here. Notice how we don't have to call setState()
      // or anything - moor will take care of updating the list automatically.
      bloc.addEntry(TodoEntry(content: controller.text));
      controller.clear();
    }
  }
}
