import '../parser.dart';

class SqlGrammar extends GrammarParser {
  SqlGrammar() : super(const SqlGrammarDefinition());
}

class SqlGrammarDefinition extends GrammarDefinition {
  const SqlGrammarDefinition();
  @override
  Parser start() => ref(select).end();

  Parser select() => string('SELECT') & ref(resultColumns).trim();

  Parser resultColumns() => ref(resultColumn)
      .separatedBy(ref(comma).trim().flatten(), includeSeparators: false);
  Parser resultColumn() => ref(exprColumn).or(ref(starColumn));
  Parser exprColumn() =>
      ref(expression) &
      (string('AS').trim() & ref(identifier).trim()).optional();
  Parser starColumn() => (tableName() & ref(dot)).optional() & ref(star);

  // todo these
  Parser<String> tableName() => string('tableName');
  Parser<String> identifier() => string('id');

  Parser comma() => char(',');
  Parser dot() => char('.');
  Parser star() => char('*');
  Parser hexDigit() => anyOf('0123456789abcdefABCDEF');

  // expressions
  Parser expression() => ref(literal);

  Parser literal() =>
      ref(stringLiteral) |
      ref(numericLiteral) |
      ref(nullLiteral) |
      ref(trueLiteral) |
      ref(falseLiteral) |
      ref(currentTimeLiteral) |
      ref(currentDateLiteral) |
      ref(currentTimestampLiteral);
  Parser stringLiteral() =>
      (anyOf('xX').optional() & char("'") & noneOf("'").star() & char("'"))
          .flatten(); // todo support '' for escaping
  Parser numericLiteral() {
    final hex = stringIgnoreCase('0x') & ref(hexDigit).plus();
    final exponent =
        (anyOf('eE') & (char('+') | char('-')).optional('+') & digit().plus())
            .flatten();

    final numberWithTrailingDecimalPoint = ref(dot) & digit().plus();
    final regularNumber =
        digit().plus() & (ref(dot) & digit().star()).optional();

    final numeric = (numberWithTrailingDecimalPoint | regularNumber).flatten();

    return hex | (numeric & exponent.optional());
  }

  Parser nullLiteral() => stringIgnoreCase('NULL');
  Parser trueLiteral() => stringIgnoreCase('TRUE');
  Parser falseLiteral() => stringIgnoreCase('FALSE');
  Parser currentTimeLiteral() => stringIgnoreCase('CURRENT_TIME');
  Parser currentDateLiteral() => stringIgnoreCase('CURRENT_DATE');
  Parser currentTimestampLiteral() => stringIgnoreCase('CURRENT_TIMESTAMP');
}
