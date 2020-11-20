import 'dart:convert';
import 'dart:ffi';

import 'package:test/test.dart';
import 'package:sqlite3/open.dart';
import 'package:ffi/ffi.dart';

import 'package:sqlparser/src/reader/tokenizer/token.dart';

typedef sqlite3_keyword_count_native = Int32 Function();
typedef sqlite3_keyword_count = int Function();

typedef sqlite3_keyword_name_native = Int32 Function(
    Int32, Pointer<Pointer<Uint8>>, Pointer<Int32>);
typedef sqlite3_keyword_name = int Function(
    int, Pointer<Pointer<Uint8>>, Pointer<Int32>);

void main() {
  String skip;
  DynamicLibrary library;

  try {
    library = open.openSqlite();

    // Some platforms have sqlite3, but no sqlite3_keyword_count
    library.lookup('sqlite3_keyword_count');
  } on dynamic {
    skip = 'sqlite3 is not available in test environment';
  }

  test(
    'recognizes all sqlite tokens',
    () {
      final keywordCount = library.lookupFunction<sqlite3_keyword_count_native,
          sqlite3_keyword_count>('sqlite3_keyword_count')();
      final nameFunction = library.lookupFunction<sqlite3_keyword_name_native,
          sqlite3_keyword_name>('sqlite3_keyword_name');

      final charOut = allocate<Pointer<Uint8>>();
      final lengthOut = allocate<Int32>();

      final missingNames = <String>[];

      for (var i = 0; i < keywordCount; i++) {
        nameFunction(i, charOut, lengthOut);

        final bytes = charOut.value.asTypedList(lengthOut.value);
        final name = utf8.decode(bytes);

        if (!keywords.containsKey(name)) {
          missingNames.add(name);
        }
      }

      missingNames.sort();

      free(charOut);
      free(lengthOut);

      expect(missingNames, isEmpty);
    },
    skip: skip,
  );
}
