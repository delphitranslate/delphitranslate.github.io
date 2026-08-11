param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$expectedWindowTitle = 'Delphi App Translation Studio'
$studioExecutables = @(
    [PSCustomObject]@{
        Platform = 'Win32'
        Configuration = 'Debug'
        Path = Join-Path $ProjectRoot 'bin\Win32\Debug\DelphiAppTranslationStudio.exe'
    },
    [PSCustomObject]@{
        Platform = 'Win64'
        Configuration = 'Debug'
        Path = Join-Path $ProjectRoot 'bin\Win64\Debug\DelphiAppTranslationStudio.exe'
    },
    [PSCustomObject]@{
        Platform = 'Win32'
        Configuration = 'Release'
        Path = Join-Path $ProjectRoot 'bin\Win32\Release\DelphiAppTranslationStudio.exe'
    },
    [PSCustomObject]@{
        Platform = 'Win64'
        Configuration = 'Release'
        Path = Join-Path $ProjectRoot 'bin\Win64\Release\DelphiAppTranslationStudio.exe'
    }
)

$smokeResults = @()
foreach ($studioExecutable in $studioExecutables) {
    if (-not (Test-Path -LiteralPath $studioExecutable.Path)) {
        throw "Studio executable not found: $($studioExecutable.Path)"
    }

    $studioProcess = Start-Process -FilePath $studioExecutable.Path `
        -PassThru -WindowStyle Hidden
    try {
        $lastWindowTitle = ''
        $startupPassed = $false

        for ($attempt = 1; $attempt -le 24; $attempt++) {
            Start-Sleep -Milliseconds 250
            $studioProcess.Refresh()

            if ($studioProcess.HasExited) {
                throw "$($studioExecutable.Path) exited during startup with code $($studioProcess.ExitCode)."
            }

            $lastWindowTitle = $studioProcess.MainWindowTitle
            if ($lastWindowTitle -eq 'Error') {
                throw "$($studioExecutable.Path) opened a startup Error dialog."
            }

            if ($lastWindowTitle -eq $expectedWindowTitle) {
                $startupPassed = $true
                break
            }
        }

        if (-not $startupPassed) {
            throw "$($studioExecutable.Path) did not expose the expected main-form title. Last title: '$lastWindowTitle'."
        }

        $smokeResults += [PSCustomObject]@{
            Platform = $studioExecutable.Platform
            Configuration = $studioExecutable.Configuration
            MainWindowTitle = $lastWindowTitle
            Startup = 'Passed'
        }
    }
    finally {
        if (-not $studioProcess.HasExited) {
            Stop-Process -Id $studioProcess.Id -Force
            $null = $studioProcess.WaitForExit(5000)
        }
        $studioProcess.Dispose()
    }
}

$smokeResults | Format-Table -AutoSize
Write-Output 'Studio launch smoke tests passed.'
