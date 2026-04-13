param(
    [string]$SongsDirectory = "partituras"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path $SongsDirectory -Filter "*.txt" -Recurse
$filesModified = 0

# Patrón flexible que captura variaciones de acentos
$pattern = "={80,}`r?`nLEYENDA\s*\/\s*NOTAS\s+ADICIONALES\s*:`r?`n\([^)]*\)`r?`n={80,}"

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, ""
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        $filesModified++
        Write-Host "Modificado: $($file.Name)"
    }
}

Write-Host "`nTotal de archivos modificados: $filesModified"
