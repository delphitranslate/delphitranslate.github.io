param([string]$PythonPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($PythonPath)) {
    $candidates = @(
        (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\python.exe')
    )
    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        & $candidate -c 'import docx, pypdf' 2>$null
        if ($LASTEXITCODE -eq 0) {
            $PythonPath = $candidate
            break
        }
    }
}
if ([string]::IsNullOrWhiteSpace($PythonPath)) {
    throw 'Python with python-docx and pypdf was not found. Pass -PythonPath.'
}

& $PythonPath (Join-Path $PSScriptRoot 'build_guides.py')
if ($LASTEXITCODE -ne 0) {
    throw 'Guide generation failed.'
}

& (Join-Path $PSScriptRoot 'finalize_guides.ps1') -PythonPath $PythonPath
if ($LASTEXITCODE -ne 0) {
    throw 'Word finalization failed.'
}

Write-Output 'User, Setup Wizard, and Engineering guides regenerated.'
