# --- OMNICONTROL V3.2: UNIVERSAL SOLDIER ---
# Autor: Gemini | Fecha: 09/12/2025
# Fixes: Fuzzy Match logic for "Accept" buttons + Aggressive Keyboard fallback

# 1. LIMPIEZA
$ErrorActionPreference = "SilentlyContinue"

# 2. CARGA DE LIBRERÍAS
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing
}
catch {
    $WPFPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
    Add-Type -Path "$WPFPath\UIAutomationClient.dll"
    Add-Type -Path "$WPFPath\UIAutomationTypes.dll"
}

# 3. MOTOR BACKEND REESCRITO (Lógica "Contains")
$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation;
using System.Collections.Generic;

namespace OmniSystem {
    public class Backend {
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);

        private static AutomationElement _cachedWindow = null;

        public static AutomationElement GetTargetWindow(string titlePart) {
            if (_cachedWindow != null) {
                try { if (_cachedWindow.Current.Name.Contains(titlePart)) return _cachedWindow; } 
                catch { _cachedWindow = null; }
            }
            var root = AutomationElement.RootElement;
            var winCond = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Window);
            var windows = root.FindAll(TreeScope.Children, winCond);
            foreach (AutomationElement win in windows) {
                if (win.Current.Name.Contains(titlePart)) {
                    _cachedWindow = win;
                    return win;
                }
            }
            return null;
        }

        public static string ScanAndDestroy(string titlePart) {
            try {
                var win = GetTargetWindow(titlePart);
                if (win == null) return "Searching...";

                // ESTRATEGIA DE BARRIDO TOTAL
                // Obtenemos TODOS los botones y links, luego filtramos por texto
                var condBtn = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button);
                
                // Buscamos todos los botones en la interfaz (Deep Scan)
                var col = win.FindAll(TreeScope.Descendants, condBtn);

                foreach (AutomationElement element in col) {
                    string name = element.Current.Name;
                    
                    // FILTRO FUZZY: Si contiene "Accept" (mayus/minus/espacios)
                    if (!string.IsNullOrEmpty(name) && name.IndexOf("Accept", StringComparison.OrdinalIgnoreCase) >= 0) {
                        
                        object patternObj;
                        if (element.TryGetCurrentPattern(InvokePattern.Pattern, out patternObj)) {
                            ((InvokePattern)patternObj).Invoke();
                            return "CLICKED: " + name;
                        }
                    }
                }
            } catch (Exception ex) { return "Error: " + ex.Message; }
            return "Scanning UI...";
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

# 4. INTERFAZ GRÁFICA
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OmniControl V3.2" Height="240" Width="380" 
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="#1E1E1E" Topmost="True" BorderBrush="#007ACC" BorderThickness="1">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#333"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> 
            <RowDefinition Height="Auto"/> 
            <RowDefinition Height="*"/>    
            <RowDefinition Height="Auto"/> 
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0" LastChildFill="False">
            <TextBlock Text="👻 OmniControl V3.2 (UNIVERSAL)" Foreground="#007ACC" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
            <Button Name="btnClose" Content="✕" Width="30" Height="25" DockPanel.Dock="Right" Background="Transparent" Foreground="#888"/>
        </DockPanel>

        <Border Grid.Row="1" Margin="0,10,0,5" Background="#111" CornerRadius="4" BorderBrush="#007ACC" BorderThickness="0,0,0,2">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="5">
                <TextBlock Text="HIT COUNT: " Foreground="#888" FontSize="12" VerticalAlignment="Center"/>
                <TextBlock Name="lblCounter" Text="0" Foreground="#00FF00" FontSize="18" FontWeight="Bold" VerticalAlignment="Center" Margin="5,0,0,0"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Margin="0,5,0,15" Background="#252526" CornerRadius="6" BorderBrush="#333" BorderThickness="1">
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                <TextBlock Name="lblStatus" Text="READY" Foreground="#CCCCCC" FontSize="13" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock Name="lblDetail" Text="Esperando ejecución..." Foreground="#555555" FontSize="10" HorizontalAlignment="Center" Margin="0,5,0,0" TextTrimming="CharacterEllipsis" MaxWidth="300"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions> <ColumnDefinition Width="*"/> <ColumnDefinition Width="Auto"/> </Grid.ColumnDefinitions>
            <Button Name="btnAction" Content="▶ INICIAR" Height="40" Background="#2D8C3C" Margin="0,0,10,0"/>
            <CheckBox Name="chkOnTop" Content="📌" IsChecked="True" Foreground="White" VerticalAlignment="Center" Grid.Column="1"/>
        </Grid>
    </Grid>
</Window>
"@

# 5. CONFIGURACIÓN
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

$btnAction = $Window.FindName("btnAction")
$btnClose = $Window.FindName("btnClose")
$lblStatus = $Window.FindName("lblStatus")
$lblDetail = $Window.FindName("lblDetail")
$lblCounter = $Window.FindName("lblCounter")
$chkOnTop = $Window.FindName("chkOnTop")
$wsh = New-Object -ComObject WScript.Shell

$IsRunning = $false
$TargetTitle = "AntiGravity"
$TotalAuths = 0
$LogPath = "$([Environment]::GetFolderPath('Desktop'))\OmniLog.txt"

function Write-Log {
    param($Msg)
    $Line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Msg
    try { Add-Content -Path $LogPath -Value $Line } catch {}
}

# 6. FILTRO DE TECLADO (A-Z, 0-9)
function Check-Typing {
    for ($i = 65; $i -le 90; $i++) { if ([OmniSystem.Backend]::GetAsyncKeyState($i) -lt 0) { return $true } }
    for ($i = 48; $i -le 57; $i++) { if ([OmniSystem.Backend]::GetAsyncKeyState($i) -lt 0) { return $true } }
    return $false
}

# 7. TIMER PRINCIPAL
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(500) # Escaneo agresivo

$Timer.Add_Tick({
        if (-not $IsRunning) { return }

        # Detectar entorno
        $hwnd = [OmniSystem.Backend]::GetForegroundWindow()
        $sb = New-Object System.Text.StringBuilder 256
        [OmniSystem.Backend]::GetWindowText($hwnd, $sb, 256) | Out-Null
        $ActiveTitle = $sb.ToString()
        $InAntiGravity = $ActiveTitle -match $TargetTitle

        # PAUSA INTELIGENTE
        if ($InAntiGravity -and (Check-Typing)) {
            $Script:IsRunning = $false
            $Timer.Stop()
            $btnAction.Content = "▶ REANUDAR"
            $btnAction.Background = "#D19A66"
            $lblStatus.Text = "⏸ PAUSA POR ESCRITURA"
            $lblDetail.Text = "Reanuda cuando termines de escribir..."
            return
        }

        # -- ESTRATEGIA HÍBRIDA --
    
        # 1. ATAQUE FRONTAL (TECLADO) - Solo si tenemos foco
        # Esto soluciona que "no haga nada aun estando activo"
        if ($InAntiGravity) {
            $wsh.SendKeys("%~") # ALT + ENTER
        }

        # 2. ATAQUE TRASERO (UI AUTOMATION) - Funciona en segundo plano
        $result = [OmniSystem.Backend]::ScanAndDestroy($TargetTitle)
    
        if ($result -match "CLICKED") {
            # Éxito Backend
            $Script:TotalAuths++
            $lblCounter.Text = "$Script:TotalAuths"
            $lblStatus.Text = "✅ OBJETIVO ELIMINADO"
            $lblStatus.Foreground = "#00FF00"
            $lblDetail.Text = $result
            Write-Log $result
            $Timer.Interval = [TimeSpan]::FromMilliseconds(1500) # Breve descanso
        }
        else {
            # Nada encontrado por Backend
            $lblDetail.Text = $result
            if ($InAntiGravity) {
                $lblStatus.Text = "⚡ MODO ACTIVO (ALT+ENTER)"
                $lblStatus.Foreground = "#00FFFF" # Cyan
            }
            else {
                $lblStatus.Text = "👁‍🗨 ESCANEANDO FONDO..."
                $lblStatus.Foreground = "#007ACC" # Azul
            }
            $Timer.Interval = [TimeSpan]::FromMilliseconds(800)
        }
    })

# 8. EVENTOS
$btnAction.Add_Click({
        if ($IsRunning) {
            $Script:IsRunning = $false
            $Timer.Stop()
            $btnAction.Content = "▶ INICIAR"
            $btnAction.Background = "#2D8C3C"
            $lblStatus.Text = "⛔ DETENIDO"
            $lblStatus.Foreground = "#FF4444"
        }
        else {
            $Script:IsRunning = $true
            $Timer.Start()
            $btnAction.Content = "⏹ DETENER"
            $btnAction.Background = "#C42B1C"
            $lblStatus.Text = "🚀 ESCANER INICIADO"
            $lblStatus.Foreground = "#007ACC"
            Write-Log "Iniciado."
        }
    })

$btnClose.Add_Click({ $Timer.Stop(); $Window.Close() })
$chkOnTop.Add_Checked({ $Window.Topmost = $true })
$chkOnTop.Add_Unchecked({ $Window.Topmost = $false })
$Window.Add_MouseLeftButtonDown({ $this.DragMove() })

Write-Host "Iniciando V3.2..." -ForegroundColor Green
$Window.ShowDialog() | Out-Null
