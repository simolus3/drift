import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;

/// A [DirectoryWatcher] reporting events as relative paths so that
/// jaspr_content picks the up correctly.
///
/// TODO: This wasn't necessary when I created the website from the template, I
/// must have misconfigured something else.
final class RelativeDirectoryWatcher implements DirectoryWatcher {
  final DirectoryWatcher _inner;

  RelativeDirectoryWatcher(this._inner);

  @override
  // ignore: deprecated_member_use
  String get directory => _inner.directory;

  @override
  Stream<WatchEvent> get events => _inner.events.map((event) {
    return WatchEvent(event.type, p.relative(event.path));
  });

  @override
  bool get isReady => _inner.isReady;

  @override
  String get path => _inner.path;

  @override
  Future get ready => _inner.ready;
}
