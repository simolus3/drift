import 'package:drift_website/src/common.dart';
import 'package:markdown/markdown.dart';
import 'package:test/test.dart';

void main() {
  test('parses admonitions', () {
    final docs = driftMarkdownDocumentBuilder();
    final parsed = docs.parse('''
!!! note

    Content
''');

    expect(renderToHtml(parsed), '''
<div class="admonition note">
<p class="admonition-title">Note</p>
<p>Content</p>
</div>''');
  });

  test('can set a custom title', () {
    final docs = driftMarkdownDocumentBuilder();
    final parsed = docs.parse('''
!!! tip "Custom title"

    Content
''');

    expect(renderToHtml(parsed), '''
<div class="admonition tip">
<p class="admonition-title">Custom title</p>
<p>Content</p>
</div>''');
  });

  test('title with markdown', () {
    final docs = driftMarkdownDocumentBuilder();
    final parsed = docs.parse('''
!!! tip "Custom `title`"

    Content
''');

    expect(renderToHtml(parsed), '''
<div class="admonition tip">
<p class="admonition-title">Custom <code>title</code></p>
<p>Content</p>
</div>''');
  });

  test('can generate collapsible', () {
    final docs = driftMarkdownDocumentBuilder();
    final parsed = docs.parse('''
??? note

    Content
''');

    expect(renderToHtml(parsed), '''
<details class="note"><summary>Note</summary>
<p>Content</p>
</details>''');
  });
}
