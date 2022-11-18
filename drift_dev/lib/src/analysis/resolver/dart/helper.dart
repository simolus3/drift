import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../../driver/driver.dart';
import '../../results/results.dart';

/// A collection of elements and Dart types important to Drift.
///
/// These types are used to determine whether a given Dart class has drift-
/// specific annotations or whether it defines a table.
class KnownDriftTypes {
  final LibraryElement helperLibrary;
  final ClassElement tableElement;
  final InterfaceType tableType;
  final InterfaceType viewType;
  final InterfaceType tableInfoType;
  final InterfaceType driftDatabase;
  final InterfaceType driftAccessor;
  final InterfaceElement typeConverter;
  final InterfaceElement jsonTypeConverter;

  KnownDriftTypes._(
    this.helperLibrary,
    this.tableElement,
    this.tableType,
    this.viewType,
    this.tableInfoType,
    this.typeConverter,
    this.jsonTypeConverter,
    this.driftDatabase,
    this.driftAccessor,
  );

  /// Constructs the set of known drift types from a helper library, which is
  /// resolved from `package:drift/src/drift_dev_helper.dart`.
  factory KnownDriftTypes._fromLibrary(LibraryElement helper) {
    final exportNamespace = helper.exportNamespace;
    final tableElement = exportNamespace.get('Table') as ClassElement;
    final dbElement = exportNamespace.get('DriftDatabase') as ClassElement;
    final daoElement = exportNamespace.get('DriftAccessor') as ClassElement;

    return KnownDriftTypes._(
      helper,
      tableElement,
      tableElement.defaultInstantiation,
      (exportNamespace.get('View') as InterfaceElement).thisType,
      (exportNamespace.get('TableInfo') as InterfaceElement).thisType,
      exportNamespace.get('TypeConverter') as InterfaceElement,
      exportNamespace.get('JsonTypeConverter2') as InterfaceElement,
      dbElement.defaultInstantiation,
      daoElement.defaultInstantiation,
    );
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    return type.asInstanceOf(typeConverter);
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `JsonTypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asJsonTypeConverter(DartType? type) {
    final converter = helperLibrary.exportNamespace.get('JsonTypeConverter2')
        as InterfaceElement;
    return type?.asInstanceOf(converter);
  }

  static Future<KnownDriftTypes> resolve(DriftAnalysisDriver driver) async {
    final library = await driver.backend
        .readDart(Uri.parse('package:drift/src/drift_dev_helper.dart'));

    return KnownDriftTypes._fromLibrary(library);
  }
}

Expression? returnExpressionOfMethod(MethodDeclaration method) {
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

  final firstComponent = type.element.library.location?.components.first;
  if (firstComponent == null) return false;

  return firstComponent.contains('drift');
}

extension IsFromDrift on Element {
  bool get isFromDefaultTable {
    final parent = enclosingElement;

    return parent is ClassElement &&
        parent.name == 'Table' &&
        isFromDrift(parent.thisType);
  }
}

extension on InterfaceElement {
  InterfaceType get defaultInstantiation => instantiate(
      typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
}

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element.name : null;
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

class DataClassInformation {
  final String enforcedName;
  final AnnotatedDartCode? extending;
  final ExistingRowClass? existingClass;

  DataClassInformation(
    this.enforcedName,
    this.extending,
    this.existingClass,
  );
}
