import 'package:drift/drift.dart';
import 'package:macros/macros.dart';

import '../../drift_macros.dart';
import '../model/column.dart';
import '../model/table.dart';

final class TableAnalyzer {
  final DriftTable macro;
  final ClassDeclaration rowClass;
  final DeclarationPhaseIntrospector introspector;

  TableAnalyzer({
    required this.macro,
    required this.rowClass,
    required this.introspector,
  });

  Future<ResolvedTable> resolve() async {
    final columns = <ResolvedColumn>[];
    for (final field in await introspector.fieldsOf(rowClass)) {
      columns.add(await _resolveColumn(field));
    }

    return ResolvedTable(
      columns: columns,
      rowClass: rowClass.identifier,
      // ignore: deprecated_member_use
      tableClass: await introspector.resolveIdentifier(
        rowClass.library.uri,
        tableClassForRow(rowClass.identifier),
      ),
      strict: macro.strict,
      withoutRowId: macro.withoutRowId,
    );
  }

  Future<ResolvedColumn> _resolveColumn(FieldDeclaration field) async {
    // todo This is just totally unsound but we can't really do better with the
    // macro API at the moment.
    var sqlType = const ColumnType.drift(DriftSqlType.int);
    if (field.type case NamedTypeAnnotation type) {
      switch (type.identifier.name) {
        case 'int':
          sqlType = const ColumnType.drift(DriftSqlType.int);
        case 'BigInt':
          sqlType = const ColumnType.drift(DriftSqlType.bigInt);
        case 'String':
          sqlType = const ColumnType.drift(DriftSqlType.string);
        case 'double':
          sqlType = const ColumnType.drift(DriftSqlType.double);
        case 'Uint8List':
          sqlType = const ColumnType.drift(DriftSqlType.blob);
        case 'DriftAny':
          sqlType = const ColumnType.drift(DriftSqlType.any);
        case 'bool':
          sqlType = const ColumnType.drift(DriftSqlType.bool);
        case 'DateTime':
          sqlType = const ColumnType.drift(DriftSqlType.dateTime);
      }
    }

    return ResolvedColumn(
      sqlType: sqlType,
      nullable: field.type.isNullable,
      // todo: Transform SQL names? Or maybe we explicitly don't want to do that
      // if a custom name has not been set.
      nameInSql: field.identifier.name,
      nameInDart: field.identifier.name,
    );
  }

  static String tableClassForRow(Identifier rowClass) {
    return '${rowClass.name}\$Table';
  }
}
