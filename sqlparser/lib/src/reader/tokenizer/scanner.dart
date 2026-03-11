import 'dart:typed_data';

import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';

import 'token.dart';
import 'utils.dart';

class Scanner {
  final Uint16List _charCodes;
  final List<TokenizerError> errors = [];

  /// Whether to scan tokens that are only relevant for drift files.
  final bool scanDriftTokens;
  final SourceFile _file;

  bool isInTopLevelDriftFile = false;

  /// Pending opening tokens used to associate them with closing tokens.
  ///
  /// This used to pair matching parentheses, as the information can be used by
  /// the parser to be more accurate about error recovery.
  /// An entry in the stack is the opening token and the token type closing that
  /// token.
  final List<(Token, TokenType)> _tokenStack = [];

  int _startOffset = 0;
  int _currentOffset = 0;
  final int _endOffset;
  bool get _isAtEnd => _currentOffset >= _endOffset;

  FileSpan get _currentSpan {
    return _file.span(_startOffset, _currentOffset);
  }

  FileLocation get _currentLocation {
    return _file.location(_currentOffset);
  }

  Scanner(FileSpan span, {this.scanDriftTokens = false})
      : _file = span.file,
        _startOffset = span.start.offset,
        _currentOffset = span.start.offset,
        _endOffset = span.end.offset,
        _charCodes = Uint16List.fromList(span.file.codeUnits);

  Token scanToken() {
    while (true) {
      if (_isAtEnd) {
        final endSpan = _file.span(_endOffset, _endOffset);
        return Token(TokenType.eof, endSpan);
      }

      _startOffset = _currentOffset;

      // We might have to call this multiple times to skip past whitespace.
      if (_consumeToken() case final token?) {
        return token;
      }
    }
  }

  Token? _consumeToken() {
    final char = _nextChar();
    switch (char) {
      case $lparen:
        return _addToken(TokenType.leftParen, closedBy: TokenType.rightParen);
      case $rparen:
        return _addToken(TokenType.rightParen, mayClose: true);
      case $comma:
        return _addToken(TokenType.comma);
      case $dot:
        if (!_isAtEnd && isDigit(_peek())) {
          return _numeric(char);
        } else {
          return _addToken(TokenType.dot);
        }
      case $plus:
        return _addToken(TokenType.plus);
      case $minus:
        if (_match($minus)) {
          return _lineComment();
        } else if (_match($rangle)) {
          return _addToken(_match($rangle)
              ? TokenType.dashRangleRangle
              : TokenType.dashRangle);
        } else {
          return _addToken(TokenType.minus);
        }
      case $asterisk:
        if (scanDriftTokens && _match($asterisk)) {
          return _addToken(TokenType.doubleStar);
        } else {
          return _addToken(TokenType.star);
        }
      case $slash:
        if (_match($asterisk)) {
          return _cStyleComment();
        } else {
          return _addToken(TokenType.slash);
        }
      case $percent:
        return _addToken(TokenType.percent);
      case $ampersand:
        return _addToken(TokenType.ampersand);
      case $pipe:
        return _addToken(_match($pipe) ? TokenType.doublePipe : TokenType.pipe);
      case $less_than:
        if (_match($equal)) {
          return _addToken(TokenType.lessEqual);
        } else if (_match($less_than)) {
          return _addToken(TokenType.shiftLeft);
        } else if (_match($greater_than)) {
          return _addToken(TokenType.lessMore);
        } else {
          return _addToken(TokenType.less);
        }
      case $greater_than:
        if (_match($equal)) {
          return _addToken(TokenType.moreEqual);
        } else if (_match($greater_than)) {
          return _addToken(TokenType.shiftRight);
        } else {
          return _addToken(TokenType.more);
        }
      case $exclamation:
        if (_match($equal)) {
          return _addToken(TokenType.exclamationEqual);
        } else {
          return _unexpectedToken();
        }
      case $equal:
        return _addToken(
            _match($equal) ? TokenType.doubleEqual : TokenType.equal);
      case $tilde:
        return _addToken(TokenType.tilde);
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

        return QuestionMarkVariableToken(_currentSpan, explicitIndex);
      case $colon:
        final name = _matchColumnName();
        if (name == null) {
          return _addToken(TokenType.colon);
        } else {
          return ColonVariableToken(_currentSpan, name);
        }
      case $dollar:
        final name = _matchColumnName();
        if (name == null) {
          return TokenizerError(
              r'Expected identifier after `$`', _currentLocation);
        }

        return DollarSignVariableToken(_currentSpan, name);
      case $at:
        final name = _matchColumnName();
        if (name == null) {
          return TokenizerError(
              r'Expected identifier after `@`', _currentLocation);
        }
        return AtSignVariableToken(_currentSpan, name);
      case $semicolon:
        final token = _addToken(TokenType.semicolon);
        _tokenStack.clear();
        return token;
      case $x:
      case $X:
        if (_match($apostrophe)) {
          return _string(binary: true);
        } else {
          return _identifier();
        }
      case $apostrophe:
        return _string();
      case $double_quote:
        return _identifier(escapeChar: $double_quote);
      case $backquote:
        if (scanDriftTokens) {
          return _inlineDart();
        } else {
          return _identifier(escapeChar: $backquote);
        }
      case $lbracket:
        return _identifier(escapeChar: $rbracket);
      case $space:
      case $cr:
      case $tab:
      case $lf:
        // ignore whitespace
        return null;

      default:
        if (isDigit(char)) {
          return _numeric(char);
        } else if (canStartIdentifier(char)) {
          return _identifier();
        } else {
          return _unexpectedToken();
        }
    }
  }

  Token _unexpectedToken() {
    return TokenizerError('Unexpected character', _currentLocation);
  }

  int _nextChar() {
    _advance();
    return _charCodes[_currentOffset - 1];
  }

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

  Token _addToken(
    TokenType type, {
    TokenType? closedBy,
    bool mayClose = false,
  }) {
    final token = Token(type, _currentSpan);

    if (closedBy != null) {
      _tokenStack.add((token, closedBy));
    }

    if (mayClose && _tokenStack.isNotEmpty) {
      final candidate = _tokenStack.removeLast();
      if (candidate.$2 == type) {
        candidate.$1.match = token;
        token.match = candidate.$1;
      } else {
        // Stack association broken, nothing we can do...
        _tokenStack.clear();
      }
    }

    return token;
  }

  Token _string({bool binary = false}) {
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

    final value = _file
        .getText(
          _startOffset + (binary ? 2 : 1),
          _currentOffset - (properlyClosed ? 1 : 0),
        )
        .replaceAll("''", "'");
    return StringLiteralToken(value, _currentSpan, binary: binary);
  }

  Token _numeric(int firstChar) {
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

        return NumericToken(_currentSpan,
            hexDigits: hexDigitsBuffer.toString());
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
    TokenizerError? requireDigit(String message) {
      final noDigit = _isAtEnd || !isDigit(_peek());
      if (noDigit) {
        return TokenizerError(message, _currentLocation);
      }
      return null;
    }

    String? beforeDecimal;
    String? afterDecimal;
    var hasDecimal = false;

    // ok, we're not dealing with a hexadecimal number.
    if (firstChar == $dot) {
      // started with a decimal point. the next char has to be numeric
      hasDecimal = true;
      if (requireDigit('Expected a digit after the decimal dot')
          case final error?) {
        return error;
      }
      afterDecimal = consumeDigits();
    } else {
      // ok, not starting with a decimal dot. In that case, the first char must
      // be a digit
      if (!isDigit(firstChar)) {
        return TokenizerError('Expected a digit', _currentLocation);
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
        return TokenizerError(
            'Unexpected end of file. '
            'Expected digits for the scientific notation',
            _currentLocation);
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
          return TokenizerError('Expected plus or minus', _currentLocation);
        }
      }
    }

    return NumericToken(
      _currentSpan,
      digitsBeforeDecimal: beforeDecimal,
      digitsAfterDecimal: afterDecimal,
      hasDecimalPoint: hasDecimal,
      exponent: parsedExponent,
    );
  }

  Token _identifier({int? escapeChar}) {
    if (escapeChar != null) {
      // find the closing quote
      while (!_isAtEnd && _peek() != escapeChar) {
        _nextChar();
      }
      // Issue an error if the column name is unterminated
      if (_isAtEnd) {
        return TokenizerError('Unterminated column name', _currentLocation);
      } else {
        // consume the closing char
        _nextChar();
        return IdentifierToken(true, _currentSpan);
      }
    } else {
      while (!_isAtEnd && continuesIdentifier(_peek())) {
        _nextChar();
      }

      // not escaped, so it could be a keyword
      final text = _currentSpan.text.toUpperCase();
      if (keywords[text] case final keyword?) {
        return KeywordToken(keyword, _currentSpan);
      } else if (scanDriftTokens && driftKeywords.containsKey(text)) {
        return KeywordToken(driftKeywords[text]!, _currentSpan);
      } else {
        return IdentifierToken(false, _currentSpan);
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

  Token _inlineDart() {
    // inline starts with a `, we just need to find the matching ` that
    // terminates this token.
    while (_peek() != $backquote && !_isAtEnd) {
      _nextChar();
    }

    if (_isAtEnd) {
      return TokenizerError('Unterminated inline Dart code', _currentLocation);
    } else {
      // consume the `
      _nextChar();
      return InlineDartToken(_currentSpan);
    }
  }

  /// Scans a line comment after the -- has already been read.
  CommentToken _lineComment() {
    var nextLineBreak = _charCodes.indexOf($lf, _currentOffset);
    if (nextLineBreak == -1) {
      nextLineBreak = _endOffset;
    }

    final content = String.fromCharCodes(
        _charCodes.getRange(_currentOffset, nextLineBreak));
    if (scanDriftTokens && isInTopLevelDriftFile) {
      // We can parse line comments as import statements or named statements.
      // We currently use fairly crude heuristics for this: The structures we
      // want to parse end with colons or semicolons, so we'll parse those if
      // the comment is at the right location.
      if (_importComment.hasMatch(content) ||
          _statementMeta.hasMatch(content)) {
        // End the comment token without consuming the line. This will treat the
        // initial `--` as a comment and allows us to parse the rest.
        return CommentToken(CommentMode.line, '', _currentSpan);
      }
    }

    _currentOffset = nextLineBreak;
    return CommentToken(CommentMode.line, content, _currentSpan);
  }

  /// Scans a /* ... */ comment after the first /* has already been read.
  /// Note that in sqlite, these comments don't have to be terminated - they
  /// will be closed by the end of input without causing a parsing error.
  CommentToken _cStyleComment() {
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

    return CommentToken(
        CommentMode.cStyle, contentBuilder.toString(), _currentSpan);
  }

  static final _importComment = RegExp(r'^\s*import.*;', caseSensitive: false);
  // match `foo:` or `myQuery (:variable AS TEXT):`
  // The colon must be at the end of the line to avoid matching regular
  // comments that happen to contain colons (e.g. `-- VIEW : description`).
  static final _statementMeta =
      RegExp(r'^\s*\w+\s*(?:\(.*\)\s*)?:\s*$', caseSensitive: false);
}
