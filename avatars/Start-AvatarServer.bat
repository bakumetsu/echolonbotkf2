@echo off
rem Starts the avatar picture server by hand (needs Python and: pip install pillow).
start "Echolon Avatar Server" /min python "%~dp0avatar_server.py"
