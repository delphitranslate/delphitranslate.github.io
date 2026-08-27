[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug'
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$SourceSearchPath = ((Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source') `
    -Directory | Select-Object -ExpandProperty FullName) -join ';')
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
$DefineSwitch = if ($Configuration -eq 'Release') {
    '-DRELEASE'
}
else {
    '-DDEBUG'
}

foreach ($Target in $Targets) {
    $PackageOutput = Join-Path $ProjectRoot `
        "bin\packages\$($Target.Platform)\$Configuration"
    $DcuOutput = Join-Path $ProjectRoot `
        "dcu\packages\$($Target.Platform)\$Configuration"
    New-Item -ItemType Directory -Force -Path $PackageOutput, $DcuOutput |
        Out-Null

    foreach ($PackageName in $RuntimePackages) {
        $PackageFile = Join-Path $ProjectRoot `
            "packages\runtime\$PackageName.dpk"
        $Command = 'call "' + $RsVars + '" && ' + $Target.Compiler +
            ' -B -Q ' + $DefineSwitch + ' -LE"' + $PackageOutput + '" -LN"' + $PackageOutput +
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
            $Command = 'call "' + $RsVars + '" && dcc32 -B -Q ' +
                $DefineSwitch + ' -LE"' +
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
            "bin\tests\packages\$($Target.Platform)\$Configuration"
        New-Item -ItemType Directory -Force -Path $ExecutableOutput |
            Out-Null
        Push-Location $PSScriptRoot
        try {
            $Command = 'call "' + $RsVars + '" && ' + $Target.Compiler +
                ' -B -Q ' + $DefineSwitch + ' -E"' + $ExecutableOutput + '" -N0"' + $DcuOutput +
                '" -U"' + $SourceSearchPath + ';' + $PackageOutput +
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

Write-Output "Phase 6/7 $Configuration packages, streaming, discovery, and selector tests passed."
