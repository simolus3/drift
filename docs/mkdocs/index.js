#!/usr/bin/env node

const shiki = require("shiki");
const arg = require("arg");

const DEFAULT_THEME = "dark-plus";
const SUPPORTED_THEMES = shiki.BUNDLED_THEMES;

// Define the command-line interface
const args = arg({
  "--input": String,
  "--theme": String,
  "-i": "--input",
  "-t": "--theme",
});

async function main() {
  const input = args["--input"];
  const themeOption = args["--theme"];

  // Check theme is supported
  let theme = DEFAULT_THEME;

  if (themeOption) {
    if (!SUPPORTED_THEMES.includes(themeOption)) {
      console.error(`Error: Unsupported theme "${themeOption}"`);
      console.error(`Supported themes: ${SUPPORTED_THEMES.join(", ")}`);
      process.exit(1);
    }

    theme = themeOption;
  }

  // Apply syntax highlighting using the shiki library
  const shikiHighlighter = await shiki.getHighlighter({ theme });
  const output = shikiHighlighter.codeToHtml(input, { lang: "dart" });

  // Write to standard output
  console.log(output);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
