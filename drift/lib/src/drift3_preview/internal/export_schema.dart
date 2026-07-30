import 'dart:convert';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../drift.dart';

/// Generates `CREATE` statements for the given [database] for all [dialects]
/// and sends generated statements through the send [port].
///
/// Each statement will be encoded as a `[index, name, sql]` list, where `index`
/// is the index in [dialects], `name` is the [DatabaseSchemaEntity.entityName]
/// and `sql` is the compiled [StatementInfo.sql] statement.
/// A list of these structures is then sent through the port.
///
/// This sequence is used by the `drift_dev schema export` command, which
/// prints `CREATE` statements making up a drift database analyzed from
/// source. For this to work, it emulates a drift build and then creates a
/// Dart program calling this method.
///
/// This method is thus internal to that utility and likely not useful outside
/// of that.
@internal
void sendCreateStatements(
  List<String> args,
  SendPort port,
  GeneratedDatabase Function(DriftConnection) database,
  List<DriftDialectFactory> dialects,
) {
  final statements = <DriftDialect, List<_CollectedStatement>>{};

  for (final dialectFactory in dialects) {
    final opened = database(
      DriftConnection(
        dialect: dialectFactory,
        openConnection: () => Future.error(UnsupportedError('Stub connection')),
      ),
    );
    final dialect = opened.dialect;
    final statementsForDialect = <_CollectedStatement>[];

    for (final entity in opened.schema) {
      StatementInfo compiled;

      switch (entity) {
        case Trigger():
        case Index():
        case SchemaEntityWithResultSet<Object, ResultSet<Object, dynamic>>():
          compiled = dialect.compile(CreateStatement.creatingElement(entity));
        case OnCreateQuery(:final definition):
          compiled = dialect.compile(definition);
      }

      statementsForDialect.add(
        _CollectedStatement(entity.entityName, compiled.sql),
      );
    }

    statements[dialect] = statementsForDialect;
  }

  List<_CollectedStatement> statementsForDialect(String dialectName) {
    final dialect = KnownSqlDialect.values.byName(dialectName);
    final entry = statements.entries.firstWhereOrNull(
      (e) => e.key.known == dialect,
    );

    if (entry == null) {
      throw ArgumentError(
        'Dialect ${dialect.name} is not registered on this database',
      );
    }

    return entry.value;
  }

  if (args case ['v2', final options]) {
    final parsedOptions = json.decode(options);
    final dialectNames = (parsedOptions['dialects'] as List).cast<String>();
    final encodedStatements = <List>[];

    for (final name in dialectNames) {
      encodedStatements.addAll(
        statementsForDialect(name).map((e) => [e.element, name, e.stmt]),
      );
    }

    port.send(encodedStatements);
  } else {
    port.send([
      for (final stmt in statementsForDialect(args.single)) stmt.stmt,
    ]);
  }
}

final class _CollectedStatement {
  final String element;
  final String stmt;

  _CollectedStatement(this.element, this.stmt);
}
