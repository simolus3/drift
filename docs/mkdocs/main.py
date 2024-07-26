### This function delares macros which can be used in the documentation files.
import json
from pathlib import Path
from io import StringIO
from html.parser import HTMLParser
from textwrap import indent as indent_text
import subprocess

current_dir = Path(__file__).parent


class MLStripper(HTMLParser):
    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs = True
        self.text = StringIO()

    def handle_data(self, d):
        self.text.write(d)

    def get_data(self):
        return self.text.getvalue()


def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()


def define_env(env):
    # Read the versions.json file in `/lib`
    # This allows `{{ versions.drift }}` in the markdown files
    version_file = Path(__file__).parent.parent / "lib" / "versions.json"
    versions: dict[str, str] = json.loads(version_file.read_text())
    env.variables["versions"] = versions

    @env.macro
    def load_snippet(snippet_name: str, *args: str, indent: int = 0):
        """
        This macro allows to load a snippets from source files and display them in the documentation.

        The snippet_name referes to whatever the snippet is named in the source file (e.g. `setup` from  `// #docregion setup``)

        The args are a list of files to load the snippet from. (e.g 'lib/snippets/setup/database.dart.excerpt.json')

        The indent is the number of spaces to indent the snippet by. (default is 0)
        This is used when placing a snippet inside tabs.
        See the `docs` for examples where indentation is used.
        """
        files = [current_dir.parent / i for i in args]
        data = {}
        for file in files:
            data.update(json.loads(file.read_text()))

        content = strip_tags(data[snippet_name])

        # If this is not a dart file, we will return the content in a regular code block.
        result: str
        is_dart = any(".dart.excerpt.json" in str(file) for file in files)
        is_drift = any(".drift.excerpt.json" in str(file) for file in files)
        if not is_dart:
            if is_drift:
                result = markdown_codeblock(content, "sql")
            else:
                result = markdown_codeblock(content)
        else:
            result = html_codeblock(content)

        # Add the indent to the snippet, besides for the first line which is already indented.
        return indent_text(result, indent * " ").lstrip()

        # # Remove the minimum indentation from each line
        # html = "\n".join([line[min_indent:] for line in html.split("\n")])

        # # Build the snippet
        # snippet = f"""```{"dart" if is_dart else ""}""" + f"\n{html}\n" + """```"""

        # # Indent the snippet by the specified amount besides for the 1st line which is already indented.
        # return "\n".join(
        #     [
        #         " " * indent + line if i > 0 else line
        #         for i, line in enumerate(snippet.split("\n"))
        #     ]
        # )

        # return code_template(data[snippet_name], indent)


def html_codeblock(content: str) -> str:
    """
    Create the html for this code block.
    """
    result = subprocess.run(
        ["npm", "run", "highlight", "--silent", "--", "--input", content],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=current_dir,
    )
    if result.returncode != 0:
        raise Exception(
            f"Failed to highlight code block: {result.stdout} {result.stderr}"
        )
    return result.stdout.decode("utf-8")


def markdown_codeblock(content: str, lang: str = "") -> str:
    return f"```{lang}\n{content}\n```"
