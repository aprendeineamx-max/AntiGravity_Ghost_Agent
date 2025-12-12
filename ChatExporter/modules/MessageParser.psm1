# ==========================================
# MessageParser Module
# Parses chat content into message objects
# ==========================================

<#
.SYNOPSIS
    Parses chat conversations into structured message objects

.DESCRIPTION
    This module provides functions to parse chat content from clipboard
    into structured message objects with metadata, timestamps, and content.

.NOTES
    Author: AntiGravity Ghost Agent
    Version: 1.0
#>

function Split-ChatMessages {
    <#
    .SYNOPSIS
        Parse chat content into individual message objects
    
    .PARAMETER Content
        Raw chat content as string
    
    .OUTPUTS
        Array of message hashtables
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    $messages = @()
    $msgCounter = 1
    
    # Split into lines
    $lines = $Content -split "`n"
    $totalLines = $lines.Count
    $lineIndex = 0
    
    $currentMessage = $null
    $currentFrom = "unknown"
    $currentText = @()
    
    # Use while loop with manual index to avoid infinite loops
    while ($lineIndex -lt $totalLines) {
        $line = $lines[$lineIndex]
        $lineIndex++
        
        # Check for role markers
        if ($line -match "^(User|Agent|System)[\s:]+(.*)$") {
            # Save previous message
            if ($currentMessage) {
                $currentMessage = Complete-MessageObject -Message $currentMessage -TextLines $currentText
                $messages += $currentMessage
            }
            
            # Start new message
            $currentFrom = $matches[1].ToLower()
            $currentText = @($matches[2])
            
            # Extract timestamp
            $timestamp = Extract-Timestamp -Line $line
            
            $currentMessage = New-MessageObject -Id $msgCounter -From $currentFrom -Timestamp $timestamp
            $msgCounter++
        }
        # Check for code block start
        elseif ($line -match "^```(\w*)") {
            $lang = $matches[1]
            if (!$lang) { $lang = "plaintext" }
            
            $codeLines = @()
            
            # Collect code block lines
            while ($lineIndex -lt $totalLines) {
                $nextLine = $lines[$lineIndex]
                $lineIndex++
                
                if ($nextLine -match "^```$") {
                    break
                }
                $codeLines += $nextLine
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
        $currentMessage = Complete-MessageObject -Message $currentMessage -TextLines $currentText
        $messages += $currentMessage
    }
    
    return , $messages
}

function New-MessageObject {
    <#
    .SYNOPSIS
        Create a new message object with default structure
    #>
    [CmdletBinding()]
    param(
        [int]$Id,
        [string]$From,
        [string]$Timestamp = "Unknown"
    )
    
    return @{
        id        = "msg_$($Id.ToString('000'))"
        timestamp = $Timestamp
        from      = $From
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
}

function Complete-MessageObject {
    <#
    .SYNOPSIS
        Complete a message object with text content and metadata
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Message,
        [array]$TextLines
    )
    
    $fullText = ($TextLines -join "`n").Trim()
    $Message.content.text = $fullText
    $Message.content.markdown = $fullText
    $Message.metadata.char_count = $fullText.Length
    $Message.metadata.line_count = $TextLines.Count
    
    return $Message
}

function Extract-Timestamp {
    <#
    .SYNOPSIS
        Extract timestamp from message line
    #>
    [CmdletBinding()]
    param(
        [string]$Line
    )
    
    $timeMatch = $Line | Select-String -Pattern "\[(\d{2}:\d{2}:\d{2})\]"
    if ($timeMatch) {
        return $timeMatch.Matches[0].Groups[1].Value
    }
    return "Unknown"
}

# Export module members
Export-ModuleMember -Function Split-ChatMessages, New-MessageObject, Complete-MessageObject, Extract-Timestamp
