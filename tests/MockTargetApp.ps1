# Mock Target for OmniControl Testing (Debug Mode)
$LogFile = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\tests\mock_debug.log"
"Starting Mock App..." | Out-File $LogFile

try {
    Add-Type -AssemblyName PresentationFramework
    "WPF Loaded." | Out-File $LogFile -Append
}
catch {
    "FATAL: WPF Load Failed - $_" | Out-File $LogFile -Append
    exit
}

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AntiGravity Security Alert" Height="300" Width="400"
        Background="#252526" Topmost="True">
    <StackPanel Margin="20" VerticalAlignment="Center">
        <TextBlock Text="Simulated Permission Request" Foreground="White" HorizontalAlignment="Center" FontSize="16"/>
        <Button Name="btnAccept" Content="Accept" Margin="0,30,0,0" Height="40" Background="#007ACC" Foreground="White" FontSize="14"/>
        <TextBlock Name="lblStatus" Text="Waiting..." Foreground="#888" Margin="0,10,0,0" HorizontalAlignment="Center"/>
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)
$btn = $Window.FindName("btnAccept")
$lbl = $Window.FindName("lblStatus")

$btn.Add_Click({
        "CLICK RECEIVED: $(Get-Date)" | Out-File $LogFile -Append
        "SUCCESS: Button Clicked" | Out-File "C:\AntiGravityExt\AntiGravity_Ghost_Agent\tests\mock_status.txt"
        $Window.Close()
    })

"UI Ready. Showing Window..." | Out-File $LogFile -Append
$Window.ShowDialog() | Out-Null
"Window Closed." | Out-File $LogFile -Append
