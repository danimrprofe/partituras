#!/usr/bin/env pwsh
# Script para actualizar capos desde song-profiles.json

$partiturasDir = ".\partituras"
$profilesFile = "$partiturasDir\song-profiles.json"

# Leer JSON de perfiles
$profiles = Get-Content $profilesFile -Encoding UTF8 -Raw | ConvertFrom-Json

$updated = 0

Get-ChildItem "$partiturasDir\*.txt" | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name

    # Generar key del perfil (artist-song en minúsculas sin caracteres especiales)
    if ($fileName -match '^(.+?)\s*-\s*(.+?)\.txt$') {
        $artist = $matches[1].Trim()
        $song = $matches[2].Trim()

        # Crear key como en el JSON
        $key = "$artist-$song".ToLower() -replace '[^a-z0-9-]', ''

        # Buscar en perfiles
        if ($profiles.PSObject.Properties.Name -contains $key) {
            $profile = $profiles.$key

            if ($profile.capo -and $profile.capo -ne "") {
                # Actualizar capo en el archivo
                $content = Get-Content $filePath -Encoding UTF8
                $newContent = $content | ForEach-Object {
                    if ($_ -match '^Capo:') {
                        "Capo: $($profile.capo)"
                    } else {
                        $_
                    }
                }

                Set-Content $filePath -Value $newContent -Encoding UTF8 -Force
                Write-Host "✓ $fileName -> Capo: $($profile.capo)" -ForegroundColor Green
                $updated++
            }
        }
    }
}

Write-Host "`n✅ Completado: $updated capos actualizados desde song-profiles.json" -ForegroundColor Yellow
