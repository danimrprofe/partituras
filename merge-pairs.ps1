#!/usr/bin/env pwsh
<#
.SYNOPSIS
Junta líneas de DOS EN DOS con alineación correcta de acordes.

.DESCRIPTION
Toma 2 pares (acorde1-letra1, acorde2-letra2) y los convierte en:
- 1 línea de acordes alineados
- 1 línea de letras juntadas

Mantiene el resto del archivo sin cambios.

.PARAMETER FilePath
Ruta del archivo (opcional)
#>

param([string]$FilePath)

function Test-IsChordLine {
    param([string]$line)
    if ([string]::IsNullOrWhiteSpace($line)) { return $false }
    
    $tokens = [regex]::Split($line.Trim(), '\s+') | Where-Object { $_ -ne '' }
    $chordCount = 0
    
    foreach ($token in $tokens) {
        if ($token -match '^[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?$') {
            $chordCount++
        }
    }
    
    return ($tokens.Count -gt 0 -and ($chordCount / $tokens.Count) -gt 0.4)
}

function Get-WordPositions {
    param([string]$text)
    
    $words = @()
    $matches = [regex]::Matches($text, '[^\s]+')
    foreach ($match in $matches) {
        $words += [PSCustomObject]@{ word = $match.Value; pos = $match.Index }
    }
    return $words
}

function Map-ChordsToWords {
    param([string]$chordLine, [string]$lyricLine)
    
    $chords = @()
    $matches = [regex]::Matches($chordLine, '[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?')
    foreach ($match in $matches) {
        $chords += [PSCustomObject]@{ chord = $match.Value; pos = $match.Index }
    }
    
    $words = Get-WordPositions $lyricLine
    
    $mappings = @()
    foreach ($chord in $chords) {
        $closest = $null
        $minDist = [int]::MaxValue
        
        # Buscar palabra en o después del acorde
        foreach ($word in $words) {
            if ($word.pos -ge $chord.pos) {
                $dist = $word.pos - $chord.pos
                if ($dist -lt $minDist) {
                    $minDist = $dist
                    $closest = $word
                }
            }
        }
        
        # Si no hay después, buscar antes
        if ($null -eq $closest) {
            foreach ($word in $words) {
                $dist = $chord.pos - $word.pos
                if ($dist -ge 0 -and $dist -lt $minDist) {
                    $minDist = $dist
                    $closest = $word
                }
            }
        }
        
        if ($null -ne $closest) {
            $mappings += [PSCustomObject]@{ chord = $chord.chord; word = $closest.word }
        }
    }
    
    return $mappings
}

function Generate-AlignedChords {
    param([array]$mappings, [string]$lyricLine)
    
    if ($mappings.Count -eq 0) { return "" }
    
    $words = Get-WordPositions $lyricLine
    $output = @(' ') * $lyricLine.Length
    $wordIndex = 0
    
    foreach ($mapping in $mappings) {
        # Buscar palabra secuencialmente
        for ($i = $wordIndex; $i -lt $words.Count; $i++) {
            if ($words[$i].word -eq $mapping.word) {
                $pos = $words[$i].pos
                $chord = $mapping.chord
                
                for ($j = 0; $j -lt $chord.Length -and $pos + $j -lt $lyricLine.Length; $j++) {
                    $output[$pos + $j] = $chord[$j]
                }
                
                $wordIndex = $i + 1
                break
            }
        }
    }
    
    return (($output -join '') -replace '\s+$', '')
}

function Process-File {
    param([string]$path)
    
    Write-Host "Procesando: $(Split-Path -Leaf $path)" -ForegroundColor Cyan
    
    try {
        $lines = @(Get-Content $path -Encoding UTF8)
        $result = @()
        $i = 0
        
        while ($i -lt $lines.Count) {
            $line = $lines[$i]
            
            # Si es línea de acorde, intentar juntar 2 pares
            if (Test-IsChordLine $line) {
                # Buscar: acorde1 + letra1 + acorde2 + letra2
                $chordLine1 = $line
                $lyricLine1 = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { $null }
                
                if ($null -ne $lyricLine1 -and -not (Test-IsChordLine $lyricLine1) -and -not [string]::IsNullOrWhiteSpace($lyricLine1)) {
                    
                    $chordLine2 = if ($i + 2 -lt $lines.Count) { $lines[$i + 2] } else { $null }
                    $lyricLine2 = if ($i + 3 -lt $lines.Count) { $lines[$i + 3] } else { $null }
                    
                    # Si tenemos el segundo par completo
                    if ($null -ne $chordLine2 -and (Test-IsChordLine $chordLine2) -and 
                        $null -ne $lyricLine2 -and -not (Test-IsChordLine $lyricLine2) -and -not [string]::IsNullOrWhiteSpace($lyricLine2)) {
                        
                        # Juntarlos
                        $map1 = Map-ChordsToWords $chordLine1 $lyricLine1
                        $map2 = Map-ChordsToWords $chordLine2 $lyricLine2
                        
                        $mergedLyrics = "$lyricLine1 $lyricLine2"
                        $allMappings = @($map1 | ForEach-Object { $_ }) + @($map2 | ForEach-Object { $_ })
                        
                        $alignedChords = Generate-AlignedChords $allMappings $mergedLyrics
                        
                        $result += $alignedChords
                        $result += $mergedLyrics
                        
                        $i += 4
                        continue
                    }
                }
            }
            
            # Si no se puede juntar, mantener línea como está
            $result += $line
            $i++
        }
        
        $result -join "`n" | Set-Content $path -Encoding UTF8 -NoNewline
        Write-Host "  ✓ OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        return $false
    }
}

# MAIN
if ($FilePath) {
    if (Test-Path $FilePath) { Process-File $FilePath }
    else { Write-Host "Archivo no encontrado" -ForegroundColor Red }
}
else {
    $folder = Join-Path (Split-Path $PSScriptRoot) "partituras"
    if (-not (Test-Path $folder)) { 
        Write-Host "Carpeta /partituras no encontrada" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Juntando líneas de dos en dos...`n" -ForegroundColor Yellow
    
    $files = @(
        Get-ChildItem -Path $folder -Filter "*.txt" -File
        Get-ChildItem -Path $folder -Filter "*.md" -File
    )
    
    $successCount = 0
    foreach ($file in $files) {
        if (Process-File $file.FullName) { $successCount++ }
    }
    
    Write-Host "`n✓ Completado: $successCount/$($files.Count) archivos" -ForegroundColor Green
}
