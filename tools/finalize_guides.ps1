param([string]$PythonPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$guideDirectory = Join-Path $projectRoot 'docs\guides'
$pdfDirectory = Join-Path $projectRoot 'docs\pdf'
$guides = @(
    'Delphi App Translation Studio User Guide',
    'Delphi App Translation Studio Setup Wizard Guide',
    'Delphi App Translation Studio Engineering Guide'
)

if ([string]::IsNullOrWhiteSpace($PythonPath)) {
    $PythonPath = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
}
New-Item -ItemType Directory -Path $pdfDirectory -Force | Out-Null
$wordSucceeded = $true
$wordPidsBefore = @(Get-Process WINWORD -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

foreach ($guide in $guides) {
    $docxPath = Join-Path $guideDirectory ($guide + '.docx')
    $pdfPath = Join-Path $pdfDirectory ($guide + '.pdf')
    if (-not (Test-Path -LiteralPath $docxPath)) { throw "Guide not found: $docxPath" }
    $job = Start-Job -ArgumentList $docxPath, $pdfPath -ScriptBlock {
        param($InputDocx, $OutputPdf)
        $word = $null
        $document = $null
        try {
            $word = New-Object -ComObject Word.Application
            $word.Visible = $false
            $word.DisplayAlerts = 0
            $document = $word.Documents.Open($InputDocx, $false, $false)
            for ($index = 1; $index -le $document.TablesOfContents.Count; $index++) {
                $document.TablesOfContents.Item($index).Update()
            }
            $document.Repaginate()
            $document.Save()
            $document.ExportAsFixedFormat($OutputPdf, 17)
        }
        finally {
            if ($null -ne $document) { $document.Close($false) }
            if ($null -ne $word) { $word.Quit() }
        }
    }
    if (-not (Wait-Job $job -Timeout 45)) {
        Stop-Job $job
        $wordSucceeded = $false
        Write-Warning "Microsoft Word timed out while finalizing $guide; the approved HTML/CSS PDF fallback will be used."
    }
    elseif ($job.State -ne 'Completed') {
        $wordSucceeded = $false
        Write-Warning "Microsoft Word failed while finalizing $guide; the approved HTML/CSS PDF fallback will be used."
    }
    Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
    Remove-Job $job -Force
    if (-not $wordSucceeded) { break }
    Write-Output "Microsoft Word finalized $guide.docx and exported its PDF."
}

if (-not $wordSucceeded) {
    Get-Process WINWORD -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -notin $wordPidsBefore } |
        Stop-Process -Force
    if (-not (Test-Path -LiteralPath $PythonPath)) {
        throw "Bundled Python runtime not found for PDF fallback: $PythonPath"
    }
    & $PythonPath (Join-Path $PSScriptRoot 'render_guides_pdf.py')
    if ($LASTEXITCODE -ne 0) { throw 'HTML/CSS PDF fallback failed.' }
    Write-Output 'Playwright HTML/CSS fallback generated all companion PDFs.'
}

Write-Output 'Guide finalization completed.'
