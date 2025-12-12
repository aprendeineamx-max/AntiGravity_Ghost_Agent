# ==========================================
# Chat Export JSON - Dual Format Exporter
# Version: 2.1 - FIXED PARSER
# ==========================================

param(
    [string]$OutputDir = "$env:USERPROFILE\Documents\AntiGravity_Chat_Exports",
    [switch]$DualExport = $true,
    [switch]$ValidateSchema = $false
)

# Load .NET for clipboard
Add-Type -AssemblyName System.Windows.Forms

# Initialize
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFile = Join-Path $OutputDir "Chat_Export_$timestamp.json"
$mdFile = Join-Path $OutputDir "Chat_Export_$timestamp.md"

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " ANTIGRAVITY CHAT EXPORT - JSON v2.1`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# STEP 1: Read Clipboard
# ==========================================

Write-Host "[1/5] Reading clipboard..." -ForegroundColor Yellow
$clipboardText = [System.Windows.Forms.Clipboard]::GetText()

if ([string]::IsNullOrWhiteSpace($clipboardText)) {
    Write-Host "ERROR: Clipboard is empty!" -ForegroundColor Red
    exit 1
}

Write-Host "   Clipboard size: $(($clipboardText.Length / 1KB).ToString('F2')) KB" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 2: Parse Messages - FIXED VERSION
# ==========================================

Write-Host "[2/5] Parsing messages..." -ForegroundColor Yellow

function Parse-ChatMessage {
    param([string]$content)
    
    $messages = @()
    $msgCounter = 1
    
    # Split into lines
    $lines = $content -split "`n"
    $totalLines = $lines.Count
    $lineIndex = 0
    
    $currentMessage = $null
    $currentFrom = "unknown"
    $currentText = @()
    
    # Use while loop with manual index to avoid foreach issues
    while ($lineIndex -lt $totalLines) {
        $line = $lines[$lineIndex]
        $lineIndex++
        
        # Check for role markers
        if ($line -match "^(User|Agent|System)[\s:]+(.*)$") {
            # Save previous message
            if ($currentMessage) {
                $fullText = ($currentText -join "`n").Trim()
                $currentMessage.content.text = $fullText
                $currentMessage.content.markdown = $fullText
                $currentMessage.metadata.char_count = $fullText.Length
                $currentMessage.metadata.line_count = $currentText.Count
                $messages += $currentMessage
            }
            
            # Start new message
            $currentFrom = $matches[1].ToLower()
            $currentText = @($matches[2])
            
            # Extract timestamp
            $timeMatch = $line | Select-String -Pattern "\[(\d{2}:\d{2}:\d{2})\]"
            $timestamp = if ($timeMatch) { $timeMatch.Matches[0].Groups[1].Value } else { "Unknown" }
            
            $currentMessage = @{
                id        = "msg_$($msgCounter.ToString('000'))"
                timestamp = $timestamp
                from      = $currentFrom
                type      = "text"
                content   = @{
                    text        = ""
                    markdown    = ""
                    code_blocks = @()
                }
                metadata  = @{
                    char_count = 0
                    line_count = 0
                    has_code   = $false
                }
            }
            $msgCounter++
        }
        # Check for code block start
        elseif ($line -match "^```(\w*)") {
            $lang = $matches[1]
            if (!$lang) { $lang = "plaintext" }
            
            $codeLines = @()
            
            # Collect code block lines (FIXED: use while with index)
            while ($lineIndex -lt $totalLines) {
                $nextLine = $lines[$lineIndex]
                $lineIndex++
                
                if ($nextLine -match "^```$") {
                    # End of code block
                    break
                }
                else {
                    $codeLines += $nextLine
                }
            }
            
            # Add to current message
            if ($currentMessage) {
                $currentMessage.content.code_blocks += @{
                    language = $lang
                    code     = ($codeLines -join "`n")
                }
                $currentMessage.metadata.has_code = $true
                $currentMessage.type = if ($currentMessage.type -eq "text") { "text+code" } else { $currentMessage.type }
            }
        }
        else {
            # Regular text line
            if ($currentMessage) {
                $currentText += $line
            }
        }
    }
    
    # Save last message
    if ($currentMessage) {
        $fullText = ($currentText -join "`n").Trim()
        $currentMessage.content.text = $fullText
        $currentMessage.content.markdown = $fullText
        $currentMessage.metadata.char_count = $fullText.Length
        $currentMessage.metadata.line_count = $currentText.Count
        $messages += $currentMessage
    }
    
    return , $messages
}

$messages = Parse-ChatMessage -content $clipboardText

Write-Host "   Parsed: $($messages.Count) messages" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 3: Build JSON Structure
# ==========================================

Write-Host "[3/5] Building JSON structure..." -ForegroundColor Yellow

# Calculate metadata
$participants = ($messages | Select-Object -ExpandProperty from -Unique)
$hasCode = ($messages | Where-Object { $_.metadata.has_code }) -ne $null
$totalChars = ($messages | Measure-Object -Property { $_.metadata.char_count } -Sum).Sum

# Build export object
$export = @{
    version     = "2.0"
    exported_at = (Get-Date).ToUniversalTime().ToString("o")
    source      = "AntiGravity Chat Exporter v2.1"
    metadata    = @{
        total_messages   = $messages.Count
        participants     = $participants
        has_images       = $false
        has_code         = $hasCode
        total_characters = $totalChars
    }
    messages    = $messages
}

Write-Host "   Metadata:" -ForegroundColor Gray
Write-Host "     - Total messages: $($messages.Count)" -ForegroundColor Gray
Write-Host "     - Participants: $($participants -join ', ')" -ForegroundColor Gray
Write-Host "     - Has code: $hasCode" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 4: Export JSON
# ==========================================

Write-Host "[4/5] Exporting JSON..." -ForegroundColor Yellow

try {
    $jsonContent = $export | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($jsonFile, $jsonContent, [System.Text.Encoding]::UTF8)
    
    $jsonSize = (Get-Item $jsonFile).Length / 1KB
    Write-Host "   SUCCESS: $jsonFile" -ForegroundColor Green
    Write-Host "   Size: $($jsonSize.ToString('F2')) KB" -ForegroundColor Gray
}
catch {
    Write-Host "   ERROR: Failed to export JSON" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ==========================================
# STEP 5: Export Markdown (Optional)
# ==========================================

if ($DualExport) {
    Write-Host "[5/5] Exporting Markdown..." -ForegroundColor Yellow
    
    $mdContent = @"
# Chat Conversation Export

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Format**: Markdown + JSON  
**Total Messages**: $($messages.Count)  
**Participants**: $($participants -join ', ')

---

"@
    
    $msgNum = 1
    foreach ($msg in $messages) {
        $mdContent += @"

## Message $msgNum

**From**: $($msg.from)  
**Time**: $($msg.timestamp)  
**Type**: $($msg.type)

$($msg.content.markdown)

"@
        
        # Add code blocks
        foreach ($codeBlock in $msg.content.code_blocks) {
            $mdContent += @"

``````$($codeBlock.language)
$($codeBlock.code)
``````

"@
        }
        
        $mdContent += "`n---`n"
        $msgNum++
    }
    
    # Save markdown
    [System.IO.File]::WriteAllText($mdFile, $mdContent, [System.Text.Encoding]::UTF8)
    
    $mdSize = (Get-Item $mdFile).Length / 1KB
    Write-Host "   SUCCESS: $mdFile" -ForegroundColor Green
    Write-Host "   Size: $($mdSize.ToString('F2')) KB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " EXPORT COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  JSON: $jsonFile" -ForegroundColor White
if ($DualExport) {
    Write-Host "  MD:   $mdFile" -ForegroundColor White
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - View JSON for structured data" -ForegroundColor Gray
Write-Host "  - View MD for human-readable format" -ForegroundColor Gray
Write-Host "  - Import JSON to database or UI reader" -ForegroundColor Gray
Write-Host ""
