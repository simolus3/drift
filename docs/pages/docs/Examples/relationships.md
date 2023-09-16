---
data:
  title: "Many to many relationships"
  description: An example that models a shopping cart system with drift.
template: layouts/docs/single
---

{% assign snippets = 'package:drift_docs/snippets/many_to_many_relationships.dart.excerpt.json' | readString | json_decode %}

## Defining the model

In this example, we're going to model a shopping system and some of its
queries in drift. First, we need to store some items that can be bought:

{% include "blocks/snippet" snippets=snippets name="buyable_items" %}

We're going to define two tables for shopping carts: One for the cart
itself, and another one to store the entries in the cart.
The latter uses [references]({{ '../Dart API/tables.md#references' | pageUrl }})
to express the foreign key constraints of referencing existing shopping
carts or product items.

{% include "blocks/snippet" snippets=snippets name="cart_tables" %}

Drift will generate matching classes for the three tables. But having to use
three different classes to model a shopping cart in our application would be
quite annoying. Let's write a single class to represent an entire shopping
cart:

{% include "blocks/snippet" snippets=snippets name="cart" %}

## Inserts
We want to write a `CartWithItems` instance into the database. We assume that
all the `BuyableItem`s included already exist in the database (we could store
them via `into(buyableItems).insert(BuyableItemsCompanion(...))`). Then,
we can insert a full cart with

{% include "blocks/snippet" snippets=snippets name="writeShoppingCart" %}

We could also define a helpful method to create a new, empty shopping cart:

{% include "blocks/snippet" snippets=snippets name="createEmptyCart" %}

## Selecting a cart
As our `CartWithItems` class consists of multiple components that are separated in the
database (information about the cart, and information about the added items), we'll have
to merge two streams together. The `rxdart` library helps here by providing the
`combineLatest2` method, allowing us to write

{% include "blocks/snippet" snippets=snippets name="watchCart" %}

## Selecting all carts
Instead of watching a single cart and all associated entries, we
now watch all carts and load all entries for each cart. For this
type of transformation, RxDart's `switchMap` comes in handy:

{% include "blocks/snippet" snippets=snippets name="watchAllCarts" %}
