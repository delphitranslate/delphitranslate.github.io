<#
Every unit the shipped runtime references is actually shipped.

The defect this exists to prevent, which has now happened once:

  A new unit is added under source\runtime. DAT.Runtime.VCL and
  DAT.Runtime.FMX start using it. The component kit generator is not told to
  copy it and the runtime package is not told to contain it. Everything in the
  product tree still compiles perfectly, because the unit is right there on the
  search path. The customer's application does not, because the kit it was
  given has a unit referencing another unit that was never delivered.

  The error appears at the far end - inside somebody else's build, as a missing
  file - and by then it is five steps from its cause.

The check is closure. Start from the units the kit copies and the packages
contain, read their uses clauses, and confirm that every DAT.* unit they name
is itself shipped. A unit that is referenced and not delivered fails this,
here, in a second, rather than in a customer's build a week later.

Studio-only units are legitimately not shipped and are named below. Anything
else referenced from a shipped unit is a defect by definition: a runtime unit
has no business depending on the Studio, so if this list ever needs extending,
the dependency is what to look at first.
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

# The DAT units a given unit names in either uses clause.
function Get-DatDependencies {
  param([string]$UnitFile)
  if (-not (Test-Path -LiteralPath $UnitFile)) { return @() }
  $text = Get-Content -LiteralPath $UnitFile -Raw
  # Comments carry unit names in prose all over this codebase, so they go first
  # or half the matches are sentences rather than dependencies.
  $text = [regex]::Replace($text, '\{[^}]*\}', ' ', 'Singleline')
  $text = [regex]::Replace($text, '\(\*.*?\*\)', ' ', 'Singleline')
  $text = [regex]::Replace($text, '//[^\r\n]*', ' ')
  $names = @()
  foreach ($match in [regex]::Matches($text, '(?is)\buses\b(.*?);')) {
    foreach ($name in [regex]::Matches($match.Groups[1].Value, '\bDAT\.[A-Za-z0-9_.]+')) {
      $names += $name.Value
    }
  }
  return $names | Sort-Object -Unique
}

function Find-UnitFile {
  param([string]$UnitName)
  foreach ($folder in 'runtime', 'components', 'core', 'design', 'scan',
    'review', 'provider', 'validation', 'integration', 'studio') {
    $candidate = Join-Path $ProjectRoot "source\$folder\$UnitName.pas"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  return ''
}

# Closure from a starting set: everything reachable, by DAT dependency, from
# the units named.
function Get-Closure {
  param([string[]]$Roots)
  $seen = @{}
  $queue = [System.Collections.Queue]::new()
  foreach ($root in $Roots) { $queue.Enqueue($root) }
  while ($queue.Count -gt 0) {
    $name = $queue.Dequeue()
    if ($seen.ContainsKey($name)) { continue }
    $seen[$name] = $true
    $file = Find-UnitFile $name
    if ($file -eq '') { continue }
    foreach ($dependency in Get-DatDependencies $file) {
      if (-not $seen.ContainsKey($dependency)) { $queue.Enqueue($dependency) }
    }
  }
  return $seen.Keys
}

Write-Output 'Shipped-unit completeness'
Write-Output ''

# --- the component kit -------------------------------------------------------
# The list the generator copies, read from the generator itself rather than
# repeated here, so that adding a unit there is the only edit needed.
$generator = Join-Path $ProjectRoot 'source\integration\DAT.Integration.ComponentPackage.pas'
$generatorText = Get-Content -LiteralPath $generator -Raw
$kitUnits = @()
foreach ($match in [regex]::Matches($generatorText,
    "CopyUnit\([^,]+,\s*[^,]+,\s*`r?`n?\s*'([^']+)'")) {
  $kitUnits += $match.Groups[1].Value
}
foreach ($match in [regex]::Matches($generatorText,
    "CopyUnit\([^,]+,\s*[^,]+,\s*'([^']+)'")) {
  $kitUnits += $match.Groups[1].Value
}
$kitUnits = $kitUnits | Sort-Object -Unique

if ($kitUnits.Count -eq 0) {
  Fail 'No CopyUnit calls were found in the kit generator; this check cannot run.'
}
else {
  Write-Output ("  the kit copies {0} unit(s)" -f $kitUnits.Count)
  $needed = Get-Closure $kitUnits
  $missing = @($needed | Where-Object {
      $kitUnits -notcontains $_ -and (Find-UnitFile $_) -ne '' })
  if ($missing.Count -eq 0) {
    Pass 'Every DAT unit the kit''s own units reference is copied with them.'
  }
  else {
    foreach ($name in $missing) {
      Fail ("The kit references {0} and does not copy it. Add a CopyUnit call in DAT.Integration.ComponentPackage." -f $name)
    }
  }
}

# --- the packages ------------------------------------------------------------
Write-Output ''
$packageFiles = Get-ChildItem (Join-Path $ProjectRoot 'packages') -Recurse -Filter '*.dpk'
$packageUnits = @()
foreach ($package in $packageFiles) {
  $text = Get-Content -LiteralPath $package.FullName -Raw
  foreach ($match in [regex]::Matches($text, '\bDAT\.[A-Za-z0-9_.]+\s+in\b')) {
    $packageUnits += ($match.Value -replace '\s+in$', '')
  }
}
$packageUnits = $packageUnits | Sort-Object -Unique
Write-Output ("  the packages contain {0} unit(s)" -f $packageUnits.Count)

$neededByPackages = Get-Closure $packageUnits
$missingFromPackages = @($neededByPackages | Where-Object {
    $packageUnits -notcontains $_ -and (Find-UnitFile $_) -ne '' })
if ($missingFromPackages.Count -eq 0) {
  Pass 'Every DAT unit the packaged units reference is in a package.'
}
else {
  foreach ($name in $missingFromPackages) {
    Fail ("A package references {0} and no package contains it. Add it to the matching .dpk." -f $name)
  }
}

Write-Output ''
if ($failures -eq 0) { Write-Output 'RESULT: pass'; exit 0 }
Write-Output "RESULT: fail ($failures)"
exit 1
