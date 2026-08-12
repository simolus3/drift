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
}

/// A regular expression matching build configuration file names.
final RegExp buildYamlPattern = RegExp('(?:\\w+\\.)?build(?:\\.\\w+)?');
