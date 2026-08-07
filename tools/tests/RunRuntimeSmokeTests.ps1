[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\..'))
$RsVars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$IntegrationSmokeDirectory = Join-Path $ProjectRoot 'export\IntegrationSmoke'
$TargetIntegrationSmokeDirectory = Join-Path $ProjectRoot `
    'export\TargetIntegrationSmoke'
$TargetIntegrationPackagesDirectory = Join-Path $ProjectRoot `
    'export\TargetIntegrationPackages'
$TargetIntegrationBackupsDirectory = Join-Path $ProjectRoot `
    'export\TargetIntegrationBackups'

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

function Invoke-IntegratedProjectBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectDirectory,
        [Parameter(Mandatory = $true)]
        [string]$ProjectFileName,
        [Parameter(Mandatory = $true)]
        [string]$Platform
    )

    Push-Location $ProjectDirectory
    try {
        $Command = 'call "' + $RsVars + '" && msbuild "' +
            $ProjectFileName + '" /t:Build /p:Config=Debug /p:Platform=' +
            $Platform + ' /v:minimal'
        & cmd.exe /d /c $Command
        if ($LASTEXITCODE -ne 0) {
            throw "$ProjectFileName integration build failed for $Platform."
        }
    }
    finally {
        Pop-Location
    }
}

function Test-IntegratedApplicationWindow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    $Process = Start-Process -FilePath $Executable -PassThru
    try {
        $Deadline = (Get-Date).AddSeconds(8)
        do {
            Start-Sleep -Milliseconds 150
            $Process.Refresh()
        }
        while (($Process.MainWindowTitle -ne 'Customer Manager') -and
            ((Get-Date) -lt $Deadline) -and (-not $Process.HasExited))

        if ($Process.MainWindowTitle -ne 'Customer Manager') {
            throw "Integrated application did not open its expected form: $Executable"
        }
    }
    finally {
        if (-not $Process.HasExited) {
            Stop-Process -Id $Process.Id -Force
            $null = $Process.WaitForExit(5000)
        }
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

    foreach ($Target in @(
        @{ Compiler = 'dcc32'; Platform = 'Win32' },
        @{ Compiler = 'dcc64'; Platform = 'Win64' }
    )) {
        Invoke-IntegratedProjectBuild `
            -ProjectDirectory (Join-Path $TargetIntegrationSmokeDirectory `
                'VCLBasic') `
            -ProjectFileName 'SampleVCLApp.dproj' `
            -Platform $Target.Platform
        Invoke-IntegratedProjectBuild `
            -ProjectDirectory (Join-Path $TargetIntegrationSmokeDirectory `
                'FMXBasic') `
            -ProjectFileName 'SampleFMXApp.dproj' `
            -Platform $Target.Platform
        Test-IntegratedApplicationWindow -Executable (Join-Path $ProjectRoot `
            "export\bin\Samples\VCLBasic\$($Target.Platform)\Debug\SampleVCLApp.exe")
        Test-IntegratedApplicationWindow -Executable (Join-Path $ProjectRoot `
            "export\bin\Samples\FMXBasic\$($Target.Platform)\Debug\SampleFMXApp.exe")
    }

    Write-Host 'Offline runtime and integration smoke tests passed.'
}
finally {
    $CleanupDirectories = @(
        $IntegrationSmokeDirectory,
        $TargetIntegrationSmokeDirectory,
        $TargetIntegrationPackagesDirectory,
        $TargetIntegrationBackupsDirectory,
        (Join-Path $ProjectRoot 'export\bin\Samples\VCLBasic'),
        (Join-Path $ProjectRoot 'export\bin\Samples\FMXBasic'),
        (Join-Path $ProjectRoot 'export\dcu\Samples\VCLBasic'),
        (Join-Path $ProjectRoot 'export\dcu\Samples\FMXBasic')
    )
    foreach ($CleanupDirectory in $CleanupDirectories) {
        if (Test-Path -LiteralPath $CleanupDirectory) {
            $ResolvedTarget = (Resolve-Path -LiteralPath `
                $CleanupDirectory).Path
            $ExportRoot = [System.IO.Path]::GetFullPath(
                (Join-Path $ProjectRoot 'export'))
            if (-not $ResolvedTarget.StartsWith(
                $ExportRoot + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase)) {
                throw 'Unexpected integration smoke-test cleanup target.'
            }
            Remove-Item -LiteralPath $ResolvedTarget -Recurse -Force
        }
    }
}
