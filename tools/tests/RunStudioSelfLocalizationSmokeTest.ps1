[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$FixturePack = Join-Path $ProjectRoot `
    'samples\StudioSelfLocalization\it-IT.json'
$LocalizationDirectory = Join-Path $ProjectRoot 'Localization'
$LanguagesDirectory = Join-Path $LocalizationDirectory 'Languages'
$TargetPack = Join-Path $LanguagesDirectory 'it-IT.json'
$PreferenceFile = Join-Path $LocalizationDirectory 'language.ini'
$ExpectedTitle = 'Studio di traduzione app Delphi'
$TemporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('DAT-SelfLocalization-' + [Guid]::NewGuid().ToString('N'))
$SavedPack = Join-Path $TemporaryDirectory 'it-IT.json'
$SavedPreference = Join-Path $TemporaryDirectory 'language.ini'
$PackExisted = Test-Path -LiteralPath $TargetPack
$PreferenceExisted = Test-Path -LiteralPath $PreferenceFile

New-Item -ItemType Directory -Path $TemporaryDirectory -Force | Out-Null
if ($PackExisted) {
    Copy-Item -LiteralPath $TargetPack -Destination $SavedPack -Force
}
if ($PreferenceExisted) {
    Copy-Item -LiteralPath $PreferenceFile `
        -Destination $SavedPreference -Force
}

try {
    New-Item -ItemType Directory -Path $LanguagesDirectory -Force | Out-Null
    Copy-Item -LiteralPath $FixturePack -Destination $TargetPack -Force
    [System.IO.File]::WriteAllText(
        $PreferenceFile,
        "[Language]`r`nSelected=it-IT`r`n",
        [System.Text.UTF8Encoding]::new($false))

    $Configurations = @(
        @{ Platform = 'Win32'; Configuration = 'Debug' },
        @{ Platform = 'Win64'; Configuration = 'Debug' },
        @{ Platform = 'Win32'; Configuration = 'Release' },
        @{ Platform = 'Win64'; Configuration = 'Release' }
    )
    $Results = @()
    foreach ($Configuration in $Configurations) {
        $Executable = Join-Path $ProjectRoot (
            'bin\{0}\{1}\DelphiAppTranslationStudio.exe' -f
            $Configuration.Platform, $Configuration.Configuration)
        if (-not (Test-Path -LiteralPath $Executable)) {
            throw "Studio executable not found: $Executable"
        }

        $Process = Start-Process -FilePath $Executable -PassThru
        try {
            $Deadline = (Get-Date).AddSeconds(10)
            do {
                Start-Sleep -Milliseconds 150
                $Process.Refresh()
            }
            while (($Process.MainWindowTitle -ne $ExpectedTitle) -and
                ((Get-Date) -lt $Deadline) -and (-not $Process.HasExited))

            $Results += [pscustomobject]@{
                Platform = $Configuration.Platform
                Configuration = $Configuration.Configuration
                MainWindowTitle = $Process.MainWindowTitle
                Passed = ($Process.MainWindowTitle -eq $ExpectedTitle)
            }
        }
        finally {
            if (-not $Process.HasExited) {
                Stop-Process -Id $Process.Id -Force
            }
        }
    }

    $Results | Format-Table -AutoSize
    if ($Results.Where({ -not $_.Passed }).Count -gt 0) {
        throw 'One or more Studio self-localization launch checks failed.'
    }
    Write-Host 'Studio self-localization smoke tests passed.'
}
finally {
    if ($PackExisted) {
        Copy-Item -LiteralPath $SavedPack -Destination $TargetPack -Force
    }
    elseif (Test-Path -LiteralPath $TargetPack) {
        Remove-Item -LiteralPath $TargetPack -Force
    }

    if ($PreferenceExisted) {
        Copy-Item -LiteralPath $SavedPreference `
            -Destination $PreferenceFile -Force
    }
    elseif (Test-Path -LiteralPath $PreferenceFile) {
        Remove-Item -LiteralPath $PreferenceFile -Force
    }

    if ((Test-Path -LiteralPath $LanguagesDirectory) -and
        ((Get-ChildItem -LiteralPath $LanguagesDirectory -Force).Count -eq 0)) {
        Remove-Item -LiteralPath $LanguagesDirectory -Force
    }
    if ((Test-Path -LiteralPath $LocalizationDirectory) -and
        ((Get-ChildItem -LiteralPath $LocalizationDirectory -Force).Count -eq 0)) {
        Remove-Item -LiteralPath $LocalizationDirectory -Force
    }
    if (Test-Path -LiteralPath $TemporaryDirectory) {
        Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force
    }
}
