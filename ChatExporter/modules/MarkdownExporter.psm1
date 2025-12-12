# ==========================================
# MarkdownExporter Module
# Exports chat messages to Markdown format
# ==========================================

<#
.SYNOPSIS
    Export module for Markdown chat exports

.DESCRIPTION
    Provides functions to format and export chat messages in Markdown format

.NOTES
    Author: AntiGravity Ghost Agent
    Version: 1.0
#>

function Export-ChatToMarkdown {
    <#
    .SYNOPSIS
        Export chat messages to Markdown file
    
    .PARAMETER Messages
        Array of message objects
    
    .PARAMETER OutputPath
        Path to save Markdown file
    
    .OUTPUTS
        Path to created Markdown file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    try {
        # Build markdown content
        $mdContent = Build-MarkdownContent -Messages $Messages
        
        # Save with UTF-8 encoding
        [System.IO.File]::WriteAllText($OutputPath, $mdContent, [System.Text.Encoding]::UTF8)
        
        return $OutputPath
    }
    catch {
        throw "Failed to export Markdown: $($_.Exception.Message)"
    }
}

function Build-MarkdownContent {
    <#
    .SYNOPSIS
        Build complete Markdown document from messages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages
    )
    
    # Get participants
    $participants = ($Messages | Select-Object -ExpandProperty from -Unique)
    
    # Create header
    $mdContent = @"
# Chat Conversation Export

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Format**: Markdown + JSON  
**Total Messages**: $($Messages.Count)  
**Participants**: $($participants -join ', ')

---

"@
    
    # Add each message
    $msgNum = 1
    foreach ($msg in $Messages) {
        $mdContent += Format-MessageAsMarkdown -Message $msg -MessageNumber $msgNum
        $msgNum++
    }
    
    return $mdContent
}

function Format-MessageAsMarkdown {
    <#
    .SYNOPSIS
        Format a single message as Markdown
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Message,
        
        [Parameter(Mandatory=$true)]
        [int]$MessageNumber
    )
    
    $md = @"

## Message $MessageNumber

**From**: $($Message.from)  
**Time**: $($Message.timestamp)  
**Type**: $($Message.type)

$($Message.content.markdown)

"@
    
    # Add code blocks
    foreach ($codeBlock in $Message.content.code_blocks) {
        $md += @"

``````$($codeBlock.language)
$($codeBlock.code)
``````

"@
    }
    
    $md += "`n---`n"
    
    return $md
}

# Export module members
Export-ModuleMember -Function Export-ChatToMarkdown, Build-MarkdownContent, Format-MessageAsMarkdown
