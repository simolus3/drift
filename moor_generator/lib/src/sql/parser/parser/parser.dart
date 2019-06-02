import 'package:moor_generator/src/sql/ast/expressions/expressions.dart';
import 'package:moor_generator/src/sql/ast/expressions/literals.dart';
import 'package:moor_generator/src/sql/ast/select/columns.dart';
import 'package:moor_generator/src/sql/parser/parser.dart';

class SemanticSqlParser extends GrammarParser {
  SemanticSqlParser() : super(SemanticSqlParserDefinition());
}

class SemanticSqlParserDefinition extends SqlGrammarDefinition {
  @override
  Parser starColumn() {
    return super.starColumn().map((each) {
      final typedEach = each as List;
      if (typedEach.first == null) {
        // just a simple star column
        return StarResultColumn.from();
      } else {
        return StarResultColumn.from(
            table: (typedEach.first as List).first as String);
      }
    });
  }

  @override
  Parser exprColumn() {
    return super.exprColumn().map((each) {
      // [expression, [AS, "column_name"]] or just [expression, null]
      final typedEach = each as List;
      final expression = typedEach.first as Expression;
      final alias = typedEach[1] != null ? typedEach[1][1] as String : null;

      return ExprResultColumn((b) => b
        ..expr = expression
        ..alias = alias);
    });
  }

  @override
  Parser currentTimestampLiteral() {
    return super.currentTimestampLiteral().map(
        (e) => CurrentTimeResolver.mode(CurrentTimeAccessor.currentTimestamp));
  }

  @override
  Parser currentDateLiteral() {
    return super
        .currentDateLiteral()
        .map((_) => CurrentTimeResolver.mode(CurrentTimeAccessor.currentDate));
  }

  @override
  Parser currentTimeLiteral() {
    return super
        .currentTimeLiteral()
        .map((_) => CurrentTimeResolver.mode(CurrentTimeAccessor.currentTime));
  }

  @override
  Parser falseLiteral() =>
      super.falseLiteral().map((_) => BooleanLiteral.from(false));

  @override
  Parser trueLiteral() =>
      super.falseLiteral().map((_) => BooleanLiteral.from(true));

  @override
  Parser nullLiteral() => super.nullLiteral().map((_) => const NullLiteral());

  @override
  Parser numericLiteral() {
    // we don't really care about the value, we just need to know the type
    return super
        .numericLiteral()
        .map((_) => NumericLiteral((b) => b.value = 0));
  }

  @override
  Parser stringLiteral() {
    // same here, only the type is relevant, the actual content doesn't matter.
    return super
        .stringLiteral()
        .map((_) => StringLiteral((b) => b.content = 'hi'));
  }
}
