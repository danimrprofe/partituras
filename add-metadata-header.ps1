#!/usr/bin/env pwsh
# Script para agregar líneas de metadatos al inicio de cada partitura sin eliminar contenido

$partiturasDir = ".\partituras"
$processed = 0
$errors = 0

Get-ChildItem "$partiturasDir\*.txt" | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name

    try {
        # Extraer artista y canción del nombre del archivo (formato: "Artista - Canción.txt")
        if ($fileName -match '^(.+?)\s*-\s*(.+?)\.txt$') {
            $artist = $matches[1].Trim()
            $song = $matches[2].Trim()
        } else {
            Write-Host "⚠️ No se pudo parsear: $fileName" -ForegroundColor Yellow
            $errors++
            return
        }

        # Leer contenido actual
        $content = Get-Content $filePath -Encoding UTF8 -Raw

        # Buscar Capo en el contenido (primer número encontrado después de CAPO: o similar)
        $capo = "No"
        if ($content -match '(?:CEJILLA|CAPO)[/:]?\s*(\d+)') {
            $capo = $matches[1]
        } elseif ($content -match '(?:CAPO|Capo)\s*(\d+)') {
            $capo = $matches[1]
        }

        # Buscar Disco/Álbum
        $disco = ""
        if ($content -match '(?:ALBUM|DISCO|Álbum|Album)[:\s]+([^\n]+)') {
            $disco = $matches[1].Trim()
        }

        # Buscar Afinación
        $afinacion = ""
        if ($content -match '(?:AFINACIÓN|TUNING|Afinación)[:\s]+([^\n]+)') {
            $afinacion = $matches[1].Trim()
        }

        # Construir header de metadatos
        $header = @"
Artista: $artist
Canción: $song
Capo: $capo
Disco: $disco
Afinación: $afinacion

"@

        # Escribir header + contenido original
        $newContent = $header + $content
        Set-Content $filePath -Value $newContent -Encoding UTF8 -Force

        $processed++
        if ($processed % 100 -eq 0) {
            Write-Host "✓ Procesadas $processed canciones..." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Error en $fileName : $_" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n✅ Completado: $processed procesadas, $errors errores" -ForegroundColor Yellow
