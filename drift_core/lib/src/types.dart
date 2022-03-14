import 'dialect.dart';

abstract class SqlType<T> {
  SqlDialect get dialect;

  String get name;
}
