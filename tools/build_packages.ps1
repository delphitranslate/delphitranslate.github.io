<#
Rebuilds every runtime and design package into bin\packages, using MSBuild.

This exists because forgetting it has cost real debugging time more than once,
and because the failure it causes is not obvious. The packages carry a compiled
copy of the runtime. Change a unit under source\runtime or source\components,
rebuild the Studio, and the Studio is current while the packages are not - so
the IDE has an old component registered, the design BPL the Wizard points at is
old, and a build that links a package gets last week's behaviour with this
week's source sitting right next to it.

Why MSBuild rather than dcc32, which is what this used to do:

  A package is described by two files. The .dpk says what it contains; the
  .dproj says how RAD Studio builds it - defines, debug information, package
  flags, search paths. Driving dcc32 at the .dpk skips the .dproj entirely, so
  the switches were hand-assembled here instead, and "how the packages are
  built" quietly became two different answers: one the IDE used and one this
  script used. They agreed only for as long as nobody changed either.

  The BPLs are precisely the artifact the IDE and the Wizard load. Building
  them by a route neither of those ever takes is how "works in our build, fails
  in the IDE" happens. Four of the five packages had no .dproj at all until
  they were written; now all five build the way RAD Studio builds them.

Output locations are still passed on the command line rather than written into
the .dproj files, so where artifacts land stays one decision in one place:

  bin\packages\<platform>\<config>    where the Studio and the Wizard look
  dcu\packages\<platform>\<config>    intermediate units, of interest to nobody

Build order is not alphabetical and is not adjustable. A package that requires
another needs that one's .dcp to exist first, so the shared core is built
before the frameworks and the design packages last.

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

# Dependency order, not alphabetical order. See the header.
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
  $projectFile = Join-Path $SourceDirectory "$Name.dproj"
  if (-not (Test-Path -LiteralPath $projectFile)) {
    Write-Output ("  FAIL  {0,-32} no .dproj - MSBuild cannot build a bare .dpk" -f $Name)
    $script:failures++
    return
  }

  $output = Join-Path $ProjectRoot "bin\packages\$Platform\$Configuration"
  $units  = Join-Path $ProjectRoot "dcu\packages\$Platform\$Configuration"
  New-Item -ItemType Directory -Force -Path $output, $units | Out-Null

  # A package that requires another finds it by .dcp, and the .dcp is wherever
  # the previous package in the order just put it - which is this same folder.
  $arguments = @(
    ('"{0}"' -f $projectFile)
    '/t:Build'
    ('/p:Platform={0}' -f $Platform)
    ('/p:Config={0}' -f $Configuration)
    ('/p:DCC_BplOutput="{0}"' -f $output)
    ('/p:DCC_DcpOutput="{0}"' -f $output)
    ('/p:DCC_DcuOutput="{0}"' -f $units)
    ('/p:DCC_UnitSearchPath="{0}"' -f $output)
    '/nologo'
    '/v:minimal'
  ) -join ' '

  $logFile = Join-Path ([System.IO.Path]::GetTempPath()) "dat-package-$Name-$Platform-$Configuration.log"
  Push-Location $SourceDirectory
  try {
    cmd /c "`"$Rsvars`" && msbuild $arguments > `"$logFile`" 2>&1"
    if ($LASTEXITCODE -eq 0) {
      Write-Output ("  ok    {0,-32} {1} {2}" -f $Name, $Platform, $Configuration)
    }
    else {
      Write-Output ("  FAIL  {0,-32} {1} {2}" -f $Name, $Platform, $Configuration)
      # An MSBuild log for a failed Delphi build is mostly noise. The compiler
      # lines are the part worth reading, so those are what get shown.
      $interesting = Get-Content -LiteralPath $logFile |
        Where-Object { $_ -match '(error|fatal|E\d{4}|F\d{4})' } |
        Select-Object -First 6
      if (-not $interesting) {
        $interesting = Get-Content -LiteralPath $logFile | Select-Object -Last 6
      }
      $interesting | ForEach-Object { Write-Output "          $_" }
      Write-Output ("          Full log: {0}" -f $logFile)
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
