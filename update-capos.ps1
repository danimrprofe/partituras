#!/usr/bin/env pwsh
# Script para buscar y actualizar información de capos en los metadatos

$partiturasDir = ".\partituras"
$updated = 0

Get-ChildItem "$partiturasDir\*.txt" | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name

    $content = Get-Content $filePath -Encoding UTF8

    # Leer primera línea con Capo
    $capoline = $content | Where-Object { $_ -match '^Capo:\s*' } | Select-Object -First 1

    if ($capoline) {
        # Buscar información de capo en el contenido
        $foundCapo = $null

        # Buscar CEJILLA/CAPO: número
        if ($content -join "`n" | Select-String 'CEJILLA/CAPO:\s*Capo?\s*(\d+)' -AllMatches | ForEach-Object { $foundCapo = $_.Matches[0].Groups[1].Value }) {
            # Found it
        }
        # Buscar CAPO: número
        elseif ($content -join "`n" | Select-String 'CAPO[:/]\s*(\d+)' -AllMatches | ForEach-Object { $foundCapo = $_.Matches[0].Groups[1].Value }) {
            # Found it
        }

        if ($foundCapo) {
            # Actualizar la línea de capo
            $newContent = $content | ForEach-Object {
                if ($_ -match '^Capo:') {
                    "Capo: $foundCapo"
                } else {
                    $_
                }
            }

            Set-Content $filePath -Value $newContent -Encoding UTF8 -Force
            Write-Host "✓ $fileName -> Capo: $foundCapo" -ForegroundColor Green
            $updated++
        }
    }
}

Write-Host "`n✅ Completado: $updated capos actualizados" -ForegroundColor Yellow
