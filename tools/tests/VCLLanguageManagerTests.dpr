program VCLLanguageManagerTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  Vcl.AppEvnts,
  Vcl.Forms,
  DAT.LifecycleSpike.Trace in 'lifecycle\DAT.LifecycleSpike.Trace.pas',
  VCLLifecycle.Form in 'lifecycle\VCLLifecycle.Form.pas'
    {frmVCLLifecycle},
  VCLLifecycle.InheritedForm in 'lifecycle\VCLLifecycle.InheritedForm.pas'
    {frmVCLInheritedLifecycle},
  SampleVCL.MainForm in '..\..\samples\VCLBasic\SampleVCL.MainForm.pas'
    {frmVCLSample},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.VCL in '..\..\source\components\DAT.Components.VCL.pas';

type
  TVCLManagerObserver = class
  private
    FCoexistingIdleCount: Integer;
    FModelessShowWasSource: Boolean;
    FModalProbeActive: Boolean;
    FModalShowWasGerman: Boolean;
    FControlChangeCount: Integer;
  public
    procedure CoexistingIdle(Sender: TObject; var Done: Boolean);
    procedure FormLifecycle(const AFramework, AFormName, AStage,
      ACaption, AProbeText: string);
    procedure ControlChanged(Sender: TObject);
    property CoexistingIdleCount: Integer read FCoexistingIdleCount;
    property ControlChangeCount: Integer read FControlChangeCount;
    property ModalProbeActive: Boolean read FModalProbeActive
      write FModalProbeActive;
    property ModalShowWasGerman: Boolean read FModalShowWasGerman;
    property ModelessShowWasSource: Boolean read FModelessShowWasSource;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure WritePack(const AFileName, ALanguageCode, ANativeName,
  ACaption, AProbeText, AInheritedCaption, AInheritedProbeText,
  ASampleCaption, ADateItem0, ADateItem1, ADateItem2, ADateItem3,
  ADateItem4: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":1,"applicationId":"VCLManagerTest",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"phase4",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy",' +
    '"longDateFormat":"","shortTimeFormat":"HH:mm",' +
    '"longTimeFormat":"HH:mm:ss","decimalSeparator":",",' +
    '"thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmVCLLifecycle.Caption":"' + ACaption + '",' +
    '"frmVCLLifecycle.lblProbe.Caption":"' + AProbeText + '",' +
    '"frmVCLInheritedLifecycle.Caption":"' + AInheritedCaption + '",' +
    '"frmVCLInheritedLifecycle.lblProbe.Caption":"' +
    AInheritedProbeText + '","frmVCLSample.Caption":"' +
    ASampleCaption + '","frmVCLSample.cmbDateRange.Items.Strings.0":"' +
    ADateItem0 + '","frmVCLSample.cmbDateRange.Items.Strings.1":"' +
    ADateItem1 + '","frmVCLSample.cmbDateRange.Items.Strings.2":"' +
    ADateItem2 + '","frmVCLSample.cmbDateRange.Items.Strings.3":"' +
    ADateItem3 + '","frmVCLSample.cmbDateRange.Items.Strings.4":"' +
    ADateItem4 + '","frmVCLSample.memInstructions.Lines.Strings.0":' +
    '"Translated memo line 1",' +
    '"frmVCLSample.memInstructions.Lines.Strings.1":' +
    '"Translated memo line 2"},' +
    '"sourceStrings":{"VCL Lifecycle Source":"' + ACaption + '",' +
    '"VCL source text":"' + AProbeText + '"},' +
    '"sources":{"frmVCLLifecycle.Caption":"VCL Lifecycle Source",' +
    '"frmVCLLifecycle.lblProbe.Caption":"VCL source text",' +
    '"frmVCLInheritedLifecycle.Caption":"VCL Inherited Source",' +
    '"frmVCLInheritedLifecycle.lblProbe.Caption":' +
    '"VCL source text",' +
    '"frmVCLSample.Caption":"Customer Manager",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.0":"Today",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.1":"Last 7 days",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.2":"Last 28 days",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.3":"Last 90 days",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.4":"This year",' +
    '"frmVCLSample.memInstructions.Lines.Strings.0":' +
    '"Enter the customer information, then choose Save Customer.",' +
    '"frmVCLSample.memInstructions.Lines.Strings.1":' +
    '"Fields marked as required must be completed."}}';
  TFile.WriteAllText(AFileName, JsonText, TEncoding.UTF8);
end;

procedure PumpToIdle;
var
  PumpIndex: Integer;
begin
  for PumpIndex := 1 to 3 do
  begin
    Application.ProcessMessages;
    Application.DoApplicationIdle;
  end;
  Application.ProcessMessages;
end;

procedure RequireGerman(const AForm: TfrmVCLLifecycle;
  const AContext: string);
begin
  Require(Pos('Deutsch', AForm.Caption) > 0,
    AContext + ': caption is not German: ' + AForm.Caption);
  Require(Pos('Deutsch', AForm.lblProbe.Caption) > 0,
    AContext + ': label is not German: ' + AForm.lblProbe.Caption);
end;

procedure RequireEnglish(const AForm: TfrmVCLLifecycle;
  const AContext: string);
begin
  Require(Pos('English', AForm.Caption) > 0,
    AContext + ': caption is not English: ' + AForm.Caption);
  Require(Pos('English', AForm.lblProbe.Caption) > 0,
    AContext + ': label is not English: ' + AForm.lblProbe.Caption);
end;

procedure TVCLManagerObserver.CoexistingIdle(Sender: TObject;
  var Done: Boolean);
begin
  Inc(FCoexistingIdleCount);
  Done := False;
end;

procedure TVCLManagerObserver.ControlChanged(Sender: TObject);
begin
  Inc(FControlChangeCount);
end;

procedure TVCLManagerObserver.FormLifecycle(const AFramework, AFormName,
  AStage, ACaption, AProbeText: string);
begin
  if AStage <> 'show' then
    Exit;
  if FModalProbeActive then
    FModalShowWasGerman := (Pos('Deutsch', ACaption) > 0) and
      (Pos('Deutsch', AProbeText) > 0)
  else if not FModelessShowWasSource then
    FModelessShowWasSource := SameText(ACaption, 'VCL Lifecycle Source') and
      SameText(AProbeText, 'VCL source text');
end;

var
  CoexistingEvents: TApplicationEvents;
  DuplicateForm: TfrmVCLLifecycle;
  ExplicitForm: TfrmVCLLifecycle;
  InheritedForm: TfrmVCLInheritedLifecycle;
  LanguagesDirectory: string;
  MainForm: TfrmVCLLifecycle;
  Manager: TDATVCLLanguageManager;
  ModalForm: TfrmVCLLifecycle;
  Observer: TVCLManagerObserver;
  PreferenceDirectory: string;
  RootDirectory: string;
  StateForm: TfrmVCLSample;
begin
  RootDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT_VCL_Manager_' + IntToStr(GetTickCount64));
  LanguagesDirectory := TPath.Combine(RootDirectory, 'Languages');
  PreferenceDirectory := TPath.Combine(RootDirectory, 'Preferences');
  TDirectory.CreateDirectory(LanguagesDirectory);
  TDirectory.CreateDirectory(PreferenceDirectory);
  WritePack(TPath.Combine(LanguagesDirectory, 'en-US.json'), 'en-US',
    'English', 'English caption', 'English probe',
    'English inherited caption', 'English inherited probe',
    'English sample', 'Today', 'Last 7 days', 'Last 28 days',
    'Last 90 days', 'This year');
  WritePack(TPath.Combine(LanguagesDirectory, 'de-DE.json'), 'de-DE',
    'Deutsch', 'Deutsch caption', 'Deutsch probe',
    'Deutsch inherited caption', 'Deutsch inherited probe',
    'Deutsch sample', 'Heute', 'Letzte 7 Tage', 'Letzte 28 Tage',
    'Letzte 90 Tage', 'Dieses Jahr');

  Observer := TVCLManagerObserver.Create;
  Manager := TDATVCLLanguageManager.Create(nil);
  CoexistingEvents := TApplicationEvents.Create(nil);
  try
    SetLifecycleTraceEvent(Observer.FormLifecycle);
    CoexistingEvents.OnIdle := Observer.CoexistingIdle;
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Manager.ApplicationId := 'VCLManagerTest';
    Manager.LanguagesFolder := LanguagesDirectory;
    Manager.SourceLanguage := 'en-US';
    Manager.AutoLoadPreferred := False;
    Manager.PreferenceLocation := plCustomFolder;
    Manager.CustomPreferenceFolder := PreferenceDirectory;
    Manager.IdleScanInterval := 0;
    Manager.RegisterFormIdentity('TfrmVCLLifecycle', 'frmVCLLifecycle');
    Manager.RegisterFormIdentity('TfrmVCLInheritedLifecycle',
      'frmVCLInheritedLifecycle');
    Manager.RegisterFormIdentity('TfrmVCLSample', 'frmVCLSample');
    Require(Manager.Initialize, 'VCL manager initialization failed.');
    Require(Manager.SelectLanguage('de-DE'),
      'Initial German selection failed.');

    MainForm := TfrmVCLLifecycle.Create(Application);
    MainForm.Show;
    PumpToIdle;
    Require(Observer.ModelessShowWasSource,
      'The documented VCL modeless first-display boundary changed.');
    RequireGerman(MainForm, 'Idle-discovered modeless form');

    DuplicateForm := TfrmVCLLifecycle.Create(nil);
    DuplicateForm.Show;
    PumpToIdle;
    Require(Pos('_', DuplicateForm.Name) > 0,
      'Delphi did not assign a duplicate-instance name for the VCL probe.');
    RequireGerman(DuplicateForm,
      'Duplicate VCL instance with stable scanner identity');

    InheritedForm := TfrmVCLInheritedLifecycle.Create(nil);
    InheritedForm.Show;
    PumpToIdle;
    Require(Pos('Deutsch', InheritedForm.Caption) > 0,
      'Inherited VCL form was not discovered and translated.');

    StateForm := TfrmVCLSample.Create(nil);
    StateForm.Show;
    PumpToIdle;
    Require((StateForm.Caption = 'Deutsch sample') and
      (StateForm.cmbDateRange.ItemIndex = 2) and
      (StateForm.cmbDateRange.Items[2] = 'Letzte 28 Tage'),
      'VCL combo-box selection was not preserved during discovery.');

    StateForm.edtCustomerName.Text := 'Alice Martin';
    StateForm.edtCustomerName.SelStart := 1;
    StateForm.edtCustomerName.SelLength := 4;
    StateForm.memInstructions.ReadOnly := False;
    StateForm.memInstructions.Lines.Text := 'Private user notes';
    StateForm.memInstructions.SelStart := 2;
    StateForm.memInstructions.SelLength := 5;
    StateForm.edtCustomerName.SetFocus;
    StateForm.edtCustomerName.OnChange := Observer.ControlChanged;
    StateForm.memInstructions.OnChange := Observer.ControlChanged;
    StateForm.cmbDateRange.OnChange := Observer.ControlChanged;

    ModalForm := TfrmVCLLifecycle.Create(nil);
    ModalForm.CloseModalAutomatically := True;
    Observer.ModalProbeActive := True;
    try
      ModalForm.ShowModal;
    finally
      Observer.ModalProbeActive := False;
    end;
    Require(Observer.ModalShowWasGerman,
      'OnModalBegin did not translate the modal form before OnShow.');

    Require(Manager.SelectLanguage('en-US'),
      'Instant VCL English selection failed.');
    RequireEnglish(MainForm, 'Visible VCL form after instant selection');
    RequireEnglish(DuplicateForm,
      'Visible VCL duplicate after instant selection');
    Require((StateForm.cmbDateRange.ItemIndex = 2) and
      (StateForm.cmbDateRange.Items[2] = 'Last 28 days'),
      Format('VCL instant selection did not preserve combo-box state: ' +
        'ItemIndex=%d, Item[2]=%s.', [StateForm.cmbDateRange.ItemIndex,
        StateForm.cmbDateRange.Items[2]]));
    Require((StateForm.edtCustomerName.Text = 'Alice Martin') and
      (StateForm.edtCustomerName.SelStart = 1) and
      (StateForm.edtCustomerName.SelLength = 4) and
      StateForm.edtCustomerName.Focused,
      'VCL editable text, selection, or focus was not preserved.');
    Require((Trim(StateForm.memInstructions.Lines.Text) =
      'Private user notes') and
      (StateForm.memInstructions.SelStart = 2) and
      (StateForm.memInstructions.SelLength = 5),
      'VCL writable memo content or selection was not preserved.');
    Require(Observer.ControlChangeCount = 0,
      'VCL localization fired a protected control OnChange event.');

    DuplicateForm.Hide;
    Require(Manager.SelectLanguage('de-DE'),
      'VCL German reselection failed.');
    Require(SameText(DuplicateForm.Caption, 'VCL Lifecycle Source') and
      SameText(DuplicateForm.lblProbe.Caption, 'VCL source text'),
      'Hidden VCL form did not return to its source baseline during the ' +
      'language transition.');
    DuplicateForm.Show;
    PumpToIdle;
    RequireGerman(DuplicateForm,
      'Hidden VCL form did not catch up at the next idle scan');

    Manager.AutoDiscoverForms := False;
    ExplicitForm := TfrmVCLLifecycle.Create(nil);
    Require(Manager.ApplyToForm(ExplicitForm) > 0,
      'Explicit pre-display VCL application reported no changes.');
    ExplicitForm.Show;
    Application.ProcessMessages;
    RequireGerman(ExplicitForm, 'Explicit pre-display VCL form');
    Manager.AutoDiscoverForms := True;

    Require(Observer.CoexistingIdleCount > 0,
      'A coexisting TApplicationEvents idle subscriber was not called.');
    Writeln('VCL_MANAGER_DISCOVERY=PASS');
    Writeln('VCL_MANAGER_MODELESS_FIRST_DISPLAY=DOCUMENTED_LIMITATION');
    Writeln('VCL_MANAGER_MODAL_BEFORE_SHOW=PASS');
    Writeln('VCL_MANAGER_STABLE_IDENTITY=PASS');
    Writeln('VCL_MANAGER_INSTANT_SWITCH=PASS');
    Writeln('VCL_MANAGER_CONTROL_STATE=PASS');
    Writeln('VCL_MANAGER_EDITABLE_DATA=PASS');
    Writeln('VCL_MANAGER_FOCUS_AND_SELECTION=PASS');
    Writeln('VCL_MANAGER_EVENT_SUPPRESSION=PASS');
    Writeln('VCL_MANAGER_COEXISTING_EVENTS=PASS');
    Writeln('VCL_MANAGER_EXPLICIT_PREDISPLAY=PASS');
  except
    on E: Exception do
    begin
      Writeln('VCL_LANGUAGE_MANAGER_TESTS=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  ExplicitForm.Free;
  ModalForm.Free;
  StateForm.Free;
  InheritedForm.Free;
  DuplicateForm.Free;
  MainForm.Free;
  Require(Manager.TrackedObjectCount = 0,
    'Released VCL forms remained in the manager tracking table.');
  Writeln('VCL_MANAGER_DETERMINISTIC_RELEASE=PASS');
  Writeln('VCL_LANGUAGE_MANAGER_TESTS=PASS');
  SetLifecycleTraceEvent(nil);
  CoexistingEvents.Free;
  Manager.Free;
  Observer.Free;
  if TDirectory.Exists(RootDirectory) then
    TDirectory.Delete(RootDirectory, True);
end.
