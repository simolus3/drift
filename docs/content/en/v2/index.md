---
title: Moor v2
layout: home
---

{{< blocks/cover title="Moor 2.0: Supercharged SQL for Dart" image_anchor="top" height="min" color="indigo" >}}
<div class="mx-auto">
    <p class="lead mt-5">
        Learn everything about Dart-SQL interop, the SQL IDE, experimental ffi support and everything new in moor
    </p>
</div>
{{< /blocks/cover >}}

{{% blocks/lead color="blue" %}}
## Generator overhaul

The rewritten compiler is faster than ever, supports more SQL features and gives you
more flexibility when writing database code.

[Check the updated documentation]({{< ref "../docs/Using SQL/moor_files.md" >}})
{{% /blocks/lead %}}

{{< blocks/section color="light" >}}
{{% blocks/feature icon="fas fa-puzzle-piece" title="Improved type inference" %}}
The new type inference engine provides more accurate results on complex expressions like window
functions. We also generate simpler methods for queries that only return one column.
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-database" title="Parser improvements" %}}
We now support more advanced features like compound select statements and window functions,
including detailed static analysis and lints.
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-code-branch" title="Dart-SQL interop" %}}
Declare tables in Dart, write your queries in SQL. Or do it the other way around. Or do it all in Dart.
Or all in SQL. Moor makes writing database code fun without taking control over your code. 
For maximum flexibilty, moor lets you inline Dart expressions into SQL and use the best of both
worlds.
{{% /blocks/feature %}}

{{< /blocks/section >}}

{{% blocks/lead color="green" %}}
## Builtin SQL IDE

Moor 2.0 expands the previous sql parser and analyzer, providing real-time feedback on your
SQL queries as you type. Moor plugs right into the Dart analysis server, so you don't have
to install any additional extensions.

[Learn more about the IDE]({{< ref "../docs/Using SQL/sql_ide.md" >}})
{{% /blocks/lead %}}

{{< blocks/section color="dark" >}}
{{% blocks/feature icon="fa-lightbulb" title="Quickfixes" %}}
![](quickfix.png)

Moor lets you write query code faster with helpful actions.
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-brain" title="Smart warnings" %}}
![](warning.png)

Moor analyzes statements as you write them and reports errors right away. 
This helps you identify problems fast, without having to open your app.
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-info-circle" title="Structure view" %}}
![](outline.png)

Moor provides an outline of your tables and queries for a better overview.
{{% /blocks/feature %}}

{{< /blocks/section >}}

{{% blocks/lead color="purple" %}}
## And much, much more

Moor 2.0 contains a set of optimizations and makes common tasks simpler
{{% /blocks/lead %}}

{{< blocks/section color="light" >}}
{{% blocks/feature icon="fa-lightbulb" title="New database helpers" %}}
New utils to load database from assets or to perform additional work before creating a database.
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-exclamation" title="Removed deprecated features" %}}
We removed a whole bunch of deprecated apis that made it harder to develop new features.

[Read the changelog for details](https://pub.dev/packages/moor#-changelog-tab-)
{{% /blocks/feature %}}
{{% blocks/feature icon="fas fa-bolt" title="Experimental `dart:ffi` bindings" %}}
The new [moor_ffi](https://pub.dev/packages/moor_ffi) package brings moor to the desktop and is up to 500x faster than the old
implementation.

_Please not that the package is still in preview_
{{% /blocks/feature %}}

{{< /blocks/section >}}

{{< blocks/section color="dark" type="section" >}}
## Try moor now

- To get started with moor, follow our [getting started guide](ref "../docs/Getting started/_index.md") here.
- To get started with SQL in moor, or to migrate an project to moor, follow our __TODO: Write migration guide__

{{< /blocks/section >}}