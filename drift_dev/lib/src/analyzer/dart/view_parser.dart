part of 'parser.dart';

class ViewParser {
  static SqlEngine? _sqlEngine;

  Future<List<MoorView>?> parseView(ClassElement element,
      List<MoorColumn> columns, String tableName, MoorDartParser base) async {
    final viewsGetter = element.lookUpGetter('views', element.library);

    if (viewsGetter == null || viewsGetter.isFromDefaultTable) {
      return null;
    }

    final ast =
        await base.loadElementDeclaration(viewsGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      base.step.reportError(ErrorInDartCode(
          affectedElement: viewsGetter,
          message: 'This must return a list literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedViews = <MoorView>[];

    if (expression is ListLiteral) {
      for (final entry in expression.elements) {
        if (entry is MethodInvocation) {
          final sqlEngine = _sqlEngine ??= base.step.task.session.spawnEngine();

          final args = entry.argumentList.arguments;
          if (args.length != 2) {
            base.step.reportError(ErrorInDartCode(
                affectedElement: viewsGetter,
                message: args.isEmpty
                    ? 'You must provide columns or sql parameter in view'
                    : 'Provide only one (columns or sql) parameter in view!'));
            return null;
          }

          String viewName;
          ExistingRowClass? rowClass;

          if (args[0] is SimpleStringLiteral) {
            viewName = (args[0] as SimpleStringLiteral).value.pascalCase;
          } else {
            final foundElement = (args[0] as SimpleIdentifier).staticElement;
            FoundDartClass? clazz;

            if (foundElement is ClassElement) {
              clazz = FoundDartClass(foundElement, null);
            } else if (foundElement is TypeAliasElement) {
              final innerType = foundElement.aliasedType;
              if (innerType is InterfaceType) {
                clazz =
                    FoundDartClass(innerType.element, innerType.typeArguments);
              }
            }

            if (clazz == null) {
              base.step.reportError(ErrorInDartCode(
                  affectedElement: viewsGetter, message: 'Invalid dart type'));
              return null;
            } else {
              rowClass = validateExistingClass(
                  columns, clazz, '', false, base.step.errors);
              if (rowClass == null) {
                return null;
              }
              viewName = rowClass.targetClass.name;
            }
          }

          final viewColumnList =
              (args[1] as NamedExpression).expression as ListLiteral;
          final viewColumnNames =
              viewColumnList.elements.cast<SimpleIdentifier>();
          final viewColumns = viewColumnNames
              .map((entry) => columns
                  .singleWhere((column) => column.dartGetterName == entry.name))
              .toList();

          final joinedColumns = viewColumns
              .where((c) => c.virtualSql == null)
              .map((e) => e.name.name)
              .join(', ');

          final sql =
              'CREATE VIEW ${viewName.snakeCase} AS SELECT $joinedColumns '
              'FROM $tableName';
          final parseResult = sqlEngine.parse(sql);
          final stmt = parseResult.rootNode as CreateViewStatement;

          final view = MoorView(
            declaration: MoorViewDeclaration(stmt, base.step.file),
            name: viewName.snakeCase,
            tableName: tableName,
            dartTypeName: viewName.pascalCase,
            entityInfoName: '${viewName}View'.pascalCase,
            existingRowClass: rowClass,
            virtual: true,
          );

          view.columns = viewColumns;
          parsedViews.add(view);
        } else {
          print('Unexpected entry in expression.elements: $entry');
        }
      }
      return parsedViews;
    } else {
      base.step.reportError(ErrorInDartCode(
          affectedElement: viewsGetter,
          message: 'This must return a list literal!'));
    }

    return null;
  }
}
