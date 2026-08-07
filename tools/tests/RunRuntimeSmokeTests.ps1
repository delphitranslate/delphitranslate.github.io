[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$IntegrationSmokeDirectory = Join-Path $ProjectRoot 'export\IntegrationSmoke'

function Invoke-Compiler {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Compiler,
        [Parameter(Mandatory = $true)]
        [string]$Platform,
        [Parameter(Mandatory = $true)]
        [string]$SourceFile
    )

    $OutputDirectory = Join-Path $ProjectRoot "bin\$Platform\Debug"
    $DcuDirectory = Join-Path $ProjectRoot "dcu\$Platform\Debug"
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $DcuDirectory -Force | Out-Null

    Push-Location $PSScriptRoot
    try {
        $Command = 'call "' + $RsVars + '" && ' + $Compiler +
            ' -B -Q -E"' + $OutputDirectory + '" -N0"' +
            $DcuDirectory + '" "' + $SourceFile + '"'
        & cmd.exe /d /c $Command
        if ($LASTEXITCODE -ne 0) {
            throw "$Compiler failed for $SourceFile."
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-GeneratedUnitCompiler {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Compiler,
        [Parameter(Mandatory = $true)]
        [string]$Platform,
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $PackageDirectory = Join-Path $IntegrationSmokeDirectory $PackageName
    $DcuDirectory = Join-Path $ProjectRoot "dcu\$Platform\Debug"
    Push-Location $PackageDirectory
    try {
        $Command = 'call "' + $RsVars + '" && ' + $Compiler +
            ' -B -Q -URuntime -N0"' + $DcuDirectory + '" "' +
            $PackageName + '.Translation.pas"'
        & cmd.exe /d /c $Command
        if ($LASTEXITCODE -ne 0) {
            throw "$Compiler failed for the generated $PackageName unit."
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-SmokeExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Platform,
        [Parameter(Mandatory = $true)]
        [string]$ProgramName
    )

    $Executable = Join-Path $ProjectRoot "bin\$Platform\Debug\$ProgramName.exe"
    & $Executable
    if ($LASTEXITCODE -ne 0) {
        throw "$ProgramName failed for $Platform."
    }
}

try {
    foreach ($Target in @(
        @{ Compiler = 'dcc32'; Platform = 'Win32' },
        @{ Compiler = 'dcc64'; Platform = 'Win64' }
    )) {
        Invoke-Compiler @Target -SourceFile 'FoundationSmokeTests.dpr'
        Invoke-SmokeExecutable -Platform $Target.Platform `
            -ProgramName 'FoundationSmokeTests'

        Invoke-GeneratedUnitCompiler @Target -PackageName 'SampleVCLApp'
        Invoke-GeneratedUnitCompiler @Target -PackageName 'SampleFMXApp'

        Invoke-Compiler @Target -SourceFile 'VCLRuntimeSmokeTests.dpr'
        Invoke-Compiler @Target -SourceFile 'FMXRuntimeSmokeTests.dpr'
        Invoke-SmokeExecutable -Platform $Target.Platform `
            -ProgramName 'VCLRuntimeSmokeTests'
        Invoke-SmokeExecutable -Platform $Target.Platform `
            -ProgramName 'FMXRuntimeSmokeTests'
    }

    Write-Host 'Offline runtime and integration smoke tests passed.'
}
finally {
    if (Test-Path -LiteralPath $IntegrationSmokeDirectory) {
        $ResolvedTarget = (Resolve-Path -LiteralPath `
            $IntegrationSmokeDirectory).Path
        $ExpectedTarget = [System.IO.Path]::GetFullPath(
            (Join-Path $ProjectRoot 'export\IntegrationSmoke'))
        if ($ResolvedTarget -ne $ExpectedTarget) {
            throw 'Unexpected integration smoke-test cleanup target.'
        }
        Remove-Item -LiteralPath $ResolvedTarget -Recurse -Force
    }
}
