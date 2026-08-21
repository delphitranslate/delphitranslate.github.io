program FMXDiscoverySmokeTests;

{ Does a FireMonkey form built after the language was chosen get translated?

  The VCL twin of this test exists because every other VCL test hands a form
  straight to the applicator, so a broken discovery path could sit there for
  the life of the project while the suite stayed green. The same was true on
  this side, and for a while the same gap was too: the FireMonkey manager has
  a discovery path of its own and nothing exercised it.

  The two frameworks find their forms by completely different means, which is
  the reason a twin is worth having rather than a shared test. The VCL manager
  watches Screen and hooks the window procedure. FireMonkey has no such thing:
  it publishes TFormBeforeShownMessage through TMessageManager, and the
  manager subscribes to that and to TFormReleasedMessage. Those are different
  enough mechanisms that one working says nothing at all about the other.

  So the questions are the ones an application actually asks. A form that did
  not exist when the language was chosen: is it translated when it is shown?
  A form shown modally, which on FireMonkey runs its own loop: is that one
  translated too? And when the source language is chosen again, does every
  word come back? }

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Types,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.FMX in '..\..\source\components\DAT.Components.FMX.pas';

type
  { A modal form blocks, so the only way to read it while it is up is from
    something running inside its own loop. }
  TModalProbe = class
  public
    TitleSeen: string;
    CaptionSeen: string;
    Dialog: TForm;
    Probe: TLabel;
    procedure Tick(Sender: TObject);
  end;

procedure TModalProbe.Tick(Sender: TObject);
begin
  (Sender as TTimer).Enabled := False;
  CaptionSeen := Dialog.Caption;
  TitleSeen := Probe.Text;
  Dialog.ModalResult := 1;
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
  { The discovery hooks run on ordinary message traffic, so the test has to
    let some happen rather than assuming it. }
  for Index := 1 to ATimes do
  begin
    Application.ProcessMessages;
    Sleep(20);
  end;
end;

{ A pack of the shape the exporter writes, for one language. }
procedure WritePack(const AFolder, ALanguageCode, ANativeName,
  AHostCaption, ADetailsCaption, ADetailsTitle: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":3,"applicationId":"FMXDiscoveryTest",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"discovery",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".",' +
    '"currencySymbol":"EUR"},' +
    '"strings":{"frmFMXDiscoveryHost.Caption":"' + AHostCaption + '",' +
    '"frmFMXDiscoveryDetails.Caption":"' + ADetailsCaption + '",' +
    '"frmFMXDiscoveryDetails.lblDetailsTitle.Text":"' +
    ADetailsTitle + '"},' +
    '"sources":{"frmFMXDiscoveryHost.Caption":"Host",' +
    '"frmFMXDiscoveryDetails.Caption":"Schedule details",' +
    '"frmFMXDiscoveryDetails.lblDetailsTitle.Text":"Schedule details"}}';
  TFile.WriteAllText(TPath.Combine(AFolder, ALanguageCode + '.json'),
    JsonText, TEncoding.UTF8);
end;

{ A details form built the way an application builds one: on demand, after the
  language has already been chosen. }
function NewDetailsForm(const AOwner: TComponent;
  out ATitle: TLabel): TForm;
begin
  Result := TForm.CreateNew(AOwner);
  Result.Name := 'frmFMXDiscoveryDetails';
  Result.Caption := 'Schedule details';
  ATitle := TLabel.Create(Result);
  ATitle.Parent := Result;
  ATitle.Name := 'lblDetailsTitle';
  ATitle.Position.X := 20;
  ATitle.Position.Y := 20;
  ATitle.Size.Width := 300;
  ATitle.Size.Height := 24;
  ATitle.Text := 'Schedule details';
end;

var
  Folder: string;
  HostForm: TForm;
  Manager: TDATFMXLanguageManager;
  Dialog: TForm;
  DialogTitle: TLabel;
  ModalDialog: TForm;
  ModalTitle: TLabel;
  Probe: TModalProbe;
  ProbeTimer: TTimer;
begin
  try
    Folder := TPath.Combine(TPath.GetTempPath, 'dat-fmx-discovery');
    TDirectory.CreateDirectory(Folder);
    WritePack(Folder, 'en-US', 'English', 'Host', 'Schedule details',
      'Schedule details');
    WritePack(Folder, 'es-ES', 'Espanol', 'Anfitrion',
      'Detalles del horario', 'Detalles del horario');
    Writeln('Language packs: ', Folder);

    Application.Initialize;
    HostForm := TForm.CreateNew(nil);
    HostForm.Name := 'frmFMXDiscoveryHost';
    HostForm.Caption := 'Host';

    Manager := TDATFMXLanguageManager.Create(HostForm);
    Manager.ApplicationId := 'FMXDiscoveryTest';
    Manager.LanguagesFolder := Folder;
    Manager.SourceLanguage := 'en-US';
    Check(Manager.Initialize,
      'The manager initialised against the pack folder.');
    Check(Manager.SelectLanguage('es-ES'), 'Spanish was selected.');
    HostForm.Show;
    Pump(5);
    Check(HostForm.Caption = 'Anfitrion',
      'The form that was already open is translated: "' +
      HostForm.Caption + '".');

    { From here on this is what an application does when a button is pressed:
      the language is already chosen, and the form does not exist yet. }
    Dialog := NewDetailsForm(HostForm, DialogTitle);
    Check(Dialog.Caption = 'Schedule details',
      'The dialog starts in the source language.');

    Dialog.Show;
    Pump(15);

    Check(Dialog.Caption = 'Detalles del horario',
      'A form built after the language was chosen is translated when shown: "' +
      Dialog.Caption + '".');
    Check(DialogTitle.Text = 'Detalles del horario',
      'Its controls are translated too: "' + DialogTitle.Text + '".');

    Dialog.Free;
    Pump(3);

    { The same thing again, opened the way an application actually opens a
      dialog. ShowModal runs its own loop, and whether the subscription reaches
      a form inside that loop is the question this asks. }
    Probe := TModalProbe.Create;
    try
      ModalDialog := NewDetailsForm(HostForm, ModalTitle);
      Probe.Dialog := ModalDialog;
      Probe.Probe := ModalTitle;
      ProbeTimer := TTimer.Create(ModalDialog);
      ProbeTimer.Interval := 400;
      ProbeTimer.OnTimer := Probe.Tick;
      ModalDialog.ShowModal;
      Check(Probe.CaptionSeen = 'Detalles del horario',
        'A form shown modally is translated: saw "' +
        Probe.CaptionSeen + '".');
      Check(Probe.TitleSeen = 'Detalles del horario',
        'and so are its controls: saw "' + Probe.TitleSeen + '".');
      ModalDialog.Free;
    finally
      Probe.Free;
    end;
    Pump(3);

    { Going home again. Choosing the source language has to put every word
      back, or each switch leaves a little of the last language behind. }
    Check(Manager.SelectLanguage('en-US'), 'English was selected again.');
    Pump(5);
    Check(HostForm.Caption = 'Host',
      'The caption came back: "' + HostForm.Caption + '".');

    { And a form built after the return is in the source language, rather than
      carrying the last pack that happened to be loaded. }
    Dialog := NewDetailsForm(HostForm, DialogTitle);
    Dialog.Show;
    Pump(10);
    Check(Dialog.Caption = 'Schedule details',
      'A form built after the return home is not translated: "' +
      Dialog.Caption + '".');
    Dialog.Free;
    Pump(3);

    HostForm.Free;

    if Failures = 0 then
    begin
      Writeln('FMX discovery smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('FMX discovery smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
