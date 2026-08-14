# Current To-Do Resolution

Last changed: August 14, 2026

This note records the current disposition of the fifteen open items from testing.
It is intentionally short and operational so it can be used before the formal
guides are regenerated.

## Fixed in code and ready for fresh testing

1. Carillon secondary-form layout edge cases
   - Runtime FMX layout now snapshots and restores full original bounds, then
     applies bounded text expansion and sibling collision repair.

2. Remaining Schedule grid/header translations
   - Unsafe partial runtime translation was removed.
   - Exact Spanish fallback headers were added for common runtime grid headers:
     Time, Type, Song/Purpose, Group, Play Date From, Play Date To, Play Time,
     Play Time(s), Date/Time, and Event.

3. F:\ executable deployment
   - Deployment now creates the destination when needed, overwrites when
     authorized, retries the copy, and verifies the copied executable by size.

4. Command processor popups
   - Elevated build launching now uses the full system command processor path,
     hidden window mode, and ShellExecute no-console flags.

5. Wizard finish-page layout
   - The Wizard form and finish page were enlarged; finish-page command buttons
     were widened and moved into a two-column button grid.

6. Wizard build/finish state
   - Finish stays disabled while build/deploy is in progress and remains
     disabled when Build and Deploy is checked until the selected build/deploy
     completes.

7. Localization Review row overlap
   - Glossary, terminology-suggestion, and layout-proposal list row heights were
     increased.

8. BPL/component install/remove stability
   - The runtime and design packages were rebuilt and synced to the public RAD
     Studio BPL/DCP folders. The latest package files need one final interactive
     IDE install/remove confirmation pass.

## Handled as product design decisions

9. Complete Reset
   - A conservative Complete Reset workflow exists in the Maintenance Studio
     advanced integration area. It previews the plan and requires explicit
     confirmation before it restores/removes generated integration artifacts.

10. Backup ZIP files in the repository root
   - `prechange_*.zip` is now ignored by Git so safety backups do not pollute
     future status output or commits.

11. Wizard dimmed background
   - The setup flow currently uses the intro screen and modal Wizard flow. The
     dimmed background remains a polish item for later UI refinement, not a
     blocker for localization correctness.

12. Menu-bar language selection versus combo box
   - The product direction remains component-based selection, primarily through
     `TDATFMXLanguageComboBox`. Menu-bar language selection remains a future
     optional integration style for applications that already have a menu bar.

13. Help-file/web-page translation
   - Runtime application Help remains a separate entity. It is deferred until
     the core app-form translation workflow is stable.

14. Visual layout preview/editor
   - The current product stores layout proposals and applies accepted runtime
     layout rules. A richer visual editor remains future work after the runtime
     layout engine is verified.

15. All languages available/exported
   - The Studio and Wizard language selectors contain the major supported
     languages currently exposed by the product. Bulk generation of every
     language pack in one Wizard pass remains a future batch feature; adding one
     language at a time is the current supported workflow.

## Fresh-test acceptance target

A fresh test folder should verify:

- no mixed partial translations such as `Horariod`;
- no repeated-character growth in runtime grid headers;
- Spanish grid headers translate by exact fallback when not persisted in FMX;
- switching back to English restores original bounds and English source text;
- Wizard build/deploy copies both language packs and the executable to the
  configured application destination when replace/create is authorized;
- Finish cannot be clicked before selected build/deploy work is complete.
