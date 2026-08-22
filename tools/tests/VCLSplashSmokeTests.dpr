program VCLSplashSmokeTests;

{ A splash screen is the one form that is shown before anything else and then
  blocked on.

  It matters because it is the first thing a user sees, and because it breaks
  every assumption the rest of the runtime is built on. An ordinary form is
  found by the manager because it appears on Screen and because ordinary
  message traffic gives the discovery hooks something to run on. A splash is
  usually created, shown, and then sat on while the application loads: no idle
  loop, often no title bar, and frequently no other form in existence yet.

  So the question this answers is simply whether the applicator ever fires for
  such a form. The answer decides whether splash translation needs new
  machinery or none at all, and it was worth measuring rather than assuming,
  because both answers were plausible.

  Text drawn onto a splash with Canvas.TextOut is a separate matter and is
  deliberately not scanned - such calls carry data far more often than
  interface text. Text baked into the splash bitmap cannot be translated by
  anything: there is nothing to scan, and the target application's resources
  are read-only by standing rule. Neither is a defect in this path. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Graphics,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.VCL in '..\..\source\components\DAT.Components.VCL.pas';

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

procedure WritePack(const AFolder, ALanguageCode, ATitle, AStatus: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":3,"applicationId":"SplashTest",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"splash",' +
    '"language":{"code":"' + ALanguageCode +
    '","nativeName":"Test","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".",' +
    '"currencySymbol":"EUR"},' +
    '"strings":{"frmSplash.lblTitle.Caption":"' + ATitle + '",' +
    '"frmSplash.lblStatus.Caption":"' + AStatus + '"},' +
    '"sources":{"frmSplash.lblTitle.Caption":"Loading",' +
    '"frmSplash.lblStatus.Caption":"Please wait"}}';
  TFile.WriteAllText(TPath.Combine(AFolder, ALanguageCode + '.json'),
    JsonText, TEncoding.UTF8);
end;

{ A splash as an application actually builds one: no border, no title bar, not
  on the task bar, and nothing else alive yet. }
function NewSplashForm(out ATitle, AStatus: TLabel): TForm;
begin
  Result := TForm.CreateNew(nil);
  Result.Name := 'frmSplash';
  Result.BorderStyle := bsNone;
  Result.Position := poScreenCenter;
  Result.ClientWidth := 420;
  Result.ClientHeight := 220;

  ATitle := TLabel.Create(Result);
  ATitle.Parent := Result;
  ATitle.Name := 'lblTitle';
  ATitle.Left := 20;
  ATitle.Top := 140;
  ATitle.Caption := 'Loading';

  AStatus := TLabel.Create(Result);
  AStatus.Parent := Result;
  AStatus.Name := 'lblStatus';
  AStatus.Left := 20;
  AStatus.Top := 170;
  AStatus.Caption := 'Please wait';
end;

var
  Folder: string;
  Splash: TForm;
  Title, Status: TLabel;
  Manager: TDATVCLLanguageManager;
begin
  try
    Folder := TPath.Combine(TPath.GetTempPath, 'dat-splash-test');
    TDirectory.CreateDirectory(Folder);
    WritePack(Folder, 'en-US', 'Loading', 'Please wait');
    WritePack(Folder, 'de-DE', 'Wird geladen', 'Bitte warten');

    Application.Initialize;

    Writeln;
    Writeln('=== the first form of all, before anything else exists ===');
    Splash := NewSplashForm(Title, Status);
    try
      { The manager belongs to the splash itself, which is the whole point:
        there is no main form yet to hang it on. }
      Manager := TDATVCLLanguageManager.Create(Splash);
      Manager.ApplicationId := 'SplashTest';
      Manager.LanguagesFolder := Folder;
      Manager.SourceLanguage := 'en-US';

      Check(Splash.Owner = nil, 'The splash owns itself and nothing owns it.');
      Check(Manager.Owner = Splash, 'The manager is owned by the splash.');
      Check(Title.Caption = 'Loading', 'It starts in the source language.');

      Check(Manager.Initialize, 'The manager initialises with no main form.');
      Check(Manager.SelectLanguage('de-DE'), 'A language can be selected.');

      { No Show, no message loop, no idle: exactly the situation a splash is
        in while the application loads behind it. }
      Writeln('        title  : ', Title.Caption);
      Writeln('        status : ', Status.Caption);
      Check(Title.Caption = 'Wird geladen',
        'The splash is translated without a message loop ever running - ' +
        'AutoTranslateOwner reaches it at Initialize.');
      Check(Status.Caption = 'Bitte warten',
        'and so is every control on it.');

      Writeln;
      Writeln('=== and it is shown, still translated ===');
      Splash.Show;
      Application.ProcessMessages;
      Check(Title.Caption = 'Wird geladen',
        'Showing it does not undo the translation.');
      Splash.Hide;

      Writeln;
      Writeln('=== going home ===');
      Check(Manager.SelectLanguage('en-US'), 'The source language is chosen.');
      Check(Title.Caption = 'Loading',
        'and the words come back: ' + Title.Caption);
    finally
      Splash.Free;
    end;

    Writeln;
    Writeln('=== a splash that opts out is left alone ===');
    Splash := NewSplashForm(Title, Status);
    try
      Manager := TDATVCLLanguageManager.Create(Splash);
      Manager.ApplicationId := 'SplashTest';
      Manager.LanguagesFolder := Folder;
      Manager.SourceLanguage := 'en-US';
      { A splash whose words sit over artwork wants its geometry frozen, and
        an application says so by turning this off. }
      Manager.AutoTranslateOwner := False;
      Check(Manager.Initialize, 'It still initialises.');
      Check(Manager.SelectLanguage('de-DE'), 'and selects a language.');
      Check(Title.Caption = 'Loading',
        'but nothing on the splash was touched, which is what was asked for.');
    finally
      Splash.Free;
    end;

    Writeln;
    if Failures = 0 then
    begin
      Writeln('VCL splash smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('VCL splash smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
