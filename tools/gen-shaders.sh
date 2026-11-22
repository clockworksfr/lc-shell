#!/bin/sh
# Compiles assets/shaders/*.frag to .qsb (Qt Shader Baker, Qt 6).
set -e
cd "$(dirname "$0")/../assets/shaders"
for f in *.frag; do
    /usr/lib/qt6/bin/qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o "$f.qsb" "$f"
done
