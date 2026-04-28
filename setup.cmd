@echo off
REM ============================================================================
REM Copilot Router - Automatic Dependency Setup (Wrapper)
REM ============================================================================
REM This file runs setup.ps1 and keeps the window open

title Copilot Router Setup

REM Run PowerShell with -NoExit to keep the window open
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERR] Node.js is not installed.
    echo       Download: https://nodejs.org/
    echo.
    pause
    exit /b 1
)

npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERR] npm is not installed.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i

echo [OK] Node.js %NODE_VERSION%
echo [OK] npm %NPM_VERSION%

REM ============================================================================
REM 2. INSTALL GLOBAL DEPENDENCIES
REM ============================================================================
echo.
echo [2/3] Installing global dependencies...

REM Copilot
set COPILOT_PATH=%APPDATA%\npm\node_modules\@github\copilot\npm-loader.js
if exist "%COPILOT_PATH%" (
    echo [OK] @github/copilot is already installed
) else (
    echo      ^> Installing @github/copilot...
    call npm install -g @github/copilot --force
    if %errorlevel% neq 0 (
        echo [ERR] Error installing @github/copilot
        pause
        exit /b 1
    )
    echo [OK] @github/copilot installed successfully
)

REM Bun
set BUN_PATH=%APPDATA%\npm\bun.cmd
if exist "%BUN_PATH%" (
    for /f "tokens=*" %%i in ('bun --version') do set BUN_VERSION=%%i
    echo [OK] bun (!BUN_VERSION!) is already installed
) else (
    echo      ^> Installing bun...
    call npm install -g bun
    if %errorlevel% neq 0 (
        echo [ERR] Error installing bun
        pause
        exit /b 1
    )
    for /f "tokens=*" %%i in ('bun --version') do set BUN_VERSION=%%i
    echo [OK] bun (!BUN_VERSION!) installed successfully
)

REM ============================================================================
REM 3. FINAL VALIDATION
REM ============================================================================
echo.
echo [3/3] Validating installation...

set ALL_GOOD=1

if not exist "%COPILOT_PATH%" (
    echo [ERR] @github/copilot was not found
    set ALL_GOOD=0
) else (
    echo [OK] @github/copilot found
)

if not exist "%BUN_PATH%" (
    echo [ERR] bun was not found
    set ALL_GOOD=0
) else (
    echo [OK] bun found
)

echo.

if %ALL_GOOD% equ 1 (
    echo ====================================================================
    echo.  [OK] Setup completed successfully!
    echo.
    echo.  Next steps:
    echo.    1. Run: .\router.ps1 up
    echo.    2. Use: Your preferred AI tool
    echo.
    echo ====================================================================
    echo.
    pause
    exit /b 0
) else (
    echo ====================================================================
    echo.  [ERR] Setup was not completed successfully!
    echo.      Please check the errors above
    echo.
    echo ====================================================================
    echo.
    pause
    exit /b 1
)
