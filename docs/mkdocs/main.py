### This function delares macros which can be used in the documentation files.
import json
from pathlib import Path
from io import StringIO
from html.parser import HTMLParser
import random
import string
from textwrap import indent as indent_text
from typing import Any

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


class Snippet:
    def __init__(self, data: dict[str, Any]) -> None:
        self.is_html: bool = data["isHtml"]
        self.code: str = data["code"]
        self.name: str = data["name"]


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
    def load_snippet(
        snippet_name: str, *args: str, indent: int = 0, title: None | str = None
    ) -> str:
        """
        This macro allows to load a snippets from source files and display them in the documentation.

        The snippet_name referes to whatever the snippet is named in the source file (e.g. `setup` from  `// #docregion setup``)

        The args are a list of files to load the snippet from. (e.g 'lib/snippets/setup/database.dart.excerpt.json')

        The indent is the number of spaces to indent the snippet by. (default is 0)
        This is used when placing a snippet inside tabs.
        See the `docs` for examples where indentation is used.
        """
        files = [current_dir.parent / i for i in args]
        data: dict[str, Snippet] = {}
        for file in files:
            raw_snippets: list[dict[str, Any]] = json.loads(file.read_text())
            for rs in raw_snippets:
                snippet = Snippet(rs)
                data[snippet.name] = snippet

        # Locate the snippet in the data
        snippet = data[snippet_name]
        is_drift = any(".drift.excerpt.json" in str(file) for file in files)

        result: str

        if snippet.is_html:
            result = html_codeblock(snippet.code, title)
        elif is_drift:
            result = markdown_codeblock(snippet.code, "sql", title)
        else:
            result = markdown_codeblock(snippet.code, title=title)

        # Add the indent to the snippet, besides for the first line which is already indented.
        return indent_text(result, indent * " ").lstrip()


def markdown_codeblock(content: str, lang: str = "", title: None | str = None) -> str:
    title_tag = "" if title is None else f' title="{title}"'
    return f"```{lang}{title_tag}\n{content}\n```"


def html_codeblock(content: str, title: None | str = None) -> str:
    """
    Create the html for this code block.
    """
    random_id = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    # Split the content by new line
    lines = content.splitlines()

    # Replace blank lines with <br> tag
    lines = [line if len(line.strip()) > 0 else "<br>" for line in lines]

    content = "\n".join(lines)

    result = f"""<pre id="{random_id}"><code>{content}</code></pre>"""
    if title:
        result = f"""<div class="highlight"><span class="filename">{title}</span>{result}</div>"""

    return result
