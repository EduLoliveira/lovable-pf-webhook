@echo off
setlocal
set "GIT_CMD=C:\Users\Eduardo Oliveira\AppData\Local\Programs\Git\cmd\git.exe"
if not exist "%GIT_CMD%" set "GIT_CMD=git"

echo ==============================================================
echo       PUBLICAR NO GITHUB - LOVABLE TERMINAL RECEIVER
echo ==============================================================
echo.

set /p REPO_URL="Cole a URL do seu repositorio GitHub (ex: https://github.com/SEU_USER/repo.git): "

if "%REPO_URL%"=="" (
    echo [ERRO] Nenhuma URL informada. Operacao cancelada.
    pause
    exit /b
)

echo.
echo Conectando ao repositorio remoto...
"%GIT_CMD%" remote remove origin 2>nul
"%GIT_CMD%" remote add origin %REPO_URL%
"%GIT_CMD%" branch -M main

echo Enviando arquivos para o GitHub...
"%GIT_CMD%" push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo [SUCESSO] Seu projeto foi publicado no GitHub!
) else (
    echo [AVISO] Se solicitou login, faca a autenticacao na janela do navegador/terminal.
)

pause
