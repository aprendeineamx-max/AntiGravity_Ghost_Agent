# ========================================
# Chat Exporter V2 - Self-Testing Version
# ========================================

Add-Type -AssemblyName System.Windows.Forms

$ExportDir = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\Exports"
$HistoryFile = Join-Path $ExportDir "Chat_Conversation.md"
$TestFile = Join-Path $ExportDir "test_chat_input.txt"

if (!(Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

# ========================================
# CORE FUNCTIONS
# ========================================

function Get-ContentHash {
    param([string]$text)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text.Trim())
    $hash = $md5.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace('-','')
}

function Test-IsChat {
    param($text)
    if (!$text -or $text.Length -lt 50) { return $false }
    
    $score = 0
    $score += ([regex]::Matches($text, '(?m)^(USER|You|AGENT|AI|Assistant)')).Count * 2
    $score += ([regex]::Matches($text, 'User uploaded image')).Count * 3
    $score += ([regex]::Matches($text, '(?m)^#{1,3}\s')).Count
    $score += ([regex]::Matches($text, 'Thought for \d+s')).Count * 2
    $score += ([regex]::Matches($text, 'Progress Updates|Files Edited')).Count * 3
    
    return $score -ge 4  # Lower threshold for testing
}

function Parse-ChatMessages {
    param([string]$rawText)
    
    $lines = $rawText -split "`n"
    $messages = @()
    $currentMessage = $null
    $inCodeBlock = $false
    $codeBlockContent = ""
    
    foreach ($line in $lines) {
        # Code block detection
        if ($line -match '^```') {
            if (!$inCodeBlock) {
                $inCodeBlock = $true
                $codeBlockContent = "$line`n"
            } else {
                $inCodeBlock = $false
                $codeBlockContent += $line
                if ($currentMessage) {
                    $currentMessage.content += "`n$codeBlockContent"
                }
                $codeBlockContent = ""
            }
            continue
        }
        
        if ($inCodeBlock) {
            $codeBlockContent += "$line`n"
            continue
        }
        
        $trimmed = $line.Trim()
        
        # Role detection
        if ($trimmed -match '^(USER|You):(.*)') {
            if ($currentMessage) { $messages += $currentMessage }
            $currentMessage = @{
                from = 'user'
                type = 'text'
                content = $matches[2].Trim()
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
        }
        elseif ($trimmed -match '^(AGENT|AI|Assistant):(.*)') {
            if ($currentMessage) { $messages += $currentMessage }
            $currentMessage = @{
                from = 'agent'
                type = 'text'
                content = $matches[2].Trim()
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
        }
        elseif ($trimmed -match 'Thought for (\d+)s') {
            if ($currentMessage) { $messages += $currentMessage }
            $currentMessage = @{
                from = 'agent'
                type = 'thought'
                content = $trimmed
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
        }
        elseif ($trimmed -match 'User uploaded image (\d+)') {
            if ($currentMessage) {
                $currentMessage.type = 'text+image'
                $currentMessage.content += "`n`n![Image $($matches[1])](attachments/image_$($matches[1]).png)"
            }
        }
        elseif ($trimmed -and $currentMessage) {
            $currentMessage.content += "`n$trimmed"
        }
    }
    
    if ($currentMessage) { $messages += $currentMessage }
    return $messages
}

function Export-ToMarkdown {
    param($messages, [hashtable]$knownHashes)
    
    $newCount = 0
    $output = ""
    
    if (!(Test-Path $HistoryFile)) {
        $output = "# Chat Conversation Export`n`n"
        $output += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $output += "**Source**: Chat Exporter V2`n`n"
        $output += "---`n`n"
    }
    
    $startNum = $knownHashes.Count + 1
    
    foreach ($message in $messages) {
        $hash = Get-ContentHash $message.content
        
        if (!$knownHashes.ContainsKey($hash)) {
            $num = $startNum + $newCount
            
            $output += "## Message $($num.ToString('000'))`n"
            $output += "**From**: $($message.from -eq 'user' ? 'User' : 'Agent')`n"
            $output += "**Time**: $($message.timestamp)`n"
            $output += "**Type**: $($message.type)`n`n"
            $output += "$($message.content)`n`n"
            $output += "---`n`n"
            
            $knownHashes[$hash] = $true
            $newCount++
        }
    }
    
    if ($newCount -gt 0) {
        Add-Content -Path $HistoryFile -Value $output
    }
    
    return $newCount
}

# ========================================
# SELF-TEST MODE
# ========================================

function Run-SelfTest {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Magenta
    Write-Host " RUNNING SELF-TEST" -ForegroundColor Magenta
    Write-Host "=====================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Test 1: Create sample chat
    Write-Host"[TEST 1] Creating sample chat input..." -ForegroundColor Yellow
    
    $sampleChat = @"
USER: Hola, necesito ayuda con un script de PowerShell

AGENT: Claro, con gusto te ayudo. ¿Qué necesitas hacer?

USER: Quiero crear un script que exporte chat. Aquí está mi código:

``````powershell
Get-Process | Where-Object { `$_.Name -eq 'chrome' }
``````

AGENT: Perfecto, veo tu código. Te sugiero agregar:

``````powershell
Get-Process | Where-Object { `$_.Name -eq 'chrome' } | Select-Object Id, Name
``````

USER: Excelente! Funcionó. User uploaded image 1

AGENT: Me alegra que funcionó! Aquí hay más detalles...
"@
    
    Set-Content -Path $TestFile -Value $sampleChat
    Write-Host "   Sample created: $TestFile" -ForegroundColor Green
    
    # Test 2: Detect as chat
    Write-Host ""
    Write-Host "[TEST 2] Testing chat detection..." -ForegroundColor Yellow
    $isChat = Test-IsChat $sampleChat
    if ($isChat) {
        Write-Host "   PASS: Detected as chat content" -ForegroundColor Green
    } else {
        Write-Host "   FAIL: Not detected as chat" -ForegroundColor Red
        return $false
    }
    
    # Test 3: Parse messages
    Write-Host ""
    Write-Host "[TEST 3] Parsing messages..." -ForegroundColor Yellow
    $messages = Parse-ChatMessages $sampleChat
    Write-Host "   Parsed $($messages.Count) messages" -ForegroundColor Green
    
    foreach ($msg in $messages) {
        Write-Host "   - $($msg.from): $($msg.type) ($($msg.content.Length) chars)" -ForegroundColor Gray
    }
    
    # Test 4: Export to file
    Write-Host ""
    Write-Host "[TEST 4] Exporting to Markdown..." -ForegroundColor Yellow
    $hashes = @{}
    $exported = Export-ToMarkdown -messages $messages -knownHashes $hashes
    Write-Host "   Exported $exported messages to:" -ForegroundColor Green
    Write-Host "   $HistoryFile" -ForegroundColor Cyan
    
    # Test 5: Verify file
    Write-Host ""
    Write-Host "[TEST 5] Verifying export file..." -ForegroundColor Yellow
    if (Test-Path $HistoryFile) {
        $content = Get-Content $HistoryFile -Raw
        $hasMessages = $content -match '## Message \d+'
        $hasCodeBlocks = $content -match '```powershell'
        $hasMetadata = $content -match '\*\*From\*\*:'
        
        Write-Host "   File exists: YES" -ForegroundColor Green
        Write-Host "   Has messages: $(if($hasMessages){'YES'}else{'NO'})" -ForegroundColor $(if($hasMessages){'Green'}else{'Red'})
        Write-Host "   Has code blocks: $(if($hasCodeBlocks){'YES'}else{'NO'})" -ForegroundColor $(if($hasCodeBlocks){'Green'}else{'Red'})
        Write-Host "   Has metadata: $(if($hasMetadata){'YES'}else{'NO'})" -ForegroundColor $(if($hasMetadata){'Green'}else{'Red'})
        
        # Show first 500 chars
        Write-Host ""
        Write-Host "   Preview (first 500 chars):" -ForegroundColor Cyan
        Write-Host "   $($content.Substring(0, [Math]::Min(500, $content.Length)))" -ForegroundColor White
        
        return ($hasMessages -and $hasCodeBlocks -and $hasMetadata)
    } else {
        Write-Host "   FAIL: File not created" -ForegroundColor Red
        return $false
    }
}

# ========================================
# MAIN
# ========================================

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " CHAT AUTO-EXPORT V2" -ForegroundColor Cyan  
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Run self-test first
$testPassed = Run-SelfTest

if (!$testPassed) {
    Write-Host ""
    Write-Host "SELF-TEST FAILED - Not starting monitor" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " SELF-TEST PASSED - Starting Monitor" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Status: Monitoring clipboard every 10s" -ForegroundColor Yellow
Write-Host "Output: $HistoryFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workflow: Ctrl+A -> Ctrl+C in chat" -ForegroundColor White
Write-Host ""

# Load existing hashes
$KnownHashes = @{}
if (Test-Path $HistoryFile) {
    $content = Get-Content $HistoryFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $pattern = '## Message \d+.*?\n.*?\n.*?\n\n([\s\S]*?)(?=\n---\n|$)'
        $matches = [regex]::Matches($content, $pattern)
        foreach ($m in $matches) {
            $hash = Get-ContentHash $m.Groups[1].Value
            $KnownHashes[$hash] = $true
        }
    }
}

$LastClipboard = ""

try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        try {
            $clipboard = [System.Windows.Forms.Clipboard]::GetText()
            
            if ($clipboard -and $clipboard -ne $LastClipboard -and $clipboard.Length -gt 50) {
                if (Test-IsChat $clipboard) {
                    $time = Get-Date -Format "HH:mm:ss"
                    Write-Host "[$time] Chat detected ($($clipboard.Length) chars)..." -ForegroundColor Yellow
                    
                    $messages = Parse-ChatMessages $clipboard
                    $added = Export-ToMarkdown -messages $messages -knownHashes $KnownHashes
                    
                    if ($added -gt 0) {
                        Write-Host "[$time] SUCCESS: $added new messages (total: $($messages.Count))" -ForegroundColor Green
                    } else {
                        Write-Host "[$time] No new messages (total: $($messages.Count))" -ForegroundColor Gray
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
    Write-Host ""
    Write-Host "Stopped" -ForegroundColor Yellow
}
