# TDATLanguageManager Phase 9 Real Application Pilot Report

Completion date: August 8, 2026

## Outcome

Phase 9 is complete. Disposable copies of real FMX and VCL applications passed
Win32 and Win64 component-integration builds and automatic startup translation.
No original application was edited.

## FMX pilot: Website Analytics

The pilot was copied from the pristine Website Analytics repository. One
`TDATFMXLanguageManager` was placed on its existing primary FMX form resource,
and the corresponding typed field and component unit were added as Delphi's
Form Designer would add them. No ordinary form received a component. No
generated translation unit, DPR startup call, or DPROJ edit was used.

With a validated Spanish JSON pack and an executable-folder pilot preference:

- Win32 Debug built and opened its first window as
  `Analítica del sitio web`.
- Win64 Debug built and opened its first window as
  `Analítica del sitio web`.

This proves FMX before-show component translation in a large, multi-form real
application.

## VCL pilot: Courier Herald Reader

The self-contained Courier Herald Reader project was copied and integrated in
the same component-first manner with one `TDATVCLLanguageManager` on its primary
designer form. No generated translation unit, DPR startup call, or DPROJ edit
was used.

With its Spanish pack selected before startup:

- Win32 Debug built and exposed the main form as
  `Lector de PDF del periódico`.
- Win64 Debug built and exposed the main form as
  `Lector de PDF del periódico`.

PowerShell does not reliably populate `MainWindowTitle` for a VCL process
launched hidden. The final test therefore enumerated the process's owned
top-level windows directly and matched the translated form caption.

## Repaired pilot failure

Carillon was initially evaluated as the real VCL pilot. Its component-enhanced
disposable copy compiled successfully on Win32 and Win64. Runtime startup then
stopped in Carillon's own SQLite dialog because the source checkout does not
contain the deployed `databases\carillon.db` file expected beside the
executable. Window inspection confirmed the exact FireDAC error. Rather than
altering Carillon's business-data requirements, the pilot was replaced with
Courier Herald Reader. The Carillon result is not counted as a runtime pass.

## Original-source protection

All work occurred below the Studio project's `export\RealAppPilots` directory.
The original Website Analytics, Carillon, and Courier Herald Reader project and
form hashes were recorded and re-read after testing. The pristine Website
Analytics repository remained clean. The disposable pilot directory was
removed after evidence was recorded.

## Release implications

The preferred component path now has real-application evidence for both
frameworks and both supported architectures. The existing VCL first-display
boundary for dynamically created modeless secondary forms remains as documented
in Phase 4; it did not affect either primary-form startup pilot.
