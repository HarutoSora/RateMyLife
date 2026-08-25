@echo off
setlocal

cd /d "%~dp0\.."

echo [build-release] flutter pub get
call flutter pub get
if errorlevel 1 (
    echo [build-release] flutter pub get failed.
    exit /b 1
)

echo [build-release] flutter analyze
call flutter analyze
if errorlevel 1 (
    echo [build-release] Analyzer found issues. Fix them before building a release.
    exit /b 1
)

echo [build-release] flutter build apk --release
call flutter build apk --release
if errorlevel 1 (
    echo [build-release] Build failed.
    exit /b 1
)

echo [build-release] Release APK built successfully.
echo [build-release] Output: build\app\outputs\flutter-apk\app-release.apk
endlocal
