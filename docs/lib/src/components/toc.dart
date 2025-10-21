import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/jaspr_content.dart' as jaspr;

import 'anchors.dart';

final class TableOfContents extends StatelessComponent {
  const TableOfContents();

  @override
  Component build(BuildContext context) {
    final page = context.page;
    final data = page.data;
    final toc = data['toc'] as jaspr.TableOfContents?;
    if (toc == null) {
      return const Component.empty();
    }
    final source = page.path;
    final issueTitle = Uri.encodeQueryComponent(
      'Documentation issue: ${data.page['title']}',
    );

    return fragment([
      div(classes: 'td-page-meta ms-2 pb-1 pt-2 mb-0', [
        a(
          classes: 'td-page-meta--edit td-page-meta__edit',
          target: Target.blank,
          referrerPolicy: ReferrerPolicy.noReferrer,
          href:
              'https://github.com/simolus3/drift/edit/develop/docs/content/$source',
          [
            i(classes: 'fa-solid fa-pen-to-square', []),
            text(' Edit this page'),
          ],
        ),
        a(
          classes: 'td-page-meta--issue td-page-meta__issue',
          target: Target.blank,
          referrerPolicy: ReferrerPolicy.noReferrer,
          href:
              'https://github.com/simolus3/drift/issues/new?template=docs.md&title=$issueTitle',
          [
            i(classes: 'fa-solid fa-list-check fa-fw', []),
            text(' Create documentation issue'),
          ],
        ),
      ]),
      div(classes: 'td-toc', [
        div(classes: 'td-toc__title', [
          span(classes: 'td-toc__title__text', [text('On this page')]),
          a(
            classes: 'td-toc__title__link',
            href: '#',
            attributes: {'title': 'Top of the page'},
            [],
          ),
        ]),
        nav(id: 'TableOfContents', [ActiveAnchors(), toc.render()]),
      ]),
    ]);
  }
}

extension on jaspr.TableOfContents {
  Component render() {
    return ul([..._buildToc(entries)]);
  }

  Iterable<Component> _buildToc(List<TocEntry> toc) sync* {
    for (final entry in toc) {
      yield li([
        a(href: '#${entry.id}', [text(entry.text)]),
        if (entry.children.isNotEmpty) ul([..._buildToc(entry.children)]),
      ]);
    }
  }
}
