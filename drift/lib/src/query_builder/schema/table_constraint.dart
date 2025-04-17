import '../compiler.dart';
import 'package:meta/meta.dart';

@immutable
abstract base class TableConstraint implements SqlComponent {
  const TableConstraint._();
}
