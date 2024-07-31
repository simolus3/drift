import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:source_span/source_span.dart';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'directive.dart';

const _equality = ListEquality();

/// A section of a file that is marked by a `#docregion` directive.
@sealed
class _ContinousRegion {
  final int startLine;
  final int endLineExclusive;

  /// The directives introducing this region.
  ///
  /// The [start] directive is only null for the full region covering the entire
  /// file. The [end] directive is only null if a region was not explicitly
  /// ended with a `#docendregion` directive.
  final Directive? start, end;

  final String indentation;

  _ContinousRegion(this.startLine, this.endLineExclusive,
      {this.start, this.end, this.indentation = ''});

  @override
  int get hashCode => Object.hash(startLine, endLineExclusive);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ContinousRegion &&
            other.startLine == startLine &&
            other.endLineExclusive == endLineExclusive &&
            other.indentation == indentation;
  }
}

/// Temporary data structure to store partialy constructed regions.
class _PendingRegion {
  final String excerpt;
  final int startLine;

  final Directive? start;
  String indentation;

  _PendingRegion(this.excerpt, this.startLine, this.start)
      : indentation = start?.indentation ?? '';
}

/// A code excerpt extracted from a file.
class _Excerpt {
  final String name;
  final List<_ContinousRegion> regions;

  _Excerpt(this.name, this.regions);

  @override
  int get hashCode => Object.hash(name, _equality.hash(regions));

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _Excerpt &&
            other.name == name &&
            _equality.equals(other.regions, regions);
  }

  String toSnippet({required SourceFile file, bool removeIndent = true}) {
    final buffer = StringBuffer();

    void text(FileSpan span, [int stripIndent = 0]) {
      if (stripIndent == 0) {
        buffer.write(span.text);
      } else {
        // Go through the span line by line. If it starts at the beginning of a
        // line, drop the first [stripIndent] units.
        final file = span.file;

        // First line, cut of `start column - stripIndent` chars at the start
        buffer.write(file.getText(
          span.start.offset + max(0, stripIndent - span.start.column),
          min(file.getOffset(span.start.line + 1) - 1, span.end.offset),
        ));

        for (var line = span.start.line + 1; line <= span.end.line; line++) {
          buffer.writeln();

          final endOffset = min(file.getOffset(line + 1) - 1, span.end.offset);
          final start = file.getOffset(line) + stripIndent;

          if (start < endOffset) {
            // If the span spans multiple lines and this isn't the first one, we
            // can just cut of the first chars.
            buffer.write(file.getText(start, endOffset));
          }
        }
      }
    }

    _ContinousRegion? latestChunk;
    for (final chunk in this.regions) {
      final stripIndent = removeIndent ? chunk.indentation.length : 0;
      // If there was a previous chunk, add a newline.
      if (latestChunk != null) {
        buffer.write('\n');
      }

      // Get the offset of the first line of the region.
      var offset = file.getOffset(chunk.startLine);

      // Insert the text of the region.
      text(file.span(offset, file.getOffset(chunk.endLineExclusive) - 1),
          stripIndent);

      // Update the last chunk.
      latestChunk = chunk;
    }

    return buffer.toString();
  }
}

/// Extracts code snippets from a string.
class _Excerpter {
  static const _fullFileKey = '(full)';
  static const _defaultRegionKey = '';

  final String content;
  final List<String> _lines; // content as list of lines

  // Index of next line to process.
  int _lineIdx;
  int get _lineNum => _lineIdx + 1;
  String get _line => _lines[_lineIdx];

  bool containsDirectives = false;

  int get numExcerpts => excerpts.length;

  _Excerpter(this.content)
      : _lines = const LineSplitter().convert(content),
        _lineIdx = 0;

  final Map<String, _Excerpt> excerpts = {};
  final List<_PendingRegion> _openExcerpts = [];

  void weave() {
    // Collect the full file in case we need it.
    _excerptStart(_fullFileKey);

    for (_lineIdx = 0; _lineIdx < _lines.length; _lineIdx++) {
      _processLine();
    }

    // End all regions at the end
    for (final open in _openExcerpts) {
      // Don't warn for empty regions if the second-last line is a directive
      _closePending(open, allowEmpty: open.start == null);
    }
  }

  void _processLine() {
    final directive = Directive.tryParse(_line);

    if (directive != null) {
      directive.issues.forEach(_warn);

      switch (directive.kind) {
        case Kind.startRegion:
          containsDirectives = true;
          _startRegion(directive);
          break;
        case Kind.endRegion:
          containsDirectives = true;
          _endRegion(directive);
          break;
        default:
          throw Exception('Unimplemented directive: $_line');
      }

      // Interrupt pending regions, they should not contain this line with
      // a directive.
      final pending = _openExcerpts.toList();
      for (final open in pending) {
        if (open.startLine <= _lineIdx) {
          _closePending(open, allowEmpty: true);
          _openExcerpts.remove(open);
          _openExcerpts.add(
              _PendingRegion(open.excerpt, _lineIdx + 1, open.start)
                ..indentation = open.indentation);
        }
      }
    } else if (_line.isNotEmpty) {
      // Check if open regions have their whitespace indendation across all
      // active lines.
      for (final open in _openExcerpts) {
        if (!_line.startsWith(open.indentation)) {
          open.indentation = '';
        }
      }
    }
  }

  void _startRegion(Directive directive) {
    final regionAlreadyStarted = <String>[];
    final regionNames = directive.args;

    log('_startRegion(regionNames = $regionNames)');

    if (regionNames.isEmpty) regionNames.add(_defaultRegionKey);
    for (final name in regionNames) {
      final isNew = _excerptStart(name, directive);
      if (!isNew) {
        regionAlreadyStarted.add(_quoteName(name));
      }
    }

    _warnRegions(
      regionAlreadyStarted,
      (regions) => 'repeated start for $regions',
    );
  }

  void _endRegion(Directive directive) {
    final regionsWithoutStart = <String>[];
    final regionNames = directive.args;
    log('_endRegion(regionNames = $regionNames)');

    if (regionNames.isEmpty) {
      regionNames.add('');
      // _warn('${directive.lexeme} has no explicit arguments; assuming ""');
    }

    outer:
    for (final name in regionNames) {
      for (final open in _openExcerpts) {
        if (open.excerpt == name) {
          _closePending(open);
          _openExcerpts.remove(open);
          continue outer;
        }
      }

      // No matching region found, otherwise we would have returned.
      regionsWithoutStart.add(_quoteName(name));
    }

    _warnRegions(
      regionsWithoutStart,
      (regions) => '$regions end without a prior start',
    );
  }

  void _warnRegions(
    List<String> regions,
    String Function(String) msg,
  ) {
    if (regions.isEmpty) return;
    final joinedRegions = regions.join(', ');
    final s = regions.isEmpty
        ? ''
        : regions.length > 1
            ? 's ($joinedRegions)'
            : ' $joinedRegions';
    _warn(msg('region$s'));
  }

  void _closePending(_PendingRegion pending, {bool allowEmpty = false}) {
    final excerpt = excerpts[pending.excerpt];
    if (excerpt == null) return;

    if (pending.startLine == _lineIdx) {
      if (!allowEmpty) {
        _warnRegions(
          [pending.excerpt],
          (regions) => 'empty $regions',
        );
      }

      return;
    }

    excerpt.regions.add(_ContinousRegion(pending.startLine, _lineIdx,
        indentation: pending.indentation));
  }

  /// Registers [name] as an open excerpt.
  ///
  /// Returns false iff name was already open
  bool _excerptStart(String name, [Directive? directive]) {
    excerpts.putIfAbsent(name, () => _Excerpt(name, []));

    if (_openExcerpts.any((e) => e.excerpt == name)) {
      return false; // Already open!
    }

    // Start region on next line if the current line is a directive.
    _openExcerpts.add(_PendingRegion(
        name, directive == null ? _lineIdx : _lineIdx + 1, directive));
    return true;
  }

  void _warn(String msg) => log('$msg at $_lineNum');

  /// Quote a region name if it isn't already quoted.
  String _quoteName(String name) => name.startsWith("'") ? name : '"$name"';
}

/// This function is a simplified version of `code_snippets`.
/// No highlighting is applied to the code snippets.
/// The code snippets are extracted from the given [code] and returned as a map of {"snippet name": "snippet code"}.
Map<String, String> extractSnippets(String code, {bool removeIndent = true}) {
  final excerpter = _Excerpter(code)..weave();
  return excerpter.excerpts.map((key, value) => MapEntry(
      key,
      value.toSnippet(
        file: SourceFile.fromString(code),
        removeIndent: removeIndent,
      )));
}
