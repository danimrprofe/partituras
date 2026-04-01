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

$resolvedMetadataCsvPath = Resolve-ProjectPath -Path $MetadataCsvPath -ProjectRoot $projectRoot
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

        [pscustomobject]@{
            id = $id
            artist = $metadata.Artist
            title = $metadata.Title
            filename = $_.Name
        }
    }

$songs | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $outputPath -Encoding UTF8

Write-Host "Indice actualizado: $($songs.Count) canciones -> $OutputFile"

if (-not [string]::IsNullOrWhiteSpace($resolvedMetadataCsvPath)) {
    if (-not (Test-Path -LiteralPath $resolvedMetadataCsvPath)) {
        throw "No existe el CSV de metadatos: $resolvedMetadataCsvPath"
    }

    Export-SongProfileSeed -Songs $songs -CsvPath $resolvedMetadataCsvPath -OutputPath $seedOutputPath
}