@echo off
setlocal EnableExtensions DisableDelayedExpansion
if /i "%~1"=="--ajuda" goto help
set "ME_SKIP_STUDIO=0"
set "ME_NO_PAUSE=0"
:options
if "%~1"=="" goto begin
if /i "%~1"=="--sem-studio" (set "ME_SKIP_STUDIO=1") else if /i "%~1"=="--sem-pausa" (set "ME_NO_PAUSE=1") else (
    echo Opcao desconhecida: %~1
    exit /b 2
)
shift
goto options
:begin
echo MONEY EMPIRE - Preparar este computador
echo Windows 10/11 x64. Internet necessaria. Instalacao na pasta do projeto.
echo.
if not exist "%~dp0scripts\tools.py" (
    echo ERRO: extraia o ZIP inteiro antes de executar Instalar.bat.
    goto failed
)
echo [1/4] Preparando Python portatil...
call "%~dp0scripts\install-python.cmd"
if errorlevel 1 goto failed
echo [2/4] Instalando Rojo e Luau...
call "%~dp0scripts\run-python.cmd" "%~dp0scripts\tools.py" setup
if errorlevel 1 goto failed
echo [3/4] Gerando MoneyEmpire.rbxlx...
call "%~dp0scripts\run-python.cmd" "%~dp0scripts\tools.py" build
if errorlevel 1 goto failed
if "%ME_SKIP_STUDIO%"=="1" goto ready
echo [4/4] Instalando ou localizando Roblox Studio...
call "%~dp0scripts\run-python.cmd" "%~dp0scripts\tools.py" setup --studio
if errorlevel 1 goto studio_failed
:ready
echo.
echo PRONTO: Python, Rojo, Luau e o arquivo do jogo estao preparados.
if "%ME_SKIP_STUDIO%"=="1" echo Studio foi pulado. Instale-o para jogar em 3D.
echo Abra Jogar.cmd, entre na sua conta Roblox no Studio e pressione F5.
echo Testar.cmd executa os testes de economia separadamente.
if "%ME_NO_PAUSE%"=="0" pause
exit /b 0
:studio_failed
echo.
echo INSTALACAO PARCIAL: Python, ferramentas e jogo prontos. Studio pendente.
echo Confira o erro acima. Tente novamente quando Roblox estiver acessivel.
echo Instalacao oficial: https://create.roblox.com/
goto failed
:failed
echo.
echo Nao foi possivel concluir. Confira o erro acima e execute novamente.
echo Se houver bloqueio de seguranca, siga as regras do seu computador.
if "%ME_NO_PAUSE%"=="0" pause
exit /b 1
:help
echo Uso: Instalar.bat [--sem-studio] [--sem-pausa]
echo Instala Python portatil, Rojo, Luau, gera o jogo e instala Roblox Studio.
echo --sem-studio: prepara somente Python, ferramentas e o arquivo do jogo.
echo --sem-pausa: termina sem esperar uma tecla.
exit /b 0
