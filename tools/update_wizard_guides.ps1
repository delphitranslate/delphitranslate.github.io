param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$guideDirectory = Join-Path $projectRoot 'docs\guides'
$pdfDirectory = Join-Path $projectRoot 'docs\pdf'

function Add-Paragraph {
    param($Selection, [string]$Text, [string]$Style = 'Normal')
    $Selection.Style = $Style
    $Selection.TypeText($Text)
    $Selection.TypeParagraph()
}

function Add-NumberedItem {
    param($Selection, [string]$Text)
    $Selection.Style = 'List Number'
    $Selection.TypeText($Text)
    $Selection.TypeParagraph()
}

function Restart-SectionNumbering {
    param($Document, [string]$Heading)
    $headingRange = $Document.Content.Duplicate
    $headingRange.Find.ClearFormatting()
    $headingRange.Find.Text = $Heading
    $headingRange.Find.Forward = $false
    $headingRange.Find.Wrap = 0
    if (-not $headingRange.Find.Execute()) { return }

    $firstListParagraph = $null
    $lastListParagraph = $null
    foreach ($paragraph in $Document.Paragraphs) {
        if ($paragraph.Range.Start -le $headingRange.End) { continue }
        if ($paragraph.Range.ListFormat.ListType -ne 0) {
            if ($null -eq $firstListParagraph) {
                $firstListParagraph = $paragraph
            }
            $lastListParagraph = $paragraph
        }
        elseif ($null -ne $firstListParagraph) {
            break
        }
    }
    if ($null -eq $firstListParagraph) { return }
    $listRange = $Document.Range($firstListParagraph.Range.Start,
        $lastListParagraph.Range.End)
    $listRange.ListFormat.RemoveNumbers()
    $listRange.ListFormat.ApplyNumberDefault()
    $listRange.ListFormat.ListTemplate.ListLevels.Item(1).StartAt = 1
}

function Update-Guide {
    param(
        $Word,
        [string]$DocxName,
        [string]$PdfName,
        [string]$Heading,
        [string]$Intro,
        [string[]]$Steps,
        [string]$Closing
    )

    $docxPath = Join-Path $guideDirectory $DocxName
    $pdfPath = Join-Path $pdfDirectory $PdfName
    $document = $Word.Documents.Open($docxPath)
    try {
        $findRange = $document.Content
        $find = $findRange.Find
        $find.ClearFormatting()
        $find.Text = $Heading
        if (-not $find.Execute()) {
            $selection = $Word.Selection
            $selection.SetRange($document.Content.End - 1, $document.Content.End - 1)
            $selection.InsertBreak(7)
            Add-Paragraph $selection $Heading 'Heading 1'
            Add-Paragraph $selection $Intro
            foreach ($step in $Steps) {
                Add-NumberedItem $selection $step
            }
            Add-Paragraph $selection $Closing
        }
        Restart-SectionNumbering $document $Heading
        $dateRange = $document.Content.Duplicate
        $dateRange.Find.Text = 'Last changed: August 9, 2026'
        if ($dateRange.Find.Execute()) {
            $dateRange.Text = 'Last changed: August 10, 2026'
        }
        $document.Save()
        $document.Close(0)
        $document = $null
    }
    finally {
        if ($null -ne $document) {
            $document.Close(0)
        }
    }
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    Update-Guide $word `
        'Delphi App Translation Studio User Guide.docx' `
        'Delphi App Translation Studio User Guide.pdf' `
        'Guided Setup Wizard (Recommended)' `
        'Guided Setup is the recommended path for a first translation. It combines project selection, language selection, provider setup, scanning, automatic translation, validation, runtime-pack export, component-kit creation, and deployment instructions in one professional FMX wizard.' `
        @(
            'On the Project page, choose Start Guided Setup.',
            'Read Welcome, then choose Next. You may select any completed step in the left rail to revisit it.',
            'Browse to the target .dproj or .dpr file. The wizard identifies VCL or FireMonkey without changing the project.',
            'Choose the source and target languages. Confirm the native language name.',
            'Choose Google Cloud Translation or DeepL. Enter or use a saved API key, save it securely or for the session, and test the connection.',
            'Run Scan Project. Existing catalog translations are retained and only new or changed source text becomes unresolved.',
            'Read the approved RAD Studio package-installation procedure. Show Design BPL opens the exact package in File Explorer.',
            'Review the summary, keep the safety backup selected, and authorize final processing. Once processing starts, navigation and cancellation remain disabled until it completes or stops safely.',
            'On Finish, review the progress log and open the generated component kit. Complete the manual RAD Studio package and component-placement steps.',
            'Build the required target configurations, then choose Run Pack Deployment. The wizard uses PowerShell with NoProfile and ExecutionPolicy Bypass. Copy All Commands remains available as a manual fallback.'
        ) `
        'Cancel before final processing closes the wizard without changing the target project. Final processing creates localization artifacts but does not automatically rewrite Delphi Pascal, form, DPR, or DPROJ files. A timestamped completion report records the generated paths and commands.'

    Update-Guide $word `
        'Delphi App Translation Studio Engineering Guide.docx' `
        'Delphi App Translation Studio Engineering Guide.pdf' `
        'Guided Setup Wizard Architecture' `
        'DAT.Studio.SetupWizard is a designer-authored FMX modal form. It is intentionally borderless, fixed-size, centered, and has no menu or system controls. All controls and layout parameters remain editable in the FMX designer. The main Studio launches it from Start Guided Setup while retaining the existing workflow as the advanced fallback.' `
        @(
            'The wizard owns isolated project-profile, scan-result, catalog, provider-key, backup, and component-kit state. No target source integration engine is invoked.',
            'The left rail permits navigation only to steps already reached. A changed project or target language invalidates downstream scan/catalog state.',
            'Pre-final activities are read-only with respect to the target except an explicitly saved provider credential, which is stored through Windows Credential Manager.',
            'Final processing optionally creates a timestamped ZIP in Documents\Delphi App Translation Backups, translates only unresolved eligible entries, saves the development catalog, validates, exports the runtime JSON pack, and generates the component kit.',
            'Blocking validation errors stop final processing before component-kit completion. Reviewed and approved translations are never resent automatically.',
            'During final processing, Back, Cancel, the rail, and close-query approval are disabled. On failure, control is restored and the progress log identifies the stopping point.',
            'The wizard generates four exact deployment commands for Win32 and Win64 Debug and Release. Every command launches the system Windows PowerShell executable with -NoProfile -ExecutionPolicy Bypass.',
            'Run Pack Deployment executes the same generated script only for target output folders that exist. Missing output folders are skipped.',
            'The component package remains a manual RAD Studio operation through Component > Install Packages > Add. The wizard never writes the IDE package registry and never uses the Install Component wizard.',
            'Wizard-Completion-Report.txt is written into the generated kit and records the project, language, catalog, runtime pack, backup, manual step, and deployment commands.'
        ) `
        'The form source is source\studio\DAT.Studio.SetupWizard.pas and its editable designer resource is source\studio\DAT.Studio.SetupWizard.fmx. The unit is registered in the DPR and DPROJ. Release validation must compile Win32 and Win64 Debug and Release and instantiate the wizard form to verify FMX streaming.'
}
finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($word) | Out-Null
}
