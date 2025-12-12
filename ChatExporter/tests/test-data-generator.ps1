# ==========================================
# Test Data Generator for Chat Export
# Generates realistic mock chat conversations
# ==========================================

param(
    [ValidateSet('Small', 'Medium', 'Large', 'Huge')]
    [string]$Size = 'Medium',
    
    [switch]$IncludeCodeBlocks = $true,
    [switch]$IncludeSpecialChars = $true,
    [switch]$IncludeEdgeCases = $false,
    [switch]$CopyToClipboard = $true
)

# Load .NET for clipboard
Add-Type -AssemblyName System.Windows.Forms

# Configuration
$messageCounts = @{
    'Small'  = 10
    'Medium' = 50
    'Large'  = 100
    'Huge'   = 500
}

$messageCount = $messageCounts[$Size]

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " CHAT TEST DATA GENERATOR`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generating: $messageCount messages ($Size dataset)" -ForegroundColor Yellow
Write-Host ""

# Sample data
$userMessages = @(
    "Continue with implementation",
    "Fix this error please",
    "What's the status?",
    "Run the tests",
    "Deploy to production",
    "Check the logs",
    "Update the README",
    "Create a new branch",
    "Merge the PR",
    "Review this code"
)

$agentMessages = @(
    "I'll help you with that",
    "Here's the implementation:",
    "The tests are passing",
    "Deployment successful",
    "Logs show no errors",
    "README updated with latest changes",
    "Branch created: feature/new-feature",
    "PR merged successfully",
    "Code review complete"
)

$codeExamples = @(
    @{
        lang = 'powershell'
        code = 'Get-ChildItem | Where-Object { $_.Name -like "*.ps1" }'
    },
    @{
        lang = 'javascript'
        code = 'const result = array.map(item => item.value);'
    },
    @{
        lang = 'python'
        code = 'def process_data(data):\n    return [x * 2 for x in data]'
    },
    @{
        lang = 'bash'
        code = 'find . -name "*.log" -exec rm {} \;'
    }
)

# Generate conversation
$conversation = @()
$timestamp = 10, 0, 0  # Start at 10:00:00

for ($i = 1; $i -le $messageCount; $i++) {
    # Determine sender
    $from = if ($i % 2 -eq 1) { 'User' } else { 'Agent' }
    
    # Pick message
    if ($from -eq 'User') {
        $text = $userMessages | Get-Random
    }
    else {
        $text = $agentMessages | Get-Random
    }
    
    # Format timestamp
    $timeStr = "{0:D2}:{1:D2}:{2:D2}" -f $timestamp
    
    # Add code block randomly
    $includeCode = ($IncludeCodeBlocks -and ((Get-Random -Min 1 -Max 100) -lt 30))
    
    if ($includeCode) {
        $codeBlock = $codeExamples | Get-Random
        $text += "`n`n``````$($codeBlock.lang)`n$($codeBlock.code)`n``````"
    }
    
    # Format message
    $message = "$from [$timeStr]: $text"
    $conversation += $message
    
    # Increment timestamp
    $timestamp[2] += (Get-Random -Min 5 -Max 60)
    if ($timestamp[2] -ge 60) {
        $timestamp[1] += 1
        $timestamp[2] -= 60
    }
    if ($timestamp[1] -ge 60) {
        $timestamp[0] += 1
        $timestamp[1] -= 60
    }
}

# Add edge cases if requested
if ($IncludeEdgeCases) {
    Write-Host "Adding edge cases..." -ForegroundColor Yellow
    
    # Empty message
    $conversation += "User [15:00:00]: "
    
    # Very long message
    $longText = "This is a very long message. " * 100
    $conversation += "Agent [15:01:00]: $longText"
    
    # Special characters
    if ($IncludeSpecialChars) {
        $conversation += "User [15:02:00]: Testing special chars: `"quotes`" 'apostrophes' [brackets] {braces} <angles>"
    }
}

# Join conversation
$fullConversation = $conversation -join "`n`n"

# Copy to clipboard
if ($CopyToClipboard) {
    [System.Windows.Forms.Clipboard]::SetText($fullConversation)
    Write-Host "✅ Copied to clipboard" -ForegroundColor Green
}

# Save to file
$outputFile = "test-data-$Size-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
[System.IO.File]::WriteAllText($outputFile, $fullConversation, [System.Text.Encoding]::UTF8)

Write-Host "✅ Saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Messages: $messageCount" -ForegroundColor Gray
Write-Host "  Characters: $($fullConversation.Length)" -ForegroundColor Gray
Write-Host "  Size: $([Math]::Round($fullConversation.Length / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host ""
Write-Host "Next step: Run export_json.ps1 to test export" -ForegroundColor Yellow
Write-Host ""
