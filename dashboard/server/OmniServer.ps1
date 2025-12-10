$port = 1337
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
}
catch {
    Write-Warning "Port $port is busy. Is the server already running?"
    exit
}

Write-Host "🛸 OmniServer listening on http://localhost:$port" -ForegroundColor Cyan

# Fix: Use PSScriptRoot to find public folder reliably
$wwwRoot = Join-Path $PSScriptRoot "..\public"

# Global state for Ghost Agent (Logic Flag)
$global:GhostActive = $true

Function Get-ProcessStatus {
    $status = @{
        "OmniGod"     = (Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue).Count -gt 0
        "OmniControl" = (Get-Process "powershell" | Where-Object { $_.MainWindowTitle -like "*OmniControl*" } | Measure-Object).Count -gt 0
        "Ghost"       = $global:GhostActive
    }
    return $status | ConvertTo-Json
}

while ($listener.IsListening) {
    # ... (Keep existing loop setup) ...
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $path = $request.Url.LocalPath
    $method = $request.HttpMethod
    
    if ($path -ne "/api/status") {
        Write-Host "[$method] $path" -ForegroundColor DarkGray
    }

    try {
        if ($path -eq "/api/status") {
            $json = Get-ProcessStatus
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -match "/api/toggle/(?<bot>\w+)") {
            $bot = $Matches['bot']
            $msg = "No Action"

            if ($bot -eq "omnigod") {
                $ahkProc = Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue
                if ($ahkProc) {
                    $ahkProc | Stop-Process -Force
                    $msg = "[STOPPED] OmniGod"
                } else {
                    $scriptPath = Join-Path $PSScriptRoot "..\..\OmniBot\OmniGod.ahk"
                    Start-Process "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" -ArgumentList "`"$scriptPath`"" -WorkingDirectory (Split-Path $scriptPath)
                    if (!$?) { Start-Process $scriptPath } 
                    $msg = "[STARTED] OmniGod"
                }
            }
            elseif ($bot -eq "omnicontrol") {
                $psProc = Get-Process "powershell" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*OmniControl*" }
                if ($psProc) {
                    $psProc | Stop-Process -Force
                    $msg = "[STOPPED] OmniControl"
                } else {
                    $scriptPath = Join-Path $PSScriptRoot "..\..\tools\OmniControl_HUD.ps1"
                    Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
                    $msg = "[STARTED] OmniControl"
                }
            }
            elseif ($bot -eq "ghost") {
                $global:GhostActive = -not $global:GhostActive
                if ($global:GhostActive) { $msg = "[ENABLED] Ghost Agent" }
                else { $msg = "[DISABLED] Ghost Agent" }
            }

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            # Serve Static Files
            if ($path -eq "/") { $path = "/index.html" }
            $filePath = Join-Path $wwwRoot $path.TrimStart("/")
            
            if (Test-Path $filePath) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $content.Length
                if ($filePath.EndsWith(".css")) { $response.ContentType = "text/css" }
                elseif ($filePath.EndsWith(".js")) { $response.ContentType = "text/javascript" }
                else { $response.ContentType = "text/html" }
                $response.OutputStream.Write($content, 0, $content.Length)
            }
            else {
                $response.StatusCode = 404
            }
        }
    }
    catch {
        $response.StatusCode = 500
        Write-Host "Error: $_" -ForegroundColor Red
    }
    finally {
        $response.Close()
    }
}
