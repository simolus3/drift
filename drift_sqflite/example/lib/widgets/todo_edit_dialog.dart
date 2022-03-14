import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:example/bloc.dart';
import 'package:example/database/database.dart';
import 'package:provider/provider.dart';

final _dateFormat = DateFormat.yMMMd();

class TodoEditDialog extends StatefulWidget {
  final TodoEntry entry;

  const TodoEditDialog({Key? key, required this.entry}) : super(key: key);

  @override
  _TodoEditDialogState createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  final TextEditingController textController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    textController.text = widget.entry.content;
    _dueDate = widget.entry.targetDate;
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var formattedDate = 'No date set';
    if (_dueDate != null) {
      formattedDate = _dateFormat.format(_dueDate!);
    }

    return AlertDialog(
      title: const Text('Edit entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
              helperText: 'Content of entry',
            ),
          ),
          Row(
            children: <Widget>[
              Text(formattedDate),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final now = DateTime.now();
                  final initialDate = _dueDate ?? now;
                  final firstDate =
                      initialDate.isBefore(now) ? initialDate : now;

                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(3000),
                  );

                  setState(() {
                    if (selectedDate != null) _dueDate = selectedDate;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          style: ButtonStyle(
            textStyle: MaterialStateProperty.all(
              const TextStyle(color: Colors.black),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            final updatedContent = textController.text;
            final entry = widget.entry.copyWith(
              content: updatedContent.isNotEmpty ? updatedContent : null,
              targetDate: _dueDate,
            );

            Provider.of<TodoAppBloc>(context, listen: false).updateEntry(entry);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
