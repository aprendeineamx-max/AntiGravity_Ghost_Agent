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

Function Get-ProcessStatus {
    $status = @{
        "OmniGod"     = (Get-Process "AutoHotkey" -ErrorAction SilentlyContinue).Count -gt 0
        "OmniControl" = (Get-Process "powershell" | Where-Object { $_.MainWindowTitle -like "*OmniControl*" } | Measure-Object).Count -gt 0
    }
    return $status | ConvertTo-Json
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $path = $request.Url.LocalPath
    $method = $request.HttpMethod

    Write-Host "[$method] $path" -ForegroundColor DarkGray

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
            # Logic to start/kill bots would go here
            # For now just mock response
            $msg = "Toggled $bot"
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
