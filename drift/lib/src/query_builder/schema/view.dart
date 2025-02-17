import 'result_set.dart';

abstract base class GeneratedView<Row extends Object,
    Self extends GeneratedView<Row, Self>> extends ResultSet<Row, Self> {
  GeneratedView({required super.entityName, required super.alias});
}
