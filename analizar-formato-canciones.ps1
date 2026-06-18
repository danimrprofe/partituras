# Analizar formato de nombres de canciones
$partiturasDir = ".\partituras"
$issues = @()

Get-ChildItem $partiturasDir -File | ForEach-Object {
    $filename = $_.Name
    $name = $_.BaseName
    $ext = $_.Extension
    
    # Definir criterios para formato correcto
    # Debe ser: Artist Name - Song Title.txt o .md
    
    $problems = @()
    
    # 1. Verificar que NO sea .html, .json, etc
    if ($ext -notin @('.txt', '.md')) {
        $problems += "Extensión no permitida: $ext"
    }
    
    # 2. Verificar que contenga guión separador " - "
    if ($name -notmatch ' - ') {
        $problems += "Falta el separador ' - ' entre artista y canción"
    }
    
    # 3. Verificar que no sea un archivo especial (sin artista)
    if ($name -in @('frozen', 'hero of war', 'toy story', 'vaiana', 'quan somrius', 
                    'tot el que vull per nadal', 'eels - end times')) {
        if ($name -notmatch ' - ') {
            $problems += "Archivo sin identificador de artista"
        }
    }
    
    # 4. Detectar información extra en el nombre (palabras como "Tabs", "Tablatures", etc)
    if ($name -match 'Tabs|Tablatures|Lyrics|Chords|Guitar|Bass|Tab Power') {
        $problems += "Contiene información extra (Tabs/Tablatures/etc)"
    }
    
    # 5. Detectar guiones múltiples o espacios raros
    if ($name -match ' -  -|--|-{2,}') {
        $problems += "Guiones múltiples o mal formados"
    }
    
    # 6. Detectar formato numérico repetido (alternativas)
    if ($name -match '\(alt\)|\(alt \d\)') {
        $problems += "Contiene marcador de alternativa (alt)"
    }
    
    # 7. Detectar "Sin titulo" 
    if ($name -match 'Sin titulo|Sin Titulo') {
        $problems += "Sin título definido"
    }
    
    # 8. Verificar duplicados (mismo nombre con .txt y .md)
    $otherExt = if ($ext -eq '.txt') { '.md' } else { '.txt' }
    if (Test-Path "$($_.DirectoryName)\$($_.BaseName)$otherExt") {
        $problems += "Existe duplicado con extensión $otherExt"
    }
    
    if ($problems.Count -gt 0) {
        $issues += [PSCustomObject]@{
            Archivo = $filename
            Problemas = $problems -join "; "
            Severidad = if ($problems -contains "Falta el separador ' - ' entre artista y canción") { "ALTA" } else { "MEDIA" }
        }
    }
}

# Mostrar resultados
Write-Host "`n=== ANÁLISIS DE FORMATO DE CANCIONES ===" -ForegroundColor Cyan
Write-Host "Total de archivos con problemas: $($issues.Count)" -ForegroundColor Yellow
Write-Host ""

# Agrupar por severidad
$altaSeveridad = $issues | Where-Object { $_.Severidad -eq "ALTA" }
$mediaSeveridad = $issues | Where-Object { $_.Severidad -eq "MEDIA" }

if ($altaSeveridad.Count -gt 0) {
    Write-Host "SEVERIDAD ALTA ($($altaSeveridad.Count) archivos):" -ForegroundColor Red
    $altaSeveridad | ForEach-Object {
        Write-Host "  ❌ $($_.Archivo)" -ForegroundColor Red
        Write-Host "     └─ $($_.Problemas)" -ForegroundColor DarkRed
    }
    Write-Host ""
}

if ($mediaSeveridad.Count -gt 0) {
    Write-Host "SEVERIDAD MEDIA ($($mediaSeveridad.Count) archivos):" -ForegroundColor Yellow
    $mediaSeveridad | ForEach-Object {
        Write-Host "  ⚠️  $($_.Archivo)" -ForegroundColor Yellow
        Write-Host "     └─ $($_.Problemas)" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

# Exportar a CSV
$issues | Export-Csv -Path ".\analisis-formato.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Resultados también guardados en: analisis-formato.csv" -ForegroundColor Green
