import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:path/path.dart' show url;

final class InheritedPageResolver extends InheritedComponent {
  final FilesystemLoader loader;

  InheritedPageResolver({
    required super.child,
    super.key,
    required this.loader,
  });

  static PageSource? resolvePageSource(BuildContext context, String path) {
    final loader = context
        .dependOnInheritedComponentOfExactType<InheritedPageResolver>()!
        .loader;
    final normalized = url.normalize(path);

    for (final page in loader.sources) {
      if (page.path == normalized) {
        return page;
      }
    }

    return null;
  }

  @override
  bool updateShouldNotify(covariant InheritedComponent oldComponent) {
    return false;
  }
}
