import 'dart:typed_data';

import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';

import 'token.dart';
import 'utils.dart';

class Scanner {
  final String source;
  final Uint16List _charCodes;

  /// Whether to scan tokens that are only relevant for drift files.
  final bool scanDriftTokens;
  final SourceFile _file;

  final List<Token> tokens = [];
  final List<TokenizerError> errors = [];

  int _startOffset = 0;
  int _currentOffset = 0;
  bool get _isAtEnd => _currentOffset >= source.length;

  FileSpan get _currentSpan {
    return _file.span(_startOffset, _currentOffset);
  }

  SourceLocation get _currentLocation {
    return _file.location(_currentOffset);
  }

  Scanner(this.source, {this.scanDriftTokens = false})
      : _file = SourceFile.fromString(source),
        _charCodes = Uint16List.fromList(source.codeUnits);

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      _startOffset = _currentOffset;
      _scanToken();
    }

    final endSpan = _file.span(source.length);
    tokens.add(Token(TokenType.eof, endSpan));

    Token? previous;
    for (var i = 0; i < tokens.length; i++) {
      final current = tokens[i];
      current.index = i;
      current.previous = previous;
      previous?.next = current;

      previous = current;
    }

    if (errors.isNotEmpty) {
      throw CumulatedTokenizerException(errors);
    }

    return tokens;
  }

  void _scanToken() {
    final char = _nextChar();
    switch (char) {
      case $lparen:
        _addToken(TokenType.leftParen);
        break;
      case $rparen:
        _addToken(TokenType.rightParen);
        break;
      case $comma:
        _addToken(TokenType.comma);
        break;
      case $dot:
        if (!_isAtEnd && isDigit(_peek())) {
          _numeric(char);
        } else {
          _addToken(TokenType.dot);
        }
        break;
      case $plus:
        _addToken(TokenType.plus);
        break;
      case $minus:
        if (_match($minus)) {
          _lineComment();
        } else if (_match($rangle)) {
          _addToken(_match($rangle)
              ? TokenType.dashRangleRangle
              : TokenType.dashRangle);
        } else {
          _addToken(TokenType.minus);
        }
        break;
      case $asterisk:
        if (scanDriftTokens && _match($asterisk)) {
          _addToken(TokenType.doubleStar);
        } else {
          _addToken(TokenType.star);
        }
        break;
      case $slash:
        if (_match($asterisk)) {
          _cStyleComment();
        } else {
          _addToken(TokenType.slash);
        }
        break;
      case $percent:
        _addToken(TokenType.percent);
        break;
      case $ampersand:
        _addToken(TokenType.ampersand);
        break;
      case $pipe:
        _addToken(_match($pipe) ? TokenType.doublePipe : TokenType.pipe);
        break;
      case $less_than:
        if (_match($equal)) {
          _addToken(TokenType.lessEqual);
        } else if (_match($less_than)) {
          _addToken(TokenType.shiftLeft);
        } else if (_match($greater_than)) {
          _addToken(TokenType.lessMore);
        } else {
          _addToken(TokenType.less);
        }
        break;
      case $greater_than:
        if (_match($equal)) {
          _addToken(TokenType.moreEqual);
        } else if (_match($greater_than)) {
          _addToken(TokenType.shiftRight);
        } else {
          _addToken(TokenType.more);
        }
        break;
      case $exclamation:
        if (_match($equal)) {
          _addToken(TokenType.exclamationEqual);
        } else {
          _unexpectedToken();
        }
        break;
      case $equal:
        _addToken(_match($equal) ? TokenType.doubleEqual : TokenType.equal);
        break;
      case $tilde:
        _addToken(TokenType.tilde);
        break;
      case $question:
        // if the next chars are numbers, this is an explicitly indexed variable
        final buffer = StringBuffer();
        while (!_isAtEnd && isDigit(_peek())) {
          buffer.writeCharCode(_nextChar());
        }

        int? explicitIndex;
        if (buffer.isNotEmpty) {
          explicitIndex = int.parse(buffer.toString());
        }

        tokens.add(QuestionMarkVariableToken(_currentSpan, explicitIndex));
        break;
      case $colon:
        final name = _matchColumnName();
        if (name == null) {
          _addToken(TokenType.colon);
        } else {
          tokens.add(ColonVariableToken(_currentSpan, ':$name'));
        }
        break;
      case $dollar:
        final name = _matchColumnName();
        if (name == null) {
          errors.add(TokenizerError(
              r'Expected identifier after `$`', _currentLocation));
          break;
        }

        tokens.add(DollarSignVariableToken(_currentSpan, name));
        break;
      case $at:
        final name = _matchColumnName();
        if (name == null) {
          errors.add(TokenizerError(
              r'Expected identifier after `@`', _currentLocation));
          break;
        }
        tokens.add(AtSignVariableToken(_currentSpan, name));
        break;
      case $semicolon:
        _addToken(TokenType.semicolon);
        break;
      case $x:
      case $X:
        if (_match($apostrophe)) {
          _string(binary: true);
        } else {
          _identifier();
        }
        break;
      case $apostrophe:
        _string();
        break;
      case $double_quote:
        _identifier(escapeChar: $double_quote);
        break;
      case $backquote:
        if (scanDriftTokens) {
          _inlineDart();
        } else {
          _identifier(escapeChar: $backquote);
        }
        break;
      case $lbracket:
        _identifier(escapeChar: $rbracket);
        break;
      case $space:
      case $cr:
      case $tab:
      case $lf:
        // ignore whitespace
        break;

      default:
        if (isDigit(char)) {
          _numeric(char);
        } else if (canStartIdentifier(char)) {
          _identifier();
        } else {
          _unexpectedToken();
        }
        break;
    }
  }

  void _unexpectedToken() {
    errors.add(TokenizerError('Unexpected character', _currentLocation));
  }

  @pragma('vm:prefer-inline')
  int _nextChar() {
    _advance();
    return _charCodes[_currentOffset - 1];
  }

  @pragma('vm:prefer-inline')
  void _advance() => _currentOffset++;

  int _peek() {
    if (_isAtEnd) throw StateError('Reached end of source');
    return _charCodes[_currentOffset];
  }

  bool _match(int expected) {
    if (_isAtEnd) return false;
    if (_peek() != expected) {
      return false;
    }
    _currentOffset++;
    return true;
  }

  void _addToken(TokenType type) {
    tokens.add(Token(type, _currentSpan));
  }

  void _string({bool binary = false}) {
    var properlyClosed = false;

    while (!_isAtEnd) {
      final char = _nextChar();

      // single quote could be an escape (when there are two of them) or the
      // end of this string literal
      if (char == $apostrophe) {
        if (!_isAtEnd && _peek() == $apostrophe) {
          _advance();
          continue;
        }
        properlyClosed = true;
        break;
      }
    }

    // Issue an error if the string is unterminated
    if (!properlyClosed) {
      errors.add(TokenizerError('Unterminated string', _currentLocation));
    }

    final value = source
        .substring(_startOffset + (binary ? 2 : 1), _currentOffset - 1)
        .replaceAll("''", "'");
    tokens.add(StringLiteralToken(value, _currentSpan, binary: binary));
  }

  void _numeric(int firstChar) {
    // https://www.sqlite.org/syntax/numeric-literal.html

    /// Recognizes either a digit or a underscore followed by a digit.
    int? digitCode(bool Function(int) isDigit) {
      if (_isAtEnd) {
        return null;
      }

      if (isDigit(_peek())) {
        // Digit without an underscore separator
        return _nextChar();
      }

      if (_peek() == $underscore &&
          _currentOffset < _charCodes.length - 1 &&
          isDigit(_charCodes[_currentOffset + 1])) {
        _nextChar(); // the underscore
        return _nextChar(); // the digit
      }

      return null;
    }

    // We basically have three cases: hexadecimal numbers (starting with 0x),
    // numbers starting with a decimal dot and numbers starting with a digit.
    if (firstChar == $0) {
      if (!_isAtEnd && (_peek() == $x || _peek() == $X)) {
        _nextChar(); // consume the x
        final hexDigitsBuffer = StringBuffer();
        // advance hexadecimal digits
        int? digit = digitCode(isHexDigit);
        while (digit != null) {
          hexDigitsBuffer.writeCharCode(digit);
          digit = digitCode(isHexDigit);
        }

        tokens.add(
            NumericToken(_currentSpan, hexDigits: hexDigitsBuffer.toString()));
        return;
      }
    }

    String consumeDigits() {
      final buffer = StringBuffer();
      int? digit = digitCode(isDigit);
      while (digit != null) {
        buffer.writeCharCode(digit);
        digit = digitCode(isDigit);
      }

      return buffer.toString();
    }

    /// Returns true without advancing if the next char is a digit. Returns
    /// false and logs an error with the message otherwise.
    bool requireDigit(String message) {
      final noDigit = _isAtEnd || !isDigit(_peek());
      if (noDigit) {
        errors.add(TokenizerError(message, _currentLocation));
      }
      return !noDigit;
    }

    String? beforeDecimal;
    String? afterDecimal;
    var hasDecimal = false;

    // ok, we're not dealing with a hexadecimal number.
    if (firstChar == $dot) {
      // started with a decimal point. the next char has to be numeric
      hasDecimal = true;
      if (requireDigit('Expected a digit after the decimal dot')) {
        afterDecimal = consumeDigits();
      }
    } else {
      // ok, not starting with a decimal dot. In that case, the first char must
      // be a digit
      if (!isDigit(firstChar)) {
        errors.add(TokenizerError('Expected a digit', _currentLocation));
        return;
      }
      beforeDecimal = String.fromCharCode(firstChar) + consumeDigits();

      // optional decimal part
      if (!_isAtEnd && _peek() == $dot) {
        _nextChar();
        hasDecimal = true;

        final digits = consumeDigits();
        if (digits.isNotEmpty) {
          afterDecimal = digits;
        }
      }
    }

    int? parsedExponent;

    // ok, we've read the first part of the number. But there's more! If it's
    // not a hexadecimal number, it could be in scientific notation.
    if (!_isAtEnd && (_peek() == $e || _peek() == $E)) {
      _nextChar(); // consume e or E

      if (_isAtEnd) {
        errors.add(TokenizerError(
            'Unexpected end of file. '
            'Expected digits for the scientific notation',
            _currentLocation));
        return;
      }

      final char = _nextChar();
      if (isDigit(char)) {
        final exponent = String.fromCharCode(char) + consumeDigits();
        parsedExponent = int.parse(exponent);
      } else {
        if (char == $plus || char == $minus) {
          requireDigit('Expected digits for the exponent');
          final exponent = consumeDigits();

          parsedExponent =
              char == $plus ? int.parse(exponent) : -int.parse(exponent);
        } else {
          errors
              .add(TokenizerError('Expected plus or minus', _currentLocation));
        }
      }
    }

    tokens.add(NumericToken(_currentSpan,
        digitsBeforeDecimal: beforeDecimal,
        digitsAfterDecimal: afterDecimal,
        hasDecimalPoint: hasDecimal,
        exponent: parsedExponent));
  }

  void _identifier({int? escapeChar}) {
    if (escapeChar != null) {
      // find the closing quote
      while (!_isAtEnd && _peek() != escapeChar) {
        _nextChar();
      }
      // Issue an error if the column name is unterminated
      if (_isAtEnd) {
        errors
            .add(TokenizerError('Unterminated column name', _currentLocation));
      } else {
        // consume the closing char
        _nextChar();
        tokens.add(IdentifierToken(true, _currentSpan));
      }
    } else {
      while (!_isAtEnd && continuesIdentifier(_peek())) {
        _nextChar();
      }

      // not escaped, so it could be a keyword
      final text = _currentSpan.text.toUpperCase();
      if (keywords.containsKey(text)) {
        tokens.add(KeywordToken(keywords[text]!, _currentSpan));
      } else if (scanDriftTokens && driftKeywords.containsKey(text)) {
        tokens.add(KeywordToken(driftKeywords[text]!, _currentSpan));
      } else {
        tokens.add(IdentifierToken(false, _currentSpan));
      }
    }
  }

  String? _matchColumnName() {
    if (_isAtEnd || !canStartIdentifier(_peek())) return null;

    final buffer = StringBuffer()..writeCharCode(_nextChar());
    while (!_isAtEnd && continuesIdentifier(_peek())) {
      buffer.writeCharCode(_nextChar());
    }

    return buffer.toString();
  }

  void _inlineDart() {
    // inline starts with a `, we just need to find the matching ` that
    // terminates this token.
    while (_peek() != $backquote && !_isAtEnd) {
      _nextChar();
    }

    if (_isAtEnd) {
      errors.add(
          TokenizerError('Unterminated inline Dart code', _currentLocation));
    } else {
      // consume the `
      _nextChar();
      tokens.add(InlineDartToken(_currentSpan));
    }
  }

  /// Scans a line comment after the -- has already been read.
  void _lineComment() {
    final contentBuilder = StringBuffer();
    while (!_isAtEnd && _peek() != $lf) {
      contentBuilder.writeCharCode(_nextChar());
    }

    tokens.add(CommentToken(
        CommentMode.line, contentBuilder.toString(), _currentSpan));
  }

  /// Scans a /* ... */ comment after the first /* has already been read.
  /// Note that in sqlite, these comments don't have to be terminated - they
  /// will be closed by the end of input without causing a parsing error.
  void _cStyleComment() {
    final contentBuilder = StringBuffer();
    while (!_isAtEnd) {
      if (_match($asterisk)) {
        if (!_isAtEnd && _match($slash)) {
          break;
        } else {
          // write the * we otherwise forgot to write
          contentBuilder.writeCharCode($asterisk);
        }
      } else {
        contentBuilder.writeCharCode(_nextChar());
      }
    }

    tokens.add(CommentToken(
        CommentMode.cStyle, contentBuilder.toString(), _currentSpan));
  }
}
