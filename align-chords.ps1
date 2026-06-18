#!/usr/bin/env pwsh
<#
.SYNOPSIS
Alinea automáticamente acordes con las palabras correspondientes en partituras.

.DESCRIPTION
Script que parsea archivos de partituras (txt/md) e alinea los acordes
exactamente sobre las palabras donde se deben tocar, usando el método:
1. Identifica qué palabra corresponde a cada acorde (en líneas originales)
2. Mapea acordes a palabras específicas
3. Al juntar líneas, busca las mismas palabras y coloca acordes en sus nuevas posiciones

.PARAMETER FilePath
Ruta del archivo a procesar (opcional, si se omite procesa todos los archivos)

.EXAMPLE
.\align-chords.ps1
.\align-chords.ps1 -FilePath ".\partituras\Bon Iver - Skinny Love.txt"
#>

param(
    [string]$FilePath
)

<# ============================================================================
   FUNCIONES DE PARSING Y ALINEACIÓN
   ============================================================================ #>

function Test-IsChordLine {
    param([string]$line)
    
    if ([string]::IsNullOrWhiteSpace($line)) { return $false }
    
    $tokens = [regex]::Split($line.Trim(), '\s+') | Where-Object { $_ -ne '' }
    $chordCount = 0
    
    foreach ($token in $tokens) {
        if ($token -match '^[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?$|^\[.*\]$') {
            $chordCount++
        }
    }
    
    return ($tokens.Count -gt 0 -and ($chordCount / $tokens.Count) -gt 0.4)
}

function Get-ChordWordMappings {
    <#
    Mapea cada acorde a la palabra específica sobre la que cae.
    Retorna array de acordes con su palabra asociada (para búsqueda posterior).
    #>
    param(
        [string]$chordLine,
        [string]$lyricLine
    )
    
    # Extraer acordes con sus posiciones
    $chordPattern = '[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?'
    $chordMatches = [regex]::Matches($chordLine, $chordPattern)
    
    $chords = @()
    foreach ($match in $chordMatches) {
        $chords += @{
            chord = $match.Value
            position = $match.Index
        }
    }
    
    # Extraer palabras con sus posiciones
    $wordPattern = '[^\s]+'
    $wordMatches = [regex]::Matches($lyricLine, $wordPattern)
    
    $words = @()
    foreach ($match in $wordMatches) {
        $words += @{
            word = $match.Value
            position = $match.Index
            length = $match.Length
        }
    }
    
    # Mapear: para cada acorde, encontrar la palabra más cercana
    $mappings = @()
    foreach ($chord in $chords) {
        $closestWord = $null
        $minDistance = [int]::MaxValue
        
        # Buscar palabra que comienza en o después del acorde
        foreach ($word in $words) {
            if ($word.position -ge $chord.position) {
                $distance = $word.position - $chord.position
                if ($distance -lt $minDistance) {
                    $minDistance = $distance
                    $closestWord = $word
                }
            }
        }
        
        # Si no hay palabra después, buscar la anterior más cercana
        if ($null -eq $closestWord) {
            foreach ($word in $words) {
                $distance = $chord.position - ($word.position + $word.length)
                if ($distance -ge 0 -and $distance -lt $minDistance) {
                    $minDistance = $distance
                    $closestWord = $word
                }
            }
        }
        
        if ($null -ne $closestWord) {
            $mappings += @{
                chord = $chord.chord
                word = $closestWord.word
            }
        }
    }
    
    return $mappings
}

function Find-AllWordPositions {
    <#
    Encuentra todas las posiciones de palabras en un texto.
    Retorna array con cada palabra y su posición.
    #>
    param([string]$text)
    
    $words = @()
    $wordPattern = '[^\s]+'
    $matches = [regex]::Matches($text, $wordPattern)
    
    foreach ($match in $matches) {
        $words += @{
            word = $match.Value
            position = $match.Index
        }
    }
    
    return $words
}

function Find-WordPositionSequential {
    <#
    Encuentra la posición de una palabra de forma secuencial.
    Mantiene un índice interno para encontrar ocurrencias siguientes.
    #>
    param(
        [array]$wordPositions,
        [int]$startIndex,
        [string]$wordToFind
    )
    
    # Buscar desde el índice dado hasta encontrar la palabra
    for ($i = $startIndex; $i -lt $wordPositions.Count; $i++) {
        if ($wordPositions[$i].word -eq $wordToFind) {
            return @{
                position = $wordPositions[$i].position
                nextIndex = $i + 1
            }
        }
    }
    
    return $null
}

function Generate-AlignedChordLine {
    <#
    Genera línea de acordes alineada basada en mappings palabra-acorde.
    Busca palabras secuencialmente para manejar repeticiones.
    #>
    param(
        [array]$mappings,
        [string]$lyricLine
    )
    
    if ($mappings.Count -eq 0) {
        return ""
    }
    
    # Obtener todas las posiciones de palabras
    $wordPositions = Find-AllWordPositions $lyricLine
    
    # Crear array para construcción
    $output = @(' ') * $lyricLine.Length
    
    $searchIndex = 0
    foreach ($mapping in $mappings) {
        $result = Find-WordPositionSequential $wordPositions $searchIndex $mapping.word
        
        if ($null -ne $result) {
            $pos = $result.position
            $chord = $mapping.chord
            $searchIndex = $result.nextIndex
            
            # Colocar acorde en esa posición
            for ($i = 0; $i -lt $chord.Length -and $pos + $i -lt $lyricLine.Length; $i++) {
                $output[$pos + $i] = $chord[$i]
            }
        }
    }
    
    return (($output -join '') -replace '\s+$', '')
}

function Merge-ChordLyricLines {
    <#
    Junta múltiples líneas de letras y realinea los acordes.
    #>
    param(
        [array]$chordLines,      # Array de líneas de acordes
        [array]$lyricLines       # Array de líneas de letras
    )
    
    if ($chordLines.Count -eq 0 -or $lyricLines.Count -eq 0) {
        return @()
    }
    
    # Recopilar todos los mappings de todos los pares
    $allMappings = @()
    
    for ($i = 0; $i -lt $chordLines.Count; $i++) {
        $mappings = Get-ChordWordMappings $chordLines[$i] $lyricLines[$i]
        $allMappings += $mappings
    }
    
    # Juntar las líneas de letras
    $mergedLyrics = ($lyricLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
    
    # Generar acordes alineados en la nueva línea
    $alignedChords = Generate-AlignedChordLine $allMappings $mergedLyrics
    
    return @($alignedChords, $mergedLyrics)
}

function Align-SongSection {
    <#
    Procesa una sección completa de canción.
    #>
    param(
        [string[]]$lines
    )
    
    $result = @()
    $i = 0
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        
        # Línea vacía
        if ([string]::IsNullOrWhiteSpace($line)) {
            $result += $line
            $i++
            continue
        }
        
        # Si es línea de acordes, recopilar pares acorde-letra consecutivos
        if (Test-IsChordLine $line) {
            $chordLines = @()
            $lyricLines = @()
            
            while ($i -lt $lines.Count -and (Test-IsChordLine $lines[$i] -or [string]::IsNullOrWhiteSpace($lines[$i]))) {
                if (Test-IsChordLine $lines[$i]) {
                    $chordLines += $lines[$i]
                    
                    # Siguiente línea debería ser letras
                    if ($i + 1 -lt $lines.Count -and -not (Test-IsChordLine $lines[$i + 1]) -and -not [string]::IsNullOrWhiteSpace($lines[$i + 1])) {
                        $lyricLines += $lines[$i + 1]
                        $i += 2
                    }
                    else {
                        $i++
                    }
                }
                else {
                    $i++
                }
            }
            
            # Si encontramos pares, mergearlos
            if ($chordLines.Count -gt 0 -and $lyricLines.Count -gt 0) {
                $merged = Merge-ChordLyricLines $chordLines $lyricLines
                $result += $merged[0]
                $result += $merged[1]
            }
            
            continue
        }
        
        # Línea normal
        $result += $line
        $i++
    }
    
    return $result
}

<# ============================================================================
   PROCESAMIENTO DE ARCHIVOS
   ============================================================================ #>

function Process-SongFile {
    param([string]$path)
    
    Write-Host "Procesando: $(Split-Path -Leaf $path)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $path -Encoding UTF8 -Raw
        $lines = @($content -split "`r?`n")
        
        # Alinear
        $aligned = Align-SongSection $lines
        
        # Guardar
        ($aligned -join "`n") | Set-Content $path -Encoding UTF8 -NoNewline
        
        Write-Host "  ✓ OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        return $false
    }
}

<# ============================================================================
   MAIN
   ============================================================================ #>

$startTime = Get-Date

if ($FilePath) {
    if (Test-Path $FilePath) {
        Process-SongFile $FilePath
    }
    else {
        Write-Host "Archivo no encontrado: $FilePath" -ForegroundColor Red
    }
}
else {
    $partiturasPath = Join-Path (Split-Path $PSScriptRoot) "partituras"
    
    if (-not (Test-Path $partiturasPath)) {
        Write-Host "Carpeta /partituras no encontrada" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Buscando archivos en: $partiturasPath`n" -ForegroundColor Yellow
    
    $files = @(
        Get-ChildItem -Path $partiturasPath -Filter "*.txt" -File
        Get-ChildItem -Path $partiturasPath -Filter "*.md" -File
    )
    
    Write-Host "Encontrados: $($files.Count) archivos`n" -ForegroundColor Yellow
    
    $successCount = 0
    foreach ($file in $files) {
        if (Process-SongFile $file.FullName) {
            $successCount++
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Resumen: $successCount/$($files.Count) archivos OK" -ForegroundColor Cyan
    Write-Host "Tiempo: $([Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2))s" -ForegroundColor Cyan
}
