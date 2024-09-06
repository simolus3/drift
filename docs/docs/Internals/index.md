---

title: Drift internals
description: Work in progress documentation on drift internals

---

## Using an unreleased drift version

To try out new drift features, you can choose to use a development version of drift before it's
published to pub. For that, add an `dependency_overrides` section to your pubspec:

```yaml
dependency_overrides:
  drift:
    git:
      url: https://github.com/simolus3/drift.git
      ref: develop
      path: drift
  drift_dev:
    git:
      url: https://github.com/simolus3/drift.git
      ref: develop
      path: drift_dev
  sqlparser:
    git:
      url: https://github.com/simolus3/drift.git
      ref: develop
      path: sqlparser
```

If you're using `drift_sqflite`, add a similar override for that package as well.
