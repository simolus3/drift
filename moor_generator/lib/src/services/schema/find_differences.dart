import 'package:moor_generator/src/analyzer/moor/moor_ffi_extension.dart';
import 'package:sqlparser/sqlparser.dart';
// ignore: implementation_imports
import 'package:sqlparser/src/utils/ast_equality.dart';

class Input {
  final String name;

  final String create;

  Input(this.name, this.create);
}

enum Kind { table, $index, trigger }

class FindSchemaDifferences {
  /// The expected schema entities
  final List<Input> referenceSchema;

  /// The actual schema entities
  final List<Input> actualSchema;

  /// When set, [actualSchema] may not contain more entities than
  /// [referenceSchema].
  final bool validateDropped;

  final SqlEngine _engine = SqlEngine(
    EngineOptions(enabledExtensions: const [
      MoorFfiExtension(),
      Json1Extension(),
      Fts5Extension(),
    ]),
  );

  FindSchemaDifferences(
      this.referenceSchema, this.actualSchema, this.validateDropped);

  CompareResult compare() {
    final results = <String, CompareResult>{};

    final referenceByName = {
      for (final ref in referenceSchema) ref.name: ref,
    };
    final actualByName = {
      for (final ref in actualSchema) ref.name: ref,
    };

    final referenceToActual = <Input, Input>{};

    // Handle the easy cases first: Is the actual schema missing anything?
    for (final inReference in referenceByName.keys) {
      if (!actualByName.containsKey(inReference)) {
        results['comparing $inReference'] = FoundDifference('Expected entity, '
            'but the actual schema does not contain anything with this name.');
      } else {
        referenceToActual[referenceByName[inReference]] =
            actualByName[inReference];
      }
    }

    if (validateDropped) {
      // Also check the other way: Does the actual schema contain more than the
      // reference?
      final additional = actualByName.keys.toSet()
        ..removeAll(referenceByName.keys);

      if (additional.isNotEmpty) {
        results['additional entries'] = FoundDifference('The schema contains '
            'the following unexpected entries: ${additional.join(', ')}');
      }
    }

    for (final match in referenceToActual.entries) {
      final name = match.key.name;
      results[name] = _compare(match.key, match.value);
    }

    return MultiResult(results);
  }

  CompareResult _compare(Input reference, Input actual) {
    final parsedReference = _engine.parse(reference.create);
    final parsedActual = _engine.parse(actual.create);

    if (parsedReference.errors.isNotEmpty) {
      return FoundDifference(
          'Internal error: Could not parse ${reference.create}');
    } else if (parsedActual.errors.isNotEmpty) {
      return FoundDifference(
          'Internal error: Could not parse ${actual.create}');
    }

    final referenceStmt = parsedReference.rootNode;
    final actualStmt = parsedActual.rootNode;

    if (referenceStmt.runtimeType != actualStmt.runtimeType) {
      return FoundDifference('Expected a ${_kindOf(referenceStmt)}, but '
          'got a ${_kindOf(actualStmt)}.');
    }

    // We have a special comparison for tables that ignores the order of column
    // declarations and so on.
    if (referenceStmt is CreateTableStatement) {
      return _compareTables(referenceStmt, actualStmt as CreateTableStatement);
    }

    return _compareByAst(referenceStmt, actualStmt);
  }

  CompareResult _compareTables(
      CreateTableStatement ref, CreateTableStatement act) {
    final results = <String, CompareResult>{};

    if (ref.withoutRowId != act.withoutRowId) {
      final expectedWithout = ref.withoutRowId;
      results['rowid'] = FoundDifference(expectedWithout
          ? 'Expected the table to have a WITHOUT ROWID clause'
          : 'Did not expect the table to have a WITHOUT ROWID clause.');
    }

    return const Success();
  }

  CompareResult _compareByAst(AstNode a, AstNode b) {
    try {
      enforceEqual(a, b);
      return const Success();
    } catch (e) {
      return FoundDifference(
          'Not equal: `${a.span.text}` and `${b.span.text}`');
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

abstract class CompareResult {
  const CompareResult();

  bool get noChanges;

  String describe(int indent);
}

class Success extends CompareResult {
  const Success();

  @override
  bool get noChanges => true;

  @override
  String describe(int indent) => '${' ' * indent}matches schema ✓';
}

class FoundDifference extends CompareResult {
  final String description;

  FoundDifference(this.description);

  @override
  bool get noChanges => false;

  @override
  String describe(int indent) => ' ' * indent + description;
}

class MultiResult extends CompareResult {
  final Map<String, CompareResult> nestedResults;

  MultiResult(this.nestedResults);

  @override
  bool get noChanges => nestedResults.values.every((e) => e.noChanges);

  @override
  String describe(int indent) {
    final buffer = StringBuffer();
    final indentStr = ' ' * indent;

    for (final result in nestedResults.entries) {
      buffer
        ..writeln('$indentStr${result.key}:')
        ..writeln(result.value.describe(indent + 1));
    }

    return buffer.toString();
  }
}
