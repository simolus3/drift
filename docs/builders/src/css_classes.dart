// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Represents a font style.
enum FontStyle { italic, bold }

/// Represents a font weight.
enum FontWeight { bold }

/// Represents a text decoration.
enum TextDecoration { underline }

/// Represents a color.
class Color {
  final int value;
  const Color(this.value);

  @override
  String toString() => 'Color($value)';

  @override
  bool operator ==(covariant Color other) {
    if (identical(this, other)) return true;

    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
    };
  }

  factory Color.fromMap(Map<String, dynamic> map) {
    return Color(
      map['value'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Color.fromJson(String source) =>
      Color.fromMap(json.decode(source) as Map<String, dynamic>);
}

class TextStyle {
  final Color? color;
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;

  const TextStyle(
      {this.color, this.fontStyle, this.fontWeight, this.decoration});

  @override
  bool operator ==(covariant TextStyle other) {
    if (identical(this, other)) return true;
    return other.color == color &&
        other.fontStyle == fontStyle &&
        other.fontWeight == fontWeight &&
        other.decoration == decoration;
  }

  @override
  int get hashCode {
    return color.hashCode ^
        fontStyle.hashCode ^
        fontWeight.hashCode ^
        decoration.hashCode;
  }

  @override
  String toString() {
    return 'TextStyle(color: $color, fontStyle: $fontStyle, fontWeight: $fontWeight, decoration: $decoration)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'color': color?.toMap(),
      'fontStyle': fontStyle?.index,
      'fontWeight': fontWeight?.index,
      'decoration': decoration?.index,
    };
  }

  factory TextStyle.fromMap(Map<String, dynamic> map) {
    return TextStyle(
      color: map['color'] != null ? Color(map['color'] as int) : null,
      fontStyle: map['fontStyle'] != null
          ? FontStyle.values[map['fontStyle'] as int]
          : null,
      fontWeight: map['fontWeight'] != null
          ? FontWeight.values[map['fontWeight'] as int]
          : null,
      decoration: map['decoration'] != null
          ? TextDecoration.values[map['decoration'] as int]
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TextStyle.fromJson(String source) =>
      TextStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  String? toCSS() {
    final css = <String>[];
    if (color != null) {
      var colorString = color!.value.toRadixString(16);
      // Remove alpha channel
      colorString = colorString.substring(2);
      css.add('color: #$colorString;');
    }
    if (fontStyle == FontStyle.italic) {
      css.add('font-style: italic;');
    }
    if (fontStyle == FontStyle.bold) {
      css.add('font-weight: bold;');
    }
    if (fontWeight != null) {
      css.add('font-weight: bold;');
    }
    if (decoration != null) {
      css.add('text-decoration: underline;');
    }
    if (css.isEmpty) {
      return null;
    } else {
      return css.join('\n');
    }
  }
}

/// A class that represents a text style that can change based on the theme.
class DynamicTextStyle {
  final TextStyle? lightStyle;
  final TextStyle? darkStyle;

  DynamicTextStyle({
    required this.lightStyle,
    required this.darkStyle,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lightStyle': lightStyle?.toMap(),
      'darkStyle': darkStyle?.toMap(),
    };
  }

  factory DynamicTextStyle.fromMap(Map<String, dynamic> map) {
    return DynamicTextStyle(
      lightStyle: map['lightStyle'] != null
          ? TextStyle.fromMap(map['lightStyle'] as Map<String, dynamic>)
          : null,
      darkStyle: map['darkStyle'] != null
          ? TextStyle.fromMap(map['darkStyle'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DynamicTextStyle.fromJson(String source) =>
      DynamicTextStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant DynamicTextStyle other) {
    if (identical(this, other)) return true;

    return other.lightStyle == lightStyle && other.darkStyle == darkStyle;
  }

  @override
  int get hashCode => lightStyle.hashCode ^ darkStyle.hashCode;

  @override
  String toString() =>
      'DynamicTextStyle(lightStyle: $lightStyle, darkStyle: $darkStyle)';

  String toCss(String className) {
    var css = '';
    css += ".$className { ${lightStyle?.toCSS() ?? ""} }\n";
    css +=
        "@media (prefers-color-scheme: dark) { .$className { ${darkStyle?.toCSS() ?? ""} } }\n";
    return css;
  }
}

String lookupClassName(DynamicTextStyle cssClass) {
  final className = styles[cssClass];
  if (className == null) {
    throw Exception(
      'A class name was not found for a given style. '
      'Please add the style to the styles map in the css_classes.dart file. '
      'Then you must add the class to the CSS file. '
      'Style: $cssClass',
    );
  }
  return className;
}

/// A span of text with a light and dark [TextStyle]s.
class TextSpan {
  final List<TextSpan> children;
  final String? text;
  final DynamicTextStyle? cssClass;
  const TextSpan({this.text, required this.cssClass, this.children = const []});

  String toHTML() {
    var html = '';
    var classes = <DynamicTextStyle>{};
    final String? className;
    if (text != null) {
      html += text!.replaceAll(" ", "&nbsp;").replaceAll('\n', "<br>");
    }
    if (cssClass != null) {
      classes.add(cssClass!);
      className = lookupClassName(cssClass!);
    } else {
      className = null;
    }

    if (children.isNotEmpty) {
      for (var child in children) {
        html += child.toHTML();
      }
    }

    return '<span ${className == null ? "" : "class=$className"} >$html</span>';
  }
}

/// Predefined styles to css classes lookup table.
final styles = <DynamicTextStyle, String>{
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4278814810)),
      darkStyle: TextStyle(color: Color(4290105000))): "syntaxHighlight-1",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4278190080)),
      darkStyle: TextStyle(color: Color(4292138196))): "syntaxHighlight-2",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4284264175)),
      darkStyle: TextStyle(color: Color(4284264175))): "syntaxHighlight-3",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4283412924)),
      darkStyle: TextStyle(color: Color(4283412924))): "syntaxHighlight-4",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4288877845)),
      darkStyle: TextStyle(color: Color(4291727736))): "syntaxHighlight-5",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4289442496)),
      darkStyle: TextStyle(color: Color(4289442496))): "syntaxHighlight-6",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4278222848)),
      darkStyle: TextStyle(color: Color(4284517198))): "syntaxHighlight-7",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4292852086)),
      darkStyle: TextStyle(color: Color(4292852086))): "syntaxHighlight-8",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4286144038)),
      darkStyle: TextStyle(color: Color(4292664490))): "syntaxHighlight-9",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4288135788)),
      darkStyle: TextStyle(color: Color(4288135788))): "syntaxHighlight-10",
  DynamicTextStyle(
      lightStyle: null,
      darkStyle: TextStyle(color: Color(4292138196))): "SyntaxHighlight-11",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4278190335)),
      darkStyle: TextStyle(color: Color(4283866326))): "SyntaxHighlight-12",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4280713113)),
      darkStyle: TextStyle(color: Color(4283353520))): "SyntaxHighlight-13",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4289659099)),
      darkStyle: TextStyle(color: Color(4291135168))): "SyntaxHighlight-14",
  DynamicTextStyle(
      lightStyle: TextStyle(color: Color(4290867929)),
      darkStyle: TextStyle(color: Color(4290867929))): "SyntaxHighlight-15",
  DynamicTextStyle(
      lightStyle: TextStyle(
          color: Color(4278190216),
          fontStyle: null,
          fontWeight: null,
          decoration: null),
      darkStyle: TextStyle(
          color: Color(4290375423),
          fontStyle: null,
          fontWeight: null,
          decoration: null)): "SyntaxHighlight-16",
  DynamicTextStyle(
      lightStyle: TextStyle(
          color: Color(4294901760),
          fontStyle: null,
          fontWeight: null,
          decoration: null),
      darkStyle: TextStyle(
          color: Color(4294901760),
          fontStyle: null,
          fontWeight: null,
          decoration: null)): "SyntaxHighlight-17"
};

// Small script for generating the CSS file from the styles map.
// This needs to be run manually when the styles map is updated.
void main() {
  var css = '';
  for (final MapEntry(key: style, value: className) in styles.entries) {
    css += style.toCss(className);
    css += '\n';
  }
  print(css);
}
