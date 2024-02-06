/// Experimental bindings to the [json1](https://www.sqlite.org/json1.html)
/// sqlite extension.
///
/// Note that the json1 extension might not be available on all runtimes.
/// When using this library, it is recommended to use a `NativeDatabase` with
/// a dependency on `sqlite3_flutter_libs`.
@experimental
library json1;

import 'package:meta/meta.dart';
import '../drift.dart';

/// Defines extensions on string expressions to support the json1 api from Dart.
extension JsonExtensions on Expression<String> {
  /// Reads `this` expression as a JSON structure and outputs the JSON in a
  /// minified format.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jmini.
  Expression<String> json() {
    return FunctionCallExpression('json', [this]);
  }

  /// Reads `this` expression as a JSON structure and outputs the JSON in a
  /// binary format internal to sqlite3.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jminib.
  Expression<Uint8List> jsonb() {
    return FunctionCallExpression('jsonb', [this]);
  }

  /// Assuming that this string is a json array, returns the length of this json
  /// array.
  ///
  /// The [path] parameter is optional. If it's set, it must refer to a valid
  /// path in this json that will be used instead of `this`. See the
  /// [sqlite documentation](https://www.sqlite.org/json1.html#path_arguments)
  /// for details. If [path] is an invalid path, this expression can cause an
  /// error when run by sqlite.
  ///
  /// For this method to be valid, `this` must be a string representing a valid
  /// json array. Otherwise, sqlite will report an error when attempting to
  /// evaluate this expression.
  ///
  /// See also:
  ///  - the [sqlite documentation for this function](https://www.sqlite.org/json1.html#the_json_array_length_function)
  Expression<int> jsonArrayLength([String? path]) {
    return FunctionCallExpression('json_array_length', [
      this,
      if (path != null) Variable.withString(path),
    ]);
  }

  /// Assuming that this string is a json object or array, extracts a part of
  /// this structure identified by [path].
  ///
  /// For more details on how to format the [path] argument, see the
  /// [sqlite documentation](https://www.sqlite.org/json1.html#path_arguments).
  ///
  /// Evaluating this expression will cause an error if [path] has an invalid
  /// format or `this` isn't well-formatted json.
  ///
  /// Note that the [T] type parameter has to be set if this function is used
  /// in [JoinedSelectStatement.addColumns] or compared via [Expression.equals].
  /// The [T] parameter denotes the mapped Dart type for this expression,
  /// such as [String].
  Expression<T> jsonExtract<T extends Object>(String path) {
    return FunctionCallExpression('json_extract', [
      this,
      Variable.withString(path),
    ]).dartCast<T>();
  }

  /// Calls the `json_each` table-valued function on `this` string, optionally
  /// using [path] as the root path.
  ///
  /// This can be used to join every element in a JSON structure to a drift
  /// query.
  ///
  /// See also: The [sqlite3 documentation](https://sqlite.org/json1.html#jeach)
  /// and [JsonTableFunction].
  JsonTableFunction jsonEach(DatabaseConnectionUser database, [String? path]) {
    return JsonTableFunction._(database, functionName: 'json_each', arguments: [
      this,
      if (path != null) Variable(path),
    ]);
  }

  /// Calls the `json_tree` table-valued function on `this` string, optionally
  /// using [path] as the root path.
  ///
  /// This can be used to join every element in a JSON structure to a drift
  /// query.
  ///
  /// See also: The [sqlite3 documentation](https://sqlite.org/json1.html#jeach)
  /// and [JsonTableFunction].
  JsonTableFunction jsonTree(DatabaseConnectionUser database, [String? path]) {
    return JsonTableFunction._(database, functionName: 'json_tree', arguments: [
      this,
      if (path != null) Variable(path),
    ]);
  }
}

/// Returns a JSON array containing the result of evaluating [value] in each row
/// of the current group.
///
/// As an example, consider two tables with a one-to-many relationship between
/// them:
///
/// ```dart
/// class Emails extends Table {
///   TextColumn get subject => text()();
///   TextColumn get body => text()();
///   IntColumn get folder => integer().references(Folders, #id)();
/// }
///
/// class Folders extends Table {
///   IntColumn get id => integer()();
///   TextColumn get title => text()();
/// }
/// ```
///
/// With this schema, suppose we want to find the subject lines of every email
/// in every folder. A join gets us all the information:
///
/// ```dart
/// final query = select(folders)
///   .join([innerJoin(emails, emails.folder.equalsExp(folders.id))]);
/// ```
///
/// However, running this query would duplicate rows for `Folders` - if that
/// table had more columns, that might not be what you want. With
/// [jsonGroupArray], it's possible to join all subjects into a single row:
///
/// ```dart
/// final subjects = jsonGroupObject(emails.subject);
/// query
///   ..groupBy([folders.id])
///   ..addColumns([subjects]);
/// ```
///
/// Running this query would return one row for each folder, where
/// `row.read(subjects)` is a textual JSON representation of the subjects for
/// all emails in that folder.
/// This string could be turned back into a list with
/// `(json.decode(row.read(subjects)!) as List).cast<String>()`.
Expression<String> jsonGroupArray(Expression value) {
  return FunctionCallExpression('json_group_array', [value]);
}

/// Returns a binary representation of a JSON array containing the result of
/// evaluating [value] in each row of the current group.
///
/// See [jsonGroupArray], the variant of this function returning a textual
/// description, for more details and an example.
Expression<Uint8List> jsonbGroupArray(Expression value) {
  return FunctionCallExpression('jsonb_group_array', [value]);
}

List<Expression> _groupObjectArgs(Map<Expression<String>, Expression> values) {
  final expressions = <Expression>[];
  for (final MapEntry(:key, :value) in values.entries) {
    expressions.add(key);
    expressions.add(value);
  }
  return expressions;
}

/// Returns a JSON object consisting of the keys and values from the provided
/// [values] map.
///
/// As an example, consider this example schema to store emails:
///
/// ```dart
/// class Emails extends Table {
///   TextColumn get subject => text()();
///   TextColumn get body => text()();
///   IntColumn get folder => integer().references(Folders, #id)();
/// }
///
/// class Folders extends Table {
///   IntColumn get id => integer()();
///   TextColumn get title => text()();
/// }
/// ```
///
/// Now, say you wanted to write a query finding the subject and body of every
/// email in every folder. The resulting value might look like this:
/// ```json
///  {
///    "Group array example": "Hey there, aren't you aware that email is dead?",
///    "Re: Group array example": "It's just an example okay?"
///  }
/// ```
///
/// Again, the starting point is formed by a query joining the tables:
///
/// ```dart
/// final query = select(folders)
///   .join([innerJoin(emails, emails.folder.equalsExp(folders.id))]);
/// ```
///
/// Now, a group by clause and [jsonGroupObject] can be used to collapse all
/// joined rows from the `emails` table into a single value:
///
/// ```dart
/// final subjectAndBody = jsonGroupObject({emails.subject: emails.body});
/// query
///   ..groupBy([folders.id])
///   ..addColumns([subjectAndBody]);
/// ```
///
/// Running this query would return one row for each folder, where
/// `row.read(subjectAndBody)` is a textual JSON representation of a
/// `Map<String, String>`.
Expression<String> jsonGroupObject(Map<Expression<String>, Expression> values) {
  return FunctionCallExpression('json_group_object', _groupObjectArgs(values));
}

/// Returns a binary representation of a JSON object consisting of the provided
/// keys and values in the current group.
///
/// See [jsonGroupObject], the variant of this function returning a textual
/// description, for more details and an example.
Expression<Uint8List> jsonbGroupObject(
    Map<Expression<String>, Expression> values) {
  return FunctionCallExpression('jsonb_group_object', _groupObjectArgs(values));
}

/// Defines extensions for the binary `JSONB` format introduced in sqlite3
/// version 3.45.
///
/// For details, see https://www.sqlite.org/json1.html#jsonb
extension JsonbExtensions on Expression<Uint8List> {
  /// Reads this binary JSONB structure and emits its textual representation as
  /// minified JSON.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jmini.
  Expression<String> json() {
    return dartCast<String>().json();
  }

  /// Assuming that `this` is an expression evaluating to a binary JSONB array,
  /// returns the length of the array.
  ///
  /// See [JsonExtensions.jsonArrayLength] for more details and
  /// https://www.sqlite.org/json1.html#jsonb for details on jsonb.
  Expression<int> jsonArrayLength([String? path]) {
    // the function accepts both formats, and this way we avoid some duplicate
    // code.
    return dartCast<String>().jsonArrayLength(path);
  }

  /// Assuming that `this` is an expression evaluating to a binary JSONB object
  /// or array, extracts the part of the structure identified by [path].
  ///
  /// For more details, see [JsonExtensions.jsonExtract] or
  /// https://www.sqlite.org/json1.html#jex.
  Expression<T> jsonExtract<T extends Object>(String path) {
    return dartCast<String>().jsonExtract(path);
  }

  /// Calls the `json_each` table-valued function on `this` binary JSON buffer,
  /// optionally using [path] as the root path.
  ///
  /// See [JsonTableFunction] and [JsonExtensions.jsonEach] for more details.
  JsonTableFunction jsonEach(DatabaseConnectionUser database, [String? path]) {
    return dartCast<String>().jsonEach(database, path);
  }

  /// Calls the `json_tree` table-valued function on `this` binary JSON buffer,
  /// optionally using [path] as the root path.
  ///
  /// See [JsonTableFunction] and [JsonExtensions.jsonTree] for more details.
  JsonTableFunction jsonTree(DatabaseConnectionUser database, [String? path]) {
    return dartCast<String>().jsonTree(database, path);
  }
}

/// Calls [json table-valued functions](https://sqlite.org/json1.html#jeach) in
/// drift.
///
/// With [JsonExtensions.jsonEach] and [JsonExtensions.jsonTree], a JSON value
/// can be used a table-like structure available in queries and joins.
///
/// For an example and more details, see the [drift documentation](https://drift.simonbinder.eu/docs/advanced-features/joins/#json-support)
final class JsonTableFunction extends TableValuedFunction<JsonTableFunction> {
  JsonTableFunction._(
    super.attachedDatabase, {
    required super.functionName,
    required super.arguments,
    super.alias,
  }) : super(
          columns: [
            GeneratedColumn<DriftAny>('key', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<DriftAny>('value', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<String>('type', alias ?? functionName, true,
                type: DriftSqlType.string),
            GeneratedColumn<DriftAny>('atom', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<int>('id', alias ?? functionName, true,
                type: DriftSqlType.int),
            GeneratedColumn<int>('parent', alias ?? functionName, true,
                type: DriftSqlType.int),
            GeneratedColumn<String>('fullkey', alias ?? functionName, true,
                type: DriftSqlType.string),
            GeneratedColumn<String>('path', alias ?? functionName, true,
                type: DriftSqlType.string),
          ],
        );

  Expression<T> _col<T extends Object>(String name) {
    return columnsByName[name]! as Expression<T>;
  }

  /// The JSON key under which this element can be found in its parent, or
  /// `null` if this is the root element.
  ///
  /// Child elements of objects have a string key, elements in arrays are
  /// represented by their index.
  Expression<DriftAny> get key => _col('key');

  /// The value for the current value.
  ///
  /// Scalar values are returned directly, objects and arrays are returned as
  /// JSON strings.
  Expression<DriftAny> get value => _col('value');

  /// The result of calling [`sqlite3_type`](https://sqlite.org/json1.html#the_json_type_function)
  /// on this JSON element.
  Expression<String> get type => _col('type');

  /// The [value], or `null` if this is not a scalar value (so either an object
  /// or an array).
  Expression<DriftAny> get atom => _col('atom');

  /// An id uniquely identifying this element in the original JSON tree.
  Expression<int> get id => _col('id');

  /// The [id] of the parent of this element.
  Expression<int> get parent => _col('parent');

  /// The JSON key that can be passed to functions like
  /// [JsonExtensions.jsonExtract] to find this value.
  Expression<String> get fullKey => _col('fullkey');

  /// Similar to [fullKey], but relative to the `root` argument passed to
  /// [JsonExtensions.jsonEach] or [JsonExtensions.jsonTree].
  Expression<String> get path => _col('path');

  @override
  ResultSetImplementation<JsonTableFunction, TypedResult> createAlias(
      String alias) {
    return JsonTableFunction._(
      attachedDatabase,
      functionName: entityName,
      arguments: arguments,
      alias: alias,
    );
  }
}
