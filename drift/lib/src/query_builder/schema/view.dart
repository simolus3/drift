import 'result_set.dart';

abstract interface class GeneratedView<Row extends Object,
    Self extends GeneratedView<Row, Self>> implements ResultSet<Row, Self> {}
