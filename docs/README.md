### Documentation for the Drift package

Folder Structure:

- `builders` Contains the builders for the snippets and dart projects versions (`versions.json` and `*.excerpt.json` in `lib`).
- `docs` Contains the markdown files for the documentation.
- `deploy` The output of the documentation build.
- `lib` Contains the code snippets for the documentation.
- `test` Contains the tests for the documentation.
- `web` Contains some dart which code which is compiled to JavaScript and served with the documentation.
- `mkdocs` Contains the MkDocs configuration.

### Building the Documentation
You will need to make the `docs.sh` script executable before you can run it. You can do this by running the following command:

```bash
chmod +x docs.sh
```

Run the following command to build the documentation:

```bash
docs.sh build
```

### Serving the Documentation

You can also serve the documentation locally and view it in your browser.
Changes to the documentation will be reflected in real-time.

##### Limitations of Serving the Documentation

- The flutter example project will not be built and served. If you would like to see the flutter example to be available in the documentation, you will need to run the `docs.sh build` 1st.
  ```bash
  docs.sh build
  docs.sh serve
  ```
- The `web` folder will not be built and served. If you would like to see the `web` folder, you will need to run the `docs.sh build` command 1st.
  ```bash
  docs.sh build
  docs.sh serve # or `docs.sh serve --with-build-runner`
  ```

Run the following command to serve the documentation:

```bash
docs.sh serve
```
If you would like changes to snippets to be available in real-time, you can run the following command:

```bash
docs.sh serve --with-build-runner
```

### Understanding the Build Process

Behind the scenes, the `docs.sh` script does the following:
1. Running `webdev`:
    - Creates `versions.json` which will inject the latest version into MkDocs. e.g. `^{{ versions.drift }}`
    - Creates `.excerpt.json` snippet files in `lib` which MkDocs will use to inject syntax highlighted code into the documentation. e.g. `{{ load_snippet('flutter','lib/snippets/setup/database.dart.excerpt.json') }}`
    - Run the `drift_dev` builder to generate the code for the snippets.
    - Compile the dart code in `web` to JavaScript.
2. Running `mkdocs`:
    - Compile the markdown files in `docs` to HTML.
3. Combine the output of the two steps into the `deploy` folder.



### Syntax Highlighting

Code which is included in markdown using \`\`\` \`\`\` snippets is highlighted by mkdocs automatically. These colors can be modified by following the instructions in the [MkDocs documentation](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#custom-syntax-theme).

Code snippets which are included in the documentation using the `{{ load_snippet() }}` macro are highlighted too. If they are from a `.dart` file we use a custom syntax highlighter, otherwise we use the default MkDocs syntax highlighter.

When `build_runner` runs, it will create a `*.excerpt.json` next to each snippet file which contains each snippet in styled HTML (`dart`) or in raw text (all other languages). The `{{ load_snippet() }}` macro injects the snippets from these `*.excerpt.json` files. The code for this macro can be found in `/docs/mkdocs/main.py`.

#### CSS Processing 

The highlighter for `dart` has been sourced from the Dart Team and the Serverpod Team. It uses VS Code themes and the Dart Grammar spec to generate HTML. However, the way it generates it is problematic.

Take the following source code
```dart
print("Hello World")
```

For the word `print`, the highlighter generates a `DynamicTextStyle` class which defines that `print` should be `yellow` in Dark Mode and `purple` in Light Mode.

We can't create HTML with inline styles which can handle Dark Mode and Light Mode:
```html
<!-- Only Light Mode -->
<div style="color: purple;">print</div>
<!-- Only Dark Mode -->
 <div style="color: yellow;">print</div>
```

We need to place the styles in a CSS class and then switch the class based on the mode. This is what need to do:

```html
<div class="dart-keyword">print</div>
```
and in the CSS file
```css
.dart-keyword {
    color: purple;
}
@media (prefers-color-scheme: dark) {
    .dart-keyword {
        color: yellow;
    }
}
```

#### Dart Builder Limitations

However, the Dart Builder handles each snippet individually and doesn't know about the other snippets. This means that it can't generate a CSS file which can handle Dark Mode and Light Mode.

The way around this is to create a Map which has every possible `DynamicTextStyle` class and maps that to a CSS class.
This can be found in the `docs/builders/src/css_classes.dart` file.

```dart
final styles = {
    DynamicTextStyle(
        lightStyle: TextStyle(color: Color(4278814810)),
        darkStyle: TextStyle(color: Color(4290105000))): "syntaxHighlight-1",
    // ...
    // Many more styles...
    // ...
    DynamicTextStyle(
        lightStyle: TextStyle(color: Color(4278190080)),
        darkStyle: TextStyle(color: Color(4292138196))): "syntaxHighlight-16",
};
```
Now we can exchange the `DynamicTextStyle` class with the CSS class in the HTML.

#### IMPORTANT: Manual CSS Updates

This `styles` map can be used to generate the CSS file. However, this does't happen automatically.
If these are updated, the CSS file needs to be updated manually. Run the `docs/builders/src/css_classes.dart` file which outputs the contents of the CSS file which then should be put in the `docs/docs/css/syntax_highlight.css` file.

This `styles` map rarely changes so this is not a big issue.


