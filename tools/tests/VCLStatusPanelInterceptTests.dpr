program VCLStatusPanelInterceptTests;

{ Item 8: a status bar panel the application overwrites in code stays
  translated. A collection item sends no WM_SETTEXT, so the caption
  interceptor cannot reach it; ApplyCollectionTextRules re-asserts the
  translation directly, and the form-owned timer keeps re-asserting it for
  the life of the form. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  Vcl.ComCtrls,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"StatusPanelTest",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{},' +
    '"templates":{"frmStatusTest.StatusBar1.Panels[0].Text":' +
    '"Zuletzt gespielt: "},' +
    '"sourceStrings":{},"sourceTemplates":{},' +
    '"sources":{"frmStatusTest.StatusBar1.Panels[0].Text":' +
    '"Last Song Played: "},' +
    '"proposals":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

function ArabicPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"StatusPanelTest",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"ar-SA","nativeName":"Arabic","direction":"rtl"},' +
    '"locale":{},"strings":{},' +
    '"templates":{"frmStatusTest.StatusBar1.Panels[0].Text":' +
    '"Arabic last played: "},' +
    '"sourceStrings":{},"sourceTemplates":{},' +
    '"sources":{"frmStatusTest.StatusBar1.Panels[0].Text":' +
    '"Last Song Played: "},"proposals":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Form: TForm;
  Bar: TStatusBar;
  NextPack: TRuntimeLanguagePack;
  Pack: TRuntimeLanguagePack;
begin
  ExitCode := 0;
  try
  Application.Initialize;
  Form := TForm.Create(nil);
  try
    Form.Name := 'frmStatusTest';
    Bar := TStatusBar.Create(Form);
    Bar.Parent := Form;
    Bar.Name := 'StatusBar1';
    Bar.Panels.Add;
    Bar.Panels[0].Text := 'Last Song Played: track.mp3';

    Pack := TestPack;
    try
      TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmStatusTest', False);
      Require(Bar.Panels[0].Text = 'Zuletzt gespielt: track.mp3',
        'The panel is translated on the first apply.');

      { The application sets its own text back, the way Carillon does after
        every song - in English, and naming whatever just played. }
      Bar.Panels[0].Text := 'Last Song Played: other.mp3';
      Require(Bar.Panels[0].Text <> 'Zuletzt gespielt: other.mp3',
        'Setup: the overwrite actually took effect.');

      TVCLTranslationApplicator.ApplyCollectionTextRules(Form,
        'frmStatusTest', Pack);
      Require(Bar.Panels[0].Text = 'Zuletzt gespielt: other.mp3',
        'A status panel the application overwrites is re-translated ' +
        'without waiting for the language to be reapplied from scratch, ' +
        'and the new song name it wrote survives translation.');

      { Switching translated language to translated language must pass through
        the source template. Otherwise the Arabic pack sees German, cannot
        match its English source, and the old language remains on screen. }
      TVCLTranslationApplicator.RestoreSourceLanguage(Form, Pack,
        'frmStatusTest');
      Require(Bar.Panels[0].Text = 'Last Song Played: other.mp3',
        'Leaving German restores the source prefix and keeps the filename.');
      NextPack := ArabicPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, NextPack,
          'frmStatusTest', False);
        Require(Bar.Panels[0].Text = 'Arabic last played: other.mp3',
          'The next translated language replaces the previous one immediately.');
      finally
        NextPack.Free;
      end;

      Writeln('VCL status panel intercept smoke test passed.');
    finally
      Pack.Free;
    end;
  finally
    Form.Free;
  end;
  except
    on E: Exception do
    begin
      Writeln('VCL status panel intercept smoke test failed: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
