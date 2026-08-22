program FMXStyledRuntimeSmokeTests;

{ Layout rules under a platform style, and inside a styled container.

  This is the one place where a rule can be applied successfully and change
  nothing at all. A FireMonkey control does not own its own appearance: while a
  setting remains in StyledSettings, the platform style supplies the value and
  an assignment to the property is accepted and then ignored. Font size,
  wrapping, text alignment and colour are all in that position.

  The applicator knows this and clears each setting out of style control before
  assigning it. Nothing proved that it works, because every runtime test until
  now ran under the default style - which is the one style least likely to
  disagree with what the designer asked for. Two defects had already been
  traced to exactly this, and the harness that was supposed to catch them
  could not have.

  So this runs the same assertions under every platform style installed with
  RAD Studio, not a synthetic one, and inside a container rather than directly
  on the form. A style that overrides a font size will fail it.

  If no style files are found it says so and stops, rather than reporting a
  pass it did not earn.

  **What each assertion is actually worth**, established by deleting the
  applicator's style handling and watching what happened:

    - **Font size: proven.** With the clearing of TStyledSetting.Size
      removed, every one of the installed styles fails this. It is a real
      guard on a real trap.

    - **Wrapping: not proven, and worth knowing.** With the clearing of
      TStyledSetting.Other removed, it still passes - because none of the
      styles shipped with RAD Studio overrides wrapping on a label, so there
      is nothing for the clearing to defend against. The assertion is kept
      because it costs nothing and would catch a style that does override it,
      but nobody should read a pass here as evidence that the wrapping path
      works under style control. Proving it needs a style authored for the
      purpose.

  The first version of this program read TextSettings rather than
  ResultingTextSettings and passed with the whole of the applicator's style
  handling deleted - it proved nothing at all. That is recorded here because
  it is the exact mistake this kind of test invites. }

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.Math,
  System.IOUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Types,
  FMX.Styles,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.LayoutOverrides in '..\..\source\runtime\DAT.Runtime.LayoutOverrides.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

{ Every setting a platform style is entitled to overrule, on a label that is
  not on the form but two levels inside it. }
function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"StyledSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".",' +
    '"currencySymbol":"EUR"},' +
    '"strings":{"frmStyled.lblNested.Text":"Sehr viel laengerer Text als ' +
    'das englische Original, damit der Umbruch etwas zu tun hat."},' +
    '"sources":{"frmStyled.lblNested.Text":"Short caption"},' +
    '"layout":[' +
    '{"formName":"frmStyled","componentName":"lblNested",' +
    '"propertyName":"AutoSize","originalValue":"True",' +
    '"translatedValue":"False","sourceChecksum":"t"},' +
    '{"formName":"frmStyled","componentName":"lblNested",' +
    '"propertyName":"FontSize","originalValue":"12",' +
    '"translatedValue":"17","sourceChecksum":"t"},' +
    '{"formName":"frmStyled","componentName":"lblNested",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"t"},' +
    '{"formName":"frmStyled","componentName":"lblNested",' +
    '"propertyName":"Width","originalValue":"120",' +
    '"translatedValue":"260","sourceChecksum":"t"},' +
    '{"formName":"frmStyled","componentName":"lblNested",' +
    '"propertyName":"Height","originalValue":"20",' +
    '"translatedValue":"64","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

{ A form holding a panel holding a layout holding the label, so that the
  control under test is genuinely nested rather than a child of the form. }
function BuildForm(out ANested: TLabel): TForm;
var
  Panel: TPanel;
  Inner: TLayout;
begin
  Result := TForm.CreateNew(nil);
  Result.Name := 'frmStyled';
  Result.ClientWidth := 500;
  Result.ClientHeight := 320;

  Panel := TPanel.Create(Result);
  Panel.Parent := Result;
  Panel.Name := 'pnlOuter';
  Panel.SetBounds(10, 10, 460, 280);

  Inner := TLayout.Create(Result);
  Inner.Parent := Panel;
  Inner.Name := 'layInner';
  Inner.SetBounds(10, 10, 430, 240);

  ANested := TLabel.Create(Result);
  ANested.Parent := Inner;
  ANested.Name := 'lblNested';
  ANested.SetBounds(5, 5, 120, 20);
  ANested.Text := 'Short caption';
  ANested.AutoSize := True;
  { Left in style control on purpose. An application that never touches
    StyledSettings is the ordinary case, and it is the case where the style
    wins unless the applicator takes the setting away from it first. }
end;

{ The assertions, run once per style. }
procedure CheckUnderCurrentStyle(const AStyleName: string);
var
  Form: TForm;
  Nested: TLabel;
  Pack: TRuntimeLanguagePack;
begin
  Form := BuildForm(Nested);
  try
    Pack := TestPack;
    try
      TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmStyled', True);
    finally
      Pack.Free;
    end;

    { ResultingTextSettings, not TextSettings.

      TextSettings reports what was assigned. StyledSettings governs
      what is actually drawn: while a setting stays in it, the style
      supplies the value and the assignment is kept but never used. So
      reading TextSettings answers 'yes, I set that' no matter what the
      user will see - which is precisely the failure this program exists
      to catch, and the first version of it read TextSettings and
      therefore passed with the applicator's style handling deleted.
      ResultingTextSettings is the merged answer: style plus own
      settings, resolved the way the control will render. }
    Writeln(Format('        %-22s font %.0f, wrap %s, width %.0f, autosize %s',
      [AStyleName, Nested.ResultingTextSettings.Font.Size,
       BoolToStr(Nested.ResultingTextSettings.WordWrap, True),
       Nested.Size.Width, BoolToStr(Nested.AutoSize, True)]));

    Check(Nested.Text <> 'Short caption',
      AStyleName + ': the nested label was found and translated at all.');
    Check(SameValue(Nested.ResultingTextSettings.Font.Size, 17, 0.01),
      AStyleName + ': the font size took, rather than the style''s.');
    Check(Nested.ResultingTextSettings.WordWrap,
      AStyleName + ': wrapping took, rather than the style''s.');
    Check(not Nested.AutoSize,
      AStyleName + ': it stopped sizing itself.');
    Check(SameValue(Nested.Size.Width, 260, 1),
      AStyleName + ': and it is the width the rule gave it.');
  finally
    Form.Free;
  end;
end;

function StyleDirectory: string;
const
  Roots: array [0 .. 1] of string = (
    'C:\Program Files (x86)\Embarcadero\Studio\37.0\Redist\styles\Fmx',
    'C:\Program Files\Embarcadero\Studio\37.0\Redist\styles\Fmx');
var
  Root: string;
begin
  for Root in Roots do
    if TDirectory.Exists(Root) then
      Exit(Root);
  Result := '';
end;

var
  Directory_: string;
  StyleFiles: TArray<string>;
  StyleFile: string;
begin
  try
    Application.Initialize;

    Writeln;
    Writeln('=== the default style, and a control two levels down ===');
    { Worth its own pass. FindComponent is owner-based, so a control nested
      inside a panel inside a layout is still found - but that is a fact about
      ownership rather than about parenthood, and it is worth holding in place
      because the obvious implementation of a control lookup walks children. }
    CheckUnderCurrentStyle('default');

    Directory_ := StyleDirectory;
    if Directory_ = '' then
    begin
      Writeln;
      Writeln('No platform styles are installed on this machine, so the ' +
        'styled checks cannot run.');
      Writeln('They are the point of this program, so this is not a pass.');
      Halt(2);
    end;

    StyleFiles := TDirectory.GetFiles(Directory_, '*.style');
    if Length(StyleFiles) = 0 then
    begin
      Writeln;
      Writeln('No .style files found in ' + Directory_);
      Halt(2);
    end;

    Writeln;
    Writeln(Format('=== under each of %d installed platform styles ===',
      [Length(StyleFiles)]));
    for StyleFile in StyleFiles do
    begin
      TStyleManager.SetStyleFromFile(StyleFile);
      CheckUnderCurrentStyle(TPath.GetFileNameWithoutExtension(StyleFile));
    end;

    Writeln;
    if Failures = 0 then
    begin
      Writeln('FMX styled runtime smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('FMX styled runtime smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
