"""Build README.pdf (Greek) and README.en.pdf (English) from the Markdown READMEs.

How it works: GitHub's own Markdown API turns each README into HTML (so tables,
badges and collapsible sections look like on github.com), local images are taken
from this working copy (so new, not yet pushed images are included), links to
repository files point to GitHub, and Chrome prints A4 PDFs.

Usage (from the repository root), after every change to README.md / README.en.md:
    python tools/build_readme_pdf.py
    python tools/build_readme_pdf.py --chrome "C:\\path\\to\\chrome.exe"

Needs: Python 3, Google Chrome, Internet access (api.github.com, shields.io badges).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_URL = "https://github.com/sanguinarypc/BoxingGymSensorsProject"
CSS = "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.5.1/github-markdown-light.min.css"
TARGETS = [("README.md", "README.pdf", "el", "Box Sensors — README"),
           ("README.en.md", "README.en.pdf", "en", "Box Sensors — README (English)")]
ALERT_TITLES = {"NOTE": "ℹ️ Note", "TIP": "💡 Tip", "IMPORTANT": "❗ Important",
                "WARNING": "⚠️ Warning", "CAUTION": "🛑 Caution"}
CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
    "/usr/bin/google-chrome", "/usr/bin/chromium",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]
STYLE = """
  @page { size: A4; margin: 14mm 12mm; }
  body { margin: 0; background: #fff; }
  .markdown-body { box-sizing: border-box; max-width: 900px; margin: 0 auto; padding: 8px 4px; font-size: 13px; }
  .markdown-body img { max-width: 100%; height: auto; }
  .markdown-body table, .markdown-body pre, .markdown-body img,
  .markdown-body .markdown-alert, .markdown-body blockquote { break-inside: avoid; }
  .markdown-body h2, .markdown-body h3, .markdown-body h4 { break-after: avoid; }
  .markdown-body pre, .markdown-body pre code { white-space: pre-wrap !important; word-break: break-word; overflow: visible !important; }
  .markdown-alert { padding: .5rem 1rem; margin-bottom: 16px; border-left: .25em solid #0969da; }
  .markdown-alert-tip { border-left-color: #1a7f37; }
  .markdown-alert-important { border-left-color: #8250df; }
  .markdown-alert-warning { border-left-color: #9a6700; }
  .markdown-alert-caution { border-left-color: #d1242f; }
  .markdown-alert-title { font-weight: 600; margin: 0 0 4px; }
  summary { font-weight: 600; }
"""


def find_chrome(explicit):
    for path in [explicit] + CHROME_CANDIDATES:
        if path and os.path.isfile(path):
            return path
    sys.exit("Chrome not found. Pass it with --chrome <path to chrome.exe>.")


def markdown_to_html(text):
    request = urllib.request.Request(
        "https://api.github.com/markdown",
        data=json.dumps({"text": text, "mode": "markdown"}).encode(),
        headers={"Accept": "application/vnd.github+json", "User-Agent": "box-sensors-readme-pdf"})
    return urllib.request.urlopen(request, timeout=60).read().decode("utf8")


def prepare(body):
    local = "file:///" + ROOT.replace("\\", "/").rstrip("/") + "/"

    # GitHub alerts ("> [!NOTE]") come back as plain quotes in document mode -> styled boxes
    body, alerts = re.subn(
        r"<blockquote>\s*<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*?)</p>\s*</blockquote>",
        lambda m: (f'<div class="markdown-alert markdown-alert-{m.group(1).lower()}">'
                   f'<p class="markdown-alert-title">{ALERT_TITLES[m.group(1)]}</p><p>{m.group(2)}</p></div>'),
        body, flags=re.S)

    # paper cannot be clicked open: show every collapsible section expanded
    body = re.sub(r"<details(?![^>]*\bopen\b)", "<details open", body)

    # relative images -> files of this working copy
    def fix_src(match):
        url = match.group(2)
        if re.match(r"^(https?:|data:|#)", url):
            return match.group(0)
        return f'{match.group(1)}"{local}{url.lstrip("./")}"'
    body = re.sub(r'(<img[^>]*?\bsrc=)"([^"]+)"', fix_src, body)

    # relative links -> GitHub; in-page anchors -> GitHub's "user-content-" ids
    def fix_href(match):
        url = match.group(1)
        if url.startswith("#"):
            return match.group(0) if url.startswith("#user-content-") else f'href="#user-content-{url[1:]}"'
        if re.match(r"^(https?:|mailto:|file:)", url):
            return match.group(0)
        return f'href="{REPO_URL}/blob/main/{url.lstrip("./")}"'
    body = re.sub(r'href="([^"]+)"', fix_href, body)
    return body, alerts


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--chrome", help="path to chrome.exe (auto-detected if omitted)")
    args = parser.parse_args()
    chrome = find_chrome(args.chrome)

    with tempfile.TemporaryDirectory() as work:
        for source, target, lang, title in TARGETS:
            body, alerts = prepare(markdown_to_html(open(os.path.join(ROOT, source), encoding="utf8").read()))
            page = os.path.join(work, f"readme_{lang}.html")
            with open(page, "w", encoding="utf8") as fh:
                fh.write(f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><title>{title}</title>'
                         f'<link rel="stylesheet" href="{CSS}"><style>{STYLE}</style></head>'
                         f'<body><article class="markdown-body">{body}</article></body></html>')
            out = os.path.join(ROOT, target)
            subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                            f"--user-data-dir={os.path.join(work, 'profile')}",
                            "--allow-file-access-from-files", "--virtual-time-budget=30000",
                            f"--print-to-pdf={out}", "file:///" + page.replace("\\", "/")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=240, check=False)
            if not os.path.isfile(out):
                sys.exit(f"{target}: Chrome did not produce the PDF")
            print(f"{source} -> {target}  ({os.path.getsize(out) // 1024} KB, {alerts} alert boxes)")


if __name__ == "__main__":
    main()
