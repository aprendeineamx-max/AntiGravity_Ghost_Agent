# ==========================================
# Automated Test Runner
# Runs complete test suite for Chat Export
# ==========================================

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " CHAT EXPORT - AUTOMATED TEST SUITE`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$testDir = $PSScriptRoot
$exporterDir = Split-Path $testDir -Parent
$outputDir = "$env:USERPROFILE\Documents\AntiGravity_Chat_Exports"

$testResults = @{
    Total  = 0
    Passed = 0
    Failed = 0
    Tests  = @()
}

function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $testResults.Total++
    Write-Host "[TEST $($testResults.Total)] $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  PASSED" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{ Name = $Name; Result = "PASSED" }
        }
        else {
            Write-Host "  FAILED" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests += @{ Name = $Name; Result = "FAILED" }
        }
    }
    catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests += @{ Name = $Name; Result = "FAILED"; Error = $_.Exception.Message }
    }
    
    Write-Host ""
}

# ==========================================
# TEST 1: Test Data Generation
# ==========================================

Run-Test "Generate Small Test Data" {
    & "$testDir\test-data-generator.ps1" -Size Small -CopyToClipboard:$false
    Test-Path "test-data-Small-*.txt"
}

# ==========================================
# TEST 2: JSON Export
# ==========================================

Run-Test "Export as JSON" {
    # Generate medium data to clipboard
    & "$testDir\test-data-generator.ps1" -Size Medium -CopyToClipboard
    Start-Sleep -Seconds 1
    
    # Run export
    & "$exporterDir\export_json.ps1" -DualExport:$false
    
    # Check output
    $jsonFiles = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    $jsonFiles -ne $null
}

# ==========================================
# TEST 3: Dual Export
# ==========================================

Run-Test "Dual Export (JSON + MD)" {
    & "$testDir\test-data-generator.ps1" -Size Medium -CopyToClipboard
    Start-Sleep -Seconds 1
    
    & "$exporterDir\export_json.ps1" -DualExport
    
    $jsonFiles = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    $mdFiles = Get-ChildItem "$outputDir\Chat_Export_*.md" | Sort-Object LastWriteTime | Select-Object -Last 1
    
    ($jsonFiles -ne $null) -and ($mdFiles -ne $null)
}

# ==========================================
# TEST 4: JSON Schema Validation
# ==========================================

Run-Test "JSON Schema Validation" {
    $latestJson = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    
    if ($latestJson) {
        & "$testDir\validate-json.ps1" -JsonFile $latestJson.FullName
        $LASTEXITCODE -eq 0
    }
    else {
        $false
    }
}

# ==========================================
# TEST 5: Code Block Preservation
# ==========================================

Run-Test "Code Block Preservation" {
    $latestJson = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    
    if ($latestJson) {
        $json = Get-Content $latestJson.FullName -Raw | ConvertFrom-Json
        $codeBlocks = $json.messages | Where-Object { $_.content.code_blocks.Count -gt 0 }
        $codeBlocks.Count -gt 0
    }
    else {
        $false
    }
}

# ==========================================
# TEST 6: Large Dataset
# ==========================================

Run-Test "Large Dataset (100 messages)" {
    & "$testDir\test-data-generator.ps1" -Size Large -CopyToClipboard
    Start-Sleep -Seconds 1
    
    & "$exporterDir\export_json.ps1" -DualExport:$false
    
    $latestJson = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    
    if ($latestJson) {
        $json = Get-Content $latestJson.FullName -Raw | ConvertFrom-Json
        $json.messages.Count -ge 90  # Allow some margin
    }
    else {
        $false
    }
}

# ==========================================
# TEST 7: Edge Cases
# ==========================================

Run-Test "Edge Cases (special characters, long messages)" {
    & "$testDir\test-data-generator.ps1" -Size Small -IncludeEdgeCases -CopyToClipboard
    Start-Sleep -Seconds 1
    
    & "$exporterDir\export_json.ps1" -DualExport:$false
    
    $latestJson = Get-ChildItem "$outputDir\Chat_Export_*.json" | Sort-Object LastWriteTime | Select-Object -Last 1
    Test-Path $latestJson.FullName
}

# ==========================================
# RESULTS SUMMARY
# ==========================================

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " TEST RESULTS`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testResults.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""

if ($testResults.Failed -eq 0) {
    Write-Host "STATUS: ALL TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    exit 0
}
else {
    Write-Host "STATUS: SOME TESTS FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed tests:" -ForegroundColor Red
    foreach ($test in $testResults.Tests | Where-Object { $_.Result -eq "FAILED" }) {
        Write-Host "  - $($test.Name)" -ForegroundColor Red
        if ($test.Error) {
            Write-Host "    Error: $($test.Error)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    exit 1
}
