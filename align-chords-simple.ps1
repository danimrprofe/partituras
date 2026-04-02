#!/usr/bin/env pwsh
<#
.SYNOPSIS
Alinea acordes correctamente sobre palabras sin cambiar la estructura del archivo.

.DESCRIPTION
Procesa pares acorde-letra existentes y realinea los acordes.
NO junta líneas - solo alinea dentro de la estructura existente.

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
        if ($token -match '^[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?$|\[|\]') {
            $chordCount++
        }
    }
    
    return ($tokens.Count -gt 0 -and ($chordCount / $tokens.Count) -gt 0.4)
}

function Get-ChordWordMappings {
    param([string]$chordLine, [string]$lyricLine)
    
    $chordPattern = '[A-G][b#]?(m|maj|min|dim|aug|add|sus|6|7|9|11|13)?(\/[A-G][b#]?)?'
    $chordMatches = [regex]::Matches($chordLine, $chordPattern)
    
    $chords = @()
    foreach ($match in $chordMatches) {
        $chords += @{ chord = $match.Value; position = $match.Index }
    }
    
    $wordPattern = '[^\s]+'
    $wordMatches = [regex]::Matches($lyricLine, $wordPattern)
    
    $words = @()
    foreach ($match in $wordMatches) {
        $words += @{ word = $match.Value; position = $match.Index; length = $match.Length }
    }
    
    $mappings = @()
    foreach ($chord in $chords) {
        $closestWord = $null
        $minDistance = [int]::MaxValue
        
        foreach ($word in $words) {
            if ($word.position -ge $chord.position) {
                $distance = $word.position - $chord.position
                if ($distance -lt $minDistance) {
                    $minDistance = $distance
                    $closestWord = $word
                }
            }
        }
        
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
            $mappings += @{ chord = $chord.chord; word = $closestWord.word }
        }
    }
    
    return $mappings
}

function Align-ChordLine {
    param([array]$mappings, [string]$lyricLine)
    
    if ($mappings.Count -eq 0) { return "" }
    
    $words = @()
    $wordMatches = [regex]::Matches($lyricLine, '[^\s]+')
    foreach ($match in $wordMatches) {
        $words += @{ word = $match.Value; position = $match.Index }
    }
    
    $output = @(' ') * $lyricLine.Length
    $searchIndex = 0
    
    foreach ($mapping in $mappings) {
        $found = $false
        for ($i = $searchIndex; $i -lt $words.Count; $i++) {
            if ($words[$i].word -eq $mapping.word) {
                $pos = $words[$i].position
                $chord = $mapping.chord
                
                for ($j = 0; $j -lt $chord.Length -and $pos + $j -lt $lyricLine.Length; $j++) {
                    $output[$pos + $j] = $chord[$j]
                }
                
                $searchIndex = $i + 1
                $found = $true
                break
            }
        }
    }
    
    return (($output -join '') -replace '\s+$', '')
}

function Process-File {
    param([string]$path)
    
    Write-Host "Alineando: $(Split-Path -Leaf $path)" -ForegroundColor Cyan
    
    try {
        $lines = @(Get-Content $path -Encoding UTF8)
        $result = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            if (Test-IsChordLine $line) {
                if ($i + 1 -lt $lines.Count) {
                    $nextLine = $lines[$i + 1]
                    
                    if (-not (Test-IsChordLine $nextLine) -and -not [string]::IsNullOrWhiteSpace($nextLine)) {
                        $mappings = Get-ChordWordMappings $line $nextLine
                        $alignedChords = Align-ChordLine $mappings $nextLine
                        $result += $alignedChords
                        $result += $nextLine
                        $i++
                        continue
                    }
                }
            }
            
            $result += $line
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
    
    Write-Host "Procesando archivos...`n" -ForegroundColor Yellow
    
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
