program VCLDiscoverySmokeTests;

{ Does a form built after the language was chosen get translated?

  Every other VCL test hands a form straight to the applicator, which is why a
  broken discovery path could sit here for the life of the project while the
  suite stayed green. This one goes through the manager instead, and builds its
  second form the way an application does: after the language is already set,
  on demand, and then shown.

  It reuses the language pack the sample application deploys, so the form names
  and the expected Spanish are the real ones rather than something invented
  here that might agree with the code while disagreeing with the product. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  DAT.Components.VCL in '..\..\source\components\DAT.Components.VCL.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  TestMainForm in '..\..\samples\VCLTranslationTestApp\TestMainForm.pas' {frmVCLTestMain},
  TestDetailsForm in '..\..\samples\VCLTranslationTestApp\TestDetailsForm.pas' {frmVCLTestDetails};

type
  { A modal form blocks, so the only way to read it while it is up is from
    something running inside its own message loop. }
  TModalProbe = class
  public
    CaptionSeen: string;
    ActiveFormSeen: string;
    ActiveIsDialog: Boolean;
    FormCount: Integer;
    ErrorCount: Integer;
    Dialog: TForm;
    procedure Tick(Sender: TObject);
    procedure TranslationError(Sender: TObject; const AContext,
      AMessage: string; var AHandled: Boolean);
  end;

procedure TModalProbe.Tick(Sender: TObject);
begin
  (Sender as TTimer).Enabled := False;
  CaptionSeen := Dialog.Caption;
  FormCount := Screen.CustomFormCount;
  if Screen.ActiveCustomForm <> nil then
    ActiveFormSeen := Screen.ActiveCustomForm.Name + ' (' +
      Screen.ActiveCustomForm.ClassName + ')'
  else
    ActiveFormSeen := '<none>';
  ActiveIsDialog := Screen.ActiveCustomForm = Dialog;
  Dialog.ModalResult := mrOk;
end;

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

procedure Pump(const ATimes: Integer);
var
  Index: Integer;
begin
  { The discovery hooks run on ordinary message traffic, so the test has to let
    some happen rather than assuming it. }
  for Index := 1 to ATimes do
  begin
    Application.ProcessMessages;
    Sleep(20);
  end;
end;

function PackFolder: string;
begin
  if ParamCount >= 1 then
    Result := TPath.GetFullPath(ParamStr(1))
  else
    Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
      '..\..\..\samples\VCLTranslationTestApp\Win32\Debug\Localization\Languages'));
end;

procedure TModalProbe.TranslationError(Sender: TObject; const AContext,
  AMessage: string; var AHandled: Boolean);
begin
  Inc(ErrorCount);
  Writeln('        translation error : ', AContext, ' - ', AMessage);
  AHandled := True;
end;

var
  HostForm: TForm;
  Manager: TDATVCLLanguageManager;
  Dialog: TForm;
  DialogLabel: TLabel;
  Folder: string;
  ModalDialog: TForm;
  Probe: TModalProbe;
  ProbeTimer: TTimer;
  RealDetails: TfrmVCLTestDetails;
  RealProbe: TModalProbe;
  RealTimer: TTimer;
  LocalPacks: string;
  PackFile: string;
  OriginalWidth: Integer;
  OriginalColor: Integer;
  OriginalFont: Integer;
begin
  try
    Folder := PackFolder;
    Writeln('Language packs: ', Folder);
    if not TDirectory.Exists(Folder) then
    begin
      Writeln('The sample application has not been built, so there is no pack ' +
        'to read. Build samples\VCLTranslationTestApp first.');
      Halt(2);
    end;

    { The manager on a streamed form resolves a relative LanguagesFolder against
      this executable and seals its configuration as the form loads, so the
      packs have to be here before any form is created. }
    LocalPacks := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'Localization' + PathDelim + 'Languages');
    TDirectory.CreateDirectory(LocalPacks);
    for PackFile in TDirectory.GetFiles(Folder, '*.json') do
      TFile.Copy(PackFile, TPath.Combine(LocalPacks,
        TPath.GetFileName(PackFile)), True);

    Application.Initialize;
    Application.CreateForm(TForm, HostForm);
    HostForm.Name := 'frmVCLTestMain';
    HostForm.Caption := 'Host';

    Manager := TDATVCLLanguageManager.Create(HostForm);
    Manager.ApplicationId := 'VCLTranslationTestApp';
    Manager.LanguagesFolder := Folder;
    Manager.SourceLanguage := 'en-US';
    Check(Manager.Initialize, 'The manager initialised against the pack folder.');
    Check(Manager.SelectLanguage('es-ES'), 'Spanish was selected.');
    HostForm.Show;
    Pump(5);

    { From here on this is what an application does when a button is pressed:
      the language is already chosen, and the form does not exist yet. }
    Dialog := TForm.CreateNew(HostForm);
    Dialog.Name := 'frmVCLTestDetails';
    Dialog.Caption := 'Schedule details';
    DialogLabel := TLabel.Create(Dialog);
    DialogLabel.Parent := Dialog;
    DialogLabel.Name := 'lblDetailsTitle';
    DialogLabel.Caption := 'Schedule details';

    Check(Dialog.Caption = 'Schedule details',
      'The dialog starts in the source language.');

    Dialog.Show;
    Pump(15);

    Check(Dialog.Caption = 'Detalles del horario',
      'A form built after the language was chosen is translated when shown.');
    Check(DialogLabel.Caption = 'Detalles del horario',
      'Its controls are translated too.');

    Dialog.Free;

    { The same thing again, opened the way an application actually opens a
      dialog. ShowModal runs its own message loop, and whether the discovery
      hooks reach a form inside that loop is the question this asks. }
    Probe := TModalProbe.Create;
    try
      ModalDialog := TForm.CreateNew(HostForm);
      ModalDialog.Name := 'frmVCLTestDetails';
      ModalDialog.Caption := 'Schedule details';
      Probe.Dialog := ModalDialog;
      ProbeTimer := TTimer.Create(ModalDialog);
      ProbeTimer.Interval := 400;
      ProbeTimer.OnTimer := Probe.Tick;
      ModalDialog.ShowModal;
      Check(Probe.CaptionSeen = 'Detalles del horario',
        'A form shown modally is translated: saw "' + Probe.CaptionSeen + '".');
      ModalDialog.Free;
    finally
      Probe.Free;
    end;

    HostForm.Free;

    { The real forms now, streamed from their own .dfm files, with the manager
      that lives on the main form rather than one built here. This is the last
      difference between the harness and the application that shows the fault. }
    RealProbe := TModalProbe.Create;
    try
      { The manager on a streamed form initialises itself as the form loads,
        and its configuration is sealed from that moment, so the pack has to be
        beside this executable before the form is created rather than pointed
        at afterwards. }
      Application.CreateForm(TfrmVCLTestMain, frmVCLTestMain);
      { The project auto-creates a details form too, and the main form then
        ignores it and builds its own. Two live instances answer to the same
        name, which is the last thing separating this harness from the running
        application. }
      Application.CreateForm(TfrmVCLTestDetails, frmVCLTestDetails);
      Check(frmVCLTestMain.DATManager.Initialized,
        'The real manager initialised as its form loaded.');
      frmVCLTestMain.DATManager.OnTranslationError :=
        RealProbe.TranslationError;
      Check(frmVCLTestMain.DATManager.SelectLanguage('es-ES'),
        'The real manager selected Spanish.');
      frmVCLTestMain.Show;
      { VCL's nonexclusive discovery contract is the bounded idle scan. Give
        it one complete configured interval rather than treating a 100 ms
        message pump as though it were that lifecycle boundary. }
      Pump(60);
      Check(frmVCLTestMain.Caption = 'Aplicaci' + #243 + 'n de prueba de traducci' + #243 + 'n VCL',
        'The main form is translated: "' + frmVCLTestMain.Caption + '".');

      RealDetails := TfrmVCLTestDetails.Create(frmVCLTestMain);
      RealProbe.Dialog := RealDetails;
      RealTimer := TTimer.Create(RealDetails);
      RealTimer.Interval := 400;
      RealTimer.OnTimer := RealProbe.Tick;
      RealDetails.ShowModal;
      Writeln('        forms open        : ', RealProbe.FormCount);
      Writeln('        active form       : ', RealProbe.ActiveFormSeen);
      Writeln('        active is dialog  : ', BoolToStr(RealProbe.ActiveIsDialog, True));
      Check(RealProbe.CaptionSeen = 'Detalles del horario',
        'The real details form is translated: saw "' + RealProbe.CaptionSeen + '".');
      RealDetails.Free;

      { Going home again. A translation widens controls, shrinks fonts and
        recolours text; choosing the source language has to put every one of
        those back, or each switch leaves a little of the last language behind
        and the form drifts. }
      OriginalWidth := frmVCLTestMain.btnPlay.Width;
      OriginalColor := frmVCLTestMain.lblIntro.Font.Color;
      OriginalFont := frmVCLTestMain.lblIntro.Font.Size;
      Check(frmVCLTestMain.DATManager.SelectLanguage('en-US'),
        'English was selected again.');
      Pump(5);
      Check(frmVCLTestMain.Caption = 'VCL Translation Test Application',
        'The caption came back: "' + frmVCLTestMain.Caption + '".');
      Writeln(Format('        btnPlay width  : spanish %d -> english %d',
        [OriginalWidth, frmVCLTestMain.btnPlay.Width]));
      Writeln(Format('        lblIntro font  : spanish %d -> english %d',
        [OriginalFont, frmVCLTestMain.lblIntro.Font.Size]));
      Writeln(Format('        lblIntro colour: spanish %d -> english %d',
        [OriginalColor, frmVCLTestMain.lblIntro.Font.Color]));
      Check(frmVCLTestMain.btnPlay.Width = 80,
        Format('btnPlay is back to its designed width of 80, not %d.',
          [frmVCLTestMain.btnPlay.Width]));
      Check(frmVCLTestMain.lblIntro.Font.Size = 9,
        Format('lblIntro is back to its designed size of 9, not %d.',
          [frmVCLTestMain.lblIntro.Font.Size]));
      Check(frmVCLTestMain.lblIntro.Width = 560,
        Format('lblIntro is back to its designed width of 560, not %d.',
          [frmVCLTestMain.lblIntro.Width]));

      { And the case an application actually presents: a form is translated
        while it is open, the user closes it, the language is changed while it
        is not on screen, and it is opened again. A form that is not visible is
        not collected when the language changes, so nothing restores it; if
        applying a language does not start from the original geometry, the new
        language is laid on top of the old one and the widths of whichever
        language it was last opened in are kept for ever. }
      frmVCLTestMain.DATManager.SelectLanguage('es-ES');
      Pump(5);
      frmVCLTestMain.Hide;
      Pump(2);
      frmVCLTestMain.DATManager.SelectLanguage('en-US');
      Pump(2);
      frmVCLTestMain.Show;
      Pump(2);
      { What the idle scan does when the form comes back on screen. It is
        called here rather than waited for because ProcessMessages does not
        raise Application.OnIdle, so the scan never runs inside this harness. }
      frmVCLTestMain.DATManager.ApplyToForm(frmVCLTestMain);
      Pump(2);
      Check(frmVCLTestMain.btnPlay.Width = 80,
        Format('A form hidden across the change comes back at its designed ' +
          'width of 80, not %d.', [frmVCLTestMain.btnPlay.Width]));
      Check(frmVCLTestMain.lblIntro.Font.Size = 9,
        Format('and at its designed font size of 9, not %d.',
          [frmVCLTestMain.lblIntro.Font.Size]));
      Check(RealProbe.ErrorCount = 0,
        Format('No translation error was swallowed during real-form testing; ' +
          '%d error(s) were reported.', [RealProbe.ErrorCount]));

      frmVCLTestMain.Free;
    finally
      RealProbe.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL form discovery smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('VCL form discovery smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
