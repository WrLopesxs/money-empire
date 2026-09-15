@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0scripts\run-python.cmd" "%~dp0scripts\tools.py" test
set "ME_RESULT=%errorlevel%"
pause
exit /b %ME_RESULT%
