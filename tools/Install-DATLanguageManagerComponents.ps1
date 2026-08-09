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
$BdsRoot = "C:\Program Files (x86)\Embarcadero\Studio\$BdsVersion"
$BdsBin = Join-Path $BdsRoot 'bin'
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
$MachineKnownPackages = "HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS\$BdsVersion\Known Packages"

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

# RAD Studio treats a per-user Known Packages key as the complete effective
# design-package list. Creating that key with only a third-party package hides
# the Embarcadero packages registered machine-wide. Seed the per-user key from
# the installed product before adding DAT, and refuse to proceed unless the
# standard package registrations are present and their files exist.
if (-not (Test-Path -LiteralPath $MachineKnownPackages)) {
    throw "RAD Studio $BdsVersion machine-wide package registration was not found: $MachineKnownPackages"
}

$MachinePackageProperties = @(
    (Get-ItemProperty -LiteralPath $MachineKnownPackages).PSObject.Properties |
        Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' }
)
if ($MachinePackageProperties.Count -lt 1) {
    throw "RAD Studio $BdsVersion has no machine-wide design-package registrations. Installation was cancelled."
}

$InstalledMachinePackageProperties = @()
$MissingMachinePackageProperties = @()
foreach ($MachinePackageProperty in $MachinePackageProperties) {
    $MachinePackageFile = ([string]$MachinePackageProperty.Name).
        Replace('$(BDSBIN)', $BdsBin).
        Replace('$(BDS)', $BdsRoot)
    if (Test-Path -LiteralPath $MachinePackageFile) {
        $InstalledMachinePackageProperties += $MachinePackageProperty
    }
    else {
        $MissingMachinePackageProperties += $MachinePackageProperty
        Write-Warning "Ignoring registered package whose BPL is not installed: $MachinePackageFile"
    }
}
if ($InstalledMachinePackageProperties.Count -lt 1) {
    throw "RAD Studio $BdsVersion has no machine-wide design packages whose BPL files exist. Installation was cancelled."
}

$RequiredStandardPackages = @()
if ($Frameworks -contains 'FMX') {
    $RequiredStandardPackages += '$(BDSBIN)\dclfmxstd370.bpl'
}
if ($Frameworks -contains 'VCL') {
    $RequiredStandardPackages += '$(BDSBIN)\dclstd370.bpl'
}
foreach ($RequiredStandardPackage in $RequiredStandardPackages) {
    if (-not ($InstalledMachinePackageProperties.Name -contains $RequiredStandardPackage)) {
        throw "Required Embarcadero design-package registration is missing: $RequiredStandardPackage"
    }
    $RequiredStandardFile = $RequiredStandardPackage.Replace('$(BDSBIN)',
        $BdsBin)
    if (-not (Test-Path -LiteralPath $RequiredStandardFile)) {
        throw "Required Embarcadero design package is missing: $RequiredStandardFile"
    }
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

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

if ($PSCmdlet.ShouldProcess($KnownPackages,
        'Preserve the complete Embarcadero design-package registry baseline')) {
    New-Item -ItemType Directory -Force -Path $KnownPackages | Out-Null
    foreach ($MachinePackageProperty in $InstalledMachinePackageProperties) {
        New-ItemProperty -LiteralPath $KnownPackages `
            -Name $MachinePackageProperty.Name `
            -Value ([string]$MachinePackageProperty.Value) `
            -PropertyType String -Force | Out-Null
    }
    foreach ($MissingMachinePackageProperty in $MissingMachinePackageProperties) {
        Remove-ItemProperty -LiteralPath $KnownPackages `
            -Name $MissingMachinePackageProperty.Name -ErrorAction SilentlyContinue
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


if (-not $WhatIfPreference) {
    $EffectivePackageProperties = @(
        (Get-ItemProperty -LiteralPath $KnownPackages).PSObject.Properties |
            Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' }
    )
    foreach ($RequiredStandardPackage in $RequiredStandardPackages) {
        if (-not ($EffectivePackageProperties.Name -contains $RequiredStandardPackage)) {
            throw "Safety verification failed: $RequiredStandardPackage is not visible in the per-user package list."
        }
    }
    foreach ($MissingMachinePackageProperty in $MissingMachinePackageProperties) {
        if ($EffectivePackageProperties.Name -contains $MissingMachinePackageProperty.Name) {
            throw "Safety verification failed: a package whose BPL is missing remains registered: $($MissingMachinePackageProperty.Name)"
        }
    }
    foreach ($SelectedFramework in $Frameworks) {
        $DesignFile = Join-Path $Destination "DATLanguageManager${SelectedFramework}Design.bpl"
        if (-not ($EffectivePackageProperties.Name -contains $DesignFile)) {
            throw "Safety verification failed: DAT design package is not registered: $DesignFile"
        }
    }
    if ($EffectivePackageProperties.Count -lt $InstalledMachinePackageProperties.Count) {
        throw 'Safety verification failed: the per-user package list is incomplete.'
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
