part of 'parser.dart';

/// Parses a [MoorView] from a Dart class.
class ViewParser {
  final DriftDartParser base;

  ViewParser(this.base);

  Future<MoorView?> parseView(
      ClassElement element, List<DriftTable> tables) async {
    final name = await _parseViewName(element);
    final columns = (await _parseColumns(element)).toList();
    final staticReferences = await _parseStaticReferences(element, tables);
    final dataClassInfo = _readDataClassInformation(columns, element);
    final query = await _parseQuery(element, staticReferences, columns);

    final view = MoorView(
      declaration:
          DartViewDeclaration(element, base.step.file, staticReferences),
      name: name,
      dartTypeName: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      entityInfoName: '\$${element.name}View',
      viewQuery: query,
    );

    view.references = [
      for (final staticRef in staticReferences) staticRef.table,
    ];

    view.columns = columns;
    return view;
  }

  _DataClassInformation _readDataClassInformation(
      List<DriftColumn> columns, ClassElement element) {
    DartObject? useRowClass;
    DartObject? driftView;
    String? customParentClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.element!.name;

      if (annotationClass == 'DriftView') {
        driftView = computed;
      } else if (annotationClass == 'UseRowClass') {
        useRowClass = computed;
      }
    }

    if (driftView != null && useRowClass != null) {
      base.step.reportError(ErrorInDartCode(
        message: "A table can't be annotated with both @DataClassName and "
            '@UseRowClass',
        affectedElement: element,
      ));
    }

    FoundDartClass? existingClass;
    String? constructorInExistingClass;
    bool? generateInsertable;

    var name = dataClassNameForClassName(element.name);

    if (driftView != null) {
      final dataClassName =
          driftView.getField('dataClassName')?.toStringValue();
      name = dataClassName ?? dataClassNameForClassName(element.name);
      customParentClass =
          parseCustomParentClass(name, driftView, element, base);
    }

    if (useRowClass != null) {
      final type = useRowClass.getField('type')!.toTypeValue();
      constructorInExistingClass =
          useRowClass.getField('constructor')!.toStringValue()!;
      generateInsertable =
          useRowClass.getField('generateInsertable')!.toBoolValue()!;

      if (type is InterfaceType) {
        existingClass = FoundDartClass(type.element, type.typeArguments);
        name = type.element.name;
      } else {
        base.step.reportError(ErrorInDartCode(
          message: 'The @UseRowClass annotation must be used with a class',
          affectedElement: element,
        ));
      }
    }

    final verified = existingClass == null
        ? null
        : validateExistingClass(columns, existingClass,
            constructorInExistingClass!, generateInsertable!, base.step);
    return _DataClassInformation(name, customParentClass, verified);
  }

  Future<String> _parseViewName(ClassElement element) async {
    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.element!.name;

      if (annotationClass == 'DriftView') {
        final name = computed.getField('name')?.toStringValue();
        if (name != null) {
          return name;
        }
        break;
      }
    }

    return ReCase(element.name).snakeCase;
  }

  Future<Iterable<DriftColumn>> _parseColumns(ClassElement element) async {
    final columnNames = element.allSupertypes
        .map((t) => t.element)
        .followedBy([element])
        .expand((e) => e.fields)
        .where((field) =>
            (isExpression(field.type) || isColumn(field.type)) &&
            field.getter != null &&
            !field.getter!.isSynthetic)
        .map((field) => field.name)
        .toSet();

    final fields = columnNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      return getter!.variable;
    }).toList();

    final results = await Future.wait(fields.map((field) async {
      final dartType = (field.type as InterfaceType).typeArguments[0];
      final typeName = dartType.element!.name!;
      final sqlType = _dartTypeToColumnType(typeName);

      if (sqlType == null) {
        final String errorMessage;
        if (typeName == 'dynamic') {
          errorMessage = 'You must specify Expression<> type argument';
        } else {
          errorMessage =
              'Invalid Expression<> type argument `$typeName` found. '
              'Must be one of: '
              'bool, String, int, DateTime, Uint8List, double';
        }
        throw analysisError(base.step, field, errorMessage);
      }

      final node =
          await base.loadElementDeclaration(field.getter!) as MethodDeclaration;
      final expression = (node.body as ExpressionFunctionBody).expression;

      return DriftColumn(
        type: sqlType,
        dartGetterName: field.name,
        name: ColumnName.implicitly(ReCase(field.name).snakeCase),
        nullable: dartType.nullabilitySuffix == NullabilitySuffix.question,
        generatedAs: ColumnGeneratedAs(expression.toString(), false),
      );
    }).toList());

    return results.whereType();
  }

  ColumnType? _dartTypeToColumnType(String name) {
    return const {
      'bool': ColumnType.boolean,
      'String': ColumnType.text,
      'int': ColumnType.integer,
      'BigInt': ColumnType.bigInt,
      'DateTime': ColumnType.datetime,
      'Uint8List': ColumnType.blob,
      'double': ColumnType.real,
    }[name];
  }

  Future<List<TableReferenceInDartView>> _parseStaticReferences(
      ClassElement element, List<DriftTable> tables) async {
    return await Stream.fromIterable(element.allSupertypes
            .map((t) => t.element)
            .followedBy([element]).expand((e) => e.fields))
        .asyncMap((field) => _getStaticReference(field, tables))
        .where((ref) => ref != null)
        .cast<TableReferenceInDartView>()
        .toList();
  }

  Future<TableReferenceInDartView?> _getStaticReference(
      FieldElement field, List<DriftTable> tables) async {
    if (field.getter != null) {
      try {
        final node = await base.loadElementDeclaration(field.getter!);
        if (node is MethodDeclaration && node.body is EmptyFunctionBody) {
          final type = tables.firstWhereOrNull(
              (tbl) => tbl.fromClass!.name == node.returnType.toString());
          if (type != null) {
            final name = node.name.toString();
            return TableReferenceInDartView(type, name);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<ViewQueryInformation> _parseQuery(
      ClassElement element,
      List<TableReferenceInDartView> references,
      List<DriftColumn> columns) async {
    final as =
        element.methods.where((method) => method.name == 'as').firstOrNull;

    if (as != null) {
      try {
        final node = await base.loadElementDeclaration(as);

        final body = (node as MethodDeclaration).body;
        if (body is! ExpressionFunctionBody) {
          throw analysisError(
            base.step,
            element,
            'The `as()` query declaration must be an expression (=>). '
            'Block function body `{ return x; }` not acceptable.',
          );
        }

        Expression? target = body.expression;
        for (;;) {
          if (target is MethodInvocation) {
            if (target.target == null) break;
            target = target.target;
          } else if (target is CascadeExpression) {
            target = target.target;
          } else {
            throw analysisError(
                base.step,
                element,
                'The `as()` query declaration contains invalid expression type '
                '${target.runtimeType}');
          }
        }

        if (target.methodName.toString() != 'select') {
          throw analysisError(
              base.step,
              element,
              'The `as()` query declaration must be started '
              'with `select(columns).from(table)');
        }

        final columnListLiteral =
            target.argumentList.arguments[0] as ListLiteral;
        final columnList =
            columnListLiteral.elements.map((col) => col.toString()).map((col) {
          final parts = col.split('.');
          if (parts.length > 1) {
            final reference =
                references.firstWhereOrNull((ref) => ref.name == parts[0]);
            if (reference == null) {
              throw analysisError(
                  base.step,
                  element,
                  'Table named `${parts[0]}` not found! Maybe not included in '
                  '@DriftDatabase or not belongs to this database');
            }
            final column = reference.table.columns
                .firstWhere((col) => col.dartGetterName == parts[1]);
            column.table = reference.table;
            return MapEntry(
                '${reference.name}.${column.dartGetterName}', column);
          }
          final column =
              columns.firstWhere((col) => col.dartGetterName == parts[0]);
          return MapEntry('${column.dartGetterName}', column);
        }).toList();

        target = target.parent as MethodInvocation;
        if (target.methodName.toString() != 'from') {
          throw analysisError(
              base.step,
              element,
              'The `as()` query declaration must be started '
              'with `select(columns).from(table)');
        }

        final from = target.argumentList.arguments[0].toString();
        final query =
            body.expression.toString().substring(target.toString().length);

        return ViewQueryInformation(columnList, from, query);
      } catch (e) {
        print(e);
        throw analysisError(
            base.step, element, 'Failed to parse view `as()` query');
      }
    }

    throw analysisError(base.step, element, 'Missing `as()` query declaration');
  }
}
