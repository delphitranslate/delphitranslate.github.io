<#
Builds the layout contract harness and the layout fitting smoke test.

Both compile against the analyser sources directly, so building them is how a
change to the analyser reaches the checks that judge it.
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

$outputDirectory = Join-Path $ProjectRoot 'bin\Tests\Win32'
$unitDirectory   = Join-Path $ProjectRoot 'dcu\Tests'
New-Item -ItemType Directory -Force -Path $outputDirectory, $unitDirectory | Out-Null

$searchPath = @(
  Join-Path $ProjectRoot 'source\core'
  Join-Path $ProjectRoot 'source\review'
  Join-Path $ProjectRoot 'source\scan'
  Join-Path $ProjectRoot 'source\runtime'
) -join ';'

$programs = @(
  Join-Path $ProjectRoot 'tools\tests\LayoutContracts.dpr'
  Join-Path $ProjectRoot 'tools\tests\LayoutFittingSmokeTests.dpr'
  Join-Path $ProjectRoot 'tools\tests\FormScanContracts.dpr'
)

foreach ($program in $programs) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($program)
  $command = '"{0}" && dcc32.exe -Q -B -E"{1}" -N0"{2}" -U"{3}" "{4}"' -f
    $Rsvars, $outputDirectory, $unitDirectory, $searchPath, $program
  $output = cmd /c $command 2>&1
  if ($LASTEXITCODE -ne 0) {
    $output | ForEach-Object { Write-Output $_ }
    throw "Build failed: $name"
  }
  Write-Output ("built {0}" -f $name)
}
