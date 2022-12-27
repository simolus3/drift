import 'dart:typed_data';

import 'converter.dart';
import 'custom_tables.dart';

class NoIdRow {
  final List<int> payload;

  NoIdRow(this.payload);
}

class Buffer {
  Buffer(TypedData payload);
}

/// The existing result class for the `customResult` query in `tables.drift`
class MyCustomResultClass {
  // with_constraints.b
  final int b;

  // config.sync_state
  final SyncType? syncState;

  // config.** (drift-generated table row class)
  final Config config;

  // no_ids.** (custom table row class)
  final NoIdRow noIds;

  // LIST(SELECT * FROM no_ids). Note that we're replacing the custom table
  // row class with a custom structure class just for this query.
  final List<Buffer> nested;

  MyCustomResultClass(
    this.b, {
    required this.syncState,
    required this.config,
    required this.noIds,
    required this.nested,
  });
}
