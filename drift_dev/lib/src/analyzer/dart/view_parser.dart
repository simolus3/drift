part of 'parser.dart';

/// Parses a [MoorView] from a Dart class.
class ViewParser {
  final DriftDartParser base;

  ViewParser(this.base);

  Future<MoorView?> parseView(
      ClassElement element, List<DriftTable> tables) async {
    final name = await _parseViewName(element);

    final staticReferences = await _parseStaticReferences(element, tables);
    final structure = await _parseSelectStructure(element, staticReferences);
    final columns =
        (await _parseColumns(element, structure, staticReferences)).toList();

    final dataClassInfo = _readDataClassInformation(columns, element);

    return MoorView(
      declaration: DartViewDeclaration(
        element,
        base.step.file,
        structure.primarySource,
        staticReferences,
        structure.dartQuerySource,
      ),
      name: name,
      dartTypeName: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      entityInfoName: '\$${element.name}View',
    )
      ..columns = columns
      ..references = [
        for (final staticRef in staticReferences) staticRef.table,
      ];
  }

  _DataClassInformation _readDataClassInformation(
      List<DriftColumn> columns, ClassElement element) {
    DartObject? useRowClass;
    DartObject? driftView;
    String? customParentClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.nameIfInterfaceType;

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
      final annotationClass = computed!.type!.nameIfInterfaceType;

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

  Future<List<DriftColumn>> _parseColumns(
    ClassElement element,
    _ParsedDartViewSelect structure,
    List<TableReferenceInDartView> references,
  ) async {
    final columns = <DriftColumn>[];

    for (final columnReference in structure.selectedColumns) {
      final parts = columnReference.toSource().split('.');

      // Column reference like `foo.bar`, where `foo` is a table that has been
      // referenced in this view.
      if (parts.length > 1) {
        final reference =
            references.firstWhereOrNull((ref) => ref.name == parts[0]);
        if (reference == null) {
          base.step.reportError(ErrorInDartCode(
            message: 'Table named `${parts[0]}` not found! Maybe not '
                'included in @DriftDatabase or not belongs to this database',
            affectedElement: element,
            affectedNode: columnReference,
          ));
          continue;
        }

        final column = reference.table.columns
            .firstWhere((col) => col.dartGetterName == parts[1]);
        column.table = reference.table;

        columns.add(DriftColumn(
          type: column.type,
          nullable: column.nullable || structure.referenceIsNullable(reference),
          dartGetterName: column.dartGetterName,
          name: column.name,
          generatedAs: ColumnGeneratedAs(
              '${reference.name}.${column.dartGetterName}', false),
          typeConverter: column.typeConverter,
        ));
      } else {
        // Locally-defined column, defined as a getter on this view class.
        final getter = element.thisType.getGetter(parts[0]);

        if (getter == null) {
          base.step.reportError(ErrorInDartCode(
            message: 'This column could not be found in the local view.',
            affectedElement: element,
            affectedNode: columnReference,
          ));
          continue;
        }

        final dartType = (getter.returnType as InterfaceType).typeArguments[0];
        final typeName = dartType.nameIfInterfaceType!;
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
          throw analysisError(base.step, getter, errorMessage);
        }

        final node =
            await base.loadElementDeclaration(getter) as MethodDeclaration;
        final expression = (node.body as ExpressionFunctionBody).expression;

        columns.add(DriftColumn(
          type: sqlType,
          dartGetterName: getter.name,
          name: ColumnName.implicitly(ReCase(getter.name).snakeCase),
          nullable: true,
          generatedAs: ColumnGeneratedAs(expression.toString(), false),
        ));
      }
    }

    return columns;
  }

  DriftSqlType? _dartTypeToColumnType(String name) {
    return const {
      'bool': DriftSqlType.bool,
      'String': DriftSqlType.string,
      'int': DriftSqlType.int,
      'BigInt': DriftSqlType.bigInt,
      'DateTime': DriftSqlType.dateTime,
      'Uint8List': DriftSqlType.blob,
      'double': DriftSqlType.double,
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
            final name = node.name.lexeme;
            return TableReferenceInDartView(type, name);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<_ParsedDartViewSelect> _parseSelectStructure(
    ClassElement element,
    List<TableReferenceInDartView> references,
  ) async {
    final as =
        element.methods.where((method) => method.name == 'as').firstOrNull;

    if (as == null) {
      throw analysisError(
          base.step, element, 'Missing `as()` query declaration');
    }

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

    final innerJoins = <TableReferenceInDartView>[];
    final outerJoins = <TableReferenceInDartView>[];

    // We have something like Query as() => select([...]).from(foo).join(...).
    // First, crawl up so get the `select`:
    Expression? target = body.expression;
    for (;;) {
      if (target is MethodInvocation) {
        if (target.target == null) break;

        final name = target.methodName.toSource();
        if (name == 'join') {
          final joinList = target.argumentList.arguments[0] as ListLiteral;
          for (final entry in joinList.elements) {
            // Do we have something like innerJoin(foo, bar)?
            if (entry is MethodInvocation) {
              final isInnerJoin = entry.methodName.toSource() == 'innerJoin';
              final table = references.firstWhereOrNull((element) =>
                  element.name == entry.argumentList.arguments[0].toSource());

              if (table != null) {
                final list = isInnerJoin ? innerJoins : outerJoins;
                list.add(table);
              }
            }
          }
        }

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

    final columnListLiteral = target.argumentList.arguments[0] as ListLiteral;
    final columnExpressions =
        columnListLiteral.elements.whereType<Expression>().toList();

    target = target.parent as MethodInvocation;
    if (target.methodName.toString() != 'from') {
      throw analysisError(
          base.step,
          element,
          'The `as()` query declaration must be started '
          'with `select(columns).from(table)');
    }

    final from = target.argumentList.arguments[0].toSource();
    final resolvedFrom =
        references.firstWhereOrNull((element) => element.name == from);
    if (resolvedFrom == null) {
      base.step.reportError(
        ErrorInDartCode(
          message: 'Table reference `$from` not found, is it added to this '
              'view as a getter?',
          affectedElement: as,
          affectedNode: target.argumentList,
        ),
      );
    }

    final query =
        body.expression.toString().substring(target.toString().length);

    return _ParsedDartViewSelect(
        resolvedFrom, innerJoins, outerJoins, columnExpressions, query);
  }
}

class _ParsedDartViewSelect {
  final TableReferenceInDartView? primarySource;
  final List<TableReferenceInDartView> innerJoins;
  final List<TableReferenceInDartView> outerJoins;

  final List<Expression> selectedColumns;
  final String dartQuerySource;

  _ParsedDartViewSelect(this.primarySource, this.innerJoins, this.outerJoins,
      this.selectedColumns, this.dartQuerySource);

  bool referenceIsNullable(TableReferenceInDartView ref) {
    return ref != primarySource && !innerJoins.contains(ref);
  }
}
