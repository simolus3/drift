import '../expressions/expression.dart';
import '../statements/select.dart';
import 'column.dart';
import 'result_set.dart';

abstract interface class GeneratedView<Row extends Object,
    Self extends GeneratedView<Row, Self>> implements ResultSet<Row, Self> {
  SelectStatement? get query;
}

final class ViewColumn<T extends Object> extends SchemaColumn<T> {
  final Expression<T> expression;

  ViewColumn({
    required super.name,
    required super.type,
    super.isNullable,
    required this.expression,
  });
}
