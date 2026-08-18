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
    '"frmFMXSample.memInstructions.Lines.Strings.0":"Erste Zeile",' +
    '"frmFMXSample.memInstructions.Lines.Strings.1":"Zweite Zeile"},' +
    '"sourceStrings":{"Close":"Schlie' + #$00DF + 'en","Event":"Evento"},' +
    '"sourceTemplates":{"Uptime: %d years":"Laufzeit: %d Jahre"},' +
    '"sources":{},"layout":[{"formName":"frmFMXSample",' +
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
    '"translatedValue":"70","sourceChecksum":"layout-test"}]}';
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
    Pack := TestPack;
    try
      AppliedCount := TFMXTranslationApplicator.ApplyToForm(
        frmFMXSample, Pack);
      Require(AppliedCount = 26, 'Unexpected FMX applied-property count.');
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
      Require(TFMXTranslationApplicator.ApplyLayoutToForm(frmFMXSample,
        Pack, 'frmFMXSample', False) = 8,
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
