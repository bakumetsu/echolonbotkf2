KF2-Avatars - Bot Scoreboard Pictures
=====================================

What it does
------------
Gives each bot a picture on the scoreboard. Drop in images and the
game shows them.

1. Put your pictures in the avatars folder
   The folder is:
     C:\Users\<you>\Documents\My Games\KillingFloor2\KFGame\BotAvatars
   Make the folder by hand if it is not there yet (the exe also
   creates it on first run).
   Accepted formats: png, jpg, jpeg, gif, bmp. Any size.
   Each picture is cropped to a centred square and shrunk to
   128x128. A gif uses its first frame. File names do not matter.
   One picture per bot. If you have more bots than pictures,
   the pictures repeat.

2. Download KF2-Avatars.exe from the Releases page:
   https://github.com/bakumetsu/echolonbotkf2/releases
   and put it in that same BotAvatars folder. It ignores any non-picture
   files in the folder. (To build it yourself instead, install Python and run
   Build-AvatarsExe.bat from the avatars folder of the source; it puts the exe in BotAvatars.)

3. Tell Steam to start the exe before the game.
   Right-click Killing Floor 2 in your Steam library, choose
   Properties, go to the General tab, and in the Launch Options
   box paste:
     "C:\Users\<you>\Documents\My Games\KillingFloor2\KFGame\BotAvatars\KF2-Avatars.exe" %command% -nostartupmovies
   Replace <you> with your Windows user name.
   Press Play as usual. The exe has no window of its own; it
   starts the picture server, launches the game, and quits when
   the game closes.
   (Double-clicking KF2-Avatars.exe also starts the game through
   Steam, if you prefer.)
   If Windows warns about an unknown app, click More info, then
   Run anyway.
   If the launch option does not take effect, restart Steam.

4. Turn on avatars in the game (once).
   Open the game console and type:
     mutate SetBotAvatars true
   That is it. Every match after that will show the pictures.

Optional: run the server without the exe
-----------------------------------------
If you would rather not edit Steam launch options, double-click
Start-AvatarServer.bat before starting the game. You need Python
and the pillow package (pip install pillow). The bat file opens
a small minimized window; leave it running while you play and
close it afterwards. The server listens on 127.0.0.1 port 8765.

Troubleshooting
---------------
Nothing showing? Open this file:
  C:\Users\<you>\Documents\My Games\KillingFloor2\KFGame\Logs\KF2-Avatars.log
It tells you which folder it used and how many usable pictures
it found.
