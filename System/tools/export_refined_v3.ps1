# Chat Exporter V3 - Complete Refinement
# Implements all 8 improvements + enhancements

Add-Type -AssemblyName System.Windows.Forms

$ExportDir = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\Exports"
$OutputFile = Join-Path $ExportDir "Chat_Refined_Export_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"

if (!(Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CHAT EXPORTER V3 - REFINED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read clipboard
Write-Host "[1/6] Reading clipboard..." -ForegroundColor Yellow
$clipboard = [System.Windows.Forms.Clipboard]::GetText()

if (!$clipboard -or $clipboard.Length -lt 100) {
    Write-Host "ERROR: Clipboard empty" -ForegroundColor Red
    exit 1
}

Write-Host "    Captured: $($clipboard.Length) chars" -ForegroundColor Green

# Parse messages with ALL improvements
Write-Host "[2/6] Parsing messages (with refinements)..." -ForegroundColor Yellow

$lines = $clipboard -split "`n"
$messages = @()
$current = $null
$inCode = $false
$codeContent = ""
$codeLang = ""
$msgId = 1
$prevLineEmpty = $false
$filesMentioned = @{}
$keywords = @{}

foreach ($line in $lines) {
    # Code block detection WITH language
    if ($line -match '^```(\w*)') {
        if (!$inCode) {
            $inCode = $true
            $codeLang = if ($matches[1]) { $matches[1] } else { "" }
            $codeContent = ""
        } else {
            $inCode = $false
            if ($current) {
                $langTag = if ($codeLang) { $codeLang } else { "" }
                $current.content += "`n`n``````$langTag`n$codeContent``````"
                $current.hasCode = $true
                if ($codeLang) {
                    $current.codeLang = $codeLang
                }
            }
            $codeContent = ""
            $codeLang = ""
        }
        continue
    }
    
    if ($inCode) {
        $codeContent += "$line`n"
        continue
    }
    
    $trimmed = $line.Trim()
    
    # Extract timestamp if present
    $timestamp = $null
    if ($trimmed -match '^\[(\d{2}:\d{2}:\d{2})\](.*)') {
        $timestamp = $matches[1]
        $trimmed = $matches[2].Trim()
    }
    
    # Role detection
    if ($trimmed -match '^(USER|You):(.*)') {
        if ($current) {
            $current.id = $msgId
            $current.lineCount = ($current.content -split "`n").Length
            $current.charCount = $current.content.Length
            $messages += $current
            $msgId++
        }
        $current = @{
            from='user'
            content=$matches[2].Trim()
            timestamp=$timestamp
            hasCode=$false
            hasImage=$false
            codeLang=$null
            lineCount=0
            charCount=0
        }
        $prevLineEmpty = $false
    }
    elseif ($trimmed -match '^(AGENT|AI|Assistant):(.*)') {
        if ($current) {
            $current.id = $msgId
            $current.lineCount = ($current.content -split "`n").Length
            $current.charCount = $current.content.Length
            $messages += $current
            $msgId++
        }
        $current = @{
            from='agent'
            content=$matches[2].Trim()
            timestamp=$timestamp
            hasCode=$false
            hasImage=$false
            codeLang=$null
            lineCount=0
            charCount=0
        }
        $prevLineEmpty = $false
    }
    elseif ($trimmed -match '^Thought for (\d+)s') {
        if ($current) {
            $current.id = $msgId
            $current.lineCount = ($current.content -split "`n").Length
            $current.charCount = $current.content.Length
            $messages += $current
            $msgId++
        }
        $current = @{
            from='agent'
            content=$trimmed
            timestamp=$timestamp
            hasCode=$false
            hasImage=$false
            codeLang=$null
            thoughtTime=$matches[1]
            lineCount=0
            charCount=0
        }
        $prevLineEmpty = $false
    }
    elseif ($trimmed -match 'User uploaded image (\d+)') {
        if ($current) {
            $current.hasImage = $true
            $current.content += "`n`n![User uploaded image $($matches[1])](attachments/image_$($matches[1]).png)"
        }
        $prevLineEmpty = $false
    }
    elseif (!$trimmed) {
        # Empty line - paragraph break
        $prevLineEmpty = $true
    }
    elseif ($trimmed -and $current) {
        # Add content with paragraph preservation
        if ($prevLineEmpty) {
            $current.content += "`n`n$trimmed"  # Paragraph break
        } else {
            $current.content += "`n$trimmed"     # Line continuation
        }
        $prevLineEmpty = $false
        
        # Extract file references
        if ($trimmed -match '([a-zA-Z0-9_]+\.(js|ps1|md|json|ahk|bat))') {
            $fileName = $matches[1]
            if (!$filesMentioned.ContainsKey($fileName)) {
                $filesMentioned[$fileName] = @()
            }
            $filesMentioned[$fileName] += $msgId
        }
        
        # Extract keywords
        $words = $trimmed -split '\s+' | Where-Object { $_.Length -gt 4 }
        foreach ($word in $words) {
            $clean = $word -replace '[^a-zA-Z0-9]', ''
            if ($clean.Length -gt 4) {
                if (!$keywords.ContainsKey($clean)) {
                    $keywords[$clean] = @()
                }
                if (!$keywords[$clean].Contains($msgId)) {
                    $keywords[$clean] += $msgId
                }
            }
        }
    }
}

if ($current) {
    $current.id = $msgId
    $current.lineCount = ($current.content -split "`n").Length
    $current.charCount = $current.content.Length
    $messages += $current
}

Write-Host "    Parsed: $($messages.Count) messages" -ForegroundColor Green

# Calculate statistics
Write-Host "[3/6] Calculating statistics..." -ForegroundColor Yellow

$userCount = ($messages | Where-Object { $_.from -eq 'user' }).Count
$agentCount = ($messages | Where-Object { $_.from -eq 'agent' }).Count
$codeCount = ($messages | Where-Object { $_.hasCode }).Count
$imageCount = ($messages | Where-Object { $_.hasImage }).Count
$totalLines = ($messages | Measure-Object -Property lineCount -Sum).Sum
$totalChars = ($messages | Measure-Object -Property charCount -Sum).Sum

# Extract unique timestamps for duration
$timestamps = $messages | Where-Object { $_.timestamp } | Select-Object -ExpandProperty timestamp
$firstTime = if ($timestamps.Count -gt 0) { $timestamps[0] } else { "Unknown" }
$lastTime = if ($timestamps.Count -gt 0) { $timestamps[-1] } else { "Unknown" }

Write-Host "    User: $userCount, Agent: $agentCount" -ForegroundColor Gray
Write-Host "    Code: $codeCount, Images: $imageCount" -ForegroundColor Gray
Write-Host "    Total: $totalLines lines, $totalChars chars" -ForegroundColor Gray

# Build output
Write-Host "[4/6] Generating export..." -ForegroundColor Yellow

$output = "# 💬 Chat Conversation - Refined Export`n`n"
$output += "<!-- METADATA START -->`n"
$output += "**📅 Exported**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$output += "**📊 Total Messages**: $($messages.Count)`n"
$output += "**👥 Participants**: User ($userCount), Agent ($agentCount)`n"
$output += "**⏱️ Time Range**: $firstTime - $lastTime`n"
$output += "**🔧 Contains**: Code blocks ($codeCount), Images ($imageCount)`n"
$output += "**📈 Volume**: $totalLines lines, $([Math]::Round($totalChars / 1000, 1))K chars`n"
$output += "<!-- METADATA END -->`n`n"
$output += "---`n`n"

# Table of contents if >20 messages
if ($messages.Count -gt 20) {
    $output += "## 📑 Quick Navigation`n`n"
    $jumpPoints = @(1, [Math]::Floor($messages.Count / 4), [Math]::Floor($messages.Count / 2), [Math]::Floor($messages.Count * 3 / 4), $messages.Count)
    $jumps = @()
    foreach ($pt in $jumpPoints) {
        $jumps += "[Message $($pt.ToString('000'))](\#message-$($pt.ToString('000')))"
    }
    $output += ($jumps -join ' • ')
    $output += "`n`n---`n`n"
}

# Messages
foreach ($msg in $messages) {
    $num = $msg.id.ToString('000')
    $fromText = if ($msg.from -eq 'user') { '👤 User' } else { '🤖 Agent' }
    
    $output += "## Message $num {#message-$num}`n"
    $output += "| Property | Value |`n"
    $output += "|----------|-------|`n"
    $output += "| **From** | $fromText |`n"
    
    if ($msg.timestamp) {
        $output += "| **Time** | $($msg.timestamp) |`n"
    }
    
    $typeText = "text"
    if ($msg.hasCode) { $typeText += " + code" }
    if ($msg.hasImage) { $typeText += " + image" }
    if ($msg.thoughtTime) { $typeText+= " + thought" }
    $output += "| **Type** | $typeText |`n"
    
    if ($msg.thoughtTime) {
        $output += "| **Thinking** | $($msg.thoughtTime)s |`n"
    }
    
    if ($msg.codeLang) {
        $output += "| **Language** | $($msg.codeLang) |`n"
    }
    
    $output += "| **Size** | $($msg.lineCount) lines, $($msg.charCount) chars |`n"
    
    # Long message handling
    if ($msg.lineCount -gt 100) {
        $output += "`n<details>`n"
        $output += "<summary>📝 Long message - Click to expand ($($msg.lineCount) lines)</summary>`n`n"
        $output += "$($msg.content)`n`n"
        $output += "</details>`n`n"
    } else {
        $output += "`n$($msg.content)`n`n"
    }
    
    $output += "---`n`n"
}

# Search Index
Write-Host "[5/6] Building search index..." -ForegroundColor Yellow

$output += "`n## 🔍 Search Index`n`n"

if ($filesMentioned.Count -gt 0) {
    $output += "### Files Mentioned`n`n"
    $sortedFiles = $filesMentioned.GetEnumerator() | Sort-Object Name
    foreach ($file in $sortedFiles) {
        $msgNums = ($file.Value | Sort-Object -Unique) -join ', '
        $output += "- **$($file.Key)**: Messages $msgNums`n"
    }
    $output += "`n"
}

if ($keywords.Count -gt 0) {
    $output += "### Top Keywords`n`n"
    $topKeywords = $keywords.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 20
    foreach ($kw in $topKeywords) {
        $msgNums = ($kw.Value | Sort-Object -Unique | Select-Object -First 5) -join ', '
        $more = if ($kw.Value.Count -gt 5) { " (+$($kw.Value.Count - 5) more)" } else { "" }
        $output += "- **$($kw.Key)**: $msgNums$more`n"
    }
    $output += "`n"
}

# Analytics Dashboard
$output += "## 📊 Conversation Analytics`n`n"
$output += "| Metric | Value |`n"
$output += "|--------|-------|`n"
$output += "| **Total Messages** | $($messages.Count) |`n"
$output += "| **User Messages** | $userCount |`n"
$output += "| **Agent Messages** | $agentCount |`n"
$output += "| **Code Snippets** | $codeCount |`n"
$output += "| **Images** | $imageCount |`n"
$output += "| **Total Lines** | $totalLines |`n"
$output += "| **Total Characters** | $([Math]::Round($totalChars / 1000, 1))K |`n"
$output += "| **Avg Message Length** | $([Math]::Round($totalChars / $messages.Count, 0)) chars |`n"
$output += "| **Files Mentioned** | $($filesMentioned.Count) |`n"

$output += "`n---`n`n"
$output += "_Exported with Chat Exporter V3 - Refined Edition_`n"

# Write file
Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-Host "[6/6] Finalizing..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " EXPORT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output: $OutputFile" -ForegroundColor Cyan
Write-Host "Size: $([Math]::Round((Get-Item $OutputFile).Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "Messages: $($messages.Count)" -ForegroundColor White
Write-Host ""

# Return filename
$OutputFile
