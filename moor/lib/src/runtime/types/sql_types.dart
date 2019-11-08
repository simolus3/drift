import 'dart:typed_data';

import 'package:convert/convert.dart';

part 'custom_type.dart';
part 'type_system.dart';

/// A type that can be mapped from Dart to sql. The generic type parameter here
/// denotes the resolved dart type.
abstract class SqlType<T> {
  /// Constant constructor so that subclasses can be constant
  const SqlType();

  /// Maps the [content] to a value that we can send together with a prepared
  /// statement to represent the given value.
  dynamic mapToSqlVariable(T content);

  /// Maps the given content to a sql literal that can be included in the query
  /// string.
  String mapToSqlConstant(T content);

  /// Maps the response from sql back to a readable dart type.
  T mapFromDatabaseResponse(dynamic response);
}

/// A marker interface for [SqlType]s that can be compared using the comparison
/// operators in sql.
abstract class ComparableType<T> extends SqlType<T> {}

/// A marker interface for [SqlType]s that have a `+` operator.
abstract class Monoid<T> extends SqlType<T> {}

/// A marker interface for [SqlType]s that support all basic arithmetic
/// operators (`+`, `-`, `*` and `/`) while also being a [ComparableType]
abstract class FullArithmetic<T> extends Monoid<T>
    implements ComparableType<T> {}

/// A mapper for boolean values in sql. Booleans are represented as integers,
/// where 0 means false and any other value means true.
class BoolType extends SqlType<bool> {
  /// Constant constructor used by the type system
  const BoolType();

  @override
  bool mapFromDatabaseResponse(response) {
    // ignore: avoid_returning_null
    if (response == null) return null;
    return response != 0;
  }

  @override
  String mapToSqlConstant(bool content) {
    if (content == null) {
      return 'NULL';
    }
    return content ? '1' : '0';
  }

  @override
  mapToSqlVariable(bool content) {
    if (content == null) {
      return null;
    }
    return content ? 1 : 0;
  }
}

/// Mapper for string values in sql.
class StringType extends SqlType<String> implements Monoid<String> {
  /// Constant constructor used by the type system
  const StringType();

  @override
  String mapFromDatabaseResponse(response) => response?.toString();

  @override
  String mapToSqlConstant(String content) {
    // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
    // A string constant is formed by enclosing the string in single quotes (').
    // A single quote within the string can be encoded by putting two single
    // quotes in a row - as in Pascal. C-style escapes using the backslash
    // character are not supported because they are not standard SQL.
    final escapedChars = content.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }

  @override
  mapToSqlVariable(String content) => content;
}

/// Maps [int] values from and to sql
class IntType extends SqlType<int> implements FullArithmetic<int> {
  /// Constant constructor used by the type system
  const IntType();

  @override
  int mapFromDatabaseResponse(response) => response as int;

  @override
  String mapToSqlConstant(int content) => content?.toString() ?? 'NULL';

  @override
  mapToSqlVariable(int content) {
    return content;
  }
}

/// Maps [DateTime] values from and to sql
class DateTimeType extends SqlType<DateTime>
    implements ComparableType<DateTime> {
  /// Constant constructor used by the type system
  const DateTimeType();

  @override
  DateTime mapFromDatabaseResponse(response) {
    if (response == null) return null;

    final unixSeconds = response as int;

    return DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  }

  @override
  String mapToSqlConstant(DateTime content) {
    if (content == null) return 'NULL';

    return (content.millisecondsSinceEpoch ~/ 1000).toString();
  }

  @override
  mapToSqlVariable(DateTime content) {
    if (content == null) return null;

    return content.millisecondsSinceEpoch ~/ 1000;
  }
}

/// Maps [Uint8List] values from and to sql
class BlobType extends SqlType<Uint8List> {
  /// Constant constructor used by the type system
  const BlobType();

  @override
  mapFromDatabaseResponse(response) => response as Uint8List;

  @override
  String mapToSqlConstant(Uint8List content) {
    // BLOB literals are string literals containing hexadecimal data and
    // preceded by a single "x" or "X" character. Example: X'53514C697465'
    return "x'${hex.encode(content)}'";
  }

  @override
  mapToSqlVariable(Uint8List content) => content;
}

/// Maps [double] values from and to sql
class RealType extends SqlType<double> implements FullArithmetic<double> {
  /// Constant constructor used by the type system
  const RealType();

  @override
  double mapFromDatabaseResponse(response) => (response as num)?.toDouble();

  @override
  String mapToSqlConstant(num content) {
    if (content == null) {
      return 'NULL';
    }
    return content.toString();
  }

  @override
  mapToSqlVariable(num content) => content;
}
