import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_web_worker_example/src/database/database.dart';

import 'src/platform/platform.dart';

void main() {
  runApp(MaterialApp(
    title: 'Flutter web worker example',
    home: Scaffold(
      body: _DatabaseSample(),
    ),
  ));
}

class _DatabaseSampleState extends State<_DatabaseSample> {
  List<Entrie> allItems = [];
  TextEditingController editController = TextEditingController();
  final database = MyDatabase(Platform.createDatabaseConnection('sample'));

  void addPressed() {
    database.into(database.entries).insert(
        EntriesCompanion(value: drift.Value(editController.text.toString())));
  }

  @override
  void initState() {
    database.allEntries().watch().listen((event) {
      setState(() {
        allItems = event;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            child: TextField(
              controller: editController,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: addPressed, child: Text('Add')),
          SizedBox(height: 20),
          Text('Entries',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 10),
          for (var e in allItems) Text(e.value),
        ],
      ),
    );
  }
}

class _DatabaseSample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DatabaseSampleState();
}
