@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0scripts\run-python.cmd" "%~dp0scripts\tools.py" open
set "ME_RESULT=%errorlevel%"
if errorlevel 1 pause
exit /b %ME_RESULT%
