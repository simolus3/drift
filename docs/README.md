# Drift documentation

Welcome to the source of drift's documentation, live at drift.simonbinder.eu.
We use a static site generator based on `build_runner` to build the documentation.

## Running the website locally

For a fast edit-refresh cycle, run

```
dart run build_runner serve web:8080 --live-reload
```

## Building the website

To build the website into a directory `out`, use:

```
dart run build_runner build --release --output web:out
```
