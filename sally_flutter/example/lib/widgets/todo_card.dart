import 'package:flutter/material.dart';
import 'package:sally_example/database.dart';

class TodoCard extends StatelessWidget {

  final TodoEntry entry;

  TodoCard(this.entry) : super(key: ObjectKey(entry.id));

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(entry.content),
    );
  }
}
