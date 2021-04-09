// @dart=2.9
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';

ExistingRowClass /*?*/ validateExistingClass(
    List<MoorColumn> columns, ClassElement desiredClass, ErrorSink errors) {
  final ctor = desiredClass.unnamedConstructor;
  if (ctor == null) {
    errors.report(ErrorInDartCode(
      affectedElement: desiredClass,
      message: 'The desired data class must have an unnamed constructor',
    ));
    return null;
  }

  final unmatchedColumnsByName = {
    for (final column in columns) column.dartGetterName: column
  };

  final columnsToParameter = <MoorColumn, ParameterElement>{};

  for (final parameter in ctor.parameters) {
    final column = unmatchedColumnsByName.remove(parameter.name);
    if (column != null) {
      columnsToParameter[column] = parameter;
    } else if (!parameter.isOptional) {
      errors.report(ErrorInDartCode(
        affectedElement: parameter,
        message: 'Unexpected parameter ${parameter.name} which has no matching '
            'column.',
      ));
    }
  }

  return ExistingRowClass(desiredClass, ctor, columnsToParameter);
}
