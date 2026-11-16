param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'Audio\Lineage2')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive not found: $ArchivePath"
}

$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArchivePath).Path)
try {
    $entries = @($archive.Entries)
    if ($entries.Count -ne 53) { throw "Expected 53 tracks; found $($entries.Count)." }
    $numbers = @{}
    foreach ($entry in $entries) {
        if ($entry.FullName -notmatch '^lineage_2_(\d{2})\. [^/\\]+\.mp3$') {
            throw "Unexpected archive entry: $($entry.FullName)"
        }
        $number = [int]$Matches[1]
        if ($number -lt 1 -or $number -gt 54 -or $number -eq 47 -or $numbers[$number]) {
            throw "Unexpected or duplicate track number: $number"
        }
        $numbers[$number] = $true
    }
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    foreach ($entry in $entries) {
        $number = [int]([regex]::Match($entry.Name, '^lineage_2_(\d{2})\.').Groups[1].Value)
        $target = Join-Path $OutputDirectory ('l2_{0:D2}.mp3' -f $number)
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
    }
    Write-Output "Prepared 53 Lineage II tracks in $OutputDirectory"
}
finally {
    $archive.Dispose()
}
