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

    if ($baseName -match "(?i)^\s*m\s*-\s*clan\s*(?:-\s*(.*))?$") {
        $artist = "MClan"
        $parsedTitle = [string]$Matches[1]
        if ([string]::IsNullOrWhiteSpace($parsedTitle)) {
            $title = "MClan"
        }
        else {
            $title = $parsedTitle.Trim()
        }
    }
    elseif ($baseName -match "^\s*-\s*(.+)$") {
        $title = $Matches[1].Trim()
    }
    elseif ($baseName -match "^\s*(.+?)\s*-\s*(.+)$") {
        $artist = $Matches[1].Trim()
        $title = $Matches[2].Trim()
    }

    # Normalizar variantes del nombre del grupo para evitar inconsistencias por guiones.
    if ($artist -match "(?i)^\s*m\s*-?\s*clan\s*$") {
        $artist = "MClan"
    }

    return [pscustomobject]@{
        Artist   = $artist
        Title    = $title
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

function Get-SongCapo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $normalizedContent = Remove-Diacritics $FileContent

    $candidates = [System.Collections.Generic.List[int]]::new()

    $capoPattern = "(?im)(?:CEJILLA\/CAPO|CEJILLA|CAPO)\s*:\s*(?:TRASTE\s+)?(-?[0-9]+)|\bcapo\s+(-?[0-9]+)"
    $matches = [regex]::Matches($normalizedContent, $capoPattern)
    foreach ($match in $matches) {
        $rawValue = if (-not [string]::IsNullOrWhiteSpace($match.Groups[1].Value)) {
            $match.Groups[1].Value
        }
        else {
            $match.Groups[2].Value
        }

        if (-not [string]::IsNullOrWhiteSpace($rawValue)) {
            [void]$candidates.Add([int]$rawValue)
        }
    }

    # Patrón para números directos: "Cejilla en traste 4" y "Cejilla: Traste 3"
    $numericCapoPattern = "(?im)(?:cejilla|capo)(?:\s+en)?\s+traste\s+(-?[0-9]+)"
    $numericMatches = [regex]::Matches($normalizedContent, $numericCapoPattern)
    foreach ($numericMatch in $numericMatches) {
        $capoValue = [int]$numericMatch.Groups[1].Value
        if ($capoValue -ne 0) {
            [void]$candidates.Add($capoValue)
        }
    }

    # Patrón para números ordinales: "Cejilla: 4o traste"
    $ordinalNumericCapoPattern = "(?im)(?:cejilla|capo).*?(-?[0-9]+)o\s+traste"
    $ordinalNumericMatches = [regex]::Matches($normalizedContent, $ordinalNumericCapoPattern)
    foreach ($ordinalNumericMatch in $ordinalNumericMatches) {
        $capoValue = [int]$ordinalNumericMatch.Groups[1].Value
        if ($capoValue -ne 0) {
            [void]$candidates.Add($capoValue)
        }
    }

    # Patrón para "Cejilla: X" o "Capo: X" (solo números)
    $simpleCapoPattern = "(?im)^(?:CEJILLA|CAPO)\s*:\s*(-?[0-9]+)"
    $simpleMatches = [regex]::Matches($normalizedContent, $simpleCapoPattern)
    foreach ($simpleMatch in $simpleMatches) {
        $capoValue = [int]$simpleMatch.Groups[1].Value
        if ($capoValue -ne 0) {
            [void]$candidates.Add($capoValue)
        }
    }

    $ordinalPattern = "(?im)\b(?:con\s+)?(?:cejilla|capo)\s+en\s+el\s+(primer|primero|segundo|tercer|tercero|cuarto|quinto|sexto|septimo|octavo|noveno|decimo|undecimo|duodecimo)\s+traste\b"
    $ordinalMap = @{
        "primer"    = 1
        "primero"   = 1
        "segundo"   = 2
        "tercer"    = 3
        "tercero"   = 3
        "cuarto"    = 4
        "quinto"    = 5
        "sexto"     = 6
        "septimo"   = 7
        "octavo"    = 8
        "noveno"    = 9
        "decimo"    = 10
        "undecimo"  = 11
        "duodecimo" = 12
    }

    $ordinalMatches = [regex]::Matches($normalizedContent, $ordinalPattern)
    foreach ($ordinalMatch in $ordinalMatches) {
        $ordinalValue = $ordinalMatch.Groups[1].Value.ToLowerInvariant()
        if ($ordinalMap.ContainsKey($ordinalValue)) {
            [void]$candidates.Add([int]$ordinalMap[$ordinalValue])
        }
    }

    $positiveCapo = $candidates | Where-Object { $_ -gt 0 } | Select-Object -First 1
    if ($null -ne $positiveCapo) {
        return [int]$positiveCapo
    }

    $fallbackCapo = $candidates | Select-Object -First 1
    if ($null -ne $fallbackCapo) {
        return [int]$fallbackCapo
    }

    return $null
}

function Get-SongHeaderMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $result = @{
        tuningText = $null
        tuningSlug = $null
        key        = $null
        time       = $null
    }

    $normalizedContent = Remove-Diacritics $FileContent

    $tuningMatch = [regex]::Match($normalizedContent, "(?im)^\s*AFINACION\s*:\s*(.+?)\s*$")
    if ($tuningMatch.Success) {
        $tuningText = $tuningMatch.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($tuningText)) {
            $result.tuningText = $tuningText

            $normalizedTuning = Remove-Diacritics $tuningText
            $normalizedTuning = $normalizedTuning.ToLowerInvariant()

            if ($normalizedTuning -match "\bestandar\b|\bstandard\b") {
                $result.tuningSlug = "estandar"
            }
            elseif ($normalizedTuning -match "eb\W*ab\W*db\W*gb\W*bb\W*eb") {
                $result.tuningSlug = "medio-tono-abajo"
            }
            elseif ($normalizedTuning -match "medio\s*tono\s*abajo") {
                $result.tuningSlug = "medio-tono-abajo"
            }
            elseif ($normalizedTuning -match "\btono\s*abajo\b") {
                $result.tuningSlug = "tono-abajo"
            }
            elseif ($normalizedTuning -match "\bdrop\s*d\b") {
                $result.tuningSlug = "drop-d"
            }
            elseif ($normalizedTuning -match "\bdrop\s*c\b") {
                $result.tuningSlug = "drop-c"
            }
        }
    }

    # Fallback: detectar afinacion estandar en texto libre o tablas, incluso sin cabecera AFINACION:
    if (-not $result.tuningSlug) {
        $hasStandardLabel = $normalizedContent -match "(?im)\b(?:AFINACION|TUNING)\s*[:\-]?\s*(?:ESTANDAR|STANDARD)\b"
        $hasEadgbePattern = $normalizedContent -match "(?im)\bE\W*A\W*D\W*G\W*B\W*E\b"
        $hasEbPattern = $normalizedContent -match "(?im)\beb\W*ab\W*db\W*gb\W*bb\W*eb\b"

        if ($hasStandardLabel -or $hasEadgbePattern) {
            $result.tuningSlug = "estandar"
        }
        elseif ($hasEbPattern) {
            $result.tuningSlug = "medio-tono-abajo"
        }
    }

    $keyMatch = [regex]::Match($normalizedContent, "(?im)^\s*TONALIDAD\s*:\s*(.+?)\s*$")
    if ($keyMatch.Success) {
        $keyText = $keyMatch.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($keyText) -and $keyText -ne "-") {
            $keyText = $keyText -replace "\bmayor\b", "Mayor"
            $keyText = $keyText -replace "\bmenor\b", "Menor"
            $result.key = $keyText
        }
    }

    $timeMatch = [regex]::Match($normalizedContent, "(?im)^\s*COMPAS\s*:\s*(\d+\s*/\s*\d+)\s*$")
    if ($timeMatch.Success) {
        $result.time = ($timeMatch.Groups[1].Value -replace "\s+", "")
    }

    return $result
}

function Get-SongSections {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )

    $sections = [System.Collections.Generic.HashSet[string]]::new()
    # Patron clasico: ESTROFA, [INTRO], etc.
    $sectionPattern = "(?i)^\s*(\[?(?:INTRO|VERSO|ESTROFA|ESTRIBILLO|PUENTE|BRIDGE|OUTRO|SOLO|CODA)\]?)"
    # Patron markdown: **Estrofa**, **[Intro]**, # Estrofa, etc.
    $mdSectionPattern = "(?i)^\s*(?:[*_]{1,3}|#{1,3})\s*(\[?(?:INTRO|VERSO|ESTROFA|ESTRIBILLO|PUENTE|BRIDGE|OUTRO|SOLO|CODA)\]?)\s*(?:[*_]{1,3})?\s*$"
    
    $lines = $FileContent -split "`n"
    foreach ($line in $lines) {
        if ($line -match $sectionPattern) {
            $match = $matches[1].ToUpper() -replace '[\[\]]', ''
            [void]$sections.Add($match)
        }
        elseif ($line -match $mdSectionPattern) {
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
        "palm-mute"     = "PALM\s+MUTE|PALM\s+MUTING|HINCHAPIÉ"
        "fingerpicking" = "FINGERPICKING|FINGER\s+PICKING|ARPEGIOS"
        "tabs"          = "\[TAB\]|TAB:|TABS?(?:\s|:|$)|(?:^|\s)[0-2][-0-9]{3,}"
        "barre-chords"  = "CEJILLA|BARRE|BARRÉ"
        "strumming"     = "STRUMMING|RASGUEO|RASGUEOS"
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
        key  = $null
        time = $null
        bpm  = $null
        capo = $null
    }

    function Normalize-TableCell {
        param([string]$Value)

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return ""
        }

        return (Remove-Diacritics $Value).ToLowerInvariant().Trim()
    }

    function Normalize-TableKey {
        param([string]$Value)

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        $cleanValue = $Value.Trim()
        $cleanValue = $cleanValue -replace "\([^\)]*\)", ""
        $cleanValue = $cleanValue -replace "\s+-\s+.*$", ""
        $cleanValue = $cleanValue -replace "\s+#\s*", "#"
        $cleanValue = $cleanValue -replace "\bmayor\b", "Mayor"
        $cleanValue = $cleanValue -replace "\bmenor\b", "Menor"
        $cleanValue = $cleanValue -replace "\s+", " "
        $cleanValue = $cleanValue.Trim()

        if ([string]::IsNullOrWhiteSpace($cleanValue) -or $cleanValue -eq "-") {
            return $null
        }

        return $cleanValue
    }

    function Parse-TableCapo {
        param([string]$Value)

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        $normalizedValue = Normalize-TableCell $Value
        if ([string]::IsNullOrWhiteSpace($normalizedValue) -or $normalizedValue -eq "-") {
            return $null
        }

        if ($normalizedValue -match "^(?:no|none|sin|sin capo|sin cejilla)$") {
            return 0
        }

        if ($normalizedValue -match "(\d+)") {
            return [int]$Matches[1]
        }

        return $null
    }
    
    $lines = $FileContent -split "`n"
    for ($i = 0; $i -lt $lines.Count - 2; $i++) {
        $currentLine = $lines[$i]
        
        # Verificar si la línea está vacía antes de procesar
        if ([string]::IsNullOrWhiteSpace($currentLine)) {
            continue
        }
        
        $normalizedHeaderLine = Remove-Diacritics $currentLine
        
        # Buscar línea de encabezado con tabla markdown
        if ($currentLine -match "^\|" -and $normalizedHeaderLine -match "Tonalidad" -and $normalizedHeaderLine -match "Compas") {
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
                        $normalizedHeader = Normalize-TableCell $header
                        $value = $data[$j]
                        
                        if ($normalizedHeader -match "tonalidad" -and $value -and $value -ne "") {
                            $result.key = Normalize-TableKey $value
                        }
                        elseif ($normalizedHeader -match "tempo" -and $value -and $value -ne "") {
                            if ($value -match "[0-9]+") {
                                $result.bpm = [int]($value -replace "[^0-9]", "")
                            }
                        }
                        elseif ($normalizedHeader -match "compas" -and $value -and $value -match "^\s*\d+\s*/\s*\d+\s*$") {
                            $result.time = ($value -replace "\s+", "")
                        }
                        elseif ($normalizedHeader -match "capo" -or $normalizedHeader -match "cejilla") {
                            $parsedCapo = Parse-TableCapo $value
                            if ($null -ne $parsedCapo) {
                                $result.capo = $parsedCapo
                            }
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
        }
        elseif ($entry.TitleKey.Contains($titleKey) -or $titleKey.Contains($entry.TitleKey)) {
            $score += 70
        }

        $sharedTokens = @($titleTokens | Where-Object { $entry.TitleTokens -contains $_ }).Count
        if ($sharedTokens -gt 0) {
            $score += $sharedTokens * 12
        }

        if (-not [string]::IsNullOrWhiteSpace($artistKey)) {
            if ($entry.ArtistKey -eq $artistKey) {
                $score += 35
            }
            elseif ($entry.ArtistKey.Contains($artistKey) -or $artistKey.Contains($entry.ArtistKey)) {
                $score += 20
            }
        }

        if ($score -gt 0) {
            [pscustomobject]@{
                Song  = $entry.Song
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

        [string]$CsvPath = "",

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $profiles = @{}

    foreach ($song in $Songs) {
        if ($song.PSObject.Properties.Name -contains "defaultTuning" -and -not [string]::IsNullOrWhiteSpace([string]$song.defaultTuning)) {
            $profiles[$song.id] = [ordered]@{
                instruments = @()
                rating      = 0
                tuning      = [string]$song.defaultTuning
            }
        }
    }

    $rows = @()
    if (-not [string]::IsNullOrWhiteSpace($CsvPath) -and (Test-Path -LiteralPath $CsvPath)) {
        $rows = Import-Csv -LiteralPath $CsvPath -Delimiter ";"
    }

    $lookupSongs = foreach ($song in $Songs) {
        [pscustomobject]@{
            Song        = $song
            ArtistKey   = Normalize-LookupText $song.artist
            TitleKey    = Normalize-LookupText $song.title
            TitleTokens = Get-LookupTokens $song.title
        }
    }

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
                rating      = [Math]::Max([int]$existing.rating, $rating)
                tuning      = if ($existing.PSObject.Properties.Name -contains "tuning") { $existing.tuning } else { "" }
            }
        }
        else {
            $profiles[$song.id] = [ordered]@{
                instruments = $instruments
                rating      = $rating
                tuning      = ""
            }
        }
    }

    $profiles | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

    Write-Host "Perfiles semilla actualizados: $($profiles.Count) canciones -> $OutputPath"

    if ($rows.Count -gt 0) {
        Write-Host "Filas del CSV casadas con el catalogo: $matchedRows"
        if ($unmatchedRows.Count -gt 0) {
            Write-Host "Filas sin casar: $($unmatchedRows.Count)"
        }
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
$songs = Get-ChildItem -LiteralPath $songsPath -File | Where-Object { $_.Extension -in @('.txt', '.md') } |
Sort-Object Name |
ForEach-Object {
    $metadata = Get-SongMetadata -File $_
        
    try {
        $fileContent = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction Stop
    }
    catch {
        $fileContent = ""
    }
        
    $bpm = if ($fileContent) { Get-SongBpm -FileContent $fileContent } else { $null }
    $capo = if ($fileContent) { Get-SongCapo -FileContent $fileContent } else { $null }
    $headerData = if ($fileContent) { Get-SongHeaderMetadata -FileContent $fileContent } else { @{ tuningSlug = $null; key = $null; time = $null } }
    $sections = if ($fileContent) { Get-SongSections -FileContent $fileContent } else { @() }
    $techniques = if ($fileContent) { Get-SongTechniques -FileContent $fileContent } else { @() }
    $tableData = if ($fileContent) { Get-SongKeyAndTimeFromTable -FileContent $fileContent } else { @{ key = $null; time = $null; bpm = $null; capo = $null } }
        
    # BPM desde tabla tiene prioridad, sino usa búsqueda de texto
    if ($tableData.bpm) {
        $bpm = $tableData.bpm
    }
    elseif (-not $bpm -and $tableData.bpm) {
        $bpm = $tableData.bpm
    }

    if ($null -ne $tableData.capo) {
        $capo = $tableData.capo
    }

    $keyValue = if ($tableData.key) { $tableData.key } else { $headerData.key }
    $timeValue = if ($tableData.time) { $tableData.time } else { $headerData.time }
        
    $baseId = New-Slug $metadata.BaseName

    if ([string]::IsNullOrWhiteSpace($baseId)) {
        $baseId = [guid]::NewGuid().ToString("N")
    }

    if ($usedIds.ContainsKey($baseId)) {
        $usedIds[$baseId] += 1
        $id = "{0}-{1}" -f $baseId, $usedIds[$baseId]
    }
    else {
        $usedIds[$baseId] = 1
        $id = $baseId
    }

    $song = [pscustomobject]@{
        id            = $id
        artist        = $metadata.Artist
        title         = $metadata.Title
        filename      = $_.Name
        defaultTuning = $headerData.tuningSlug
    }
        
    if ($bpm) {
        $song | Add-Member -NotePropertyName "bpm" -NotePropertyValue $bpm
    }

    if ($null -ne $capo) {
        $song | Add-Member -NotePropertyName "capo" -NotePropertyValue $capo
    }
        
    if ($sections -and $sections.Length -gt 0) {
        $song | Add-Member -NotePropertyName "sections" -NotePropertyValue @($sections)
    }
        
    if ($techniques -and $techniques.Length -gt 0) {
        $song | Add-Member -NotePropertyName "techniques" -NotePropertyValue @($techniques)
    }
        
    if ($keyValue) {
        $song | Add-Member -NotePropertyName "key" -NotePropertyValue $keyValue
    }
        
    if ($timeValue) {
        $song | Add-Member -NotePropertyName "timeSignature" -NotePropertyValue $timeValue
    }
    
    # Agregar URL de búsqueda de YouTube
    $searchQuery = "$($metadata.Artist) $($metadata.Title)"
    $encodedQuery = [Uri]::EscapeDataString($searchQuery)
    $song | Add-Member -NotePropertyName "youtubeUrl" -NotePropertyValue "https://www.youtube.com/results?search_query=$encodedQuery"
        
    $song
}

@($songs) | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $outputPath -Encoding UTF8

Write-Host "Indice actualizado: $($songs.Count) canciones -> $OutputFile"

if (-not [string]::IsNullOrWhiteSpace($resolvedMetadataCsvPath)) {
    if (-not (Test-Path -LiteralPath $resolvedMetadataCsvPath)) {
        throw "No existe el CSV de metadatos: $resolvedMetadataCsvPath"
    }
}

Export-SongProfileSeed -Songs $songs -CsvPath $resolvedMetadataCsvPath -OutputPath $seedOutputPath