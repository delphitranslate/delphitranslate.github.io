[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$RuntimePackages = @(
    'DATLanguageManagerCoreRuntime',
    'DATLanguageManagerVCLRuntime',
    'DATLanguageManagerFMXRuntime'
)
$DesignPackages = @(
    'DATLanguageManagerVCLDesign',
    'DATLanguageManagerFMXDesign'
)
$Targets = @(
    @{ Compiler = 'dcc32'; Platform = 'Win32' },
    @{ Compiler = 'dcc64'; Platform = 'Win64' }
)

foreach ($Target in $Targets) {
    $PackageOutput = Join-Path $ProjectRoot `
        "bin\packages\$($Target.Platform)\Debug"
    $DcuOutput = Join-Path $ProjectRoot `
        "dcu\packages\$($Target.Platform)\Debug"
    New-Item -ItemType Directory -Force -Path $PackageOutput, $DcuOutput |
        Out-Null

    foreach ($PackageName in $RuntimePackages) {
        $PackageFile = Join-Path $ProjectRoot `
            "packages\runtime\$PackageName.dpk"
        $Command = 'call "' + $RsVars + '" && ' + $Target.Compiler +
            ' -B -Q -LE"' + $PackageOutput + '" -LN"' + $PackageOutput +
            '" -N0"' + $DcuOutput + '" -U"' + $PackageOutput +
            '" "' + (Split-Path $PackageFile -Leaf) + '"'
        Push-Location (Split-Path $PackageFile -Parent)
        try {
            & cmd.exe /d /c $Command
            if ($LASTEXITCODE -ne 0) {
                throw "$PackageName failed for $($Target.Platform)."
            }
        }
        finally {
            Pop-Location
        }
    }

    if ($Target.Platform -eq 'Win32') {
        foreach ($PackageName in $DesignPackages) {
            $PackageFile = Join-Path $ProjectRoot `
                "packages\design\$PackageName.dpk"
            $Command = 'call "' + $RsVars + '" && dcc32 -B -Q -LE"' +
                $PackageOutput + '" -LN"' + $PackageOutput + '" -N0"' +
                $DcuOutput + '" -U"' + $PackageOutput + '" "' +
                (Split-Path $PackageFile -Leaf) + '"'
            Push-Location (Split-Path $PackageFile -Parent)
            try {
                & cmd.exe /d /c $Command
                if ($LASTEXITCODE -ne 0) {
                    throw "$PackageName design package failed."
                }
            }
            finally {
                Pop-Location
            }
        }
    }

    foreach ($TestName in @('VCLDesignStreamingTests',
            'FMXDesignStreamingTests')) {
        $ExecutableOutput = Join-Path $ProjectRoot `
            "bin\$($Target.Platform)\Debug"
        Push-Location $PSScriptRoot
        try {
            $Command = 'call "' + $RsVars + '" && ' + $Target.Compiler +
                ' -B -Q -E"' + $ExecutableOutput + '" -N0"' + $DcuOutput +
                '" "' + $TestName + '.dpr"'
            & cmd.exe /d /c $Command
            if ($LASTEXITCODE -ne 0) {
                throw "$TestName failed to compile for $($Target.Platform)."
            }
        }
        finally {
            Pop-Location
        }
        $Executable = Join-Path $ExecutableOutput "$TestName.exe"
        & $Executable
        if ($LASTEXITCODE -ne 0) {
            throw "$TestName failed for $($Target.Platform)."
        }
    }
}

Write-Output 'Phase 6/7 packages, streaming, discovery, and selector tests passed.'
