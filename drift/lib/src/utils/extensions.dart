import 'package:drift/src/runtime/query_builder/query_builder.dart';

///
extension ResultSetImplementationExt on ResultSetImplementation {
  ///
  List<GeneratedColumn> get $nvColumns =>
      $columns.where((c) => c.virtualSql == null).toList();

  /// Required virtual columns (that not null)
  List<GeneratedColumn> get $rvColumns =>
      $columns.where((c) => c.virtualSql == null || !c.$nullable).toList();
}
