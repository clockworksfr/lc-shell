#!/usr/bin/env python3
"""Build launcher/data/emoji.json from Unicode data.

Inputs (Unicode License v3, see launcher/data/README.md):
  emoji-test.txt       https://unicode.org/Public/emoji/latest/emoji-test.txt
  <lang>.json          cldr-json: cldr-annotations-full/annotations/<lang>/annotations.json
  <lang>-derived.json  cldr-json: cldr-annotations-derived-full/annotationsDerived/<lang>/annotations.json

Usage: gen-emoji.py emoji-test.txt DIR > launcher/data/emoji.json
  DIR holds fr.json, fr-derived.json, en.json, en-derived.json.

Output: {
  "languages": ["en", "fr"],
  "emoji": [[emoji, version, {"en": [name, keywords], "fr": [name, keywords]}], ...]
}
Keywords joined with "|". Fully-qualified emoji only, skin-tone variants left out.
"""

import json
import os
import re
import sys

LANGUAGES = ["en", "fr"]
SKIN_TONES = {chr(c) for c in range(0x1F3FB, 0x1F400)}
LINE = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E([\d.]+)\s+(.+)$")


def load_annotations(path):
    data = json.load(open(path, encoding="utf-8"))
    root = data.get("annotations") or data.get("annotationsDerived")
    return root["annotations"]


def main():
    test_path, directory = sys.argv[1:3]
    annotations = {}
    for lang in LANGUAGES:
        annotations[lang] = {
            **load_annotations(os.path.join(directory, f"{lang}-derived.json")),
            **load_annotations(os.path.join(directory, f"{lang}.json")),
        }

    out = []
    for line in open(test_path, encoding="utf-8"):
        match = LINE.match(line.strip())
        if not match:
            continue
        codepoints, _, version, name_unicode = match.groups()
        emoji = "".join(chr(int(c, 16)) for c in codepoints.split())
        if any(ch in SKIN_TONES for ch in emoji):
            continue

        names = {}
        for lang in LANGUAGES:
            table = annotations[lang]
            entry = table.get(emoji) or table.get(emoji.replace("\ufe0f", "")) or {}
            name = (entry.get("tts") or [""])[0] or (name_unicode if lang == "en" else "")
            keywords = [k for k in entry.get("default", []) if k != name]
            names[lang] = [name, "|".join(keywords)]
        out.append([emoji, float(version), names])

    json.dump({"languages": LANGUAGES, "emoji": out}, sys.stdout, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main()
