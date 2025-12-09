# Mock Target for OmniControl Testing
Add-Type -AssemblyName PresentationFramework

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AntiGravity Security Alert" Height="200" Width="300"
        Background="#252526">
    <StackPanel Margin="20" VerticalAlignment="Center">
        <TextBlock Text="Simulated Permission Request" Foreground="White" HorizontalAlignment="Center"/>
        
        <!-- TARGET BUTTON -->
        <Button Name="btnAccept" Content="Accept" Margin="0,20,0,0" Height="30" Background="#007ACC" Foreground="White"/>
        
        <TextBlock Name="lblStatus" Text="Waiting..." Foreground="#888" Margin="0,10,0,0" HorizontalAlignment="Center"/>
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)
$btn = $Window.FindName("btnAccept")
$lbl = $Window.FindName("lblStatus")

$btn.Add_Click({
        $lbl.Text = "CLICK RECEIVED!"
        $lbl.Foreground = "Green"
        [System.Windows.MessageBox]::Show("Auto-Click Verified!")
    })

$Window.ShowDialog()
