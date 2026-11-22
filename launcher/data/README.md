# Données du lanceur

`emoji.json` est généré par `tools/gen-emoji.py` à partir de :

- `emoji-test.txt` (Unicode Emoji 18.0) — https://unicode.org/Public/emoji/latest/
- annotations anglaises et françaises du CLDR — https://github.com/unicode-org/cldr-json

Ces données sont sous [Unicode License v3](https://www.unicode.org/license.txt) :
copyright © 1991-2026 Unicode, Inc. Redistribution libre avec cette notice.

Régénérer :

```sh
curl -LO https://unicode.org/Public/emoji/latest/emoji-test.txt
for l in en fr; do
  curl -L -o $l.json https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/$l/annotations.json
  curl -L -o $l-derived.json https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-derived-full/annotationsDerived/$l/annotations.json
done
python3 tools/gen-emoji.py emoji-test.txt . > emoji.json && mv emoji.json launcher/data/emoji.json
```
