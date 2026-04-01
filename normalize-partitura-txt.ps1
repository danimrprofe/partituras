param(
    [string]$SongsDirectory = "partituras",
    [switch]$WhatIf
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

    if ($artist -match "(?i)^\s*m\s*-?\s*clan\s*$") {
        $artist = "MClan"
    }

    return [pscustomobject]@{
        Artist = $artist
        Title  = $title
    }
}

function Detect-TuningText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $match = [regex]::Match($Content, "(?im)^\s*(?:AFINACION|TUNING)\s*:\s*(.+?)\s*$")
    if ($match.Success) {
        $value = $match.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return "Estandar (E A D G B E)"
}

function Detect-CapoText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $lineMatch = [regex]::Match($Content, "(?im)^\s*(?:CEJILLA/CAPO|CEJILLA|CAPO)\s*:\s*(.+?)\s*$")
    if ($lineMatch.Success) {
        $raw = $lineMatch.Groups[1].Value.Trim()
        if ($raw -match "(?i)^\s*(sin\s+cejilla|sin\s+capo|none|no\s+capo|0)\s*$") {
            return "Sin cejilla"
        }

        if ($raw -match "(\d+)") {
            $capoNum = [int]$Matches[1]
            if ($capoNum -le 0) {
                return "Sin cejilla"
            }
            return "Capo $capoNum"
        }

        return $raw
    }

    $inline = [regex]::Match($Content, "(?i)\bcapo\s+([0-9]+)")
    if ($inline.Success) {
        $capoNum = [int]$inline.Groups[1].Value
        if ($capoNum -le 0) {
            return "Sin cejilla"
        }
        return "Capo $capoNum"
    }

    return "Sin cejilla"
}

function Detect-AlbumText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $match = [regex]::Match($Content, "(?im)^\s*ALBUM\s*:\s*(.+?)\s*$")
    if ($match.Success) {
        $value = $match.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return "-"
}

function Normalize-SectionLine {
    param(
        [string]$Line
    )

    $pattern = "(?i)^\s*(?:\*{1,3}|#{1,3}|\[)?\s*(intro(?:duccion)?|verse|verso|estrofa|chorus|coro|estribillo|pre[-\s]?(?:chorus|coro|estribillo)|bridge|puente|instrumental(?:es)?|solo(?:s)?|outro|final|coda|interlude|interludio)(?:\s*[:\-]?\s*(\d+))?\s*(?:\]|\*{1,3})?\s*$"
    $match = [regex]::Match($Line, $pattern)
    if (-not $match.Success) {
        return $Line
    }

    $rawName = (Remove-Diacritics $match.Groups[1].Value).ToLowerInvariant()
    $number = $match.Groups[2].Value

    $canonical = switch -Regex ($rawName) {
        "^intro" { "INTRO"; break }
        "^verse$|^verso$|^estrofa$" { "ESTROFA"; break }
        "^chorus$|^coro$|^estribillo$" { "ESTRIBILLO"; break }
        "^pre" { "PRE-ESTRIBILLO"; break }
        "^bridge$|^puente$" { "PUENTE"; break }
        "^instrumental" { "INSTRUMENTAL"; break }
        "^solo" { "SOLO"; break }
        "^outro$" { "OUTRO"; break }
        "^final$" { "FINAL"; break }
        "^coda$" { "CODA"; break }
        "^interlude$|^interludio$" { "INTERLUDIO"; break }
        default { "" }
    }

    if ([string]::IsNullOrWhiteSpace($canonical)) {
        return $Line
    }

    if ([string]::IsNullOrWhiteSpace($number)) {
        return $canonical
    }

    return "$canonical $number"
}

function Normalize-BodySections {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $lines = $Content -split "`r?`n"
    $normalizedLines = foreach ($line in $lines) {
        Normalize-SectionLine -Line $line
    }

    return ($normalizedLines -join "`r`n")
}

function Build-MinimalHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Artist,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Album,

        [Parameter(Mandatory = $true)]
        [string]$Tuning,

        [Parameter(Mandatory = $true)]
        [string]$Capo
    )

    return @(
        "# PARTITURA v1",
        "================================================================================",
        "ARTISTA: $Artist",
        "CANCION: $($Title.ToUpperInvariant())",
        "ALBUM:   $Album",
        "================================================================================",
        "AFINACION: $Tuning",
        "CEJILLA/CAPO: $Capo",
        "================================================================================",
        "LEYENDA / NOTAS ADICIONALES:",
        "(Acordes e informacion adicional)",
        "================================================================================"
    ) -join "`r`n"
}

$projectRoot = Split-Path -Parent $PSCommandPath
$songsPath = Resolve-ProjectPath -Path $SongsDirectory -ProjectRoot $projectRoot

if (-not (Test-Path -LiteralPath $songsPath)) {
    throw "No existe la carpeta de partituras: $songsPath"
}

$txtFiles = Get-ChildItem -LiteralPath $songsPath -File -Filter "*.txt" | Sort-Object Name

$updated = 0
$alreadyV1 = 0

foreach ($file in $txtFiles) {
    $original = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($original)) {
        continue
    }

    $metadata = Get-SongMetadata -File $file
    $normalizedBody = Normalize-BodySections -Content $original

    if ($original -match "(?m)^#\s*PARTITURA\s+v1\s*$") {
        $alreadyV1 += 1

        if ($normalizedBody -ne $original) {
            if (-not $WhatIf) {
                Set-Content -LiteralPath $file.FullName -Value $normalizedBody -Encoding UTF8
            }
            $updated += 1
        }

        continue
    }

    $album = Detect-AlbumText -Content $original
    $tuning = Detect-TuningText -Content $original
    $capo = Detect-CapoText -Content $original

    $header = Build-MinimalHeader -Artist $metadata.Artist -Title $metadata.Title -Album $album -Tuning $tuning -Capo $capo
    $bodyTrimmed = $normalizedBody.TrimStart("`r", "`n")
    $final = "$header`r`n`r`n$bodyTrimmed"

    if (-not $WhatIf) {
        Set-Content -LiteralPath $file.FullName -Value $final -Encoding UTF8
    }

    $updated += 1
}

Write-Host "Normalizacion completada."
Write-Host "Total .txt: $($txtFiles.Count)"
Write-Host "Con cabecera v1 previa: $alreadyV1"
Write-Host "Archivos actualizados: $updated"
