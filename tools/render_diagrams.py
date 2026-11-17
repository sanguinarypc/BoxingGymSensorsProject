"""Render the README diagrams (pictures/diagrams/*.mmd) to PNG images.

Why PNG: the GitHub mobile app does not draw Mermaid diagrams, so the READMEs
embed these images instead. Edit the .mmd file, then run this script.

Usage (from the repository root):
    python tools/render_diagrams.py            # renders every .mmd
    python tools/render_diagrams.py --chrome "C:\\path\\to\\chrome.exe"

Needs: Python 3 + Pillow (pip install pillow), Google Chrome, Internet access
(mermaid is loaded from cdn.jsdelivr.net).
"""
import argparse
import glob
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIAGRAMS = os.path.join(ROOT, "pictures", "diagrams")
BACKGROUND = "#161B22"            # dark background (same as GitHub dark theme)
BACKGROUND_RGB = (0x16, 0x1B, 0x22)
MARGIN = 28                       # pixels around the drawing (at 2x scale)
MERMAID = "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"
CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
    "/usr/bin/google-chrome", "/usr/bin/chromium",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]

PAGE = """<!doctype html><html><head><meta charset="utf-8">
<script src="{mermaid}"></script>
<style>html,body{{margin:0;background:{bg}}} #d{{display:inline-block;padding:24px}}</style></head>
<body><div id="d"></div><script>
mermaid.initialize({{startOnLoad:false, theme:'base',
  flowchart:{{htmlLabels:true, curve:'basis', nodeSpacing:40, rankSpacing:55, padding:14}},
  themeVariables:{{fontFamily:'Segoe UI, Arial, sans-serif', fontSize:'19px',
    darkMode:true, background:'{bg}', primaryColor:'#2E1F5E', primaryTextColor:'#E2E8F0',
    textColor:'#E2E8F0', primaryBorderColor:'#A78BFA', lineColor:'#94A3B8',
    clusterBkg:'#1C2330', clusterBorder:'#475569', edgeLabelBackground:'{bg}', titleColor:'#E2E8F0'}}}});
mermaid.render('m', {source}).then(r => {{
  const d = document.getElementById('d'); d.innerHTML = r.svg;
  const svg = d.querySelector('svg'); const vb = svg.viewBox.baseVal;
  svg.style.maxWidth = 'none';                     // draw at 2x for sharp text on phones
  svg.setAttribute('width', vb.width * 2); svg.setAttribute('height', vb.height * 2);
}}).catch(e => {{ document.body.innerText = 'ERROR ' + e.message; }});
</script></body></html>"""


def find_chrome(explicit):
    for path in [explicit] + CHROME_CANDIDATES:
        if path and os.path.isfile(path):
            return path
    sys.exit("Chrome not found. Pass it with --chrome <path to chrome.exe>.")


def render(mmd_path, chrome, work):
    name = os.path.splitext(os.path.basename(mmd_path))[0]
    source = open(mmd_path, encoding="utf8").read()
    page = os.path.join(work, f"{name}.html")
    with open(page, "w", encoding="utf8") as fh:
        fh.write(PAGE.format(mermaid=MERMAID, bg=BACKGROUND, source=json.dumps(source)))
    shot = os.path.join(work, f"{name}_raw.png")
    subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    f"--user-data-dir={os.path.join(work, 'profile')}",
                    "--window-size=1800,2600", "--virtual-time-budget=15000",
                    f"--screenshot={shot}", "file:///" + page.replace("\\", "/")],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180, check=False)
    image = Image.open(shot).convert("RGB")
    box = ImageChops.difference(image, Image.new("RGB", image.size, BACKGROUND_RGB)).getbbox()
    if not box:
        print(f"  {name}: EMPTY render (check the .mmd syntax or Internet access)")
        return False
    left, top, right, bottom = box
    if right >= image.width - 2 or bottom >= image.height - 2:
        print(f"  {name}: WARNING the drawing touches the window edge and may be cut off")
    image = image.crop((max(left - MARGIN, 0), max(top - MARGIN, 0),
                        min(right + MARGIN, image.width), min(bottom + MARGIN, image.height)))
    out = os.path.join(DIAGRAMS, f"{name}.png")
    image.save(out, optimize=True)
    print(f"  {name}.png  {image.size[0]}x{image.size[1]}  {os.path.getsize(out) // 1024} KB")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--chrome", help="path to chrome.exe (auto-detected if omitted)")
    args = parser.parse_args()
    chrome = find_chrome(args.chrome)
    sources = sorted(glob.glob(os.path.join(DIAGRAMS, "*.mmd")))
    print(f"Rendering {len(sources)} diagram(s) from {DIAGRAMS}")
    with tempfile.TemporaryDirectory() as work:
        ok = all([render(path, chrome, work) for path in sources])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
