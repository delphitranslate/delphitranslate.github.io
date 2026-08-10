param([Parameter(Mandatory = $true)][string]$PythonPath)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$guideDirectory = Join-Path $projectRoot 'docs\guides'
$guides = @(
    'Delphi App Translation Studio User Guide',
    'Delphi App Translation Studio Setup Wizard Guide',
    'Delphi App Translation Studio Engineering Guide'
)

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    foreach ($guide in $guides) {
        $docxPath = Join-Path $guideDirectory ($guide + '.docx')
        if (-not (Test-Path -LiteralPath $docxPath)) {
            throw "Guide not found: $docxPath"
        }

        $document = $word.Documents.Open($docxPath)
        try {
            foreach ($tableOfContents in $document.TablesOfContents) {
                $tableOfContents.Update()
            }
            $document.Save()
        }
        finally {
            $document.Close(0)
            [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject(
                $document) | Out-Null
        }
    }
}
finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($word) |
        Out-Null
}

& $PythonPath (Join-Path $PSScriptRoot 'render_guides_pdf.py')
if ($LASTEXITCODE -ne 0) {
    throw 'Playwright PDF generation failed.'
}

Write-Output 'Word TOCs updated and companion PDFs generated.'
