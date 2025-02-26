import 'package:meta/meta_meta.dart';

/// {@template drift_riverpod/QueryProvider}
/// An annotation for fields forming a query provider.
///
/// Query providers are backed by an SQL statement that is analyzed at build
/// time to infer when it needs to be updated. This allows SQL statements to be
/// used as Riverpod providers.
/// Like all providers, query providers are defined as top-level variables.
/// Their initializer __must__ be a method invocation on a database or DAO
/// provider, like this:
///
/// ```dart
/// final database = StateProvider((ref) => MyDriftDatabase());
///
/// @queryProvider
/// final users = database.$amountOfUsers('SELECT * FROM users');
/// ```
///
/// The `$amountOfUsers` method does not exist at the time the provider is
/// defined, it's generated through `build_runner`. The `drift_riverpod` will
/// generate one extension for every field annotated with [QueryProvider].
///
/// For queries that depend on parameters, `drift_riverpod` can generate
/// provider families:
///
/// ```dart
/// @QueryProvider(singleRow: true)
/// final user = database.$userProvider((int id) => 'SELECT * FROM users WHERE id = $id');
/// ```
///
/// Note that, despite using string interpolation, there's no risk of an SQL
/// injection attack! [QueryProvider]s just declare a query, a builder will
/// analyze these declarations to replace the interpolation with prepared
/// statements.
///
/// The annotation can be used in two ways: Through the [QueryProvider] class or
/// with the [queryProvider] top-level field. Using the latter is equivalent to
/// using [QueryProvider] with the default options.
/// {@endtemplate}
@Target({TargetKind.topLevelVariable})
final class QueryProvider<Row> {
  /// Whether the annotated query is expexted to only return a single row.
  ///
  /// While regular providers are generated as lists, they [singleRow] providers
  /// generate as a single value:
  ///
  /// ```dart
  /// @queryProvider
  /// final countUsers = database.$countUsers('SELECT COUNT(*) FROM users;');
  /// ```
  final bool singleRow;

  /// Creates a query provider annotation. See the [QueryProvider] class
  /// documentation for details.
  const QueryProvider({this.singleRow = false});
}

/// {@macro drift_riverpod/QueryProvider}
const queryProvider = QueryProvider<dynamic>();
