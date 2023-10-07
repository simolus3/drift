import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';

import '../../driver/driver.dart';
import '../../driver/error.dart';
import '../../results/results.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';
import '../shared/data_class.dart';

/// A collection of elements and Dart types important to Drift.
///
/// These types are used to determine whether a given Dart class has drift-
/// specific annotations or whether it defines a table.
class KnownDriftTypes {
  final LibraryElement helperLibrary;
  final ClassElement tableElement;
  final InterfaceType tableType;
  final InterfaceType tableIndexType;
  final InterfaceType viewType;
  final InterfaceType tableInfoType;
  final InterfaceType driftDatabase;
  final InterfaceType driftAccessor;
  final InterfaceElement customSqlType;
  final InterfaceElement typeConverter;
  final InterfaceElement jsonTypeConverter;
  final InterfaceType driftAny;
  final InterfaceType uint8List;

  KnownDriftTypes._(
    this.helperLibrary,
    this.tableElement,
    this.tableType,
    this.tableIndexType,
    this.viewType,
    this.tableInfoType,
    this.customSqlType,
    this.typeConverter,
    this.jsonTypeConverter,
    this.driftDatabase,
    this.driftAccessor,
    this.driftAny,
    this.uint8List,
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
      (exportNamespace.get('TableIndex') as InterfaceElement).thisType,
      (exportNamespace.get('View') as InterfaceElement).thisType,
      (exportNamespace.get('TableInfo') as InterfaceElement).thisType,
      exportNamespace.get('CustomSqlType') as InterfaceElement,
      exportNamespace.get('TypeConverter') as InterfaceElement,
      exportNamespace.get('JsonTypeConverter2') as InterfaceElement,
      dbElement.defaultInstantiation,
      daoElement.defaultInstantiation,
      (exportNamespace.get('DriftAny') as InterfaceElement)
          .defaultInstantiation,
      (exportNamespace.get('Uint8List') as InterfaceElement)
          .defaultInstantiation,
    );
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    return type.asInstanceOf(typeConverter);
  }

  InterfaceType? asCustomType(DartType type) {
    return type.asInstanceOf(customSqlType);
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
    final library = await driver.backend.readDart(uri);

    return KnownDriftTypes._fromLibrary(library);
  }

  static final Uri uri = Uri.parse('package:drift/src/drift_dev_helper.dart');
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

  static Future<DataClassInformation> resolve(
    LocalElementResolver resolver,
    List<DriftColumn> columns,
    ClassElement element,
  ) async {
    DartObject? dataClassName;
    DartObject? useRowClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed?.type?.nameIfInterfaceType;

      if (annotationClass == 'DataClassName') {
        dataClassName = computed;
      } else if (annotationClass == 'UseRowClass') {
        useRowClass = computed;
      }
    }

    if (dataClassName != null && useRowClass != null) {
      resolver.reportError(DriftAnalysisError.forDartElement(
        element,
        "A table can't be annotated with both @DataClassName and @UseRowClass",
      ));
    }

    String name;
    AnnotatedDartCode? customParentClass;
    ExistingRowClass? existingClass;

    if (dataClassName != null) {
      name = dataClassName.getField('name')!.toStringValue()!;
      customParentClass =
          parseCustomParentClass(name, dataClassName, element, resolver);
    } else {
      name = dataClassNameForClassName(element.name);
    }

    if (useRowClass != null) {
      final typeProvider = element.library.typeProvider;
      final typeSystem = element.library.typeSystem;

      final type =
          useRowClass.getField('type')!.extractType(typeProvider, typeSystem);
      final constructorInExistingClass =
          useRowClass.getField('constructor')!.toStringValue()!;
      final generateInsertable =
          useRowClass.getField('generateInsertable')!.toBoolValue()!;
      final helper = await resolver.resolver.driver.loadKnownTypes();

      if (type is InterfaceType) {
        final found = FoundDartClass(type.element, type.typeArguments);

        existingClass = validateExistingClass(columns, found,
            constructorInExistingClass, generateInsertable, resolver, helper);

        if (existingClass?.isRecord != true) {
          name = type.element.name;
        }
      } else if (type is RecordType) {
        existingClass = validateRowClassFromRecordType(
            element, columns, type, generateInsertable, resolver, helper);
      } else {
        resolver.reportError(DriftAnalysisError.forDartElement(
          element,
          'The @UseRowClass annotation must be used with a class',
        ));
      }
    }

    return DataClassInformation(name, customParentClass, existingClass);
  }
}

extension on DartObject {
  DartType? extractType(TypeProvider typeProvider, TypeSystem typeSystem) {
    final typeValue = toTypeValue();
    if (typeValue != null) {
      if (typeValue.nullabilitySuffix == NullabilitySuffix.star) {
        // For some reason the analyzer adds the star suffix on type literals,
        // we definitely want to remove it.
        return typeSystem.promoteToNonNull(typeValue);
      }

      return typeValue;
    }

    // Dart doesn't have record type literals, so if one writes
    // `(int, String, x: bool)`, that's actually a record with the given type
    // literals as fields. We need to reconstruct a record type out of that.
    final type = this.type;
    if (type != null && type is RecordType) {
      // todo: Use public API after https://dart-review.googlesource.com/c/sdk/+/277401
      final positionalFields = <DartType>[];
      final namedFields = <String, DartType>{};

      for (var i = 0; i < type.positionalFields.length; i++) {
        final type = getField('\$$i')?.extractType(typeProvider, typeSystem);
        if (type == null) return null;

        positionalFields.add(type);
      }

      for (final named in type.namedFields) {
        final type =
            getField(named.name)?.extractType(typeProvider, typeSystem);
        if (type == null) return null;

        namedFields[named.name] = type;
      }

      return typeProvider.createRecordType(
        positional: positionalFields,
        named: namedFields.entries.toList(),
      );
    }

    return null;
  }
}
