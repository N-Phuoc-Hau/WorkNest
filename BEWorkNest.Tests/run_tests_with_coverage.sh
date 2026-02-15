#!/bin/bash

# Script để chạy tests và generate coverage report cho WorkNest Backend

echo "==================================="
echo "WorkNest Backend - Test Runner"
echo "==================================="
echo ""

cd "$(dirname "$0")"

echo "[1/5] Building solution..."
dotnet build ../BEWorkNest/BEWorkNest.csproj --configuration Release
if [ $? -ne 0 ]; then
    echo "Error: Build failed!"
    exit 1
fi
echo "Build successful!"
echo ""

echo "[2/5] Running all tests..."
dotnet test --configuration Release --logger "console;verbosity=normal"
if [ $? -ne 0 ]; then
    echo "Warning: Some tests failed! Check output above."
fi
echo ""

echo "[3/5] Collecting code coverage..."
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput=./coverage/
echo ""

echo "[4/5] Installing report generator (if not installed)..."
dotnet tool install -g dotnet-reportgenerator-globaltool --ignore-failed-sources
echo ""

echo "[5/5] Generating HTML coverage report..."
reportgenerator -reports:coverage/coverage.cobertura.xml -targetdir:coveragereport -reporttypes:Html
echo ""

echo "==================================="
echo "Test Results Summary"
echo "==================================="
echo "Coverage report generated at: $(pwd)/coveragereport/index.html"
echo ""

# Try to open in default browser (works on most Linux systems)
if command -v xdg-open > /dev/null; then
    echo "Opening coverage report in browser..."
    xdg-open coveragereport/index.html
elif command -v open > /dev/null; then
    # macOS
    echo "Opening coverage report in browser..."
    open coveragereport/index.html
fi

echo ""
echo "==================================="
echo "Done! Check the browser for coverage report."
echo "==================================="
