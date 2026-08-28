<#
Runs the Pascal scan contracts.

The fixture in contracts\pascalscan holds the shapes that have produced a wrong
capture at some point. This checks two things about it: that the text a person
would actually see is claimed, and that the text that is plumbing is not.

The second half is the one that matters. A scanner that misses a caption is
found the moment somebody looks at the screen; a scanner that claims a file
name sends the application looking for a file that does not exist, and nothing
about the screen says so.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$HarnessExe,
  [switch]$SkipStaleCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$Fixture = Join-Path $ProjectRoot 'contracts\pascalscan\scan_fixture.pas'

if ([string]::IsNullOrWhiteSpace($HarnessExe)) {
  $HarnessExe = Join-Path $ProjectRoot 'bin\Tests\Win32\ScannerSmokeTests.exe'
}
if (-not (Test-Path -LiteralPath $HarnessExe)) {
  throw "Scanner harness not found: $HarnessExe. Build it with tools\build_layout_contracts.ps1."
}
if (-not (Test-Path -LiteralPath $Fixture)) {
  throw "Scan fixture not found: $Fixture"
}
$HarnessExe = (Resolve-Path $HarnessExe).Path

Write-Output "Pascal scan contracts"
Write-Output "Harness: $HarnessExe"
Write-Output "Fixture: $Fixture"
Write-Output ""

if (-not $SkipStaleCheck) {
  $harnessTime = (Get-Item -LiteralPath $HarnessExe).LastWriteTimeUtc
  foreach ($source in (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source\scan') -Filter *.pas -File)) {
    if ($source.LastWriteTimeUtc -gt $harnessTime) {
      throw ("Stale scanner harness rejected. Rebuild {0}; source {1} is newer ({2:o}) than the harness ({3:o})." -f
        $HarnessExe, $source.FullName, $source.LastWriteTimeUtc, $harnessTime)
    }
  }
}

$reported = & $HarnessExe $Fixture 2>&1

# Text a person sees, which must be claimed.
$mustClaim = @(
  'Enter information in these fields to silence the bell system on selected dates.',
  'Caption after an apostrophe in a comment',
  'Time',
  'Song',
  'Remaining events for Today:'
  'Time: %s, Song: %s'
  'Now Playing: %s  (%s remaining )'
  '[%d/%d] Processing: %s'
)

# Plumbing, which must not be.
$mustReject = @(
  'logsCarillonPlayLog.txt',
  'CarillonBackup.dat',
  'Total:  items',
  'Total: '
)

$failed = 0
foreach ($text in $mustClaim) {
  if ($reported -match [regex]::Escape($text)) {
    Write-Output "  ok    claimed: $text"
  }
  else {
    Write-Output "  FAIL  not claimed: $text"
    $failed++
  }
}
foreach ($text in $mustReject) {
  if ($reported -match [regex]::Escape($text)) {
    Write-Output "  FAIL  claimed but should not be: $text"
    $failed++
  }
  else {
    Write-Output "  ok    rejected: $text"
  }
}

Write-Output ""
Write-Output ("Checks: {0}   failed: {1}" -f ($mustClaim.Count + $mustReject.Count), $failed)
if ($failed -eq 0) {
  Write-Output "RESULT: pass"
  exit 0
}
Write-Output "RESULT: fail"
exit 1
