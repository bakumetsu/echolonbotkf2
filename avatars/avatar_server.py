"""Local HTTP server that serves bot avatars for Killing Floor 2."""

import argparse
import io
import os
import random
import re
import sys
import threading
import time
from collections import OrderedDict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from PIL import Image

ID_RE = re.compile(r"^\d{1,10}$")
EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".bmp"}
SIZE = 128

_cache: dict[tuple[str, float, int], bytes] = {}


def _flatten_alpha(img: Image.Image) -> Image.Image:
    """Flatten RGBA transparency onto black, return opaque RGB."""
    if img.mode == "RGBA":
        background = Image.new("RGB", img.size, (0, 0, 0))
        background.paste(img, mask=img.split()[3])
        return background
    return img.convert("RGB")


def _center_crop_square(img: Image.Image) -> Image.Image:
    """Crop to a square using the short side, centred."""
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def convert_image(path: Path) -> bytes:
    """Convert an image file to a 128x128 opaque RGBA PNG (in memory)."""
    stat = path.stat()
    key = (str(path.resolve()), stat.st_mtime, stat.st_size)
    if key in _cache:
        return _cache[key]

    img = Image.open(path)
    if img.format == "GIF":
        img.seek(0)
    img = img.convert("RGBA")
    img = _flatten_alpha(img)
    img = _center_crop_square(img)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    img.convert("RGBA").save(buf, format="PNG")
    data = buf.getvalue()
    _cache[key] = data
    return data


def scan_folder(folder: Path) -> list[Path]:
    """Return usable image files in *folder*, sorted by name. Bad files are skipped."""
    if not folder.is_dir():
        return []
    results: list[Path] = []
    for p in sorted(folder.iterdir(), key=lambda x: x.name):
        if p.suffix.lower() not in EXTENSIONS:
            continue
        try:
            convert_image(p)  # full decode, so truncated files are skipped too
            results.append(p)
        except Exception as exc:
            print(f"skip {p.name}: {exc}")
    return results


class AvatarPool:
    """Per-match avatar assignment with a bounded LRU of matches."""

    def __init__(self, folder: Path, rng: random.Random | None = None, max_matches: int = 8):
        self._folder = folder
        self._rng = rng or random.Random()
        self._max_matches = max_matches
        self._lock = threading.Lock()
        self._matches: OrderedDict[str, dict] = OrderedDict()

    def _resolve(self, match: str, slot: str) -> tuple[bytes | None, str | None]:
        """Return (bytes, filename) or (None, None) for the given match/slot."""
        if not ID_RE.match(match) or not ID_RE.match(slot):
            return None, None
        with self._lock:
            if match not in self._matches:
                images = scan_folder(self._folder)
                self._rng.shuffle(images)
                self._matches[match] = {
                    "images": images,
                    "assignments": {},
                    "filenames": {},
                }
                while len(self._matches) > self._max_matches:
                    self._matches.popitem(last=False)
            self._matches.move_to_end(match)

            entry = self._matches[match]
            if slot in entry["assignments"]:
                return entry["assignments"][slot], entry["filenames"][slot]
            idx = len(entry["assignments"])
            if idx >= len(entry["images"]):
                return None, None
            img_path = entry["images"][idx]
            data = convert_image(img_path)
            entry["assignments"][slot] = data
            entry["filenames"][slot] = img_path.name
            return data, img_path.name

    def get(self, match: str, slot: str) -> bytes | None:
        """Return avatar bytes for match/slot, or None if unavailable."""
        data, _ = self._resolve(match, slot)
        return data


def make_handler(pool: AvatarPool):
    """Return a request-handler class bound to *pool*."""

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass

        def do_GET(self):
            parts = self.path.strip("/").split("/")
            if len(parts) != 3 or parts[0] != "avatar":
                self._send(404, b"")
                self._log("?", "?", None)
                return
            match_id = parts[1]
            slot_raw = parts[2]
            if not slot_raw.endswith(".png"):
                self._send(404, b"")
                self._log(match_id, slot_raw, None)
                return
            slot_id = slot_raw[:-4]
            data, filename = pool._resolve(match_id, slot_id)
            if data is None:
                self._send(404, b"")
                self._log(match_id, slot_id, None)
            else:
                self._send(200, data)
                self._log(match_id, slot_id, filename)

        def _send(self, code: int, body: bytes):
            self.send_response(code)
            if body:
                self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if body:
                self.wfile.write(body)

        def _log(self, match_id: str, slot_id: str, filename: str | None):
            ts = time.strftime("%Y-%m-%d %H:%M:%S")
            name = filename or "404"
            print(f"{ts} {match_id}/{slot_id} -> {name}", flush=True)

    return Handler


def main(argv=None):
    parser = argparse.ArgumentParser(description="KF2 bot avatar server")
    parser.add_argument("--folder", type=Path, default=None, help="Image folder")
    parser.add_argument("--port", type=int, default=8765, help="Port to listen on")
    args = parser.parse_args(argv)

    if args.folder is not None:
        folder = args.folder
    else:
        home = Path(os.environ.get("USERPROFILE", os.path.expanduser("~")))
        folder = home / "Documents" / "My Games" / "KillingFloor2" / "KFGame" / "BotAvatars"

    pool = AvatarPool(folder)
    count = len(scan_folder(folder))
    print(f"Folder: {folder}")
    print(f"Port: {args.port}")
    print(f"Usable images: {count}")

    handler = make_handler(pool)
    try:
        server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    except OSError as exc:
        print(f"Cannot bind to 127.0.0.1:{args.port} — {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
