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

  bool isJsonAwareTypeConverter(DartType? type, LibraryElement context) {
    final jsonMixin =
        helperLibrary.exportNamespace.get('JsonTypeConverter') as ClassElement;
    final jsonConverterType = jsonMixin.instantiate(
      typeArguments: [
        context.typeProvider.dynamicType,
        context.typeProvider.dynamicType
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    return type != null &&
        context.typeSystem.isSubtypeOf(type, jsonConverterType);
  }
}
