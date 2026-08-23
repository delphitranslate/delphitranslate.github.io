program FMXRuntimeSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.Math,
  System.TypInfo,
  System.SysUtils,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Types,
  System.UITypes,
  SampleFMX.MainForm in '..\..\samples\FMXBasic\SampleFMX.MainForm.pas'
    {frmFMXSample},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"SampleFMXApp",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmFMXSample.Caption":"FMX Beispiel",' +
    '"frmFMXSample.lblHeading.Text":"Kundendaten",' +
    '"frmFMXSample.lblCustomerName.Text":"Kundenname",' +
    '"frmFMXSample.edtCustomerName.TextPrompt":"Vollst\u00e4ndiger Name",' +
    '"frmFMXSample.btnSave.Text":"Kunde speichern",' +
    '"frmFMXSample.mnuFile.Text":"Datei",' +
    '"frmFMXSample.mnuExit.Text":"Beenden",' +
    '"frmFMXSample.mnuLanguage.Text":"Sprache",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.0":"Heute",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.1":"Letzte 7 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.2":"Letzte 28 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.3":"Letzte 90 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.4":"Dieses Jahr",' +
    '"frmFMXSample.chkSendCopy.Text":"Kopie senden",' +
    { The heading arrives with a break mark in it, the way a translation of a
      long word does. A heading never wraps, so the offer is never taken and
      the mark can only ever do harm. }
    '"frmFMXSample.colCustomer.Header":"Kun' + #$00AD + 'de",' +
    '"frmFMXSample.memInstructions.Lines.Strings.0":"Erste Zeile",' +
    '"frmFMXSample.memInstructions.Lines.Strings.1":"Zweite Zeile"},' +
    '"sourceStrings":{"Close":"Schlie' + #$00DF + 'en","Event":"Evento"},' +
    '"sourceTemplates":{"Uptime: %d years":"Laufzeit: %d Jahre"},' +
    { The source text for each key, which is what returning to the original
      language reads. Left empty, the words stay translated however well the
      geometry is put back. }
    '"sources":{"frmFMXSample.Caption":"FMX Sample",' +
    '"frmFMXSample.lblHeading.Text":"Customer details",' +
    '"frmFMXSample.lblCustomerName.Text":"Customer name",' +
    '"frmFMXSample.btnSave.Text":"&Save Customer"},' +
    '"layout":[{"formName":"frmFMXSample",' +
    '"componentName":"lblHeading","propertyName":"Width",' +
    '"originalValue":"360","translatedValue":"480",' +
    '"sourceChecksum":"layout-test"},' +
    { The remaining six layout properties, on one control, in the arrangement
      that kept reaching the screen broken: a label told to stop sizing itself
      and then given a width, a height, wrapping and a smaller size. Order is
      what makes it work. Switch the sizing off after the width is set and the
      label springs back around its text; set the size after the height and
      the height no longer suits the text it has to hold. Only Width was ever
      asserted here, which is why none of that was caught. }
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"AutoSize","originalValue":"True",' +
    '"translatedValue":"False","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"FontSize","originalValue":"14",' +
    '"translatedValue":"11.5","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"Width","originalValue":"180",' +
    '"translatedValue":"120","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"Height","originalValue":"26",' +
    '"translatedValue":"58","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"Position.X","originalValue":"0",' +
    '"translatedValue":"24","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"lblCustomerName",' +
    '"propertyName":"Position.Y","originalValue":"66",' +
    '"translatedValue":"70","sourceChecksum":"layout-test"},' +
    { A rule that names neither a size nor a place. The runtime carries its own
      fitting heuristics, which measure the text afresh and resize a control to
      suit; they are meant to stand aside wherever the analyser has already
      decided something. The guard that arranges that once counted only the
      four geometry properties, so a control spoken about in any other terms
      looked untouched and was resized against the plan. This button asks only
      for a smaller size and must come through with the width it was drawn at. }
    '{"formName":"frmFMXSample","componentName":"btnSave",' +
    '"propertyName":"FontSize","originalValue":"14",' +
    '"translatedValue":"12","sourceChecksum":"layout-test"},' +
    { Two kinds of control the assertions had never reached. A check box
      carries its caption beside a tick box, so its width means something
      different from a label's; a grid column is not a control at all in the
      usual sense and is reached through the grid that owns it. }
    '{"formName":"frmFMXSample","componentName":"chkSendCopy",' +
    '"propertyName":"Width","originalValue":"200",' +
    '"translatedValue":"260","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"chkSendCopy",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"layout-test"},' +
    '{"formName":"frmFMXSample","componentName":"colCustomer",' +
    '"propertyName":"Width","originalValue":"180",' +
    '"translatedValue":"240","sourceChecksum":"layout-test"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  AppliedCount: Integer;
  DynamicLabel: TLabel;
  EventLabel: TLabel;
  OriginalFontColor: TAlphaColor;
  OriginalHorizontalAlignment: TTextAlign;
  OriginalStyledSettings: TStyledSettings;
  Pack: TRuntimeLanguagePack;
  TemplateLabel: TLabel;
begin
  try
    Application.Initialize;
    frmFMXSample := TfrmFMXSample.Create(nil);
    DynamicLabel := TLabel.Create(frmFMXSample);
    DynamicLabel.Text := 'Close';
    DynamicLabel.StyledSettings := [TStyledSetting.Family];
    DynamicLabel.TextSettings.FontColor := TAlphaColorRec.White;
    DynamicLabel.TextSettings.HorzAlign := TTextAlign.Trailing;
    EventLabel := TLabel.Create(frmFMXSample);
    EventLabel.Text := 'Event';
    OriginalFontColor := DynamicLabel.TextSettings.FontColor;
    OriginalHorizontalAlignment := DynamicLabel.TextSettings.HorzAlign;
    OriginalStyledSettings := DynamicLabel.StyledSettings;
    TemplateLabel := TLabel.Create(frmFMXSample);
    TemplateLabel.Text := 'Uptime: 2 years';
    { A data row whose text happens to match something the pack can translate.
      Grid cells are the application's data - song titles, file names, rows
      from a database - and must come through a translation untouched. }
    frmFMXSample.grdCustomers.RowCount := 1;
    frmFMXSample.grdCustomers.Cells[0, 0] := 'Event';
    Pack := TestPack;
    try
      AppliedCount := TFMXTranslationApplicator.ApplyToForm(
        frmFMXSample, Pack);
      Require(AppliedCount = 32, 'Unexpected FMX applied-property count.');
      Require(frmFMXSample.Caption = 'FMX Beispiel',
        'The FMX form caption was not translated.');
      Require(frmFMXSample.lblHeading.Text = 'Kundendaten',
        'The FMX label was not translated.');
      Require(Round(frmFMXSample.lblHeading.Width) = 480,
        'The FMX translated-language layout rule was not applied.');
      { The other six properties, on the control carrying all of them. Each of
        these was applied by the runtime and asserted by nobody, and each one
        was a defect the developer had to find by looking at his screen. The
        height matters most: a label pinned to a fixed size and told to wrap,
        but left at the height of one line, does not shorten its text, it cuts
        it off. }
      Require(not frmFMXSample.lblCustomerName.AutoSize,
        'Automatic sizing was not switched off.');
      Require(Round(frmFMXSample.lblCustomerName.Width) = 120,
        'The FMX width rule was not applied.');
      Require(Round(frmFMXSample.lblCustomerName.Height) = 58,
        'The FMX height rule was not applied, so wrapped text would be cut.');
      Require(frmFMXSample.lblCustomerName.TextSettings.WordWrap,
        'The FMX wrapping rule was not applied.');
      Require(SameValue(frmFMXSample.lblCustomerName.TextSettings.Font.Size,
        11.5, 0.01), 'The FMX text-size rule was not applied.');
      Require(Round(frmFMXSample.lblCustomerName.Position.X) = 24,
        'The FMX horizontal position rule was not applied.');
      Require(Round(frmFMXSample.lblCustomerName.Position.Y) = 70,
        'The FMX vertical position rule was not applied.');
      { Assigning the size and the wrapping is not enough on its own: the
        platform style overrides both unless it is told to stand aside, and it
        does so silently. }
      Require(not (TStyledSetting.Size in
        frmFMXSample.lblCustomerName.StyledSettings),
        'The platform style can still override the text size.');
      Require(not (TStyledSetting.Other in
        frmFMXSample.lblCustomerName.StyledSettings),
        'The platform style can still override wrapping.');
      { The button keeps the width the designer gave it. Its translated caption
        is longer than the original, so the fitting would widen it if it were
        allowed to look. }
      Require(Round(frmFMXSample.btnSave.Width) = 150,
        'The runtime fitting resized a button the analyser had ruled on.');
      Require(SameValue(frmFMXSample.btnSave.TextSettings.Font.Size, 12,
        0.01), 'The button text size rule was not applied.');
      { A check box and a grid column, neither of which the assertions had
        ever reached. }
      Require(frmFMXSample.chkSendCopy.Text = 'Kopie senden',
        'The check box caption was not translated.');
      Require(Round(frmFMXSample.chkSendCopy.Width) = 260,
        'A width rule was not applied to a check box.');
      Require(frmFMXSample.chkSendCopy.TextSettings.WordWrap,
        'A wrapping rule was not applied to a check box.');
      Require(Pos(#$00AD, frmFMXSample.colCustomer.Header) = 0,
        'A grid heading carries no break marks for the text engine to ' +
        'break at.');
      Require(frmFMXSample.colCustomer.Header = 'Kunde',
        'The grid column heading was not translated.');
      Require(frmFMXSample.grdCustomers.Cells[0, 0] = 'Event',
        'A grid cell was translated. Cells carry the application''s data, ' +
        'not its interface, and the substitution has no reliable inverse.');
      Require(Round(frmFMXSample.colCustomer.Width) = 240,
        'A width rule was not applied to a grid column.');
      Require(TFMXTranslationApplicator.ApplyLayoutToForm(frmFMXSample,
        Pack, 'frmFMXSample', False) = 12,
        'The FMX source-layout restore rules were not all applied.');
      Require(Round(frmFMXSample.lblHeading.Width) = 360,
        'The FMX source layout was not restored.');
      Require(frmFMXSample.mnuLanguage.Text = 'Sprache',
        'The FMX menu was not translated.');
      Require(frmFMXSample.cmbDateRange.ItemIndex = 2,
        'The FMX combo-box selection changed during translation.');
      Require(frmFMXSample.cmbDateRange.Selected.Text = 'Letzte 28 Tage',
        'The selected FMX combo-box item was not translated in place.');
      Require((frmFMXSample.memInstructions.Lines.Count = 2) and
        (frmFMXSample.memInstructions.Lines[1] = 'Zweite Zeile'),
        'The FMX memo lines were not translated.');
      Require(DynamicLabel.Text = 'Schlie' + #$00DF + 'en',
        'An anonymous runtime-created FMX label was not translated.');
      Require((DynamicLabel.TextSettings.FontColor = OriginalFontColor) and
        (DynamicLabel.TextSettings.HorzAlign = OriginalHorizontalAlignment) and
        (DynamicLabel.StyledSettings = OriginalStyledSettings),
        'FMX translation changed designer-owned label formatting.');
      Require(TemplateLabel.Text = 'Laufzeit: 2 Jahre',
        'A runtime-created FMX formatted caption was not translated.');
      Require(EventLabel.Text = 'Evento',
        'The FMX runtime source string was not translated.');
      Require(TFMXTranslationApplicator.ApplyToForm(frmFMXSample, Pack,
        frmFMXSample.Name, True, False) >= 0,
        'The FMX dynamic-only refresh failed.');
      TFMXTranslationApplicator.ApplyToForm(frmFMXSample, Pack,
        frmFMXSample.Name, True, False);
      Require(EventLabel.Text = 'Evento',
        'Repeated FMX dynamic refresh mutated an already-translated value.');
      Require(Round(frmFMXSample.lblHeading.Width) = 360,
        'A dynamic-only refresh reapplied language layout rules.');

      { Going back to the language the application was written in must give the
        form back, not only its words.

        The second control here is the point. Nothing in the pack mentions the
        customer-name edit, so a restore built out of rule original values has
        nothing to say about it; the run-time fitting resizes such controls all
        the same, and before the snapshot there was no record of what they had
        been. Standing in for the fitting, it is knocked out of shape by hand
        before the restore, and must come back. }
      frmFMXSample.edtCustomerName.Width := 123;
      frmFMXSample.edtCustomerName.Height := 61;
      frmFMXSample.lblCustomerName.Position.X := 37;
      TFMXTranslationApplicator.RestoreSourceLanguage(frmFMXSample, Pack,
        frmFMXSample.Name);
      Require(frmFMXSample.lblCustomerName.Text = 'Customer name',
        'Returning to the source language did not restore the text.');
      Require(Round(frmFMXSample.lblCustomerName.Width) = 180,
        'Returning to the source language did not restore a width.');
      Require(Round(frmFMXSample.lblCustomerName.Height) = 26,
        'Returning to the source language did not restore a height.');
      Require(Round(frmFMXSample.lblCustomerName.Position.X) = 0,
        'Returning to the source language did not restore a position.');
      Require(Round(frmFMXSample.lblCustomerName.Position.Y) = 66,
        'Returning to the source language did not restore a position.');
      Require(SameValue(frmFMXSample.lblCustomerName.TextSettings.Font.Size,
        14, 0.01),
        'Returning to the source language did not restore the text size.');
      Require(Round(frmFMXSample.edtCustomerName.Width) = 390,
        'A control with no layout rule was not restored from the snapshot.');
      Require(Round(frmFMXSample.edtCustomerName.Height) = 36,
        'A control with no layout rule was not restored from the snapshot.');
    finally
      Pack.Free;
      frmFMXSample.Free;
    end;
    Writeln('FMX runtime translation smoke test passed.');
  except
    on E: Exception do
    begin
      Writeln('FMX runtime translation smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
