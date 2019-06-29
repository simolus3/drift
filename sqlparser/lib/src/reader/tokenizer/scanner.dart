import 'package:source_span/source_span.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/reader/tokenizer/utils.dart';

class Scanner {
  final String source;

  final List<Token> tokens = [];
  final List<TokenizerError> errors = [];

  int _startOffset;
  int _currentOffset = 0;
  bool get _isAtEnd => _currentOffset >= source.length;

  SourceSpan get _currentSpan {
    return SourceSpanWithContext(_startLocation, _currentLocation,
        source.substring(_startOffset, _currentOffset), source);
  }

  SourceLocation get _startLocation {
    return SourceLocation(_startOffset);
  }

  SourceLocation get _currentLocation {
    return SourceLocation(_currentOffset);
  }

  Scanner(this.source);

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      _startOffset = _currentOffset;
      _scanToken();
    }

    final endLoc = SourceLocation(source.length);
    tokens.add(Token(TokenType.eof, SourceSpan(endLoc, endLoc, '')));
    return tokens;
  }

  void _scanToken() {
    final char = _nextChar();
    switch (char) {
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case ',':
        _addToken(TokenType.comma);
        break;
      case '.':
        if (!_isAtEnd && isDigit(_peek())) {
          _numeric(char);
        } else {
          _addToken(TokenType.dot);
        }
        break;
      case '+':
        _addToken(TokenType.plus);
        break;
      case '-':
        _addToken(TokenType.minus);
        break;
      case '*':
        _addToken(TokenType.star);
        break;
      case '/':
        _addToken(TokenType.slash);
        break;
      case '%':
        _addToken(TokenType.percent);
        break;
      case '&':
        _addToken(TokenType.ampersand);
        break;
      case '|':
        _addToken(_match('|') ? TokenType.doublePipe : TokenType.pipe);
        break;

      case '<':
        if (_match('=')) {
          _addToken(TokenType.lessEqual);
        } else if (_match('<')) {
          _addToken(TokenType.shiftLeft);
        } else if (_match('>')) {
          _addToken(TokenType.lessMore);
        } else {
          _addToken(TokenType.less);
        }
        break;
      case '>':
        if (_match('=')) {
          _addToken(TokenType.moreEqual);
        } else if (_match('>')) {
          _addToken(TokenType.shiftRight);
        } else {
          _addToken(TokenType.more);
        }
        break;
      case '=':
        _addToken(_match('=') ? TokenType.doubleEqual : TokenType.equal);
        break;
      case '~':
        _addToken(TokenType.tilde);
        break;

      case '?':
        _addToken(TokenType.questionMark);
        break;
      case ':':
        _addToken(TokenType.colon);
        break;
      case ';':
        _addToken(TokenType.semicolon);
        break;

      case 'x':
        if (_match("'")) {
          _string(binary: false);
        } else {
          _identifier();
        }
        break;
      case "'":
        _string();
        break;
      case '"':
        // todo sqlite also allows string literals with double ticks, we don't
        _identifier(escapedInQuotes: true);
        break;
      case ' ':
      case '\t':
      case '\n':
        // ignore whitespace
        break;

      default:
        if (isDigit(char)) {
          _numeric(char);
        } else if (canStartColumnName(char)) {
          _identifier();
        } else {
          errors.add(TokenizerError(
              'Unexpected character.', SourceLocation(_currentOffset)));
        }
        break;
    }
  }

  String _nextChar() {
    _currentOffset++;
    return source.substring(_currentOffset - 1, _currentOffset);
  }

  String _peek() {
    if (_isAtEnd) throw StateError('Reached end of source');
    return source.substring(_currentOffset, _currentOffset + 1);
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (source.substring(_currentOffset, _currentOffset + 1) != expected) {
      return false;
    }
    _currentOffset++;
    return true;
  }

  void _addToken(TokenType type) {
    tokens.add(Token(type, _currentSpan));
  }

  void _string({bool binary = false}) {
    while (_peek() != "'" && !_isAtEnd) {
      _nextChar();
    }

    // Issue an error if the string is unterminated
    if (_isAtEnd) {
      errors.add(TokenizerError('Unterminated string', _currentLocation));
    }

    // consume the closing "'"
    _nextChar();

    final value = source.substring(_startOffset + 1, _currentOffset - 1);
    tokens.add(StringLiteralToken(value, _currentSpan, binary: binary));
  }

  void _numeric(String firstChar) {
    // https://www.sqlite.org/syntax/numeric-literal.html

    // We basically have three cases: hexadecimal numbers (starting with 0x),
    // numbers starting with a decimal dot and numbers starting with a digit.
    if (firstChar == '0') {
      if (!_isAtEnd && (_peek() == 'x' || _peek() == 'X')) {
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
    if (firstChar == '.') {
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
      if (!_isAtEnd && _peek() == '.') {
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
    if (!_isAtEnd && (_peek() == 'e' || _peek() == 'E')) {
      _nextChar(); // consume e or E

      if (_isAtEnd) {
        errors.add(TokenizerError(
            'Unexpected end of file. Expected digits for the scientific notation',
            _currentLocation));
        return;
      }

      final char = _nextChar();
      if (isDigit(char)) {
        consumeDigits();
        _addToken(TokenType.numberLiteral);
        return;
      } else {
        if (char == '+' || char == '-') {
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
      while (_peek() != '"' && !_isAtEnd) {
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
        _addToken(keywords[text]);
      } else {
        tokens.add(IdentifierToken(false, _currentSpan));
      }
    }
  }
}
