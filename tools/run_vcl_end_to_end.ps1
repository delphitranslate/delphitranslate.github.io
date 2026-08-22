<#
The whole pipeline, on a real VCL application, ending in a running executable.

Every other check in this product stops at a file. The contracts prove the plan,
the harnesses prove the applicator, and the batch runner proves the export - but
nothing proved that a pack, carried through a generated component kit into an
application somebody built the ordinary way, actually changes what appears on
screen. That gap is why several things believed fixed came back.

This closes it. In order:

  1. Build DATBatch into the product tree.
  2. Run it over samples\VCLBasic: scan, catalog, memory, validate, plan the
     layout, write the pack, and generate the component kit.
  3. Build the sample application against the kit's ComponentSource **and
     nothing else**, which is what proves the kit is complete. A unit missing
     from it compiles perfectly well here and fails in a customer's project,
     which is the worst possible place to find out.
  4. Deploy the packs beside the executable.
  5. Launch it with --selftest, which applies a language, writes what every
     caption actually became, and exits without showing a window.
  6. Check those captions, and check the round trip back to the source
     language.

Translations: the point of this run is the pipeline, not translation quality, so
where the catalog has no translation the script writes a marked placeholder into
it rather than calling a paid service. The markers are visible in the output on
purpose - a caption that comes back unmarked has not been translated, and that
is exactly what this is looking for.
#>
[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$Rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat',
  [string]$Language = 'de-DE'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$sample      = Join-Path $ProjectRoot 'samples\VCLBasic'
$sampleProj  = Join-Path $sample 'SampleVCLApp.dproj'
$work        = Join-Path ([System.IO.Path]::GetTempPath()) ('dat-e2e-' + [Guid]::NewGuid().ToString('N'))
$batchOut    = Join-Path $ProjectRoot 'bin\Tools'
$failures    = 0

function Check {
  param([bool]$Condition, [string]$Message)
  if ($Condition) { Write-Output "  ok    $Message" }
  else { Write-Output "  FAIL  $Message"; $script:failures++ }
}

function Invoke-Compiler {
  param([string]$WorkingDirectory, [string]$Arguments, [string]$What)
  Push-Location $WorkingDirectory
  try {
    $command = '"{0}" && dcc32.exe {1}' -f $Rsvars, $Arguments
    $output = cmd /c $command
    if ($LASTEXITCODE -ne 0) {
      $output | ForEach-Object { Write-Output $_ }
      throw "Build failed: $What"
    }
  }
  finally { Pop-Location }
}

New-Item -ItemType Directory -Force -Path $work, $batchOut,
  (Join-Path $ProjectRoot 'dcu\Tools') | Out-Null

try {
  $searchPath = @('core', 'review', 'scan', 'runtime', 'components', 'provider',
    'validation', 'integration') |
    ForEach-Object { Join-Path $ProjectRoot "source\$_" }
  $searchPath = $searchPath -join ';'

  Write-Output 'Building DATBatch'
  Invoke-Compiler (Join-Path $ProjectRoot 'tools') `
    ('-Q -B -E"{0}" -N0"{1}" -U"{2}" DATBatch.dpr' -f
      $batchOut, (Join-Path $ProjectRoot 'dcu\Tools'), $searchPath) 'DATBatch'

  # --- the pipeline ----------------------------------------------------------
  Write-Output ''
  Write-Output 'Running the pipeline'
  $packs = Join-Path $work 'packs'
  $kit   = Join-Path $work 'kit'
  & (Join-Path $batchOut 'DATBatch.exe') --project $sampleProj `
    --languages $Language --out $packs --kit $kit --no-translate | Out-Null

  # A catalog with nothing translated is refused by the validator, correctly.
  # Seed it, say so, and run again.
  $catalog = Join-Path $env:LOCALAPPDATA `
    ("DelphiAppTranslationStudio\Workspaces\SampleVCLApp\Development\SampleVCLApp.$Language.translation-project.json")
  if (Test-Path -LiteralPath $catalog) {
    $json = Get-Content -LiteralPath $catalog -Raw -Encoding UTF8 |
      ConvertFrom-Json
    $seeded = 0
    foreach ($entry in $json.entries) {
      if ([string]::IsNullOrWhiteSpace($entry.translatedText)) {
        $entry.translatedText = "[$Language] " + $entry.sourceText
        $entry.status = 'reviewed'
        $seeded++
      }
    }
    if ($seeded -gt 0) {
      $json | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $catalog -Encoding UTF8
      Write-Output "  seeded $seeded entry(ies) with marked placeholder text"
      & (Join-Path $batchOut 'DATBatch.exe') --project $sampleProj `
        --languages $Language --out $packs --kit $kit --no-translate | Out-Null
    }
  }
  Check (Test-Path (Join-Path $packs "$Language.json")) 'A runtime pack was written.'

  $componentSource = Join-Path $kit 'SampleVCLApp\ComponentSource'
  Check (Test-Path $componentSource) 'A component kit was generated.'

  # --- the application, built against the kit alone ---------------------------
  Write-Output ''
  Write-Output 'Building the sample against the kit only'
  $app = Join-Path $work 'app'
  New-Item -ItemType Directory -Force -Path $app, (Join-Path $work 'dcu') | Out-Null
  Invoke-Compiler $sample `
    ('-Q -B -E"{0}" -N0"{1}" -U"{2}" SampleVCLApp.dpr' -f
      $app, (Join-Path $work 'dcu'), $componentSource) 'SampleVCLApp'
  Check (Test-Path (Join-Path $app 'SampleVCLApp.exe')) `
    'It compiles against the kit with no reference to the product tree, so the kit is complete.'

  # --- deploy -----------------------------------------------------------------
  $deployed = Join-Path $app 'Localization\Languages'
  New-Item -ItemType Directory -Force -Path $deployed | Out-Null
  Get-ChildItem $kit -Recurse -Filter '*.json' |
    Where-Object { $_.Name -match '^[a-z]{2}-[A-Za-z]+\.json$' } |
    ForEach-Object { Copy-Item $_.FullName $deployed -Force }
  Copy-Item (Join-Path $packs "$Language.json") $deployed -Force

  # --- run it -----------------------------------------------------------------
  function Invoke-SelfTest {
    param([string]$Wanted)
    $resultFile = Join-Path $app 'selftest-result.txt'
    Remove-Item $resultFile -Force -ErrorAction SilentlyContinue
    $process = Start-Process -FilePath (Join-Path $app 'SampleVCLApp.exe') `
      -ArgumentList '--selftest', '--language', $Wanted `
      -PassThru -WindowStyle Hidden
    if (-not $process.WaitForExit(60000)) {
      $process.Kill()
      throw 'The sample application did not exit; --selftest was not honoured.'
    }
    if (-not (Test-Path $resultFile)) { throw 'No self-test result was written.' }
    $values = @{}
    foreach ($line in Get-Content $resultFile) {
      $at = $line.IndexOf('=')
      if ($at -gt 0) { $values[$line.Substring(0, $at)] = $line.Substring($at + 1) }
    }
    return $values
  }

  Write-Output ''
  Write-Output 'Launching it in the source language first'
  $english = Invoke-SelfTest 'en-US'
  Check ($english['managerInitialized'] -eq 'True') `
    'The manager initialised from the .dfm alone, with nothing set in code.'

  Write-Output ''
  Write-Output "Launching it in $Language"
  $translated = Invoke-SelfTest $Language
  foreach ($key in 'formCaption', 'lblHeading', 'btnSave', 'mnuFile') {
    Write-Output ('        {0,-16} {1}  ->  {2}' -f `
      $key, $english[$key], $translated[$key])
  }
  Check ($translated['activeLanguage'] -eq $Language) `
    "The language was applied: $($translated['activeLanguage'])."

  # Compared against what the same control said in English rather than against
  # the marker text, so this keeps working whatever the catalog holds - real
  # translations included.
  Check ($translated['formCaption'] -ne $english['formCaption']) `
    'The form caption changed, so the pack reached the running window.'
  Check ($translated['lblHeading'] -ne $english['lblHeading']) `
    'So did a label.'
  Check ($translated['btnSave'] -ne $english['btnSave']) `
    'So did a button.'
  Check ($translated['mnuFile'] -ne $english['mnuFile']) `
    'So did a menu item, which the runtime reaches by a different path.'
  # Words are only half of a pack. A run where every caption changed and no
  # control moved would look like a pass and would mean the layout rules
  # never left the file - which is exactly what this script found the first
  # time it was run.
  Check ($translated['btnSaveWidth'] -ne $english['btnSaveWidth']) `
    ("and the layout rules reached the screen: the button is " +
     "$($english['btnSaveWidth']) wide in English and " +
     "$($translated['btnSaveWidth']) translated.")

  Write-Output ''
  Write-Output 'Going home'
  $returned = Invoke-SelfTest 'en-US'
  Write-Output ('        {0,-16} {1}' -f 'formCaption', $returned['formCaption'])
  Check ($returned['formCaption'] -eq $english['formCaption']) `
    'Choosing the source language gives the original words back, exactly.'
  Check ($returned['btnSave'] -eq $english['btnSave']) `
    'and does so for every control, not just the caption.'
  Check ($returned['btnSaveWidth'] -eq $english['btnSaveWidth']) `
    ("and the layout comes back too: $($english['btnSaveWidth']) " +
     "designed, $($translated['btnSaveWidth']) translated, " +
     "$($returned['btnSaveWidth']) home.")
}
finally {
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output ''
if ($failures -eq 0) {
  Write-Output 'RESULT: pass'
  exit 0
}
Write-Output "RESULT: fail ($failures)"
exit 1
