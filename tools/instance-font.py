#!/usr/bin/env python3
"""Make a static, renamed instance of a variable font (Qt ignores axes).

Usage: instance-font.py VARIABLE.ttf "Family Name" OUT.ttf AXIS=VALUE...
Example (Matrix's dot numerals):
    instance-font.py "Doto[ROND,wght].ttf" "Doto Matrix" DotoMatrix.ttf wght=900 ROND=100
Needs fontTools.
"""

import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer


def main():
    source, family, out, *axes = sys.argv[1:]
    location = {k: float(v) for k, v in (a.split("=") for a in axes)}
    font = instancer.instantiateVariableFont(TTFont(source), location)
    for record in font["name"].names:
        if record.nameID in (1, 4, 16):
            record.string = family
        elif record.nameID == 6:
            record.string = family.replace(" ", "")
        elif record.nameID in (2, 17):
            record.string = "Regular"
    font.save(out)


if __name__ == "__main__":
    main()
