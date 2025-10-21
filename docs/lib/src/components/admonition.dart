import 'package:markdown/markdown.dart';

/// Parses blocks of the format used by Material for MkDocs
/// [Admonitions](https://squidfunk.github.io/mkdocs-material/reference/admonitions/).
final class AdmonitionSyntax extends BlockSyntax {
  const AdmonitionSyntax();

  @override
  bool canParse(BlockParser parser) {
    return pattern.hasMatch(parser.current.content);
  }

  @override
  Node? parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final collapsible = match.group(1)! == '???';
    final type = match.group(2)!;
    final defaultTitle =
        _defaultTitles[type] ??
        (throw ArgumentError.value(
          type,
          'type',
          'Unknown type. Supported are: ${_defaultTitles.keys.join(', ')}',
        ));

    final title = match.group(3);
    final parsedTitle = InlineParser(
      title ?? defaultTitle,
      parser.document,
    ).parse();
    parser.advance();

    final childLines = parseChildLines(parser);
    final children = BlockParser(
      childLines,
      parser.document,
    ).parseLines(parentSyntax: this);

    if (collapsible) {
      return Element('details', [Element('summary', parsedTitle), ...children])
        ..attributes['class'] = type;
    } else {
      return Element('div', [
        Element('p', parsedTitle)..attributes['class'] = 'admonition-title',
        ...children,
      ])..attributes['class'] = 'admonition $type';
    }
  }

  @override
  List<Line> parseChildLines(BlockParser parser) {
    final consumed = <Line>[];

    while (!parser.isDone) {
      const prefix = '    ';
      final content = parser.current.content;

      if (content.trim().isEmpty) {
        consumed.add(Line(content));
      } else if (content.startsWith(prefix)) {
        consumed.add(Line(content.substring(prefix.length)));
      } else {
        break;
      }

      parser.advance();
    }

    return consumed;
  }

  @override
  RegExp get pattern => _pattern;

  static final _pattern = RegExp(r'(!!!|\?\?\?)\s+(\w+)(?:\s+"(.*)")?');

  static const _defaultTitles = {
    'note': 'Note',
    'abstract': 'Abstract',
    'info': 'Info',
    'tip': 'Tip',
    'success': 'Success',
    'question': 'Question',
    'warning': 'Warning',
    'failure': 'Failure',
    'danger': 'Danger',
    'bug': 'Bug',
    'example': 'Example',
    'quote': 'Quote',
  };
}
