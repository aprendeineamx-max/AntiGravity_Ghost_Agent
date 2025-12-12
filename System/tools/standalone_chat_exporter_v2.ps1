# Chat Exporter V2 - Production
# Auto-monitors clipboard and exports chat with v2 format

Add-Type -AssemblyName System.Windows.Forms

$ExportDir = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\Exports"
$HistoryFile = Join-Path $ExportDir "Chat_Conversation.md"

if (!(Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

function Get-Hash {
    param($text)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hash = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text.Trim()))
    return [BitConverter]::ToString($hash).Replace('-','')
}

function Test-Chat {
    param($text)
    if (!$text -or $text.Length -lt 100) { return $false }
    
    $score = 0
    $score += ([regex]::Matches($text, '(?m)^(USER|AGENT|AI|You)')).Count * 2
    $score += ([regex]::Matches($text, 'uploaded image')).Count * 3
    $score += ([regex]::Matches($text, '(?m)^#{1,3}\s')).Count
    $score += ([regex]::Matches($text, 'Thought for')).Count * 2
    $score += ([regex]::Matches($text, 'Progress Updates|Files Edited')).Count * 2
    
    return $score -ge 6
}

function Parse-Messages {
    param($text)
    
    $lines = $text -split "`n"
    $messages = @()
    $current = $null
    $inCode = $false
    $code = ""
    
    foreach ($line in $lines) {
        if ($line -match '^```') {
            if (!$inCode) {
                $inCode = $true
                $code = "$line`n"
            } else {
                $inCode = $false
                $code += $line
                if ($current) {
                    $current.content += "`n$code"
                }
                $code = ""
            }
            continue
        }
        
        if ($inCode) {
            $code += "$line`n"
            continue
        }
        
        $t = $line.Trim()
        
        if ($t -match '^(USER|You):(.*)') {
            if ($current) { $messages += $current }
            $current = @{from='user'; type='text'; content=$matches[2].Trim(); time=(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")}
        }
        elseif ($t -match '^(AGENT|AI|Assistant):(.*)') {
            if ($current) { $messages += $current }
            $current = @{from='agent'; type='text'; content=$matches[2].Trim(); time=(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")}
        }
        elseif ($t -match 'Thought for') {
            if ($current) { $messages += $current }
            $current = @{from='agent'; type='thought'; content=$t; time=(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")}
        }
        elseif ($t -match 'User uploaded image (\d+)') {
            if ($current) {
                $current.type = 'text+image'
                $current.content += "`n`n![Image](attachments/image_$($matches[1]).png)"
            }
        }
        elseif ($t -and $current) {
            $current.content += "`n$t"
        }
    }
    
    if ($current) { $messages += $current }
    return $messages
}

function Export-Messages {
    param($msgs, $hashes)
    
    $output = ""
    $new = 0
    $num = $hashes.Count + 1
    
    if (!(Test-Path $HistoryFile)) {
        $output = "# Chat Conversation Export`n`n"
        $output += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $output += "**Source**: AntiGravity IDE - Chat Exporter V2`n`n"
        $output += "---`n`n"
    }
    
    foreach ($m in $msgs) {
        $h = Get-Hash $m.content
        if (!$hashes.ContainsKey($h)) {
            $fromText = if ($m.from -eq 'user') { 'User' } else { 'Agent' }
            
            $output += "## Message $($num.ToString('000'))`n"
            $output += "**From**: $fromText`n"
            $output += "**Time**: $($m.time)`n"
            $output += "**Type**: $($m.type)`n`n"
            $output += "$($m.content)`n`n"
            $output += "---`n`n"
            
            $hashes[$h] = $true
            $num++
            $new++
        }
    }
    
    if ($new -gt 0) {
        Add-Content -Path $HistoryFile -Value $output
    }
    
    return $new
}

# Load existing hashes
$KnownHashes = @{}
if (Test-Path $HistoryFile) {
    $content = Get-Content $HistoryFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $msgBlocks = [regex]::Matches($content, '## Message \d+')
        foreach ($m in $msgBlocks) {
            $KnownHashes["msg_$($m.Value)"] = $true
        }
        Write-Host "Loaded $($KnownHashes.Count) existing messages" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  CHAT AUTO-EXPORT V2 (PRODUCTION)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status: Active - Monitoring every 10s" -ForegroundColor Green
Write-Host "Output: $HistoryFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Features:" -ForegroundColor Cyan
Write-Host "  - Code block preservation" -ForegroundColor White
Write-Host "  - Message structure (From/Time/Type)" -ForegroundColor White
Write-Host "  - MD5 deduplication" -ForegroundColor White
Write-Host ""
Write-Host "Workflow: Ctrl+A -> Ctrl+C" -ForegroundColor White
Write-Host ""

$LastClip = ""

try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        try {
            $clip = [System.Windows.Forms.Clipboard]::GetText()
            
            if ($clip -and $clip -ne $LastClip -and $clip.Length -gt 100) {
                if (Test-Chat $clip) {
                    $time = Get-Date -Format "HH:mm:ss"
                    Write-Host "[$time] Chat detected ($($clip.Length) chars)..." -ForegroundColor Yellow
                    
                    $msgs = Parse-Messages $clip
                    $added = Export-Messages -msgs $msgs -hashes $KnownHashes
                    
                    if ($added -gt 0) {
                        Write-Host "[$time] SUCCESS: $added new messages (total: $($msgs.Count))" -ForegroundColor Green
                    } else {
                        Write-Host "[$time] No new messages (total: $($msgs.Count))" -ForegroundColor Gray
                    }
                }
                $LastClip = $clip
            }
        }
        catch {
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Stopped" -ForegroundColor Yellow
}
