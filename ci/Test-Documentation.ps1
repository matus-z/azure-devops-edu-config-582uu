<#
.SYNOPSIS
    Overí, že dokumentácia zodpovedá nasadzovanej verzii.

.DESCRIPTION
    Nasadenie bez popisu zmeny je presne to, čo schvaľovateľovi chýba, keď sa
    rozhoduje. Preto sa kontroluje spolu s testami, ešte pred publikovaním.

.EXAMPLE
    .\ci\Test-Documentation.ps1 -Version v1.2.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Version,

    [string]   $Path      = 'docs',
    [string[]] $Required  = @('CHANGELOG.md', 'popis-zmeny.md'),
    [string]   $Changelog = 'CHANGELOG.md'
)

$ErrorActionPreference = 'Stop'

$missing = $Required | Where-Object { -not (Test-Path (Join-Path $Path $_)) }
if ($missing) {
    Write-Host "##vso[task.logissue type=error]Chýba: $(($missing | ForEach-Object { Join-Path $Path $_ }) -join ', ')"
    exit 1
}

$changelogPath = Join-Path $Path $Changelog
if (-not (Select-String -Path $changelogPath -Pattern ([regex]::Escape($Version)) -Quiet)) {
    Write-Host "##vso[task.logissue type=error]$Changelog nespomína verziu $Version"
    exit 1
}

Write-Host "Dokumentácia k verzii $Version je na mieste."
