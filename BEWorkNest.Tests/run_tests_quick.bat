@echo off
REM Quick test runner - Chỉ chạy tests, không generate report

echo Running tests...
cd /d "%~dp0"

dotnet test --logger "console;verbosity=normal" --configuration Release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================
    echo All tests passed! ✓
    echo ===================================
) else (
    echo.
    echo ===================================
    echo Some tests failed! ✗
    echo ===================================
)

pause
