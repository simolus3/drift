import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/writer.dart';
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import 'declarations/declaration.dart';
import 'table.dart';
import 'types.dart';
import 'used_type_converter.dart';

/// The column types in sql.
enum ColumnType { integer, text, boolean, datetime, blob, real }

/// Name of a column. Contains additional info on whether the name was chosen
/// implicitly (based on the dart getter name) or explicitly (via an named())
/// call in the column builder dsl.
class ColumnName {
  /// A column name is implicit if it has been looked up with the associated
  /// field name in the table class. It's explicit if `.named()` was called in
  /// the column builder.
  final bool implicit;

  final String name;

  ColumnName.implicitly(this.name) : implicit = true;
  ColumnName.explicitly(this.name) : implicit = false;

  @override
  int get hashCode => name.hashCode + implicit.hashCode * 31;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    // ignore: test_types_in_equals
    final typedOther = other as ColumnName;
    return typedOther.implicit == implicit && typedOther.name == name;
  }

  @override
  String toString() {
    return 'ColumnName($name, implicit = $implicit)';
  }
}

/// A column, as specified by a getter in a table.
class MoorColumn implements HasDeclaration, HasType {
  /// The getter name of this column in the table class. It will also be used
  /// as getter name in the TableInfo class (as it needs to override the field)
  /// and in the generated data class that will be generated for each table.
  final String dartGetterName;

  String get getterNameWithTable =>
      table == null ? dartGetterName : '${table!.dbGetterName}.$dartGetterName';

  /// The declaration of this column, contains information about where this
  /// column was created in source code.
  @override
  final ColumnDeclaration? declaration;

  /// Whether this column was declared inside a moor file.
  bool get declaredInMoorFile => declaration?.isDefinedInMoorFile ?? false;

  /// The sql type of this column
  @override
  final ColumnType type;

  /// The name of this column, as chosen by the user
  final ColumnName name;

  /// An (optional) name to use as a json key instead of the [dartGetterName].
  final String? overriddenJsonName;
  String getJsonKey([MoorOptions options = const MoorOptions.defaults()]) {
    if (overriddenJsonName != null) return overriddenJsonName!;

    final useColumnName = options.useColumnNameAsJsonKeyWhenDefinedInMoorFile &&
        declaredInMoorFile;
    return useColumnName ? name.name : dartGetterName;
  }

  /// Whether the user has explicitly declared this column to be nullable, the
  /// default is false
  @override
  final bool nullable;

  /// Whether this column has auto increment.
  bool get hasAI => features.any((f) => f is AutoIncrement);

  final List<ColumnFeature> features;

  /// If this columns has custom constraints that should be used instead of the
  /// default ones.
  final String? customConstraints;

  /// Dart code that generates the default expression for this column, or null
  /// if there is no default expression.
  final String? defaultArgument;

  /// Dart code for the `clientDefault` expression, or null if it hasn't been
  /// set.
  final String? clientDefaultCode;

  /// The [UsedTypeConverter], if one has been set on this column.
  @override
  final UsedTypeConverter? typeConverter;

  /// The documentation comment associated with this column
  ///
  /// Stored as a multi line string with leading triple-slashes `///` for every line
  final String? documentationComment;

  final ColumnGeneratedAs? generatedAs;

  bool get isGenerated => generatedAs != null;

  /// Parent table
  MoorTable? table;

  /// The column type from the dsl library. For instance, if a table has
  /// declared an `IntColumn`, the matching dsl column name would also be an
  /// `IntColumn`.
  @Deprecated('Use Column<innerColumnType()> instead')
  String get dslColumnTypeName => const {
        ColumnType.boolean: 'BoolColumn',
        ColumnType.text: 'TextColumn',
        ColumnType.integer: 'IntColumn',
        ColumnType.datetime: 'DateTimeColumn',
        ColumnType.blob: 'BlobColumn',
        ColumnType.real: 'RealColumn',
      }[type]!;

  String innerColumnType(
      [GenerationOptions options = const GenerationOptions()]) {
    String code;

    switch (type) {
      case ColumnType.integer:
        code = 'int';
        break;
      case ColumnType.text:
        code = 'String';
        break;
      case ColumnType.boolean:
        code = 'bool';
        break;
      case ColumnType.datetime:
        code = 'DateTime';
        break;
      case ColumnType.blob:
        code = 'Uint8List';
        break;
      case ColumnType.real:
        code = 'double';
        break;
    }

    // We currently use nullable columns everywhere because it's not clear how
    // to express nullability in joins otherwise.
    return options.nnbd ? '$code?' : code;
  }

  SqlType sqlType() {
    switch (type) {
      case ColumnType.integer:
        return const IntType();
      case ColumnType.boolean:
        return const BoolType();
      case ColumnType.datetime:
        return const IntType();
      case ColumnType.text:
        return const StringType();
      case ColumnType.blob:
        return const BlobType();
      case ColumnType.real:
        return const RealType();
    }
  }

  @override
  bool get isArray => false;

  MoorColumn({
    required this.type,
    required this.dartGetterName,
    required this.name,
    this.overriddenJsonName,
    this.customConstraints,
    this.nullable = false,
    this.features = const [],
    this.defaultArgument,
    this.clientDefaultCode,
    this.typeConverter,
    this.declaration,
    this.documentationComment,
    this.generatedAs,
  });
}

abstract class ColumnFeature {
  const ColumnFeature();
}

/// A `PRIMARY KEY` column constraint.
class PrimaryKey extends ColumnFeature {
  const PrimaryKey();
}

class AutoIncrement extends PrimaryKey {
  static const AutoIncrement _instance = AutoIncrement._();

  const AutoIncrement._();

  factory AutoIncrement() => _instance;

  @override
  bool operator ==(Object other) => other is AutoIncrement;

  @override
  int get hashCode => 1337420;
}

class LimitingTextLength extends ColumnFeature {
  final int? minLength;

  final int? maxLength;

  LimitingTextLength({this.minLength, this.maxLength});

  @override
  int get hashCode => minLength.hashCode ^ maxLength.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    // ignore: test_types_in_equals
    final typedOther = other as LimitingTextLength;
    return typedOther.minLength == minLength &&
        typedOther.maxLength == maxLength;
  }
}

class UnresolvedDartForeignKeyReference extends ColumnFeature {
  final ClassElement otherTable;
  final String otherColumnName;
  final ReferenceAction? onUpdate;
  final ReferenceAction? onDelete;

  final Element? surroundingElementForErrors;
  final AstNode? otherTableName;
  final AstNode columnNameNode;

  UnresolvedDartForeignKeyReference(
    this.otherTable,
    this.otherColumnName,
    this.onUpdate,
    this.onDelete,
    this.surroundingElementForErrors,
    this.otherTableName,
    this.columnNameNode,
  );
}

class ResolvedDartForeignKeyReference extends ColumnFeature {
  final MoorTable otherTable;
  final MoorColumn otherColumn;
  final ReferenceAction? onUpdate;
  final ReferenceAction? onDelete;

  ResolvedDartForeignKeyReference(
      this.otherTable, this.otherColumn, this.onUpdate, this.onDelete);
}

class ColumnGeneratedAs {
  final String? dartExpression;
  final bool stored;

  ColumnGeneratedAs(this.dartExpression, this.stored);
}
