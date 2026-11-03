@echo off
setlocal enabledelayedexpansion
title Git Sync - Commit & Push para GitHub
cd /d "%~dp0"

set "GIT_CMD=C:\Users\Eduardo Oliveira\AppData\Local\Programs\Git\cmd\git.exe"
if not exist "%GIT_CMD%" set "GIT_CMD=git"

echo ==============================================================
echo        SINCRONIZAR COM GITHUB (ADD, COMMIT E PUSH)
echo ==============================================================
echo.

echo [1/3] Verificando arquivos alterados...
"%GIT_CMD%" status -s
echo.

set /p COMMIT_MSG="Digite a mensagem do commit (ou Enter para padrao): "

if "%COMMIT_MSG%"=="" (
    set "COMMIT_MSG=feat: update project files and autodrome animations"
)

echo.
echo [2/3] Adicionando arquivos e realizando commit...
"%GIT_CMD%" add .
"%GIT_CMD%" commit -m "%COMMIT_MSG%"

echo.
echo [3/3] Enviando alteracoes para o GitHub (main)...
"%GIT_CMD%" push origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ==============================================================
    echo  [SUCESSO] Alteracoes enviadas com sucesso para o GitHub!
    echo ==============================================================
) else (
    echo [AVISO] Ocorreu uma pendencia no push. Verifique conexao ou permissoes.
)

pause
