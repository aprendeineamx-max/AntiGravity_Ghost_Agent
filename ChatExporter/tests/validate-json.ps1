# ==========================================
# JSON Schema Validator
# Validates exported JSON against schema v2.0
# ==========================================

param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFile,
    
    [string]$SchemaFile = "$PSScriptRoot\..\schemas\message-schema-v2.json"
)

Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " JSON SCHEMA VALIDATOR`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check files exist
if (!(Test-Path $JsonFile)) {
    Write-Host "ERROR: JSON file not found: $JsonFile" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $SchemaFile)) {
    Write-Host "ERROR: Schema file not found: $SchemaFile" -ForegroundColor Red
    exit 1
}

Write-Host "Validating:" -ForegroundColor Yellow
Write-Host "  JSON: $JsonFile" -ForegroundColor Gray
Write-Host "  Schema: $SchemaFile" -ForegroundColor Gray
Write-Host ""

# Load JSON
try {
    $json = Get-Content $JsonFile -Raw | ConvertFrom-Json
    Write-Host "[OK] JSON is valid and parseable" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] JSON parse error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Load Schema
try {
    $schema = Get-Content $SchemaFile -Raw | ConvertFrom-Json
}
catch {
    Write-Host "[FAIL] Schema parse error" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running validations..." -ForegroundColor Yellow
Write-Host ""

$errors = @()
$warnings = @()

# Validation 1: Version
if ($json.version -ne "2.0") {
    $errors += "Version must be '2.0', got '$($json.version)'"
}
else {
    Write-Host "[OK] Version: $($json.version)" -ForegroundColor Green
}

# Validation 2: Required fields
$requiredFields = @('version', 'exported_at', 'metadata', 'messages')
foreach ($field in $requiredFields) {
    if (-not $json.PSObject.Properties[$field]) {
        $errors += "Missing required field: $field"
    }
    else {
        Write-Host "[OK] Required field present: $field" -ForegroundColor Green
    }
}

# Validation 3: Metadata
if ($json.metadata) {
    if ($json.metadata.total_messages -ne $json.messages.Count) {
        $warnings += "Metadata total_messages ($($json.metadata.total_messages)) doesn't match actual count ($($json.messages.Count))"
    }
    Write-Host "[OK] Metadata structure valid" -ForegroundColor Green
}

# Validation 4: Messages array
if ($json.messages) {
    Write-Host "[OK] Messages array present ($($json.messages.Count) messages)" -ForegroundColor Green
    
    # Validate each message
    $msgErrors = 0
    foreach ($msg in $json.messages) {
        # Check ID format
        if ($msg.id -notmatch '^msg_\d{3,}$') {
            $msgErrors++
            $errors += "Invalid message ID format: $($msg.id)"
        }
        
        # Check required fields
        if (-not $msg.from) {
            $msgErrors++
            $errors += "Message $($msg.id) missing 'from' field"
        }
        
        if (-not $msg.content) {
            $msgErrors++
            $errors += "Message $($msg.id) missing 'content' field"
        }
    }
    
    if ($msgErrors -eq 0) {
        Write-Host "[OK] All messages have valid structure" -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] $msgErrors message(s) have structural issues" -ForegroundColor Yellow
    }
}

# Validation 5: Code blocks
$messagesWithCode = $json.messages | Where-Object { $_.content.code_blocks -and $_.content.code_blocks.Count -gt 0 }
if ($messagesWithCode) {
    Write-Host "[OK] Code blocks found in $($messagesWithCode.Count) message(s)" -ForegroundColor Green
    
    foreach ($msg in $messagesWithCode) {
        foreach ($block in $msg.content.code_blocks) {
            if (-not $block.code) {
                $warnings += "Message $($msg.id) has code block without 'code' field"
            }
        }
    }
}

Write-Host ""
Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Host " VALIDATION RESULTS`n" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "STATUS: VALID" -ForegroundColor Green
    Write-Host "  No errors or warnings found" -ForegroundColor Gray
    exit 0
}
else {
    if ($errors.Count -gt 0) {
        Write-Host "ERRORS: $($errors.Count)" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  - $err" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "WARNINGS: $($warnings.Count)" -ForegroundColor Yellow
        foreach ($warn in $warnings) {
            Write-Host "  - $warn" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($errors.Count -gt 0) {
        Write-Host "STATUS: INVALID" -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "STATUS: VALID (with warnings)" -ForegroundColor Yellow
        exit 0
    }
}
