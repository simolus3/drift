import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../../connections/result_set.dart';
import '../../dsl/table.dart';
import '../../runtime/data_class.dart';
import '../../runtime/database/connection_user.dart';
import '../expressions/variables.dart';
import '../results.dart';
import '../types.dart';
import 'column.dart';
import 'entities.dart';

@immutable
mixin ResultSet<Row extends Object, Self extends ResultSet<Row, Self>>
    implements ResultSetDsl, DatabaseSchemaEntity {
  String? get alias;

  IList<SchemaColumn> get columns;

  String get aliasOrName => alias ?? entityName;

  late final Map<String, SchemaColumn> columnsByName = {
    for (final column in columns) column.name: column,
  };

  Row? Function(DriftRow) createMapperToDart(ResultSetStructure structure) {
    return createMapperFromPositions(structure.tables[this]!);
  }

  Row? Function(DriftRow) createMapperFromPositions(
      IList<ColumnPosition> positions);

  Row? mapToDart(DriftRow row) {
    return createMapperToDart(row.resultSet.structure)(row);
  }

  /// Converts a [companion] to the real model class, [Row].
  ///
  /// Values that are [Value.absent] in the companion will be set to `null`.
  /// The [database] instance is used so that the raw values from the companion
  /// can properly be interpreted as the high-level Dart values exposed by the
  /// data class.
  Row mapFromCompanion(
      Insertable<Row> companion, DatabaseConnectionUser database) {
    final asColumnMap = companion.toColumns(false);

    if (asColumnMap.values.any((e) => e is! Variable)) {
      throw ArgumentError('The companion $companion cannot be transformed '
          'into a dataclass as it contains expressions that need to be '
          'evaluated by a database engine.');
    }

    final structure = ResultSetStructure().withSelectStarFromSingleTable(this);

    final rawValues = asColumnMap.cast<String, Variable>().map((key, value) {
      final (type, dartValue) = value.resolveValue(database.dialect);

      return MapEntry(
          key, type.sqlParameterOrNull(database.dialect, dartValue));
    });

    final resultSet = RawResultSet.generate(
      1,
      (_, rs) => RawRow.byMap(resultSet: rs, values: rawValues),
    );

    final mappedResultSet =
        DriftResultSet(structure, resultSet, database.dialect);
    final mapper = createMapperToDart(structure);
    return mapper(mappedResultSet.first)!;
  }

  Self withAlias(String alias);

  /// Type-level hack: Result sets are supposed to inherit from the [Self] type
  /// they declare, so this returns just `this`.
  Self asSelfType();

  @override
  bool operator ==(Object other) {
    // result sets are singleton instances except for aliases
    if (other is ResultSet) {
      return other.runtimeType == runtimeType && other.alias == alias;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(alias, entityName);

  static ResultSet fromDsl(ResultSetDsl dsl) {
    return dsl as ResultSet;
  }
}
