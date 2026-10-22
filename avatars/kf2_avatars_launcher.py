"""Launcher for the KF2 avatar server."""

import os
import subprocess
import sys
import threading
import time
import traceback
from datetime import datetime
from http.server import ThreadingHTTPServer
from pathlib import Path

from avatar_server import AvatarPool, make_handler, scan_folder


def _default_process_check() -> bool:
    """Return True while any KFGame.exe process is alive."""
    import psutil

    for proc in psutil.process_iter(["name"]):
        try:
            if proc.info["name"] == "KFGame.exe":
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return False


def _ts() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def run(
    argv: list[str],
    *,
    port: int = 8765,
    folder: Path | None = None,
    log_path: Path | None = None,
    process_check=None,
    poll_interval: float = 5.0,
    start_timeout: float = 120.0,
) -> int:
    if folder is None:
        folder = (
            Path(os.environ["USERPROFILE"])
            / "Documents" / "My Games" / "KillingFloor2" / "KFGame" / "BotAvatars"
        )
    if log_path is None:
        log_path = (
            Path(os.environ["USERPROFILE"])
            / "Documents" / "My Games" / "KillingFloor2" / "KFGame" / "Logs" / "KF2-Avatars.log"
        )
    if process_check is None:
        process_check = _default_process_check

    folder = Path(folder)
    log_path = Path(log_path)

    folder.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    log_file = open(log_path, "w", encoding="utf-8")
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    sys.stdout = log_file  # type: ignore[assignment]
    sys.stderr = log_file  # type: ignore[assignment]

    def _log(msg: str) -> None:
        print(f"[{_ts()}] {msg}", flush=True)

    server: ThreadingHTTPServer | None = None
    exit_code = 0

    try:
        _log(f"Start: {datetime.now().isoformat()}")
        _log(f"Folder: {folder}")

        try:
            images = scan_folder(folder)
            _log(f"Usable images: {len(images)}")
        except Exception:
            _log("Error scanning folder:")
            traceback.print_exc()

        _log(f"Server port: {port}")

        # --- start server (non-fatal) ---
        try:
            pool = AvatarPool(folder)
            handler = make_handler(pool)
            server = ThreadingHTTPServer(("127.0.0.1", port), handler)
            t = threading.Thread(target=server.serve_forever, daemon=True)
            t.start()
        except OSError as exc:
            _log(f"Port {port} already in use: {exc}")
            server = None
        except Exception:
            _log("Server setup failed:")
            traceback.print_exc()
            server = None

        # --- launch game ---
        if argv:
            _log(f"Game command: {argv}")
            proc = subprocess.Popen(argv)
            _log("Game started")
            proc.wait()
            exit_code = proc.returncode if proc.returncode is not None else 0
            _log(f"Game process exited with code {exit_code}")

            while process_check():
                time.sleep(poll_interval)
        else:
            _log("No arguments — launching via Steam")
            os.startfile("steam://rungameid/232090")  # type: ignore[attr-defined]
            _log("Game started (Steam launch)")

            deadline = time.monotonic() + start_timeout
            appeared = False
            while time.monotonic() < deadline:
                if process_check():
                    appeared = True
                    break
                time.sleep(poll_interval)

            if not appeared:
                _log(f"KFGame.exe did not appear within {start_timeout:.0f}s")
                exit_code = 1
            else:
                _log("KFGame.exe detected")
                while process_check():
                    time.sleep(poll_interval)
                exit_code = 0

        _log("game closed, exiting")

    except Exception:
        _log("Fatal error:")
        traceback.print_exc()
        exit_code = 1

    finally:
        if server is not None:
            try:
                server.shutdown()
                server.server_close()
            except Exception:
                pass
        sys.stdout = old_stdout
        sys.stderr = old_stderr
        log_file.close()

    return exit_code


def main() -> None:
    sys.exit(run(sys.argv[1:]))


if __name__ == "__main__":
    main()
