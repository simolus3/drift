// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';
import 'package:characters/characters.dart';
import 'package:path/path.dart' as p;

import 'span_parser.dart';

const _bracketStyles = <TextStyle>[
  TextStyle(color: Color(0xFF5caeef)),
  TextStyle(color: Color(0xFFdfb976)),
  TextStyle(color: Color(0xFFc172d9)),
  TextStyle(color: Color(0xFF4fb1bc)),
  TextStyle(color: Color(0xFF97c26c)),
  TextStyle(color: Color(0xFFabb2c0)),
];

const _failedBracketStyle = TextStyle(color: Color(0xFFff0000));

const _defaultLightThemeFiles = [
  'light_vs.json',
  'light_plus.json',
];

const _defaultDarkThemeFiles = [
  'dark_vs.json',
  'dark_plus.json',
];

class Highlighter {
  Highlighter({required this.theme});

  final Grammar _grammar = Grammar.fromJson(jsonDecode(
      File(p.join(Directory.current.path, "builders", "grammar", 'dart.json'))
          .readAsStringSync()) as Map<String, dynamic>);

  /// The [HighlighterTheme] used to style the code.
  final HighlighterTheme theme;

  /// Formats the given [code] and returns a [TextSpan] with syntax
  /// highlighting.
  TextSpan highlight(String code) {
    var spans = SpanParser.parse(_grammar, code);
    var textSpans = <TextSpan>[];
    var bracketCounter = 0;

    int charPos = 0;
    for (var span in spans) {
      // Add any text before the span.
      if (span.start > charPos) {
        var text = code.substring(charPos, span.start);
        TextSpan? textSpan;
        (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
        textSpans.add(
          textSpan,
        );

        charPos = span.start;
      }

      // Add the span.
      var segment = code.substring(span.start, span.end);
      var style = theme._getStyle(span.scopes);
      textSpans.add(
        TextSpan(text: segment, style: style ?? const TextStyle()),
      );

      charPos = span.end;
    }

    // Add any text after the last span.
    if (charPos < code.length) {
      var text = code.substring(charPos, code.length);
      TextSpan? textSpan;
      (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
      textSpans.add(
        textSpan,
      );
    }

    return TextSpan(children: textSpans, style: theme._wrapper);
  }

  (TextSpan, int) _formatBrackets(String text, int bracketCounter) {
    var spans = <TextSpan>[];
    var plainText = '';
    for (var char in Characters(text)) {
      if (_isStartingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        bracketCounter += 1;
        plainText = '';
      } else if (_isEndingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        bracketCounter -= 1;
        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        plainText = '';
      } else {
        plainText += char;
      }
    }
    if (plainText.isNotEmpty) {
      spans.add(TextSpan(text: plainText));
    }

    if (spans.length == 1) {
      return (spans[0], bracketCounter);
    } else {
      return (TextSpan(children: spans), bracketCounter);
    }
  }

  TextStyle _getBracketStyle(int bracketCounter) {
    if (bracketCounter < 0) {
      return _failedBracketStyle;
    }
    return _bracketStyles[bracketCounter % _bracketStyles.length];
  }

  bool _isStartingBracket(String bracket) {
    return bracket == '{' || bracket == '[' || bracket == '(';
  }

  bool _isEndingBracket(String bracket) {
    return bracket == '}' || bracket == ']' || bracket == ')';
  }
}

/// A [HighlighterTheme] which is used to style the code.
class HighlighterTheme {
  late final TextStyle _wrapper;
  TextStyle? _fallback;
  final _scopes = <String, TextStyle>{};

  HighlighterTheme(
    ThemeMode mode,
  ) {
    _wrapper = mode == ThemeMode.light
        ? const TextStyle(color: Color(0xFF000088))
        : const TextStyle(color: Color(0xFFB9EEFF));

    final filenames = mode == ThemeMode.light
        ? _defaultLightThemeFiles
        : _defaultDarkThemeFiles;
    for (var filename in filenames) {
      final content =
          File(p.join(Directory.current.path, "builders", "themes", filename))
              .readAsStringSync();
      _parseTheme(content);
    }
  }

  void _parseTheme(String json) {
    var theme = jsonDecode(json);

    final settings = (theme['settings'] as List).cast<Map>();
    for (Map setting in settings) {
      var style = _parseTextStyle(setting['settings'] as Map);

      var scopes = setting['scope'];
      if (scopes is String) {
        _addScope(scopes, style);
      } else if (scopes is List) {
        for (final scope in scopes.whereType<String>()) {
          _addScope(scope, style);
        }
      } else if (scopes == null) {
        _fallback = style;
      }
    }
  }

  TextStyle _parseTextStyle(Map setting) {
    Color? color;
    var foregroundSetting = setting['foreground'];
    if (foregroundSetting is String && foregroundSetting.startsWith('#')) {
      color = Color(
        int.parse(
              foregroundSetting.substring(1),
              radix: 16,
            ) |
            0xFF000000,
      );
    }

    FontStyle? fontStyle;
    FontWeight? fontWeight;
    TextDecoration? textDecoration;

    var fontStyleSetting = setting['fontStyle'];
    if (fontStyleSetting is String) {
      if (fontStyleSetting == 'italic') {
        fontStyle = FontStyle.italic;
      } else if (fontStyleSetting == 'bold') {
        fontWeight = FontWeight.bold;
      } else if (fontStyleSetting == 'underline') {
        textDecoration = TextDecoration.underline;
      } else {
        throw Exception('WARNING unknown style: $fontStyleSetting');
      }
    }

    return TextStyle(
      color: color,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      decoration: textDecoration,
    );
  }

  void _addScope(String scope, TextStyle style) {
    _scopes[scope] = style;
  }

  TextStyle? _getStyle(List<String> scope) {
    for (var s in scope) {
      var fallbacks = _fallbacks(s);
      for (var f in fallbacks) {
        var style = _scopes[f];
        if (style != null) {
          return style;
        }
      }
    }
    return _fallback;
  }

  List<String> _fallbacks(String scope) {
    var fallbacks = <String>[];
    var parts = scope.split('.');
    for (var i = 0; i < parts.length; i++) {
      var s = parts.sublist(0, i + 1).join('.');
      fallbacks.add(s);
    }
    return fallbacks.reversed.toList();
  }
}

/// Flutter Stubs
enum ThemeMode {
  light,
  dark,
}

enum Brightness {
  dark,
  light;
}

enum FontStyle {
  italic,
  bold;
}

enum FontWeight {
  bold;
}

enum TextDecoration {
  underline;
}

class Color {
  final int value;
  const Color(this.value);
}

class TextStyle {
  final Color? color;
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;
  const TextStyle(
      {this.color, this.fontStyle, this.fontWeight, this.decoration});

  String toCSS() {
    var css = '';
    if (color != null) {
      var colorString = color!.value.toRadixString(16);
      // Remove alpha channel
      colorString = colorString.substring(2);
      css += 'color: #$colorString;';
    }
    if (fontStyle != null) {
      if (fontStyle == FontStyle.italic) {
        css += 'font-style: italic;';
      }
      if (fontStyle == FontStyle.bold) {
        css += 'font-weight: bold;';
      }
    }
    if (fontWeight != null) {
      css += 'font-weight: bold;';
    }
    if (decoration != null) {
      // Add underline
      css += 'text-decoration: underline;';
    }
    if (css.isEmpty) {
      return '';
    } else {
      return 'style="$css"';
    }
  }
}

class TextSpan {
  final List<TextSpan> children;
  final String? text;
  final TextStyle style;
  const TextSpan(
      {this.text, this.style = const TextStyle(), this.children = const []});

  String toHTML() {
    var html = '';
    if (text != null) {
      html += text!.replaceAll(" ", "&nbsp;").replaceAll('\n', "<br>");
    }
    if (children.isNotEmpty) {
      for (var child in children) {
        html += child.toHTML();
      }
    }

    return '<span ${style.toCSS()}>$html</span>';
  }
}
