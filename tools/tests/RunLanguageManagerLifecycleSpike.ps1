[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$SourceSearchPath = ((Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source') `
    -Directory | Select-Object -ExpandProperty FullName) -join ';')
$TestPrograms = @(
    'FMXManagerLifecycleSpikeTests',
    'VCLManagerLifecycleSpikeTests',
    'VCLManagerMDILifecycleSpikeTests'
)
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
        foreach ($TestProgram in $TestPrograms) {
            $SourceFile = "$TestProgram.dpr"
            $Command = 'call "' + $RsVars + '" && ' +
                $Target.Compiler + ' -B -Q -E"' + $OutputDirectory +
                '" -N0"' + $DcuDirectory + '" -U"' +
                $SourceSearchPath + '" "' + $SourceFile + '"'
            & cmd.exe /d /c $Command
            if ($LASTEXITCODE -ne 0) {
                throw "$SourceFile failed to compile for $($Target.Platform)."
            }
        }
    }
    finally {
        Pop-Location
    }

    foreach ($TestProgram in $TestPrograms) {
        $Executable = Join-Path $OutputDirectory "$TestProgram.exe"
        & $Executable
        if ($LASTEXITCODE -ne 0) {
            throw "$TestProgram failed for $($Target.Platform)."
        }
    }
}

Write-Output 'TDATLanguageManager Phase 1 lifecycle spike completed for Win32 and Win64.'
