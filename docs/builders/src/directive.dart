/// Directives usually appear inside a line comment.
///
/// Ignore any close-comment syntax:
///
/// - CSS and Java-like languages: `*/`
/// - HTML: `-->`
///
final _directiveRegEx = RegExp(
    r'^(\s*)(\S.*?)?#((?:end)?docregion)\b\s*(.*?)(?:\s*(?:-->|\*\/))?\s*$');

final _argSeparator = RegExp(r'\s*,\s*');

/// Represents a code-excerpter directive (both the model and lexical elements)
class Directive {
  static const int _lexemeIndex = 3;

  final Match _match;
  final Kind kind;

  late final List<String> _args;

  /// Issues raised while parsing this directive.
  final List<String> issues = [];

  Directive._(this.kind, this._match) {
    final argsMaybeWithDups = _parseArgs();
    final argCounts = <String, int>{};

    for (var arg in argsMaybeWithDups) {
      if (arg.isEmpty) {
        issues.add('unquoted default region name is deprecated');
      } else if (arg == "''") {
        arg = '';
      }

      var argCount = argCounts[arg] ?? 0;
      argCount += 1;

      if (argCount == 2) {
        issues.add('repeated argument "$arg"');
      }

      argCounts[arg] = argCount;
    }

    _args = argCounts.keys.toList();
  }

  String get line => _match[0] ?? '';

  /// Whitespace before the directive
  String get indentation => _match[1] ?? '';

  /// Characters at the start of the line before the directive lexeme
  String get prefix => indentation + (_match[2] ?? '');

  /// The directive's lexeme or empty if not found
  String get lexeme => _match[_lexemeIndex] ?? '';

  /// Raw string corresponding to the directive's arguments
  String get rawArgs => _match[4] ?? '';

  List<String> get args => _args;

  static Directive? tryParse(String line) {
    final match = _directiveRegEx.firstMatch(line);

    if (match == null) return null;

    final lexeme = match[_lexemeIndex];
    final kind = tryParseKind(lexeme);
    return kind == null ? null : Directive._(kind, match);
  }

  List<String> _parseArgs() =>
      rawArgs.isEmpty ? const [] : rawArgs.split(_argSeparator);
}

enum Kind {
  startRegion,
  endRegion,
  plaster, // TO be deprecated
}

Kind? tryParseKind(String? lexeme) {
  switch (lexeme) {
    case 'docregion':
      return Kind.startRegion;
    case 'enddocregion':
      return Kind.endRegion;
    case 'docplaster':
      return Kind.plaster;
    default:
      return null;
  }
}
