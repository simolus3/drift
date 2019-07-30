import 'package:moor_generator/src/parser/moor/parsed_moor_file.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

/// Parses and analyzes the experimental `.moor` files containing sql
/// statements.
class MoorAnalyzer {
  /// Content of the `.moor` file we're analyzing.
  final String content;

  MoorAnalyzer(this.content);

  Future<MoorParsingResult> analyze() {
    final engine = SqlEngine();
    final tokens = engine.tokenize(content);
    final results = SqlEngine().parseMultiple(tokens, content);

    final createdTables = <CreateTable>[];
    final errors = <MoorParsingError>[];

    for (var parsedStmt in results) {
      if (parsedStmt.rootNode is CreateTableStatement) {
        createdTables.add(CreateTable(parsedStmt));
      } else {
        errors.add(
          MoorParsingError(
            parsedStmt.rootNode.span,
            message:
                'At the moment, only CREATE TABLE statements are supported in .moor files',
          ),
        );
      }
    }

    // all results have the same list of errors
    final sqlErrors = results.isEmpty ? <ParsingError>[] : results.first.errors;

    for (var error in sqlErrors) {
      errors.add(MoorParsingError(error.token.span, message: error.message));
    }

    final parsedFile = ParsedMoorFile(createdTables);

    return Future.value(MoorParsingResult(parsedFile, errors));
  }
}

class MoorParsingResult {
  final ParsedMoorFile parsedFile;
  final List<MoorParsingError> errors;

  MoorParsingResult(this.parsedFile, this.errors);
}

class MoorParsingError {
  final FileSpan span;
  final String message;

  MoorParsingError(this.span, {this.message});

  @override
  String toString() {
    return span.message(message, color: true);
  }
}
