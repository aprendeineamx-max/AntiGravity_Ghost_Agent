<#
    .SYNOPSIS
    OMNICONTROL HUD v2.0 - Remastered
    External Overwatch System for AntiGravity Agent.
    
    .DESCRIPTION
    A Floating HEAD-UP DISPLAY (HUD) that monitors foreground windows.
    If a target window (e.g. VS Code / AntiGravity) requests attention,
    it automatically injects confirmation keys.

    FEATURES v2.0:
    - Multi-Target Regex Support
    - Rolling Event Log
    - Dynamic Status Indicators
    - Safety Kill-Switch (User Typing Detection)
    - Dark Mode "Ghost" Aesthetic
#>

Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing

# --- 1. WIN32 API INTEGRATION ---
$Win32Code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
"@
if (-not ([System.Management.Automation.PSTypeName]'Win32Utils.Win32').Type) {
    Add-Type -MemberDefinition $Win32Code -Name "Win32" -Namespace Win32Utils
}

# --- 2. CONFIGURATION ---
$Config = @{
    Targets  = @("AntiGravity", "Visual Studio Code", "Confirmar", "Security Warning")
    Keys     = "%~"  # Alt + Enter
    Interval = 1.0   # Seconds
}

# --- 3. XAML INTERFACE (Redesigned) ---
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniControl HUD" Height="220" Width="340" 
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="#111111" Topmost="True" BorderBrush="#333333" BorderThickness="1"
        Opacity="0.95">
    
    <Window.Resources>
        <!-- Scrollbar Style (Hidden/Minimal) -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="5"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="30"/>  <!-- Header -->
            <RowDefinition Height="60"/>  <!-- Status Monitor -->
            <RowDefinition Height="*"/>   <!-- Log Console -->
            <RowDefinition Height="40"/>  <!-- Controls -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Border Grid.Row="0" Background="#1A1A1A" MouseLeftButtonDown="DragWindow">
            <DockPanel LastChildFill="False" Margin="10,0">
                <TextBlock Text="👻 OMNICONTROL // v2.0" Foreground="#666666" FontWeight="Bold" FontFamily="Consolas" VerticalAlignment="Center"/>
                <Button Name="btnClose" Content="✕" DockPanel.Dock="Right" Background="Transparent" Foreground="#666" BorderThickness="0" Margin="5,0,0,0" FontWeight="Bold"/>
                <CheckBox Name="chkOnTop" Content="📌" IsChecked="True" DockPanel.Dock="Right" Foreground="#444" BorderBrush="#333" VerticalAlignment="Center" ToolTip="Always On Top"/>
            </DockPanel>
        </Border>

        <!-- STATUS MONITOR -->
        <Border Grid.Row="1" Background="#0F0F0F" BorderBrush="#222" BorderThickness="0,1">
            <Grid Margin="10,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                
                <!-- Pulse Indicator -->
                <Border Name="bdrPulse" Width="10" Height="10" CornerRadius="10" Background="#333" VerticalAlignment="Top" Margin="0,5,10,0">
                    <Border.Effect>
                        <BlurEffect Radius="2"/>
                    </Border.Effect>
                </Border>

                <StackPanel Grid.Column="1">
                    <TextBlock Name="lblState" Text="STANDBY" Foreground="#555" FontWeight="Bold" FontSize="12"/>
                    <TextBlock Name="lblDetails" Text="Waiting for signature..." Foreground="#444" FontSize="10" FontFamily="Segoe UI" Margin="0,2,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- LOG CONSOLE -->
        <ListBox Name="lstLog" Grid.Row="2" Background="#000000" BorderThickness="0" Foreground="#00FF00" FontFamily="Consolas" FontSize="10" ScrollViewer.VerticalScrollBarVisibility="Hidden">
            <ListBox.ItemContainerStyle>
                <Style TargetType="ListBoxItem">
                    <Setter Property="Padding" Value="5,1"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ListBoxItem">
                                <ContentPresenter/>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </ListBox.ItemContainerStyle>
        </ListBox>

        <!-- CONTROLS -->
        <Grid Grid.Row="3" Background="#1A1A1A">
            <Button Name="btnToggle" Content="▶ ACTIVATE AGENT" Background="#222" Foreground="#888" BorderThickness="0" FontWeight="Bold"/>
        </Grid>

    </Grid>
</Window>
"@

# --- 4. ENGINE INITIALIZATION ---
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Map UI Elements
$Elements = @{}
@("btnClose", "chkOnTop", "bdrPulse", "lblState", "lblDetails", "lstLog", "btnToggle") | ForEach-Object {
    $Elements[$_] = $Window.FindName($_)
}

# --- 5. LOGIC CORE ---
$State = @{
    Running = $false
    wsh     = New-Object -ComObject WScript.Shell
}

function Add-Log($msg, $color = "#666666") {
    $item = New-Object System.Windows.Controls.ListBoxItem
    $item.Content = "$((Get-Date).ToString('HH:mm:ss')) | $msg"
    $item.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    $Elements.lstLog.Items.Add($item) | Out-Null
    $Elements.lstLog.ScrollIntoView($item)
    # Keep log clean (last 50)
    if ($Elements.lstLog.Items.Count -gt 50) { $Elements.lstLog.Items.RemoveAt(0) }
}

function Check-Safety {
    # Scan A-Z (65-90) & 0-9 (48-57)
    $typing = (65..90 + 48..57) | Where-Object { [Win32Utils.Win32]::GetAsyncKeyState($_) -lt 0 }
    return ($typing.Count -gt 0)
}

function Set-Pulse($color) {
    try {
        $Elements.bdrPulse.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    }
    catch {}
}

# --- 6. TICKER LOOP ---
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromSeconds($Config.Interval)

$Timer.Add_Tick({
        if (-not $State.Running) { return }

        # 1. Get Active Window
        $hwnd = [Win32Utils.Win32]::GetForegroundWindow()
        $sb = New-Object System.Text.StringBuilder 256
        [Win32Utils.Win32]::GetWindowText($hwnd, $sb, 256) | Out-Null
        $activeTitle = $sb.ToString()

        # 2. Update UI (Passive)
        if ($activeTitle) {
            $Elements.lblDetails.Text = "Focus: $activeTitle"
        }

        # 3. Safety Check
        if (Check-Safety) {
            $Elements.lblState.Text = "⏸ PAUSED (USER INPUT)"
            $Elements.lblState.Foreground = [System.Windows.Media.Brushes]::Yellow
            Set-Pulse "#FFFF00"
            return
        }

        # 4. Target Match
        $match = $Config.Targets | Where-Object { $activeTitle -match $_ }
        if ($match) {
            # FIRE
            $Elements.lblState.Text = "⚡ ENGAGED: $match"
            $Elements.lblState.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            Set-Pulse "#00FF00"
        
            $State.wsh.SendKeys($Config.Keys)
            Add-Log "Auto-Accepted: $match" "#00FF00"
        
            # Debounce/Cooldown
            Start-Sleep -Milliseconds 500
        }
        else {
            $Elements.lblState.Text = "👀 SEARCHING..."
            $Elements.lblState.Foreground = [System.Windows.Media.Brushes]::DeepSkyBlue
            Set-Pulse "#007ACC"
        }
    })

# --- 7. EVENT BINDINGS ---

$Window.Add_MouseLeftButtonDown({ $this.DragMove() })
$Elements.btnClose.Add_Click({ $Window.Close() })

$Elements.btnToggle.Add_Click({
        $State.Running = -not $State.Running
        if ($State.Running) {
            $Elements.btnToggle.Content = "⏹ DEACTIVATE"
            $Elements.btnToggle.Foreground = [System.Windows.Media.Brushes]::Red
            $Elements.lblState.Text = "STARTED"
            Add-Log "Agent Activated" "#FFFFFF"
            $Timer.Start()
        }
        else {
            $Elements.btnToggle.Content = "▶ ACTIVATE AGENT"
            $Elements.btnToggle.Foreground = [System.Windows.Media.Brushes]::Gray
            $Elements.lblState.Text = "STANDBY"
            $Elements.lblState.Foreground = [System.Windows.Media.Brushes]::Gray
            Set-Pulse "#333333"
            Add-Log "Agent Stopped" "#888888"
            $Timer.Stop()
        }
    })

$Elements.chkOnTop.Add_Checked({ $Window.Topmost = $true })
$Elements.chkOnTop.Add_Unchecked({ $Window.Topmost = $false })

# --- 8. LAUNCH ---
Add-Log "OmniControl v2.0 Initialized"
$Window.ShowDialog() | Out-Null
