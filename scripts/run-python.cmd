@echo off
setlocal EnableExtensions DisableDelayedExpansion
if exist "%~dp0..\.tools\python\python.exe" goto portable
rem Keep supporting existing clones that already have Python on PATH.
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>&1
if errorlevel 1 (
    echo ERRO: Python 3.10+ indisponivel. Execute Instalar.bat primeiro.
    exit /b 1
)
python %*
exit /b %errorlevel%
:portable
"%~dp0..\.tools\python\python.exe" %*
exit /b %errorlevel%
