# Script para agregar URLs de búsqueda de YouTube al index.json

$indexPath = "./partituras/index.json"

# Leer el archivo JSON
$json = Get-Content -Path $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json

$urlsAdded = 0

foreach ($song in $json) {
    # Si no tiene youtubeUrl o está vacío, generarlo
    if (-not $song.PSObject.Properties.Name -contains "youtubeUrl" -or [string]::IsNullOrWhiteSpace($song.youtubeUrl)) {
        # Crear la URL de búsqueda en YouTube
        $searchQuery = "$($song.artist) $($song.title)"
        # Codificar la query para URL
        $encodedQuery = [Uri]::EscapeDataString($searchQuery)
        $song.youtubeUrl = "https://www.youtube.com/results?search_query=$encodedQuery"
        
        $urlsAdded++
    }
}

# Guardar el archivo actualizado
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "URLs de YouTube agregadas: $urlsAdded canciones"
Write-Host "Total de canciones: $($json.Count)"
Write-Host "Índice actualizado: $indexPath"
