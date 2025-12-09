# --- OMNICONTROL V2.1: REFACTORED HYBRID ---
# Status: Production Ready | Logic: Modularized

# --- 0. BOOTSTRAP LIBRARIES ---
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing
}
catch {
    Write-Warning "System assemblies missing. UI Automation features may fail."
}

# --- 1. BACKEND ENGINE (C#) ---
$BackendSource = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation; 
using System.Collections.Generic;

namespace OmniInternal {
    public class Core {
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);

        public static string GetActiveTitle() {
            var hwnd = GetForegroundWindow();
            var sb = new StringBuilder(256);
            GetWindowText(hwnd, sb, 256);
            return sb.ToString();
        }

        public static bool IsTyping() {
            // Check A-Z and 0-9
            for (int i = 65; i <= 90; i++) if (GetAsyncKeyState(i) < 0) return true;
            for (int i = 48; i <= 57; i++) if (GetAsyncKeyState(i) < 0) return true;
            return false;
        }

        public static bool TryClickAccept(IntPtr hwnd) {
            if (hwnd == IntPtr.Zero) return false;
            try {
                var root = AutomationElement.FromHandle(hwnd);
                if (root == null) return false;

                // Define search conditions for "Accept" buttons
                var conditions = new OrCondition(
                    new PropertyCondition(AutomationElement.NameProperty, "Accept"),
                    new PropertyCondition(AutomationElement.NameProperty, "Accept all"),
                    new PropertyCondition(AutomationElement.NameProperty, "Allow"),
                    new PropertyCondition(AutomationElement.NameProperty, "Yes"),
                    new PropertyCondition(AutomationElement.NameProperty, "Confirmar")
                );

                var buttonCond = new AndCondition(
                    new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button),
                    conditions
                );

                var element = root.FindFirst(TreeScope.Descendants, buttonCond);
                if (element != null) {
                    var invoke = element.GetCurrentPattern(InvokePattern.Pattern) as InvokePattern;
                    invoke?.Invoke();
                    return true;
                }
            } catch { /* Silent Fail */ }
            return false;
        }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]'OmniInternal.Core').Type) {
        Add-Type -TypeDefinition $BackendSource -Language CSharp -ReferencedAssemblies UIAutomationClient, UIAutomationTypes
    }
}
catch { Write-Warning "Backend load skipped (Type exists)." }

# --- 2. CONFIGURATION ---
$Config = @{
    TargetTitle = "AntiGravity"
    ScanRate    = 1000 # ms
}

# --- 3. UI DEFINITION (XAML) ---
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OmniControl HUD" Height="200" Width="320" 
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="#121212" Topmost="True" BorderBrush="#444" BorderThickness="1">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="30"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <DockPanel Grid.Row="0" LastChildFill="False">
            <TextBlock Text="COVERT OPS: OMNICONTROL" Foreground="#666" FontWeight="Bold" FontFamily="Consolas" VerticalAlignment="Center"/>
            <Button Name="btnClose" Content="X" Width="20" Background="Transparent" Foreground="#888" DockPanel.Dock="Right" FontWeight="Bold"/>
        </DockPanel>

        <!-- Status Screen -->
        <Border Grid.Row="1" Background="#000" BorderBrush="#222" BorderThickness="1" Margin="0,5">
            <StackPanel VerticalAlignment="Center">
                <TextBlock Name="lblState" Text="STANDBY" Foreground="#555" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock Name="lblMeta" Text="Waiting for target..." Foreground="#333" FontSize="10" HorizontalAlignment="Center" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <!-- Action Bar -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions> <ColumnDefinition Width="*"/> <ColumnDefinition Width="30"/> </Grid.ColumnDefinitions>
            <Button Name="btnToggle" Content="ENGAGE SYSTEM" Height="30" Background="#222" Foreground="#888" FontWeight="Bold"/>
            <CheckBox Name="chkTop" IsChecked="True" Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right" Content="📌" Foreground="#444"/>
        </Grid>
    </Grid>
</Window>
"@

# --- 4. CONTROLLER LOGIC ---
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# UI Bindings
$UI = @{}
"btnClose", "lblState", "lblMeta", "btnToggle", "chkTop" | ForEach-Object { $UI[$_] = $Window.FindName($_) }

$Runtime = @{
    Active = $false
    wsh    = New-Object -ComObject WScript.Shell
}

# Timer Loop
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds($Config.ScanRate)

$Timer.Add_Tick({
        if (-not $Runtime.Active) { return }

        # 1. State Check: Typing?
        if ([OmniInternal.Core]::IsTyping()) {
            $UI.lblState.Text = "PAUSED"
            $UI.lblState.Foreground = [System.Windows.Media.Brushes]::Orange
            $UI.lblMeta.Text = "User input detected"
            return
        }

        # 2. Get Context
        $hwnd = [OmniInternal.Core]::GetForegroundWindow()
        $title = [OmniInternal.Core]::GetActiveTitle()

        # 3. Decision Matrix
        if ($title -match $Config.TargetTitle) {
            $UI.lblState.Text = "TARGET LOCKED"
            $UI.lblState.Foreground = [System.Windows.Media.Brushes]::Green
        
            # Action A: UI Automation
            $clicked = [OmniInternal.Core]::TryClickAccept($hwnd)
        
            # Action B: Keyboard (Fallback) if needed
            if ($clicked) {
                $UI.lblMeta.Text = "Action: Button Clicked via API"
            }
            else {
                $Runtime.wsh.SendKeys("%~")
                $UI.lblMeta.Text = "Action: Key Injection (Alt+Enter)"
            }
        }
        else {
            $UI.lblState.Text = "SCANNING"
            $UI.lblState.Foreground = [System.Windows.Media.Brushes]::Cyan
            $UI.lblMeta.Text = "Focus: $title"
        }
    })

# Events
$UI.btnToggle.Add_Click({
        $Runtime.Active = -not $Runtime.Active
        if ($Runtime.Active) {
            $UI.btnToggle.Content = "DISENGAGE"
            $UI.btnToggle.Background = "#330000"
            $UI.btnToggle.Foreground = "Red"
            $Timer.Start()
        }
        else {
            $UI.btnToggle.Content = "ENGAGE SYSTEM"
            $UI.btnToggle.Background = "#222"
            $UI.btnToggle.Foreground = "#888"
            $Timer.Stop()
            $UI.lblState.Text = "STANDBY"
            $UI.lblState.Foreground = "#555"
        }
    })

$UI.btnClose.Add_Click({ $Window.Close() })
$UI.chkTop.Add_Checked({ $Window.Topmost = $true })
$UI.chkTop.Add_Unchecked({ $Window.Topmost = $false })
$Window.Add_MouseLeftButtonDown({ $this.DragMove() })

$Window.ShowDialog() | Out-Null
