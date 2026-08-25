@echo off
setlocal

cd /d "%~dp0\.."

echo [analyze] flutter analyze
call flutter analyze
if errorlevel 1 (
    echo [analyze] Issues found above.
    exit /b 1
)

echo [analyze] No issues found.
endlocal
