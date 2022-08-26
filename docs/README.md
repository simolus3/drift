# Drift documentation

Welcome to the source of drift's documentation, live at drift.simonbinder.eu.
We use a static site generator based on `build_runner` to build the documentation.

## Running the website locally

For a fast edit-refresh cycle, run

```
dart pub global run webdev serve --auto refresh pages:9999 test:10000 web:8080
```

You can ignore the `pages:9999` (or use any other port), it's just required
so that the build system actually generates pages.

## Building the website

To build the website, first run

```
dart run build_runner build --release
```

To then copy generated contents into a directory, use:

```
dart run build_runner build --release --output web:out
```

Where `out` is the desired output directory.
Note that both steps are necessary since the build system doesn't re-generate
pages otherwise.
