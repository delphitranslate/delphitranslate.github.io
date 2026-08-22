<#
No compiled artifact is older than the source it contains.

This is the guard the layout contract runner has always had - "a stale harness
is rejected, because a result that describes code you are no longer running is
worse than no result" - applied to everything else that carries compiled code.

It exists because the idea was right and was only ever applied in one place.
Packages went a week stale while the source moved underneath them: the Studio
was current, the source was current, and the BPLs the Wizard actually loads
were seven days old. Every runtime change in that week was in the source and in
nobody's binary. The failure showed up as a customer-side build error five
steps from its cause, and cost a test cycle to find.

What is checked, and against what:

  bin\packages\**\*.bpl        source\runtime, source\components, source\design
  the Studio executable        every unit it compiles
  tools\tests\*.exe            the sources each one uses
  bin\Tools\DATBatch.exe       the whole product source

An artifact that does not exist yet is not stale - it is absent, which is a
different thing and is reported differently. Nothing here builds anything; it
only answers whether what exists can be trusted.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  # The check is about human-scale staleness, not clock skew. A source saved a
  # second before a build that was already running is not a problem.
  [int]$ToleranceSeconds = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$stale   = 0
$absent  = 0
$checked = 0

function Newest-Source {
  param([string[]]$Folders)
  $newest = $null
  foreach ($folder in $Folders) {
    $path = Join-Path $ProjectRoot $folder
    if (-not (Test-Path -LiteralPath $path)) { continue }
    foreach ($file in Get-ChildItem $path -Recurse -File -Include '*.pas', '*.dpk', '*.dfm', '*.fmx') {
      if (($null -eq $newest) -or ($file.LastWriteTimeUtc -gt $newest.LastWriteTimeUtc)) {
        $newest = $file
      }
    }
  }
  return $newest
}

function Check-Artifact {
  param(
    [string]$Label,
    [string]$ArtifactPath,
    [string[]]$SourceFolders,
    [switch]$OptionalArtifact
  )
  $script:checked++
  if (-not (Test-Path -LiteralPath $ArtifactPath)) {
    if ($OptionalArtifact) {
      Write-Output ("  --    {0,-46} not built yet" -f $Label)
    }
    else {
      Write-Output ("  MISSING {0,-44} {1}" -f $Label, $ArtifactPath)
      $script:absent++
    }
    return
  }
  $artifact = Get-Item -LiteralPath $ArtifactPath
  $newest = Newest-Source $SourceFolders
  if ($null -eq $newest) {
    Write-Output ("  --    {0,-46} no sources found to compare" -f $Label)
    return
  }
  $gap = ($newest.LastWriteTimeUtc - $artifact.LastWriteTimeUtc).TotalSeconds
  if ($gap -gt $ToleranceSeconds) {
    Write-Output ("  STALE {0,-46} {1:N0}h behind {2}" -f
      $Label, ($gap / 3600), $newest.Name)
    $script:stale++
  }
  else {
    Write-Output ("  ok    {0,-46}" -f $Label)
  }
}

$runtimeSources = @('source\runtime', 'source\components', 'source\core',
  'source\design')
# Each program is compared against the source it actually compiles, not
# against the whole tree. A harness reported stale because a unit it has
# never heard of changed is a false alarm, and a guard that cries wolf
# gets ignored - which leaves things exactly where they were before it
# existed.
$studioSources = @('source')
$batchSources = @('source\core', 'source\scan', 'source\review',
  'source\provider', 'source\validation', 'source\integration',
  'source\runtime')
$contractSources = @('source\core', 'source\review',
  'source\scan', 'source\runtime')

Write-Output 'Artifacts against the source they carry'
Write-Output ''

Write-Output 'Packages - these are what the Wizard and the IDE load'
foreach ($platform in 'Win32', 'Win64') {
  foreach ($configuration in 'Debug', 'Release') {
    $folder = Join-Path $ProjectRoot "bin\packages\$platform\$configuration"
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    foreach ($bpl in Get-ChildItem $folder -Filter '*.bpl') {
      Check-Artifact ("$platform $configuration " + $bpl.BaseName) `
        $bpl.FullName $runtimeSources
    }
  }
}

Write-Output ''
Write-Output 'Programs'
Check-Artifact 'Studio' (Join-Path $ProjectRoot 'bin\Win32\Debug\DelphiAppTranslationStudio.exe') $studioSources -OptionalArtifact
Check-Artifact 'Studio (Release)' (Join-Path $ProjectRoot 'bin\Win32\Release\DelphiAppTranslationStudio.exe') $studioSources -OptionalArtifact
Check-Artifact 'DATBatch' (Join-Path $ProjectRoot 'bin\Tools\DATBatch.exe') $batchSources -OptionalArtifact
Check-Artifact 'LayoutContracts' (Join-Path $ProjectRoot 'bin\Tests\Win32\LayoutContracts.exe') $contractSources -OptionalArtifact

Write-Output ''
if (($stale -eq 0) -and ($absent -eq 0)) {
  Write-Output "RESULT: pass ($checked checked)"
  exit 0
}
if ($stale -gt 0) {
  Write-Output "$stale artifact(s) are older than the source they carry."
  Write-Output 'Run tools\build_packages.ps1, then rebuild the Studio, then try again.'
}
if ($absent -gt 0) {
  Write-Output "$absent artifact(s) are missing."
}
Write-Output "RESULT: fail"
exit 1
