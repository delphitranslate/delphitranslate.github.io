<#
Runs the form scan contracts.

Each contract is a small .dfm or .fmx form paired with an .expected.txt listing
the component, property and text the scanner must read out of it. The forms are
purpose-built rather than taken from one real application, so a rule is proved
on the shape of a problem rather than on Carillon.

The same two guards as the layout contracts:

  - a stale harness is rejected. If any scanner source is newer than the
    executable, the run stops rather than reporting on code that is no longer
    the code being changed.
  - coverage is enforced. A fixture with no expectation file fails the run, so
    a form cannot sit in the folder proving nothing.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$FixtureRoot,
  [string]$HarnessExe,
  [switch]$SkipStaleCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($FixtureRoot)) {
  $FixtureRoot = Join-Path $ProjectRoot 'contracts\formscan'
}
$FixtureRoot = (Resolve-Path $FixtureRoot).Path

if ([string]::IsNullOrWhiteSpace($HarnessExe)) {
  $HarnessExe = Join-Path $ProjectRoot 'bin\Tests\Win32\FormScanContracts.exe'
}

if (-not (Test-Path -LiteralPath $HarnessExe)) {
  throw "Form scan harness not found: $HarnessExe. Build it with tools\build_layout_contracts.ps1."
}
$HarnessExe = (Resolve-Path $HarnessExe).Path

Write-Output "Form scan contracts"
Write-Output "Harness : $HarnessExe"
Write-Output "Fixtures: $FixtureRoot"
Write-Output ""

# --- stale harness guard ------------------------------------------------------
if (-not $SkipStaleCheck) {
  $harnessTime = (Get-Item -LiteralPath $HarnessExe).LastWriteTimeUtc
  $sources = @()
  $sources += Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source\scan') -Filter *.pas -File
  $harnessSource = Join-Path $ProjectRoot 'tools\tests\FormScanContracts.dpr'
  if (Test-Path -LiteralPath $harnessSource) {
    $sources += Get-Item -LiteralPath $harnessSource
  }
  foreach ($source in $sources) {
    if ($source.LastWriteTimeUtc -gt $harnessTime) {
      throw ("Stale form scan harness rejected. Rebuild {0}; source {1} is newer ({2:o}) than the harness ({3:o})." -f
        $HarnessExe, $source.FullName, $source.LastWriteTimeUtc, $harnessTime)
    }
  }
}

# --- coverage guard -----------------------------------------------------------
$fixtures = @(Get-ChildItem -LiteralPath $FixtureRoot -File |
  Where-Object { $_.Extension -in '.dfm', '.fmx' })

if ($fixtures.Count -eq 0) {
  Write-Output "RESULT: fail (no fixtures found)"
  exit 1
}

$uncovered = @()
foreach ($fixture in $fixtures) {
  $expectation = Join-Path $FixtureRoot ($fixture.BaseName + '.expected.txt')
  if (-not (Test-Path -LiteralPath $expectation)) {
    $uncovered += $fixture.Name
  }
}
if ($uncovered.Count -gt 0) {
  foreach ($name in $uncovered) {
    Write-Output "  FAIL  $name has no expectation file"
  }
  Write-Output "RESULT: fail (uncovered fixtures)"
  exit 1
}

# --- run ----------------------------------------------------------------------
$output = & $HarnessExe $FixtureRoot 2>&1
$code = $LASTEXITCODE
foreach ($line in $output) { Write-Output $line }
exit $code
