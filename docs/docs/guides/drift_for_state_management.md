---
title: State management
description: This page presents a few ideas on how to integrate drift with popular state management approaches.
---

After getting started with drift, you might be wondering how drift and it's reactive queries fit into the
overal architecture of your app.
This page gives an overview explaining how drift can be a part of any well-designed app, and provides additional
details for popular state management libraries.

Since _many_ different tools and libraries for app architecture and state management exist in the Flutter ecosystem,
this page can't give a complete guide on how to integrate drift with every single one of them.
Luckily, drift was designed to not depend on any particular approach!
By relying on core Dart concepts like streams, it's easy to integrate into most existing approaches.

## General ideas

When integrating drift into apps, following these basic points is typically helpful:

1. __Resource management__: Drift databases are easy to open and `close()`. You can store them in global variables,
   but that can make it harder to provide isolated databases for tests. Use a library like `get_it` or `riverpod`
   that allows disposing resources when they're no longer needed.
2. __Testing__: Drift databases are [easy to unit test](../testing.md). Use that to your advantage and use a fresh
   in-memory database for each test. These databases are very cheap to create and give you the confidence that
   your database code works.
   Avoid mocking drift databases, and don't mock your repositories: Just use the real thing!
3. __Reactivity__: Drift allows watching queries as Dart `Stream`s that are easy to integrate into most Dart
   frameworks. You can listen to them in Blocs or use direct `StreamBuilders`s or `StreamProvider`s.

## Riverpod

Using [Riverpod](https://riverpod.dev/) allows declaring modular providers with automatic dependency tracking.
Combining drift with Riverpod is straightforward, and drift provides the [`drift_riverpod`](pub.dev/packages/drift_riverpod)
package that makes drift queries a first-class citizen in Riverpod.

## Bloc

## `get_it`
