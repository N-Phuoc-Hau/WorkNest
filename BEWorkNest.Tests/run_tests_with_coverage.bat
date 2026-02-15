@echo off
REM Script để chạy tests và generate coverage report cho WorkNest Backend

echo ===================================
echo WorkNest Backend - Test Runner
echo ===================================
echo.

cd /d "%~dp0"

echo [1/5] Building solution...
dotnet build ../BEWorkNest/BEWorkNest.csproj --configuration Release
if %ERRORLEVEL% NEQ 0 (
    echo Error: Build failed!
    pause
    exit /b 1
)
echo Build successful!
echo.

echo [2/5] Running all tests...
dotnet test --configuration Release --logger "console;verbosity=normal"
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Some tests failed! Check output above.
)
echo.

echo [3/5] Collecting code coverage...
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput=./coverage/
echo.

echo [4/5] Installing report generator (if not installed)...
dotnet tool install -g dotnet-reportgenerator-globaltool --ignore-failed-sources
echo.

echo [5/5] Generating HTML coverage report...
reportgenerator -reports:coverage/coverage.cobertura.xml -targetdir:coveragereport -reporttypes:Html
echo.

echo ===================================
echo Test Results Summary
echo ===================================
echo Coverage report generated at: %~dp0coveragereport\index.html
echo.

echo Opening coverage report in browser...
start coveragereport\index.html

echo.
echo ===================================
echo Done! Check the browser for coverage report.
echo ===================================
pause
