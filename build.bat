@echo off
setlocal

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..\..") do set ROOT_DIR=%%~fI
set BUILD_DIR=%SCRIPT_DIR%build-win

cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" -G "Visual Studio 17 2022" -A x64 ^
  -DWITH_VM=OFF ^
  -DWITH_HLREDIS=ON ^
  -DDOWNLOAD_DEPENDENCIES=ON ^
  -DWITH_FMT=OFF ^
  -DWITH_OPENAL=OFF ^
  -DWITH_SDL=OFF ^
  -DWITH_SQLITE=OFF ^
  -DWITH_SSL=OFF ^
  -DWITH_UI=OFF ^
  -DWITH_UV=OFF ^
  -DWITH_VIDEO=OFF ^
  -DWITH_HEAPS=OFF
if errorlevel 1 exit /b %errorlevel%

cmake --build "%BUILD_DIR%" --config Release --target redis.hdll
if errorlevel 1 exit /b %errorlevel%

echo.
echo Built redis.hdll in:
echo   %BUILD_DIR%bin
