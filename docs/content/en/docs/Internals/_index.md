---
title: "Moor internals"
weight: 300000
description: Work in progress documentation on moor internals
---

## Using an unreleased moor version

To try out new moor features, you can choose to use a development or beta version of moor before it's
published to pub. For that, add an `dependency_overrides` section to your pubspec:

```yaml
dependency_overrides:
  moor:
    git:
      url: https://github.com/simolus3/moor.git
      ref: beta
      path: moor
  moor_ffi:
    git:
      url: https://github.com/simolus3/moor.git
      ref: beta
      path: moor_ffi
  moor_generator:
    git:
      url: https://github.com/simolus3/moor.git
      ref: beta
      path: moor_generator
  sqlparser:
    git:
      url: https://github.com/simolus3/moor.git
      ref: beta
      path: sqlparser
```

If you're using `moor_flutter`, just exchange `moor_ffi` with `moor_flutter` in the package name
and path. To use the bleeding edge of moor, change `ref: beta` to `ref: develop` for all packages.