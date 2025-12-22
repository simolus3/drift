import 'package:meta/meta.dart';

import '../../connection/result_set.dart';
import '../../database/connection_user.dart';
import '../../database/data_class.dart';
import '../../dsl/table.dart';
import '../expressions/variables.dart';
import '../results.dart';
import 'column.dart';
import 'entities.dart';

/// A result set as it appears in the database schema.
///
/// [Row] is the Dart type to represent a value of this result set. [Self] is
/// the actual subtype.
///
/// To read a result set from a row, use [DriftRow.readTable].
mixin ResultSet<Row extends Object, Self extends ResultSet<Row, Self>>
    implements ResultSetDsl, DatabaseSchemaEntity {
  /// When created through [withAlias], an alias for this result set.
  String? get alias;

  /// The columns of this result set.
  List<SchemaColumn> get columns;

  /// If an [alias] is set, the alias. Otherwise, the [entityName] for this
  /// result set.
  String get aliasOrName => alias ?? entityName;

  /// All [columns], indexed by their name.
  late final Map<String, SchemaColumn> columnsByName = {
    for (final column in columns) column.name: column,
  };

  /// Creates a function that, when receiving a [DriftRow], extracts columns for
  /// this result set into the mapped [Row] type.
  Row? Function(DriftRow) createMapperToDart(ResultSetStructure structure) {
    final positions = structure.tables[this];
    if (positions == null) {
      throw StateError('Table $aliasOrName has not been selected from');
    }

    return createMapperFromPositions(positions);
  }

  /// Like [createMapperToDart], but with positions already resolved.
  Row? Function(DriftRow) createMapperFromPositions(
    List<ColumnPosition> positions,
  );

  /// Converts a [companion] to the real model class, [Row].
  ///
  /// Values that are [Value.absent] in the companion will be set to `null`.
  /// The [database] instance is used so that the raw values from the companion
  /// can properly be interpreted as the high-level Dart values exposed by the
  /// data class.
  Row mapFromCompanion(
    Insertable<Row> companion,
    DatabaseConnectionUser database,
  ) {
    final asColumnMap = companion.toColumns(false);

    if (asColumnMap.values.any((e) => e is! Variable)) {
      throw ArgumentError(
        'The companion $companion cannot be transformed '
        'into a dataclass as it contains expressions that need to be '
        'evaluated by a database engine.',
      );
    }

    final structure = ResultSetStructure()..addSelectStarFromSingleTable(this);
    final resultSet = RawResultSet.fromRows(
      columnNames: [...asColumnMap.keys],
      rows: [
        [
          for (final value in asColumnMap.values)
            (value as Variable).resolveValue(database.dialect).rawValue,
        ],
      ],
    );

    final mappedResultSet = DriftResultSet(
      structure,
      resultSet,
      database.dialect,
    );
    final mapper = createMapperToDart(structure);
    return mapper(mappedResultSet.first)!;
  }

  /// Returns a new instance of this result set with [alias] set to the given
  /// value.
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

  /// Internal, cast from [ResultSetDsl] (which will implement [ResultSet] for
  /// drift-generated result sets) to [ResultSet].
  @internal
  static ResultSet fromDsl(ResultSetDsl dsl) {
    return dsl as ResultSet;
  }
}
