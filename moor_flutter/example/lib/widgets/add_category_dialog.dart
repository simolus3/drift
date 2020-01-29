import 'package:flutter/material.dart';
import 'package:moor_example/bloc.dart';
import 'package:provider/provider.dart';

class AddCategoryDialog extends StatefulWidget {
  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Add a category',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name of the category',
              ),
              onSubmitted: (_) => _addEntry(),
            ),
            ButtonBar(
              children: [
                FlatButton(
                  child: const Text('Add'),
                  textColor: Theme.of(context).accentColor,
                  onPressed: _addEntry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addEntry() {
    if (_controller.text.isNotEmpty) {
      Provider.of<TodoAppBloc>(context).addCategory(_controller.text);
      Navigator.of(context).pop();
    }
  }
}
