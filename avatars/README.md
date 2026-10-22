# Bot avatars server and launcher

Source for the scoreboard pictures of the bots (`bBotAvatars`). Not compiled: the exe is built locally and shared as a zip.

- `avatar_server.py`: HTTP server on `127.0.0.1:8765`. Crops the images in `Documents\My Games\KillingFloor2\KFGame\BotAvatars` to 128x128 and hands one out per bot slot. Run it by hand with `python avatar_server.py` (needs `pillow`).
- `kf2_avatars_launcher.py`: runs that server, starts the game and exits when `KFGame.exe` is gone. Log: `KFGame\Logs\KF2-Avatars.log`.
- `Build-AvatarsExe.bat`: builds `dist\KF2-Avatars.exe` (PyInstaller, no window) and copies `README-Avatars.txt` (the player instructions) next to it.

Steam launch option: `"C:\path\to\KF2-Avatars.exe" %command%`.
