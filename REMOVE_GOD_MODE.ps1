# --- CLEANER: REMOVE GOD MODE INJECTION ---
$PosiblesRutas = @(
    "$env:LOCALAPPDATA\Programs\AntiGravity",
    "$env:PROGRAMFILES\AntiGravity",
    "$env:APPDATA\AntiGravity",
    "$env:LOCALAPPDATA\Programs\cursor",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
)

$TargetDir = $null
foreach ($ruta in $PosiblesRutas) {
    if (Test-Path $ruta) {
        $Busqueda = Get-ChildItem -Path $ruta -Filter "workbench.html" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Busqueda) { $TargetDir = $Busqueda.DirectoryName; break }
    }
}

if ($TargetDir) {
    $JsFile = "$TargetDir\workbench.js"
    $Backup = "$JsFile.original"

    if (Test-Path $Backup) {
        Copy-Item $Backup $JsFile -Force
        Write-Host "✅ GOD MODE ELIMINADO. Archivo original restaurado." -ForegroundColor Green
        Write-Host "Por favor, reinicia AntiGravity para ver los cambios." -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ No se encontró backup (.original). Intentando limpieza manual..." -ForegroundColor Yellow
        $Content = Get-Content $JsFile -Raw
        if ($Content -match "GOD MODE V4") {
            # Simple replace to empty string or you might need a regex if complex
            # For safety, let's just warn user if no backup
            Write-Host "❌ No puedo restaurar sin backup. Reinstala AntiGravity si persiste." -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ No se encontró la instalación." -ForegroundColor Red
}
Pause
