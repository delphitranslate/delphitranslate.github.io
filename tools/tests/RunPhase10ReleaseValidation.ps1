[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$ProjectFile = Join-Path $ProjectRoot 'DelphiAppTranslationStudio.dproj'
$SourceSearchPath = @(
    '..\..\source\studio'
    '..\..\source\core'
    '..\..\source\scan'
    '..\..\source\runtime'
    '..\..\source\integration'
    '..\..\source\provider'
    '..\..\source\validation'
    '..\..\source\review'
) -join ';'

$BackgroundJobCommand = 'Start' + '-Job'
$BackgroundPowerShellJobs = Get-ChildItem -LiteralPath $ProjectRoot `
    -Recurse -Filter '*.ps1' -File | Select-String `
        -SimpleMatch $BackgroundJobCommand
if ($BackgroundPowerShellJobs) {
    throw 'PowerShell background jobs are not permitted in project scripts.'
}

function Invoke-CheckedScript {
    param([Parameter(Mandatory = $true)][string]$FileName,
        [string[]]$Arguments = @())

    & $FileName @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Validation script failed: $FileName $Arguments"
    }
}

foreach ($Configuration in @('Debug', 'Release')) {
    $PackageTestScript = Join-Path $PSScriptRoot `
        'RunLanguageManagerPackageTests.ps1'
    Invoke-CheckedScript -FileName $PackageTestScript `
        -Arguments @($Configuration)
}

foreach ($TestScript in @(
        'RunLanguageManagerCoreTests.ps1',
        'RunFMXLanguageManagerTests.ps1',
        'RunVCLLanguageManagerTests.ps1',
        'RunRuntimeSmokeTests.ps1')) {
    Invoke-CheckedScript (Join-Path $PSScriptRoot $TestScript)
}

foreach ($Configuration in @('Debug', 'Release')) {
    foreach ($Platform in @('Win32', 'Win64')) {
        Push-Location $ProjectRoot
        try {
            $BuildCommand = 'call "' + $RsVars + '" && msbuild "' +
                $ProjectFile + '" /t:Build /p:Config=' + $Configuration +
                ' /p:Platform=' + $Platform + ' /v:minimal'
            & cmd.exe /d /c $BuildCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Studio $Platform $Configuration build failed."
            }
        }
        finally {
            Pop-Location
        }

        $Compiler = if ($Platform -eq 'Win32') { 'dcc32' } else { 'dcc64' }
        $DefineSwitch = if ($Configuration -eq 'Release') {
            '-DRELEASE'
        }
        else {
            '-DDEBUG'
        }
        $ExecutableOutput = Join-Path $ProjectRoot `
            "bin\$Platform\$Configuration"
        $DcuOutput = Join-Path $ProjectRoot `
            "dcu\$Platform\$Configuration"
        New-Item -ItemType Directory -Force -Path $ExecutableOutput,
            $DcuOutput | Out-Null
        Push-Location $PSScriptRoot
        try {
            $CompileCommand = 'call "' + $RsVars + '" && ' + $Compiler +
                ' -B -Q ' + $DefineSwitch + ' -E"' + $ExecutableOutput +
                '" -N0"' + $DcuOutput + '" -U"' + $SourceSearchPath +
                '" "StudioFormSmokeTests.dpr"'
            & cmd.exe /d /c $CompileCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Studio form test compile failed for $Platform $Configuration."
            }
        }
        finally {
            Pop-Location
        }
        & (Join-Path $ExecutableOutput 'StudioFormSmokeTests.exe')
        if ($LASTEXITCODE -ne 0) {
            throw "Studio form test failed for $Platform $Configuration."
        }
    }
}

$LaunchTestScript = Join-Path $PSScriptRoot `
    'RunStudioLaunchSmokeTests.ps1'
$SelfLocalizationTestScript = Join-Path $PSScriptRoot `
    'RunStudioSelfLocalizationSmokeTest.ps1'
Invoke-CheckedScript $LaunchTestScript
Invoke-CheckedScript $SelfLocalizationTestScript

Write-Output 'Phase 10 complete release validation passed.'
