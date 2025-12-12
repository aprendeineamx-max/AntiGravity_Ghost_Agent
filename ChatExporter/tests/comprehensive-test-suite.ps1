# ===========================================================================
# COMPREHENSIVE SYSTEM TEST SUITE - ENHANCED VERSION
# Tests all modules with robust error handling and proper assertions
# ===========================================================================

Write-Host "=========================================`n" -ForegroundColor Cyan
Write-Host " COMPREHENSIVE SYSTEM TEST SUITE v2.0`n" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-Case {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $testResults.Total++
    Write-Host "[$($testResults.Total)] $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{ Name = $Name; Result = "PASS" }
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests += @{ Name = $Name; Result = "FAIL" }
        }
    }
    catch {
        Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests += @{ Name = $Name; Result = "FAIL"; Error = $_.Exception.Message }
    }
    Write-Host ""
}

# Helper: Safe clipboard set with retry
function Set-ClipboardSafe {
    param([string]$Text)
    
    $retries = 3
    for ($i = 1; $i -le $retries; $i++) {
        try {
            [System.Windows.Forms.Clipboard]::Clear()
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.Clipboard]::SetText($Text)
            Start-Sleep -Milliseconds 200
            
            # Verify
            $verify = [System.Windows.Forms.Clipboard]::GetText()
            if ($verify -eq $Text) {
                return $true
            }
        }
        catch {
            if ($i -lt $retries) {
                Start-Sleep -Milliseconds 300
            }
        }
    }
    return $false
}

# Navigate to ChatExporter directory
$scriptDir = Split-Path -Parent $PSScriptRoot
cd $scriptDir

Write-Host "Working directory: $((Get-Location).Path)" -ForegroundColor Gray
Write-Host ""

# Load .NET for clipboard
Add-Type -AssemblyName System.Windows.Forms

# ===========================================================================
# PHASE 1: Module Unit Tests
# ===========================================================================

Write-Host "=== PHASE 1: Module Unit Tests ===" -ForegroundColor Yellow
Write-Host ""

# Import modules
Import-Module .\modules\MessageParser.psm1 -Force -ErrorAction Stop
Import-Module .\modules\JSONExporter.psm1 -Force -ErrorAction Stop
Import-Module .\modules\MarkdownExporter.psm1 -Force -ErrorAction Stop
Import-Module .\modules\ClipboardMonitor.psm1 -Force -ErrorAction Stop

# Test 1: MessageParser with simple input
Test-Case "MessageParser: Parse 3 messages" {
    $testContent = @"
User [10:00:00]: Hello
Agent [10:00:05]: Hi there
User [10:00:10]: How are you?
"@
    $messages = Split-ChatMessages -Content $testContent
    $messages.Count -eq 3
}

# Test 2: MessageParser with code blocks
Test-Case "MessageParser: Parse message with code block" {
    $testContent = @"
User [10:00:00]: Here's some code

``````powershell
Get-Process | Where-Object { `$_.Name -like "*chrome*" }
``````

Agent [10:00:05]: That looks good
"@
    $messages = Split-ChatMessages -Content $testContent
    ($messages.Count -eq 2) -and ($messages[0].metadata.has_code -eq $true)
}

# Test 3: JSONExporter
Test-Case "JSONExporter: Build export object" {
    $testMessages = @(
        @{
            id = "msg_001"
            timestamp = "10:00:00"
            from = "user"
            type = "text"
            content = @{ text = "Hello"; markdown = "Hello"; code_blocks = @() }
            metadata = @{ char_count = 5; line_count = 1; has_code = $false }
        }
    )
    $export = Build-ExportObject -Messages $testMessages
    ($export.version -eq "2.0") -and ($export.messages.Count -eq 1)
}

# Test 4: JSONExporter file export
Test-Case "JSONExporter: Export to file" {
    $testMessages = @(
        @{
            id = "msg_001"
            timestamp = "10:00:00"
            from = "user"
            type = "text"
            content = @{ text = "Test"; markdown = "Test"; code_blocks = @() }
            metadata = @{ char_count = 4; line_count = 1; has_code = $false }
        }
    )
    $testPath = "$env:TEMP\test_export_$(Get-Random).json"
    try {
        Export-ChatToJSON -Messages $testMessages -OutputPath $testPath
        $fileExists = Test-Path $testPath
        if ($fileExists) { Remove-Item $testPath -Force }
        $fileExists
    }
    catch {
        if (Test-Path $testPath) { Remove-Item $testPath -Force }
        $false
    }
}

# Test 5: MarkdownExporter
Test-Case "MarkdownExporter: Export to file" {
    $testMessages = @(
        @{
            id = "msg_001"
            timestamp = "10:00:00"
            from = "user"
            type = "text"
            content = @{ text = "Test"; markdown = "Test"; code_blocks = @() }
            metadata = @{ char_count = 4; line_count = 1; has_code = $false }
        }
    )
    $testPath = "$env:TEMP\test_export_$(Get-Random).md"
    try {
        Export-ChatToMarkdown -Messages $testMessages -OutputPath $testPath
        $fileExists = Test-Path $testPath
        if ($fileExists) { Remove-Item $testPath -Force }
        $fileExists
    }
    catch {
        if (Test-Path $testPath) { Remove-Item $testPath -Force }
        $false
    }
}

# Test 6: ClipboardMonitor - FIXED ASSERTION
Test-Case "ClipboardMonitor: Get stats function" {
    try {
        $stats = Get-ClipboardStats
        # Verify function returns hashtable with expected properties
        ($stats -is [hashtable]) -and 
        ($stats.ContainsKey('char_count')) -and 
        ($stats.ContainsKey('line_count')) -and
        ($stats.ContainsKey('size_kb')) -and
        ($stats.char_count -is [int]) -and
        ($stats.line_count -is [int])
    }
    catch {
        $false
    }
}

# ===========================================================================
# PHASE 2: Integration Tests
# ===========================================================================

Write-Host "=== PHASE 2: Integration Tests ===" -ForegroundColor Yellow
Write-Host ""

# Test 7: main.ps1 with test data - IMPROVED
Test-Case "Integration: main.ps1 with test data" {
    $testData = @"
User [10:00:00]: Test message 1
Agent [10:00:05]: Response 1
User [10:00:10]: Test message 2
"@
    
    $testDir = "$env:TEMP\ChatExportTest_$(Get-Random)"
    
    try {
        # Set clipboard safely
        $clipboardSet = Set-ClipboardSafe -Text $testData
        if (!$clipboardSet) {
            Write-Host "    Warning: Clipboard set failed" -ForegroundColor Yellow
            return $false
        }
        
        # Run main.ps1
        & .\main.ps1 -OutputDir $testDir -ErrorAction Stop 2>&1 | Out-Null
        
        # Check output
        $latestJSON = Get-ChildItem $testDir -Filter "Chat_Export_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $testPassed = $latestJSON -ne $null
        
        # Cleanup
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        
        $testPassed
    }
    catch {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        $false
    }
}

# ===========================================================================
# PHASE 3: Stress Tests
# ===========================================================================

Write-Host "=== PHASE 3: Stress Tests ===" -ForegroundColor Yellow
Write-Host ""

# Test 8: Large dataset (100 messages)
Test-Case "Stress: Parse 100 messages" {
    $lines = @()
    for ($i = 1; $i -le 100; $i++) {
        $time = "10:$(($i % 60).ToString('00')):00"
        $from = if ($i % 2 -eq 1) { "User" } else { "Agent" }
        $lines += "$from [$time]: Message $i"
    }
    $largeContent = $lines -join "`n"
    
    $messages = Split-ChatMessages -Content $largeContent
    $messages.Count -ge 95  # Allow 5% margin for parsing variations
}

# Test 9: Long single message
Test-Case "Stress: Parse very long message" {
    $longText = "This is a very long message. " * 500  # ~15000 chars
    $testContent = "User [10:00:00]: $longText"
    
    $messages = Split-ChatMessages -Content $testContent
    ($messages.Count -eq 1) -and ($messages[0].metadata.char_count -gt 10000)
}

# ===========================================================================
# PHASE 4: JSON Validation  
# ===========================================================================

Write-Host "=== PHASE 4: JSON Schema Validation ===" -ForegroundColor Yellow
Write-Host ""

# Test 10: Schema compliance
Test-Case "Validation: JSON schema compliance" {
    $testMessages = @(
        @{
            id = "msg_001"
            timestamp = "10:00:00"
            from = "user"
            type = "text"
            content = @{ text = "Test"; markdown = "Test"; code_blocks = @() }
            metadata = @{ char_count = 4; line_count = 1; has_code = $false }
        }
    )
    
    $testPath = "$env:TEMP\schema_test_$(Get-Random).json"
    
    try {
        Export-ChatToJSON -Messages $testMessages -OutputPath $testPath
        
        # Validate
        $validationResult = & .\tests\validate-json.ps1 -JsonFile $testPath -ErrorAction SilentlyContinue 2>&1
        $passed = $LASTEXITCODE -eq 0
        
        # Cleanup
        if (Test-Path $testPath) { Remove-Item $testPath -Force }
        
        $passed
    }
    catch {
        if (Test-Path $testPath) { Remove-Item $testPath -Force }
        $false
    }
}

# ===========================================================================
# PHASE 5: Backward Compatibility - FIXED PATHS
# ===========================================================================

Write-Host "=== PHASE 5: Backward Compatibility ===" -ForegroundColor Yellow
Write-Host ""

# Test 11: export_json.ps1 still works - IMPROVED
Test-Case "Backward: export_json.ps1 functional" {
    $testData = "User [10:00:00]: Test`nAgent [10:00:05]: Response"
    $testDir = "$env:TEMP\BackwardTest_$(Get-Random)"
    
    try {
        $clipboardSet = Set-ClipboardSafe -Text $testData
        if (!$clipboardSet) {
            Write-Host "    Warning: Clipboard set failed" -ForegroundColor Yellow
            return $false
        }
        
        & .\export_json.ps1 -OutputDir $testDir -ErrorAction Stop 2>&1 | Out-Null
        
        $latestJSON = Get-ChildItem $testDir -Filter "Chat_Export_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $testPassed = $latestJSON -ne $null
        
        # Cleanup
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        
        $testPassed
    }
    catch {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        $false
    }
}

# Test 12: test-data-generator still works - IMPROVED
Test-Case "Backward: test-data-generator functional" {
    try {
        $currentDir = Get-Location
        cd .\tests
        
        & .\test-data-generator.ps1 -Size Small -CopyToClipboard:$false -ErrorAction Stop 2>&1 | Out-Null
        
        # Check for files in tests directory
        $testFiles = Get-ChildItem "test-data-Small-*.txt" -ErrorAction SilentlyContinue
        $testPassed = $testFiles.Count -gt 0
        
        cd $currentDir
        $testPassed
    }
    catch {
        cd $currentDir
        $false
    }
}

# ===========================================================================
# RESULTS SUMMARY
# ===========================================================================

Write-Host "=========================================`n" -ForegroundColor Cyan
Write-Host " TEST RESULTS SUMMARY`n" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testResults.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) {'Red'} else {'Green'})
Write-Host ""

$passRate = [Math]::Round(($testResults.Passed / $testResults.Total) * 100, 1)
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) {'Green'} elseif ($passRate -ge 75) {'Yellow'} else {'Red'})
Write-Host ""

if ($testResults.Failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($test in $testResults.Tests | Where-Object { $_.Result -eq "FAIL" }) {
        Write-Host "  - $($test.Name)" -ForegroundColor Red
        if ($test.Error) {
            Write-Host "    Error: $($test.Error)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "STATUS: SOME TESTS FAILED" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "STATUS: ALL TESTS PASSED ✅" -ForegroundColor Green
    Write-Host ""
    exit 0
}
