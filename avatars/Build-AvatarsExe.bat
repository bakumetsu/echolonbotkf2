@echo off
rem Builds KF2-Avatars.exe (avatar server + game wrapper) with PyInstaller straight into the Bot Avatar folder,
rem KFGame\BotAvatars, where the Steam launch option points. Close the game first (a running exe cannot be overwritten).
set "OUT=%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\BotAvatars"
python -m pip install --upgrade pyinstaller pillow psutil
if errorlevel 1 exit /b 1
pyinstaller --onefile --noconsole --name KF2-Avatars --paths "%~dp0." --workpath "%~dp0build" --distpath "%OUT%" --specpath "%~dp0build" "%~dp0kf2_avatars_launcher.py"
if errorlevel 1 exit /b 1
echo.
echo Built: %OUT%\KF2-Avatars.exe
