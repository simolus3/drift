import 'package:built_value/built_value.dart';

part 'specified_column.g.dart';

enum ColumnType { integer, text, boolean }

abstract class ColumnName implements Built<ColumnName, ColumnNameBuilder> {
  /// A column name is implicit if it has been looked up with the associated
  /// field name in the table class. It's explicit if `.named()` was called in
  /// the column builder.
  bool get implicit;

  String get name;

  ColumnName._();

  factory ColumnName([updates(ColumnNameBuilder b)]) = _$ColumnName;

  factory ColumnName.implicitly(String name) => ColumnName((b) => b
    ..implicit = true
    ..name = name);

  factory ColumnName.explicitly(String name) => ColumnName((b) => b
    ..implicit = false
    ..name = name);
}

class SpecifiedColumn {
  final String dartGetterName;
  final ColumnType type;
  final ColumnName name;

  bool get hasAI => features.any((f) => f is AutoIncrement);

  /// Whether this column has been declared as the primary key via the
  /// column builder. The `primaryKey` field in the table class is unrelated to
  /// this.
  final bool declaredAsPrimaryKey;
  final List<ColumnFeature> features;

  String get dartTypeName => {
        ColumnType.boolean: 'bool',
        ColumnType.text: 'String',
        ColumnType.integer: 'int'
      }[type];

  const SpecifiedColumn(
      {this.type,
      this.dartGetterName,
      this.name,
      this.declaredAsPrimaryKey = false,
      this.features = const []});
}

abstract class ColumnFeature {
  const ColumnFeature();
}

class AutoIncrement extends ColumnFeature {
  static const AutoIncrement _instance = AutoIncrement._();

  const AutoIncrement._();

  factory AutoIncrement() => _instance;

  @override
  bool operator ==(other) => other is AutoIncrement;

  @override
  int get hashCode => 1337420;
}

abstract class LimitingTextLength extends ColumnFeature
    implements Built<LimitingTextLength, LimitingTextLengthBuilder> {
  @nullable
  int get minLength;

  @nullable
  int get maxLength;

  LimitingTextLength._();

  factory LimitingTextLength(void updates(LimitingTextLengthBuilder b)) =
      _$LimitingTextLength;

  factory LimitingTextLength.withLength({int min, int max}) =>
      LimitingTextLength((b) => b
        ..minLength = min
        ..maxLength = max);
}

class Reference extends ColumnFeature {
  final SpecifiedColumn referencedColumn;

  const Reference(this.referencedColumn);
}
