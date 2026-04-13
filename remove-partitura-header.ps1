# Remove "# PARTITURA v1" from all song files
$count = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $content = Get-Content -Path $filePath -Raw
    
    if ($content -like "# PARTITURA v1`r`n*" -or $content -like "# PARTITURA v1`n*") {
        $newContent = $content -replace "^# PARTITURA v1\r?\n", ""
        Set-Content -Path $filePath -Value $newContent -NoNewline -Encoding UTF8
        Write-Output "✓ $($_.Name)"
        $count++
    }
}

Write-Output "`nTotal de archivos procesados: $count"
