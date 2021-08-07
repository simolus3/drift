import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:sqlparser/sqlparser.dart';

class TypeConverterHint extends TypeHint {
  final UsedTypeConverter converter;

  TypeConverterHint(this.converter);
}
