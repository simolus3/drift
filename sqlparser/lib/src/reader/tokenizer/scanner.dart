import 'dart:typed_data';

import 'package:source_span/source_span.dart';

import 'token.dart';
import 'utils.dart';

class Scanner {
  final String source;
  final Uint16List _charCodes;

  /// Whether to scan tokens that are only relevant for moor.
  final bool scanMoorTokens;
  final SourceFile _file;

  final List<Token> tokens = [];
  final List<TokenizerError> errors = [];

  int _startOffset;
  int _currentOffset = 0;
  bool get _isAtEnd => _currentOffset >= source.length;

  FileSpan get _currentSpan {
    return _file.span(_startOffset, _currentOffset);
  }

  SourceLocation get _currentLocation {
    return _file.location(_currentOffset);
  }

  Scanner(this.source, {this.scanMoorTokens = false})
      : _file = SourceFile.fromString(source),
        _charCodes = Uint16List.fromList(source.codeUnits);

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      _startOffset = _currentOffset;
      _scanToken();
    }

    final endSpan = _file.span(source.length);
    tokens.add(Token(TokenType.eof, endSpan));

    for (var i = 0; i < tokens.length; i++) {
      tokens[i].index = i;
    }

    return tokens;
  }

  void _scanToken() {
    final char = _nextChar();
    switch (char) {
      case charParenLeft:
        _addToken(TokenType.leftParen);
        break;
      case charParenRight:
        _addToken(TokenType.rightParen);
        break;
      case charComma:
        _addToken(TokenType.comma);
        break;
      case charPeriod:
        if (!_isAtEnd && isDigit(_peek())) {
          _numeric(char);
        } else {
          _addToken(TokenType.dot);
        }
        break;
      case charPlus:
        _addToken(TokenType.plus);
        break;
      case charMinus:
        if (_match(charMinus)) {
          _lineComment();
        } else {
          _addToken(TokenType.minus);
        }
        break;
      case charStar:
        if (scanMoorTokens && _match(charStar)) {
          _addToken(TokenType.doubleStar);
        }
        _addToken(TokenType.star);
        break;
      case charSlash:
        if (_match(charStar)) {
          _cStyleComment();
        } else {
          _addToken(TokenType.slash);
        }

        break;
      case charPercent:
        _addToken(TokenType.percent);
        break;
      case charAmpersand:
        _addToken(TokenType.ampersand);
        break;
      case charPipe:
        _addToken(_match(charPipe) ? TokenType.doublePipe : TokenType.pipe);
        break;
      case charLess:
        if (_match(charEquals)) {
          _addToken(TokenType.lessEqual);
        } else if (_match(charLess)) {
          _addToken(TokenType.shiftLeft);
        } else if (_match(charGreater)) {
          _addToken(TokenType.lessMore);
        } else {
          _addToken(TokenType.less);
        }
        break;
      case charGreater:
        if (_match(charEquals)) {
          _addToken(TokenType.moreEqual);
        } else if (_match(charGreater)) {
          _addToken(TokenType.shiftRight);
        } else {
          _addToken(TokenType.more);
        }
        break;
      case charExclMark: // !
        if (_match(charEquals)) {
          _addToken(TokenType.exclamationEqual);
        }
        break;
      case charEquals:
        _addToken(_match(charEquals) ? TokenType.doubleEqual : TokenType.equal);
        break;
      case charTilde:
        _addToken(TokenType.tilde);
        break;
      case charQuestionMark:
        // if the next chars are numbers, this is an explicitly indexed variable
        final buffer = StringBuffer();
        while (!_isAtEnd && isDigit(_peek())) {
          buffer.writeCharCode(_nextChar());
        }

        int explicitIndex;
        if (buffer.isNotEmpty) {
          explicitIndex = int.parse(buffer.toString());
        }

        tokens.add(QuestionMarkVariableToken(_currentSpan, explicitIndex));
        break;
      case charColon:
        final name = _matchColumnName();
        if (name == null) {
          _addToken(TokenType.colon);
        } else {
          tokens.add(ColonVariableToken(_currentSpan, ':$name'));
        }
        break;
      case charDollarSign:
        final name = _matchColumnName();
        tokens.add(DollarSignVariableToken(_currentSpan, name));
        break;
      case charAt:
        final name = _matchColumnName();
        tokens.add(AtSignVariableToken(_currentSpan, name));
        break;
      case charSemicolon:
        _addToken(TokenType.semicolon);
        break;
      case charCodeX:
      case charCodeLowerX:
        if (_match(charSingleTick)) {
          _string(binary: true);
        } else {
          _identifier();
        }
        break;
      case charSingleTick:
        _string();
        break;
      case charDoubleTick:
        _identifier(escapedInQuotes: true);
        break;
      case charBacktick:
        if (scanMoorTokens) {
          _inlineDart();
        } else {
          _unexpectedToken();
        }
        break;
      case charSpace:
      case charCarriageReturn:
      case charTab:
      case charLineFeed:
        // ignore whitespace
        break;

      default:
        if (isDigit(char)) {
          _numeric(char);
        } else if (canStartColumnName(char)) {
          _identifier();
        } else {
          _unexpectedToken();
        }
        break;
    }
  }

  void _unexpectedToken() {
    errors.add(TokenizerError('Unexpected character.', _currentLocation));
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
      if (char == charSingleTick) {
        if (!_isAtEnd && _peek() == charSingleTick) {
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
        .substring(_startOffset + 1, _currentOffset - 1)
        .replaceAll("''", "'");
    tokens.add(StringLiteralToken(value, _currentSpan, binary: binary));
  }

  void _numeric(int firstChar) {
    // https://www.sqlite.org/syntax/numeric-literal.html

    // We basically have three cases: hexadecimal numbers (starting with 0x),
    // numbers starting with a decimal dot and numbers starting with a digit.
    if (firstChar == charCodeZero) {
      if (!_isAtEnd && (_peek() == charCodeLowerX || _peek() == charCodeX)) {
        _nextChar(); // consume the x
        // advance hexadecimal digits
        while (!_isAtEnd && isHexDigit(_peek())) {
          _nextChar();
        }
        _addToken(TokenType.numberLiteral);
        return;
      }
    }

    void consumeDigits() {
      while (!_isAtEnd && isDigit(_peek())) {
        _nextChar();
      }
    }

    /// Returns true without advancing if the next char is a digit. Returns
    /// false and logs an error with the message otherwise.
    bool _requireDigit(String message) {
      final noDigit = _isAtEnd || !isDigit(_peek());
      if (noDigit) {
        errors.add(TokenizerError(message, _currentLocation));
      }
      return !noDigit;
    }

    // ok, we're not dealing with a hexadecimal number.
    if (firstChar == charPeriod) {
      // started with a decimal point. the next char has to be numeric
      if (_requireDigit('Expected a digit after the decimal dot')) {
        consumeDigits();
      }
    } else {
      // ok, not starting with a decimal dot. In that case, the first char must
      // be a digit
      if (!isDigit(firstChar)) {
        errors.add(TokenizerError('Expected a digit', _currentLocation));
        return;
      }
      consumeDigits();

      // optional decimal part
      if (!_isAtEnd && _peek() == charPeriod) {
        _nextChar();
        // if there is a decimal separator, there must be at least one digit
        // after it
        if (_requireDigit('Expected a digit after the decimal dot')) {
          consumeDigits();
        } else {
          return;
        }
      }
    }

    // ok, we've read the first part of the number. But there's more! If it's
    // not a hexadecimal number, it could be in scientific notation.
    if (!_isAtEnd && (_peek() == charLowerE || _peek() == charCodeE)) {
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
        consumeDigits();
        _addToken(TokenType.numberLiteral);
        return;
      } else {
        if (char == charPlus || char == charMinus) {
          _requireDigit('Expected digits for the exponent');
          consumeDigits();
          _addToken(TokenType.numberLiteral);
        } else {
          errors
              .add(TokenizerError('Expected plus or minus', _currentLocation));
        }
      }
    } else {
      // ok, no scientific notation
      _addToken(TokenType.numberLiteral);
    }
  }

  void _identifier({bool escapedInQuotes = false}) {
    if (escapedInQuotes) {
      // find the closing quote
      while (!_isAtEnd && _peek() != charDoubleTick) {
        _nextChar();
      }
      // Issue an error if the column name is unterminated
      if (_isAtEnd) {
        errors
            .add(TokenizerError('Unterminated column name', _currentLocation));
      } else {
        // consume the closing double quote
        _nextChar();
        tokens.add(IdentifierToken(true, _currentSpan));
      }
    } else {
      while (!_isAtEnd && continuesColumnName(_peek())) {
        _nextChar();
      }

      // not escaped, so it could be a keyword
      final text = _currentSpan.text.toUpperCase();
      if (keywords.containsKey(text)) {
        tokens.add(KeywordToken(keywords[text], _currentSpan));
      } else if (scanMoorTokens && moorKeywords.containsKey(text)) {
        tokens.add(KeywordToken(moorKeywords[text], _currentSpan));
      } else {
        tokens.add(IdentifierToken(false, _currentSpan));
      }
    }
  }

  String _matchColumnName() {
    if (_isAtEnd || !canStartColumnName(_peek())) return null;

    final buffer = StringBuffer()..writeCharCode(_nextChar());
    while (!_isAtEnd && continuesColumnName(_peek())) {
      buffer.writeCharCode(_nextChar());
    }

    return buffer.toString();
  }

  void _inlineDart() {
    // inline starts with a `, we just need to find the matching ` that
    // terminates this token.
    while (_peek() != charBacktick && !_isAtEnd) {
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
    while (!_isAtEnd && _peek() != charLineFeed) {
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
      if (_match(charStar)) {
        if (!_isAtEnd && _match(charSlash)) {
          break;
        } else {
          // write the * we otherwise forgot to write
          contentBuilder.writeCharCode(charStar);
        }
      } else {
        contentBuilder.writeCharCode(_nextChar());
      }
    }

    tokens.add(CommentToken(
        CommentMode.cStyle, contentBuilder.toString(), _currentSpan));
  }
}
