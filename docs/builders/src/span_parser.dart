// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is taken from DevTools and should be kept in-sync with any changes
// that affect the resulting tokens.
//
// https://github.com/flutter/devtools/blob/master/packages/devtools_app/lib/src/screens/debugger/span_parser.dart

// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:string_scanner/string_scanner.dart';

const _neverMatchingRegexStr = r'^(?!x)x';

//TODO(jacobr): cleanup.
// ignore: avoid_classes_with_only_static_members
abstract class SpanParser {
  /// Takes a TextMate [Grammar] and a [String] and outputs a list of
  /// [ScopeSpan]s corresponding to the parsed input.
  static List<ScopeSpan> parse(Grammar grammar, String src) {
    final scopeStack = ScopeStack();
    final scanner = LineScanner(src);
    while (!scanner.isDone) {
      final foundMatch =
          grammar.topLevelMatcher.scan(grammar, scanner, scopeStack);
      if (!foundMatch && !scanner.isDone) {
        // Found no match, move forward by a character and try again.
        scanner.readChar();
      }
    }
    scopeStack.popAll(scanner.location);
    return scopeStack.spans;
  }
}

/// A representation of a TextMate grammar used to create [ScopeSpan]s
/// representing scopes within a body of text.
///
/// References used:
///   - Grammar specification:
///       https://macromates.com/manual/en/language_grammars#language_grammars
///   - Helpful blog post which clears up ambiguities in the spec:
///       https://www.apeth.com/nonblog/stories/textmatebundle.html
///
class Grammar {
  factory Grammar.fromJson(Map<String, Object?> json) {
    return Grammar._(
      name: json['name'] as String,
      scopeName: json['scopeName'] as String,
      topLevelMatcher: GrammarMatcher.parse(json),
      repository: Repository.build(json),
    );
  }

  Grammar._({
    this.name,
    this.scopeName,
    required this.topLevelMatcher,
    required this.repository,
  });

  final String? name;

  final String? scopeName;

  final GrammarMatcher topLevelMatcher;

  final Repository repository;

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert({
      'name': name,
      'scopeName': scopeName,
      'topLevelMatcher': topLevelMatcher.toJson(),
      'repository': repository.toJson(),
    });
  }
}

/// A representation of a span of text which has `scope` applied to it.
class ScopeSpan {
  ScopeSpan({
    required this.scopes,
    required ScopeStackLocation startLocation,
    required ScopeStackLocation endLocation,
  })  : _startLocation = startLocation,
        _endLocation = endLocation;

  ScopeStackLocation get startLocation => _startLocation;
  ScopeStackLocation get endLocation => _endLocation;
  int get start => _startLocation.position;
  int get end => _endLocation.position;
  int get length => end - start;

  final ScopeStackLocation _startLocation;
  ScopeStackLocation _endLocation;

  /// The one-based line number.
  int get line => startLocation.line + 1;

  /// The one-based column number.
  int get column => startLocation.column + 1;

  final List<String> scopes;

  bool contains(int token) => (start <= token) && (token < end);

  /// Splits the current [ScopeSpan] into multiple spans separated by [cond].
  /// This is useful for post-processing the results from a rule with a while
  /// condition as formatting should not be applied to the characters that
  /// match the while condition.
  List<ScopeSpan> split(LineScanner scanner, RegExp cond) {
    final splitSpans = <ScopeSpan>[];

    // Create a temporary scanner, copying [0, end] to ensure that line/column
    // information is consistent with the original scanner.
    final splitScanner = LineScanner(
      scanner.substring(0, end),
      position: start,
    );

    // Start with a copy of the original span
    ScopeSpan current = ScopeSpan(
      scopes: scopes.toList(),
      startLocation: startLocation,
      endLocation: endLocation,
    );

    while (!splitScanner.isDone) {
      if (splitScanner.matches(cond)) {
        // Update the end position for this span as it's been fully processed.
        current._endLocation = splitScanner.location;
        splitSpans.add(current);

        // Move the scanner position past the matched condition.
        splitScanner.scan(cond);

        // Create a new span based on the current position.
        current = ScopeSpan(
          scopes: scopes.toList(),
          startLocation: splitScanner.location,
          // Will be updated later.
          endLocation: ScopeStackLocation.zero,
        );
      } else {
        // Move scanner position forward.
        splitScanner.readChar();
      }
    }
    // Finish processing the last span, which will always have the same end
    // position as the span we're splitting.
    current._endLocation = endLocation;
    splitSpans.add(current);

    return splitSpans;
  }

  @override
  String toString() {
    return '[$start, $end, $line:$column (len: $length)] = $scopes';
  }
}

/// A top-level repository of rules that can be referenced within other rules
/// using the 'includes' keyword.
class Repository {
  Repository.build(Map<String, Object?> grammarJson) {
    final repositoryJson = (grammarJson['repository'] as Map<String, Object?>?)
        ?.cast<String, Map<String, Object?>>();
    if (repositoryJson == null) {
      return;
    }
    for (final subRepo in repositoryJson.keys) {
      matchers[subRepo] = GrammarMatcher.parse(repositoryJson[subRepo]!);
    }
  }

  final matchers = <String?, GrammarMatcher>{};

  Map<String, Object?> toJson() {
    return {
      for (final entry in matchers.entries)
        if (entry.key != null) entry.key!: entry.value.toJson(),
    };
  }
}

abstract class GrammarMatcher {
  factory GrammarMatcher.parse(Map<String, Object?> json) {
    if (_IncludeMatcher.isType(json)) {
      return _IncludeMatcher(json['include'] as String);
    } else if (_SimpleMatcher.isType(json)) {
      try {
        return _SimpleMatcher(json);
      } catch (e) {
        return _SimpleMatcher({
          'match': _neverMatchingRegexStr,
        });
      }
    } else if (_MultilineMatcher.isType(json)) {
      try {
        return _MultilineMatcher(json);
      } catch (e) {
        return _MultilineMatcher({
          'begin': _neverMatchingRegexStr,
        });
      }
    } else if (_PatternMatcher.isType(json)) {
      return _PatternMatcher(json);
    }
    throw StateError('Unknown matcher type: $json');
  }

  GrammarMatcher._(Map<String, Object?> json) : name = json['name'] as String?;

  final String? name;

  bool scan(Grammar grammar, LineScanner scanner, ScopeStack scopeStack);

  void _applyCapture(
    Grammar grammar,
    LineScanner scanner,
    ScopeStack scopeStack,
    Map<String, Object?>? captures,
    ScopeStackLocation location,
  ) {
    final lastMatch = scanner.lastMatch!;
    final start = lastMatch.start;
    final end = lastMatch.end;
    final matchStartLocation = location;
    if (captures != null) {
      final match = scanner.substring(start, end);
      for (int i = 0; i <= lastMatch.groupCount; ++i) {
        // Skip if we don't have a scope or nested patterns for this capture.
        if (!captures.containsKey(i.toString())) continue;

        final captureText = lastMatch.group(i);
        if (captureText == null || captureText.isEmpty) continue;

        final startOffset = match.indexOf(captureText);
        final capture = captures[i.toString()] as Map<String, Object?>;
        final captureStartLocation = matchStartLocation.offset(startOffset);
        final captureEndLocation =
            captureStartLocation.offset(captureText.length);
        final captureName = capture['name'] as String?;

        scopeStack.push(captureName, captureStartLocation);

        // Handle nested pattern matchers.
        if (capture.containsKey('patterns')) {
          final captureScanner = LineScanner(
            scanner.substring(0, captureEndLocation.position),
            position: captureStartLocation.position,
          );
          GrammarMatcher.parse(capture)
              .scan(grammar, captureScanner, scopeStack);
        }

        scopeStack.pop(captureName, captureEndLocation);
      }
    }
  }

  Map<String, Object?> toJson();
}

/// A simple matcher which matches a single line.
class _SimpleMatcher extends GrammarMatcher {
  _SimpleMatcher(Map<String, Object?> json)
      : match = RegExp(json['match'] as String, multiLine: true),
        captures = (json['captures'] as Map<String, Object?>?)
            ?.cast<String, Map<String, Object?>>(),
        super._(json);

  static bool isType(Map<String, Object?> json) {
    return json.containsKey('match');
  }

  final RegExp match;

  final Map<String, Object?>? captures;

  @override
  bool scan(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    final location = scanner.location;
    if (scanner.scan(match)) {
      scopeStack.push(name, location);
      _applyCapture(grammar, scanner, scopeStack, captures, location);
      scopeStack.pop(name, scanner.location);
      return true;
    }
    return false;
  }

  @override
  Map<String, Object?> toJson() {
    return {
      if (name != null) 'name': name,
      'match': match.pattern,
      if (captures != null) 'captures': captures,
    };
  }
}

class _MultilineMatcher extends GrammarMatcher {
  _MultilineMatcher(Map<String, Object?> json)
      : begin = RegExp(json['begin'] as String, multiLine: true),
        beginCaptures = json['beginCaptures'] as Map<String, Object?>?,
        contentName = json['contentName'] as String?,
        end = json['end'] == null
            ? null
            : RegExp(json['end'] as String, multiLine: true),
        endCaptures = json['endCaptures'] as Map<String, Object?>?,
        captures = json['captures'] as Map<String, Object?>?,
        whileCond = json['while'] == null
            ? null
            : RegExp(json['while'] as String, multiLine: true),
        patterns = (json['patterns'] as List<Object?>?)
            ?.cast<Map<String, Object?>>()
            .map((e) => GrammarMatcher.parse(e))
            .toList()
            .cast<GrammarMatcher>(),
        super._(json);

  static bool isType(Map<String, Object?> json) {
    return json.containsKey('begin') &&
        (json.containsKey('end') || json.containsKey('while'));
  }

  /// A regular expression which defines the beginning match of this rule. This
  /// property is required and must be defined along with either `end` or
  /// `while`.
  final RegExp begin;

  /// A set of scopes to apply to groups captured by `begin`. `captures` should
  /// be null if this property is provided.
  final Map<String, Object?>? beginCaptures;

  /// The scope that applies to the content between the matches found by
  /// `begin` and `end`.
  final String? contentName;

  /// A regular expression which defines the match signaling the end of the
  /// rule application. This property is mutually exclusive with the `while`
  /// property.
  final RegExp? end;

  /// A set of scopes to apply to groups captured by `begin`. `captures` should
  /// be null if this property is provided.
  final Map<String, Object?>? endCaptures;

  /// A regular expression corresponding with the `while` property used to
  /// determine if the next line should have the current rule applied. If
  /// `patterns` is provided, the contents of a line that satisfy this regular
  /// expression will be processed against the provided patterns.
  ///
  /// This expression is applied to every line **after** the first line matched
  /// by `begin`. If this expression fails after the line matched by `begin`,
  /// the overall rule does not fail and the resulting [ScopeSpan]s will consist
  /// of matches found in the first line.
  ///
  /// This property is mutually exclusive with the `end` property.
  final RegExp? whileCond;

  /// A set of scopes to apply to groups captured by `begin` and `end`.
  /// Providing this property is the equivalent of setting `beginCaptures` and
  /// `endCaptures` to the same value. `beginCaptures` and `endCaptures` should
  /// be null if this property is provided.
  final Map<String, Object?>? captures;

  final List<GrammarMatcher>? patterns;

  void _scanBegin(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    final location = scanner.location;
    if (!scanner.scan(begin)) {
      // This shouldn't happen since we've already checked that `begin` matches
      // the beginning of the string.
      throw StateError('Expected ${begin.pattern} to match.');
    }
    _processCaptureHelper(
      grammar,
      scanner,
      scopeStack,
      beginCaptures,
      location,
    );
  }

  void _scanToEndOfLine(
    Grammar grammar,
    LineScanner scanner,
    ScopeStack scopeStack,
  ) {
    while (!scanner.isDone) {
      if (String.fromCharCode(scanner.peekChar()!) == '\n') {
        scanner.readChar();
        break;
      }
      bool foundMatch = false;
      for (final pattern in patterns ?? <GrammarMatcher>[]) {
        if (pattern.scan(grammar, scanner, scopeStack)) {
          foundMatch = true;
          break;
        }
      }
      if (!foundMatch) {
        scanner.readChar();
      }
    }
  }

  void _scanUpToEndMatch(
    Grammar grammar,
    LineScanner scanner,
    ScopeStack scopeStack,
  ) {
    while (!scanner.isDone && end != null && !scanner.matches(end!)) {
      bool foundMatch = false;
      for (final pattern in patterns ?? <GrammarMatcher>[]) {
        if (pattern.scan(grammar, scanner, scopeStack)) {
          foundMatch = true;
          break;
        }
      }
      if (!foundMatch) {
        // Move forward by a character, try again.
        scanner.readChar();
      }
    }
  }

  void _scanEnd(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    final location = scanner.location;
    if (end != null && !scanner.scan(end!)) {
      return;
    }
    _processCaptureHelper(grammar, scanner, scopeStack, endCaptures, location);
  }

  void _processCaptureHelper(
    Grammar grammar,
    LineScanner scanner,
    ScopeStack scopeStack,
    Map<String, Object?>? customCaptures,
    ScopeStackLocation location,
  ) {
    if (contentName == null || (customCaptures ?? captures) != null) {
      _applyCapture(
        grammar,
        scanner,
        scopeStack,
        customCaptures ?? captures,
        location,
      );
    }
  }

  @override
  bool scan(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    if (!scanner.matches(begin)) {
      return false;
    }

    scopeStack.push(name, scanner.location);
    _scanBegin(grammar, scanner, scopeStack);
    if (end != null) {
      scopeStack.push(contentName, scanner.location);
      _scanUpToEndMatch(grammar, scanner, scopeStack);
      scopeStack.pop(contentName, scanner.location);
      _scanEnd(grammar, scanner, scopeStack);
    } else if (whileCond != null) {
      // Find the range of the string that is matched by the while condition.
      final start = scanner.position;
      _skipLine(scanner);
      while (!scanner.isDone && whileCond != null && scanner.scan(whileCond!)) {
        _skipLine(scanner);
      }
      final end = scanner.position;

      // Create a temporary scanner to ensure that rules that don't find an
      // end match don't try and match all the way to the end of the file.
      final contentScanner = LineScanner(
        scanner.substring(0, end),
        position: start,
      );

      // Capture a marker for where the contents start, used later to split
      // spans.
      final whileContentBeginMarker = scopeStack.marker();

      _scanToEndOfLine(grammar, contentScanner, scopeStack);

      // Process each line until the `while` condition fails.
      while (!contentScanner.isDone &&
          whileCond != null &&
          contentScanner.scan(whileCond!)) {
        _scanToEndOfLine(grammar, contentScanner, scopeStack);
      }

      // Now, split any spans produced whileContentBeginMarker by `whileCond`.
      scopeStack.splitFromMarker(
        scanner,
        whileContentBeginMarker,
        whileCond!,
      );
    } else {
      throw StateError(
        "One of 'end' or 'while' must be provided for rule: $name",
      );
    }
    scopeStack.pop(name, scanner.location);
    return true;
  }

  void _skipLine(LineScanner scanner) {
    scanner.scan(RegExp('.*\n'));
  }

  @override
  Map<String, Object?> toJson() {
    return {
      if (name != null) 'name': name,
      'begin': begin.pattern,
      if (beginCaptures != null) 'beginCaptures': beginCaptures,
      if (end != null) 'end': end!.pattern,
      if (endCaptures != null) 'endCaptures': endCaptures,
      if (whileCond != null) 'while': whileCond!.pattern,
      if (patterns != null)
        'patterns': patterns!.map((e) => e.toJson()).toList(),
    };
  }
}

class _PatternMatcher extends GrammarMatcher {
  _PatternMatcher(Map<String, Object?> json)
      : patterns = (json['patterns'] as List<Object?>?)
            ?.cast<Map<String, Object?>>()
            .map((e) => GrammarMatcher.parse(e))
            .toList()
            .cast<GrammarMatcher>(),
        super._(json);

  static bool isType(Map<String, Object?> json) {
    return json.containsKey('patterns');
  }

  final List<GrammarMatcher>? patterns;

  @override
  bool scan(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    // Try each rule in the include and return after the first successful match.
    for (final pattern in patterns!) {
      if (pattern.scan(grammar, scanner, scopeStack)) {
        return true;
      }
    }
    return false;
  }

  @override
  Map<String, Object?> toJson() {
    return {
      if (name != null) 'name': name,
      if (patterns != null)
        'patterns': patterns!.map((e) => e.toJson()).toList(),
    };
  }
}

/// A [GrammarMatcher] that corresponds to an `include` rule referenced in a
/// `patterns` array. Allows for executing rules defined within a
/// [Repository].
class _IncludeMatcher extends GrammarMatcher {
  _IncludeMatcher(String include)
      : include = include.substring(1),
        super._({});

  final String include;

  static bool isType(Map<String, Object?> json) {
    return json.containsKey('include');
  }

  @override
  bool scan(Grammar grammar, LineScanner scanner, ScopeStack scopeStack) {
    final matcher = grammar.repository.matchers[include];
    if (matcher == null) {
      throw StateError('Could not find $include in the repository.');
    }
    return matcher.scan(grammar, scanner, scopeStack);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'include': include,
    };
  }
}

/// Tracks the current scope stack, producing [ScopeSpan]s as the contents
/// change.
class ScopeStack {
  ScopeStack();

  final stack = Queue<ScopeStackItem>();
  final spans = <ScopeSpan>[];

  /// Location where the next produced span should begin.
  ScopeStackLocation _nextLocation = ScopeStackLocation.zero;

  /// Adds a scope for a given region.
  ///
  /// This method is the same as calling [push] and then [pop] with the same
  /// args.
  void add(
    String? scope, {
    required ScopeStackLocation start,
    required ScopeStackLocation end,
  }) {
    push(scope, start);
    pop(scope, end);
  }

  /// Pushes a new scope onto the stack starting at [start].
  void push(String? scope, ScopeStackLocation location) {
    if (scope == null) return;

    // If the stack is empty, seed the position which is used for the start
    // of the next produced token.
    if (stack.isEmpty) {
      _nextLocation = location;
    }

    // Whenever we push a new item, produce a span for the region between the
    // last started scope and the new current position.
    if (location.position > _nextLocation.position) {
      final scopes = stack.map((item) => item.scope).toSet();
      _produceSpan(scopes, end: location);
    }

    // Add this new scope to the stack, but don't produce its token yet. We will
    // do that when the next item is pushed (in which case we'll fill the gap),
    // or when this item is popped (in which case we'll produce a span for that
    // full region).
    stack.add(ScopeStackItem(scope, location));
  }

  /// Pops the last scope off the stack, producing a token if necessary up until
  /// [end].
  void pop(String? scope, ScopeStackLocation end) {
    if (scope == null) return;
    assert(stack.isNotEmpty);

    final scopes = stack.map((item) => item.scope).toSet();
    final last = stack.removeLast();
    assert(last.scope == scope);
    assert(last.location.position <= end.position);

    _produceSpan(scopes, end: end);
  }

  void popAll(ScopeStackLocation location) {
    while (stack.isNotEmpty) {
      pop(stack.last.scope, location);
    }
  }

  /// Captures a marker to identify spans produced before/after this call.
  ScopeStackMarker marker() {
    return ScopeStackMarker(spanIndex: spans.length, location: _nextLocation);
  }

  /// Splits all spans created since [begin] by [condition].
  ///
  /// This is used to handle multiline spans that use begin/end such as
  /// capturing triple-backtick code blocks that would have captured the leading
  /// '/// ', which should not be included.
  void splitFromMarker(
    LineScanner scanner,
    ScopeStackMarker begin,
    RegExp condition,
  ) {
    // Remove the spans to be split. We will push new spans after splitting.
    final spansToSplit = spans.sublist(begin.spanIndex);
    if (spansToSplit.isEmpty) return;
    spans.removeRange(begin.spanIndex, spans.length);

    // Also rewind the last positions to the start place.
    _nextLocation = begin.location;

    // Add the split spans individually.
    for (final span in spansToSplit
        .expand((spanToSplit) => spanToSplit.split(scanner, condition))) {
      // To handler spans with multiple scopes, we need to push each scope, and
      // then pop each scope. We cannot use `add`.
      for (final scope in span.scopes) {
        push(scope, span.startLocation);
      }
      for (final scope in span.scopes.reversed) {
        pop(scope, span.endLocation);
      }
    }
  }

  void _produceSpan(
    Set<String> scopes, {
    required ScopeStackLocation end,
  }) {
    // Don't produce zero-width spans.
    if (end.position == _nextLocation.position) return;

    // If the new span starts at the same place that the previous one ends and
    // has the same scopes, we can replace the previous one with a single new
    // larger span.
    final newScopes = scopes.toList();
    final lastSpan = spans.lastOrNull;
    if (lastSpan != null &&
        lastSpan.endLocation.position == _nextLocation.position &&
        lastSpan.scopes.equals(newScopes)) {
      final span = ScopeSpan(
        scopes: newScopes,
        startLocation: lastSpan.startLocation,
        endLocation: end,
      );
      // Replace the last span with this one.
      spans.last = span;
    } else {
      final span = ScopeSpan(
        scopes: newScopes,
        startLocation: _nextLocation,
        endLocation: end,
      );
      spans.add(span);
    }
    _nextLocation = end;
  }
}

/// An item pushed onto the scope stack, consisting of a [String] scope and a
/// location.
class ScopeStackItem {
  ScopeStackItem(this.scope, this.location);

  final String scope;
  final ScopeStackLocation location;
}

/// A marker tracking a position in the list of produced tokens.
///
/// Used for back-tracking when handling nested multiline tokens.
class ScopeStackMarker {
  ScopeStackMarker({
    required this.spanIndex,
    required this.location,
  });

  final int spanIndex;
  final ScopeStackLocation location;
}

/// A location (including offset, line, column) in the code parsed for scopes.
class ScopeStackLocation {
  const ScopeStackLocation({
    required this.position,
    required this.line,
    required this.column,
  });

  static const zero = ScopeStackLocation(position: 0, line: 0, column: 0);

  /// 0-based offset in content.
  final int position;

  /// 0-based line number of [position].
  final int line;

  /// 0-based column number of [position].
  final int column;

  /// Returns a location offset by [offset] characters.
  ///
  /// This method does not handle line wrapping so should only be used where it
  /// is known that the offset does not wrap across a line boundary.
  ScopeStackLocation offset(int offset) {
    return ScopeStackLocation(
      position: position + offset,
      line: line,
      column: column + offset,
    );
  }
}

extension LineScannerExtension on LineScanner {
  ScopeStackLocation get location =>
      ScopeStackLocation(position: position, line: line, column: column);
}
