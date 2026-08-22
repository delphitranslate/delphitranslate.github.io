<#
The build that stands in for a customer uses the same tool the customer does.

This guard exists because of a specific false pass. The end-to-end run - the
one whose whole purpose is to prove a kit works inside somebody else's
application - compiled that application with dcc32. The Wizard, which is what a
customer actually runs, compiles with MSBuild. So the end-to-end went green on
a Tuesday while the Wizard's build path was broken, and stayed green, because
the thing being proved was not the thing that failed.

A test that simulates a customer with a tool no customer runs is not a
simulation. It is a second, private build path that happens to resemble one.

What is checked:

  - The Wizard's deployer still drives MSBuild.
  - The end-to-end still builds the sample application with MSBuild.
  - Every package has a .dproj, because MSBuild cannot build a bare .dpk and
    a package without one silently falls out of the build.
  - No compiled package artifacts are sitting beside the .dpk files, where the
    compiler searches before it searches anywhere this project chose. A stale
    Win32 .dcp in that folder makes a Win64 build fail with a message about
    version mismatch that names neither the folder nor the staleness.

Bare .dpr programs - the harnesses, DATBatch - are deliberately not covered.
They have no .dproj, they reproduce nobody's project settings, and giving each
one a project file would be dozens of new files to keep in step for no fidelity
gained. dcc32 is the right tool for those and this guard does not object to it.
#>
[CmdletBinding()]
param([string]$ProjectRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$failures = 0
function Fail { param([string]$Message) Write-Output "  FAIL  $Message"; $script:failures++ }
function Pass { param([string]$Message) Write-Output "  ok    $Message" }

Write-Output 'Build paths that must agree'
Write-Output ''

# --- the Wizard and its stand-in ---------------------------------------------
$deployer = Join-Path $ProjectRoot 'source\integration\DAT.Integration.BuildDeploy.pas'
$deployerText = Get-Content -LiteralPath $deployer -Raw
if ($deployerText -match '(?i)msbuild') {
  Pass 'The Wizard builds a customer application with MSBuild.'
}
else {
  Fail 'The Wizard no longer drives MSBuild. Whatever it drives now is what the end-to-end must drive too.'
}

$endToEnd = Join-Path $ProjectRoot 'tools\run_vcl_end_to_end.ps1'
$endToEndText = Get-Content -LiteralPath $endToEnd -Raw
if ($endToEndText -match '(?i)Invoke-MSBuild\s+\$sample') {
  Pass 'The end-to-end builds the sample application with MSBuild, as a customer would.'
}
else {
  Fail 'The end-to-end no longer builds the sample with MSBuild, so it has stopped simulating a customer.'
}

# --- every package is buildable by MSBuild at all ----------------------------
Write-Output ''
$missing = 0
foreach ($package in Get-ChildItem (Join-Path $ProjectRoot 'packages') -Recurse -Filter '*.dpk') {
  $project = [System.IO.Path]::ChangeExtension($package.FullName, '.dproj')
  if (-not (Test-Path -LiteralPath $project)) {
    Fail ("{0} has no .dproj, so MSBuild cannot build it." -f $package.Name)
    $missing++
  }
}
if ($missing -eq 0) { Pass 'Every package has a .dproj.' }

# --- nothing stale where the compiler looks first ----------------------------
Write-Output ''
$strays = @()
foreach ($folder in 'packages\runtime', 'packages\design') {
  $path = Join-Path $ProjectRoot $folder
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $strays += Get-ChildItem $path -File |
    Where-Object { $_.Extension -in '.dcp', '.bpl', '.dcu' }
}
if ($strays.Count -eq 0) {
  Pass 'No compiled artifacts are sitting beside the .dpk files.'
}
else {
  foreach ($stray in $strays) {
    Fail ("{0} is a compiled artifact in a package source folder; the compiler searches there first." -f $stray.Name)
  }
  Write-Output ''
  Write-Output '  These are build droppings. Deleting them is safe - they are'
  Write-Output '  untracked, ignored by git, and rebuilt into bin\packages.'
}

Write-Output ''
if ($failures -eq 0) { Write-Output 'RESULT: pass'; exit 0 }
Write-Output "RESULT: fail ($failures)"
exit 1
