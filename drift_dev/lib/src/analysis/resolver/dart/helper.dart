import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';

import '../../backend.dart';
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
  final LibraryElement2 helperLibrary;
  final ClassElement2 tableElement;
  final InterfaceType tableType;
  final InterfaceType tableIndexType;
  final InterfaceType viewType;
  final InterfaceType tableInfoType;
  final InterfaceType driftDatabase;
  final InterfaceType driftAccessor;
  final InterfaceElement2 userDefinedSqlType;
  final InterfaceElement2 typeConverter;
  final InterfaceElement2 jsonTypeConverter;
  final InterfaceType driftAny;
  final InterfaceType uint8List;
  final InterfaceType geopolyPolygon;

  KnownDriftTypes._(
    this.helperLibrary,
    this.tableElement,
    this.tableType,
    this.tableIndexType,
    this.viewType,
    this.tableInfoType,
    this.userDefinedSqlType,
    this.typeConverter,
    this.jsonTypeConverter,
    this.driftDatabase,
    this.driftAccessor,
    this.driftAny,
    this.uint8List,
    this.geopolyPolygon,
  );

  /// Constructs the set of known drift types from a helper library, which is
  /// resolved from `package:drift/src/drift_dev_helper.dart`.
  factory KnownDriftTypes._fromLibrary(LibraryElement2 helper) {
    final exportNamespace = helper.exportNamespace;
    final tableElement = exportNamespace.get2('Table') as ClassElement2;
    final dbElement = exportNamespace.get2('DriftDatabase') as ClassElement2;
    final daoElement = exportNamespace.get2('DriftAccessor') as ClassElement2;

    return KnownDriftTypes._(
      helper,
      tableElement,
      tableElement.defaultInstantiation,
      (exportNamespace.get2('TableIndex') as InterfaceElement2).thisType,
      (exportNamespace.get2('View') as InterfaceElement2).thisType,
      (exportNamespace.get2('TableInfo') as InterfaceElement2).thisType,
      exportNamespace.get2('UserDefinedSqlType') as InterfaceElement2,
      exportNamespace.get2('TypeConverter') as InterfaceElement2,
      exportNamespace.get2('JsonTypeConverter2') as InterfaceElement2,
      dbElement.defaultInstantiation,
      daoElement.defaultInstantiation,
      (exportNamespace.get2('DriftAny') as InterfaceElement2)
          .defaultInstantiation,
      (exportNamespace.get2('Uint8List') as InterfaceElement2)
          .defaultInstantiation,
      (exportNamespace.get2('GeopolyPolygon') as InterfaceElement2)
          .defaultInstantiation,
    );
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    return type.asInstanceOf2(typeConverter);
  }

  InterfaceType? asUserDefinedType(DartType type) {
    return type.asInstanceOf2(userDefinedSqlType);
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `JsonTypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asJsonTypeConverter(DartType? type) {
    final converter = helperLibrary.exportNamespace.get2('JsonTypeConverter2')
        as InterfaceElement2;
    return type?.asInstanceOf2(converter);
  }

  bool get isStillConsistent {
    try {
      helperLibrary.session.getParsedLibraryByElement2(helperLibrary);
      return true;
    } on InconsistentAnalysisException {
      return false;
    }
  }

  static Future<KnownDriftTypes?> resolve(DriftBackend backend) async {
    if (backend.canReadDart) {
      final library = await backend.readDart(uri);

      return KnownDriftTypes._fromLibrary(library);
    }

    return null;
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

bool isColumnBuilder(DartType type) {
  final name = type.nameIfInterfaceType;

  return isFromDrift(type) &&
      name != null &&
      name.contains('Column') &&
      name.contains('Builder');
}

bool isFromDrift(DartType type) {
  if (type is! InterfaceType) return false;

  final uri = type.element3.library2.uri;
  return uri.scheme == 'package' && uri.pathSegments[0] == 'drift';
}

extension IsFromDrift on Element2 {
  bool get isFromDefaultTable {
    final parent = enclosingElement2;

    return parent is ClassElement2 &&
        parent.name3 == 'Table' &&
        isFromDrift(parent.thisType);
  }

  List<ElementAnnotation> get metadataIfAnnotatable {
    return switch (this) {
      final Annotatable a => a.metadata2.annotations,
      _ => const [],
    };
  }
}

extension LookupConstructor2 on InterfaceType {
  ConstructorElement2? lookUpConstructor2(
      String? name, LibraryElement2 library) {
    return switch (name) {
      null => element3.unnamedConstructor2,
      var name => element3.getNamedConstructor2(name),
    };
  }
}

extension on InterfaceElement2 {
  InterfaceType get defaultInstantiation => instantiate(
      typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
}

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element3.name3 : null;
  }

  String get userVisibleName => getDisplayString();

  /// How this type should look like in generated code.
  String codeString() {
    if (nullabilitySuffix == NullabilitySuffix.star) {
      // We can't actually use the legacy star in code, so don't show it.
      return getDisplayString();
    }
    return getDisplayString();
  }
}

class DataClassInformation {
  final String? enforcedName;
  final String? companionName;
  final CustomParentClass? extending;
  final ExistingRowClass? existingClass;
  final List<AnnotatedDartCode> interfaces;

  DataClassInformation(
    this.enforcedName,
    this.companionName,
    this.extending,
    this.existingClass,
    this.interfaces,
  );

  static Future<DataClassInformation> resolve(
    LocalElementResolver resolver,
    List<DriftColumn> columns,
    ClassElement2 element,
  ) async {
    DartObject? dataClassName;
    DartObject? useRowClass;

    for (final annotation in element.metadata2.annotations) {
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

    var name = dataClassName?.getField('name')!.toStringValue();
    final companionName = dataClassName?.getField('companion')?.toStringValue();
    CustomParentClass? customParentClass;
    ExistingRowClass? existingClass;
    List<AnnotatedDartCode> implementedInterfaces = const [];

    if (dataClassName != null) {
      customParentClass =
          parseCustomParentClass(name, dataClassName, element, resolver);

      final interfaces = dataClassName
          .getField('implementing')
          ?.toListValue()
          ?.map((field) => AnnotatedDartCode.type(field.toTypeValue()!))
          .toList();
      if (interfaces != null) {
        implementedInterfaces = interfaces;
      }
    }

    if (useRowClass != null) {
      final typeProvider = element.library2.typeProvider;
      final typeSystem = element.library2.typeSystem;

      final type =
          useRowClass.getField('type')!.extractType(typeProvider, typeSystem);
      final constructorInExistingClass =
          useRowClass.getField('constructor')!.toStringValue()!;
      final generateInsertable =
          useRowClass.getField('generateInsertable')!.toBoolValue()!;
      final helper = await resolver.resolver.driver.knownTypes;

      if (type is InterfaceType) {
        final found = FoundDartClass(type.element3, type.typeArguments);

        existingClass = validateExistingClass(columns, found,
            constructorInExistingClass, generateInsertable, resolver, helper);

        if (existingClass?.isRecord != true) {
          name = type.element3.name3;
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

    return DataClassInformation(
      name,
      companionName,
      customParentClass,
      existingClass,
      implementedInterfaces,
    );
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
