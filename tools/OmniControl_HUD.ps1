# --- OMNICONTROL V2.0: AUTO-AUTHORIZER ---
# Autor: Gemini | Fecha: 09/12/2025
# Nivel: UI Automation (Backend Click) + Keyboard Injection

# 1. CARGAR LIBRERÍAS DE AUTOMATIZACIÓN (El cerebro que "ve" los botones)
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing
}
catch {
    Write-Warning "Intentando cargar librerías WPF desde rutas estándar..."
    $WPFPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
    Add-Type -Path "$WPFPath\UIAutomationClient.dll"
    Add-Type -Path "$WPFPath\UIAutomationTypes.dll"
}

# 2. DEFINIR MOTOR HÍBRIDO (API + UI AUTOMATION)
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

        // FUNCIÓN CLAVE: Busca el botón dentro de la ventana y lo pulsa
        public static bool ClickAcceptButton(IntPtr hwnd) {
            try {
                if (hwnd == IntPtr.Zero) return false;
                
                // Conectamos con la ventana
                var root = AutomationElement.FromHandle(hwnd);
                if (root == null) return false;

                // Buscamos botones llamados "Accept all" o "Accept"
                // Usamos una condición OR para cubrir ambos casos
                var condNameAll = new PropertyCondition(AutomationElement.NameProperty, "Accept all");
                var condNameOne = new PropertyCondition(AutomationElement.NameProperty, "Accept");
                var condType = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button);
                
                var condFinal = new AndCondition(condType, new OrCondition(condNameAll, condNameOne));

                // Escaneo rápido (FindFirst es más eficiente que buscar todos)
                var element = root.FindFirst(TreeScope.Descendants, condFinal);

                if (element != null) {
                    // Si encontramos el botón, ejecutamos su patrón 'Invoke' (Clic sin mouse)
                    var invokePattern = element.GetCurrentPattern(InvokePattern.Pattern) as InvokePattern;
                    if (invokePattern != null) {
                        invokePattern.Invoke();
                        return true; // ¡Autorizado!
                    }
                }
            } catch (Exception) {
                // Silencioso si falla la lectura del árbol (común en apps Electron)
            }
            return false;
        }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]'OmniSystem.Backend').Type) {
        Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies UIAutomationClient, UIAutomationTypes
    }
}
catch { Write-Warning "Backend ya cargado. Continuando..." }

# 3. INTERFAZ GRÁFICA (HUD)
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniControl V2" Height="190" Width="350" 
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="#1E1E1E" Topmost="True" BorderBrush="#007ACC" BorderThickness="1">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
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
             <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.8"/>
                    <Setter Property="Cursor" Value="Hand"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> 
            <RowDefinition Height="*"/>    
            <RowDefinition Height="Auto"/> 
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0" LastChildFill="False">
            <TextBlock Text="👻 OmniControl V2.0" Foreground="#007ACC" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
            <Button Name="btnClose" Content="✕" Width="30" Height="25" DockPanel.Dock="Right" Background="Transparent" Foreground="#888"/>
        </DockPanel>

        <Border Grid.Row="1" Margin="0,15,0,15" Background="#252526" CornerRadius="6" BorderBrush="#333" BorderThickness="1">
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                <TextBlock Name="lblStatus" Text="SISTEMA LISTO" Foreground="#CCCCCC" FontSize="13" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock Name="lblDetail" Text="Esperando AntiGravity..." Foreground="#555555" FontSize="10" HorizontalAlignment="Center" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button Name="btnAction" Content="▶ ACTIVAR AUTORIZADOR" Height="40" Background="#2D8C3C" Margin="0,0,10,0"/>
            <CheckBox Name="chkOnTop" Content="📌" IsChecked="True" Foreground="White" VerticalAlignment="Center" Grid.Column="1"/>
        </Grid>
    </Grid>
</Window>
"@

# 4. INICIALIZACIÓN
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

$btnAction = $Window.FindName("btnAction")
$btnClose = $Window.FindName("btnClose")
$lblStatus = $Window.FindName("lblStatus")
$lblDetail = $Window.FindName("lblDetail")
$chkOnTop = $Window.FindName("chkOnTop")
$wsh = New-Object -ComObject WScript.Shell

$IsRunning = $false
$TargetTitle = "AntiGravity" 

# 5. TIMER INTELIGENTE
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(1200) # Frecuencia de escaneo

function Check-Typing {
    for ($i = 65; $i -le 90; $i++) { if ([OmniSystem.Backend]::GetAsyncKeyState($i) -lt 0) { return $true } } # A-Z
    for ($i = 48; $i -le 57; $i++) { if ([OmniSystem.Backend]::GetAsyncKeyState($i) -lt 0) { return $true } } # 0-9
    return $false
}

$Timer.Add_Tick({
        if (-not $IsRunning) { return }

        # A. Obtener Ventana
        $hwnd = [OmniSystem.Backend]::GetForegroundWindow()
        $sb = New-Object System.Text.StringBuilder 256
        [OmniSystem.Backend]::GetWindowText($hwnd, $sb, 256) | Out-Null
        $ActiveTitle = $sb.ToString()

        # B. Pausa si escribes
        if (Check-Typing) {
            $Script:IsRunning = $false
            $Timer.Stop()
            $btnAction.Content = "▶ REANUDAR"
            $btnAction.Background = "#D19A66"
            $lblStatus.Text = "⏸ PAUSA (Usuario escribiendo)"
            $lblStatus.Foreground = "#D19A66"
            return
        }

        # C. Lógica de Autorización
        if ($ActiveTitle -match $TargetTitle) {
        
            $lblStatus.Text = "⚡ ESCANEANDO UI..."
            $lblStatus.Foreground = "#00FF00"
            $lblDetail.Text = "Ventana: Detectada"

            # 1. DISPARO TECLADO (Para sugerencias en línea)
            $wsh.SendKeys("%~") 
        
            # 2. DISPARO UI AUTOMATION (Para botón 'Accept all')
            # Ejecutamos esto en un bloque try para no detener el script si falla el escaneo
            $clicked = $false
            try {
                # Intentamos invocar el botón directamente via UI Automation
                $clicked = [OmniSystem.Backend]::ClickAcceptButton($hwnd)
            }
            catch {}

            if ($clicked) {
                $lblStatus.Text = "✅ BOTÓN 'ACCEPT' PULSADO"
                $lblDetail.Text = "Autorización Backend Exitosa"
                # Si pulsamos botón, damos un respiro mayor
                $Timer.Interval = [TimeSpan]::FromMilliseconds(2000)
            }
            else {
                $lblStatus.Text = "⚡ AUTORIZANDO (ALT+ENTER)"
                $Timer.Interval = [TimeSpan]::FromMilliseconds(1500)
            }

        }
        else {
            $Timer.Interval = [TimeSpan]::FromMilliseconds(1000)
            $lblStatus.Text = "👁‍🗨 BUSCANDO ANTIGRAVITY..."
            $lblStatus.Foreground = "#007ACC"
            $lblDetail.Text = "Foco actual: $ActiveTitle"
        }
    })

# 6. EVENTOS
$btnAction.Add_Click({
        if ($IsRunning) {
            $Script:IsRunning = $false
            $Timer.Stop()
            $btnAction.Content = "▶ ACTIVAR AUTORIZADOR"
            $btnAction.Background = "#2D8C3C"
            $lblStatus.Text = "⛔ SISTEMA DETENIDO"
            $lblStatus.Foreground = "#FF4444"
        }
        else {
            $Script:IsRunning = $true
            $Timer.Start()
            $btnAction.Content = "⏹ DETENER"
            $btnAction.Background = "#C42B1C"
            $lblStatus.Text = "🚀 INICIANDO..."
            $lblStatus.Foreground = "#007ACC"
        }
    })

$btnClose.Add_Click({ $Timer.Stop(); $Window.Close() })
$chkOnTop.Add_Checked({ $Window.Topmost = $true })
$chkOnTop.Add_Unchecked({ $Window.Topmost = $false })
$Window.Add_MouseLeftButtonDown({ $this.DragMove() })

Write-Host "Cargando OmniControl V2..." -ForegroundColor Cyan
$Window.ShowDialog() | Out-Null
