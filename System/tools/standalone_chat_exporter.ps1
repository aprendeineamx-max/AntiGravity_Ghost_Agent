Add-Type -AssemblyName System.Windows.Forms

$ExportDir = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\Exports"
$HistoryFile = Join-Path $ExportDir "Chat_Conversation.md"

if (!(Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

$KnownHashes = @{}
if (Test-Path $HistoryFile) {
    $content = Get-Content $HistoryFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $matches = [regex]::Matches($content, '### User Input\s+([\s\S]*?)(?=###|$)')
        foreach ($m in $matches) {
            $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($m.Value.Trim()))
            $hashString = [System.BitConverter]::ToString($hash).Replace('-','')
            $KnownHashes[$hashString] = $true
        }
        Write-Host "Cargados $($KnownHashes.Count) mensajes existentes" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " CHAT AUTO-EXPORT (STANDALONE)" -ForegroundColor Cyan  
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Activo - Monitoreando clipboard cada 10s" -ForegroundColor Green
Write-Host "Archivo: $HistoryFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Workflow: Ctrl+A -> Ctrl+C -> Listo!" -ForegroundColor White
Write-Host ""

$LastClipboard = ""

function Test-IsChat {
    param($text)
    if (!$text -or $text.Length -lt 100) { return $false }
    
    $score = 0
    $score += ([regex]::Matches($text, '(?m)^(USER|You|AGENT|AI)')).Count * 2
    $score += ([regex]::Matches($text, 'User uploaded image')).Count * 3
    $score += ([regex]::Matches($text, '(?m)^#{1,3}\s')).Count
    if ($text -match 'Progress Updates|Files Edited') { $score += 3 }
    
    return $score -ge 6
}

function Parse-Chat {
    param($text)
    
    $lines = $text -split "`n"
    $entries = @()
    $currentEntry = $null
    $currentRole = $null
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        if ($trimmed -match '^(USER|You)[\s:]') {
            if ($currentEntry) { $entries += $currentEntry }
            $cleaned = $trimmed -replace '^(USER|You)[\s:]+', ''
            $currentEntry = @{ role = 'user'; text = $cleaned }
            $currentRole = 'user'
        }
        elseif ($trimmed -match '^(AGENT|AI|Assistant)[\s:]') {
            if ($currentEntry) { $entries += $currentEntry }
            $cleaned = $trimmed -replace '^(AGENT|AI|Assistant)[\s:]+', ''
            $currentEntry = @{ role = 'agent'; text = $cleaned }
            $currentRole = 'agent'
        }
        elseif ($trimmed -and $currentEntry) {
            $currentEntry.text += "`n$trimmed"
        }
        elseif ($trimmed -and !$currentEntry) {
            $currentRole = if ($currentRole -eq 'user') { 'agent' } else { 'user' }
            $currentEntry = @{ role = $currentRole; text = $trimmed }
        }
    }
    
    if ($currentEntry) { $entries += $currentEntry }
    return $entries
}

function Export-ToFile {
    param($entries)
    
    $header = ""
    if (!(Test-Path $HistoryFile)) {
        $header = "# Chat Conversation`n`n"
        $header += "Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._`n`n"
    }
    
    $newContent = ""
    $addedCount = 0
    
    foreach ($entry in $entries) {
        $entryJson = $entry | ConvertTo-Json -Compress
        $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($entryJson))
        $hashString = [System.BitConverter]::ToString($hash).Replace('-','')
        
        if (!$KnownHashes.ContainsKey($hashString)) {
            if ($entry.role -eq 'user') {
                $newContent += "### User Input`n`n$($entry.text)`n`n"
            } else {
                $newContent += "$($entry.text)`n`n"
            }
            $KnownHashes[$hashString] = $true
            $addedCount++
        }
    }
    
    if ($addedCount -gt 0) {
        Add-Content -Path $HistoryFile -Value ($header + $newContent) -NoNewline
        return $addedCount
    }
    return 0
}

try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        try {
            $clipboard = [System.Windows.Forms.Clipboard]::GetText()
            
            if ($clipboard -and $clipboard -ne $LastClipboard -and $clipboard.Length -gt 100) {
                if (Test-IsChat $clipboard) {
                    $time = Get-Date -Format "HH:mm:ss"
                    Write-Host "[$time] Chat detectado ($($clipboard.Length) chars)" -ForegroundColor Yellow
                    
                    $entries = Parse-Chat $clipboard
                    $added = Export-ToFile $entries
                    
                    if ($added -gt 0) {
                        Write-Host "[$time] Exportados $added nuevos mensajes (total: $($entries.Count))" -ForegroundColor Green
                    } else {
                        Write-Host "[$time] Sin mensajes nuevos (total: $($entries.Count))" -ForegroundColor Gray
                    }
                }
                $LastClipboard = $clipboard
            }
        }
        catch {
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Detenido" -ForegroundColor Yellow
}
