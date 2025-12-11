# --- OMNICONTROL V3.2: UNIVERSAL SOLDIER (REPAIRED) ---
# Autor: Gemini | Fecha: 09/12/2025
# Fixes: Syntax errors, cleaner Header

$ErrorActionPreference = "SilentlyContinue"

# 1. CARGA DE LIBRERÍAS
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    $WPFPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
    try {
        Add-Type -Path "$WPFPath\UIAutomationClient.dll"
        Add-Type -Path "$WPFPath\UIAutomationTypes.dll"
    }
    catch {}
}

# 2. MOTOR BACKEND
$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation;
using System.Windows; 

namespace OmniSystem {
    public class Backend {
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
        [DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime;
        }

        // --- ZONE DATA ---
        public static int ZoneX = 0, ZoneY = 0, ZoneW = 9999, ZoneH = 9999;
        
        public static void UpdateZone(int x, int y, int w, int h) {
            ZoneX = x; ZoneY = y; ZoneW = w; ZoneH = h;
        }

        public static bool IsUserIdle(int thresholdMs) {
            var lastInput = new LASTINPUTINFO();
            lastInput.cbSize = (uint)Marshal.SizeOf(lastInput);
            if (!GetLastInputInfo(ref lastInput)) return false; // Fail safe
            
            uint idleTime = (uint)Environment.TickCount - lastInput.dwTime;
            return idleTime > thresholdMs;
        }

        public static string ScanAndDestroy(string titlePart) {
            try {
                // --- SMART TYPING CHECK ---
                // Si el usuario escribió hace menos de 2000ms, NO HACER NADA.
                if (!IsUserIdle(2000)) {
                    return "PAUSED: TYPING..."; 
                }

                var root = AutomationElement.RootElement;
                var winCond = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Window);
                var windows = root.FindAll(TreeScope.Children, winCond);
                
                foreach (AutomationElement win in windows) {
                    if (win.Current.Name.Contains(titlePart)) {
                        // FOUND WINDOW, SCAN FOR BUTTONS
                         var btnCond = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button);
                         var buttons = win.FindAll(TreeScope.Descendants, btnCond);
                         
                         foreach (AutomationElement btn in buttons) {
                             // --- ZONE FILTER ---
                             if (ZoneW > 0 && ZoneH > 0) {
                                 Rect btnRect = btn.Current.BoundingRectangle;
                                 double btnCX = btnRect.X + (btnRect.Width / 2);
                                 double btnCY = btnRect.Y + (btnRect.Height / 2);
                                 
                                 if (btnCX < ZoneX || btnCX > (ZoneX + ZoneW) || 
                                     btnCY < ZoneY || btnCY > (ZoneY + ZoneH)) {
                                     continue; // IGNORE BUTTON OUTSIDE ZONE
                                 }
                             }

                             string name = btn.Current.Name;
                             if (!string.IsNullOrEmpty(name)) {
                                 bool match = false;
                                 if (name.IndexOf("Accept", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 else if (name.IndexOf("Allow", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 else if (name.Contains("Accept all")) match = true;
                                 else if (name.Contains("AcceptAlt")) match = true; 
                                 else if (name.IndexOf("Run command", StringComparison.OrdinalIgnoreCase) >= 0) match = true;

                                 if (match) {
                                     var invoke = btn.GetCurrentPattern(InvokePattern.Pattern) as InvokePattern;
                                     if (invoke != null) {
                                         invoke.Invoke();
                                         return "CLICKED: " + name;
                                     }
                                 }
                             }
                         }
                    }
                }
            } catch {}
            return "Scanning...";
        }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]'OmniSystem.Backend').Type) {
        Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies UIAutomationClient, UIAutomationTypes, WindowsBase
    }
}
catch { 
    Write-Host "Error compiling C# Backend: $_" 
}

# 3. INTERFAZ XAML (MODERN GLASS UI)
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniControl HUD" Height="220" Width="340"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" Topmost="True" ResizeMode="NoResize">
    
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#33FFFFFF"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#44FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#22FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="12" Background="#F2121212" BorderBrush="#33FFFFFF" BorderThickness="1" Margin="10">
        <Border.Effect>
            <DropShadowEffect BlurRadius="20" ShadowDepth="5" Opacity="0.6" Color="Black"/>
        </Border.Effect>
        
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <!-- Header -->
                <RowDefinition Height="Auto"/> <!-- Status Block -->
                <RowDefinition Height="*"/>    <!-- Zone Info -->
                <RowDefinition Height="Auto"/> <!-- Footer -->
            </Grid.RowDefinitions>

            <!-- Header -->
            <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,10">
                <TextBlock Text="[+]" Foreground="#00E5FF" FontSize="14" Margin="0,0,6,0" VerticalAlignment="Center"/>
                <TextBlock Text="OMNICONTROL" Foreground="White" FontWeight="Bold" FontSize="13" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBlock Text="HUD" Foreground="#888" FontWeight="Regular" FontSize="13" Margin="5,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- Status Block -->
            <Border Grid.Row="1" Background="#1AFFFFFF" CornerRadius="8" Padding="12,8" Margin="0,5">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Ellipse Name="statusDot" Grid.Column="0" Width="10" Height="10" Fill="#555" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <TextBlock Name="lblStatus" Grid.Column="1" Text="Initializing..." Foreground="#DDD" FontSize="11" 
                               TextTrimming="CharacterEllipsis" VerticalAlignment="Center" ToolTip="{Binding Text, RelativeSource={RelativeSource Self}}"/>
                </Grid>
            </Border>

            <!-- Zone Info -->
            <StackPanel Grid.Row="2" VerticalAlignment="Center" Margin="0,10">
                <TextBlock Text="ACTIVE ZONE LOCK" Foreground="#666" FontSize="9" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock Name="lblZone" Text="Wait..." Foreground="#00E5FF" FontSize="11" FontWeight="SemiBold" 
                           HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap" Margin="0,2,0,0"/>
            </StackPanel>

            <!-- Footer -->
            <Button Name="btnExit" Grid.Row="3" Content="DISCONNECT" Style="{StaticResource ModernBtn}" Margin="0,5,0,0"/>
        </Grid>
    </Border>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)
$Window.Left = [System.Windows.SystemParameters]::PrimaryScreenWidth - 360
$Window.Top = 20

# CONTROLS
$lblStatus = $Window.FindName("lblStatus")
$lblZone = $Window.FindName("lblZone")
$statusDot = $Window.FindName("statusDot")
$btnExit = $Window.FindName("btnExit")

$btnExit.Add_Click({ $Window.Close() })

# MAIN LOOP
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(500)
$Timer.Add_Tick({
        # 1. READ OMNIGOD LIVE ZONE
        # Fix: Use PSScriptRoot for reliable path resolution
        $ScriptRoot = $PSScriptRoot
        if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    
        $IniPath = Join-Path $ScriptRoot "..\OmniBot\OmniGod_Live.ini"
    
        if (Test-Path $IniPath) {
            $GX = 0; $GY = 0; $GW = 0; $GH = 0;
        
            $Content = Get-Content $IniPath -Raw
            if ($Content -match "GlobalX=(\d+)") { $GX = [int]$Matches[1] }
            if ($Content -match "GlobalY=(\d+)") { $GY = [int]$Matches[1] }
            if ($Content -match "GlobalW=(\d+)") { $GW = [int]$Matches[1] }
            if ($Content -match "GlobalH=(\d+)") { $GH = [int]$Matches[1] }
        
            if ($GW -gt 0) {
                [OmniSystem.Backend]::UpdateZone($GX, $GY, $GW, $GH)
                $lblZone.Text = "LOCKED [${GX}, ${GY}] : ${GW}x${GH}px"
                $lblZone.Foreground = "#00E5FF" # Cyan
            }
            else {
                $lblZone.Text = "Searching for OmniGod Signal..."
                $lblZone.Foreground = "#777"
            }
        }
        else {
            $lblZone.Text = "OFFLINE"
            $lblZone.Foreground = "#FF5555" # Soft Red
        }

        # 2. EXECUTE SCAN
        $Result = [OmniSystem.Backend]::ScanAndDestroy("AntiGravity")
    
        if ($Result -match "CLICKED") {
            $lblStatus.Text = $Result
            $statusDot.Fill = "#00FF00" # Lime
        }
        elseif ($Result -match "PAUSED") {
            $lblStatus.Text = $Result
            $statusDot.Fill = "#FF8C00" # Dark Orange
        }
        else {
            $lblStatus.Text = $Result
            if ($Result -match "Scanning") {
                $statusDot.Fill = "#FFC107" # Amber (Standby)
            }
            else {
                $statusDot.Fill = "#555"
            }
        }
    })

$Timer.Start()
$Window.ShowDialog() | Out-Null
