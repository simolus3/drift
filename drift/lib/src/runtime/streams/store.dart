import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../database/connection_user.dart';
import 'update_rules.dart';

const _listEquality = ListEquality<Object?>();

/// Defines interfaces for running streams that refresh on table updates, as
/// well as dispatching table updates.
abstract interface class StreamQueryStore {
  /// Creates a new stream from a select statement expressed through [fetcher].
  Stream<T> registerStream<T extends Object>(
      QueryStreamFetcher<T> fetcher, DatabaseConnectionUser database);

  /// Creates a stream that emits updates synchronously if they match [query].
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query);

  /// Handles updates on a given table by re-executing all queries that read
  /// from that table.
  void handleTableUpdates(Set<TableUpdate> updates);

  /// Closes this instance.
  ///
  /// This will also end all streams registered with [registerStream].
  Future<void> close();
}

/// Representation of a select statement that knows from which tables the
/// statement is reading its data and how to execute the query.
@internal
class QueryStreamFetcher<Rows extends Object> {
  /// Table updates that will affect this stream.
  ///
  /// If any of these tables changes, the stream must fetch its data again.
  final TableUpdateQuery readsFrom;

  /// Key that can be used to check whether two fetchers will yield the same
  /// result when operating on the same data.
  ///
  /// When not null, [Rows] must be `List<Map<String, Object?>>` (the most
  /// common form used for all queries except for manager queries with
  /// prefetches).
  final StreamKey? key;

  /// Function that asynchronously fetches the latest set of data.
  final Future<Rows> Function() fetchData;

  QueryStreamFetcher({
    required this.readsFrom,
    this.key,
    required this.fetchData,
  });
}

/// Key that uniquely identifies a select statement. If two keys created from
/// two select statements are equal, the statements are equal as well.
///
/// As two equal statements always yield the same result when operating on the
/// same data, this can make streams more efficient as we can return the same
/// stream for two equivalent queries.
@internal
final class StreamKey {
  final String sql;
  final List<dynamic> variables;

  StreamKey(this.sql, this.variables);

  @override
  int get hashCode {
    return Object.hash(sql, _listEquality.hash(variables));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StreamKey &&
            other.sql == sql &&
            _listEquality.equals(other.variables, variables));
  }
}
