---
data:
  title: "Community"
  weight: 50
  description: Packages contributed by the community
template: layouts/docs/single
---

{% block "blocks/pageinfo" %}
Do you have a drift-related package you want to share? Awesome, please let me know!
[Twitter](https://twitter.com/dersimolus) or via email to oss &lt;at&gt;simonbinder&lt;dot&gt;eu.
{% endblock %}

## Storage inspector

[Nicola Verbeeck](https://github.com/NicolaVerbeeck) wrote the `storage_inspector` packages, which
allow you to inspect your app's persistent data in JetBrains tools like IntelliJ or Android Studio.
This includes drift databases, but preferences or secure local storage are also supported.

- The general [`storage_inspector`](https://pub.dev/packages/storage_inspector) package on pub.
- The [IDEA plugin for your IDE](https://plugins.jetbrains.com/plugin/18231-local-storage-inspector).
- [drift support for `storage_inspector`](https://pub.dev/packages/drift_local_storage_inspector).

## drift_db_viewer

[drift_db_viewer](https://pub.dev/packages/drift_db_viewer) (and [moor_db_viewer](https://pub.dev/packages/moor_db_viewer)) by [Koen Van Looveren](https://github.com/vanlooverenkoen)
is a package to view a moor or drift database in your Flutter app directly.
It includes a graphical user interface showing you all rows for each table. You can also filter
rows by columns that you've added to your tables.

## moor2csv

[Dhiman Seal](https://github.com/Dhi13man) wrote a package to export moor or drift databases as csv files.
The package is [on pub](https://pub.dev/packages/moor2csv).
