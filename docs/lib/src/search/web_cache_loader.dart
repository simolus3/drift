import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'loader.dart';

/// A [SearchIndexLoader] storing partial responses in the `window.cache` API.
///
/// Because that API can't index partial responses, we use fake requests
/// containing the page id in its URL.
final class CachedIndexLoader implements SearchIndexLoader {
  final SearchIndexLoader _fallback;
  web.Cache? _cache;

  CachedIndexLoader(this._fallback);

  @override
  void close() {
    _fallback.close();
  }

  @override
  Future<SearchDatabaseInfo> fetchMeta() async {
    final meta = await _fallback.fetchMeta();
    try {
      _cache = await _openCache(meta.hash);
    } on Object catch (e) {
      print('Could not open search cache: $e');
    }

    return meta;
  }

  @override
  Future<FetchedPages> fetchPage(PageFetchQuery query) async {
    final cache = _cache;
    if (cache == null) {
      return await _fallback.fetchPage(query);
    }

    var fromCache = Uint8List(query.length);
    var hasMissingPages = false;
    for (var page = query.startPage; page < query.endPage; page++) {
      final cacheKey = '/${query.info.hash}/$page'.toJS;
      final cached = await cache.match(cacheKey).toDart;
      if (cached case final response?) {
        final bytes = await response.bytes().toDart;
        final startOffset =
            (page - query.startPage) * SearchIndexLoader.pageSize;

        fromCache.setRange(
          startOffset,
          startOffset + SearchIndexLoader.pageSize,
          bytes.toDart,
        );
      } else {
        hasMissingPages = true;
        break;
      }
    }

    if (!hasMissingPages) {
      return FetchedPages(startPage: query.startPage, pages: fromCache);
    }

    final source = await _fallback.fetchPage(query);
    final endPage = source.endPage;
    for (var page = source.startPage; page < endPage; page++) {
      final cacheKey = '/${query.info.hash}/$page'.toJS;
      cache.put(cacheKey, web.Response(source.viewPage(page).toJS));
    }

    return source;
  }

  Future<web.Cache?> _openCache(String hash) async {
    final cache = _cacheStorage;
    if (cache == null) {
      return null;
    }

    const prefix = 'search-';
    final targetKey = '$prefix$hash';
    final opened = await cache.open(targetKey).toDart;

    // Delete all others.
    for (final existing in (await cache.keys().toDart).toDart) {
      final key = existing.toDart;
      if (key.startsWith('search-') && key != targetKey) {
        print('Deleting outdated search cache $key');
        await cache.delete(key).toDart;
      }
    }

    return opened;
  }
}

@JS('caches')
external web.CacheStorage? get _cacheStorage;
