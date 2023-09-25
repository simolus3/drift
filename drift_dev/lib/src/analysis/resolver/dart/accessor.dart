import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import 'helper.dart';

class DartAccessorResolver
    extends LocalElementResolver<DiscoveredBaseAccessor> {
  DartAccessorResolver(
      super.file, super.discovered, super.resolver, super.state);

  @override
  Future<BaseDriftAccessor> resolve() async {
    final tables = <DriftTable>[];
    final views = <DriftView>[];
    final includes = <Uri>[];
    final queries = <QueryOnAccessor>[];

    final annotation = discovered.annotation;
    final element = discovered.dartElement;

    List<DartObject> readList(String name) {
      final rawTablesOrNull = annotation.getField(name)?.toListValue();
      if (rawTablesOrNull == null) {
        final annotationName =
            annotation.type?.nameIfInterfaceType ?? 'DriftDatabase';

        reportError(DriftAnalysisError.forDartElement(
          element,
          'Could not read $name from @$annotationName annotation! \n'
          'Please make sure that all table classes exist.',
        ));

        return const [];
      } else {
        return rawTablesOrNull;
      }
    }

    for (final tableType in readList('tables')) {
      final dartType = tableType.toTypeValue();

      if (dartType is! InterfaceType) {
        reportError(
          DriftAnalysisError.forDartElement(
            element,
            'Could not read table from '
            '`${dartType?.getDisplayString(withNullability: true)}`, it needs '
            'to reference a table class.',
          ),
        );
        continue;
      }

      final table = await resolveDartReferenceOrReportError<DriftTable>(
          dartType.element,
          (msg) => DriftAnalysisError.forDartElement(element, msg));
      if (table != null) {
        tables.add(table);
      }
    }

    for (final viewType in readList('views')) {
      final dartType = viewType.toTypeValue();

      if (dartType is! InterfaceType) {
        reportError(
          DriftAnalysisError.forDartElement(
            element,
            'Could not read view from '
            '`${dartType?.getDisplayString(withNullability: true)}`, it needs '
            'to reference a view class.',
          ),
        );
        continue;
      }

      final view = await resolveDartReferenceOrReportError<DriftView>(
          dartType.element,
          (msg) => DriftAnalysisError.forDartElement(element, msg));
      if (view != null) {
        views.add(view);
      }
    }

    for (final include in annotation.getField('include')!.toSetValue()!) {
      final value = include.toStringValue()!;
      final import = Uri.tryParse(value);

      if (import == null) {
        reportError(
          DriftAnalysisError.forDartElement(
              element, '`$value` is not a valid URI to include'),
        );
      } else {
        includes.add(import);

        final resolved = await resolver.driver
            .findLocalElements(discovered.ownId.libraryUri.resolveUri(import));
        if (!resolved.isValidImport) {
          reportError(
            DriftAnalysisError.forDartElement(
                element, '`$value` could not be imported'),
          );
        }
      }
    }

    final rawQueries = annotation.getField('queries')!.toMapValue()!;
    rawQueries.forEach((key, value) {
      final keyStr = key!.toStringValue()!;
      final valueStr = value!.toStringValue()!;

      queries.add(QueryOnAccessor(keyStr, valueStr));
    });

    final declaration = DriftDeclaration.dartElement(element);
    if (discovered.isDatabase) {
      final accessors = <DatabaseAccessor>[];
      final rawDaos = annotation.getField('daos')!.toListValue()!;
      for (final value in rawDaos) {
        final type = value.toTypeValue()!;

        if (type is! InterfaceType) {
          reportError(
            DriftAnalysisError.forDartElement(
              element,
              'Could not read referenced DAO from '
              '`$type?.getDisplayString(withNullability: true)}`, it needs '
              'to reference an accessor class.',
            ),
          );
          continue;
        }

        final dao = await resolveDartReferenceOrReportError<DatabaseAccessor>(
            type.element,
            (msg) => DriftAnalysisError.forDartElement(element, msg));
        if (dao != null) accessors.add(dao);
      }

      return DriftDatabase(
        id: discovered.ownId,
        declaration: declaration,
        declaredTables: tables,
        declaredViews: views,
        declaredIncludes: includes,
        declaredQueries: queries,
        schemaVersion: await _readSchemaVersion(),
        accessors: accessors,
      );
    } else {
      final dbType = element.allSupertypes
          .firstWhereOrNull((i) => i.element.name == 'DatabaseAccessor');

      // inherits from DatabaseAccessor<T>, we want to know which T

      final dbImpl = dbType?.typeArguments.single ??
          element.library.typeProvider.dynamicType;
      if (dbImpl is DynamicType) {
        reportError(DriftAnalysisError.forDartElement(
          element,
          'This class must inherit from DatabaseAccessor<T>, where T is an '
          'actual type of a database.',
        ));
      }

      return DatabaseAccessor(
        id: discovered.ownId,
        declaration: declaration,
        declaredTables: tables,
        declaredViews: views,
        declaredIncludes: includes,
        declaredQueries: queries,
        ownType: AnnotatedDartCode.type(element.thisType),
        databaseClass: AnnotatedDartCode.type(dbImpl),
      );
    }
  }

  Future<int?> _readSchemaVersion() async {
    final element =
        discovered.dartElement.thisType.getGetter('schemaVersion')?.variable;
    if (element == null) return null;

    try {
      if (element.isSynthetic) {
        // Getter, read from `=>` body if possible.
        final expr = returnExpressionOfMethod(await resolver.driver.backend
            .loadElementDeclaration(element.getter!) as MethodDeclaration);
        if (expr is IntegerLiteral) {
          return expr.value;
        }
      } else {
        final astField = await resolver.driver.backend
            .loadElementDeclaration(element) as VariableDeclaration;
        if (astField.initializer is IntegerLiteral) {
          return (astField.initializer as IntegerLiteral).value;
        }
      }
    } catch (e, s) {
      resolver.driver.backend.log
          .warning('Could not read schemaVersion from $element', e, s);
    }
    return null;
  }
}
