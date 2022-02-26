import 'package:source_span/source_span.dart';

bool intersect(SourceSpan a, SourceSpan b) {
  final startOfFirst = a.start.offset;
  final endOfFirst = a.end.offset;
  final startOfSecond = b.start.offset;
  final endOfSecond = b.end.offset;

  return !(endOfFirst < startOfSecond || startOfFirst > endOfSecond);
}
