import 'package:drift/drift.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';

import '../remote_database.dart';

class DatabaseViewer extends StatefulWidget {
  final RemoteDatabase database;

  const DatabaseViewer({super.key, required this.database});

  @override
  State<DatabaseViewer> createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  late final GeneratedDatabase wrapper;

  @override
  void initState() {
    wrapper = RemoteDatabaseAsDatabase(widget.database);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DriftDbViewer(wrapper);
  }
}
