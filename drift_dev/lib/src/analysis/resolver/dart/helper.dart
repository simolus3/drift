import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../backend.dart';
import '../../driver/error.dart';
import '../../options.dart';
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
  final InterfaceElement userDefinedSqlType;
  final InterfaceElement typeConverter;
  final InterfaceElement jsonTypeConverter;
  final InterfaceType? driftAny;
  final InterfaceType uint8List;
  final InterfaceType? geopolyPolygon;
  final InterfaceElement? driftColumnDeclarationBuilder;

  KnownDriftTypes._({
    required this.helperLibrary,
    required this.tableElement,
    required this.tableType,
    required this.tableIndexType,
    required this.viewType,
    required this.tableInfoType,
    required this.userDefinedSqlType,
    required this.typeConverter,
    required this.jsonTypeConverter,
    required this.driftDatabase,
    required this.driftAccessor,
    required this.driftAny,
    required this.uint8List,
    required this.geopolyPolygon,
    required this.driftColumnDeclarationBuilder,
  });

  late final TypeChecker? checkDriftColumnDeclarationBuilder =
      switch (driftColumnDeclarationBuilder) {
        null => null,
        final builderClass => TypeChecker.fromStatic(builderClass.thisType),
      };

  /// Constructs the set of known drift types from a helper library, which is
  /// resolved from `package:drift/src/drift_dev_helper.dart`.
  factory KnownDriftTypes._fromLibrary(
    LibraryElement helper,
    LibraryElement? sqliteHelper, {
    bool forDrift3 = false,
  }) {
    final exportNamespace = helper.exportNamespace;
    final tableElement = exportNamespace.get2('Table') as ClassElement;
    final dbElement = exportNamespace.get2('DriftDatabase') as ClassElement;
    final daoElement = exportNamespace.get2('DriftAccessor') as ClassElement;

    // In drift3, SQLite-specific types are exported from another package.
    final sqliteExportNamespace = sqliteHelper?.exportNamespace;

    return KnownDriftTypes._(
      helperLibrary: helper,
      tableElement: tableElement,
      tableType: tableElement.defaultInstantiation,
      tableIndexType:
          (exportNamespace.get2('TableIndex') as InterfaceElement).thisType,
      viewType: (exportNamespace.get2('View') as InterfaceElement).thisType,
      tableInfoType:
          (exportNamespace.get2(forDrift3 ? 'ResultSet' : 'TableInfo')
                  as InterfaceElement)
              .thisType,
      userDefinedSqlType:
          exportNamespace.get2(forDrift3 ? 'SqlType' : 'UserDefinedSqlType')
              as InterfaceElement,
      typeConverter: exportNamespace.get2('TypeConverter') as InterfaceElement,
      jsonTypeConverter:
          exportNamespace.get2('JsonTypeConverter2') as InterfaceElement,
      driftDatabase: dbElement.defaultInstantiation,
      driftAccessor: daoElement.defaultInstantiation,
      driftAny: (sqliteExportNamespace?.get2('DriftAny') as InterfaceElement?)
          ?.defaultInstantiation,
      uint8List: (exportNamespace.get2('Uint8List') as InterfaceElement)
          .defaultInstantiation,
      geopolyPolygon:
          (sqliteExportNamespace?.get2('GeopolyPolygon') as InterfaceElement?)
              ?.defaultInstantiation,
      driftColumnDeclarationBuilder: forDrift3
          ? exportNamespace.get2('DriftColumnDeclarationBuilder')
                as InterfaceElement
          : null,
    );
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `TypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asTypeConverter(DartType type) {
    return type.asInstanceOf(typeConverter);
  }

  InterfaceType? asUserDefinedType(DartType type) {
    return type.asInstanceOf(userDefinedSqlType);
  }

  /// Converts the given Dart [type] into an instantiation of the
  /// `JsonTypeConverter` class from drift.
  ///
  /// Returns `null` if [type] is not a subtype of `TypeConverter`.
  InterfaceType? asJsonTypeConverter(DartType? type) {
    final converter =
        helperLibrary.exportNamespace.get2('JsonTypeConverter2')
            as InterfaceElement;
    return type?.asInstanceOf(converter);
  }

  bool get isStillConsistent {
    try {
      helperLibrary.session.getParsedLibraryByElement(helperLibrary);
      return true;
    } on InconsistentAnalysisException {
      return false;
    }
  }

  static Future<KnownDriftTypes?> resolve(
    DriftOptions options,
    DriftBackend backend,
  ) async {
    if (backend.canReadDart) {
      if (options.drift3Preview) {
        final mainLibrary = await backend.readDart(drift3Uri);
        LibraryElement? sqliteLibrary;

        try {
          sqliteLibrary = await backend.readDart(drift3SqliteUri);
        } on Object {
          // Ignore, no SQLite types then.
        }

        return KnownDriftTypes._fromLibrary(
          mainLibrary,
          sqliteLibrary,
          forDrift3: true,
        );
      } else {
        final library = await backend.readDart(drift2Uri);
        return KnownDriftTypes._fromLibrary(library, library);
      }
    }

    return null;
  }

  static final Uri drift2Uri = Uri.parse(
    'package:drift/src/drift_dev_helper.dart',
  );
  static final Uri drift3Uri = Uri.parse(
    'package:drift/src/drift3_preview/src/drift_dev_helper.dart',
  );
  static final Uri drift3SqliteUri = Uri.parse(
    'package:drift_sqlite/src/drift_dev_helper.dart',
  );
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
  final argument =
      args.arguments.singleWhereOrNull(
            (e) => e is NamedArgument && e.name.lexeme == argName,
          )
          as NamedArgument?;

  return argument?.argumentExpression;
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

  return switch (type.element.library.uri) {
    Uri(scheme: 'package', pathSegments: ['drift' || 'drift3', ...]) => true,
    _ => false,
  };
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
    typeArguments: const [],
    nullabilitySuffix: NullabilitySuffix.none,
  );
}

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element.name : null;
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
    BaseElementResolver resolver,
    List<DriftColumn> columns,
    ClassElement element,
  ) async {
    DartObject? dataClassName;
    DartObject? useRowClass;

    for (final annotation in element.metadata.annotations) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed?.type?.nameIfInterfaceType;

      if (annotationClass == 'DataClassName') {
        dataClassName = computed;
      } else if (annotationClass == 'UseRowClass') {
        useRowClass = computed;
      }
    }

    if (dataClassName != null && useRowClass != null) {
      resolver.reportError(
        DriftAnalysisError.forDartElement(
          element,
          "A table can't be annotated with both @DataClassName and @UseRowClass",
        ),
      );
    }

    var name = dataClassName?.getField('name')!.toStringValue();
    final companionName = dataClassName?.getField('companion')?.toStringValue();
    CustomParentClass? customParentClass;
    ExistingRowClass? existingClass;
    List<AnnotatedDartCode> implementedInterfaces = const [];

    if (dataClassName != null) {
      customParentClass = parseCustomParentClass(
        name,
        dataClassName,
        element,
        resolver,
      );

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
      final typeProvider = element.library.typeProvider;
      final typeSystem = element.library.typeSystem;

      final type = useRowClass
          .getField('type')!
          .extractType(typeProvider, typeSystem);
      final constructorInExistingClass = useRowClass
          .getField('constructor')!
          .toStringValue()!;
      final generateInsertable = useRowClass
          .getField('generateInsertable')!
          .toBoolValue()!;
      final helper = await resolver.resolver.driver.knownTypes;

      if (type is InterfaceType) {
        final found = FoundDartClass(type.element, type.typeArguments);

        existingClass = validateExistingClass(
          columns,
          found,
          constructorInExistingClass,
          generateInsertable,
          resolver,
          helper,
        );

        if (existingClass?.isRecord != true) {
          name = type.element.name!;
        }
      } else if (type is RecordType) {
        existingClass = validateRowClassFromRecordType(
          element,
          columns,
          type,
          generateInsertable,
          resolver,
          helper,
        );
      } else {
        resolver.reportError(
          DriftAnalysisError.forDartElement(
            element,
            'The @UseRowClass annotation must be used with a class',
          ),
        );
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
        final type = getField(
          named.name,
        )?.extractType(typeProvider, typeSystem);
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
