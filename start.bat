@echo off
setlocal
cd /d "%~dp0"
title Jiuhu MC Server (NeoForge 21.1.267)
rem Java 21 (Oracle JRE on this machine). Keep this file ASCII-only, CRLF, no BOM.
set "JAVA_CMD=C:\Program Files\Common Files\Oracle\Java\javapath\java.exe"
if not exist "%JAVA_CMD%" (
    echo [ERROR] java.exe not found: "%JAVA_CMD%"
    echo Install Java 21 or edit JAVA_CMD in this file.
    pause
    exit /b 1
)
if not exist logs mkdir logs
echo [Jiuhu] Starting server. Console output is written to logs\start_console.log
echo [Jiuhu] The window stays quiet while the server runs - that is normal.
echo [Jiuhu] Watch logs\start_console.log for live output.
"%JAVA_CMD%" @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.267/win_args.txt %* >> "logs\start_console.log" 2>&1
set EXITCODE=%ERRORLEVEL%
echo.
echo [Jiuhu] Server exited with code %EXITCODE%. See logs\latest.log and logs\start_console.log
pause
exit /b %EXITCODE%
