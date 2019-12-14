import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:moor_generator/src/model/table.dart';

import 'column.dart';

class UsedTypeConverter {
  /// Index of this converter in the table in which it has been created.
  int index;

  /// The table using this type converter.
  MoorTable table;

  /// The [Expression] that will construct the type converter at runtime. The
  /// type converter constructed will map a [mappedType] to the [sqlType] and
  /// vice-versa.
  final Expression expression;

  /// The type that will be present at runtime.
  final DartType mappedType;

  /// The type that will be written to the database.
  final ColumnType sqlType;

  DartType get typeOfConverter => expression.staticType;

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  UsedTypeConverter(
      {@required this.expression,
      @required this.mappedType,
      @required this.sqlType});
}
