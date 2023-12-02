import 'package:db_viewer/db_viewer.dart';
import 'package:flutter/material.dart';

import '../remote_database.dart';
import 'database.dart';

class DatabaseViewer extends StatefulWidget {
  final RemoteDatabase database;

  const DatabaseViewer({super.key, required this.database});

  @override
  State<DatabaseViewer> createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  @override
  void initState() {
    DbViewerDatabase.initDb(ViewerDatabase(database: widget.database));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const DbViewerNavigator();
  }
}
