<#
Rebuilds every runtime and design package into bin\packages.

This exists because forgetting it has cost real debugging time more than once,
and because the failure it causes is not obvious. The packages carry a compiled
copy of the runtime. Change a unit under source\runtime or source\components,
rebuild the Studio, and the Studio is current while the packages are not - so
the IDE has an old component registered, the design BPL the Wizard points at is
old, and a build that links a package gets last week's behaviour with this
week's source sitting right next to it.

Worse, the copies are in three places and they drift apart:

  packages\runtime, packages\design   where dcc32 puts them by default
  bin\packages\<platform>\<config>    where the Studio and the Wizard look

Only the second matters at run time. The first is a by-product, and it is the
one that gets rebuilt by hand when somebody remembers to rebuild anything.

Design packages are Win32 only - the IDE loads them and the IDE is a 32-bit
host. Runtime packages are built for both platforms because a customer's
application may be either.

Run this after any change under source\runtime or source\components, and before
running the Wizard against a real application.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$Rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if (-not (Test-Path -LiteralPath $Rsvars)) {
  throw "The Delphi environment file was not found: $Rsvars"
}

$searchPath = @('runtime', 'components', 'core') |
  ForEach-Object { Join-Path $ProjectRoot "source\$_" }
$searchPath += Join-Path $ProjectRoot 'source\design'
$searchPath = $searchPath -join ';'

$runtimePackages = @(
  'DATLanguageManagerCoreRuntime',
  'DATLanguageManagerVCLRuntime',
  'DATLanguageManagerFMXRuntime')
$designPackages = @(
  'DATLanguageManagerVCLDesign',
  'DATLanguageManagerFMXDesign')

$failures = 0

function Build-Package {
  param(
    [string]$Name,
    [string]$SourceDirectory,
    [string]$Platform,
    [string]$Configuration
  )
  $compiler = if ($Platform -eq 'Win64') { 'dcc64.exe' } else { 'dcc32.exe' }
  $output = Join-Path $ProjectRoot "bin\packages\$Platform\$Configuration"
  $units  = Join-Path $ProjectRoot "dcu\packages\$Platform\$Configuration"
  New-Item -ItemType Directory -Force -Path $output, $units | Out-Null

  # -LE and -LN place the .bpl and .dcp where the Studio and the Wizard expect
  # them; without those they land beside the .dpk and nothing that matters ever
  # sees them.
  $arguments = '-B -Q -U"{0}" -N0"{1}" -LE"{2}" -LN"{2}" {3}.dpk' -f
    $searchPath, $units, $output, $Name
  if ($Configuration -eq 'Debug') { $arguments = '-V -VN ' + $arguments }

  Push-Location $SourceDirectory
  try {
    $result = cmd /c "`"$Rsvars`" && $compiler $arguments 2>&1"
    if ($LASTEXITCODE -eq 0) {
      Write-Output ("  ok    {0,-32} {1} {2}" -f $Name, $Platform, $Configuration)
    }
    else {
      Write-Output ("  FAIL  {0,-32} {1} {2}" -f $Name, $Platform, $Configuration)
      $result | Select-Object -Last 8 | ForEach-Object { Write-Output "          $_" }
      $script:failures++
    }
  }
  finally { Pop-Location }
}

$runtimeDirectory = Join-Path $ProjectRoot 'packages\runtime'
$designDirectory  = Join-Path $ProjectRoot 'packages\design'

Write-Output 'Runtime packages'
foreach ($platform in 'Win32', 'Win64') {
  foreach ($configuration in 'Debug', 'Release') {
    foreach ($package in $runtimePackages) {
      Build-Package $package $runtimeDirectory $platform $configuration
    }
  }
}

Write-Output ''
Write-Output 'Design packages (Win32 only - the IDE is the host)'
foreach ($configuration in 'Debug', 'Release') {
  foreach ($package in $designPackages) {
    Build-Package $package $designDirectory 'Win32' $configuration
  }
}

Write-Output ''
if ($failures -eq 0) {
  Write-Output 'RESULT: pass'
  Write-Output ''
  Write-Output 'The design BPL to install in the IDE:'
  Write-Output ('  ' + (Join-Path $ProjectRoot 'bin\packages\Win32\Release\DATLanguageManagerVCLDesign.bpl'))
  Write-Output ('  ' + (Join-Path $ProjectRoot 'bin\packages\Win32\Release\DATLanguageManagerFMXDesign.bpl'))
  exit 0
}
Write-Output "RESULT: fail ($failures)"
exit 1
