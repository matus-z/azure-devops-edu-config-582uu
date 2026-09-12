<#
.SYNOPSIS
    Spustí testy dodávateľa proti zostavenému balíku.

.DESCRIPTION
    Testy bežia proti tomu, čo sa naozaj zostavilo: `src\` z klonu nahradíme
    balíkom z Build (aj s dosadenou verziou). Priečinok najprv mažeme —
    `Copy-Item -Recurse` do už existujúceho priečinka vie podpriečinky zanoriť
    do seba (`src\hooks\hooks`).

    `tests\` je v koreni repozitára dodávateľa, aplikácia v `src\`.

.EXAMPLE
    .\ci\Invoke-VendorTests.ps1 -PackagePath $(Pipeline.Workspace)\build-output
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $PackagePath,

    [string] $VendorRoot = 'vendor',
    [string] $SourceDir  = 'src',
    [string] $TestDir    = 'tests'
)

$ErrorActionPreference = 'Stop'

$target = Join-Path $VendorRoot $SourceDir
Remove-Item $target -Recurse -Force
Copy-Item $PackagePath $target -Recurse -Force

Push-Location $VendorRoot
try {
    node --test --test-reporter=spec $TestDir
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

# Pop-Location by prepísala návratový kód, preto ho držíme v premennej.
if ($exitCode -ne 0) {
    Write-Host "##vso[task.logissue type=error]Testy zlyhali (exit $exitCode)"
    exit $exitCode
}
