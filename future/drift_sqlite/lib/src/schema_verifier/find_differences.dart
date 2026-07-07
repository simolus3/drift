@internal
library;

import 'package:drift3/drift.dart' as drift;
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlparser/sqlparser.dart';
// ignore: implementation_imports
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../dialect/dialect.dart';
import 'common.dart';

/// An SQL element as part of the database schema.
final class SyntacticSchemaElement {
  /// the name of this table, view, index or trigger.
  final String name;

  /// The `CREATE` statement backing this schema element.
  final String create;

  /// @nodoc
  SyntacticSchemaElement({required this.name, required this.create});
}

/// A collection of [SyntacticSchemaElement]s.
extension type SyntacticSchema(List<SyntacticSchemaElement> elements)
    implements List<SyntacticSchemaElement> {
  /// Reads the schema from a database connection.
  factory SyntacticSchema.readFromDatabase(CommonDatabase db) {
    final rows = db.select(_query);
    final elements = <SyntacticSchemaElement>[
      for (final row in rows)
        SyntacticSchemaElement(
          name: row.columnAt(0) as String,
          create: row.columnAt(1) as String,
        ),
    ];

    return SyntacticSchema(elements);
  }

  /// Reads the schema from an opened drift connection.
  static Future<SyntacticSchema> readFromDrift(
    drift.DriftSession session,
  ) async {
    final result = await session.execute(
      drift.StatementInfo(_query, needsResultSet: true),
    );
    final rows = result.resultSet!;

    return SyntacticSchema([
      for (final [name as String, sql as String] in rows)
        SyntacticSchemaElement(name: name, create: sql),
    ]);
  }

  /// Extracts a schema from values declared in a drift database.
  static SyntacticSchema fromDeclaredDriftSchema(
    drift.DatabaseSchema schema, {
    drift.DriftDialect? dialect,
  }) {
    final resolvedDialect = dialect ?? const SqliteDialect();
    final found = <SyntacticSchemaElement>[];

    for (final element in schema) {
      final stmt = drift.CreateStatement.creatingElement(element);
      final sql = resolvedDialect.compile(stmt);

      assert(sql.variables.isEmpty);
      found.add(
        SyntacticSchemaElement(name: element.entityName, create: sql.sql),
      );
    }

    return SyntacticSchema(found);
  }

  /// Compares elements in this schema to the other.
  CompareResult compareTo({
    required SyntacticSchema expected,
    ValidationOptions options = const ValidationOptions(),
  }) {
    return _FindSchemaDifferences(expected, this, options).compare();
  }

  // Query all schema elements except for shadow tables.
  // This also filters out an Android-specific table present when using native
  // Android APIs: https://github.com/simolus3/drift/discussions/2042.
  static const _query = '''
SELECT s.name, s.sql
FROM sqlite_schema s
  LEFT OUTER JOIN pragma_table_list(s.name) info
WHERE (s.type != 'table' or info.type != 'shadow')
  AND s.sql IS NOT NULL
  AND s.name != 'android_metadata'
''';
}

final class _FindSchemaDifferences {
  final SyntacticSchema referenceSchema;
  final SyntacticSchema actualSchema;

  /// Validation options.
  final ValidationOptions options;

  final SqlEngine _engine = SqlEngine(
    EngineOptions(
      version: .current,
      enabledExtensions: const [Json1Extension(), Fts5Extension()],
    ),
  );

  _FindSchemaDifferences(this.referenceSchema, this.actualSchema, this.options);

  CompareResult compare() {
    return _compareNamed<SyntacticSchemaElement>(
      reference: referenceSchema.elements,
      actual: actualSchema.elements,
      name: (e) => e.name,
      compare: _compareElement,
      validateActualInReference: options.validateDropped,
    );
  }

  CompareResult _compareNamed<T extends Object>({
    required List<T> reference,
    required List<T> actual,
    required String Function(T) name,
    required CompareResult Function(T, T) compare,
    bool validateActualInReference = true,
  }) {
    final results = <String, CompareResult>{};
    final referenceByName = {for (final ref in reference) name(ref): ref};
    final actualByName = {for (final ref in actual) name(ref): ref};

    final referenceToActual = <T, T>{};

    for (final inReference in referenceByName.keys) {
      if (!actualByName.containsKey(inReference)) {
        results['comparing $inReference'] = _FoundDifference(
          'The actual schema does not contain anything with this name.',
        );
      } else {
        referenceToActual[referenceByName[inReference]!] =
            actualByName[inReference]!;
      }
    }

    if (validateActualInReference) {
      // Also check the other way: Does the actual schema contain more than the
      // reference?
      final additional = actualByName.keys.toSet()
        ..removeAll(referenceByName.keys);

      if (additional.isNotEmpty) {
        results['additional'] = _FoundDifference(
          'Contains the following '
          'unexpected entries: ${additional.join(', ')}',
        );
      }
    }

    for (final match in referenceToActual.entries) {
      results[name(match.key)] = compare(match.key, match.value);
    }

    return _MultiResult(results);
  }

  CompareResult _compareElement(
    SyntacticSchemaElement reference,
    SyntacticSchemaElement actual,
  ) {
    final parsedReference = _engine.parse(
      ParserEntrypoint.statement,
      reference.create,
    );
    final parsedActual = _engine.parse(
      ParserEntrypoint.statement,
      actual.create,
    );

    if (parsedReference.errors.isNotEmpty) {
      return _FoundDifference(
        'Internal error: Could not parse ${reference.create}',
      );
    } else if (parsedActual.errors.isNotEmpty) {
      return _FoundDifference(
        'Internal error: Could not parse ${actual.create}',
      );
    }

    final referenceStmt = parsedReference.rootNode;
    final actualStmt = parsedActual.rootNode;

    if (referenceStmt.runtimeType != actualStmt.runtimeType) {
      return _FoundDifference(
        'Expected a ${_kindOf(referenceStmt)}, but '
        'got a ${_kindOf(actualStmt)}.',
      );
    }

    // We have a special comparison for tables that ignores the order of column
    // declarations and so on.
    if (referenceStmt is CreateTableStatement) {
      return _compareTables(referenceStmt, actualStmt as CreateTableStatement);
    }

    return _compareByAst(referenceStmt, actualStmt);
  }

  CompareResult _compareTables(
    CreateTableStatement ref,
    CreateTableStatement act,
  ) {
    final results = <String, CompareResult>{};

    results['columns'] = _compareColumns(ref.columns, act.columns);

    // We're currently comparing table constraints by their exact order.
    if (ref.tableConstraints.length != act.tableConstraints.length) {
      results['constraints'] = _FoundDifference(
        'Expected the table to have ${ref.tableConstraints.length} table '
        'constraints, it actually has ${act.tableConstraints.length}.',
      );
    } else {
      for (var i = 0; i < ref.tableConstraints.length; i++) {
        final refConstraint = ref.tableConstraints[i];
        final actConstraint = act.tableConstraints[i];

        results['constraints_$i'] = _compareByAst(refConstraint, actConstraint);
      }
    }

    if (ref.withoutRowId != act.withoutRowId) {
      final expectedWithout = ref.withoutRowId;
      results['rowid'] = _FoundDifference(
        expectedWithout
            ? 'Expected the table to have a WITHOUT ROWID clause'
            : 'Did not expect the table to have a WITHOUT ROWID clause.',
      );
    }

    return _MultiResult(results);
  }

  CompareResult _compareColumns(
    List<ColumnDefinition> ref,
    List<ColumnDefinition> act,
  ) {
    return _compareNamed<ColumnDefinition>(
      reference: ref,
      actual: act,
      name: (def) => def.columnName,
      compare: _compareColumn,
    );
  }

  CompareResult _compareColumn(ColumnDefinition ref, ColumnDefinition act) {
    final refType = _engine.schemaReader.resolveColumnType(ref.typeName);
    final actType = _engine.schemaReader.resolveColumnType(act.typeName);

    if (refType != actType) {
      return _FoundDifference(
        'Different types: Expected ${ref.typeName}, got ${act.typeName}',
      );
    }

    if (options.validateColumnConstraints) {
      try {
        enforceEqualIterable(ref.constraints, act.constraints);
      } catch (e) {
        final firstSpan = ref.constraints.spanOrNull?.text ?? '';
        final secondSpan = act.constraints.spanOrNull?.text ?? '';
        return _FoundDifference(
          'Not equal: `$firstSpan` (expected) and `$secondSpan` (actual)',
        );
      }
    }

    return const _Success();
  }

  CompareResult _compareByAst(AstNode reference, AstNode actual) {
    try {
      enforceEqual(reference, actual);
      return const _Success();
    } catch (e) {
      return _FoundDifference(
        'Not equal: Expected `${reference.span?.text}`, '
        'got `${actual.span?.text}`',
      );
    }
  }

  String _kindOf(AstNode node) {
    if (node is CreateVirtualTableStatement) {
      return 'virtual table';
    } else if (node is CreateTableStatement) {
      return 'table';
    } else if (node is CreateViewStatement) {
      return 'view';
    } else if (node is CreateTriggerStatement) {
      return 'trigger';
    } else if (node is CreateIndexStatement) {
      return 'index';
    } else {
      return '<unknown>';
    }
  }
}

/// The result of comparing two schema instances.
sealed class CompareResult {
  const CompareResult();

  /// Whether the compared schemas are equal.
  bool get areEqual;

  /// Emits a human-readable descriptions of schema differences to aid in
  /// debugging.
  String describe() => _describe(0);
  String _describe(int indent);
}

final class _Success extends CompareResult {
  const _Success();

  @override
  bool get areEqual => true;

  @override
  String _describe(int indent) => '${' ' * indent}matches schema ✓';
}

final class _FoundDifference extends CompareResult {
  final String description;

  _FoundDifference(this.description);

  @override
  bool get areEqual => false;

  @override
  String _describe(int indent) => ' ' * indent + description;
}

final class _MultiResult extends CompareResult {
  final Map<String, CompareResult> nestedResults;

  _MultiResult(this.nestedResults);

  @override
  bool get areEqual => nestedResults.values.every((e) => e.areEqual);

  @override
  String _describe(int indent) {
    final buffer = StringBuffer();
    final indentStr = ' ' * indent;

    for (final result in nestedResults.entries) {
      if (result.value.areEqual) continue;

      buffer
        ..writeln('$indentStr${result.key}:')
        ..writeln(result.value._describe(indent + 1));
    }

    return buffer.toString();
  }
}
