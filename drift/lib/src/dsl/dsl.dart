import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import '../runtime/types/mapping.dart';

part 'columns.dart';
part 'database.dart';
part 'table.dart';

/// Implementation for dsl methods that aren't called at runtime but only exist
/// for the generator to pick up. For instance, in
/// ```dart
/// class MyTable extends Table {
///   IntColumn get id => integer().autoIncrement()();
/// }
/// ```
/// Neither [Table.integer], [BuildIntColumn.autoIncrement] or
/// [BuildGeneralColumn.call]  will be called at runtime. Instead, the generator
/// will take a look at the written Dart code to recognize that `id` is a column
/// of type int that has auto increment (and is thus the primary key). It will
/// generate a subclass of `MyTable` which looks like this:
/// ```dart
/// class _$MyTable extends MyTable {
///   IntColumn get id => GeneratedIntColumn(
///     'id',
///     'my-table',
///     false,
///     declaredAsPrimaryKey: false,
///     declaredAsAutoIncrement: true,
///   );
/// }
/// ```
Never _isGenerated() {
  throw UnsupportedError(
    'This method should not be called at runtime. Are you sure you re-ran the '
    'builder after changing your tables or databases?',
  );
}
