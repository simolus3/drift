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

  void insertBefore(SyntacticEntity entity, String addedContent) {
    replace(entity.offset, 0, addedContent);
  }

  void insertAfter(SyntacticEntity entity, String addedContent) {
    replace(entity.end, 0, addedContent);
  }

  void swap(SyntacticEntity a, SyntacticEntity b) {
    // Assuming that content is $prefix $a $middle $b $suffix

    // $prefix
    final buffer = StringBuffer(content.substring(0, a.offset + _skew));

    // $prefix $b
    buffer.write(content.substring(b.offset + _skew, b.end + _skew));

    // $prefix $b $middle
    buffer.write(content.substring(a.end + _skew, b.offset + _skew));

    // $prefix $b $middle $a
    buffer.write(content.substring(a.offset + _skew, a.end + _skew));

    // $prefix $b $middle $a $suffix
    buffer.write(content.substring(b.end + _skew));

    content = buffer.toString();
  }
}

/// A regular expression matching build configuration file names.
final RegExp buildYamlPattern = RegExp('(?:\\w+\\.)?build(?:\\.\\w+)?');
