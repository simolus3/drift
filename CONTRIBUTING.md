# Contributing

Thanks for taking the time to contribute to moor!

## Reporting issues
Feel free to post any questions, bug reports or feature requests by creating an issue.
In any case, taking the time to provide some context on
- what you were trying to do
- what you would have expected to happen
- what actually happened

most certainly helps to resolve the issue quickly.

## Contributing code
All kinds of pull requests are absolutely appreciated! Before working on bigger changes, it
can be helpful to create an issue describing your plans to help coordination.

If you have any question about moor internals, you're most welcome to create an issue or
[chat via gitter](http://gitter.im/simolus3).

## Workflows

### Releasing to pub
Minor changes will be published directly, no special steps are necessary. For major
updates that span multiple versions, we should follow these steps

1. Changelogs: For new updates, we use the same `CHANGELOG` for `moor` and `moor_flutter`. This
   is because most changes happen with moor directly, but users are most likely depending on the
   Flutter version only. The changelog for the generator should only point out relevant changes to
   the generator.
2. Make sure each package has the correct dependencies: `moor_flutter` version `1.x` should depend
   on moor `1.x` as well to ensure users will always `pub get` moor packages that are compatible
   with each other.
3. Comment out the `dependency_overrides` section 
4. Publish packages in this order to avoid scoring penalties caused by versions not existing:
   1. `moor`
   2. `moor_generator`
   3. `moor_flutter`
 
The `sqlparser` library can be published independently from moor.

### Building the documentation
We use hugo and docsy to build the documentation. The [readme](docs/README.md) contains everything
you need to know go get started.