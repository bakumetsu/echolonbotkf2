@echo off
rem Builds avatars\dist\KF2-Avatars.exe (avatar server + game wrapper) with PyInstaller.
python -m pip install --upgrade pyinstaller pillow psutil
if errorlevel 1 exit /b 1
pyinstaller --onefile --noconsole --name KF2-Avatars --paths "%~dp0." --workpath "%~dp0build" --distpath "%~dp0dist" --specpath "%~dp0build" "%~dp0kf2_avatars_launcher.py"
if errorlevel 1 exit /b 1
copy /y "%~dp0README-Avatars.txt" "%~dp0dist\" >nul
echo.
echo Built: %~dp0dist\KF2-Avatars.exe
