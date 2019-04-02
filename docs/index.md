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
now run your queries with fluent Dart code:

## TODO-List and current limitations
### Limitations (at the moment)
Please note that a workaround for most on this list exists with custom statements.

- No `group by` or window functions

### Planned for the future
These aren't sorted by priority. If you have more ideas or want some features happening soon,
let me know by [creating an issue]({{site.github_link}}/issues/new)!
- Simple `COUNT(*)` operations (group operations will be much more complicated)
- Support Dart VM apps
- References
  - DSL API
  - Support in generator
  - Validations
- Bulk inserts
- When inserts / updates fail due to invalid data, explain why that happened
### Interesting stuff that would be nice to have
Implementing this will very likely result in backwards-incompatible changes.

- Find a way to hide implementation details from users while still making them
  accessible for the generated code
- `GROUP BY` grouping functions 
- Support for different database engines
  - Support webapps via `AlaSQL` or a different engine
