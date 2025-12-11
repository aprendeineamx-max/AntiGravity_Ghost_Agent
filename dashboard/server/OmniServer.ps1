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

# Global state
$global:GhostActive = $true
$global:OmniGodPaused = $false
$global:AgentWorking = $false

Function Get-ProcessStatus {
    $ahkRunning = (Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue).Count -gt 0
    $status = @{
        "OmniGod"     = $ahkRunning -and (-not $global:OmniGodPaused)
        "OmniControl" = (Get-Process "powershell" | Where-Object { $_.MainWindowTitle -like "*OmniControl*" } | Measure-Object).Count -gt 0
        "Ghost"       = $global:GhostActive
    }
    return $status | ConvertTo-Json
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $path = $request.Url.LocalPath
    $method = $request.HttpMethod
    
    if ($path -ne "/api/status") {
        Write-Host "[$method] $path" -ForegroundColor DarkGray
    }
    
    # --- CORS HEADERS (Fix for Fetch Blocking) ---
    $response.AddHeader("Access-Control-Allow-Origin", "*")
    $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $response.AddHeader("Access-Control-Allow-Headers", "Content-Type")
    
    if ($method -eq "OPTIONS") {
        $response.StatusCode = 204
        $response.Close()
        continue
    }

    try {
        if ($path -eq "/api/status") {
            $json = Get-ProcessStatus
            # Inject AgentWorking state from Ghost
            $statusObj = $json | ConvertFrom-Json
            $statusObj | Add-Member -NotePropertyName "AgentWorking" -NotePropertyValue ($global:AgentWorking -eq $true)
            $newJson = $statusObj | ConvertTo-Json
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($newJson)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/report_state") {
            if ($method -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                try {
                    $data = $body | ConvertFrom-Json
                    $global:AgentWorking = $data.working
                }
                catch { $global:AgentWorking = $false }
                
                $msg = "OK"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/api/log_chat") {
            if ($method -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()

                $logPath = Join-Path $PSScriptRoot "..\..\Antigravity_ChatLog.txt"
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $separator = "_______________________________"
                
                $logEntry = "[$timestamp]`n$body`n$separator`n"
                
                Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
                
                $msg = "Logged"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/api/toggle_ghost") {
            if ($method -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                try {
                    $data = $body | ConvertFrom-Json
                    # F8 sends Active: True/False
                    # If F8 says Active (True), then Paused is False.
                    # If F8 says Inactive (False), then Paused is True.
                    $global:OmniGodPaused = -not $data.active
                    
                    $statusStr = if (-not $global:OmniGodPaused) { "ACTIVE" } else { "PAUSED" }
                    Write-Host "🔄 OmniGod Status Sync (F8): $statusStr" -ForegroundColor Yellow
                }
                catch { 
                    Write-Warning "Invalid JSON in toggle request" 
                }
                
                $msg = "OK"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -match "/api/toggle/(?<bot>\w+)") {
            $bot = $Matches['bot']
            $msg = "No Action"

            if ($bot -eq "omnigod") {
                # UI Button Logic: Toggle Pause State instead of Killing Process
                $global:OmniGodPaused = -not $global:OmniGodPaused
                
                if ($global:OmniGodPaused) { 
                    $msg = "[PAUSED] OmniGod" 
                }
                else { 
                    $msg = "[RESUMED] OmniGod" 
                    # Optional: Ensure process is running if it crashed?
                    $ahkProc = Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue
                    if (-not $ahkProc) {
                        $scriptPath = Join-Path $PSScriptRoot "..\..\OmniBot\OmniGod.ahk"
                        Start-Process "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" -ArgumentList "`"$scriptPath`"" -WorkingDirectory (Split-Path $scriptPath)
                        $msg = "[STARTED] OmniGod"
                    }
                }
            }
            elseif ($bot -eq "omnicontrol") {
                $psProc = Get-Process "powershell" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*OmniControl*" }
                if ($psProc) {
                    $psProc | Stop-Process -Force
                    $msg = "[STOPPED] OmniControl"
                }
                else {
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
        $response.Close() # Ensure close on error
    }
    finally {
        try { $response.Close() } catch {}
    }
}
