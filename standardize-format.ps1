# Script para estandarizar el formato de todas las partituras
# Formato deseado:
# Línea 1: Artista
# Línea 2: Canción
# Línea 3: Capo X (si existe, si es 0 o no existe, dejar vacío)

$partiturasPath = Join-Path $PSScriptRoot "partituras"
$processed = 0
$errors = 0

Get-ChildItem $partiturasPath -Filter "*.txt" | ForEach-Object {
    try {
        $filePath = $_.FullName
        $fileName = $_.BaseName  # Sin extensión

        # Extraer artista y canción del nombre del archivo (formato: "Artista - Canción")
        if ($fileName -match "^(.+?)\s+-\s+(.+)$") {
            $artist = $matches[1].Trim()
            $title = $matches[2].Trim()
        } else {
            Write-Host "⚠️ No se pudo parsear: $fileName" -ForegroundColor Yellow
            $errors++
            return
        }

        # Leer contenido actual
        $content = Get-Content $filePath -Encoding UTF8
        $lines = @()
        if ($content -is [string]) {
            $lines = @($content)
        } else {
            $lines = $content
        }

        # Buscar línea de CAPO
        $capoLine = ""
        $contentStart = 0
        $capoValue = 0

        foreach ($i in 0..($lines.Length - 1)) {
            $line = $lines[$i]

            # Buscar CEJILLA/CAPO
            if ($line -match "(?:CEJILLA|CAPO)[:/\s]+(Capo\s+)?(-?\d+)" -or $line -match "^Capo\s+(-?\d+)") {
                if ($matches[1]) {
                    $capoValue = [int]$matches[1]
                } else {
                    $capoValue = [int]$matches[2]
                }
                # Continuar buscando contenido real (después de saltar líneas vacías)
                for ($j = $i + 1; $j -lt $lines.Length; $j++) {
                    if ($lines[$j].Trim() -ne "" -and $lines[$j] -notmatch "^[A-Z\s]+$") {
                        $contentStart = $j
                        break
                    }
                }
                if ($contentStart -eq 0) { $contentStart = $i + 1 }
                break
            }

            # Si encontramos el nombre del artista o canción en MAYÚSCULAS, comenzar desde después
            if ($line -match "^[A-Z\s]+$" -and $line.Trim() -ne "") {
                # Podría ser el artista o canción, saltar estos
                continue
            }

            # Si encontramos una sección (INTRO, ESTROFA, etc.) o acordes, comenzar aquí
            if ($line -match "^(INTRO|ESTROFA|VERSO|CORO|PUENTE|OUTRO|BRIDGE|CHORUS|VERSE|SOLO|RIFF|FILL|BREAK|BRIDGE|PRE|PRE-CORO|PRE-CHORUS|FINAL|END).*" -or
                ($line -match "^[A-G]" -and $line -match "[#bm]?[ms]?[79(]" -and $i -gt 2)) {
                $contentStart = $i
                break
            }
        }

        # Si no encontramos donde empieza el contenido, buscar primera línea no vacía y no metadatos
        if ($contentStart -eq 0) {
            for ($i = 0; $i -lt $lines.Length; $i++) {
                $line = $lines[$i].Trim()
                # Saltar líneas vacías y metadatos (artista/canción en mayús, CAPO, etc.)
                if ($line -ne "" -and
                    $line -notmatch "^[A-Z\s]+$" -and
                    $line -notmatch "(?:CEJILLA|CAPO)" -and
                    $line -ne $artist.ToUpper() -and
                    $line -ne $title.ToUpper()) {
                    $contentStart = $i
                    break
                }
            }
        }

        # Construir nuevo contenido
        $newContent = @()
        $newContent += $artist
        $newContent += $title
        if ($capoValue -ne 0 -and $capoValue -ne "") {
            $newContent += "Capo $capoValue"
        } else {
            $newContent += ""
        }

        # Agregar contenido original (saltando metadatos)
        if ($contentStart -gt 0 -and $contentStart -lt $lines.Length) {
            $newContent += $lines[$contentStart..($lines.Length - 1)]
        }

        # Guardar
        $newContent | Set-Content $filePath -Encoding UTF8

        $processed++
        if ($processed % 50 -eq 0) {
            Write-Host "✓ Procesadas $processed canciones..." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error en $($_.Name): $_" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "✅ Completado: $processed procesadas, $errors errores" -ForegroundColor Green
