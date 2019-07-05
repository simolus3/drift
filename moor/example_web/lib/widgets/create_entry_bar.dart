import 'package:flutter_web/material.dart';

import '../main.dart';

class CreateEntryBar extends StatefulWidget {
  @override
  _CreateEntryBarState createState() => _CreateEntryBarState();
}

class _CreateEntryBarState extends State<CreateEntryBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            final text = _controller.text;
            _controller.clear();

            DatabaseProvider.provide(context).createTodoEntry(text);
          },
        ),
      ],
    );
  }
}
