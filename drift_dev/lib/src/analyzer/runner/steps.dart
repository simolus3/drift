import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/dart/parser.dart';
import 'package:drift_dev/src/analyzer/drift/entity_handler.dart';
import 'package:drift_dev/src/analyzer/drift/parser.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/runner/task.dart';
import 'package:drift_dev/src/analyzer/sql_queries/custom_result_class.dart';
import 'package:drift_dev/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:drift_dev/src/analyzer/view/view_analyzer.dart';
import 'package:drift_dev/src/utils/entity_reference_sorter.dart';
import 'package:source_gen/source_gen.dart';

import '../helper.dart';

part 'steps/analyze_dart.dart';
part 'steps/analyze_moor.dart';
part 'steps/parse_dart.dart';
part 'steps/parse_moor.dart';

/// A [Step] performs actions for a [Task] on a single file.
abstract class Step {
  final Task task;
  final FoundFile file;
  final ErrorSink errors = ErrorSink();

  bool get isParsing => true;

  String get path => file.uri.path;

  Step(this.task, this.file);

  void reportError(DriftError error) =>
      errors.report(error..wasDuringParsing = isParsing);
}

abstract class AnalyzingStep extends Step {
  AnalyzingStep(Task task, FoundFile file) : super(task, file);

  @override
  final bool isParsing = false;

  Iterable<DriftSchemaEntity> _availableEntities(Iterable<FoundFile> imports) {
    return imports.expand<DriftSchemaEntity>((file) =>
        file.currentResult?.declaredEntities ?? const Iterable.empty());
  }

  Iterable<DriftTable> _availableTables(Iterable<FoundFile> imports) {
    return _availableEntities(imports).whereType<DriftTable>();
  }

  Iterable<MoorView> _availableViews(Iterable<FoundFile> imports) {
    return _availableEntities(imports).whereType<MoorView>();
  }
}
