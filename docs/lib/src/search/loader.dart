import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

abstract interface class SearchIndexLoader {
  factory SearchIndexLoader.http(Uri metaUri) = HttpSearchIndexLoader;

  /// Resolves meta information (size and hash) of the search database.
  Future<SearchDatabaseInfo> fetchMeta();

  /// Fetches a database page based on its index.
  ///
  /// Returns whether range requests are supported and contents. If range
  /// requests are not supported, the response is for the entire database.
  Future<FetchedPages> fetchPage(PageFetchQuery query);

  void close();

  static const pageSize = 4096;
}

final class SearchDatabaseInfo {
  final String hash;

  /// The total amount of pages in the search database.
  final int pages;

  SearchDatabaseInfo({required this.hash, required this.pages});
}

final class PageFetchQuery {
  final SearchDatabaseInfo info;

  /// Index of the first page to load.
  final int startPage;

  /// Exclusive end index, i.e. the first page to not load.
  final int endPage;

  int get length => (endPage - startPage) * SearchIndexLoader.pageSize;

  PageFetchQuery({
    required this.info,
    required this.startPage,
    required this.endPage,
  });
}

final class FetchedPages {
  /// The first page that has actually been loaded.
  ///
  /// This is usually the [PageFetchQuery.startPage], but can also be `0` if the
  /// server doesn't support range requests.
  final int startPage;

  /// Contents of pages, starting from [startPage].
  final Uint8List pages;

  int get pageCount => pages.length ~/ SearchIndexLoader.pageSize;

  int get endPage => startPage + pageCount;

  FetchedPages({required this.startPage, required this.pages});

  Uint8List viewPage(int no) {
    final index =
        RangeError.checkValueInInterval(no, startPage, endPage - 1) - startPage;

    return pages.buffer.asUint8List(
      pages.offsetInBytes + index * SearchIndexLoader.pageSize,
      SearchIndexLoader.pageSize,
    );
  }
}

/// A [SearchIndexLoader] implemented by one HTTP request per page.
final class HttpSearchIndexLoader implements SearchIndexLoader {
  final Client _client = Client();
  final Uri metaUri;

  HttpSearchIndexLoader(this.metaUri);

  @override
  Future<SearchDatabaseInfo> fetchMeta() async {
    final response = await _client.get(metaUri);
    if (response.statusCode != 200) {
      throw ClientException('Unexpected result code ${response.statusCode}');
    }

    final parsed = json.decode(response.body);
    return SearchDatabaseInfo(
      hash: parsed['hash'] as String,
      pages: parsed['blocks'] as int,
    );
  }

  @override
  Future<FetchedPages> fetchPage(PageFetchQuery query) async {
    final startOffset = query.startPage * SearchIndexLoader.pageSize;
    final endOffset = query.endPage * SearchIndexLoader.pageSize - 1;
    final response = await _client.get(
      metaUri.resolve('./${query.info.hash}.db'),
      headers: {'Range': 'bytes=$startOffset-$endOffset'},
    );

    return switch (response.statusCode) {
      200 => FetchedPages(startPage: 0, pages: response.bodyBytes),
      206 => FetchedPages(
        startPage: query.startPage,
        pages: response.bodyBytes,
      ),
      final status => throw ClientException('Unexpected result code $status'),
    };
  }

  @override
  void close() {
    _client.close();
  }
}
