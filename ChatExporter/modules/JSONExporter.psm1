# ==========================================
# JSONExporter Module
# Exports chat messages to JSON format
# ==========================================

<#
.SYNOPSIS
    Export module for JSON chat exports

.DESCRIPTION
    Provides functions to build and export chat messages in JSON format
    conforming to schema v2.0

.NOTES
    Author: AntiGravity Ghost Agent
    Version: 1.0
#>

function Export-ChatToJSON {
    <#
    .SYNOPSIS
        Export chat messages to JSON file
    
    .PARAMETER Messages
        Array of message objects
    
    .PARAMETER OutputPath
        Path to save JSON file
    
    .OUTPUTS
        Path to created JSON file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    try {
        # Build export object
        $exportObject = Build-ExportObject -Messages $Messages
        
        # Convert to JSON
        $jsonContent = $exportObject | ConvertTo-Json -Depth 10
        
        # Save with UTF-8 encoding
        [System.IO.File]::WriteAllText($OutputPath, $jsonContent, [System.Text.Encoding]::UTF8)
        
        return $OutputPath
    }
    catch {
        throw "Failed to export JSON: $($_.Exception.Message)"
    }
}

function Build-ExportObject {
    <#
    .SYNOPSIS
        Build complete export object conforming to schema v2.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages
    )
    
    # Calculate metadata
    $participants = ($Messages | Select-Object -ExpandProperty from -Unique)
    $hasCode = ($Messages | Where-Object { $_.metadata.has_code }) -ne $null
    
    # Calculate total characters
    $totalChars = 0
    foreach ($msg in $Messages) {
        if ($msg.metadata -and $msg.metadata.char_count) {
            $totalChars += $msg.metadata.char_count
        }
    }
    
    return @{
        version     = "2.0"
        exported_at = (Get-Date).ToUniversalTime().ToString("o")
        source      = "AntiGravity Chat Exporter v2.1 (Modular)"
        metadata    = @{
            total_messages   = $Messages.Count
            participants     = $participants
            has_images       = $false
            has_code         = $hasCode
            total_characters = $totalChars
        }
        messages    = $Messages
    }
}

function Get-ExportMetadata {
    <#
    .SYNOPSIS
        Calculate export metadata from messages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages
    )
    
    $participants = ($Messages | Select-Object -ExpandProperty from -Unique)
    $hasCode = ($Messages | Where-Object { $_.metadata.has_code }) -ne $null
    
    return @{
        total_messages = $Messages.Count
        participants   = $participants
        has_code       = $hasCode
    }
}

# Export module members
Export-ModuleMember -Function Export-ChatToJSON, Build-ExportObject, Get-ExportMetadata
