[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('FMX', 'VCL', 'Both')]
    [string]$Framework = 'Both',

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [ValidateSet('Install', 'Repair', 'Remove')]
    [string]$Action = 'Install',

    [switch]$SkipBuild,

    [string]$PackageSource = ''
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$BdsVersion = '37.0'
$BundledPackageDirectory = Join-Path $PSScriptRoot 'DelphiPackages'
$UsingBundledPackages = [string]::IsNullOrWhiteSpace($PackageSource) -and
    (Test-Path -LiteralPath $BundledPackageDirectory)
$PackageOutput = if ($UsingBundledPackages) {
    $BundledPackageDirectory
}
elseif ([string]::IsNullOrWhiteSpace($PackageSource)) {
    Join-Path $ProjectRoot "bin\packages\Win32\$Configuration"
}
else {
    [System.IO.Path]::GetFullPath($PackageSource)
}
$PublicDocumentsRoot = [Environment]::GetFolderPath('CommonDocuments')
$Destination = Join-Path $PublicDocumentsRoot "Embarcadero\Studio\$BdsVersion\Bpl"
$KnownPackages = "HKCU:\Software\Embarcadero\BDS\$BdsVersion\Known Packages"

if ($UsingBundledPackages -and
    (-not $PSBoundParameters.ContainsKey('Framework'))) {
    $HasFmx = Test-Path -LiteralPath (Join-Path $PackageOutput `
        'DATLanguageManagerFMXDesign.bpl')
    $HasVcl = Test-Path -LiteralPath (Join-Path $PackageOutput `
        'DATLanguageManagerVCLDesign.bpl')
    if ($HasFmx -and (-not $HasVcl)) { $Framework = 'FMX' }
    elseif ($HasVcl -and (-not $HasFmx)) { $Framework = 'VCL' }
}

$Frameworks = if ($Framework -eq 'Both') { @('FMX', 'VCL') } else { @($Framework) }
$PackageNames = [System.Collections.Generic.List[string]]::new()
$PackageNames.Add('DATLanguageManagerCoreRuntime')
foreach ($SelectedFramework in $Frameworks) {
    $PackageNames.Add("DATLanguageManager${SelectedFramework}Runtime")
    $PackageNames.Add("DATLanguageManager${SelectedFramework}Design")
}

if (Get-Process -Name bds -ErrorAction SilentlyContinue) {
    throw 'RAD Studio is running. Close every RAD Studio window, then run this installer again.'
}

if (($Action -ne 'Remove') -and (-not $SkipBuild) -and
    [string]::IsNullOrWhiteSpace($PackageSource) -and
    (-not $UsingBundledPackages)) {
    & (Join-Path $ProjectRoot 'tools\tests\RunLanguageManagerPackageTests.ps1') `
        -Configuration $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw 'The package build or its verification tests failed. Nothing was installed.'
    }
}

if ($Action -eq 'Remove') {
    foreach ($SelectedFramework in $Frameworks) {
        $DesignFile = Join-Path $Destination "DATLanguageManager${SelectedFramework}Design.bpl"
        if (Test-Path -LiteralPath $KnownPackages) {
            if ($PSCmdlet.ShouldProcess($DesignFile, 'Remove Delphi design-package registration')) {
                Remove-ItemProperty -LiteralPath $KnownPackages -Name $DesignFile `
                    -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Output 'DAT Language Manager design-package registration removed. Package files were retained for recovery.'
    exit 0
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
New-Item -ItemType Directory -Force -Path $KnownPackages | Out-Null

foreach ($PackageName in $PackageNames | Select-Object -Unique) {
    $SourceBpl = Join-Path $PackageOutput "$PackageName.bpl"
    if (-not (Test-Path -LiteralPath $SourceBpl)) {
        throw "Required package was not built: $SourceBpl"
    }
    $DestinationBpl = Join-Path $Destination "$PackageName.bpl"
    if ($PSCmdlet.ShouldProcess($DestinationBpl, "Copy $PackageName")) {
        Copy-Item -LiteralPath $SourceBpl -Destination $DestinationBpl -Force
    }
}

foreach ($SelectedFramework in $Frameworks) {
    $DesignFile = Join-Path $Destination "DATLanguageManager${SelectedFramework}Design.bpl"
    $Description = "DAT Localization $SelectedFramework Components"
    if ($PSCmdlet.ShouldProcess($DesignFile, 'Register Delphi design package')) {
        New-ItemProperty -LiteralPath $KnownPackages -Name $DesignFile `
            -Value $Description -PropertyType String -Force | Out-Null
    }
}

if ($WhatIfPreference) {
    Write-Output "DAT Language Manager $Framework component installation preview completed; no changes were made."
}
else {
    Write-Output "DAT Language Manager $Framework component installation completed."
}
Write-Output "Packages: $Destination"
Write-Output 'Start RAD Studio and look for DAT Localization in the Tool Palette.'
