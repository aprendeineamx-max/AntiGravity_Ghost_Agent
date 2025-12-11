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

        // --- ZONE DATA ---
        public static int ZoneX = 0, ZoneY = 0, ZoneW = 9999, ZoneH = 9999;
        
        public static void UpdateZone(int x, int y, int w, int h) {
            ZoneX = x; ZoneY = y; ZoneW = w; ZoneH = h;
        }

        public static string ScanAndDestroy(string titlePart) {
            try {
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
                                 // Simple Intersection Check: Center Point
                                 double btnCX = btnRect.X + (btnRect.Width / 2);
                                 double btnCY = btnRect.Y + (btnRect.Height / 2);
                                 
                                 // Is Center inside Zone?
                                 if (btnCX < ZoneX || btnCX > (ZoneX + ZoneW) || 
                                     btnCY < ZoneY || btnCY > (ZoneY + ZoneH)) {
                                     continue; // IGNORE BUTTON OUTSIDE ZONE
                                 }
                             }
                             // -------------------

                             string name = btn.Current.Name;
                             if (!string.IsNullOrEmpty(name)) {
                                 bool match = false;
                                 if (name.IndexOf("Accept", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 else if (name.IndexOf("Allow", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 // else if (name.IndexOf("Setup", StringComparison.OrdinalIgnoreCase) >= 0) match = true;  <-- Desactivado por seguridad
                                 // Specific precise matches for tricky buttons
                                 else if (name.Contains("Accept all")) match = true;
                                 else if (name.Contains("AcceptAlt")) match = true; 
                                 
                                 // New Request: "Run Command" is dangerous if unchecked, but SAFE inside Zone
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

# 3. INTERFAZ XAML
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OmniControl HUD" Height="150" Width="300"
        WindowStyle="None" AllowsTransparency="True" Background="#222" Topmost="True">
    <StackPanel Margin="10">
        <TextBlock Text="👻 OMNICONTROL ACTIVE" Foreground="Cyan" FontWeight="Bold" HorizontalAlignment="Center"/>
        <TextBlock Name="lblStatus" Text="Scanning..." Foreground="#888" HorizontalAlignment="Center" Margin="0,10,0,0"/>
        <TextBlock Name="lblZone" Text="Zone: Global" Foreground="Gray" FontSize="10" HorizontalAlignment="Center" Margin="0,5,0,0"/>
        <Button Name="btnExit" Content="EXIT" Background="#444" Foreground="White" Margin="0,20,0,0"/>
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)
$Window.Left = [System.Windows.SystemParameters]::PrimaryScreenWidth - 320
$Window.Top = 10

# CONTROLS
$lblStatus = $Window.FindName("lblStatus")
$lblZone = $Window.FindName("lblZone")
$btnExit = $Window.FindName("btnExit")
$btnExit.Add_Click({ $Window.Close() })

# MAIN LOOP
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(500)
$Timer.Add_Tick({
        # 1. READ OMNIGOD LIVE ZONE
        $IniPath = Join-Path (Get-Location) "..\OmniBot\OmniGod_Live.ini"
        if (Test-Path $IniPath) {
            $GX = 0; $GY = 0; $GW = 0; $GH = 0;
        
            # Simple Regex Parsing (faster than INI libraries in pure PS loop)
            $Content = Get-Content $IniPath -Raw
            if ($Content -match "GlobalX=(\d+)") { $GX = [int]$Matches[1] }
            if ($Content -match "GlobalY=(\d+)") { $GY = [int]$Matches[1] }
            if ($Content -match "GlobalW=(\d+)") { $GW = [int]$Matches[1] }
            if ($Content -match "GlobalH=(\d+)") { $GH = [int]$Matches[1] }
        
            if ($GW -gt 0) {
                [OmniSystem.Backend]::UpdateZone($GX, $GY, $GW, $GH)
                $lblZone.Text = "Zone: Active [$GX, $GY] ${GW}x${GH}"
                $lblZone.Foreground = "Cyan"
            }
            else {
                $lblZone.Text = "Zone: Waiting for OmniGod..."
                $lblZone.Foreground = "Gray"
            }
        }
        else {
            $lblZone.Text = "Zone: OFFLINE (No INI)"
            $lblZone.Foreground = "Red"
        }

        # 2. EXECUTE SCAN
        $Result = [OmniSystem.Backend]::ScanAndDestroy("AntiGravity")
    
        if ($Result -match "CLICKED") {
            $lblStatus.Text = $Result
            $lblStatus.Foreground = "Lime"
        }
        else {
            $lblStatus.Text = $Result ; Scanning...
            $lblStatus.Foreground = "#888"
        }
    })

$Timer.Start()
$Window.ShowDialog() | Out-Null
