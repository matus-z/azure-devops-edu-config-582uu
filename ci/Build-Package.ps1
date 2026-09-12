<#
.SYNOPSIS
    Zostaví balík z kódu dodávateľa a zapíše doň nasadzovanú verziu.

.DESCRIPTION
    Verziu zapisujeme do stránky, aby bola viditeľná aj bez otvorenia
    pipeline. Keby placeholder chýbal, nahradenie by ticho neurobilo nič
    a verzia by sa na stránku nedostala — preto zlyháme hlasne.

.EXAMPLE
    .\ci\Build-Package.ps1 -Version v1.2.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Version,

    [string] $Source      = 'vendor\src',
    [string] $Destination = 'dist',
    [string] $Page        = 'index.html',
    [string] $Placeholder = '__VERSION__'
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
Copy-Item (Join-Path $Source '*') $Destination -Recurse -Force

$pagePath = Join-Path $Destination $Page
$content  = Get-Content $pagePath -Raw

if ($content -notlike "*$Placeholder*") {
    Write-Host "##vso[task.logissue type=error]$pagePath neobsahuje $Placeholder — verzia by sa na stránku nedostala"
    exit 1
}

$content.Replace($Placeholder, $Version) | Set-Content $pagePath -NoNewline

Write-Host "Balík zostavený, verzia $Version zapísaná do $Page:"
Get-ChildItem $Destination -Recurse -File | Select-Object FullName
