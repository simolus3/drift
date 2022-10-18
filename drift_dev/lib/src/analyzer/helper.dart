import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../backends/backend.dart';

/// Utils that read `package:drift/src/drift_dev_helper.dart`
class HelperLibrary {
  final LibraryElement helperLibrary;

  HelperLibrary(this.helperLibrary);

  static Future<HelperLibrary> resolveWith(BackendTask task) async {
    final lib = await task
        .resolveDart(Uri.parse('package:drift/src/drift_dev_helper.dart'));
    return HelperLibrary(lib);
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    final converter =
        helperLibrary.exportNamespace.get('TypeConverter') as InterfaceElement;
    return type.asInstanceOf(converter);
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `JsonTypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asJsonTypeConverter(DartType type) {
    final converter = helperLibrary.exportNamespace.get('JsonTypeConverter2')
        as InterfaceElement;
    return type.asInstanceOf(converter);
  }

  bool isJsonAwareTypeConverter(DartType? type, LibraryElement context) {
    final jsonMixin = helperLibrary.exportNamespace.get('JsonTypeConverter2')
        as InterfaceElement;
    final jsonConverterType = jsonMixin.instantiate(
      typeArguments: [
        context.typeProvider.dynamicType,
        context.typeProvider.dynamicType,
        context.typeProvider.dynamicType,
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    return type != null &&
        context.typeSystem.isSubtypeOf(type, jsonConverterType);
  }
}
