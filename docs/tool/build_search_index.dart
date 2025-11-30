import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha1;
import 'package:drift_website/src/common.dart';
import 'package:drift_website/src/components/inherited_page.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr/src/server/async_build_owner.dart';
import 'package:jaspr_router/src/misc/inherited_router.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Creates a SQLite database file containing an FTS5 table indexing all content
/// in the documentation website.
void main() async {
  final loader = driftWebsiteLoader();
  final config = driftPageConfig(forSearchIndex: true);
  for (final file in Directory('web').listSync()) {
    if (file is File && p.extension(file.path) == '.db') {
      file.deleteSync();
    }
  }

  final target = File('web/search.db');
  if (target.existsSync()) {
    target.deleteSync();
  }

  final routes = await loader.loadRoutes(config, true);

  final db = sqlite3.openInMemory()
    ..createContentTable()
    // This is the default, but the client also assumes this page size when
    // fetching the database in range requests, so it's better to be explicit
    // about this.
    ..execute('pragma page_size = 4096;');
  for (final route in routes) {
    if (route case final Route route) {
      print('Has route ${route.path}, ${route.name}, ${route.title}');

      final binding = _RenderTextBinding(currentUrl: route.path)
        ..attachRootComponent(_RenderSingleRoute(loader, route));
      final (:title, :content) = await binding.render();
      if (binding.hadError) {
        print('Stopping due to error');
        exit(1);
      }

      db.addPage(title, content, route.path);
    }
  }

  print('Created FTS5 index for pages');
  // Merge multiple indexes into one for smaller size and faster queries.
  db.execute('INSERT INTO content (content) VALUES (?)', ['optimize']);
  db.execute('VACUUM INTO ?', [target.path]);

  final contents = target.readAsBytesSync();
  if (contents.length % 4096 != 0) {
    throw 'Database file size not divisible by block size';
  }

  final hash = sha1.convert(contents);
  target.renameSync('web/$hash.db');
  File('${target.path}.json').writeAsStringSync(
    json.encode({'hash': hash.toString(), 'blocks': contents.length ~/ 4096}),
  );

  exit(0);

  // TODO: It would be nice to also index documentation comments.
}

final class _RenderSingleRoute extends StatelessComponent {
  final FilesystemLoader loader;
  final Route route;

  _RenderSingleRoute(this.loader, this.route);

  @override
  Component build(BuildContext context) {
    final state = RouteState(
      location: route.path,
      subloc: '',
      name: route.name,
    );
    return InheritedRouteState(
      state: state,
      child: InheritedPageResolver(
        child: route.builder!(context, state),
        loader: loader,
      ),
    );
  }
}

/// A jaspr render element implementation that just renders the inner text of
/// nodes without any escapes.
///
/// This is used to build content for the FTS5 index. We don't want to just
/// paste raw markdown into that index because the outputs of some components,
/// in particular of `<Snippets />`, should also be part of the index.
final class _RenderTextBinding extends AppBinding with ComponentsBinding {
  @override
  final String currentUrl;

  var hadError = false;

  _RenderTextBinding({required this.currentUrl});

  @override
  RenderObject createRootRenderObject() {
    return RootMarkupRenderObject();
  }

  Future<({String title, String content})> render() async {
    final root = rootElement!;
    final completer = Completer();
    root.binding.addPostFrameCallback(completer.complete);
    await completer.future;

    final buffer = StringBuffer();
    var title = '';

    void render(
      MarkupRenderObject obj,
      StringBuffer buffer,
      bool strictFormatting,
    ) {
      if (obj case MarkupRenderElement element) {
        if (element.tag == 'title') {
          title = (obj.children.single as MarkupRenderText).text;
        } else if (element.tag == 'style') {
          // Don't render inline styles
          return;
        }
      }

      if (obj is MarkupRenderText) {
        buffer.write(obj.text);
      } else {
        final strictFormattingHere =
            strictFormatting ||
            switch (obj) {
              MarkupRenderElement(tag: 'span' || 'pre') => true,
              _ => false,
            };

        for (final (i, child) in obj.children.indexed) {
          if (!strictFormattingHere && i != 0) {
            buffer.write(' ');
          }

          render(child, buffer, strictFormattingHere);
        }
      }
    }

    render(root.renderObject as MarkupRenderObject, buffer, false);
    return (title: title, content: buffer.toString());
  }

  @override
  BuildOwner createRootBuildOwner() {
    return AsyncBuildOwner();
  }

  @override
  bool get isClient => false;

  @override
  void reportBuildError(Element element, Object error, StackTrace stackTrace) {
    hadError = true;
    stderr.writeln(
      'Error while building ${element.component.runtimeType}:\n$error\n\n$stackTrace',
    );
  }

  @override
  void scheduleFrame(VoidCallback frameCallback) {
    throw UnsupportedError(
      'Scheduling a frame is not supported on the server, and should never happen.',
    );
  }
}

extension on Database {
  void createContentTable() {
    execute('''
CREATE VIRTUAL TABLE content USING fts5(
  title,
  body,
  path UNINDEXED
);
''');
  }

  void addPage(String title, String body, String path) {
    execute('INSERT INTO content (title, body, path) VALUES (?, ?, ?)', [
      title,
      body,
      path,
    ]);
  }
}
