from __future__ import annotations

from datetime import date
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GUIDES_DIR = PROJECT_ROOT / "docs" / "guides"
ICON = (
    PROJECT_ROOT
    / "images and icons"
    / "DelphiAppTranslationStudio-Icon-Master-v2_150.png"
)
LAST_CHANGED = "August 6, 2026"
BLUE = "234C80"
BRIGHT_BLUE = "1974DF"
ORANGE = "F28A1B"
PALE_BLUE = "EAF3FF"
INK = "163A63"
GRAY = "5D7693"


def set_cell_shading(cell, fill: str) -> None:
    properties = cell._tc.get_or_add_tcPr()
    shading = properties.find(qn("w:shd"))
    if shading is None:
        shading = OxmlElement("w:shd")
        properties.append(shading)
    shading.set(qn("w:fill"), fill)


def add_field(paragraph, instruction: str) -> None:
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instruction_text = OxmlElement("w:instrText")
    instruction_text.set(qn("xml:space"), "preserve")
    instruction_text.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    placeholder = OxmlElement("w:t")
    placeholder.text = "Update this field in Microsoft Word."
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run = paragraph.add_run()
    run._r.extend([begin, instruction_text, separate, placeholder, end])


def set_page_number_format(section, fmt: str, start: int | None = None) -> None:
    properties = section._sectPr
    page_number = properties.find(qn("w:pgNumType"))
    if page_number is None:
        page_number = OxmlElement("w:pgNumType")
        properties.append(page_number)
    page_number.set(qn("w:fmt"), fmt)
    if start is not None:
        page_number.set(qn("w:start"), str(start))


def unlink_headers(section) -> None:
    section.header.is_linked_to_previous = False
    section.footer.is_linked_to_previous = False


def configure_page(section) -> None:
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.68)
    section.left_margin = Inches(0.78)
    section.right_margin = Inches(0.72)
    section.header_distance = Inches(0.3)
    section.footer_distance = Inches(0.3)


def add_header_footer(section, title: str, numbered: bool) -> None:
    unlink_headers(section)
    header = section.header.paragraphs[0]
    header.text = title
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    for run in header.runs:
        run.font.name = "Aptos"
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor.from_string(GRAY)
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    if numbered:
        footer.add_run("Page ")
        add_field(footer, "PAGE")
    for run in footer.runs:
        run.font.name = "Aptos"
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor.from_string(GRAY)


def setup_styles(document: Document) -> None:
    styles = document.styles
    normal = styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(9.5)
    normal.font.color.rgb = RGBColor.from_string("26384A")
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.05

    for name, size, color in (
        ("Title", 29, BLUE),
        ("Subtitle", 15, GRAY),
        ("Heading 1", 19, BLUE),
        ("Heading 2", 14, BRIGHT_BLUE),
        ("Heading 3", 11, ORANGE),
    ):
        style = styles[name]
        style.font.name = "Aptos Display"
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.bold = name != "Subtitle"
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.space_before = Pt(9)
        style.paragraph_format.space_after = Pt(5)

    if "Code Block" not in styles:
        code = styles.add_style("Code Block", WD_STYLE_TYPE.PARAGRAPH)
    else:
        code = styles["Code Block"]
    code.font.name = "Cascadia Mono"
    code.font.size = Pt(8)
    code.font.color.rgb = RGBColor.from_string(INK)
    code.paragraph_format.left_indent = Inches(0.2)
    code.paragraph_format.right_indent = Inches(0.2)
    code.paragraph_format.space_before = Pt(3)
    code.paragraph_format.space_after = Pt(5)

    if "Callout" not in styles:
        callout = styles.add_style("Callout", WD_STYLE_TYPE.PARAGRAPH)
    else:
        callout = styles["Callout"]
    callout.font.name = "Aptos"
    callout.font.size = Pt(9)
    callout.font.color.rgb = RGBColor.from_string(INK)
    callout.paragraph_format.left_indent = Inches(0.2)
    callout.paragraph_format.right_indent = Inches(0.2)
    callout.paragraph_format.space_before = Pt(4)
    callout.paragraph_format.space_after = Pt(6)


def add_cover(document: Document, title: str, subtitle: str) -> None:
    section = document.sections[0]
    configure_page(section)
    add_header_footer(section, "", False)

    document.add_paragraph("")
    document.add_paragraph("")
    logo = document.add_paragraph()
    logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
    if ICON.exists():
        logo.add_run().add_picture(str(ICON), width=Inches(1.5))

    heading = document.add_paragraph(style="Title")
    heading.alignment = WD_ALIGN_PARAGRAPH.CENTER
    heading.add_run(title)
    subheading = document.add_paragraph(style="Subtitle")
    subheading.alignment = WD_ALIGN_PARAGRAPH.CENTER
    subheading.add_run(subtitle)

    accent = document.add_table(rows=1, cols=2)
    accent.alignment = WD_TABLE_ALIGNMENT.CENTER
    accent.columns[0].width = Inches(3.25)
    accent.columns[1].width = Inches(3.25)
    set_cell_shading(accent.cell(0, 0), BLUE)
    set_cell_shading(accent.cell(0, 1), ORANGE)
    for cell in accent.rows[0].cells:
        cell.height = Inches(0.08)

    document.add_paragraph("")
    meta = document.add_paragraph()
    meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = meta.add_run(
        f"Version 1.0\nLast changed: {LAST_CHANGED}\n"
        "Windows • Delphi VCL and FireMonkey • Win32 and Win64"
    )
    run.font.name = "Aptos"
    run.font.size = Pt(11)
    run.font.color.rgb = RGBColor.from_string(GRAY)


def add_toc_section(document: Document, guide_title: str) -> None:
    section = document.add_section(WD_SECTION.NEW_PAGE)
    configure_page(section)
    set_page_number_format(section, "lowerRoman", 1)
    add_header_footer(section, guide_title, True)
    document.add_heading("Table of Contents", level=1)
    paragraph = document.add_paragraph()
    add_field(paragraph, 'TOC \\o "1-3" \\h \\z \\u')
    paragraph.add_run().add_break(WD_BREAK.PAGE)

    content_section = document.add_section(WD_SECTION.NEW_PAGE)
    configure_page(content_section)
    set_page_number_format(content_section, "decimal", 1)
    add_header_footer(content_section, guide_title, True)


def add_paragraphs(document: Document, paragraphs: list[str]) -> None:
    for text in paragraphs:
        document.add_paragraph(text)


def add_bullets(document: Document, items: list[str]) -> None:
    for item in items:
        document.add_paragraph(item, style="List Bullet")


def add_steps(document: Document, items: list[str]) -> None:
    for index, item in enumerate(items, 1):
        paragraph = document.add_paragraph()
        paragraph.paragraph_format.left_indent = Inches(0.22)
        paragraph.paragraph_format.first_line_indent = Inches(-0.22)
        lead = paragraph.add_run(f"{index}. ")
        lead.bold = True
        paragraph.add_run(item)


def add_callout(document: Document, title: str, text: str) -> None:
    table = document.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.cell(0, 0)
    set_cell_shading(cell, PALE_BLUE)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    paragraph = cell.paragraphs[0]
    paragraph.style = "Callout"
    lead = paragraph.add_run(title + " ")
    lead.bold = True
    lead.font.color.rgb = RGBColor.from_string(BLUE)
    paragraph.add_run(text)


def add_table(document: Document, headers: list[str], rows: list[list[str]]) -> None:
    table = document.add_table(rows=1, cols=len(headers))
    table.style = "Light Shading Accent 1"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    header_properties = table.rows[0]._tr.get_or_add_trPr()
    repeat_header = OxmlElement("w:tblHeader")
    repeat_header.set(qn("w:val"), "true")
    header_properties.append(repeat_header)
    for index, header in enumerate(headers):
        cell = table.rows[0].cells[index]
        cell.text = header
        set_cell_shading(cell, BLUE)
        for run in cell.paragraphs[0].runs:
            run.font.bold = True
            run.font.color.rgb = RGBColor(255, 255, 255)
    for row in rows:
        cells = table.add_row().cells
        row_properties = table.rows[-1]._tr.get_or_add_trPr()
        cannot_split = OxmlElement("w:cantSplit")
        row_properties.append(cannot_split)
        for index, value in enumerate(row):
            cells[index].text = value
            cells[index].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP


def finish_document(document: Document, path: Path) -> None:
    document.core_properties.title = path.stem
    document.core_properties.subject = "Delphi App Translation Studio documentation"
    document.core_properties.author = "TMartinDub"
    document.core_properties.keywords = (
        "Delphi, VCL, FireMonkey, FMX, localization, translation"
    )
    document.settings.update_fields_on_open = True
    path.parent.mkdir(parents=True, exist_ok=True)
    document.save(path)


def build_user_guide() -> Path:
    document = Document()
    setup_styles(document)
    title = "Delphi App Translation Studio — User Guide"
    add_cover(
        document,
        "User Guide",
        "Delphi App Translation Studio",
    )
    add_toc_section(document, title)

    document.add_heading("1. Welcome", level=1)
    add_paragraphs(
        document,
        [
            "Delphi App Translation Studio is a Windows developer tool for adding offline localization to existing Delphi VCL and FireMonkey applications. It scans designer-authored forms and Delphi resourcestring declarations, stores the results in an editable development catalog, optionally obtains draft translations from an Internet provider, validates the finished language, and exports a compact JSON pack for the target application.",
            "The Studio itself is built with FireMonkey, but it works with both VCL and FMX target projects. The supported build targets are Windows Win32 and Win64. macOS, iOS, Android, Linux, C++Builder, and runtime cloud translation are outside the product scope.",
        ],
    )
    add_callout(
        document,
        "Offline by design.",
        "Only the developer Studio contacts DeepL or Google. A translated target application reads local JSON files and never needs Internet access or a provider API key.",
    )

    document.add_heading("1.1 What the Studio changes", level=2)
    add_bullets(
        document,
        [
            "Scanning is read-only and does not alter the selected project.",
            "Saving creates project-local Localization\\Development catalog files.",
            "Export creates project-local Localization\\Languages runtime packs.",
            "Integration is a separate explicit operation with preview, verified backup, apply, and restore.",
            "Language menu items are persisted in the target DFM or FMX so they remain editable in the Delphi IDE.",
        ],
    )

    document.add_heading("2. Installation and Startup", level=1)
    add_paragraphs(
        document,
        [
            "The open-source project can be opened and compiled by anyone with Delphi 13 / RAD Studio 13 Florence. No installer is required for development builds. Open DelphiAppTranslationStudio.dproj, choose Win32 or Win64, and build.",
            "Build products are placed under bin\\<Platform>\\<Configuration>. Compiler units are placed under dcu. The project deliberately does not target mobile or macOS platforms.",
        ],
    )
    document.add_heading("2.1 First launch", level=2)
    add_steps(
        document,
        [
            "Run DelphiAppTranslationStudio.exe.",
            "Confirm that the title reads Delphi App Translation Studio.",
            "Use the left workflow panel. The blue selection bar follows the active Project, Scan, Languages, Validation, Export, Integration, or Provider Settings page.",
        ],
    )

    document.add_heading("3. The End-to-End Workflow", level=1)
    add_table(
        document,
        ["Step", "Purpose", "Primary output"],
        [
            ["1 Project", "Open and identify a Delphi project.", "Project profile"],
            ["2 Scan", "Extract designated designer text and resourcestrings.", "Scan result"],
            ["3 Languages", "Create or edit one target-language catalog.", "Development JSON"],
            ["4 Validation", "Check completeness and structural safety.", "Issue list"],
            ["5 Export", "Create the compact offline pack.", "Runtime JSON"],
            ["6 Integration", "Preview/apply runtime and language-menu wiring.", "Integrated target project"],
            ["7 Provider Settings", "Configure optional DeepL or Google access.", "Secure credential or session key"],
        ],
    )

    document.add_heading("4. Open and Scan a Project", level=1)
    add_steps(
        document,
        [
            "Choose Project and select Open Delphi Project.",
            "Open a .dproj when available; a .dpr is also accepted.",
            "Review the detected framework, platforms, form count, and source count.",
            "Choose Scan. The Studio reads text DFM/FMX resources and resourcestring declarations.",
            "Review the entry count, elapsed milliseconds, breakdown, and result list.",
        ],
    )
    add_callout(
        document,
        "Binary forms.",
        "The scanner expects text DFM/FMX resources. If a legacy DFM is binary, use Delphi's normal form conversion facilities before scanning and keep a source-control copy.",
    )
    document.add_heading("4.1 Text that is collected", level=2)
    add_bullets(
        document,
        [
            "Captions, Text values, prompts, hints, headings, and designated list content.",
            "Memo and string-list content when it represents user-visible text.",
            "Delphi resourcestring symbols with stable unit-and-symbol keys.",
            "Locale metadata such as date, time, number, and currency formatting is entered on the Languages page rather than guessed from UI text.",
        ],
    )

    document.add_heading("5. Create and Edit a Language Catalog", level=1)
    add_steps(
        document,
        [
            "Choose Languages after scanning.",
            "Enter the source language, normally en-US.",
            "Enter a target locale such as it-IT, de-DE, fr-FR, or es-ES.",
            "Enter the language's native name, such as Italiano or Deutsch.",
            "Leave direction as ltr unless the target requires right-to-left metadata.",
            "Review or edit the date, time, decimal, thousands, and currency fields. Blank fields are initially populated from Delphi TFormatSettings for the target locale.",
            "Choose Create / Save.",
        ],
    )
    add_paragraphs(
        document,
        [
            "The catalog is saved under Localization\\Development using the project name and target locale. Each target language has its own development catalog. Existing translations are preserved on later scans when the stable key and source text remain unchanged. Changed source text is flagged for review, and removed entries become obsolete rather than disappearing silently.",
        ],
    )

    document.add_heading("5.1 Translation statuses", level=2)
    add_table(
        document,
        ["Status", "Meaning"],
        [
            ["Needs translation", "No usable target text is present."],
            ["Machine translated", "DeepL or Google produced a draft that requires review."],
            ["Edited", "A person changed or entered the target text."],
            ["Reviewed", "A person reviewed the target text."],
            ["Approved", "The entry is release-approved."],
            ["Source changed", "The source changed after a translation existed."],
            ["Excluded", "The entry is intentionally omitted."],
            ["Obsolete", "The source entry no longer exists in the latest scan."],
            ["Error", "The entry needs correction after a failed operation or check."],
        ],
    )

    document.add_heading("6. Provider Settings", level=1)
    add_paragraphs(
        document,
        [
            "Provider translation is optional. The Studio supports DeepL API Free, DeepL API Pro, and Google Cloud Translation Basic v2. Provider accounts, billing, quotas, prices, and supported languages are controlled by the provider and may change.",
        ],
    )
    add_table(
        document,
        ["Control", "Behavior"],
        [
            ["Provider", "Select DeepL or Google Cloud Translation."],
            ["DeepL API plan", "Select API Free or API Pro so the Studio uses the matching endpoint."],
            ["API key", "Masked field for a new or replacement key."],
            ["Remember securely", "Stores the key as a Windows Generic Credential."],
            ["Session only", "Clear Remember before saving; the key is held only until shutdown."],
            ["Replace / Save Key", "Records the entered key using the selected storage choice."],
            ["Test Connection", "Sends a small English-to-Italian request."],
            ["Remove Key", "Deletes stored and session copies for the selected provider."],
            ["Timeout / batch", "Controls 5-300 second requests and 1-50 strings per request."],
        ],
    )

    document.add_heading("7. Obtain and Enter a DeepL API Key", level=1)
    add_callout(
        document,
        "Use a DeepL API account.",
        "A normal DeepL Translator subscription is not automatically a DeepL API plan. Confirm that the account includes API Free or API Pro.",
    )
    add_steps(
        document,
        [
            "Open the official DeepL developer site at https://developers.deepl.com/ and review current API account requirements.",
            "Create or sign in to a DeepL account and subscribe to DeepL API Free or DeepL API Pro as appropriate.",
            "Open the account's API Keys tab. Create a separate key for this Studio when the account interface permits multiple keys.",
            "Copy the key once and keep it out of source code, JSON catalogs, issue trackers, email, and screenshots.",
            "In the Studio, choose Provider Settings and select DeepL.",
            "Select API Free or API Pro to match the account. Free uses api-free.deepl.com; Pro uses api.deepl.com.",
            "Paste the key into the masked field.",
            "Leave Remember securely checked for Windows Credential Manager, or clear it for Use for This Session Only.",
            "Choose Replace / Save Key, then Test Connection.",
            "If the test fails, verify the plan selection, key status, account quota/billing, firewall, and target-language availability.",
        ],
    )
    add_paragraphs(
        document,
        [
            "DeepL key and authentication reference: https://developers.deepl.com/docs/getting-started/auth",
            "DeepL quickstart: https://developers.deepl.com/docs/getting-started/quickstart",
            "DeepL multiple-key guidance: https://developers.deepl.com/docs/multiple-api-keys",
        ],
    )

    document.add_heading("8. Obtain and Enter a Google API Key", level=1)
    add_callout(
        document,
        "Google Basic v2 only.",
        "The Studio uses Cloud Translation Basic v2 because it supports API-key authentication. Cloud Translation Advanced v3 uses different authentication and is not implemented.",
    )
    add_steps(
        document,
        [
            "Open Google Cloud Console at https://console.cloud.google.com/ and sign in.",
            "Create a dedicated Google Cloud project or select an existing project intended for this Studio.",
            "Attach an active billing account if Google requires billing for the Cloud Translation API.",
            "Open APIs & Services, then Library. Find and enable Cloud Translation API.",
            "Open APIs & Services, then Credentials. Choose Create credentials and API key.",
            "Immediately edit the new key. Under API restrictions, restrict it to Cloud Translation API. Apply any additional restriction that is compatible with the developer computer and organization; desktop usage commonly makes website-referrer restrictions unsuitable.",
            "Review quotas and budget alerts in Google Cloud before bulk translation.",
            "In the Studio, choose Provider Settings and select Google Cloud Translation.",
            "Paste the key into the masked field. The DeepL plan control is disabled because it does not apply.",
            "Choose persistent Windows Credential Manager storage or session-only use, then Replace / Save Key and Test Connection.",
        ],
    )
    add_paragraphs(
        document,
        [
            "Google Cloud Translation setup: https://docs.cloud.google.com/translate/docs/setup",
            "Google API-key creation and management: https://docs.cloud.google.com/docs/authentication/api-keys",
            "Google API-key restrictions: https://docs.cloud.google.com/api-keys/docs/add-restrictions-api-keys",
            "Cloud Translation authentication: https://docs.cloud.google.com/translate/docs/authentication",
        ],
    )

    document.add_heading("9. Translate Missing Entries", level=1)
    add_steps(
        document,
        [
            "Open or create the target-language catalog.",
            "Confirm the source and target language codes.",
            "Configure and test a provider.",
            "Choose Translate Missing with Provider.",
            "Read the confirmation message. It separately reports exact reviewed translations that will be reused locally and strings that will be sent to the provider.",
            "Choose Yes to begin. Existing complete reviewed or approved work is preserved.",
            "Wait for all batches. Exact reviewed matches require no Internet request; transient HTTP 429 and provider server failures are retried.",
            "Review every machine-translated entry for meaning, placeholders, accelerators, product terminology, tone, and available control space.",
            "Save the catalog and run Validation.",
        ],
    )
    add_callout(
        document,
        "Cost control.",
        "The confirmation count is not a price quote. Provider billing can depend on characters and account terms. Check the provider dashboard and quotas before a large request.",
    )

    document.add_heading("10. Validate and Export", level=1)
    add_paragraphs(
        document,
        [
            "Validation checks catalog metadata, required translations, duplicate keys, source changes, placeholders, accelerator keys, and excluded/obsolete conditions. Errors block export. Warnings and information messages should still be reviewed.",
        ],
    )
    add_steps(
        document,
        [
            "Choose Validation and Run Validation.",
            "Open each listed issue and correct the catalog entry or metadata.",
            "Repeat until no errors remain.",
            "Choose Export and Export Runtime Pack.",
            "Record the output path under Localization\\Languages.",
        ],
    )

    document.add_heading("11. Integrate a Target Application", level=1)
    add_paragraphs(
        document,
        [
            "Integration adds the offline runtime, generated application-specific unit, startup calls, event wiring, and designer-persisted language menu items. It does not add provider access to the target.",
        ],
    )
    add_steps(
        document,
        [
            "Close or save the target project in Delphi.",
            "Select Integration and confirm the designated language menu component, normally mnuLanguage.",
            "Choose Build Integration Plan and review each proposed operation.",
            "Choose Generate Preview. Inspect the package, language-menu.json, generated unit, Runtime folder, Localization\\Languages, and Deploy-LanguagePacks.ps1.",
            "Choose Apply only after reviewing the change set. The Studio creates and verifies a pre-change backup and writes a manifest.",
            "Reopen the target project, inspect the DFM/FMX menu items in the IDE, and build Win32 and Win64.",
            "Run the target, select a language, restart if required by the application's integration pattern, and verify all forms.",
            "Use Restore to recover the recorded pre-integration state if needed.",
        ],
    )

    document.add_heading("11.1 Runtime files and preferences", level=2)
    add_bullets(
        document,
        [
            "Deploy JSON packs beside the target executable under Localization\\Languages.",
            "Run Deploy-LanguagePacks.ps1 from the preview package with -ApplicationDirectory pointing to the output folder, or copy the files through the Delphi deployment manager.",
            "The selected language is stored in %LOCALAPPDATA%\\<ApplicationId>\\language.ini.",
            "The executable folder can therefore remain read-only, as it normally is under Program Files.",
        ],
    )

    document.add_heading("12. Translate the Studio Itself", level=1)
    add_steps(
        document,
        [
            "Run the English Studio and select DelphiAppTranslationStudio.dproj.",
            "Scan it and create the desired language catalog.",
            "Translate, review, validate, and export the pack.",
            "Build the self-integration preview for mnuLanguage.",
            "Apply the persisted FMX menu-resource update.",
            "Close the running Studio, rebuild it, and start the newly built executable.",
            "Select the new language. The preference is applied on the next launch.",
        ],
    )
    add_paragraphs(
        document,
        [
            "The running executable is never overwritten. The JSON pack and preference are separate from the executable, and the rebuild supplies the updated menu on the next run.",
        ],
    )

    document.add_heading("13. Troubleshooting", level=1)
    add_table(
        document,
        ["Symptom", "Likely action"],
        [
            ["Project framework unknown", "Open the .dproj, confirm VCL/FMX units and project metadata, then rescan."],
            ["No scan entries", "Confirm text DFM/FMX resources and designated user-visible properties."],
            ["HTTP 401/403", "Replace the key; verify provider plan, API enablement, restrictions, and billing."],
            ["HTTP 429", "Quota or rate limit reached; wait, reduce batch size, or review provider quota."],
            ["DeepL test fails only on one plan", "Select API Free or API Pro to match the account endpoint."],
            ["Google test fails", "Confirm Basic v2 Cloud Translation API is enabled and key API restriction permits it."],
            ["Export blocked", "Run Validation and correct every error."],
            ["Language menu missing", "Confirm the designated menu name and rebuild the integration plan."],
            ["Preference cannot be found", "Check %LOCALAPPDATA%\\<ApplicationId>\\language.ini, not the executable folder."],
            ["Target remains English", "Confirm the JSON pack applicationId and locale, deployment folder, selected preference, and startup ApplyTranslation calls."],
        ],
    )

    document.add_heading("14. Security and Privacy", level=1)
    add_bullets(
        document,
        [
            "Only confirmed source strings are sent to the selected provider.",
            "Do not send secrets, personal data, customer data, or regulated information as UI text.",
            "Remembered keys are Windows Generic Credentials; session keys are not persisted.",
            "Removing a key affects only the selected provider.",
            "Provider settings JSON contains no API key.",
            "Catalogs, runtime packs, deployment packages, logs, backups, and Git should contain no key.",
            "Rotate a key immediately in the provider console if it may have been exposed, then replace it in the Studio.",
        ],
    )

    document.add_heading("15. File and Folder Reference", level=1)
    add_table(
        document,
        ["Location", "Contents"],
        [
            ["Localization\\Development", "Editable full development catalogs."],
            ["Localization\\Languages", "Compact offline runtime JSON packs."],
            ["export", "Generated previews and temporary product output."],
            ["docs\\guides / docs\\pdf", "Editable guides and companion PDFs."],
            ["%LOCALAPPDATA%\\DelphiAppTranslationStudio", "Studio settings and language preference, but no remembered key."],
            ["Windows Credential Manager", "Remembered DeepL/Google Generic Credentials."],
            ["%LOCALAPPDATA%\\<ApplicationId>", "Integrated application's selected-language preference."],
        ],
    )

    document.add_heading("16. Provider Reference and Change Notice", level=1)
    add_paragraphs(
        document,
        [
            "Provider setup screens and commercial terms can change after this guide is published. Before creating a production key, compare these steps with the official pages listed in Chapters 7 and 8. Prefer a dedicated, restricted key and review the provider dashboard after the first bulk run.",
            "This guide documents the implemented Studio as of August 6, 2026.",
        ],
    )

    path = GUIDES_DIR / "Delphi App Translation Studio User Guide.docx"
    finish_document(document, path)
    return path


def build_engineering_guide() -> Path:
    document = Document()
    setup_styles(document)
    title = "Delphi App Translation Studio — Engineering Guide"
    add_cover(
        document,
        "Engineering Guide",
        "Architecture, Formats, Integration, Security, and Validation",
    )
    add_toc_section(document, title)

    document.add_heading("1. Product Scope and Invariants", level=1)
    add_paragraphs(
        document,
        [
            "Delphi App Translation Studio is a Windows-only, open-source localization workspace written in Delphi FireMonkey. It targets Delphi VCL and FMX applications compiled for Win32 and Win64. It is not a runtime translation service and does not require target machines to have Internet access.",
            "The central invariant is separation: scan and catalog operations do not modify target source; provider access exists only in the Studio; integration is explicit, previewed, transactional, backed up, and reversible; target applications consume compact offline JSON only.",
        ],
    )
    add_bullets(
        document,
        [
            "All user interface controls are persisted in DAT.Studio.MainForm.fmx and remain editable in the RAD Studio designer.",
            "No UI is constructed at runtime.",
            "Stable keys, not source text alone, identify translated properties.",
            "Original designer text remains the runtime fallback.",
            "API keys never enter project artifacts.",
            "Language menu items remain designer-persisted in DFM/FMX resources.",
        ],
    )

    document.add_heading("2. Repository and Build Layout", level=1)
    add_table(
        document,
        ["Path", "Responsibility"],
        [
            ["source\\core", "Catalog types, JSON persistence, project detection, workspace paths, runtime pack generation."],
            ["source\\scan", "VCL/FMX form text, Pascal resourcestrings, extraction rules, diagnostics, incremental merge."],
            ["source\\validation", "Catalog safety and completeness checks."],
            ["source\\provider", "Provider types/settings, Credential Manager, DeepL/Google HTTPS client."],
            ["source\\runtime", "Pack discovery/loading, preference, manager, VCL and FMX applicators."],
            ["source\\integration", "Plan, resource/source rewriting, change sets, transaction, package generation."],
            ["source\\studio", "Designer-authored FMX UI and Studio self-localization."],
            ["source\\schemas", "Development and runtime JSON Schemas."],
            ["tools\\tests", "Foundation, runtime, integration, form-streaming, launch, and self-localization smoke tests."],
            ["docs / help / samples", "Product documentation, help source, and safe fixtures."],
        ],
    )
    document.add_heading("2.1 Toolchain", level=2)
    document.add_paragraph(
        'call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"\n'
        "msbuild DelphiAppTranslationStudio.dproj /t:Build /p:Config=Debug /p:Platform=Win32\n"
        "msbuild DelphiAppTranslationStudio.dproj /t:Build /p:Config=Release /p:Platform=Win64",
        style="Code Block",
    )
    add_paragraphs(
        document,
        [
            "The DPROJ identifies the main form as FMX, includes the standard project resource, uses source\\provider in its unit search path, and routes EXE/DCU output to bin and dcu by platform/configuration.",
        ],
    )

    document.add_heading("3. System Architecture", level=1)
    add_table(
        document,
        ["Boundary", "Input", "Output"],
        [
            ["Detection and scan", ".dproj/.dpr, text DFM/FMX, Pascal source", "TProjectProfile and TProjectScanResult"],
            ["Catalog", "Scan result plus existing development JSON", "Merged TTranslationCatalog"],
            ["Provider", "Confirmed source strings plus in-memory credential", "Machine-translated entry values"],
            ["Validation", "Development catalog", "Errors, warnings, information"],
            ["Pack builder", "Valid catalog", "Compact runtime JSON"],
            ["Integration", "Project profile, packs, designated menu", "Preview package and transactional change set"],
            ["Runtime", "Local JSON and per-user preference", "Translated existing controls and locale settings"],
        ],
    )

    document.add_heading("4. Core Data Model and JSON", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Core.Types defines target framework/platform flags, locale metadata, translation status, catalog entries, and catalog ownership. Development JSON retains source text, translation, stable key, checksum, status, source location, component/property metadata, and locale data. Runtime JSON deliberately omits development-only detail.",
        ],
    )
    document.add_heading("4.1 Stable keys", level=2)
    add_bullets(
        document,
        [
            "Form properties use form.component.property, for example frmMain.btnSave.Text.",
            "resourcestring entries use the Pascal unit and symbol.",
            "Keys remain stable when wording changes, allowing source-changed detection.",
            "Fallback source text remains in the compiled DFM/FMX or code.",
        ],
    )
    document.add_heading("4.2 Development catalog", level=2)
    document.add_paragraph(
        '{\n'
        '  "schemaVersion": 1,\n'
        '  "applicationId": "SampleApp",\n'
        '  "sourceLanguage": "en-US",\n'
        '  "locale": {"languageCode": "it-IT", "nativeLanguageName": "Italiano"},\n'
        '  "entries": [{"key": "frmMain.btnSave.Text", "sourceText": "Save",\n'
        '               "translatedText": "Salva", "status": "reviewed"}]\n'
        "}",
        style="Code Block",
    )
    document.add_heading("4.3 Runtime pack", level=2)
    document.add_paragraph(
        '{\n'
        '  "schemaVersion": 1,\n'
        '  "applicationId": "SampleApp",\n'
        '  "languageCode": "it-IT",\n'
        '  "nativeLanguageName": "Italiano",\n'
        '  "sourceCatalogChecksum": "...",\n'
        '  "strings": {"frmMain.btnSave.Text": "Salva"}\n'
        "}",
        style="Code Block",
    )
    add_paragraphs(
        document,
        [
            "The schema files are source\\schemas\\development-project.schema.json and runtime-language-pack.schema.json. Changes require schema-version handling, round-trip fixtures, and compatibility notes.",
        ],
    )

    document.add_heading("5. Project Detection and Scanning", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Core.ProjectDetection reads project metadata, resolves the DPR, detects VCL or FMX through project/form evidence, records Win32/Win64 support, and enumerates forms and Pascal sources. DAT.Scan.Project coordinates form and resourcestring scanners while measuring elapsed milliseconds.",
            "DAT.Scan.FormText parses text DFM/FMX without instantiating target forms. DAT.Scan.PascalResources extracts resourcestring declarations. DAT.Scan.TextCodec preserves Delphi text encodings and escaped string syntax. DAT.Scan.Rules centralizes designated property decisions.",
        ],
    )
    document.add_heading("5.1 Incremental merge", level=2)
    add_steps(
        document,
        [
            "Index the existing catalog by stable key.",
            "Add unseen keys as needs-translation.",
            "Preserve translation and status when source text is unchanged.",
            "Preserve existing translation but mark source-changed when source text differs.",
            "Mark catalog-only entries obsolete unless excluded.",
            "Report new, changed, unchanged, and obsolete counts.",
        ],
    )

    document.add_heading("6. Studio UI and Workflow State", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Studio.MainForm.fmx contains the complete orange-and-blue interface. The workflow selection rectangle moves among seven persisted pages. DAT.Studio.MainForm.pas contains event and state logic only; it does not construct controls.",
            "The form owns the project profile, scan result, catalog, validation result, integration change set, provider settings, and per-provider session-key strings. Destructors release owned objects. Catalog updates invalidate validation and export state.",
        ],
    )
    add_callout(
        document,
        "FMX validation requirement.",
        "A successful compile is insufficient. Persisted FMX property-type errors surface only while streaming. StudioFormSmokeTests directly constructs the form, and launch tests verify the real title in every configuration.",
    )

    document.add_heading("7. Provider Settings and Secret Storage", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Provider.Settings persists only provider, DeepL plan, remember choice, timeout, and batch size in %LOCALAPPDATA%\\DelphiAppTranslationStudio\\provider-settings.json. Bounds are normalized to 5-300 seconds and 1-50 strings.",
            "DAT.Provider.CredentialStore uses CredWriteW, CredReadW, CredDeleteW, and CredFree with CRED_TYPE_GENERIC and local-machine persistence. Credential targets are provider-specific and begin TMartinDub/DelphiAppTranslationStudio/. Secret bytes are cleared after conversion where practical.",
        ],
    )
    add_table(
        document,
        ["Choice", "Persistence", "Replacement behavior"],
        [
            ["Remember checked", "Windows Credential Manager", "Writes/replaces selected provider credential and clears session copy."],
            ["Remember cleared", "Process memory only", "Deletes selected provider stored credential and retains entered key until shutdown."],
            ["Remove Key", "None", "Deletes stored and session copies for selected provider."],
        ],
    )
    add_bullets(
        document,
        [
            "The masked edit never displays a stored credential.",
            "The effective key resolves new field text, then session memory, then Credential Manager.",
            "No error message contains the key, request headers, or provider response body.",
            "Credential operations occur only when needed; the form can start without network access.",
        ],
    )

    document.add_heading("8. Provider HTTP Clients", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Provider.Client uses Delphi THTTPClient. It validates a nonblank key, normalizes settings, builds provider-specific JSON, sends HTTPS POST requests, parses provider response arrays, verifies result counts, and returns translations in source order.",
        ],
    )
    add_table(
        document,
        ["Provider", "Endpoint", "Authentication", "Payload"],
        [
            ["DeepL API Free", "https://api-free.deepl.com/v2/translate", "Authorization: DeepL-Auth-Key", "text array, source_lang, target_lang"],
            ["DeepL API Pro", "https://api.deepl.com/v2/translate", "Authorization: DeepL-Auth-Key", "text array, source_lang, target_lang"],
            ["Google Basic v2", "https://translation.googleapis.com/language/translate/v2", "X-Goog-Api-Key", "q array, source, target, format=text"],
        ],
    )
    document.add_heading("8.1 Reliability and cancellation", level=2)
    add_bullets(
        document,
        [
            "Batch size is capped at 50 and Google language tags are reduced to base language where appropriate.",
            "DeepL source codes are normalized to two-letter uppercase; targets retain supported regional forms.",
            "HTTP 429 and 5xx responses receive three bounded attempts with short backoff.",
            "Other non-2xx statuses fail immediately with provider, status, and corrective categories.",
            "A cancellation callback is checked between batches.",
            "Test Connection translates one harmless English phrase to Italian.",
        ],
    )
    document.add_heading("8.2 Official protocol references", level=2)
    add_bullets(
        document,
        [
            "DeepL authentication: https://developers.deepl.com/docs/getting-started/auth",
            "DeepL quickstart: https://developers.deepl.com/docs/getting-started/quickstart",
            "Google Basic translate method: https://docs.cloud.google.com/translate/docs/reference/rest/v2/translate",
            "Google Cloud Translation authentication: https://docs.cloud.google.com/translate/docs/authentication",
            "Google API-key best practices: https://docs.cloud.google.com/docs/authentication/api-keys-best-practices",
        ],
    )

    document.add_heading("9. Bulk Translation and Review Semantics", level=1)
    add_steps(
        document,
        [
            "Validate that a catalog and target locale exist.",
            "Build an exact-match memory from reviewed and approved entries in the target catalog.",
            "Count local reuses and provider-bound missing/source-changed/error entries while excluding excluded and obsolete entries.",
            "Present a developer confirmation with both counts.",
            "Resolve the selected provider and effective key only when provider-bound entries remain.",
            "Send batches and preserve output ordering.",
            "Commit local reuses and provider results only after the provider operation returns successfully.",
            "Preserve reviewed/approved status for local reuse, mark provider results machine-translated, invalidate validation, refresh the list, and save an existing catalog.",
        ],
    )
    add_paragraphs(
        document,
        [
            "This all-or-error assignment avoids a half-updated in-memory catalog when a later batch fails. Existing reviewed/approved complete translations do not qualify for replacement. Human review remains a product rule, not an optional recommendation.",
        ],
    )

    document.add_heading("10. Validation and Runtime Pack Export", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Validation.Catalog validates metadata, missing target text, duplicates, changed source, placeholders, accelerators, and status conditions. Export is blocked by errors. DAT.Core.RuntimePack serializes only runtime-required metadata and strings and records a source-catalog checksum.",
            "Locale data is retained in the runtime pack so DAT.Runtime.Manager can expose a pack-specific TFormatSettings without globally mutating the developer's source code.",
        ],
    )

    document.add_heading("11. Runtime Engine", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Runtime.LanguagePack loads and discovers JSON packs, checks application identity, and provides fallback lookup. DAT.Runtime.Preference reads/writes the selected locale. DAT.Runtime.Manager owns the active pack, discovery, preference, translation lookup, and locale format settings.",
            "DAT.Runtime.VCL and DAT.Runtime.FMX traverse existing component trees and supported collection properties. They apply values by stable key to already designer-created controls. Missing keys retain source text. The adapters do not create controls or rearrange layouts.",
        ],
    )
    document.add_heading("11.1 Deployment paths", level=2)
    add_bullets(
        document,
        [
            "Packs: <ExecutableDirectory>\\Localization\\Languages\\<locale>.json.",
            "Preference: %LOCALAPPDATA%\\<ApplicationId>\\language.ini.",
            "Studio preference: %LOCALAPPDATA%\\DelphiAppTranslationStudio\\language.ini.",
            "Developer catalogs remain in the target source tree under Localization\\Development.",
        ],
    )

    document.add_heading("12. Integration Planning and Transactions", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Integration.Plan builds a human-readable plan. DAT.Integration.Package creates the generated application unit, framework adapter, shared runtime units, JSON packs, language-menu manifest, and deployment script. DAT.Integration.Engine builds every proposed file change in memory.",
            "DAT.Integration.MenuResource modifies text DFM/FMX menus idempotently and preserves designer editability. DAT.Integration.DelphiSource applies narrowly scoped DPR, PAS, and DPROJ wiring. DAT.Integration.Transaction checks source state, creates a verified pre-change backup, writes files atomically, rolls back failures, and records a manifest for restore.",
        ],
    )
    document.add_heading("12.1 Generated startup contract", level=2)
    add_bullets(
        document,
        [
            "InitializeTranslation runs before form creation.",
            "ApplyTranslation is called for created forms.",
            "SelectLanguageMenuItem derives a locale from datLanguage_<locale> component names.",
            "TranslateText provides resourcestring/code fallback access.",
            "Runtime ownership is finalized safely.",
        ],
    )
    add_callout(
        document,
        "Original code preservation.",
        "Integration adds narrowly scoped calls and units but does not replace original captions or rewrite every control. The original DFM/FMX values continue to be the source-language fallback.",
    )

    document.add_heading("13. Self-Localization", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Studio.Translation resolves the project/deployed pack directory, initializes a Studio runtime before form creation, applies the active pack in FormCreate, and maps persisted language-menu names to locale codes. Self-integration recognizes the existing runtime and plans only the menu-resource change, preventing duplicate startup wiring.",
        ],
    )

    document.add_heading("14. Error Handling and Diagnostics", level=1)
    add_bullets(
        document,
        [
            "Project, scan, catalog, validation, export, integration, credential, and provider errors are caught at Studio event boundaries and summarized in the status card.",
            "Provider exceptions carry an optional HTTP status but not response bodies.",
            "Form scanners return file/line diagnostics without instantiating target UI.",
            "Integration previews enumerate affected files and descriptions before mutation.",
            "Transaction errors trigger rollback and retain backup evidence.",
            "Provider keys must never be added to troubleshooting logs.",
        ],
    )

    document.add_heading("15. Test Strategy and Verified Matrix", level=1)
    add_table(
        document,
        ["Test", "Coverage"],
        [
            ["FoundationSmokeTests", "Detection, catalog round-trip/merge, scan, validation, runtime pack, preference, package, target integration, self change set."],
            ["VCLRuntimeSmokeTests", "VCL controls, menu items, locale, generated unit."],
            ["FMXRuntimeSmokeTests", "FMX controls, menu items, locale, generated unit."],
            ["StudioFormSmokeTests", "Direct FMX stream/create, masked key field, provider list, Settings activation."],
            ["RunRuntimeSmokeTests.ps1", "Both compilers plus disposable integrated VCL/FMX projects."],
            ["RunStudioLaunchSmokeTests.ps1", "Debug/Release Win32/Win64 real main-window title."],
            ["RunStudioSelfLocalizationSmokeTest.ps1", "Italian Studio title in all four configurations with state restoration."],
        ],
    )
    add_paragraphs(
        document,
        [
            "On August 6, 2026, Debug and Release builds passed for Win32 and Win64; the full runtime/integration suite passed under both compilers; normal launch and Italian self-localization passed in all four configurations; and direct FMX form streaming passed.",
        ],
    )
    document.add_heading("15.1 Live provider testing", level=2)
    add_paragraphs(
        document,
        [
            "Automated fixtures must not contain live keys. Release testing uses an owner-supplied restricted key through the Settings page, confirms Test Connection, translates a small disposable catalog, checks machine-translated status, then removes or rotates the test key. Network/provider availability is external state and is not required for offline runtime tests.",
        ],
    )

    document.add_heading("16. Security Review", level=1)
    add_table(
        document,
        ["Threat", "Control"],
        [
            ["Key committed to Git", "No key field in settings JSON/catalogs; Credential Manager or memory only; release secret scan."],
            ["Key leaked through URL/log", "Authentication headers, redacted errors, no body/header logging."],
            ["Wrong target changed", "Profile display, previewed file change set, explicit Apply."],
            ["Unrecoverable source mutation", "Verified G-drive project backup by workflow policy plus transaction backup/manifest/restore."],
            ["Installed-folder write failure", "Per-user language preference; packs are read-only deployment assets."],
            ["Machine mistranslation shipped", "Machine-translated status, validation, required human review."],
            ["Pack for wrong application", "applicationId validation in pack discovery/loading."],
        ],
    )
    add_paragraphs(
        document,
        [
            "Windows Credential Manager follows Microsoft guidance for application credentials (CredWrite/CredRead). It protects persistence under the signed-in Windows context; it does not make a key safe from malware running as that user. Provider-side restrictions, quotas, rotation, and least privilege remain necessary.",
        ],
    )

    document.add_heading("17. Release and Contribution Workflow", level=1)
    add_steps(
        document,
        [
            "Read global and repository directives.",
            "Confirm the exact requested scope and make a pre-change backup when changes are approved.",
            "Keep UI edits in the FMX designer resource and source event logic separate.",
            "Add deterministic tests without credentials.",
            "Run Win32/Win64 Debug/Release builds elevated.",
            "Run runtime, form-streaming, launch, and self-localization suites.",
            "Update phase notes, help, User Guide, Engineering Guide, real TOCs, PDFs, and visual QA.",
            "Check for a stale zero-byte .git\\index.lock with no Git process.",
            "Review status, stage only intended files, commit clearly, and push every configured remote.",
        ],
    )

    document.add_heading("18. Known Boundaries and Future-Compatible Design", level=1)
    add_bullets(
        document,
        [
            "Only Windows Win32/Win64 Delphi applications are supported.",
            "Google Advanced v3, OAuth/service-account workflows, and other providers are not implemented.",
            "Provider operations currently run as an explicit Studio action; target runtime remains offline.",
            "No automatic control resizing/reflow is performed.",
            "Binary DFM conversion is outside the scanner.",
            "Live language application to already-open target forms depends on generated event usage; restart is the conservative workflow.",
            "Provider account terms and language support are external and must be rechecked for each release.",
        ],
    )

    document.add_heading("19. Documentation Generation", level=1)
    add_paragraphs(
        document,
        [
            "The editable guides are generated from actual source and engineering notes with python-docx. Each DOCX contains a Word TOC field, a dedicated TOC section, and a new-page content section. Microsoft Word COM updates the TOC and fields, repaginates, saves the DOCX, and exports the companion PDF through ExportAsFixedFormat. PDFs are rendered to page images and inspected before release.",
        ],
    )

    document.add_heading("20. Source References", level=1)
    add_bullets(
        document,
        [
            "Repository source, forms, project metadata, schemas, and smoke tests as of August 6, 2026.",
            "Microsoft credential handling: https://learn.microsoft.com/en-us/windows/win32/secbp/handling-passwords",
            "Windows CREDENTIAL structure: https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentialw",
            "DeepL developer documentation: https://developers.deepl.com/docs/getting-started/auth",
            "Google Cloud Translation documentation: https://docs.cloud.google.com/translate/docs/authentication",
            "Google API-key guidance: https://docs.cloud.google.com/docs/authentication/api-keys-best-practices",
        ],
    )

    path = GUIDES_DIR / "Delphi App Translation Studio Engineering Guide.docx"
    finish_document(document, path)
    return path


if __name__ == "__main__":
    for generated_path in (build_user_guide(), build_engineering_guide()):
        print(generated_path)
