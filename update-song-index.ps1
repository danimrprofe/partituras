param(
    [string]$SongsDirectory = "partituras",
    [string]$OutputFile = "partituras/index.json",
    [string]$MetadataCsvPath = "",
    [string]$SeedOutputFile = "partituras/song-profiles.seed.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Remove-Diacritics {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()

    foreach ($character in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($character)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($character)
        }
    }

    return $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
}

function New-Slug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $withoutDiacritics = Remove-Diacritics $Value
    $slug = $withoutDiacritics.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    return $slug.Trim("-")
}

function Resolve-ProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $ProjectRoot $Path
}

function Get-SongMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name).Trim()
    $artist = "Desconocido"
    $title = $baseName

    if ($baseName -match "^\s*-\s*(.+)$") {
        $title = $Matches[1].Trim()
    } elseif ($baseName -match "^\s*(.+?)\s*-\s*(.+)$") {
        $artist = $Matches[1].Trim()
        $title = $Matches[2].Trim()
    }

    return [pscustomobject]@{
        Artist = $artist
        Title = $title
        BaseName = $baseName
    }
}

function Get-SongBpm {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $bpmPattern = "(?i)(?:BPM|TEMPO)[\s:]*([0-9]+)"
    $matches = [regex]::Matches($FileContent, $bpmPattern)
    
    if ($matches.Count -gt 0) {
        return [int]$matches[0].Groups[1].Value
    }
    
    return $null
}

function Get-SongSections {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $sections = [System.Collections.Generic.HashSet[string]]::new()
    $sectionPattern = "(?i)^\s*(\[?(?:INTRO|VERSO|ESTROFA|ESTRIBILLO|PUENTE|BRIDGE|OUTRO)\]?)"
    
    $lines = $FileContent -split "`n"
    foreach ($line in $lines) {
        if ($line -match $sectionPattern) {
            $match = $matches[1].ToUpper() -replace '[\[\]]', ''
            [void]$sections.Add($match)
        }
    }
    
    return @($sections)
}

function Get-SongTechniques {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $techniques = [System.Collections.Generic.HashSet[string]]::new()
    $contentUpper = $FileContent.ToUpper()
    
    $techniquePatterns = @{
        "palm-mute" = "PALM\s+MUTE|PALM\s+MUTING|HINCHAPIÉ"
        "fingerpicking" = "FINGERPICKING|FINGER\s+PICKING|ARPEGIOS"
        "tabs" = "\[TAB\]|TAB:|TABS?(?:\s|:|$)|(?:^|\s)[0-2][-0-9]{3,}"
        "barre-chords" = "CEJILLA|BARRE|BARRÉ"
        "strumming" = "STRUMMING|RASGUEO|RASGUEOS"
    }
    
    foreach ($technique in $techniquePatterns.Keys) {
        if ($contentUpper -match $techniquePatterns[$technique]) {
            [void]$techniques.Add($technique)
        }
    }
    
    return @($techniques)
}

function Get-SongKeyAndTimeFromTable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $result = @{
        key = $null
        time = $null
        bpm = $null
    }
    
    $lines = $FileContent -split "`n"
    for ($i = 0; $i -lt $lines.Count - 2; $i++) {
        $currentLine = $lines[$i]
        
        # Buscar línea de encabezado con tabla markdown
        if ($currentLine -match "^\|" -and $currentLine -match "Tonalidad" -and $currentLine -match "Compás") {
            # Verificar siguiente línea sea separador
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match "^\|.*-.*\|") {
                # Leer línea de datos
                if ($i + 2 -lt $lines.Count) {
                    $headerLine = $currentLine
                    $dataLine = $lines[$i + 2]
                    
                    # Parsear con split, eliminando espacios en blanco
                    $headerRaw = $headerLine -split "\|" 
                    $dataRaw = $dataLine -split "\|"
                    
                    # Filtrar celdas (eliminar primero y último que son vacío)
                    $headers = @()
                    $data = @()
                    
                    for ($j = 1; $j -lt $headerRaw.Count - 1; $j++) {
                        $headers += $headerRaw[$j].Trim()
                    }
                    for ($j = 1; $j -lt $dataRaw.Count - 1; $j++) {
                        $data += $dataRaw[$j].Trim()
                    }
                    
                    # Mapear datos a headers
                    for ($j = 0; $j -lt $headers.Count -and $j -lt $data.Count; $j++) {
                        $header = $headers[$j]
                        $value = $data[$j]
                        
                        if ($header -match "^Tonalidad" -and $value -and $value -ne "") {
                            $result.key = $value
                        }
                        elseif ($header -match "^Tempo" -and $value -and $value -ne "") {
                            if ($value -match "[0-9]+") {
                                $result.bpm = [int]($value -replace "[^0-9]", "")
                            }
                        }
                        elseif ($header -match "^Compás" -and $value -and $value -match "^\d+/\d+$") {
                            $result.time = $value
                        }
                    }
                    
                    break
                }
            }
        }
    }
    
    return $result
}

function Normalize-LookupText {
    param(
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $withoutDiacritics = Remove-Diacritics $Value
    $normalized = $withoutDiacritics.ToLowerInvariant()
    $normalized = $normalized -replace "\(ver\s*\d+\)", ""
    $normalized = $normalized -replace "https?://\S+", ""
    $normalized = $normalized -replace "^[0-9]+\s+", ""
    $normalized = $normalized -replace "[^a-z0-9]+", " "
    $normalized = $normalized -replace "\s+", " "

    return $normalized.Trim()
}

function Get-LookupTokens {
    param(
        [string]$Value
    )

    $normalized = Normalize-LookupText $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    return @(
        $normalized.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries) |
            Where-Object { $_.Length -gt 1 } |
            Select-Object -Unique
    )
}

function Get-RatingFromStars {
    param(
        [string]$Stars
    )

    if ([string]::IsNullOrWhiteSpace($Stars)) {
        return 0
    }

    return [Math]::Min(5, ([regex]::Matches($Stars, "★")).Count)
}

function Get-InstrumentsFromCsvRow {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Row
    )

    $instruments = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($Row.PIA)) {
        $instruments.Add("piano")
    }

    if (-not [string]::IsNullOrWhiteSpace($Row.GUI)) {
        $instruments.Add("guitarra-electrica")
    }

    return @($instruments | Select-Object -Unique)
}

function Find-SongMatch {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$LookupSongs,

        [string]$Artist,

        [string]$Title
    )

    $artistKey = Normalize-LookupText $Artist
    $titleKey = Normalize-LookupText $Title
    $titleTokens = Get-LookupTokens $Title

    if ([string]::IsNullOrWhiteSpace($titleKey)) {
        return $null
    }

    $scoredCandidates = foreach ($entry in $LookupSongs) {
        $score = 0

        if ($entry.TitleKey -eq $titleKey) {
            $score += 100
        } elseif ($entry.TitleKey.Contains($titleKey) -or $titleKey.Contains($entry.TitleKey)) {
            $score += 70
        }

        $sharedTokens = @($titleTokens | Where-Object { $entry.TitleTokens -contains $_ }).Count
        if ($sharedTokens -gt 0) {
            $score += $sharedTokens * 12
        }

        if (-not [string]::IsNullOrWhiteSpace($artistKey)) {
            if ($entry.ArtistKey -eq $artistKey) {
                $score += 35
            } elseif ($entry.ArtistKey.Contains($artistKey) -or $artistKey.Contains($entry.ArtistKey)) {
                $score += 20
            }
        }

        if ($score -gt 0) {
            [pscustomobject]@{
                Song = $entry.Song
                Score = $score
            }
        }
    }

    $bestCandidates = @($scoredCandidates | Sort-Object Score -Descending | Select-Object -First 2)
    if ($bestCandidates.Count -eq 0) {
        return $null
    }

    if ($bestCandidates[0].Score -lt 24) {
        return $null
    }

    if ($bestCandidates.Count -gt 1 -and ($bestCandidates[0].Score - $bestCandidates[1].Score) -lt 8) {
        return $null
    }

    return $bestCandidates[0].Song
}

function Export-SongProfileSeed {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Songs,

        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $rows = Import-Csv -LiteralPath $CsvPath -Delimiter ";"
    $lookupSongs = foreach ($song in $Songs) {
        [pscustomobject]@{
            Song = $song
            ArtistKey = Normalize-LookupText $song.artist
            TitleKey = Normalize-LookupText $song.title
            TitleTokens = Get-LookupTokens $song.title
        }
    }

    $profiles = @{}
    $matchedRows = 0
    $unmatchedRows = [System.Collections.Generic.List[string]]::new()

    foreach ($row in $rows) {
        $title = [string]$row.Titulo
        $artist = [string]$row.Artista
        $rating = Get-RatingFromStars $row.Estrellas
        $instruments = @(Get-InstrumentsFromCsvRow -Row $row)

        if ([string]::IsNullOrWhiteSpace((Normalize-LookupText $title))) {
            continue
        }

        if ($rating -eq 0 -and $instruments.Count -eq 0) {
            continue
        }

        $song = Find-SongMatch -LookupSongs $lookupSongs -Artist $artist -Title $title
        if (-not $song) {
            $unmatchedRows.Add(("{0} - {1}" -f $artist, $title).Trim(" -"))
            continue
        }

        $matchedRows += 1

        if ($profiles.ContainsKey($song.id)) {
            $existing = $profiles[$song.id]
            $profiles[$song.id] = [ordered]@{
                instruments = @(@($existing.instruments) + $instruments | Select-Object -Unique)
                rating = [Math]::Max([int]$existing.rating, $rating)
            }
        } else {
            $profiles[$song.id] = [ordered]@{
                instruments = $instruments
                rating = $rating
            }
        }
    }

    $profiles | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

    Write-Host "Perfiles semilla actualizados: $($profiles.Count) canciones con datos importados -> $OutputPath"
    Write-Host "Filas del CSV casadas con el catalogo: $matchedRows"

    if ($unmatchedRows.Count -gt 0) {
        Write-Host "Filas sin casar: $($unmatchedRows.Count)"
    }
}

$projectRoot = Split-Path -Parent $PSCommandPath
$songsPath = Resolve-ProjectPath -Path $SongsDirectory -ProjectRoot $projectRoot
$outputPath = Resolve-ProjectPath -Path $OutputFile -ProjectRoot $projectRoot
$seedOutputPath = Resolve-ProjectPath -Path $SeedOutputFile -ProjectRoot $projectRoot

$resolvedMetadataCsvPath = ""
if (-not [string]::IsNullOrWhiteSpace($MetadataCsvPath)) {
    $resolvedMetadataCsvPath = Resolve-ProjectPath -Path $MetadataCsvPath -ProjectRoot $projectRoot
}
if ([string]::IsNullOrWhiteSpace($resolvedMetadataCsvPath)) {
    $defaultMetadataCsvPath = Join-Path $projectRoot "canciones.txt"
    if (Test-Path -LiteralPath $defaultMetadataCsvPath) {
        $resolvedMetadataCsvPath = $defaultMetadataCsvPath
    }
}

if (-not (Test-Path -LiteralPath $songsPath)) {
    throw "No existe la carpeta de partituras: $songsPath"
}

$usedIds = @{}
$songs = Get-ChildItem -LiteralPath $songsPath -File -Filter "*.txt" |
    Sort-Object Name |
    ForEach-Object {
        $metadata = Get-SongMetadata -File $_
        
        try {
            $fileContent = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction Stop
        } catch {
            $fileContent = ""
        }
        
        $bpm = if ($fileContent) { Get-SongBpm -FileContent $fileContent } else { $null }
        $sections = if ($fileContent) { Get-SongSections -FileContent $fileContent } else { @() }
        $techniques = if ($fileContent) { Get-SongTechniques -FileContent $fileContent } else { @() }
        $tableData = if ($fileContent) { Get-SongKeyAndTimeFromTable -FileContent $fileContent } else { @{ key = $null; time = $null; bpm = $null } }
        
        # BPM desde tabla tiene prioridad, sino usa búsqueda de texto
        if ($tableData.bpm) {
            $bpm = $tableData.bpm
        } elseif (-not $bpm -and $tableData.bpm) {
            $bpm = $tableData.bpm
        }
        
        $baseId = New-Slug $metadata.BaseName

        if ([string]::IsNullOrWhiteSpace($baseId)) {
            $baseId = [guid]::NewGuid().ToString("N")
        }

        if ($usedIds.ContainsKey($baseId)) {
            $usedIds[$baseId] += 1
            $id = "{0}-{1}" -f $baseId, $usedIds[$baseId]
        } else {
            $usedIds[$baseId] = 1
            $id = $baseId
        }

        $song = [pscustomobject]@{
            id = $id
            artist = $metadata.Artist
            title = $metadata.Title
            filename = $_.Name
        }
        
        if ($bpm) {
            $song | Add-Member -NotePropertyName "bpm" -NotePropertyValue $bpm
        }
        
        if ($sections -and $sections.Length -gt 0) {
            $song | Add-Member -NotePropertyName "sections" -NotePropertyValue @($sections)
        }
        
        if ($techniques -and $techniques.Length -gt 0) {
            $song | Add-Member -NotePropertyName "techniques" -NotePropertyValue @($techniques)
        }
        
        if ($tableData.key) {
            $song | Add-Member -NotePropertyName "key" -NotePropertyValue $tableData.key
        }
        
        if ($tableData.time) {
            $song | Add-Member -NotePropertyName "timeSignature" -NotePropertyValue $tableData.time
        }
        
        $song
    }

$songs | ConvertTo-Json -Depth 3 -AsArray | Set-Content -LiteralPath $outputPath -Encoding UTF8

Write-Host "Indice actualizado: $($songs.Count) canciones -> $OutputFile"

if (-not [string]::IsNullOrWhiteSpace($resolvedMetadataCsvPath)) {
    if (-not (Test-Path -LiteralPath $resolvedMetadataCsvPath)) {
        throw "No existe el CSV de metadatos: $resolvedMetadataCsvPath"
    }

    Export-SongProfileSeed -Songs $songs -CsvPath $resolvedMetadataCsvPath -OutputPath $seedOutputPath
}