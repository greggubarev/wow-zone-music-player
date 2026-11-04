param(
    [string]$PerfectWorldRoot,
    [string]$MorrowindMusicRoot,
    [string[]]$WowClientRoots = @(
        'C:\Program Files (x86)\World of Warcraft\_retail_',
        'C:\Program Files (x86)\World of Warcraft\_forever_'
    )
)

$ErrorActionPreference = 'Stop'
$addonSource = $PSScriptRoot
$musicSource = if ($PerfectWorldRoot) {
    Join-Path $PerfectWorldRoot 'element\music'
} else {
    Join-Path $addonSource 'Audio\PerfectWorld'
}
if ($PerfectWorldRoot -and -not (Test-Path -LiteralPath $musicSource -PathType Container)) {
    throw "Perfect World music folder not found: $musicSource"
}

$tracksText = Get-Content -LiteralPath (Join-Path $addonSource 'Tracks.lua') -Raw
$trackNames = [regex]::Matches($tracksText, 'file\s*=\s*"([A-Za-z0-9_]+\.mp3)"') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
if ($trackNames.Count -eq 0) { throw 'No audio filenames found in Tracks.lua.' }

$missing = @($trackNames | Where-Object { -not (Test-Path -LiteralPath (Join-Path $musicSource $_) -PathType Leaf) })
if ($PerfectWorldRoot -and $missing.Count -gt 0) {
    throw "Missing Perfect World music files: $($missing -join ', ')"
}
$pwiSourceReady = $missing.Count -eq 0

$morrowindText = Get-Content -LiteralPath (Join-Path $addonSource 'MorrowindTracks.lua') -Raw
$morrowindNames = [regex]::Matches($morrowindText, 'file\s*=\s*"(mw_\d{2}\.mp3)"') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
if ($morrowindNames.Count -ne 21) { throw 'Expected 21 Morrowind tracks.' }
$morrowindSource = if ($MorrowindMusicRoot) {
    $MorrowindMusicRoot
} else {
    Join-Path $addonSource 'Audio\Morrowind'
}
if ($MorrowindMusicRoot -and -not (Test-Path -LiteralPath $morrowindSource -PathType Container)) {
    throw "Morrowind music folder not found: $morrowindSource"
}
$missingMorrowind = @($morrowindNames | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $morrowindSource $_) -PathType Leaf)
})
if ($MorrowindMusicRoot -and $missingMorrowind.Count -gt 0) {
    throw "Missing Morrowind music files: $($missingMorrowind -join ', ')"
}
$morrowindSourceReady = $missingMorrowind.Count -eq 0

foreach ($root in $WowClientRoots) {
    $addons = Join-Path $root 'Interface\AddOns'
    if (-not (Test-Path -LiteralPath $addons -PathType Container)) {
        throw "WoW AddOns folder not found: $addons"
    }
}

foreach ($root in $WowClientRoots) {
    $target = Join-Path $root 'Interface\AddOns\WoWZoneMusicPlayer'
    $audioTarget = Join-Path $target 'Audio'
    New-Item -ItemType Directory -Path $audioTarget -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $addonSource 'Audio\silence.mp3') -Destination (Join-Path $audioTarget 'silence.mp3') -Force
    $pwiTarget = Join-Path $audioTarget 'PerfectWorld'
    New-Item -ItemType Directory -Path $pwiTarget -Force | Out-Null
    if ($pwiSourceReady) {
        foreach ($name in $trackNames) {
            $sourceFile = Join-Path $musicSource $name
            $targetFile = Join-Path $pwiTarget $name
            $same = (Test-Path -LiteralPath $targetFile -PathType Leaf) -and
                ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -eq
                 (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash)
            if (-not $same) {
                Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
            }
        }
    }
    $morrowindTarget = Join-Path $audioTarget 'Morrowind'
    New-Item -ItemType Directory -Path $morrowindTarget -Force | Out-Null
    if ($morrowindSourceReady) {
        foreach ($name in $morrowindNames) {
            $sourceFile = Join-Path $morrowindSource $name
            $targetFile = Join-Path $morrowindTarget $name
            $same = (Test-Path -LiteralPath $targetFile -PathType Leaf) -and
                ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -eq
                 (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash)
            if (-not $same) {
                Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
            }
        }
    }
    $pwiReady = (@($trackNames | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $pwiTarget $_) -PathType Leaf)
    }).Count -eq 0)
    $morrowindReady = (@($morrowindNames | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $morrowindTarget $_) -PathType Leaf)
    }).Count -eq 0)
    foreach ($name in @('WoWZoneMusicPlayer.toc', 'WoWZoneMusicPlayer.lua', 'Tracks.lua', 'MorrowindTracks.lua', 'MusicIcon.tga', 'ControlIcons.tga', 'SourceIcons.tga', 'PrepareMorrowind.ps1', 'README.md')) {
        Copy-Item -LiteralPath (Join-Path $addonSource $name) -Destination (Join-Path $target $name) -Force
    }
    $morrowindFlag = if ($morrowindReady) { 'true' } else { 'false' }
    $pwiFlag = if ($pwiReady) { 'true' } else { 'false' }
    Set-Content -LiteralPath (Join-Path $target 'InstalledLibraries.lua') -Value "PWZoneMusicInstalled = { pwi = $pwiFlag, morrowind = $morrowindFlag }" -Encoding Ascii
    Write-Output "Installed: $target (Perfect World $(if ($pwiReady) { $trackNames.Count } else { 0 }), Morrowind $(if ($morrowindReady) { 21 } else { 0 }))"
}
