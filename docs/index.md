---
layout: home
title: Home
description: Moor is an easy to use, reactive persistence library for Flutter apps.
nav_order: 0
---

# Moor
{: .fs-9 }

Moor is an easy to use, reactive persistence library for Flutter apps. Define your
database tables in pure Dart and enjoy a fluent query API, auto-updating streams
and more!
{: .fs-6 .fw-300 }

[![Build Status](https://travis-ci.com/simolus3/moor.svg?token=u4VnFEE5xnWVvkE6QsqL&branch=master)](https://travis-ci.com/simolus3/moor)
[![codecov](https://codecov.io/gh/simolus3/moor/branch/master/graph/badge.svg)](https://codecov.io/gh/simolus3/moor)

[Get started now]({{ site.common_links.getting_started | absolute_url }}){: .btn .btn-green .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub]({{site.github_link}}){: .btn .btn-outline .fs-5 .mb-4 .mb-md-0 .mr-2 }

---

## Getting started
{% include content/getting_started.md %}

You can ignore the `schemaVersion` at the moment, the important part is that you can
now run your queries with fluent Dart code

## [Writing queries]({{"queries" | absolute_url }})

## TODO-List
There are some sql features like `group by` statements which aren't natively supported by moor yet.
However, as moor supports [custom sql queries]({{"queries/custom" | absolute_url}}), there are easy
workarounds for most entries on this list. Custom queries work well together with the regular api,
as they integrate with stream queries and automatic result parsing.
### Limitations (at the moment)
These aren't sorted by priority. If you have more ideas or want some features happening soon,
let me know by [creating an issue]({{site.github_link}}/issues/new)!
- No `group by`, count, or window functions
- Support other platforms:
  - VM apps
  - Web apps via `AlaSQL` or a different engine?
- References (can be expressed via custom constraints, see issue [#14](https://github.com/simolus3/moor/issues/14))
- When inserts / updates fail due to invalid data, explain why that happened
