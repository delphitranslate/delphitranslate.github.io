# Refuses a source file that carries non-ASCII text without saying it is UTF-8.
#
# Delphi reads a .pas or .dpr with no byte order mark as the machine's ANSI
# codepage. A file that is really UTF-8 therefore compiles wrong: 'Schließen'
# is stored as the bytes C3 9F for its sharp s, read as Windows-1252 those are
# 'Ã' and 'Ÿ', and the built-in German term for Close shipped as SchlieÃŸen -
# into the catalogue, into the project glossary, and into the shared German
# dictionary, where every later German project would have inherited it.
#
# Nothing about that failure is visible in the source, in a compiler warning,
# or in any test written in English. The only reliable moment to catch it is
# before the build, by looking at the bytes.

param(
    [string] $ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$folders = @('source', 'tools', 'samples') |
    ForEach-Object { Join-Path $ProjectRoot $_ } |
    Where-Object { Test-Path $_ }

$offenders = @()
$checked = 0

foreach ($folder in $folders) {
    Get-ChildItem $folder -Recurse -Include *.pas, *.dpr, *.dpk -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\__backup\\|\\__history\\' } |
        ForEach-Object {
            $checked++
            $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
            if ($bytes.Length -lt 1) { return }

            $hasBom = ($bytes.Length -ge 3 -and
                       $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
            if ($hasBom) { return }

            $nonAscii = $false
            foreach ($b in $bytes) { if ($b -gt 127) { $nonAscii = $true; break } }
            if ($nonAscii) { $offenders += $_.FullName.Replace($ProjectRoot + '\', '') }
        }
}

Write-Output ("Source encoding check: {0} file(s) examined." -f $checked)

if ($offenders.Count -eq 0) {
    Write-Output 'RESULT: pass'
    exit 0
}

Write-Output ''
Write-Output 'These files hold characters outside ASCII but carry no UTF-8 byte order mark,'
Write-Output 'so the compiler will read them in the ANSI codepage and their text will be wrong:'
foreach ($file in $offenders) { Write-Output ("  {0}" -f $file) }
Write-Output ''
Write-Output 'Save each one as UTF-8 with a byte order mark, or write the characters as escapes.'
Write-Output 'RESULT: fail'
exit 1
