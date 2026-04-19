param([switch]$Force = $false)

$Host.UI.RawUI.WindowTitle = "Copilot Router Setup"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "         Copilot Router - Dependency Setup" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Validating prerequisites..." -ForegroundColor Yellow

if (-Not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js is not installed" -ForegroundColor Red
    Write-Host "Download: https://nodejs.org/" -ForegroundColor Gray
    Read-Host "Press ENTER to close"
    exit 1
}

if (-Not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: npm is not installed" -ForegroundColor Red
    Read-Host "Press ENTER to close"
    exit 1
}

$nodeVersion = node --version
$npmVersion = npm --version
Write-Host "OK: Node.js $nodeVersion" -ForegroundColor Green
Write-Host "OK: npm $npmVersion" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Installing global dependencies..." -ForegroundColor Yellow

$copilotPath = "$env:APPDATA\npm\node_modules\@github\copilot\npm-loader.js"
if ((Test-Path $copilotPath) -and -not $Force) {
    Write-Host "OK: @github/copilot is already installed" -ForegroundColor Green
} else {
    Write-Host "  -> Installing @github/copilot..." -ForegroundColor Gray
    npm install -g @github/copilot --force 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: @github/copilot installed" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to install @github/copilot" -ForegroundColor Red
        Read-Host "Press ENTER to close"
        exit 1
    }
}

$bunCmd = "$env:APPDATA\npm\bun.cmd"
if ((Test-Path $bunCmd) -and -not $Force) {
    $bunVersion = & bun --version 2>&1
    Write-Host "OK: bun ($bunVersion) is already installed" -ForegroundColor Green
} else {
    Write-Host "  -> Installing bun..." -ForegroundColor Gray
    npm install -g bun 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $bunVersion = & bun --version 2>&1
        Write-Host "OK: bun ($bunVersion) installed" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to install bun" -ForegroundColor Red
        Read-Host "Press ENTER to close"
        exit 1
    }
}

Write-Host ""
Write-Host "[3/3] Validating installation..." -ForegroundColor Yellow

$allGood = $true

if (-Not (Test-Path $copilotPath)) {
    Write-Host "ERROR: @github/copilot was not found" -ForegroundColor Red
    $allGood = $false
} else {
    Write-Host "OK: @github/copilot found" -ForegroundColor Green
}

if (-Not (Test-Path $bunCmd)) {
    Write-Host "ERROR: bun was not found" -ForegroundColor Red
    $allGood = $false
} else {
    Write-Host "OK: bun found" -ForegroundColor Green
}

Write-Host ""

if ($allGood) {
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS: Setup completed!" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "  Next steps:" -ForegroundColor Green
    Write-Host "  1. Run: .\router.ps1 up" -ForegroundColor Green
    Write-Host "  2. Use: Your preferred AI tool" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press ENTER to close"
    exit 0
} else {
    Write-Host "=========================================================" -ForegroundColor Red
    Write-Host "  ERROR: Setup was not completed" -ForegroundColor Red
    Write-Host "  Check the errors above" -ForegroundColor Red
    Write-Host "=========================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press ENTER to close"
    exit 1
}
