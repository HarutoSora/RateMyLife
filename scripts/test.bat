@echo off
setlocal

cd /d "%~dp0\.."

echo [test] flutter test
call flutter test
if errorlevel 1 (
    echo [test] One or more tests failed.
    exit /b 1
)

echo [test] All tests passed.
endlocal
