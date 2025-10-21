import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_docsy/jaspr_docsy.dart';

import 'components/broken.dart';
import 'components/inherited_page.dart';

final class DriftPage extends StatelessComponent {
  final String title;
  final String definingFile;

  const DriftPage(this.title, this.definingFile);

  @override
  Component build(BuildContext context) {
    final referencedPage = InheritedPageResolver.resolvePageSource(
      context,
      definingFile,
    );
    final currentRoute = context.page.url;

    if (referencedPage == null) {
      return BrokenComponent('$title $definingFile');
    }

    return SidebarEntry(
      href: referencedPage.url,
      title: text(title),
      depth: 3,
      activePath: currentRoute == referencedPage.url,
    );
  }
}

final class DriftPageGroup extends StatelessComponent {
  final String? title;
  final List<DriftPage> pages;

  const DriftPageGroup({this.title, required this.pages});

  @override
  Component build(BuildContext context) {
    return SidebarEntry(
      href: null,
      depth: 2,
      title: switch (title) {
        null => null,
        final title => text(title),
      },

      children: pages,
    );
  }
}

final class DriftTab {
  final String name;
  final String page;
  final List<DriftPageGroup> groups;

  const DriftTab(this.name, this.page, this.groups);

  static const docs = DriftTab('Docs', '/', [
    DriftPageGroup(
      pages: [
        DriftPage('Home', 'index.md'),
        DriftPage('Setup guide', 'setup.md'),
        DriftPage('FAQ', 'faq.md'),
      ],
    ),
    DriftPageGroup(
      title: 'Dart reference',
      pages: [
        DriftPage('Defining tables', 'dart_api/tables.md'),
        DriftPage('Selects', 'dart_api/select.md'),
        DriftPage('Writes (update, insert, delete)', 'dart_api/writes.md'),
        DriftPage('Expressions', 'dart_api/expressions.md'),
        DriftPage('Stream queries', 'dart_api/streams.md'),
        DriftPage('Schema introspection', 'dart_api/schema_inspection.md'),
        DriftPage('Views', 'dart_api/views.md'),
        DriftPage('DAOs', 'dart_api/daos.md'),
        DriftPage('Manager API', 'dart_api/manager.md'),
        DriftPage('Transactions', 'dart_api/transactions.md'),
      ],
    ),
    DriftPageGroup(
      title: 'SQL API reference',
      pages: [
        DriftPage('Overview', 'sql_api/index.md'),
        DriftPage('Drift files', 'sql_api/drift_files.md'),
        DriftPage('SQLite extensions', 'sql_api/extensions.md'),
        DriftPage('Custom queries', 'sql_api/custom_queries.md'),
      ],
    ),
    DriftPageGroup(
      title: 'Migrations',
      pages: [
        DriftPage('Overview', 'migrations/index.md'),
        DriftPage('Migrator APIs', 'migrations/api.md'),
        DriftPage('Testing', 'migrations/tests.md'),
        DriftPage('Helpers', 'migrations/step_by_step.md'),
        DriftPage('Schema exports', 'migrations/exports.md'),
      ],
    ),
    DriftPageGroup(
      title: 'Platforms',
      pages: [
        DriftPage('Overview', 'platforms/index.md'),
        DriftPage('Native', 'platforms/vm.md'),
        DriftPage('Web', 'platforms/web.md'),
        DriftPage('Encryption', 'platforms/encryption.md'),
        DriftPage('libsql', 'platforms/libsql.md'),
        DriftPage('PostgreSQL', 'platforms/postgres.md'),
      ],
    ),
    DriftPageGroup(
      title: 'Generation options',
      pages: [
        DriftPage('Overview', 'generation_options/index.md'),
        DriftPage('Modular code generation', 'generation_options/modular.md'),
        DriftPage(
          'Drift and other builders',
          'generation_options/in_other_builders.md',
        ),
      ],
    ),
    DriftPageGroup(
      title: 'Tools',
      pages: [
        DriftPage('Overview', 'tools/index.md'),
        DriftPage('Devtools extension', 'tools/devtools.md'),
        DriftPage('Community tools', 'community_tools.md'),
      ],
    ),
    DriftPageGroup(
      title: 'Advanced topics',
      pages: [
        DriftPage('Isolates', 'isolates.md'),
        DriftPage('Testing', 'testing.md'),
        DriftPage('Generated table rows', 'dart_api/rows.md'),
        DriftPage('Type converters', 'type_converters.md'),
        DriftPage('Custom SQL types', 'sql_api/types.md'),
      ],
    ),
  ]);
  static const examples = DriftTab('Examples', '/examples/', [
    DriftPageGroup(
      title: 'Examples',
      pages: [
        DriftPage('Overview', 'examples/index.md'),
        DriftPage('Flutter', 'examples/flutter.md'),
        DriftPage('Many-to-many relations', 'examples/relationships.md'),
        DriftPage(
          'Importing existing databases',
          'examples/existing_databases.md',
        ),
        DriftPage('Tracing database operations', 'examples/tracing.md'),
        DriftPage('Backend synchronization', 'examples/server_sync.md'),
      ],
    ),
  ]);

  static const guides = DriftTab('Guides', '/guides/datetime-migrations', [
    DriftPageGroup(
      title: 'Guides',
      pages: [
        DriftPage('DateTime storage', 'guides/datetime-migrations.md'),
        DriftPage('Upgrading Drift', 'guides/upgrading.md'),
        DriftPage('Migrate to Drift', 'guides/migrating_to_drift.md'),
        DriftPage('Install from GitHub', 'guides/install_from_gh.md'),
      ],
    ),
  ]);

  static const all = [docs, guides, examples];

  static DriftTab? current(BuildContext context) {
    final currentPage = context.page;
    for (final tab in all) {
      for (final group in tab.groups) {
        for (final page in group.pages) {
          if (page.definingFile == currentPage.path) {
            return tab;
          }
        }
      }
    }

    return null;
  }
}
