import 'dart:typed_data';

/// A type that can be mapped from Dart to sql. The generic type parameter here
/// denotes the resolved dart type.
abstract class SqlType<T> {
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

/// A mapper for boolean values in sql. Booleans are represented as integers,
/// where 0 means false and any other value means true.
class BoolType extends SqlType<bool> {
  const BoolType();

  @override
  bool mapFromDatabaseResponse(response) {
    return response != 0;
  }

  @override
  String mapToSqlConstant(bool content) {
    return content ? '1' : '0';
  }

  @override
  mapToSqlVariable(bool content) {
    return content ? 1 : 0;
  }
}

class StringType extends SqlType<String> {
  const StringType();

  @override
  String mapFromDatabaseResponse(response) => response as String;

  @override
  String mapToSqlConstant(String content) {
    // TODO: implement mapToSqlConstant, we would probably have to take care
    // of sql injection vulnerabilities here
    throw UnimplementedError("Strings can't be mapped to sql literals yet");
  }

  @override
  mapToSqlVariable(String content) => content;
}

class IntType extends SqlType<int> {
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

class DateTimeType extends SqlType<DateTime> {
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

class BlobType extends SqlType<Uint8List> {
  const BlobType();

  @override
  mapFromDatabaseResponse(response) => response as Uint8List;

  @override
  String mapToSqlConstant(content) {
    throw UnimplementedError("Blobs can't be mapped to sql literals");
  }

  @override
  mapToSqlVariable(content) => content;
}

class RealType extends SqlType<double> {
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
