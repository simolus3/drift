---

title: Many-to-Many
description: Handling many-to-many relationships in drift

---


Drift, being a relational database library and not an ORM, does not provide built-in support for many-to-many relationships. Instead, it gives you the tools to manually write the necessary joins to express more complex queries efficiently.

This example demonstrates how to handle a complex many-to-many relationship by creating a database for an online shop. Specifically, we will explore how to represent shopping carts in SQL.

In this scenario, there exists a many-to-many relationship between shopping carts and products. A product can be present in multiple shopping carts simultaneously, and a cart can contain multiple products as well.


There are 2 ways to model many-to-many relationships in SQL:

1. Using a 3rd *through* table that stores the relationships between the two entities.
   This is the traditional way to model many-to-many relationships in SQL.

2. Store the many side of the relationship as a JSON array in the one side.
   This approach is more flexible and can be more efficient for certain queries.

Both methods have their merits and drawbacks. The conventional relational approach offers stronger data integrity safeguards. For example, it allows for automatic removal of product references from shopping carts when a product is deleted.  

Conversely, JSON structures simplify query writing. This is particularly beneficial when the sequence of products in a shopping cart matters, as JSON lists inherently maintain order, unlike rows in a relational table.

Picking the right approach is a design decision you'll have to make.   
This page describes both approaches and highlights some differences between them.

## Common setup

In both approaches, we'll implement a repository for shopping cart entries that
will adhere to the following interface:

{{ load_snippet('interface','lib/snippets/modular/many_to_many/shared.dart.excerpt.json') }}

We also need a table for products that can be bought:

{{ load_snippet('buyable_items','lib/snippets/modular/many_to_many/shared.dart.excerpt.json') }}

## In a relational structure

### Defining the model

We're going to define two tables for shopping carts: One for the cart
itself, and another one to store the entries in the cart.
The latter uses [references](../Dart API/tables.md#references)
to express the foreign key constraints of referencing existing shopping
carts or product items.

{{ load_snippet('cart_tables','lib/snippets/modular/many_to_many/relational.dart.excerpt.json') }}

### Inserts
We want to write a `CartWithItems` instance into the database. We assume that
all the `BuyableItem`s included already exist in the database (we could store
them via `into(buyableItems).insert(BuyableItemsCompanion(...))`). Then,
we can replace a full cart with

{{ load_snippet('updateCart','lib/snippets/modular/many_to_many/relational.dart.excerpt.json') }}

We could also define a helpful method to create a new, empty shopping cart:

{{ load_snippet('createEmptyCart','lib/snippets/modular/many_to_many/relational.dart.excerpt.json') }}

### Selecting a cart
As our `CartWithItems` class consists of multiple components that are separated in the
database (information about the cart, and information about the added items), we'll have
to merge two streams together. The `rxdart` library helps here by providing the
`combineLatest2` method, allowing us to write

{{ load_snippet('watchCart','lib/snippets/modular/many_to_many/relational.dart.excerpt.json') }}

### Selecting all carts
Instead of watching a single cart and all associated entries, we
now watch all carts and load all entries for each cart. For this
type of transformation, RxDart's `switchMap` comes in handy:

{{ load_snippet('watchAllCarts','lib/snippets/modular/many_to_many/relational.dart.excerpt.json') }}

## With JSON functions

This time, we can store items directly in the shopping cart table. Multiple
entries are stored in a single row by encoding them into a JSON array, which
happens with help of the `json_serializable` package:



{{ load_snippet('tables','lib/snippets/modular/many_to_many/json.dart.excerpt.json') }}

Creating shopping carts looks just like in the relational example:

{{ load_snippet('createEmptyCart','lib/snippets/modular/many_to_many/json.dart.excerpt.json') }}

However, updating a shopping cart doesn't require a transaction anymore since it can all happen
in a single table:

{{ load_snippet('updateCart','lib/snippets/modular/many_to_many/json.dart.excerpt.json') }}

To select a single cart, we can use the [`json_each`](https://sqlite.org/json1.html#jeach)
function from sqlite3 to "join" each item stored in the JSON array as if it were a separate
row. That way, we can efficiently look up all items in a cart:

{{ load_snippet('watchCart','lib/snippets/modular/many_to_many/json.dart.excerpt.json') }}

Watching all carts isn't that much harder, we just remove the `where` clause and
combine all rows into a map from carts to their items:

{{ load_snippet('watchAllCarts','lib/snippets/modular/many_to_many/json.dart.excerpt.json') }}
