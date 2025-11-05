import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:path/path.dart' show url;

import 'broken.dart';
import 'inherited_page.dart';

/// Renders markdown links to source files (with a `.md` extension) by rewriting
/// them to the final url that page would have in the end.
final class PageRef extends CustomComponent {
  PageRef() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'a', :final attributes, :final children)) {
      final href = switch (attributes['href']) {
        null => null,
        final href => Uri.parse(href),
      };
      if (href == null) {
        return null;
      }

      if (href.authority == '' && url.extension(href.path) == '.md') {
        return _PageLink(ref: href, child: builder.build(children));
      }
    }

    return null;
  }
}

final class _PageLink extends StatelessComponent {
  final Uri ref;
  final Component child;

  _PageLink({required this.ref, required this.child});

  @override
  Component build(BuildContext context) {
    final page = context.page;
    final resolvedRef = url.join(url.dirname(page.path), ref.path);
    final referencedPage = InheritedPageResolver.resolvePageSource(
      context,
      resolvedRef,
    );

    if (referencedPage == null) {
      return BrokenComponent('broken link to ${ref.path} from ${page.path}');
    }

    return a(
      href: Uri.parse(referencedPage.url)
          .replace(
            fragment: ref.fragment.isNotEmpty ? ref.fragment : null,
            query: ref.query.isNotEmpty ? ref.query : null,
          )
          .toString(),
      [child],
    );
  }
}
