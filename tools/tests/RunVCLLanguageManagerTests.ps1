[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$Targets = @(
    @{ Compiler = 'dcc32'; Platform = 'Win32' },
    @{ Compiler = 'dcc64'; Platform = 'Win64' }
)

foreach ($Target in $Targets) {
    $OutputDirectory = Join-Path $ProjectRoot `
        "bin\$($Target.Platform)\Debug"
    $DcuDirectory = Join-Path $ProjectRoot `
        "dcu\$($Target.Platform)\Debug"
    New-Item -ItemType Directory -Force `
        -Path $OutputDirectory, $DcuDirectory | Out-Null

    Push-Location $PSScriptRoot
    try {
        $Command = 'call "' + $RsVars + '" && ' +
            $Target.Compiler + ' -B -Q -E"' + $OutputDirectory +
            '" -N0"' + $DcuDirectory + '" "VCLLanguageManagerTests.dpr"'
        & cmd.exe /d /c $Command
        if ($LASTEXITCODE -ne 0) {
            throw "VCLLanguageManagerTests failed to compile for $($Target.Platform)."
        }
    }
    finally {
        Pop-Location
    }

    $Executable = Join-Path $OutputDirectory 'VCLLanguageManagerTests.exe'
    & $Executable
    if ($LASTEXITCODE -ne 0) {
        throw "VCLLanguageManagerTests failed for $($Target.Platform)."
    }
}

Write-Output 'TDATLanguageManager Phase 4 VCL tests passed for Win32 and Win64.'
