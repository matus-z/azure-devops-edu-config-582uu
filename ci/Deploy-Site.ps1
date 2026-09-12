<#
.SYNOPSIS
    Nasadí zostavený balík na cieľové prostredie.

.DESCRIPTION
    Staging aj produkcia nasadzujú ten istý artefakt tým istým spôsobom —
    líšia sa len prostredím a cieľom. Schválenia a kontroly nie sú tu, sú
    nastavené na prostredí (`environment:`), preto je tento skript zámerne
    hlúpy: skopíruje a vypíše, čo skopíroval.

    Bez `-TargetPath` sa iba vypíše obsah balíka — to je režim na workshop.
    V ostrej prevádzke sa zadá SMB share, ktorý je zároveň priečinkom IIS
    stránky, napr. `\\server\stranka\staging`.

.EXAMPLE
    .\ci\Deploy-Site.ps1 -Version v1.2.1 -EnvironmentName STAGING -PackagePath $(Pipeline.Workspace)\app
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Version,

    [Parameter(Mandatory)]
    [string] $EnvironmentName,

    [Parameter(Mandatory)]
    [string] $PackagePath,

    [string] $TargetPath
)

$ErrorActionPreference = 'Stop'

Write-Host "Nasadzujem verziu $Version na $EnvironmentName"
Get-ChildItem $PackagePath -Recurse | Select-Object Name, Length

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Write-Host "-TargetPath nezadaný — kopírovanie preskočené (workshopový režim)."
    return
}

New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null
Copy-Item (Join-Path $PackagePath '*') $TargetPath -Recurse -Force
Write-Host "OK — verzia $Version skopírovaná do $TargetPath."
