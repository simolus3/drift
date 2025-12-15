import 'package:meta/meta.dart';

import '../../query_builder/schema/result_set.dart';
import '../../query_builder/schema/table.dart';
import '../../query_builder/schema/view.dart';

/// Collects a set of [UpdateRule]s which can be used to express how a set of
/// direct updates to a table affects other updates.
///
/// This is used to implement query streams in databases that have triggers.
final class StreamQueryUpdateRules {
  /// All rules active in a database.
  final List<UpdateRule> rules;

  /// Creates a [StreamQueryUpdateRules] from the underlying [rules].
  const StreamQueryUpdateRules(this.rules);

  /// The default implementation, which doesn't have any rules.
  const StreamQueryUpdateRules.none() : this(const []);

  /// Obtain a set of all tables that might be affected by direct updates in
  /// [input].
  Set<TableUpdate> apply(Iterable<TableUpdate> input) {
    // Most users don't have any update rules, and this check is much faster
    // than crawling through all updates.
    if (rules.isEmpty) return input.toSet();

    final pending = List.of(input);
    final seen = <TableUpdate>{};
    while (pending.isNotEmpty) {
      final update = pending.removeLast();
      seen.add(update);

      for (final rule in rules) {
        if (rule is WritePropagation && rule.on.matches(update)) {
          pending.addAll(rule.result.where((u) => !seen.contains(u)));
        }
      }
    }

    return seen;
  }
}

/// A common rule that describes how a [TableUpdate] has other [TableUpdate]s.
sealed class UpdateRule {
  /// Common const constructor so that subclasses can be const.
  const UpdateRule._();
}

/// An [UpdateRule] for triggers that exist in a database.
///
/// An update on [on] implicitly triggers updates on [result].
///
/// This class is for use by generated or drift-internal code only. It does not
/// adhere to Semantic Versioning and should not be used manually.
final class WritePropagation extends UpdateRule {
  /// The updates that cause further writes in [result].
  final TableUpdateQuery on;

  /// All updates that will be performed by the trigger listening on [on].
  final List<TableUpdate> result;

  /// Default constructor. See [WritePropagation] for details.
  const WritePropagation({required this.on, required this.result}) : super._();
}

/// Classifies a [TableUpdate] by what kind of write happened - an insert, an
/// update or a delete operation.
///
/// This information is used by drift to determine which triggers might be
/// invoked by the write. For instance, an `AFTER UPDATE ON table` trigger would
/// only be considered for [UpdateKind.update].
enum UpdateKind {
  /// An insert statement ran on the affected table.
  ///
  /// This will also be used for upserts.
  insert,

  /// An update statement ran on the affected table.
  update,

  /// A delete statement ran on the affected table.
  delete,
}

/// Contains information on how a table was updated, which can be used to find
/// queries that are affected by this.
final class TableUpdate {
  /// What kind of update was applied to the [table].
  ///
  /// Can be null, which indicates that the update is not known.
  final UpdateKind? kind;

  /// Name of the table that was updated.
  final String table;

  /// Default constant constructor.
  const TableUpdate(this.table, {this.kind});

  /// Creates a [TableUpdate] instance based on a [GeneratedTable] instead of
  /// the raw name.
  factory TableUpdate.onTable(GeneratedTable table, {UpdateKind? kind}) {
    return TableUpdate(table.entityName, kind: kind);
  }

  @override
  int get hashCode => Object.hash(kind, table);

  @override
  bool operator ==(Object other) {
    return other is TableUpdate && other.kind == kind && other.table == table;
  }

  @override
  String toString() {
    return 'TableUpdate($table, kind: $kind)';
  }
}

/// A table update query describes information to listen for [TableUpdate]s.
///
/// Users should not extend implement this class.
sealed class TableUpdateQuery {
  /// Default const constructor so that subclasses can have constant
  /// constructors.
  const TableUpdateQuery();

  /// A query that listens for all table updates in a database.
  const factory TableUpdateQuery.any() = AnyUpdateQuery;

  /// A query that listens for all updates that match any query in [queries].
  const factory TableUpdateQuery.allOf(List<TableUpdateQuery> queries) =
      MultipleUpdateQuery;

  /// A query that listens for all updates on a specific [table] by its name.
  ///
  /// The optional [limitUpdateKind] parameter can be used to limit the updates
  /// to a certain kind.
  const factory TableUpdateQuery.onTableName(
    String table, {
    UpdateKind? limitUpdateKind,
  }) = SpecificUpdateQuery;

  /// A query that listens for all updates on a specific [table].
  ///
  /// The optional [limitUpdateKind] parameter can be used to limit the updates
  /// to a certain kind.
  factory TableUpdateQuery.onTable(
    ResultSet table, {
    UpdateKind? limitUpdateKind,
  }) {
    if (table is GeneratedView) {
      return TableUpdateQuery.allOf([
        for (final table in /*table.readTables*/ const <String>[])
          TableUpdateQuery.onTableName(table),
      ]);
    }

    return TableUpdateQuery.onTableName(
      table.entityName,
      limitUpdateKind: limitUpdateKind,
    );
  }

  /// A query that listens for any change on any table in [tables].
  factory TableUpdateQuery.onAllTables(Iterable<ResultSet> tables) {
    return TableUpdateQuery.allOf([
      for (final table in tables)
        if (table is GeneratedView)
          for (final table in table.readsFrom)
            TableUpdateQuery.onTableName(table)
        else
          TableUpdateQuery.onTable(table),
    ]);
  }

  /// Determines whether the [update] would be picked up by this query.
  bool matches(TableUpdate update);
}

@internal
final class AnyUpdateQuery extends TableUpdateQuery {
  const AnyUpdateQuery();

  @override
  bool matches(TableUpdate update) => true;
}

@internal
final class MultipleUpdateQuery extends TableUpdateQuery {
  final List<TableUpdateQuery> queries;

  const MultipleUpdateQuery(this.queries);

  @override
  bool matches(TableUpdate update) => queries.any((q) => q.matches(update));
}

@internal
final class SpecificUpdateQuery extends TableUpdateQuery {
  final UpdateKind? limitUpdateKind;
  final String table;

  const SpecificUpdateQuery(this.table, {this.limitUpdateKind});

  @override
  bool matches(TableUpdate update) {
    if (update.table != table) return false;

    return update.kind == null ||
        limitUpdateKind == null ||
        update.kind == limitUpdateKind;
  }

  @override
  int get hashCode => Object.hash(limitUpdateKind, table);

  @override
  bool operator ==(Object other) {
    return other is SpecificUpdateQuery &&
        other.limitUpdateKind == limitUpdateKind &&
        other.table == table;
  }
}
