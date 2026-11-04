param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [string]$FfmpegPath
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive not found: $ArchivePath"
}
if (-not $FfmpegPath) {
    $ffmpegCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if (-not $ffmpegCommand) { throw 'FFmpeg was not found. Pass -FfmpegPath.' }
    $FfmpegPath = $ffmpegCommand.Source
}
if (-not (Test-Path -LiteralPath $FfmpegPath -PathType Leaf)) {
    throw "FFmpeg not found: $FfmpegPath"
}

$entries = @(tar -tf $ArchivePath)
if ($LASTEXITCODE -ne 0) { throw 'Could not read the archive.' }
foreach ($entry in $entries) {
    if ($entry -match '(^/|^[A-Za-z]:|(^|[\\/])\.\.([\\/]|$))') {
        throw "Unsafe archive path: $entry"
    }
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('PWZM-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    tar -xf $ArchivePath -C $scratch
    if ($LASTEXITCODE -ne 0) { throw 'Could not extract the archive.' }
    $files = @(Get-ChildItem -LiteralPath $scratch -Recurse -File |
        Where-Object { $_.Extension -in @('.flac', '.mp3') } | Sort-Object Name)
    if ($files.Count -ne 21) { throw "Expected 21 audio tracks; found $($files.Count)." }

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    foreach ($item in $files) {
        if ($item.Name -notmatch '^(\d{2})[.\-]') {
            throw "Unrecognized track name: $($item.Name)"
        }
        $number = [int]$Matches[1]
        $destination = Join-Path $OutputDirectory ('mw_{0:D2}.mp3' -f $number)
        & $FfmpegPath -nostdin -loglevel error -fflags +bitexact -i $item.FullName `
            -map 0:a:0 -vn -map_metadata -1 -flags:a +bitexact `
            -codec:a libmp3lame -b:a 192k -ar 44100 `
            -id3v2_version 0 -write_id3v1 0 -write_xing 0 -y $destination
        if ($LASTEXITCODE -ne 0) { throw "Could not prepare $($item.Name)." }
    }
    Write-Output "Prepared 21 Morrowind tracks in $OutputDirectory"
}
finally {
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolvedScratch.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $resolvedScratch -Leaf) -match '^PWZM-[0-9a-f]{32}$') {
        Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
    }
}
