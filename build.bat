@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "BUILD_DIR=%SCRIPT_DIR%\build-win"
set "GENERATOR=Visual Studio 16 2019"

cmake -S "%SCRIPT_DIR%" -B "%BUILD_DIR%" -G "%GENERATOR%" -A x64
if errorlevel 1 exit /b %errorlevel%

cmake --build "%BUILD_DIR%" --config Release --target redis.hdll
if errorlevel 1 exit /b %errorlevel%

echo.
echo Built redis.hdll in:
echo   %BUILD_DIR%bin
