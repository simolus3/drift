import 'package:flutter/material.dart';
import 'package:moor_example/database/database.dart';
import 'package:moor_example/main.dart';

class TodoEditDialog extends StatefulWidget {
  final TodoEntry entry;

  const TodoEditDialog({Key key, this.entry}) : super(key: key);

  @override
  _TodoEditDialogState createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    textController.text = widget.entry.content;
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              helperText: 'Content of entry',
            ),
          ),
        ],
      ),
      actions: [
        FlatButton(
          child: const Text('Cancel'),
          textColor: Colors.red,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FlatButton(
          child: const Text('Save'),
          onPressed: () {
            final entry = widget.entry;
            if (textController.text.isNotEmpty) {
              BlocProvider.provideBloc(context)
                  .db
                  .updateContent(entry.id, textController.text);
            }

            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
