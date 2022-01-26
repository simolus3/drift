---
data:
  title: "Community"
  description: Packages contributed by the community
template: layouts/docs/single
---

{% block "blocks/pageinfo" %}
Do you have a drift-related package you want to share? Awesome, please let me know!
Contact me on [Gitter](https://gitter.im/moor-dart/community), [Twitter](https://twitter.com/dersimolus)
or via email to oss &lt;at&gt;simonbinder&lt;dot&gt;eu.
{% endblock %}

## Drift inspector

[Chimerapps](https://github.com/Chimerapps) wrote the `drift_inspector` package and plugin for IntelliJ
and Android Studio. You can use it to inspect a moor or drift database right from your IDE!

- The [`drift_inspector` package](https://pub.dev/packages/drift_inspector) on pub
- The [IntelliJ plugin](https://plugins.jetbrains.com/plugin/15364-drift-database-inspector)
- The [project on GitHub](https://github.com/Chimerapps/drift_inspector)

The upcoming [`storage_inspector`](https://github.com/NicolaVerbeeck/flutter_local_storage_inspector) package
and IntelliJ plugin will also enable you to inspect your drift database along with local storage or other
persistence packages you use.

## drift_db_viewer

[drift_db_viewer](https://pub.dev/packages/drift_db_viewer) (and [moor_db_viewer](https://pub.dev/packages/moor_db_viewer)) by [Koen Van Looveren](https://github.com/vanlooverenkoen)
is a package to view a moor or drift database in your Flutter app directly.
It includes a graphical user interface showing you all rows for each table. You can also filter
rows by columns that you've added to your tables.

## moor2csv

[Dhiman Seal](https://github.com/Dhi13man) wrote a package to export moor or drift databases as csv files.
The package is [on pub](https://pub.dev/packages/moor2csv).
