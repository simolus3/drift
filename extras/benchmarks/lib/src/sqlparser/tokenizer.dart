import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';

// ignore: implementation_imports
import 'package:sqlparser/src/reader/tokenizer/token.dart';
// ignore: implementation_imports
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';

class TokenizerBenchmark extends BenchmarkBase {
  StringBuffer input;

  static const int size = 10000;

  TokenizerBenchmark(ScoreEmitter emitter)
      : super('Tokenizing $size keywords', emitter: emitter);

  @override
  void setup() {
    input = StringBuffer();

    final random = Random();
    final keywordLexemes = keywords.keys.toList();
    for (var i = 0; i < size; i++) {
      final keyword = keywordLexemes[random.nextInt(keywordLexemes.length)];
      input..write(' ')..write(keyword);
    }
  }

  @override
  void run() {
    final scanner = Scanner(input.toString());
    scanner.scanTokens();
  }
}
