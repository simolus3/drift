import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../driver/driver.dart';

class KnownDriftTypes {
  final ClassElement tableElement;
  final InterfaceType tableType;

  KnownDriftTypes._(this.tableElement, this.tableType);

  /// Constructs the set of known drift types from a helper library, which is
  /// resolved from `package:drift/drift_dev_helper.dart`.
  factory KnownDriftTypes._fromLibrary(LibraryElement helper) {
    final exportNamespace = helper.exportNamespace;
    final tableElement = exportNamespace.get('Table') as ClassElement;

    return KnownDriftTypes._(
      tableElement,
      tableElement.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  static Future<KnownDriftTypes> resolve(DriftAnalysisDriver driver) async {
    final library = await driver.backend
        .readDart(Uri.parse('package:drift/src/drift_dev_helper.dart'));

    return KnownDriftTypes._fromLibrary(library);
  }
}

Expression? returnExpressionOfMethod(MethodDeclaration method,
    {bool reportErrorOnFailure = true}) {
  final body = method.body;

  if (body is! ExpressionFunctionBody) {
    return null;
  }

  return body.expression;
}

bool isFromDrift(DartType type) {
  if (type is! InterfaceType) return false;

  final firstComponent = type.element2.library.location?.components.first;
  if (firstComponent == null) return false;

  return firstComponent.contains('drift');
}

extension IsFromDrift on Element {
  bool get isFromDefaultTable {
    final parent = enclosingElement3;

    return parent is ClassElement &&
        parent.name == 'Table' &&
        isFromDrift(parent.thisType);
  }
}
