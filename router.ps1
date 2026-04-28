param(
    [string]$Action
)

$Host.UI.RawUI.WindowTitle = "Copilot Router Engine"
$LogPath = "router-engine.log"

function Show-Help {
    Write-Host ""
    Write-Host " [Copilot Router Engine - CLI]" -ForegroundColor Cyan
    Write-Host " ========================================================="
    Write-Host " Command      Action" -ForegroundColor Yellow
    Write-Host " up           Starts the Hub in background silently"
    Write-Host " down         Kills the Hub service and closes ports"
    Write-Host " logs         Displays engine log in real-time (streaming)"
    Write-Host " status       Checks if port 3099 is online and active"
    Write-Host " ========================================================="
    Write-Host ""
}

switch ($Action) {
    "up" {
        $portCheck = Get-NetTCPConnection -LocalPort 3099 -ErrorAction SilentlyContinue
        if ($portCheck) {
            Write-Host "[!] Port 3099 is already in use. Please cancel with '.\router.ps1 down' first." -ForegroundColor Red
            return
        }

        Write-Host "[>] Igniting the engines (Bun Native)..." -ForegroundColor DarkGray
        
        if (-Not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType File -Force | Out-Null }
        Clear-Content $LogPath

        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "$env:APPDATA\npm\bun.cmd"
        $ProcessInfo.Arguments = "run src/router.ts"
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.RedirectStandardError = $true
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.CreateNoWindow = $true
        $ProcessInfo.WorkingDirectory = $PWD

        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo
        
        $Process.EnableRaisingEvents = $true
        Register-ObjectEvent -InputObject $Process -EventName "OutputDataReceived" -Action {
            Add-Content -Path "router-engine.log" -Value $Event.SourceEventArgs.Data
        } | Out-Null
        Register-ObjectEvent -InputObject $Process -EventName "ErrorDataReceived" -Action {
            Add-Content -Path "router-engine.log" -Value $Event.SourceEventArgs.Data
        } | Out-Null

        $Process.Start() | Out-Null
        $Process.BeginOutputReadLine()
        $Process.BeginErrorReadLine()

        Set-Content -Path ".router.pid" -Value $Process.Id

        Start-Sleep -Seconds 1
        Write-Host "[OK] Copilot Router running in Background (PID: $($Process.Id))." -ForegroundColor Green
        Write-Host "     Port 3099 is now yours and the local Cloud is online." -ForegroundColor Green
        Write-Host "     Use '.\router.ps1 logs' to monitor traffic." -ForegroundColor Gray
    }

    "down" {
        if (Test-Path ".router.pid") {
            $PIDToKill = Get-Content ".router.pid"
            Write-Host "[>] Tearing down local Hub service (PID: $PIDToKill)..." -ForegroundColor Yellow
            Stop-Process -Id $PIDToKill -Force -ErrorAction SilentlyContinue
            Remove-Item ".router.pid" -Force
            Write-Host "[OK] Server offline. Ports released." -ForegroundColor Green
        } else {
            $ports = Get-NetTCPConnection -LocalPort 3099 -ErrorAction SilentlyContinue
            if ($ports) {
                Write-Host "[!] Force killing processes on port 3099..." -ForegroundColor Yellow
                foreach ($p in $ports) { Stop-Process -Id $p.OwningProcess -Force -ErrorAction SilentlyContinue }
            }
            Write-Host "[OK] The system is already clean/offline." -ForegroundColor Green
        }
    }

    "logs" {
        if (-Not (Test-Path $LogPath)) {
            Write-Host "[!] Log not found. Did the engine start?" -ForegroundColor Red
            return
        }
        Write-Host "--- Tailing: $LogPath (Ctrl+C to exit) ---" -ForegroundColor Cyan
        Get-Content $LogPath -Wait -Tail 20
    }

    "status" {
        $portCheck = Get-NetTCPConnection -LocalPort 3099 -ErrorAction SilentlyContinue
        if ($portCheck) {
            $PIDNumber = if (Test-Path ".router.pid") { Get-Content ".router.pid" } else { $portCheck.OwningProcess }
            Write-Host "[ONLINE] Bun engine running fast. (PID: $PIDNumber)" -ForegroundColor Green
        } else {
            Write-Host "[OFFLINE] Engine disconnected or service down." -ForegroundColor Red
        }
    }

    default {
        Show-Help
    }
}
