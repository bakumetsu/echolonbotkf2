# KF2-Avatars

Bot scoreboard pictures for Killing Floor 2.

## What's here

- `KF2-Avatars.exe` - starts the picture server and launches KF2
  through Steam. Drop it in the `BotAvatars` folder.
- `Start-AvatarServer.bat` - runs the same server without the
  exe (needs Python + `pillow`). Listens on 127.0.0.1:8765.
- `README-Avatars.txt` - plain-text player guide.

## Quick start

1. Put your pictures (png / jpg / jpeg / gif / bmp, any size) in
   `C:\Users\<you>\Documents\My Games\KillingFloor2\KFGame\BotAvatars`.
   Create the folder if it's missing.
2. Put `KF2-Avatars.exe` in that same folder.
3. Steam: Killing Floor 2, Properties, General, Launch Options:
   `"C:\Users\<you>\Documents\My Games\KillingFloor2\KFGame\BotAvatars\KF2-Avatars.exe" %command% -nostartupmovies`
   (replace `<you>`). Press Play.
4. In-game console, once: `mutate SetBotAvatars true`

Full step-by-step instructions: see `README-Avatars.txt`.

## For developers

Source: `avatar_server.py` (HTTP server on `127.0.0.1:8765`), `kf2_avatars_launcher.py` (runs the server, starts the game, exits when `KFGame.exe` is gone; log `KFGame\Logs\KF2-Avatars.log`). The exe is not committed. `kit\avatars\Build-AvatarsExe.bat` builds it with PyInstaller straight into `KFGame\BotAvatars`; the Steam launch option points there.
