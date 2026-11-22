#!/usr/bin/env python3
"""Build launcher/data/emoji.json from Unicode data.

Inputs (Unicode License v3, see launcher/data/README.md):
  emoji-test.txt   https://unicode.org/Public/emoji/latest/emoji-test.txt
  fr.json          cldr-json: cldr-annotations-full/annotations/fr/annotations.json
  fr-derived.json  cldr-json: cldr-annotations-derived-full/annotationsDerived/fr/annotations.json

Usage: gen-emoji.py emoji-test.txt fr.json fr-derived.json > launcher/data/emoji.json

Output: JSON array of [emoji, french name, english name, french keywords, emoji version],
fully-qualified emoji only, skin-tone variants left out.
"""

import json
import re
import sys

SKIN_TONES = {chr(c) for c in range(0x1F3FB, 0x1F400)}
LINE = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E([\d.]+)\s+(.+)$")


def load_annotations(path):
    data = json.load(open(path, encoding="utf-8"))
    root = data.get("annotations") or data.get("annotationsDerived")
    return root["annotations"]


def main():
    test_path, fr_path, derived_path = sys.argv[1:4]
    annotations = {**load_annotations(derived_path), **load_annotations(fr_path)}

    out = []
    for line in open(test_path, encoding="utf-8"):
        match = LINE.match(line.strip())
        if not match:
            continue
        codepoints, _, version, name_en = match.groups()
        emoji = "".join(chr(int(c, 16)) for c in codepoints.split())
        if any(ch in SKIN_TONES for ch in emoji):
            continue

        entry = annotations.get(emoji) or annotations.get(emoji.replace("\ufe0f", "")) or {}
        name_fr = (entry.get("tts") or [""])[0]
        keywords = [k for k in entry.get("default", []) if k != name_fr]
        out.append([emoji, name_fr, name_en, "|".join(keywords), float(version)])

    json.dump(out, sys.stdout, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main()
