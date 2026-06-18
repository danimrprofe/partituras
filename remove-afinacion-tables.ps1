# Script para remover bloques de "Afinación medio tono abajo" y tablas de markdown
$rootPath = "./partituras"
$files = Get-ChildItem -Path $rootPath -Filter "*.txt" -File

$filesProcessed = 0
$afinacionRemoved = 0
$tablasRemoved = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Remover bloque "Afinación medio tono abajo" con sus líneas
    # Patrón: "Afinación medio tono abajo" seguido de acordes tipo "E A D G B E" y "sin cejilla"
    $content = $content -replace 'Afinación\s+medio\s+tono\s+abajo\s*\nE\s+A\s+D\s+G\s+B\s+E\s*\nsin\s+cejilla\s*\n', ''
    
    if ($content -ne $originalContent) {
        $afinacionRemoved++
    }
    
    $originalContent = $content
    
    # Remover tablas de markdown tipo:
    # Primera línea: | Tonalidad | Tempo | Compás | Capo |
    # Segunda línea: | --------- | ----- | ------ | ---- |
    # Tercera línea: | valores |
    $content = $content -replace '\|\s*Tonalidad[^\n]*\n\|\s*-[^\n]*\n\|[^\n]*\n', ''
    
    if ($content -ne $originalContent) {
        $tablasRemoved++
    }
    
    # Escribir solo si hubo cambios
    if ($content -ne $originalContent -or $afinacionRemoved -gt 0 -or $tablasRemoved -gt 0) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
    }
    
    $filesProcessed++
    if ($filesProcessed % 50 -eq 0) {
        Write-Host "Procesados: $filesProcessed archivos..."
    }
}

Write-Host "Total de archivos procesados: $filesProcessed"
Write-Host "Bloques de afinación removidos: $afinacionRemoved"
Write-Host "Tablas markdown removidas: $tablasRemoved"
