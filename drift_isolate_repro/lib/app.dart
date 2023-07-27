import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database.dart';

class ProviderWrapper extends StatelessWidget {
  final Widget child;

  const ProviderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => Database(),
      dispose: (_, database) => database.close(),
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: DatabaseUser(),
      ),
    );
  }
}

class DatabaseUser extends StatefulWidget {
  const DatabaseUser({super.key});

  @override
  State<DatabaseUser> createState() => DatabaseUserState();
}

class DatabaseUserState extends State<DatabaseUser> {
  Future<void>? _operation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: FutureBuilder(
        future: _operation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('error ${snapshot.error}');
            } else {
              return const Text('done');
            }
          } else {
            return const Text('not started yet');
          }
        },
      ),
      onTap: () {
        setState(() {
          _operation ??=
              Provider.of<Database>(context, listen: false).testQuery();
        });
      },
    );
  }
}
