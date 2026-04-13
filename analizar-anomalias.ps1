# Detectar anomalías en las partituras

$issues = @{
    "Metadata_No_Limpiados" = @()
    "Capo_Duplicado" = @()
    "Capo_Inconsistente" = @()
    "Capo_Solto" = @()
    "Archivos_Muy_Cortos" = @()
    "Secciones_Sin_Etiquetar" = @()
}

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $lines = @(Get-Content -Path $file.FullName)
    $content = Get-Content -Path $file.FullName -Raw
    
    # 1. Detectar metadatos no limpiados
    if ($content -match "^(?:ARTISTA|CANCIÓN|Artista:|Canción:)" ) {
        $issues["Metadata_No_Limpiados"] += $file.Name
    }
    
    # 2. Detectar CEJILLA/CAPO duplicadas
    $capoCount = @($content -split "`n" | Where-Object { $_ -match "^CEJILLA|^Capo\s+[0-9]|^CAPO\s+" }).Count
    if ($capoCount -gt 1) {
        $issues["Capo_Duplicado"] += $file.Name
    }
    
    # 3. Detectar formatos inconsistentes de capo
    if ($content -match "CEJILLA/CAPO:\s*[0-9](?!\s*\||CAPO)") {
        $issues["Capo_Inconsistente"] += $file.Name
    }
    
    # 4. Detectar líneas "Capo" sueltas (fuera de CEJILLA/CAPO)
    if ($content -match "^Capo\s+[0-9]" -and $content -notmatch "^CEJILLA/CAPO:.*Capo") {
        $issues["Capo_Solto"] += $file.Name
    }
    
    # 5. Archivos muy cortos (<10 líneas útiles)
    if ($lines.Count -lt 10) {
        $issues["Archivos_Muy_Cortos"] += $file.Name
    }
}

Write-Host "=== ANÁLISIS DE ANOMALÍAS ===" -ForegroundColor Cyan
Write-Host ""

foreach ($issueType in $issues.Keys) {
    $count = $issues[$issueType].Count
    if ($count -gt 0) {
        Write-Host "$issueType : $count archivos" -ForegroundColor Yellow
        $issues[$issueType] | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
        if ($count -gt 5) {
            Write-Host "  ... y $($count - 5) más"
        }
    }
}
