<#
Runs the layout contracts.

Each contract is a small form, a catalog naming the translated text for it, and
an expectation file stating what the analyser must do with them. Because the
forms are purpose-built rather than taken from one real application, the rules
are proved on the shape of a problem instead of on Carillon.

Two guards borrowed from the conversion contracts in VCL2FMXConverter:

  - a stale harness is rejected. If any analyser source is newer than the
    executable, the run stops rather than reporting on code that is no longer
    the code being changed.
  - coverage is enforced. A fixture with no expectation file fails the run, so
    a rule cannot quietly exist without a contract.
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
  $FixtureRoot = Join-Path $ProjectRoot 'contracts\layout'
}
$FixtureRoot = (Resolve-Path $FixtureRoot).Path

if ([string]::IsNullOrWhiteSpace($HarnessExe)) {
  $HarnessExe = Join-Path $ProjectRoot 'bin\Tests\Win32\LayoutContracts.exe'
}

if (-not (Test-Path -LiteralPath $HarnessExe)) {
  throw "Layout contract harness not found: $HarnessExe. Build it with tools\build_layout_contracts.ps1."
}
$HarnessExe = (Resolve-Path $HarnessExe).Path

# --- stale harness guard -----------------------------------------------------
# Testing a harness older than the code it exercises is how a fix gets reported
# as working when the run never contained it.
if (-not $SkipStaleCheck) {
  $harnessInfo = Get-Item -LiteralPath $HarnessExe
  $sourceFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source') -Recurse -File -Include '*.pas'
    Get-Item -LiteralPath (Join-Path $ProjectRoot 'tools\tests\LayoutContracts.dpr') -ErrorAction SilentlyContinue
  ) | Where-Object { $_ -ne $null }

  $newer = @($sourceFiles | Where-Object { $_.LastWriteTimeUtc -gt $harnessInfo.LastWriteTimeUtc } |
    Sort-Object LastWriteTimeUtc -Descending)
  if ($newer.Count -gt 0) {
    throw ("Stale layout contract harness rejected. Rebuild {0}; source {1} is newer ({2:o}) than the harness ({3:o})." -f
      $HarnessExe, $newer[0].FullName, $newer[0].LastWriteTimeUtc, $harnessInfo.LastWriteTimeUtc)
  }
}

Write-Output "Layout contracts"
Write-Output ("Harness : {0}" -f $HarnessExe)
Write-Output ("Fixtures: {0}" -f $FixtureRoot)
Write-Output ""

# --- coverage ----------------------------------------------------------------
$expectationFiles = @(Get-ChildItem -LiteralPath $FixtureRoot -File -Filter '*.expected.json' | Sort-Object Name)
$fixtureForms     = @(Get-ChildItem -LiteralPath $FixtureRoot -File -Filter '*.fmx')

$covered = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($e in $expectationFiles) {
  [void]$covered.Add(($e.Name -replace '\.expected\.json$', '.fmx'))
}

$uncovered = @($fixtureForms | Where-Object { -not $covered.Contains($_.Name) })
if ($uncovered.Count -gt 0) {
  foreach ($u in $uncovered) {
    Write-Output ("  UNCOVERED  {0} has no expectation file" -f $u.Name)
  }
  Write-Output ""
  Write-Output ("RESULT: fail ({0} fixture(s) without a contract)" -f $uncovered.Count)
  exit 1
}

if ($expectationFiles.Count -eq 0) {
  Write-Output "RESULT: fail (no contracts found)"
  exit 1
}

# --- run ---------------------------------------------------------------------
$failed = 0
foreach ($expectation in $expectationFiles) {
  $output = & $HarnessExe $expectation.FullName 2>&1
  $code = $LASTEXITCODE
  foreach ($line in $output) { Write-Output $line }
  if ($code -ne 0) { $failed++ }
}

Write-Output ""
Write-Output ("Contracts: {0}   failed: {1}" -f $expectationFiles.Count, $failed)
if ($failed -eq 0) {
  Write-Output "RESULT: pass"
  exit 0
}
Write-Output "RESULT: fail"
exit 1
