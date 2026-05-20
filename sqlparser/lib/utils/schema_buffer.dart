/// Provides [SchemaBuffer], a utility to patch `CREATE` statements with
/// [AlterTableStatement]s.
///
/// {@template sqlparser/utils/schema_buffer_example}
///
///  ### Example
///
/// This Dart program will parse a number of schema-altering statements and
/// print the resulting schema (as a single `CREATE TABLE` statement) in the
/// end.
///
/// ```dart
/// import 'package:source_span/source_span.dart';
/// import 'package:sqlparser/sqlparser.dart';
/// import 'package:sqlparser/utils/schema_buffer.dart';

/// void main() {
///   final engine = SqlEngine();
///   final buffer = SchemaBuffer();
///
///   // Parse a list of statements to apply to the schema.
///   final parseResults =
///       engine.parseMultiple(SourceFile.fromString(statements).span(0));
///   if (parseResults.errors.isNotEmpty) {
///     throw ArgumentError('Syntax error in statements: ${parseResults.errors}');
///   }

///   // Apply to schema
///   for (final statement in parseResults.rootNode.childNodes) {
///     final schemaErrors = buffer.process(statement as Statement);
///     if (schemaErrors.isNotEmpty) {
///       throw ArgumentError(schemaErrors.join(', '));
///     }
///   }

///   // Print results. Note that this preserves the formatting of the original
///   // CREATE TABLE statements
///   for (final stmt in buffer.definitions.values) {
///     print(stmt);
///   }
/// }
///
/// const statements = '''
/// CREATE TABLE users (
///   id INTEGER NOT NULL PRIMARY KEY,
///   name TEXT NOT NULL
/// ) STRICT;
///
/// CREATE TABLE "groups" (
///   name TEXT NOT NULL
/// );
///
/// ALTER TABLE users RENAME TO accounts;
/// DROP TABLE "groups";
/// ALTER TABLE accounts ADD COLUMN birthdate TEXT;
/// ALTER TABLE accounts RENAME COLUMN name TO username;
/// ''';
/// ```
///
/// {@endtemplate}
library;

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/utils/case_insensitive_map.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../src/ast/ast.dart';
import '../src/reader/syntactic_entity.dart';
import '../src/analysis/analysis.dart';

/// Utility to infer a schema across multiple `CREATE`, `DROP` and `ALTER TABLE`
/// statements.
///
/// On a schema buffer, call [process] with the parsed statement to apply to the
/// schema tracked on it. After adding all statements, [definitions] returns
/// the transformed `CREATE` statement for each element.
///
/// {@macro sqlparser/utils/schema_buffer_example}
final class SchemaBuffer {
  final Map<String, _SchemaElement> _currentElements = CaseInsensitiveMap();

  /// An iterable of all schema elements currently tracked, mapping from their
  /// name to their `CREATE` statement.
  Map<String, String> get definitions {
    return {
      for (final element in _currentElements.entries)
        element.key: element.value.toString(),
    };
  }

  /// Interpret the schema against the schema managed in this buffer.
  ///
  /// `CREATE` statements will add new elements, `DROP` statements will remove
  /// them. `ALTER TABLE` statements are handled by patching the existing
  /// `CREATE TABLE` statement affected by it.
  ///
  /// Returns analysis errors if the statement can't be applied (e.g. because
  /// it attempts to create a table that already exists).
  List<AnalysisError> process(Statement statement) {
    final errors = <AnalysisError>[];

    switch (statement) {
      case final AlterTableStatement alterTable:
        if (_currentElements[alterTable.table.tableName]
            case final _TableSchemaElement table?) {
          _applyAlterTable(errors, statement, alterTable.instruction, table);
        } else {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.referencedUnknownTable,
              relevantNode: alterTable.table,
            ),
          );
        }

      case final CreateTableStatement createTable:
        _defineNew(errors, DropType.table, createTable);
      case final CreateTriggerStatement createTrigger:
        _defineNew(errors, DropType.trigger, createTrigger);
      case final CreateIndexStatement createIndex:
        _defineNew(errors, DropType.$index, createIndex);
      case final CreateViewStatement createView:
        _defineNew(errors, DropType.view, createView);
      case final DropStatement drop:
        _drop(errors, drop);
      default:
      // Not a statement affecting the schema, ignore.
    }

    return errors;
  }

  void _defineNew(
    List<AnalysisError> errors,
    DropType type,
    CreatingStatement statement,
  ) {
    if (_currentElements[statement.createdName] case final existingElement?) {
      if (existingElement.type != type) {
        errors.add(
          AnalysisError(
            type: AnalysisErrorType.other,
            message:
                'A schema element of a different type with that name already '
                'exists',
            relevantNode: statement,
          ),
        );
      } else if (!statement.ifNotExists) {
        errors.add(
          AnalysisError(
            type: AnalysisErrorType.other,
            message: 'Already exists',
            relevantNode: statement,
          ),
        );
      }
    }

    _currentElements[statement.createdName] = switch (statement) {
      CreateTableStatement() => _TableSchemaElement(statement),
      _ => _OtherSchemaElement(type, statement.span!),
    };
  }

  void _drop(List<AnalysisError> errors, DropStatement statement) {
    if (_currentElements.remove(statement.elementName)
        case final droppedElement?) {
      if (droppedElement.type != statement.type) {
        errors.add(
          AnalysisError(
            type: AnalysisErrorType.other,
            message: 'Wrong type, is ${droppedElement.type.name}',
            relevantNode: statement.typeToken ?? statement,
          ),
        );
      }
    } else if (!statement.ifExists) {
      errors.add(
        AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Entity to drop does not exist.',
          relevantNode: statement,
        ),
      );
    }
  }

  void _applyAlterTable(
    List<AnalysisError> errors,
    AstNode statement,
    AlterTableInstruction instruction,
    _TableSchemaElement element,
  ) {
    switch (instruction) {
      case RenameTo(:final newTableName):
        if (_currentElements.containsKey(newTableName)) {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.other,
              message: 'Table with that name already exists',
              relevantNode: instruction.newTableNameToken ?? instruction,
            ),
          );
        } else {
          _currentElements.remove(element.lowercaseName);

          element.name.lexeme = instruction.newTableNameToken!.lexeme;
          element.lowercaseName = newTableName.toLowerCase();
          _currentElements[element.lowercaseName] = element;
        }
      case RenameColumnTo():
        final oldName = instruction.oldName.columnName.toLowerCase();
        final newName = instruction.newName.toLowerCase();
        if (element.findColumn(newName) != null) {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.other,
              message: 'Column with that name already exists',
              relevantNode: instruction.newNameToken ?? instruction,
            ),
          );
        }

        if (element.findColumn(oldName) case final old?) {
          old.lowercaseName = newName;
          old.nameLexeme.lexeme = instruction.newNameToken!.lexeme;
        } else {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.referencedUnknownColumn,
              relevantNode: instruction.oldName,
            ),
          );
        }
      case AddColumn(:final definition):
        if (element.findColumn(definition.columnName.toLowerCase()) != null) {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.other,
              message: 'Column with that name already exists',
              relevantNode: definition,
            ),
          );
        }

        element.addColumn(statement, definition);
      case DropColumn(:final column):
        if (element.findColumn(column.columnName.toLowerCase())
            case final column?) {
          element.dropColumn(column);

          if (element._columns.isEmpty) {
            errors.add(
              AnalysisError(
                type: AnalysisErrorType.other,
                relevantNode: instruction,
                message: "Can't delete only remaining column in table",
              ),
            );
          }
        } else {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.referencedUnknownColumn,
              relevantNode: column,
            ),
          );
        }
      case AlterColumn(:final columnName, instruction: final inner):
        if (element.findColumn(columnName.toLowerCase()) case final column?) {
          switch (inner) {
            case AlterColumnSetNotNull(:final onConflict):
              column.setNotNull(onConflict);
            case AlterColumnDropNotNull():
              column.dropNotNull();
          }
        } else {
          errors.add(
            AnalysisError(
              type: AnalysisErrorType.referencedUnknownColumn,
              relevantNode: instruction.columnNameToken ?? instruction,
            ),
          );
        }
      case AddConstraint(checkTable: final checkTable):
        if (checkTable.name != null) {
          for (final tableConstraint in element._tableConstraints) {
            if (checkTable.name == tableConstraint.constraint.name) {
              errors.add(
                AnalysisError(
                  type: AnalysisErrorType.other,
                  relevantNode: instruction,
                  message: 'constraint ${checkTable.name} already exists',
                ),
              );
              return;
            }
          }

          for (final column in element._columns) {
            for (final columnConstraint in column.constraints) {
              if (checkTable.name == columnConstraint.constraint.name) {
                errors.add(
                  AnalysisError(
                    type: AnalysisErrorType.other,
                    relevantNode: instruction,
                    message: 'constraint ${checkTable.name} already exists',
                  ),
                );
                return;
              }
            }
          }
        }

        element.addConstraint(statement, checkTable);
      case DropConstraint(name: final name):
        for (final tableConstraint in element._tableConstraints) {
          if (name == tableConstraint.constraint.name) {
            if (tableConstraint.constraint is! CheckTable) {
              errors.add(
                AnalysisError(
                  type: AnalysisErrorType.other,
                  relevantNode: tableConstraint.constraint,
                  message: 'constraint may not be dropped: $name',
                ),
              );
              return;
            }
            element.dropConstraint(tableConstraint);
            return;
          }
        }

        for (final column in element._columns) {
          for (final columnConstraint in column.constraints) {
            if (name == columnConstraint.constraint.name) {
              if (columnConstraint.constraint is! CheckColumn &&
                  columnConstraint.constraint is! NotNull) {
                errors.add(
                  AnalysisError(
                    type: AnalysisErrorType.other,
                    relevantNode: columnConstraint.constraint,
                    message: 'constraint may not be dropped: $name',
                  ),
                );
                return;
              }
              column.dropConstraint(columnConstraint);
              return;
            }
          }
        }

        errors.add(
          AnalysisError(
            type: AnalysisErrorType.other,
            relevantNode: instruction,
            message: 'no such constraint: $name',
          ),
        );
    }
  }
}

sealed class _SchemaElement {
  DropType get type;
}

/// A non-virtual table in the schema.
///
/// Because tables can be altered, we track the source location of its name and
/// other elements.
final class _TableSchemaElement extends _SchemaElement {
  final CreateTableStatement originalStatement;
  final LinkedList<_SourceElement> _sources = LinkedList()
    ..add(_SourceElement(''));

  String lowercaseName;
  late _SourceElement name;
  final List<_ColumnDefinition> _columns = [];
  final List<_TableConstraint> _tableConstraints = [];

  _TableSchemaElement(this.originalStatement)
    : lowercaseName = originalStatement.createdName {
    // Create editable source elements for all names and column definitions in
    // the CREATE TABLE statement, since they can be changed by ALTER TABLE
    // statements.
    final text = originalStatement.span!.text;
    final startOffset = originalStatement.firstPosition;
    final fromText = _SourceFromText(text, startOffset, _sources.last);

    name = fromText
        .createElementFromSyntax(originalStatement.tableNameToken!)
        .$2;
    for (final (i, column) in originalStatement.columns.indexed) {
      final before = fromText.elementUntil(column.nameToken!.firstPosition);
      final columnDef = fromText._readColumnDefinition(
        i == 0 ? null : before,
        column,
      );

      _columns.add(columnDef);
    }

    for (final constraint in originalStatement.tableConstraints) {
      final before = fromText.elementUntil(constraint.firstPosition);
      final constraintDef = fromText._readTableConstraint(before, constraint);

      _tableConstraints.add(constraintDef);
    }

    // Add remaining text from the CREATE TABLE statement.
    fromText.elementUntil(text.length);
  }

  @override
  DropType get type => DropType.table;

  _ColumnDefinition? findColumn(String lowercaseName) {
    assert(lowercaseName.toLowerCase() == lowercaseName);

    return _columns.firstWhereOrNull((e) => e.lowercaseName == lowercaseName);
  }

  void addColumn(AstNode originalStatement, ColumnDefinition definition) {
    if (_columns.lastOrNull case final last?) {
      final precedingComma =
          last.precedingComma?.clone() ?? _SourceElement(', ');
      last.end.insertAfter(precedingComma);

      final text = originalStatement.span!.text;
      final startOffset = originalStatement.firstPosition;
      final fromText = _SourceFromText(text, startOffset, precedingComma);
      fromText.currentPosition = definition.firstPosition;

      _columns.add(fromText._readColumnDefinition(precedingComma, definition));
    } else {
      throw UnsupportedError('TODO: Adding column to empty table');
    }
  }

  void dropColumn(_ColumnDefinition definition) {
    definition.precedingComma?.unlink();
    definition.nameLexeme.unlink();
    definition.typeName?.unlink();
    for (final constraint in definition.constraints) {
      constraint.source.unlink();
    }

    _columns.remove(definition);
  }

  void addConstraint(AstNode originalStatement, CheckTable checkTable) {
    final _SourceElement precedingComma;

    if (_tableConstraints.lastOrNull case final lastConstraint?) {
      precedingComma =
          lastConstraint.precedingComma?.clone() ?? _SourceElement(', ');

      lastConstraint.source.insertAfter(precedingComma);
    } else if (_columns.lastOrNull case final lastColumn?) {
      precedingComma =
          lastColumn.precedingComma?.clone() ?? _SourceElement(', ');

      lastColumn.end.insertAfter(precedingComma);
    } else {
      throw UnsupportedError('TODO: Adding constraint to empty table');
    }

    final text = originalStatement.span!.text;
    final startOffset = originalStatement.firstPosition;
    final fromText = _SourceFromText(text, startOffset, precedingComma);
    fromText.currentPosition = checkTable.firstPosition;
    _tableConstraints.add(
      fromText._readTableConstraint(precedingComma, checkTable),
    );
  }

  void dropConstraint(_TableConstraint tableConstraint) {
    _tableConstraints.remove(tableConstraint);
    tableConstraint.precedingComma?.unlink();
    tableConstraint.source.unlink();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final source in _sources) {
      buffer.write(source.lexeme);
    }

    return buffer.toString();
  }
}

final class _ColumnDefinition {
  final _SourceElement? precedingComma;
  final _SourceElement nameLexeme;
  String lowercaseName;
  _SourceElement? typeName;
  final List<_ColumnConstraint> constraints;

  _SourceElement get end {
    if (constraints.isNotEmpty) {
      return constraints.last.source;
    } else {
      return typeName ?? nameLexeme;
    }
  }

  _ColumnDefinition(
    this.precedingComma,
    this.nameLexeme,
    this.lowercaseName,
    this.typeName,
    this.constraints,
  );

  void setNotNull(ConflictClause? onConflict) {
    if (constraints.any((c) => c.constraint is NotNull)) {
      return; // Already has a not null constraint
    }

    final constraint = NotNull(null, onConflict: onConflict);
    final withSpan = _ColumnConstraint(
      constraint,
      _SourceElement(' ${constraint.toSql()}'),
    );

    withSpan.addAfter(end);
    constraints.add(withSpan);
  }

  void dropNotNull() {
    constraints.removeWhere((c) {
      if (c.constraint is NotNull) {
        c.source.unlink();
        return true;
      }
      return false;
    });
  }

  void dropConstraint(_ColumnConstraint columnConstraint) {
    constraints.remove(columnConstraint);
    columnConstraint.source.unlink();
  }
}

final class _TableConstraint {
  final TableConstraint constraint;
  final _SourceElement source;
  final _SourceElement? precedingComma;

  _TableConstraint(this.precedingComma, this.constraint, this.source);
}

/// Any schema element that isn't a (non-virtual) table.
///
/// Because these can't be altered, we don't have to track detailed information
/// on them and just preserve their original text.
final class _OtherSchemaElement extends _SchemaElement {
  @override
  final DropType type;
  final FileSpan createStatement;

  _OtherSchemaElement(this.type, this.createStatement);

  @override
  String toString() {
    return createStatement.text;
  }
}

final class _ColumnConstraint {
  final ColumnConstraint constraint;
  final _SourceElement source;

  _ColumnConstraint(this.constraint, this.source);

  void addAfter(_SourceElement before) {
    before.insertAfter(source);
  }
}

final class _SourceElement extends LinkedListEntry<_SourceElement> {
  String lexeme;

  _SourceElement(this.lexeme);

  _SourceElement clone() => _SourceElement(lexeme);
}

final class _SourceFromText {
  final String text;
  final int startOffset;
  _SourceElement last;

  var currentPosition = 0;

  _SourceFromText(this.text, this.startOffset, this.last);

  _SourceElement? elementUntil(int offset) {
    if (currentPosition < offset) {
      // Static text before this element.
      final element = _SourceElement(text.substring(currentPosition, offset));
      last.insertAfter(element);
      last = element;
      currentPosition = offset;
      return element;
    } else {
      return null;
    }
  }

  (_SourceElement?, _SourceElement) createElementFromSpan(
    int offset,
    int length,
  ) {
    final prior = elementUntil(offset);
    final element = elementUntil(currentPosition + length)!;

    return (prior, element);
  }

  (_SourceElement?, _SourceElement) createElementFromSyntax(
    SyntacticEntity entity,
  ) {
    return createElementFromSpan(
      entity.firstPosition - startOffset,
      entity.length,
    );
  }

  _ColumnDefinition _readColumnDefinition(
    _SourceElement? precedingComma,
    ColumnDefinition column,
  ) {
    final (before, name) = createElementFromSyntax(column.nameToken!);
    _SourceElement? typeName;
    final constraints = <_ColumnConstraint>[];
    if (column.constraints.isNotEmpty) {
      typeName = elementUntil(column.constraints.first.firstPosition);
      for (final constraint in column.constraints) {
        constraints.add(
          _ColumnConstraint(constraint, elementUntil(constraint.lastPosition)!),
        );
      }
    } else {
      typeName = elementUntil(column.lastPosition);
    }

    return _ColumnDefinition(
      precedingComma,
      name,
      column.columnName.toLowerCase(),
      typeName,
      constraints,
    );
  }

  _TableConstraint _readTableConstraint(
    _SourceElement? precedingComma,
    TableConstraint tableConstraint,
  ) {
    return _TableConstraint(
      precedingComma,
      tableConstraint,
      elementUntil(tableConstraint.lastPosition)!,
    );
  }
}
