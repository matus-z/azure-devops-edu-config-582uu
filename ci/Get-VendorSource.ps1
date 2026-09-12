<#
.SYNOPSIS
    Stiahne kód dodávateľa na danom tagu.

.DESCRIPTION
    Klonujeme skriptom a nie cez `resources.repositories`, lebo ref v
    `resources` sa vyhodnocuje pri kompilácii pipeline, takže sa nedá načítať
    zo súboru. Vďaka tomu je zmena verzie zmenou vo `version.json`, nie
    zmenou pipeline.

    Token sa do adresy vkladá až tu a berie sa z premennej prostredia, aby sa
    nedostal do príkazového riadku ani do logu. V kroku ho treba namapovať:

        env:
          SYSTEM_ACCESSTOKEN: $(System.AccessToken)

.EXAMPLE
    .\ci\Get-VendorSource.ps1 -Url https://adoserver.koop.sk/DefaultCollection/EDU/_git/Dev -Tag v1.2.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Url,

    [Parameter(Mandatory)]
    [string] $Tag,

    [string] $Destination = 'vendor',
    [string] $AccessToken = $env:SYSTEM_ACCESSTOKEN
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
    Write-Host "##vso[task.logissue type=error]Chýba token — v kroku treba namapovať SYSTEM_ACCESSTOKEN: `$(System.AccessToken)"
    exit 1
}

$authUrl = $Url.Replace('https://', "https://$AccessToken@")

git clone --depth 1 --branch $Tag $authUrl $Destination
if ($LASTEXITCODE -ne 0) {
    Write-Host "##vso[task.logissue type=error]Tag '$Tag' sa nepodarilo načítať — existuje?"
    exit 1
}

Write-Host "OK — tag $Tag stiahnutý do '$Destination'."
