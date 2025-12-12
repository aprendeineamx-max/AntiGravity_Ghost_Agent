# One-Shot Export: Capture clipboard NOW and export
# Run this AFTER copying the chat with Ctrl+A -> Ctrl+C

Add-Type -AssemblyName System.Windows.Forms

$ExportDir = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\Exports"
$OutputFile = Join-Path $ExportDir "Chat_Real_Export_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"

if (!(Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ONE-SHOT CHAT EXPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Reading clipboard..." -ForegroundColor Yellow

$clipboard = [System.Windows.Forms.Clipboard]::GetText()

if (!$clipboard -or $clipboard.Length -lt 100) {
    Write-Host ""
    Write-Host "ERROR: Clipboard is empty or too short" -ForegroundColor Red
    Write-Host "Please copy the chat first (Ctrl+A -> Ctrl+C in AntiGravity)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Captured: $($clipboard.Length) characters" -ForegroundColor Green
Write-Host ""
Write-Host "Parsing messages..." -ForegroundColor Yellow

# Parse with advanced logic
$lines = $clipboard -split "`n"
$messages = @()
$current = $null
$inCode = $false
$codeContent = ""
$messageNum = 1

foreach ($line in $lines) {
    # Code block detection
    if ($line -match '^```(\w*)') {
        if (!$inCode) {
            $inCode = $true
            $lang = $matches[1]
            $codeContent = "``````$lang`n"
        } else {
            $inCode = $false
            $codeContent += "``````"
            if ($current) {
                $current.content += "`n`n$codeContent"
                $current.hasCode = $true
            }
            $codeContent = ""
        }
        continue
    }
    
    if ($inCode) {
        $codeContent += "$line`n"
        continue
    }
    
    $trimmed = $line.Trim()
    
    # Role markers
    if ($trimmed -match '^(USER|You):(.*)') {
        if ($current) {
            $current.id = $messageNum
            $messages += $current
            $messageNum++
        }
        $current = @{
            from = 'user'
            type = 'text'
            content = $matches[2].Trim()
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            hasCode = $false
            hasImage = $false
        }
    }
    elseif ($trimmed -match '^(AGENT|AI|Assistant):(.*)') {
        if ($current) {
            $current.id = $messageNum
            $messages += $current
            $messageNum++
        }
        $current = @{
            from = 'agent'
            type = 'text'
            content = $matches[2].Trim()
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            hasCode = $false
            hasImage = $false
        }
    }
    elseif ($trimmed -match '^Thought for (\d+)s') {
        if ($current) {
            $current.id = $messageNum
            $messages += $current
            $messageNum++
        }
        $current = @{
            from = 'agent'
            type = 'thought'
            content = $trimmed
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            hasCode = $false
            hasImage = $false
            thoughtTime = $matches[1]
        }
    }
    elseif ($trimmed -match 'User uploaded image (\d+)') {
        if ($current) {
            $current.hasImage = $true
            $current.content += "`n`n![User uploaded image $($matches[1])](attachments/image_$($matches[1]).png)"
        }
    }
    elseif ($trimmed -and $current) {
        $current.content += "`n$trimmed"
    }
}

if ($current) {
    $current.id = $messageNum
    $messages += $current
}

Write-Host "Parsed: $($messages.Count) messages" -ForegroundColor Green

# Count stats
$userMsgs = ($messages | Where-Object { $_.from -eq 'user' }).Count
$agentMsgs = ($messages | Where-Object { $_.from -eq 'agent' }).Count
$codeBlocks = ($messages | Where-Object { $_.hasCode }).Count
$images = ($messages | Where-Object { $_.hasImage }).Count

Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  User messages: $userMsgs" -ForegroundColor White
Write-Host "  Agent messages: $agentMsgs" -ForegroundColor White
Write-Host "  With code blocks: $codeBlocks" -ForegroundColor White
Write-Host "  With images: $images" -ForegroundColor White

Write-Host ""
Write-Host "Exporting to Markdown..." -ForegroundColor Yellow

# Build output with best structure
$output = "# 💬 Chat Conversation - Real Export`n`n"
$output += "**📅 Exported**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$output += "**📊 Total Messages**: $($messages.Count)`n"
$output += "**👥 Participants**: User ($userMsgs), Agent ($agentMsgs)`n"
$output += "**🔧 Contains**: "

$features = @()
if ($codeBlocks -gt 0) { $features += "Code blocks ($codeBlocks)" }
if ($images -gt 0) { $features += "Images ($images)" }
$output += ($features -join ', ')
$output += "`n`n"
$output += "---`n`n"

# Table of Contents for easier navigation
if ($messages.Count -gt 20) {
    $output += "## 📑 Quick Navigation`n`n"
    $output += "Jump to: "
    $jumps = @()
    for ($i = 0; $i -lt [Math]::Min(10, $messages.Count); $i += [Math]::Max(1, [Math]::Floor($messages.Count / 10))) {
        $msgNum = $messages[$i].id
        $jumps += "[Message $msgNum](#message-$($msgNum.ToString('000')))"
    }
    $output += ($jumps -join ' • ')
    $output += "`n`n---`n`n"
}

# Messages
foreach ($msg in $messages) {
    $num = $msg.id.ToString('000')
    $fromText = if ($msg.from -eq 'user') { '👤 User' } else { '🤖 Agent' }
    $typeText = $msg.type
    
    if ($msg.hasCode) { $typeText += ' + code' }
    if ($msg.hasImage) { $typeText += ' + image' }
    
    $output += "## Message $num {#message-$num}`n"
    $output += "| Property | Value |`n"
    $output += "|----------|-------|`n"
    $output += "| **From** | $fromText |`n"
    $output += "| **Time** | $($msg.timestamp) |`n"
    $output += "| **Type** | $typeText |`n"
    
    if ($msg.thoughtTime) {
        $output += "| **Thinking** | $($msg.thoughtTime)s |`n"
    }
    
    $output += "`n$($msg.content)`n`n"
    $output += "---`n`n"
}

# Footer
$output += "`n`n"
$output += "---`n"
$output += "_Exported with Chat Exporter V2 - AntiGravity IDE_`n"

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " EXPORT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output file:" -ForegroundColor Cyan
Write-Host $OutputFile -ForegroundColor Yellow
Write-Host ""
Write-Host "File size: $([Math]::Round((Get-Item $OutputFile).Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host ""
Write-Host "Opening file..." -ForegroundColor Gray

# Open in default markdown viewer
Start-Process $OutputFile

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
