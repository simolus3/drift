// Waiting for linkcheck to migrate...
// @dart=2.9
import 'dart:async';
import 'dart:io';

import 'package:linkcheck/linkcheck.dart' as check;
import 'package:linkcheck/src/parsers/url_skipper.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

/// Checks that the content in `deploy/` only contains valid links.
Future<void> main() async {
  final done = Completer<void>();

  await _startServer(done.future);
  check.CrawlResult results;
  try {
    results = await check.crawl(
      [
        Uri.parse('http://localhost:8080/'),
        Uri.parse('http://localhost:8080/api/')
      ],
      {'http://localhost:8080/**'},
      // todo: Re-enable. Current problem is that we link new pages to their
      // final url (under drift.simonbinder.eu) before they're deployed.
      false,
      UrlSkipper(
          '', ['github.com', 'pub.dev', 'api.dart.dev', 'fonts.gstatic.com']),
      false,
      false,
      const Stream<Null /*Never*/ >.empty(),
      stdout,
    );
  } finally {
    done.complete();
  }

  var hasBrokenLinks = false;

  for (final result in results.destinations) {
    // todo: Remove !result.isExternal after external links work again
    if (result.isBroken && !result.isExternal) {
      print('Broken: $result (${result.toMap()})');
      hasBrokenLinks = true;
    }
  }

  if (!hasBrokenLinks) {
    print('No broken links found!');
  } else {
    exit(1);
  }
}

Future<void> _startServer(Future<void> completeSignal) async {
  final handler = createStaticHandler('deploy/', defaultDocument: 'index.html');
  final server = await io.serve(handler, 'localhost', 8080);

  print('Started server - listening on :8080');

  completeSignal.then((_) => server.close()).ignore();
}
