import 'package:analyzer/dart/ast/syntactic_entity.dart';

final class StringRewriter {
  String content;
  var _skew = 0;

  StringRewriter(this.content);

  void replace(int start, int originalLength, String newContent) {
    content = content.replaceRange(
      _skew + start,
      _skew + start + originalLength,
      newContent,
    );
    _skew += newContent.length - originalLength;
  }

  void replaceNode(SyntacticEntity entity, String newContent) {
    replace(entity.offset, entity.length, newContent);
  }
}

/// A regular expression matching build configuration file names.
final RegExp buildYamlPattern = RegExp('(?:\\w+\\.)?build(?:\\.\\w+)?');
