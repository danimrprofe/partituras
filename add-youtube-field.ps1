# Script para agregar el campo youtubeUrl al index.json

$indexPath = "c:\Users\Dani\Desktop\github\partituras\partituras\index.json"

# Leer el archivo JSON
$json = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Agregar el campo youtubeUrl a cada canción
foreach ($song in $json) {
    if (-not $song.PSObject.Properties.Name -contains "youtubeUrl") {
        $song | Add-Member -NotePropertyName "youtubeUrl" -NotePropertyValue ""
    }
}

# Guardar el archivo actualizado
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "Campo 'youtubeUrl' agregado a todas las canciones en index.json"
