# ==========================================
# Chat Export - Main Orchestrator (Modular)
# Version: 2.1 - Modular Architecture
# ==========================================

<#
.SYNOPSIS
    Main orchestrator for chat export using modular architecture

.DESCRIPTION
    Imports and coordinates all export modules to provide dual-format
    chat export (JSON + Markdown)

.PARAMETER OutputDir
    Directory for export files

.PARAMETER DualExport
    Export both JSON and Markdown (default: true)

.NOTES
    Author: AntiGravity Ghost Agent
    Version: 2.1
#>

param(
    [string]$OutputDir = "$env:USERPROFILE\Documents\AntiGravity_Chat_Exports",
    [switch]$DualExport = $true
)

# ==========================================
# Import Modules
# ==========================================

$moduleDir = Join-Path $PSScriptRoot "modules"

Import-Module (Join-Path $moduleDir "ClipboardMonitor.psm1") -Force
Import-Module (Join-Path $moduleDir "MessageParser.psm1") -Force
Import-Module (Join-Path $moduleDir "JSONExporter.psm1") -Force
Import-Module (Join-Path $moduleDir "MarkdownExporter.psm1") -Force

# ==========================================
# Initialize
# ==========================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFile = Join-Path $OutputDir "Chat_Export_$timestamp.json"
$mdFile = Join-Path $OutputDir "Chat_Export_$timestamp.md"

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " ANTIGRAVITY CHAT EXPORT - v2.1 MODULAR`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# STEP 1: Read Clipboard
# ==========================================

Write-Host "[1/5] Reading clipboard..." -ForegroundColor Yellow

if (Test-ClipboardEmpty) {
    Write-Host "ERROR: Clipboard is empty!" -ForegroundColor Red
    exit 1
}

$clipboardText = Get-ClipboardContent
$stats = Get-ClipboardStats

Write-Host "   Clipboard size: $($stats.size_kb) KB" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 2: Parse Messages
# ==========================================

Write-Host "[2/5] Parsing messages..." -ForegroundColor Yellow

try {
    $messages = Split-ChatMessages -Content $clipboardText
    Write-Host "   Parsed: $($messages.Count) messages" -ForegroundColor Gray
}
catch {
    Write-Host "ERROR: Failed to parse messages: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ==========================================
# STEP 3: Build Metadata
# ==========================================

Write-Host "[3/5] Building metadata..." -ForegroundColor Yellow

$metadata = Get-ExportMetadata -Messages $messages

Write-Host "   Metadata:" -ForegroundColor Gray
Write-Host "     - Total messages: $($metadata.total_messages)" -ForegroundColor Gray
Write-Host "     - Participants: $($metadata.participants -join ', ')" -ForegroundColor Gray
Write-Host "     - Has code: $($metadata.has_code)" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 4: Export JSON
# ==========================================

Write-Host "[4/5] Exporting JSON..." -ForegroundColor Yellow

try {
    $exportedJSON = Export-ChatToJSON -Messages $messages -OutputPath $jsonFile
    $jsonSize = (Get-Item $exportedJSON).Length / 1KB
    Write-Host "   SUCCESS: $exportedJSON" -ForegroundColor Green
    Write-Host "   Size: $($jsonSize.ToString('F2')) KB" -ForegroundColor Gray
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ==========================================
# STEP 5: Export Markdown (Optional)
# ==========================================

if ($DualExport) {
    Write-Host "[5/5] Exporting Markdown..." -ForegroundColor Yellow
    
    try {
        $exportedMD = Export-ChatToMarkdown -Messages $messages -OutputPath $mdFile
        $mdSize = (Get-Item $exportedMD).Length / 1KB
        Write-Host "   SUCCESS: $exportedMD" -ForegroundColor Green
        Write-Host "   Size: $($mdSize.ToString('F2')) KB" -ForegroundColor Gray
    }
    catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " EXPORT COMPLETE (MODULAR)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  JSON: $jsonFile" -ForegroundColor White
if ($DualExport) {
    Write-Host "  MD:   $mdFile" -ForegroundColor White
}
Write-Host ""
Write-Host "Architecture: Modular (4 modules)" -ForegroundColor Gray
Write-Host "  - ClipboardMonitor.psm1" -ForegroundColor Gray
Write-Host "  - MessageParser.psm1" -ForegroundColor Gray
Write-Host "  - JSONExporter.psm1" -ForegroundColor Gray
Write-Host "  - MarkdownExporter.psm1" -ForegroundColor Gray
Write-Host ""
