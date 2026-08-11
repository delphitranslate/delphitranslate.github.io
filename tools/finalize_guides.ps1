param(
    [string]$LibreOfficePath =
        'C:\Program Files\LibreOffice\program\soffice.com'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$guideDirectory = Join-Path $projectRoot 'docs\guides'
$pdfDirectory = Join-Path $projectRoot 'docs\pdf'
$guides = @(
    'Delphi App Translation Studio User Guide',
    'Delphi App Translation Studio Setup Wizard Guide',
    'Delphi App Translation Studio Engineering Guide'
)
$conversionTimeoutMilliseconds = 120000
$terminationWaitMilliseconds = 5000

if (-not (Test-Path -LiteralPath $LibreOfficePath)) {
    throw "LibreOffice command-line executable not found: $LibreOfficePath"
}

New-Item -ItemType Directory -Path $pdfDirectory -Force | Out-Null

foreach ($guide in $guides) {
    $docxPath = Join-Path $guideDirectory ($guide + '.docx')
    $pdfPath = Join-Path $pdfDirectory ($guide + '.pdf')
    if (-not (Test-Path -LiteralPath $docxPath)) {
        throw "Guide not found: $docxPath"
    }

    $process = Start-Process -FilePath $LibreOfficePath -ArgumentList @(
        '--headless',
        '--convert-to', 'pdf',
        '--outdir', ('"{0}"' -f $pdfDirectory),
        ('"{0}"' -f $docxPath)
    ) -PassThru -WindowStyle Hidden
    try {
        if (-not $process.WaitForExit($conversionTimeoutMilliseconds)) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $null = $process.WaitForExit($terminationWaitMilliseconds)
            throw "LibreOffice timed out while exporting $guide. Its process was stopped."
        }
        if ($process.ExitCode -ne 0) {
            throw "LibreOffice failed while exporting $guide with exit code $($process.ExitCode)."
        }
    }
    finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $null = $process.WaitForExit($terminationWaitMilliseconds)
        }
        $process.Dispose()
    }

    if (-not (Test-Path -LiteralPath $pdfPath)) {
        throw "LibreOffice did not create the expected PDF: $pdfPath"
    }
    Write-Output "LibreOffice exported $guide.pdf."
}

Write-Output 'Guide finalization completed without background PowerShell jobs.'
