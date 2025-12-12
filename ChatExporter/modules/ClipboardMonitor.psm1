# ==========================================
# ClipboardMonitor Module
# Clipboard operations for chat export
# ==========================================

<#
.SYNOPSIS
    Clipboard monitoring and reading module

.DESCRIPTION
    Provides functions to read and monitor clipboard content

.NOTES
    Author: AntiGravity Ghost Agent
    Version: 1.0
#>

# Load .NET type for clipboard access
Add-Type -AssemblyName System.Windows.Forms

function Get-ClipboardContent {
    <#
    .SYNOPSIS
        Read current clipboard text content
    
    .OUTPUTS
        String containing clipboard text, or empty string if clipboard is empty
    #>
    [CmdletBinding()]
    param()
    
    try {
        $content = [System.Windows.Forms.Clipboard]::GetText()
        if ([string]::IsNullOrWhiteSpace($content)) {
            return ""
        }
        return $content
    }
    catch {
        Write-Warning "Failed to read clipboard: $($_.Exception.Message)"
        return ""
    }
}

function Test-ClipboardEmpty {
    <#
    .SYNOPSIS
        Check if clipboard is empty
    
    .OUTPUTS
        Boolean - $true if empty, $false if contains text
    #>
    [CmdletBinding()]
    param()
    
    $content = Get-ClipboardContent
    return [string]::IsNullOrWhiteSpace($content)
}

function Get-ClipboardStats {
    <#
    .SYNOPSIS
        Get statistics about clipboard content
    
    .OUTPUTS
        Hashtable with character count, line count, and size in KB
    #>
    [CmdletBinding()]
    param()
    
    $content = Get-ClipboardContent
    
    if ([string]::IsNullOrWhiteSpace($content)) {
        return @{
            char_count = 0
            line_count = 0
            size_kb    = 0
        }
    }
    
    $lines = $content -split "`n"
    
    return @{
        char_count = $content.Length
        line_count = $lines.Count
        size_kb    = [Math]::Round($content.Length / 1KB, 2)
    }
}

# Export module members
Export-ModuleMember -Function Get-ClipboardContent, Test-ClipboardEmpty, Get-ClipboardStats
