$path = "C:\Users\Administrator\Desktop";
if (Test-Path $path) {
    Get-ChildItem $path -Force | Select-Object Name | Out-File "C:\AntiGravityExt\debug_output.txt" -Encoding ascii
} else {
    "Desktop not found" | Out-File "C:\AntiGravityExt\debug_output.txt" -Encoding ascii
}
