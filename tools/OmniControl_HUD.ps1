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

namespace OmniSystem {
    public class Backend {
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);

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
                             string name = btn.Current.Name;
                             if (!string.IsNullOrEmpty(name)) {
                                 bool match = false;
                                 if (name.IndexOf("Accept", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 else if (name.IndexOf("Allow", StringComparison.OrdinalIgnoreCase) >= 0) match = true;
                                 // else if (name.IndexOf("Setup", StringComparison.OrdinalIgnoreCase) >= 0) match = true;  <-- Desactivado por seguridad
                                 // else if (name.IndexOf("Run command", StringComparison.OrdinalIgnoreCase) >= 0) match = true; <-- CULPABLE DE CLICS EN IDE
                                 // Specific precise matches for tricky buttons
                                 else if (name.Contains("Accept all")) match = true;
                                 else if (name.Contains("AcceptAlt")) match = true; 

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
        Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies UIAutomationClient, UIAutomationTypes
    }
}
catch { }

# 3. INTERFAZ XAML
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OmniControl HUD" Height="150" Width="300"
        WindowStyle="None" AllowsTransparency="True" Background="#222" Topmost="True">
    <StackPanel Margin="10">
        <TextBlock Text="👻 OMNICONTROL ACTIVE" Foreground="Cyan" FontWeight="Bold" HorizontalAlignment="Center"/>
        <TextBlock Name="lblStatus" Text="Scanning..." Foreground="#888" HorizontalAlignment="Center" Margin="0,10,0,0"/>
        <Button Name="btnExit" Content="EXIT" Background="#444" Foreground="White" Margin="0,20,0,0"/>
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)
$lblStatus = $Window.FindName("lblStatus")
$btnExit = $Window.FindName("btnExit")

# 4. LOGIC LOOP
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(1000)
$Timer.Add_Tick({
        $res = [OmniSystem.Backend]::ScanAndDestroy("AntiGravity")
        $lblStatus.Text = $res
        if ($res -like "CLICKED*") { $lblStatus.Foreground = "Green" }
        else { $lblStatus.Foreground = "#888" }
    })

$btnExit.Add_Click({ $Window.Close() })

$Timer.Start()
$Window.ShowDialog() | Out-Null
