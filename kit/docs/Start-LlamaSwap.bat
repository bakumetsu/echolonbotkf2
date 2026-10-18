@echo off
REM Starts llama-swap for the Echolon agent kit. Keep this window open while the kit runs.
REM Close the old llama-server launcher first: both use port 8080.
cd /d "%~dp0"
title llama-swap - Echolon kit (http://127.0.0.1:8080)
llama-swap.exe --config config.yaml --listen 127.0.0.1:8080
echo.
echo llama-swap stopped.
pause
