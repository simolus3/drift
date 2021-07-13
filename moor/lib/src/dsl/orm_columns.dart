// ignore_for_file: public_member_api_docs
part of 'dsl.dart';

enum ColumnType { integer, text, boolean, datetime, blob, real }

@Target({TargetKind.field})
class ColumnDef {
  final String? name;
  final bool nullable;
  final ColumnType type;
  final String? customConstraints;
  final Expression<dynamic>? sqlDefault;
  final TypeConverter? converter;
  const ColumnDef(
    this.type, {
    this.nullable = false,
    this.name,
    this.customConstraints,
    this.sqlDefault,
    this.converter,
  });
}

enum KeyAction { noAction, cascade, restrict, setNull, setDefault }

@Target({TargetKind.field})
class ForeignKeyColumn extends ColumnDef {
  final Type references;
  final String column;
  final KeyAction? onUpdate;
  final KeyAction? onDelete;

  const ForeignKeyColumn(
    this.references, {
    TypeConverter? converter,
    bool nullable = false,
    String? name,
    String? customConstraints,
    Expression<dynamic>? sqlDefault,
    this.column = 'id',
    this.onUpdate = KeyAction.cascade,
    this.onDelete = KeyAction.restrict,
  }) : super(
          ColumnType.integer,
          nullable: nullable,
          name: name,
          customConstraints: customConstraints,
          sqlDefault: sqlDefault,
          converter: converter,
        );
}

@Target({TargetKind.field})
class EnumColumn extends ColumnDef {
  const EnumColumn({
    bool nullable = false,
    String? name,
    String? customConstraints,
    Expression<dynamic>? sqlDefault,
  }) : super(
          ColumnType.integer,
          nullable: nullable,
          name: name,
          customConstraints: customConstraints,
          sqlDefault: sqlDefault,
        );
}

@Target({TargetKind.field})
class PrimaryKeyColumn {
  const PrimaryKeyColumn();
}

@Target({TargetKind.field})
class AutoIncrement {
  const AutoIncrement();
}

@Target({TargetKind.field})
class TextLimit {
  final int? min;
  final int? max;

  const TextLimit({this.min, this.max});
}
