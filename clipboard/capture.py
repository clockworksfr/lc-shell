#!/usr/bin/env python3
"""Clipboard capture for lc-shell, run by `wl-paste --watch` on every change.

    wl-paste --watch python3 -I capture.py <store dir> <max image bytes> <ignore sensitive 1|0>

Picks the richest useful type of the new selection (files, image, text),
stores the payload as <store dir>/blobs/<sha1>.<ext> and prints one JSON
line on stdout, read by Clipboard.qml (which indexes, dedupes and prunes):

    {"state": "data", "hash", "mime", "file", "size", "text"?, "w"?, "h"?}
    {"state": "sensitive" | "skipped" | "empty"}

The selection content arrives on stdin (type chosen by wl-paste); it is
ignored and read again with the chosen type.
"""

import hashlib
import json
import os
import struct
import subprocess
import sys

# Inline text kept in the index for search and previews.
TEXT_INLINE = 16 * 1024
IMAGE_TYPES = ["image/png", "image/jpeg", "image/webp", "image/gif", "image/bmp", "image/svg+xml"]
TEXT_TYPES = ["text/plain;charset=utf-8", "text/plain", "UTF8_STRING", "STRING", "TEXT"]
EXTENSIONS = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif", "image/bmp": "bmp", "image/svg+xml": "svg"}


def emit(record):
    sys.stdout.write(json.dumps(record, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def paste(mime):
    return subprocess.run(["wl-paste", "--no-newline", "--type", mime], capture_output=True, timeout=10).stdout


def image_size(data):
    """Width and height of a PNG or JPEG, else (0, 0)."""
    if data[:8] == b"\x89PNG\r\n\x1a\n" and len(data) >= 24:
        return struct.unpack(">II", data[16:24])
    if data[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            length = struct.unpack(">H", data[i + 2:i + 4])[0]
            if marker in (0xC0, 0xC1, 0xC2):
                h, w = struct.unpack(">HH", data[i + 5:i + 9])
                return w, h
            i += 2 + length
    return 0, 0


def main():
    # The store is private: copies can hold secrets.
    os.umask(0o077)
    try:
        sys.stdin.buffer.read()
    except OSError:
        pass

    store = sys.argv[1]
    max_image = int(sys.argv[2]) if len(sys.argv) > 2 else 20 * 1000 * 1000
    ignore_sensitive = (sys.argv[3] if len(sys.argv) > 3 else "1") != "0"
    state = os.environ.get("CLIPBOARD_STATE", "data")
    if state == "sensitive" and ignore_sensitive:
        return emit({"state": "sensitive"})
    if state not in ("data", "sensitive"):
        return

    types = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True, timeout=5).stdout.split("\n")
    types = [t.strip() for t in types if t.strip()]
    # Password managers mark their copies (KeePassXC, KDE).
    if ignore_sensitive and "x-kde-passwordManagerHint" in types:
        return emit({"state": "sensitive"})

    if "text/uri-list" in types:
        mime = "text/uri-list"
    else:
        image = next((t for t in IMAGE_TYPES if t in types), None)
        text = next((t for t in TEXT_TYPES if t in types), None)
        # A browser's "copy image" also offers text/html: the image wins.
        mime = (image if max_image > 0 else None) or text
    if not mime:
        return emit({"state": "skipped", "types": types[:8]})

    data = paste(mime)
    if not data or (mime.startswith("text") or mime in TEXT_TYPES) and not data.strip():
        return emit({"state": "empty"})
    if mime.startswith("image/") and len(data) > max_image:
        return emit({"state": "skipped", "reason": "size", "size": len(data)})

    digest = hashlib.sha1(data).hexdigest()
    ext = EXTENSIONS.get(mime, "txt")
    blobs = os.path.join(store, "blobs")
    os.makedirs(blobs, exist_ok=True)
    name = f"{digest}.{ext}"
    path = os.path.join(blobs, name)
    if not os.path.exists(path):
        tmp = path + ".part"
        with open(tmp, "wb") as f:
            f.write(data)
        os.replace(tmp, path)

    record = {"state": "data", "hash": digest, "mime": mime, "file": name, "size": len(data)}
    if mime.startswith("image/"):
        w, h = image_size(data)
        record.update(w=w, h=h)
    else:
        record["text"] = data[:TEXT_INLINE].decode("utf-8", errors="replace")
        record["truncated"] = len(data) > TEXT_INLINE
        record["mime"] = "text/uri-list" if mime == "text/uri-list" else "text/plain;charset=utf-8"
    emit(record)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never kill the watcher
        emit({"state": "error", "error": str(e)[:200]})
