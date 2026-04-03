# Regenerar index.json correctamente
$files = Get-ChildItem -File | Where-Object { $_.Extension -match '\.(txt|md)$' }
$songs = @()

foreach ($file in $files) {
    $baseName = $file.BaseName.Trim()
    $parts = $baseName -split ' - ', 2
    $artist = $parts[0].Trim()
    $title = if ($parts.Count -gt 1) { $parts[1].Trim() } else { $baseName }
    $id = ($baseName -replace '[^\w\s-]', '' -replace '\s+', '-' -replace '^-|-$', '' -replace '-+', '-').ToLowerInvariant()
    
    $songs += @{
        id = $id
        artist = $artist
        title = $title
        filename = $file.Name
    }
}

# Ordenar y eliminar duplicados por ID
$songs = $songs | Sort-Object { $_.id } -Unique

# Convertir a JSON
$json = $songs | ConvertTo-Json -Depth 3
$json | Out-File -FilePath 'index.json' -Encoding UTF8

Write-Host "OK: Regenerado: $($songs.Count) canciones"
