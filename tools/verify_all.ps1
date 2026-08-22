<#
Build everything, run everything, and prove nothing is stale.

This is the command to run before handing work back. It exists because handing
back source changes without rebuilding the binaries that carry them cost a
wasted test cycle: the Studio was rebuilt, the packages were not, and a Wizard
run failed inside a customer-side build with an error nobody could see.

The order matters and is not arbitrary:

  1. Packages first. Everything else can depend on them, and they are the
     artifact most often forgotten because nothing else fails without them
     until much later and somewhere else.
  2. The Studio and the batch runner, which carry the kit generator.
  3. The contract harnesses, which the contract runner refuses to use if they
     are older than the analyser.
  4. Every suite.
  5. The two guards, last, so they judge what was just built rather than what
     was there before.

A failure anywhere stops the run and says which step. Passing means the source,
the binaries, and the tests agree with one another - which is the only state in
which handing work back is honest.

  -SkipEndToEnd   omit the end-to-end run, which builds and launches the sample
                  application and takes the longest.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$Rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat',
  [switch]$SkipEndToEnd
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$tools = Join-Path $ProjectRoot 'tools'

$steps = @()
function Step {
  param([string]$Name, [scriptblock]$Action)
  Write-Output ''
  Write-Output ('=== {0} ===' -f $Name)
  $ok = $true
  try {
    & $Action
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) { $ok = $false }
  }
  catch {
    Write-Output ("  ERROR  {0}" -f $_.Exception.Message)
    $ok = $false
  }
  $script:steps += [pscustomobject]@{ Name = $Name; Passed = $ok }
  if (-not $ok) { Write-Output ('  {0} FAILED' -f $Name) }
}

function Run-Script {
  param([string]$FileName, [string[]]$Arguments = @())
  & powershell -ExecutionPolicy Bypass -File (Join-Path $tools $FileName) @Arguments
}

# --- 1. the artifacts --------------------------------------------------------
Step 'Packages' { Run-Script 'build_packages.ps1' | Select-Object -Last 4 }

Step 'Studio' {
  # MSBuild, driven at the Studio's own .dproj. Nothing is passed on the
  # command line because the .dproj already declares its output folders and
  # its unit search path - so "how the Studio is built" is one answer, living
  # in the project file, and the IDE and this script both read it.
  #
  # It used to be two answers: a hand-written search path here and a
  # DCCReference list there, agreeing only for as long as nobody touched
  # either. They had already drifted - this script searched source\components
  # and the .dproj did not.
  $project = Join-Path $ProjectRoot 'DelphiAppTranslationStudio.dproj'
  foreach ($configuration in 'Debug', 'Release') {
    $logFile = Join-Path ([System.IO.Path]::GetTempPath()) "dat-studio-$configuration.log"
    Push-Location $ProjectRoot
    try {
      cmd /c "`"$Rsvars`" && msbuild `"$project`" /t:Build /p:Platform=Win32 /p:Config=$configuration /nologo /v:minimal > `"$logFile`" 2>&1"
      if ($LASTEXITCODE -ne 0) {
        Get-Content -LiteralPath $logFile |
          Where-Object { $_ -match '(error|fatal|E\d{4}|F\d{4})' } |
          Select-Object -First 6 | ForEach-Object { Write-Output "  $_" }
        throw "Studio $configuration build failed. Full log: $logFile"
      }
      Write-Output ("  ok    Studio {0}" -f $configuration)
    }
    finally { Pop-Location }
  }
}

Step 'Batch runner and contract harnesses' {
  $searchPath = @('core', 'review', 'scan', 'runtime', 'components', 'provider',
    'validation', 'integration') |
    ForEach-Object { Join-Path $ProjectRoot "source\$_" }
  $output = Join-Path $ProjectRoot 'bin\Tools'
  $units  = Join-Path $ProjectRoot 'dcu\Tools'
  New-Item -ItemType Directory -Force -Path $output, $units | Out-Null
  Push-Location (Join-Path $ProjectRoot 'tools')
  try {
    $arguments = '-Q -B -E"{0}" -N0"{1}" -U"{2}" DATBatch.dpr' -f
      $output, $units, ($searchPath -join ';')
    $result = cmd /c "`"$Rsvars`" && dcc32.exe $arguments 2>&1"
    if ($LASTEXITCODE -ne 0) {
      $result | Select-Object -Last 8 | ForEach-Object { Write-Output "  $_" }
      throw 'DATBatch build failed.'
    }
    Write-Output '  ok    DATBatch'
  }
  finally { Pop-Location }
  Run-Script 'build_layout_contracts.ps1'
}

# --- 2. the suites -----------------------------------------------------------
Step 'Source encoding' { Run-Script 'check_source_encoding.ps1' | Select-Object -Last 2 }
Step 'Layout contracts' { Run-Script 'run_layout_contracts.ps1' | Select-Object -Last 3 }
Step 'Form scan contracts' { Run-Script 'run_form_scan_contracts.ps1' | Select-Object -Last 2 }
Step 'Pascal scan contracts' { Run-Script 'run_pascal_scan_contracts.ps1' | Select-Object -Last 2 }

Step 'Harnesses' {
  # 'studio' is here because one harness exercises a Studio form. Leaving
  # it out does not fail loudly - the harness simply does not build, and a
  # harness that never builds is a harness nobody notices is missing.
  $searchPath = @('core', 'review', 'scan', 'runtime', 'components',
    'provider', 'validation', 'integration', 'studio') |
    ForEach-Object { Join-Path $ProjectRoot "source\$_" }
  $output = Join-Path ([System.IO.Path]::GetTempPath()) 'dat-verify-tests'
  New-Item -ItemType Directory -Force -Path $output, (Join-Path $output 'dcu') | Out-Null
  $names = Get-ChildItem (Join-Path $ProjectRoot 'tools\tests') -Filter '*.dpr' |
    Where-Object { $_.BaseName -notin @('LayoutContracts', 'FormScanContracts') } |
    ForEach-Object { $_.BaseName }
  $bad = 0
  Push-Location (Join-Path $ProjectRoot 'tools\tests')
  try {
    foreach ($name in $names) {
      $arguments = '-Q -B -E"{0}" -N0"{1}" -U"{2}" {3}.dpr' -f
        $output, (Join-Path $output 'dcu'), ($searchPath -join ';'), $name
      $null = cmd /c "`"$Rsvars`" && dcc32.exe $arguments 2>&1"
      if ($LASTEXITCODE -ne 0) {
        Write-Output ("  FAIL  {0,-34} did not build" -f $name); $bad++; continue
      }
      # Run from the project root. Several harnesses resolve their
      # fixtures relative to the working directory, so running them
      # from anywhere else fails on a missing file rather than on
      # anything they were written to test.
      Push-Location $ProjectRoot
      try { $null = & (Join-Path $output "$name.exe") }
      finally { Pop-Location }
      # 2 means the harness said it could not run here - a sample application
      # that has not been built, a language Windows does not have. That is not
      # a pass and it is not a failure; it is reported and not counted.
      if ($LASTEXITCODE -eq 0) { Write-Output ("  ok    {0}" -f $name) }
      elseif ($LASTEXITCODE -eq 2) { Write-Output ("  --    {0,-34} skipped, cannot run here" -f $name) }
      else { Write-Output ("  FAIL  {0,-34} exit {1}" -f $name, $LASTEXITCODE); $bad++ }
    }
  }
  finally { Pop-Location }
  if ($bad -gt 0) { throw "$bad harness(es) failed." }
}

if (-not $SkipEndToEnd) {
  Step 'End to end, on a built and launched application' {
    Run-Script 'run_vcl_end_to_end.ps1' | Select-Object -Last 3
  }
}

# --- 3. the guards, judging what was just built ------------------------------
Step 'Build paths agree' { Run-Script 'check_build_paths_agree.ps1' | Select-Object -Last 3 }
Step 'Shipped units complete' { Run-Script 'check_shipped_units_complete.ps1' | Select-Object -Last 2 }
Step 'Artifacts current' { Run-Script 'check_artifacts_current.ps1' | Select-Object -Last 3 }

# --- the answer --------------------------------------------------------------
Write-Output ''
Write-Output '================ summary ================'
foreach ($step in $steps) {
  Write-Output ('  {0}  {1}' -f $(if ($step.Passed) { 'pass' } else { 'FAIL' }), $step.Name)
}
$failed = @($steps | Where-Object { -not $_.Passed })
Write-Output ''
if ($failed.Count -eq 0) {
  Write-Output 'RESULT: pass - source, binaries and tests agree.'
  exit 0
}
Write-Output ("RESULT: fail - {0} step(s)." -f $failed.Count)
exit 1
