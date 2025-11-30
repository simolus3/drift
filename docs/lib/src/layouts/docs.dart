import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart' hide TableOfContents;
import 'package:jaspr_docsy/jaspr_docsy.dart';

import '../components/flutter_favorite.dart';
import '../components/footer.dart';
import '../components/header.dart';
import '../components/modal.dart';
import '../components/sidebar.dart';
import '../components/toc.dart';
import '../search/component.dart';

final class DriftDocsLayout extends DocsyLayout {
  DriftDocsLayout({
    super.navbar = const DriftHeader(),
    super.footer = const DriftFooter(),
    super.sidebar = const DriftSidebar(),
    super.toc = const TableOfContents(),
  }) : super(wrapBody: _buildBody);

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page).where((e) => e is! Style);
    yield link(href: '/styles.css', rel: 'stylesheet');
  }

  @override
  Component buildContent(Page page, Component child) {
    return fragment([
      if (page.url == '/') FlutterFavoriteIcon(),
      PageContent(page: page, renderedMarkdown: child),
    ]);
  }

  @override
  Pattern get name => 'docs';

  @override
  PageType get type => PageType.page;

  static Component _buildBody(List<Component> children) {
    return Component.fragment([...children, SearchModal(), Backdrop()]);
  }
}
