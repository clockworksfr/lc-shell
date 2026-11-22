# Données du lanceur

`emoji.json` est généré par `tools/gen-emoji.py` à partir de :

- `emoji-test.txt` (Unicode Emoji 18.0) — https://unicode.org/Public/emoji/latest/
- annotations françaises du CLDR — https://github.com/unicode-org/cldr-json

Ces données sont sous [Unicode License v3](https://www.unicode.org/license.txt) :
copyright © 1991-2026 Unicode, Inc. Redistribution libre avec cette notice.

Régénérer :

```sh
curl -LO https://unicode.org/Public/emoji/latest/emoji-test.txt
curl -L -o fr.json https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/fr/annotations.json
curl -L -o fr-derived.json https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-derived-full/annotationsDerived/fr/annotations.json
python3 tools/gen-emoji.py emoji-test.txt fr.json fr-derived.json > launcher/data/emoji.json
```
