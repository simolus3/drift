import 'dart:async';

import 'package:drift/drift.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:sqlite3/wasm.dart';

import 'database.dart';
import 'loader.dart';
import 'web_cache_loader.dart';

final searchDatabase = FutureProvider((ref) async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('/sqlite3.wasm'));
  return await SearchDatabase.open(
    sqlite,
    CachedIndexLoader(SearchIndexLoader.http(Uri.parse('/search.db.json'))),
  );
});

final class SearchTermNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void search(String text) {
    state = text;
  }

  static final provider = NotifierProvider(SearchTermNotifier.new);
}

final class SearchResults {
  final List<SearchResult> results;
  final SearchResult? active;

  const SearchResults(this.results, this.active);
}

final class SearchResultsNotifier extends AsyncNotifier<SearchResults> {
  late final SearchDatabase _database;

  Completer<void>? _abortCurrentSearch;
  Future<void>? _currentSearch;

  @override
  FutureOr<SearchResults> build() async {
    _database = await ref.read(searchDatabase.future);

    ref.listen(SearchTermNotifier.provider, (_, term) async {
      if (term.length >= 3) {
        _abortCurrentSearch?.complete();
        Future<void> startSearch() {
          assert(_currentSearch == null);
          final abort = _abortCurrentSearch = Completer();
          return _search(term, abort.future).whenComplete(() {
            _currentSearch = null;
          });
        }

        await _currentSearch;
        _currentSearch ??= startSearch();
      }
    }, fireImmediately: true);

    ref.onCancel(() => _abortCurrentSearch?.complete());
    return const SearchResults([], null);
  }

  Future<void> _search(String text, Future<void> cancel) async {
    print('Starting search for $text');
    state = AsyncLoading();
    try {
      var collectedItems = <SearchResult>[];

      await for (final item in _database.search(text, cancel: cancel).take(5)) {
        collectedItems.add(item);
        state = AsyncData(SearchResults(collectedItems, null));
      }
    } on CancellationException {
      return;
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  set activeResult(SearchResult result) {
    if (state case AsyncData(:final value)) {
      state = AsyncData(SearchResults(value.results, result));
    }
  }

  void activeUp() {
    _activeNext(-1);
  }

  void activeDown() {
    _activeNext(1);
  }

  void _activeNext(int offset) {
    if (state case AsyncData(
      value: SearchResults(:final results, :final active),
    )) {
      final originalIndex = active == null ? -1 : results.indexOf(active);
      final nextIndex = switch (originalIndex) {
        -1 => offset.isNegative ? results.length - 1 : 0,
        _ => (originalIndex + offset) % results.length,
      };

      state = AsyncData(SearchResults(results, results[nextIndex]));
    }
  }

  static final provider = AsyncNotifierProvider(SearchResultsNotifier.new);
}
