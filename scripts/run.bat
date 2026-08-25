@echo off
setlocal

cd /d "%~dp0\.."

echo [run] flutter pub get
call flutter pub get
if errorlevel 1 (
    echo [run] flutter pub get failed.
    exit /b 1
)

echo [run] flutter run
call flutter run
if errorlevel 1 (
    echo [run] flutter run failed. Is a device or emulator connected? Run "flutter devices" to check.
    exit /b 1
)

endlocal
