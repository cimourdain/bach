#!/usr/bin/env python3
"""Refresh the "Expected output" blocks of the library documentation pages.

For every `::: code-group` found in the "## Usage Examples" section of libs/<lib>.md, the
"With bach" snippet is executed (in a sandbox where lib/bach/ links to this
repository), its output is converted to styled HTML (ANSI colors) and written in a
collapsed `::: details Expected output` block placed right after the code-group.

Non deterministic values (timestamps, temp paths...) are replaced by fixed ones.

A `<!-- args: --foo bar -->` and/or `<!-- env: NAME=value -->` HTML comment placed right
before a code-group gives the arguments and environment variables used to run the script;
the executed command is then shown before the output. An example whose run fails (command not found...) gets
no output block and a warning is printed.

Usage: update_outputs.py [--dry-run] [lib ...]
"""
import html, os, re, shlex, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBS_DIR = ROOT / "libs"
DETAILS_TITLE = "Expected output"
TIMEOUT = 30
# Libraries whose examples do not work with the current code (docs to fix first): no output block
SKIP_LIBS = set()

# ---------------------------------------------------------------- ANSI -> HTML
BASIC = {"1": "red", "2": "green", "3": "yellow", "4": "blue", "5": "magenta", "6": "cyan"}
PALETTE_256 = {0: None, 1: "red", 2: "green", 3: "yellow", 4: "blue", 5: "magenta", 6: "cyan", 7: None,
               8: "dim", 9: "red", 10: "green", 11: "yellow", 12: "blue", 13: "magenta", 14: "cyan", 15: None}


def to_html(raw: str, command: str = "") -> str:
    raw = raw.replace("\x1b(B", "")
    out, state, opened, pos = [], [], False, 0

    def close():
        nonlocal opened
        if opened:
            out.append("</span>")
            opened = False

    def set_color(cls):
        state[:] = [c for c in state if not c.startswith("c-")]
        if cls == "dim":
            state.append("dim")
        elif cls:
            state.append("c-" + cls)

    for m in re.finditer(r"\x1b\[([0-9;]*)m", raw):
        out.append(html.escape(raw[pos:m.start()], quote=False))
        pos = m.end()
        close()
        codes = (m.group(1) or "0").split(";")
        i = 0
        while i < len(codes):
            c = codes[i]
            if c in ("0", ""):
                state.clear()
            elif c == "1":
                state.append("bold")
            elif c == "2":
                state.append("dim")
            elif len(c) == 2 and c[0] == "3" and c[1] in BASIC:
                set_color(BASIC[c[1]])
            elif len(c) == 2 and c[0] == "9" and c[1] in BASIC:
                set_color(BASIC[c[1]])
            elif c == "90":
                set_color("dim")
            elif c == "38" and i + 2 < len(codes) and codes[i + 1] == "5":
                set_color(PALETTE_256.get(int(codes[i + 2])))
                i += 2
            i += 1
        if state:
            out.append(f'<span class="{" ".join(dict.fromkeys(state))}">')
            opened = True
    out.append(html.escape(raw[pos:], quote=False))
    close()
    body = "".join(out).rstrip("\n")
    if command:
        body = f'<span class="cmd">$ {html.escape(command, quote=False)}</span>\n' + body
    return '<pre class="ansi" v-pre>' + body + "</pre>"


# ------------------------------------------------------------------ execution
def normalize(text: str, workdir: str) -> str:
    """Replace non deterministic values by fixed ones."""
    text = text.replace(workdir, "/home/user/project")
    text = re.sub(r"\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}", "2026-01-01 12:00:00", text)
    text = re.sub(r"/tmp/tmp\.[A-Za-z0-9]+", "/tmp/tmp.XXXXXXXXXX", text)
    text = re.sub(r"\b\d{2}:\d{2}:\d{2}\b", "12:00:00", text)
    text = re.sub(r"\btmp[A-Za-z0-9_]{8}\b", "tmpXXXXXXXX", text)
    return text


def run_snippet(code: str, args: list, extra_env: dict) -> str:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = os.path.realpath(tmp)
        lib_dir = Path(tmp) / "lib" / "bach"
        lib_dir.mkdir(parents=True)
        (lib_dir / "bach.sh").symlink_to(ROOT / "bach.sh")
        for f in LIBS_DIR.glob("*.sh"):
            (lib_dir / f.name).symlink_to(f)
        script = Path(tmp) / "my_script.sh"
        # fixed seed so that examples using $RANDOM are reproducible
        script.write_text(re.sub(r"^(#!.*\n)?", lambda m: (m.group(1) or "") + "RANDOM=42\n", code, count=1))
        env = {**os.environ, "TERM": "xterm-256color", "COLUMNS": "80", "TZ": "UTC", **extra_env}
        env.pop("LOG_LEVEL", None)
        try:
            res = subprocess.run(["bash", str(script), *args], cwd=tmp, env=env, stdin=subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=TIMEOUT)
            out = res.stdout.decode(errors="replace")
        except subprocess.TimeoutExpired as e:
            out = (e.stdout or b"").decode(errors="replace")
        out = out.replace("\r", "")
        return normalize(out, tmp)


# Output patterns revealing a broken example (the doc must be fixed, not published)
ERROR_PATTERNS = re.compile(
    r"command not found|unbound variable|syntax error|still not declared|No such file or directory: *$|"
    r"line \d+: .*\.sh: No such file", re.M)

# --------------------------------------------------------------- doc rewriting
CODE_GROUP = re.compile(r"::: code-group\n(.*?)\n:::\n", re.S)
STALE_AFTER = re.compile(
    r"\A(?:\n*(?:::: details " + DETAILS_TITLE + r"\n.*?\n:::\n|\*\*(?:Expected )?Output:?\*\*:?\n+```[^\n]*\n.*?```\n))+\n*", re.S)


def process(lib: str, dry: bool) -> int:
    path = LIBS_DIR / f"{lib}.md"
    text = path.read_text()
    m = re.search(r"\n## Usage Examples\n", text)
    if not m:
        return 0
    start = m.start() + 1
    nxt = re.search(r"\n## (?!Usage Examples)", text[start:])
    end = start + nxt.start() + 1 if nxt else len(text)
    sec = text[start:end]

    pieces, pos, count = [], 0, 0
    for g in CODE_GROUP.finditer(sec):
        pieces.append(sec[pos:g.end()])
        pos = g.end()
        # optional `<!-- args: ... -->` / `<!-- env: A=b ... -->` comments right before the group
        cm = re.search(r"((?:<!-- (?:args|env): .*? -->\s*)+)\Z", sec[:g.start()])
        args, extra_env = [], {}
        if cm:
            for kind, value in re.findall(r"<!-- (args|env): (.*?) -->", cm.group(1)):
                if kind == "args":
                    args = shlex.split(value)
                else:
                    extra_env = dict(item.split("=", 1) for item in shlex.split(value))
        command = ""
        if args or extra_env:
            command = " ".join([f"{k}={shlex.quote(v)}" for k, v in extra_env.items()]
                               + ["./my_script.sh"] + [shlex.quote(a) for a in args])
        # drop a previous generated (or hand written) output block following the group
        stale = STALE_AFTER.match(sec[pos:])
        if stale:
            pos += stale.end()
        bach = re.search(r"```bash \[With bach\]\n(.*?)```", g.group(1), re.S)
        if not bach:
            continue
        if lib in SKIP_LIBS:
            pieces.append("\n")
            continue
        output = run_snippet(bach.group(1), args, extra_env).strip("\n")
        if ERROR_PATTERNS.search(output):
            title = re.findall(r"^### (.*)$", sec[:g.start()], re.M)
            print(f"WARNING {lib}: example '{title[-1] if title else '?'}' fails, output skipped:\n    "
                  + "\n    ".join(output.splitlines()[:3]), file=sys.stderr)
            pieces.append("\n")
            continue
        if not output.strip():
            pieces.append("\n")
            continue
        count += 1
        if dry:
            print(f"--- {lib} example {count}\n{output}\n")
        pieces.append(f"\n::: details {DETAILS_TITLE}\n\n{to_html(output, command)}\n\n:::\n\n")
    pieces.append(sec[pos:])
    new_sec = "".join(pieces)
    # normalize blank lines between blocks
    new_sec = re.sub(r"\n{3,}", "\n\n", new_sec)
    if not dry:
        path.write_text(text[:start] + new_sec + text[end:])
    return count


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    libs = [a for a in args if not a.startswith("--")] or sorted(
        p.stem for p in LIBS_DIR.glob("*.md") if p.stem != "TODO")
    for lib in libs:
        n = process(lib, dry)
        print(f"{lib}: {n} output(s) {'previewed' if dry else 'updated'}")


if __name__ == "__main__":
    main()
