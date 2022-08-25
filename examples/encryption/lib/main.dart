import 'dart:ffi';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'database.dart';

void main() {
  open
    ..overrideFor(OperatingSystem.android, openCipherOnAndroid)
    ..overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'))
    ..overrideFor(
        OperatingSystem.windows, () => DynamicLibrary.open('sqlcipher.dll'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encrypted drift application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _database = MyEncryptedDatabase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted drift example'),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _database.notes.select().watch(),
        builder: (context, state) {
          if (state.hasError) {
            debugPrintStack(
              label: state.error.toString(),
              stackTrace: state.stackTrace,
            );
          }

          if (!state.hasData) {
            return const Align(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: [
              for (final entry in state.data!)
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _AddEntryDialog(database: _database),
          );
        },
      ),
    );
  }
}

class _AddEntryDialog extends StatefulWidget {
  // You should really use a proper package like riverpod or get_it to pass the
  // database around, but tiny example only wants to show how to use encryption.
  final MyEncryptedDatabase database;

  const _AddEntryDialog({Key? key, required this.database}) : super(key: key);

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add new entry'),
      content: TextField(controller: _controller),
      actions: [
        TextButton(
          onPressed: () {
            widget.database.notes
                .insertOne(NotesCompanion.insert(content: _controller.text));
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
