import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../../driver/driver.dart';

class KnownDriftTypes {
  final ClassElement tableElement;
  final InterfaceType tableType;
  final InterfaceElement typeConverter;
  final InterfaceElement jsonTypeConverter;

  KnownDriftTypes._(
    this.tableElement,
    this.tableType,
    this.typeConverter,
    this.jsonTypeConverter,
  );

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
      exportNamespace.get('TypeConverter') as InterfaceElement,
      exportNamespace.get('JsonTypeConverter') as InterfaceElement,
    );
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    return type.asInstanceOf(typeConverter);
  }

  bool isJsonAwareTypeConverter(DartType? type, LibraryElement context) {
    final jsonConverterType = jsonTypeConverter.instantiate(
      typeArguments: [
        context.typeProvider.dynamicType,
        context.typeProvider.dynamicType
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    return type != null &&
        context.typeSystem.isSubtypeOf(type, jsonConverterType);
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

String? readStringLiteral(Expression expression) {
  if (expression is StringLiteral) {
    final value = expression.stringValue;
    if (value != null) {
      return value;
    }
  }

  return null;
}

int? readIntLiteral(Expression expression) {
  if (expression is IntegerLiteral) {
    return expression.value;
  } else {
    return null;
  }
}

Expression? findNamedArgument(ArgumentList args, String argName) {
  final argument = args.arguments.singleWhereOrNull(
    (e) => e is NamedExpression && e.name.label.name == argName,
  ) as NamedExpression?;

  return argument?.expression;
}

bool isColumn(DartType type) {
  final name = type.nameIfInterfaceType;

  return isFromDrift(type) &&
      name != null &&
      name.contains('Column') &&
      !name.contains('Builder');
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

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element2.name : null;
  }

  String get userVisibleName => getDisplayString(withNullability: true);

  /// How this type should look like in generated code.
  String codeString() {
    if (nullabilitySuffix == NullabilitySuffix.star) {
      // We can't actually use the legacy star in code, so don't show it.
      return getDisplayString(withNullability: false);
    }

    return getDisplayString(withNullability: true);
  }
}
