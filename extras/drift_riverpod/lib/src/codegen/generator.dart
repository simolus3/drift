import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/writer.dart';

import '../annotation.dart';
import 'query_provider.dart';

final class DriftRiverpodGenerator
    extends GeneratorForAnnotation<QueryProvider> {
  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final resolved =
        await buildStep.resolver.astNodeFor(element, resolve: true);

    if (resolved == null) {
      print(spanForElement(element).message('Could not resolve element'));
      return null;
    }

    String? generatedCode;
    final (definition, errors) =
        await QueryProviderDefinition.parse(element, resolved);
    if (definition != null) {
      final analyzed =
          await ResolvedQueryProvider.analyze(definition, buildStep);
      errors.addAll(analyzed.errors);

      if (analyzed.query != null) {
        final generationOptions = GenerationOptions(
          imports: ImportManagerForPartFiles(await buildStep.inputLibrary),
        );
        final writer = Writer(
          analyzed.databaseOptions ?? DriftOptions.fromJson({}),
          generationOptions: generationOptions,
        );

        // TODO: Write one extension per library instead of one per query
        final header = writer.leaf();
        header
          ..write('extension on ')
          ..write(header.refUri(
              definition.database.libraryUri, definition.database.name))
          ..writeln('{');

        writer.leaf().write('}');
        generatedCode = writer.writeGenerated();
      }
    }

    for (final error in errors) {
      print(error);
    }

    return generatedCode;
  }
}
