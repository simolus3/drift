// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:drift_dev/src/analysis/results/results.dart';

import '../annotation.dart';
import 'query_provider.dart';

final class DriftRiverpodGenerator
    extends GeneratorForAnnotation<QueryProvider> {
  @override
  TypeChecker get typeChecker => annotationChecker;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    (Writer, Scope, Scope)? possibleWriter;
    Future<(Scope, Scope)> createWriter(DriftElementId id,
        [DriftOptions? options]) async {
      if (possibleWriter case final writer?) {
        return (writer.$2, writer.$3);
      }

      final generationOptions = GenerationOptions(
        imports: ImportManagerForPartFiles(await buildStep.inputLibrary),
      );
      final writer = Writer(
        options ?? DriftOptions.fromJson({}),
        generationOptions: generationOptions,
      );

      writer.leaf()
        ..write('extension on ')
        ..write(writer.refUri(id.libraryUri, id.name))
        ..writeln('{');
      final extensionOnDatabase = writer.child();
      writer.leaf().write('}');

      writer.leaf()
        ..write('extension on ')
        ..writeDriftRiverpod('DatabaseProvider')
        ..write('<')
        ..write(writer.refUri(id.libraryUri, id.name))
        ..write('> {');
      final extensionOnProvider = writer.child();
      writer.leaf().write('}');

      possibleWriter = (writer, extensionOnDatabase, extensionOnProvider);
      return (extensionOnDatabase, extensionOnProvider);
    }

    for (var annotated in library.annotatedWith(
      typeChecker,
      throwOnUnresolved: throwOnUnresolved,
    )) {
      final element = annotated.element;
      final resolved =
          await buildStep.resolver.astNodeFor(element, resolve: true);

      if (resolved == null) {
        print(spanForElement(element).message('Could not resolve element'));
        continue;
      }

      final (definition, errors) = await QueryProviderDefinition.parse(
        element,
        resolved,
        annotated.annotation.objectValue,
      );
      if (definition != null) {
        final analyzed =
            await ResolvedQueryProvider.analyze(definition, buildStep);
        errors.addAll(analyzed.errors);
        final (onDatabase, onProvider) =
            await createWriter(definition.database, analyzed.databaseOptions);

        if (analyzed.query != null) {
          QueryProviderWriter(onDatabase, onProvider, analyzed).write();
        }
      }

      for (final error in errors) {
        print(error);
      }
    }

    return possibleWriter?.$1.writeGenerated() ?? '';
  }

  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Shouldn't be called because we overwrite generate()
    throw UnimplementedError();
  }
}
