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
LAST_CHANGED = "August 7, 2026"
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

def set_table_geometry(table, widths: list[int], indent: int = 120) -> None:
    if sum(widths) != 9360:
        raise ValueError("Table widths must total 9360 DXA.")
    table.autofit = False
    properties = table._tbl.tblPr
    for tag in ("w:tblW", "w:tblInd", "w:tblLayout", "w:tblCellMar"):
        existing = properties.find(qn(tag))
        if existing is not None:
            properties.remove(existing)

    table_width = OxmlElement("w:tblW")
    table_width.set(qn("w:w"), "9360")
    table_width.set(qn("w:type"), "dxa")
    properties.append(table_width)
    table_indent = OxmlElement("w:tblInd")
    table_indent.set(qn("w:w"), str(indent))
    table_indent.set(qn("w:type"), "dxa")
    properties.append(table_indent)
    layout = OxmlElement("w:tblLayout")
    layout.set(qn("w:type"), "fixed")
    properties.append(layout)

    margins = OxmlElement("w:tblCellMar")
    for side, value in (
        ("top", 80), ("bottom", 80), ("start", 120), ("end", 120)
    ):
        margin = OxmlElement(f"w:{side}")
        margin.set(qn("w:w"), str(value))
        margin.set(qn("w:type"), "dxa")
        margins.append(margin)
    properties.append(margins)

    grid = table._tbl.tblGrid
    for column in list(grid):
        grid.remove(column)
    for width in widths:
        column = OxmlElement("w:gridCol")
        column.set(qn("w:w"), str(width))
        grid.append(column)

    for row in table.rows:
        for index, cell in enumerate(row.cells):
            cell.width = Inches(widths[index] / 1440)
            cell_properties = cell._tc.get_or_add_tcPr()
            cell_width = cell_properties.find(qn("w:tcW"))
            if cell_width is None:
                cell_width = OxmlElement("w:tcW")
                cell_properties.append(cell_width)
            cell_width.set(qn("w:w"), str(widths[index]))
            cell_width.set(qn("w:type"), "dxa")


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
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)


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
    normal.font.name = "Calibri"
    normal.font.size = Pt(11)
    normal.font.color.rgb = RGBColor.from_string("26384A")
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    for name, size, color in (
        ("Title", 29, BLUE),
        ("Subtitle", 15, GRAY),
        ("Heading 1", 16, "2E74B5"),
        ("Heading 2", 13, "2E74B5"),
        ("Heading 3", 12, "1F4D78"),
    ):
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.bold = name != "Subtitle"
        style.paragraph_format.keep_with_next = True
        if name == "Heading 1":
            style.paragraph_format.space_before = Pt(18)
            style.paragraph_format.space_after = Pt(10)
        elif name == "Heading 2":
            style.paragraph_format.space_before = Pt(14)
            style.paragraph_format.space_after = Pt(7)
        elif name == "Heading 3":
            style.paragraph_format.space_before = Pt(10)
            style.paragraph_format.space_after = Pt(5)
        else:
            style.paragraph_format.space_before = Pt(0)
            style.paragraph_format.space_after = Pt(8)

    for name in ("List Bullet", "List Number"):
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(11)
        style.paragraph_format.left_indent = Inches(0.375)
        style.paragraph_format.first_line_indent = Inches(-0.188)
        style.paragraph_format.space_after = Pt(4)
        style.paragraph_format.line_spacing = 1.25

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
    set_table_geometry(accent, [4680, 4680], indent=0)
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
    numbering = document.part.numbering_part.element
    style_num_id = int(
        document.styles["List Number"].element.pPr.numPr.numId.val
    )
    base_number = numbering.xpath(
        f'./w:num[@w:numId="{style_num_id}"]'
    )[0]
    abstract_id = base_number.find(qn("w:abstractNumId")).get(qn("w:val"))
    existing_ids = [
        int(element.get(qn("w:numId"))) for element in numbering.findall(qn("w:num"))
    ]
    list_num_id = max(existing_ids, default=0) + 1
    number = OxmlElement("w:num")
    number.set(qn("w:numId"), str(list_num_id))
    abstract_number = OxmlElement("w:abstractNumId")
    abstract_number.set(qn("w:val"), abstract_id)
    number.append(abstract_number)
    level_override = OxmlElement("w:lvlOverride")
    level_override.set(qn("w:ilvl"), "0")
    start_override = OxmlElement("w:startOverride")
    start_override.set(qn("w:val"), "1")
    level_override.append(start_override)
    number.append(level_override)
    numbering.append(number)

    for item in items:
        paragraph = document.add_paragraph(item, style="List Number")
        number_properties = paragraph._p.get_or_add_pPr().get_or_add_numPr()
        number_properties.get_or_add_ilvl().val = 0
        number_properties.get_or_add_numId().val = list_num_id


def add_callout(document: Document, title: str, text: str) -> None:
    table = document.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_geometry(table, [9360])
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
    widths_by_count = {
        2: [2700, 6660],
        3: [1800, 3900, 3660],
        4: [1500, 2500, 2680, 2680],
    }
    widths = widths_by_count.get(
        len(headers), [9360 // len(headers)] * len(headers)
    )
    widths[-1] += 9360 - sum(widths)
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
            cells[index].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    set_table_geometry(table, widths)


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
            "Delphi App Translation Studio is an offline-first Windows developer tool for adding localization to existing Delphi VCL and FireMonkey applications. It scans designer-authored forms and Delphi resourcestring declarations, stores the results in an editable development catalog, automatically translates unresolved text through Google Cloud Translation or DeepL, validates translation safety, and exports a compact JSON pack for the target application.",
            "The Studio itself is built with FireMonkey, but it works with both VCL and FMX target projects. The supported build targets are Windows Win32 and Win64. macOS, iOS, Android, Linux, C++Builder, and runtime cloud translation are outside the product scope.",
        ],
    )
    add_callout(
        document,
        "Offline by design.",
        "Only the developer's Studio computer needs Internet access while creating translations. The finished target application reads local JSON language packs and never needs Internet access, a provider account, or an API key.",
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
            "The Studio opens maximized. Use the left workflow panel; every page expands into the available workspace and the blue selection bar follows Project, Scan, Translate, Validation, Export, Integration, and Provider Settings.",
        ],
    )

    document.add_heading("3. The End-to-End Workflow", level=1)
    add_table(
        document,
        ["Step", "Purpose", "Primary output"],
        [
            ["1 Project", "Open and identify a Delphi project.", "Project profile"],
            ["2 Scan", "Extract designated designer text and resourcestrings.", "Scan result"],
            ["3 Translate", "Select a language and translate unresolved text automatically.", "Saved machine-translation catalog"],
            ["4 Validation", "Check completeness and structural safety.", "Issue list"],
            ["5 Export", "Create the compact offline pack.", "Runtime JSON"],
            ["6 Integration", "Preview/apply runtime and language-menu wiring.", "Integrated target project"],
            ["7 Provider Settings", "Configure and test Google Cloud Translation or DeepL.", "Secure provider configuration"],
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
            "Choose Translate after scanning.",
            "Select the source language, normally English (United States) [en-US].",
            "Select the target language from the built-in language list. The Studio records its locale code and native name.",
            "Review the automatically selected left-to-right or right-to-left direction.",
            "Review or edit the date, time, decimal, thousands, and currency fields. Blank fields are initially populated from Delphi TFormatSettings for the target locale.",
            "Choose Save.",
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
            ["AI draft", "Legacy provenance retained when opening a catalog created by an earlier Studio build."],
            ["Machine translated", "DeepL or Google produced a draft that requires review."],
            ["Imported", "CSV supplied target text that requires review."],
            ["Edited", "A person changed or entered the target text."],
            ["Reviewed", "A person reviewed the target text."],
            ["Approved", "The entry is release-approved."],
            ["Source changed", "The source changed after a translation existed."],
            ["Excluded", "The entry is intentionally omitted."],
            ["Obsolete", "The source entry no longer exists in the latest scan."],
            ["Error", "The entry needs correction after a failed operation or check."],
        ],
    )

    document.add_heading("5.2 Automatic Google or DeepL workflow", level=2)
    add_steps(
        document,
        [
            "Open Provider Settings and select Google Cloud Translation or DeepL.",
            "Paste the provider API key into the masked field, choose secure Windows Credential Manager storage or session-only use, and select Replace / Save Key.",
            "Choose Test Connection. Resolve any authentication, billing, restriction, firewall, or quota error before translating a project.",
            "Return to Translate, select the target language, and choose Translate Automatically.",
            "Confirm the displayed provider and unresolved-entry count. The Studio sends only eligible unresolved source strings; Reviewed, Approved, Excluded, and Obsolete entries are not replaced.",
            "The Studio processes provider requests in bounded batches, records each result as Machine translated with Google or DeepL provenance, saves the development catalog automatically, and leaves every result ready for human review.",
        ],
    )
    add_callout(
        document,
        "No extra software installation.",
        "Automatic translation is built into the Studio. It requires only a supported provider account and API key; no command-line AI agent, Python package, browser extension, or separate translation utility is required.",
    )

    document.add_heading("5.3 Safety, context, and focused review", level=2)
    add_bullets(
        document,
        [
            "Designer-property entries are applied automatically by the VCL or FMX runtime adapter.",
            "Pascal resourcestring entries require an explicit TranslateText(Key, Fallback) call at the intended code location. Mark Manual wiring confirmed only after adding and reviewing that call.",
            "Translation origin is independent of Draft, Reviewed, and Approved status. A provider result is never silently approved.",
            "Only Needs Translation, Source Changed, and Error entries are eligible. Existing Machine-translated, Imported, Edited, Reviewed, Approved, Excluded, and Obsolete work is protected unless the developer changes its status deliberately.",
            "The terminology profile records application context, audience, tone, formality, protected names, and preferred terminology.",
            "Validation focuses on placeholders, accelerators, inconsistent repeated terms, source changes, and runtime wiring.",
            "Exact-source translations from other stable keys are suggestions only. The developer must explicitly accept one, and the accepted target remains Edited rather than inheriting approval.",
        ],
    )

    document.add_heading("6. Provider Settings and Secure Key Storage", level=1)
    add_paragraphs(
        document,
        [
            "Provider Settings supports DeepL API Free, DeepL API Pro, and Google Cloud Translation Basic v2. Provider accounts, billing, quotas, prices, and supported languages are controlled by the provider and may change.",
            "A remembered key is stored as a Windows Generic Credential for the current Windows user. The key is not written to the Delphi project, JSON catalogs, exported packs, source distribution, or Git repository. Session-only keys are cleared when the Studio closes.",
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
            "Open Google Cloud Console at https://console.cloud.google.com/ and sign in with the account that will own billing and credentials.",
            "Use the project selector to create a dedicated project, such as Delphi App Translation Studio, or select an existing project whose billing and key lifecycle you control.",
            "Open Billing for that project and link an active billing account. Cloud Translation setup requires billing to be enabled even when usage might fall within a current no-charge allowance.",
            "Open APIs & Services, then Library. Search for Cloud Translation API, open it, and choose Enable. Confirm that the selected project is still the intended project.",
            "Open APIs & Services, then Credentials. Choose Create credentials, then API key. Create a standard API key; do not bind it to a service account for this Studio.",
            "Name the key clearly, for example Delphi App Translation Studio - <computer or developer>. Google requires at least one API restriction when a key is created in the console.",
            "Under API restrictions, choose Restrict key and select only Cloud Translation API (service translate.googleapis.com), then save. Do not leave the key usable with every Google API.",
            "Application restrictions are recommended by Google, but the available types are websites, server IP addresses, Android, and iOS. A native Windows desktop application has no matching signed-application restriction. Use an IP-address restriction only when the developer computer exits through a stable public IP that you control; do not select website, Android, or iOS restrictions for the Studio.",
            "Copy the displayed key string immediately and keep it out of source code, JSON, screenshots, email, issue trackers, and chat. The key ID or display name is not the usable key string.",
            "Review Cloud Translation pricing, quotas, and billing budget alerts before a large project. API keys associate requests with the project for quota and billing.",
            "In the Studio, choose Provider Settings and select Google Cloud Translation. The DeepL plan list becomes disabled because it does not apply.",
            "Paste the key into the masked field. Leave Remember securely checked to store it as a Windows Generic Credential, or clear the check box for session-only use.",
            "Choose Replace / Save Key, then Test Connection. A successful test translates one small English phrase to Italian.",
            "If the test returns HTTP 403, verify the selected project, billing, API enablement, and API/application restrictions. HTTP 429 normally indicates a quota or rate limit. After changing a Google restriction, allow a few minutes for propagation and test again.",
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

    document.add_heading("9. Direct Provider Translation", level=1)
    add_steps(
        document,
        [
            "Open or create the target-language catalog.",
            "Confirm the source and target language codes.",
            "Configure and test a provider under Provider Settings.",
            "Choose Translate Automatically on the Translate page.",
            "Read the confirmation message showing how many unresolved strings will be sent to the provider. Cross-key suggestions are never accepted automatically.",
            "Choose Yes to begin. Existing complete reviewed or approved work is preserved.",
            "Wait for all batches. Transient HTTP 429 and provider server failures receive bounded retries.",
            "Review every machine-translated entry for meaning, placeholders, accelerators, product terminology, tone, and available control space.",
            "The Studio saves the catalog automatically. Run Validation after reviewing the results.",
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
            "Structural validation checks catalog metadata, required translations, duplicate keys, source changes, Delphi indexed/sequential placeholders, accelerator keys, and excluded/obsolete conditions. Errors block export. Manual resourcestring wiring is reported as a runtime-readiness warning. Linguistic Reviewed and Approved states are reported separately and are not inferred from structural validation.",
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
            "Integration adds the offline runtime, generated application-specific unit, startup calls, event wiring, and designer-persisted language menu items. It automatically builds an English source-language pack from the latest scan, normalizes and de-duplicates the available language list, and installs every JSON pack transactionally. It populates the named menu when present; when absent, it adds an FMX TMenuBar/TMenuItem or VCL TMainMenu/TMenuItem to the primary form and adds matching form-class declarations. It does not add provider access to the target.",
        ],
    )
    add_steps(
        document,
        [
            "Close or save the target project in Delphi.",
            "Select Integration and confirm the designated language menu component name, normally mnuLanguage. The plan states whether that designer menu will be populated or added to the primary form.",
            "Choose Build Integration Plan and review each proposed operation.",
            "Choose Generate Preview. The exact-change viewer is optional; select any changed file when you want to inspect its line-numbered original/proposed text.",
            "Check the single authorization box. You do not have to open or approve every file separately.",
            "Optionally select Build and deploy after Apply, then choose Win32 or Win64 and Debug or Release. The Studio requests elevation for the Delphi build, deploys packs, and never launches the target.",
            "Choose Apply. The Studio creates and verifies a pre-change backup, writes atomically, and records a restore manifest.",
            "If automatic build/deploy was not selected, reopen the target project, inspect the DFM/FMX menu items in the IDE, build, and copy the packs beside the executable.",
            "Run the target and select a language. Every currently open form is translated immediately; forms created later receive the saved language in their designer-persisted OnCreate path.",
            "Use Restore to recover the recorded pre-integration state if needed.",
        ],
    )

    document.add_heading("11.1 Runtime files and preferences", level=2)
    add_bullets(
        document,
        [
            "Deploy JSON packs beside the target executable under Localization\\Languages.",
            "Use Build and deploy after Apply for the automatic path. Deploy-LanguagePacks.ps1 and manual copying remain available for custom output layouts.",
            "The selected language is stored in %LOCALAPPDATA%\\<ApplicationId>\\language.ini.",
            "The executable folder can therefore remain read-only, as it normally is under Program Files.",
            "VCL startup applies the first form through generated DPR wiring. FMX integration persists an OnCreate handler in every form resource and applies translation after FMX streaming; an existing handler is preserved.",
            "Selecting or reselecting a language applies the selected pack to every open form immediately. English is a real generated pack, so returning from another language restores all scanned source strings without restarting.",
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
            "Select the new language. Open forms change immediately and the preference is retained for the next launch.",
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
            "This guide documents the implemented Studio as of August 7, 2026.",
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
        '  "schemaVersion": 3,\n'
        '  "applicationId": "SampleApp",\n'
        '  "sourceLanguage": "en-US",\n'
        '  "locale": {"languageCode": "it-IT", "nativeLanguageName": "Italiano"},\n'
        '  "entries": [{"key": "frmMain.btnSave.Text", "sourceText": "Save",\n'
        '               "translatedText": "Salva", "status": "machineTranslated",\n'
        '               "translationOrigin": "google",\n'
        '               "runtimeApplication": "automatic"}]\n'
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
            "DAT.Studio.MainForm.fmx contains the complete orange-and-blue interface. The form persists WindowState=wsMaximized, uses client-aligned workflow cards, anchors resizable work areas to every relevant edge, and keeps the status card at the bottom. The workflow selection rectangle moves among Project, Scan, Translate, Validation, Export, Integration, and Provider Settings. Language and provider choices, Translate Automatically, key-management actions, and all other controls are persisted designer objects. DAT.Studio.MainForm.pas contains event and state logic only; it does not construct controls.",
            "Each workflow TLabel explicitly persists HitTest=True. FireMonkey labels default to HitTest=False, which would otherwise pass mouse events through the visible label even when an OnClick event is assigned. The setting remains editable in the Object Inspector.",
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

    document.add_heading("9. Automatic Provider Translation and Review", level=1)
    add_paragraphs(
        document,
        [
            "Translate Automatically is the canonical machine-translation path. It validates the selected catalog language, loads the selected provider settings and effective key, counts eligible unresolved entries, and shows the provider and count before any network request.",
            "Eligible source strings are copied into ordered arrays and sent through DAT.Provider.Client in bounded batches. Reviewed, Approved, Excluded, and Obsolete entries are not overwritten. Provider results are mapped back by index, marked Machine translated, tagged with Google or DeepL provenance, and saved to the canonical development catalog automatically.",
            "If no key is available, the workflow opens Provider Settings and gives a specific corrective message. HTTP or parsing failures leave the catalog entries unchanged for the failed operation and report a redacted summary in the status card.",
            "CSV interchange and manual editing remain optional alternatives for translation-company collaboration or specialized review, not prerequisites for automatic translation.",
            "The Studio never copies a translation from one stable key to another automatically. Exact-source matches are suggestions only. Explicit acceptance creates an Edited result and does not inherit Reviewed or Approved status.",
        ],
    )
    add_bullets(
        document,
        [
            "Mark Reviewed requires nonblank translated text.",
            "Approve requires the entry to have reached Reviewed first.",
            "Translation origin is independent of linguistic status.",
            "Inconsistent repeated terms and structural defects form the focused exception queue; a valid machine-translated draft is not itself an error.",
            "Structural validity, linguistic status, automatic runtime coverage, and manual wiring readiness are separate measures.",
            "A Pascal resourcestring remains manual wiring until the developer confirms the generated TranslateText call site.",
        ],
    )

    document.add_heading("10. Validation and Runtime Pack Export", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Validation.Catalog validates metadata, missing target text, duplicates, changed source, Delphi indexed and sequential Format arguments, accelerators, inconsistent repeated-source terminology, and status conditions. Export is blocked by errors. Manual resourcestring wiring is reported separately from structural errors. DAT.Core.RuntimePack serializes only runtime-required metadata and strings and records a source-catalog checksum.",
            "Locale data is retained in the runtime pack so DAT.Runtime.Manager can expose a pack-specific TFormatSettings without globally mutating the developer's source code.",
        ],
    )

    document.add_heading("11. Runtime Engine", level=1)
    add_paragraphs(
        document,
        [
            "DAT.Runtime.LanguagePack loads and discovers JSON packs, checks application identity, rejects empty/invalid packs, canonicalizes native language names, de-duplicates exact locale codes, and suppresses a generic locale when a regional variant exists. DAT.Runtime.Preference reads/writes the selected locale. DAT.Runtime.Manager owns the active pack, discovery, preference, translation lookup, and locale format settings. The source language loads its generated JSON pack when present and falls back to designer text only for older deployments without that pack.",
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
            "DAT.Integration.Plan builds a human-readable plan. DAT.Integration.Package creates the generated application unit, framework adapter, shared runtime units, normalized JSON packs, automatic English source pack, language-menu manifest, and deployment script. DAT.Integration.Engine builds every proposed file change in memory, including language-pack installation. TIntegrationFileChange.ExactReviewText provides an optional complete line-numbered original/proposed LCS diff; generated files are shown in full.",
            "One explicit authorization enables Apply; opening every diff is not required. DAT.Integration.Transaction checks source state, creates a verified pre-change backup, writes files atomically, rolls back failures, and records a manifest for restore. DAT.Integration.BuildDeploy can then invoke the Delphi 37 build elevated and deploy the package packs to the standardized executable output without launching it.",
            "DAT.Integration.MenuResource modifies text DFM/FMX menus idempotently and preserves designer editability. It locates the first DPR-created form when a menu must be added, reuses an existing TMenuBar/TMainMenu when available, or persists a new framework-appropriate container and menu. DAT.Integration.DelphiSource adds matching component fields and applies narrowly scoped DPR, PAS, and DPROJ wiring. For FMX, it preserves an existing root OnCreate handler or persists datTranslationFormCreate in the FMX and adds ApplyTranslation(Self) to its Pascal method. This respects the FMX form streaming lifecycle and avoids translating the first form from the DPR immediately after CreateForm.",
        ],
    )
    document.add_heading("12.1 Generated startup contract", level=2)
    add_bullets(
        document,
        [
            "InitializeTranslation runs before form creation.",
            "VCL applies the first created form through the DPR startup wiring.",
            "FMX applies each form in its designer-persisted OnCreate handler after streaming is complete.",
            "SelectLanguageMenuItem derives a locale from datLanguage_<locale> component names.",
            "SelectLanguage applies the chosen pack to every currently open form immediately.",
            "The generated en-US pack makes switching back to source text deterministic.",
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
            "Integration previews show a complete line-numbered exact diff for every affected file before mutation.",
            "Transaction errors trigger rollback and retain backup evidence.",
            "Provider keys must never be added to troubleshooting logs.",
        ],
    )

    document.add_heading("15. Test Strategy and Verified Matrix", level=1)
    add_table(
        document,
        ["Test", "Coverage"],
        [
            ["FoundationSmokeTests", "Detection, scan-to-catalog, schema/provenance round-trip, provider client contracts, CSV interchange, review/approval, validation, runtime pack, preference, exact diff, integration, and self change set."],
            ["VCLRuntimeSmokeTests", "VCL controls, menu items, locale, generated unit."],
            ["FMXRuntimeSmokeTests", "All representative FMX form properties, menu items, locale, generated unit."],
            ["StudioFormSmokeTests", "Direct FMX stream/create, maximized client-aligned pages, provider-only automatic-translation controls, exact-review controls, linguistic action wiring, and Provider Settings activation."],
            ["RunRuntimeSmokeTests.ps1", "Both compilers, scanner/catalog/provider contracts, disposable integrated VCL/FMX builds, deployed Italian pack, and required Italian launch title."],
            ["RunStudioLaunchSmokeTests.ps1", "Debug/Release Win32/Win64 real main-window title."],
            ["RunStudioSelfLocalizationSmokeTest.ps1", "Italian Studio title in all four configurations with state restoration."],
        ],
    )
    add_paragraphs(
        document,
        [
            "On August 7, 2026, the deterministic release gate passed with real compilable VCL and FMX samples under Win32 and Win64. Scanner, catalog, provider request/response contracts, review, validation, export, integration, deployed packs, and required Italian launch titles passed without embedding a live credential. The Studio built in Debug and Release for both architectures, streamed its FMX form directly, launched normally, and self-localized to Italian in all four configurations.",
        ],
    )
    document.add_heading("15.1 Optional live provider testing", level=2)
    add_paragraphs(
        document,
        [
            "Automated fixtures must not contain live keys. Live provider acceptance uses an owner-supplied restricted key through Provider Settings, confirms Test Connection, translates a small disposable catalog, checks Machine translated status and provider provenance, then removes or rotates the test key. Provider availability is external state and cannot be made deterministic, but live provider acceptance is required before a public release that claims current Google or DeepL compatibility.",
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
            "Provider operations are explicit Studio actions; target runtime remains offline.",
            "No automatic control resizing/reflow is performed.",
            "Binary DFM conversion is outside the scanner.",
            "Automatic runtime application covers scanned designer properties. Application-specific strings still require the documented TranslateText wiring.",
            "Provider account terms and language support are external and must be rechecked for each release.",
        ],
    )

    document.add_heading("19. Documentation Generation", level=1)
    add_paragraphs(
        document,
        [
            "The editable guides are generated from actual source and engineering notes with python-docx. Each DOCX contains a Word TOC field, a dedicated TOC section, and a new-page content section. Microsoft Word COM updates the TOC and fields, repaginates, and saves the DOCX. Word ExportAsFixedFormat is the preferred companion-PDF path; when that host export is unavailable, the documented fallback is styled HTML/CSS printed through Playwright. Final PDFs are rendered to page images and inspected before release.",
        ],
    )

    document.add_heading("20. Source References", level=1)
    add_bullets(
        document,
        [
            "Repository source, forms, project metadata, schemas, and smoke tests as of August 7, 2026.",
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
