<#
Builds the Engineering Guide .docx from its HTML source, and its PDF from that.

Three steps, and the middle one is the reason this script exists rather than a
line in somebody's notes.

  1. The two figures are rendered from their .svg originals to .png at twice
     the size they are placed at, so they stay sharp in print. The .svg files
     are the source of truth and the things worth editing; the .png files are
     build output that happens to live beside them because the HTML has to name
     them. They were once produced by hand and not kept, and the guide was
     rebuilt without its diagrams as a result.

  2. LibreOffice converts the HTML to .docx and *links* the figures rather than
     embedding them - an absolute path into this machine. The document looks
     right here and arrives with two empty frames anywhere else. Turning those
     links into embedded parts is done by tools\embed_docx_images.py, which
     explains why it is Python and not more PowerShell.

  3. The .pdf is produced from the finished .docx, so what is read is what was
     built rather than a second conversion of the source.

The guide's own appearance - heading spacing above all - comes from the
stylesheet at the top of the HTML. Without it LibreOffice's defaults give
Heading 2 and Heading 3 `w:after="0"`: no space at all beneath them, so every
subheading sits hard against its first paragraph.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$LibreOffice = 'C:\Program Files\LibreOffice\program\soffice.com',
  [string]$Python = 'C:\Users\marti\AppData\Local\Microsoft\WindowsApps\python.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if (-not (Test-Path -LiteralPath $LibreOffice)) {
  throw "LibreOffice command-line executable not found: $LibreOffice"
}
if (-not (Test-Path -LiteralPath $Python)) {
  throw "Python not found: $Python"
}

$guideDirectory = Join-Path $ProjectRoot 'docs\guides'
$pdfDirectory   = Join-Path $ProjectRoot 'docs\pdf'
$embedScript    = Join-Path $ProjectRoot 'tools\embed_docx_images.py'
$guideName      = 'Delphi App Translation Studio Engineering Guide'
$sourceHtml     = Join-Path $guideDirectory ($guideName + '.source.html')
$finalDocx      = Join-Path $guideDirectory ($guideName + '.docx')

foreach ($required in @($sourceHtml, $embedScript)) {
  if (-not (Test-Path -LiteralPath $required)) {
    throw "Not found: $required"
  }
}
New-Item -ItemType Directory -Force -Path $pdfDirectory | Out-Null

$work = Join-Path ([System.IO.Path]::GetTempPath()) `
  ('dat-guide-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Invoke-LibreOffice {
  param([string[]]$Arguments)
  # No 2>&1 here. LibreOffice writes a harmless "Could not find platform
  # independent libraries" line to stderr on this machine, and Windows
  # PowerShell turns any redirected stderr from a native program into an error
  # record - so redirecting would fail every successful conversion. The exit
  # code is the thing worth reading.
  & $LibreOffice @Arguments | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw ('LibreOffice conversion failed (exit {0}): {1}' -f
      $LASTEXITCODE, ($Arguments -join ' '))
  }
}

try {
  # --- 1. figures -------------------------------------------------------------
  $figures = @(
    @{ Name = 'fig1-pipeline'; Width = 2080; Height = 660 }
    @{ Name = 'fig2-seams';    Width = 2080; Height = 800 }
  )
  foreach ($figure in $figures) {
    $svg = Join-Path $guideDirectory ($figure.Name + '.svg')
    if (-not (Test-Path -LiteralPath $svg)) {
      throw "Figure source not found: $svg"
    }
    $filter = 'png:draw_png_Export:{{"PixelWidth":{{"type":"long","value":{0}}},"PixelHeight":{{"type":"long","value":{1}}}}}' -f
      $figure.Width, $figure.Height
    Invoke-LibreOffice @('--headless', '--convert-to', $filter,
      '--outdir', $guideDirectory, $svg)
    Write-Output ("rendered {0}.png" -f $figure.Name)
  }

  # --- 2. document ------------------------------------------------------------
  Invoke-LibreOffice @('--headless', '--convert-to', 'docx:MS Word 2007 XML',
    '--outdir', $work, $sourceHtml)
  $linkedDocx = Join-Path $work ($guideName + '.source.docx')
  if (-not (Test-Path -LiteralPath $linkedDocx)) {
    throw "LibreOffice produced no .docx in $work"
  }

  $embeddedDocx = Join-Path $work 'guide.docx'
  & $Python $embedScript $linkedDocx $embeddedDocx
  if ($LASTEXITCODE -ne 0) {
    throw 'Embedding the figures failed.'
  }
  Copy-Item -LiteralPath $embeddedDocx -Destination $finalDocx -Force
  Write-Output ("built {0} ({1:N0} bytes)" -f
    (Split-Path -Leaf $finalDocx), (Get-Item -LiteralPath $finalDocx).Length)

  # --- 3. pdf -----------------------------------------------------------------
  Invoke-LibreOffice @('--headless', '--convert-to', 'pdf',
    '--outdir', $pdfDirectory, $finalDocx)
  $pdf = Join-Path $pdfDirectory ($guideName + '.pdf')
  Write-Output ("built {0} ({1:N0} bytes)" -f
    (Split-Path -Leaf $pdf), (Get-Item -LiteralPath $pdf).Length)
}
finally {
  Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
