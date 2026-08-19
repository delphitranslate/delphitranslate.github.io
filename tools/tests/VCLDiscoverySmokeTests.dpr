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
    Dialog: TForm;
    procedure Tick(Sender: TObject);
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
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\..\samples\VCLTranslationTestApp\Win32\Debug\Localization\Languages'));
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
      Check(frmVCLTestMain.DATManager.SelectLanguage('es-ES'),
        'The real manager selected Spanish.');
      frmVCLTestMain.Show;
      Pump(5);
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
