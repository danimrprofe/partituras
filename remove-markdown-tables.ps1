# Script mejorado para remover tablas de markdown de los archivos
$rootPath = "./partituras"

$files = Get-ChildItem -Path $rootPath -Filter "*.txt" -File

$filesProcessed = 0
$tablesRemoved = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Patrón para detectar tablas de markdown de metadatos:
    # | Tonalidad (con o sin emoji) | ... | Capo |
    # | --------- | ... |
    # | valores |
    # Puede haber múltiples líneas de datos
    
    $content = $content -replace '\|\s*🎸?Tonalidad\s*\|[^\n]*Capo\s*\|\s*\n\|\s*-+\s*\|[^\n]*-+\s*\|[^\n]*\n(?:\|[^\n]*\|\s*\n)*', ''
    
    if ($content -ne $originalContent) {
        $tablesRemoved++
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
    }
    
    $filesProcessed++
    if ($filesProcessed % 50 -eq 0) {
        Write-Host "Procesados: $filesProcessed archivos..."
    }
}

Write-Host "Total de archivos procesados: $filesProcessed"
Write-Host "Tablas removidas: $tablesRemoved"
