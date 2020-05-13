import 'package:source_span/source_span.dart';

/// Interface for entities that appear in a piece of text. As far as the
/// parser is concerned, this contains tokens and ast nodes.
abstract class SyntacticEntity {
  /// Whether this entity has a source span associated with it.
  bool get hasSpan;

  /// The piece of text forming this syntactic entity.
  FileSpan get span;

  /// The first position of this entity, as an zero-based offset in the file it
  /// was read from.
  ///
  /// Instead of returning null, this getter may throw for entities where
  /// [hasSpan] is false.
  int get firstPosition;

  /// The (exclusive) last index of this entity in the source.
  ///
  /// Instead of returning null, this getter may throw for entities where
  /// [hasSpan] is false.
  int get lastPosition;

  /// Whether this entity is synthetic, meaning that it doesn't appear in the
  /// actual source.
  bool get synthetic;
}

/// Extension to report the length of a [SyntacticEntity].
extension SyntacticLengthExtension on SyntacticEntity {
  /// The length of this entity, in characters.
  int get length => lastPosition - firstPosition;
}

/// Extension to obtain the span for a sequence of [SyntacticEntity].
extension UnionEntityExtension on Iterable<SyntacticEntity> {
  /// Creates the span covered by all of the entities in this iterable.
  FileSpan get span {
    if (isEmpty) {
      throw ArgumentError.value(this, 'this', 'Was empty');
    }

    final firstSpan = first.span;
    return skip(1).fold(
      firstSpan,
      (previousValue, entity) => previousValue.expand(entity.span),
    );
  }
}
