program FMXLanguageManagerTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  FMX.Forms,
  FMX.Types,
  DAT.LifecycleSpike.Trace in 'lifecycle\DAT.LifecycleSpike.Trace.pas',
  FMXLifecycle.Form in 'lifecycle\FMXLifecycle.Form.pas'
    {frmFMXLifecycle},
  FMXLifecycle.InheritedForm in 'lifecycle\FMXLifecycle.InheritedForm.pas'
    {frmFMXInheritedLifecycle},
  SampleFMX.MainForm in '..\..\samples\FMXBasic\SampleFMX.MainForm.pas'
    {frmFMXSample},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.FMX in '..\..\source\components\DAT.Components.FMX.pas';

type
  TFMXManagerTest = class
  private
    FManager: TDATFMXLanguageManager;
    FMainForm: TfrmFMXLifecycle;
    FRunError: string;
    FShowWasGerman: Boolean;
    FPaintWasGerman: Boolean;
    procedure PumpMessages;
    procedure RequireGerman(const AForm: TfrmFMXLifecycle;
      const AContext: string);
    procedure RequireEnglish(const AForm: TfrmFMXLifecycle;
      const AContext: string);
  public
    procedure Configure(const AManager: TDATFMXLanguageManager;
      const AMainForm: TfrmFMXLifecycle);
    procedure Execute(Sender: TObject);
    procedure FormLifecycle(const AFramework, AFormName, AStage,
      ACaption, AProbeText: string);
    property RunError: string read FRunError;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure WritePack(const AFileName, ALanguageCode, ANativeName,
  ACaption, AProbeText, AInheritedCaption,
  AInheritedProbeText, ASampleCaption, ADateItem0, ADateItem1,
  ADateItem2, ADateItem3, ADateItem4: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":1,"applicationId":"FMXManagerTest",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"phase3",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy",' +
    '"longDateFormat":"","shortTimeFormat":"HH:mm",' +
    '"longTimeFormat":"HH:mm:ss","decimalSeparator":",",' +
    '"thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmFMXLifecycle.Caption":"' + ACaption + '",' +
    '"frmFMXLifecycle.lblProbe.Text":"' + AProbeText + '",' +
    '"frmFMXInheritedLifecycle.Caption":"' + AInheritedCaption + '",' +
    '"frmFMXInheritedLifecycle.lblProbe.Text":"' +
    AInheritedProbeText + '","frmFMXSample.Caption":"' +
    ASampleCaption + '","frmFMXSample.cmbDateRange.Items.Strings.0":"' +
    ADateItem0 + '","frmFMXSample.cmbDateRange.Items.Strings.1":"' +
    ADateItem1 + '","frmFMXSample.cmbDateRange.Items.Strings.2":"' +
    ADateItem2 + '","frmFMXSample.cmbDateRange.Items.Strings.3":"' +
    ADateItem3 + '","frmFMXSample.cmbDateRange.Items.Strings.4":"' +
    ADateItem4 + '"}}';
  TFile.WriteAllText(AFileName, JsonText, TEncoding.UTF8);
end;

procedure TFMXManagerTest.Configure(
  const AManager: TDATFMXLanguageManager;
  const AMainForm: TfrmFMXLifecycle);
begin
  FManager := AManager;
  FMainForm := AMainForm;
  FRunError := '';
end;

procedure TFMXManagerTest.Execute(Sender: TObject);
var
  DuplicateForm: TfrmFMXLifecycle;
  ExplicitForm: TfrmFMXLifecycle;
  InheritedForm: TfrmFMXInheritedLifecycle;
  PopupForm: TfrmFMXLifecycle;
  StateForm: TfrmFMXSample;
begin
  TTimer(Sender).Enabled := False;
  DuplicateForm := nil;
  ExplicitForm := nil;
  InheritedForm := nil;
  PopupForm := nil;
  StateForm := nil;
  try
    if FMainForm = nil then
      FMainForm := TfrmFMXLifecycle(Application.MainForm);
    RequireGerman(FMainForm, 'Auto-created form');
    Require(FShowWasGerman,
      'The auto-created form OnShow did not observe German text.');
    Require(FPaintWasGerman,
      'The auto-created form first paint did not observe German text.');

    DuplicateForm := TfrmFMXLifecycle.Create(nil);
    DuplicateForm.Show;
    PumpMessages;
    Require(Pos('_', DuplicateForm.Name) > 0,
      'Delphi did not assign a duplicate-instance name for the probe.');
    RequireGerman(DuplicateForm,
      'Duplicate instance with scanner-backed stable identity');

    InheritedForm := TfrmFMXInheritedLifecycle.Create(nil);
    InheritedForm.Show;
    PumpMessages;
    Require(Pos('Deutsch', InheritedForm.Caption) > 0,
      'Inherited form was not translated before display.');

    PopupForm := TfrmFMXLifecycle.Create(nil);
    PopupForm.FormStyle := TFormStyle.Popup;
    PopupForm.Show;
    PumpMessages;
    RequireGerman(PopupForm, 'Popup-style form');

    StateForm := TfrmFMXSample.Create(nil);
    StateForm.Show;
    PumpMessages;
    Require(StateForm.Caption = 'Deutsch sample',
      'State-preservation form did not translate before display.');
    Require((StateForm.cmbDateRange.ItemIndex = 2) and
      (StateForm.cmbDateRange.Selected.Text = 'Letzte 28 Tage'),
      'The selected FMX combo-box item was not preserved and translated.');

    Require(FManager.SelectLanguage('en-US'),
      'Instant English selection failed.');
    RequireEnglish(FMainForm, 'Visible main form after instant selection');
    RequireEnglish(DuplicateForm,
      'Visible duplicate form after instant selection');
    Require(Pos('English', InheritedForm.Caption) > 0,
      'Visible inherited form did not change immediately to English.');
    Require((StateForm.cmbDateRange.ItemIndex = 2) and
      (StateForm.cmbDateRange.Selected.Text = 'Last 28 days'),
      'Instant language selection did not preserve combo-box state.');

    DuplicateForm.Hide;
    Require(FManager.SelectLanguage('de-DE'),
      'Second German selection failed.');
    RequireGerman(FMainForm, 'Visible main form after German reselection');
    RequireEnglish(DuplicateForm,
      'Hidden form should remain in its prior generation');
    DuplicateForm.Show;
    PumpMessages;
    RequireGerman(DuplicateForm,
      'Hidden form did not update at its next before-show notification');

    FManager.AutoTranslateNewForms := False;
    ExplicitForm := TfrmFMXLifecycle.Create(nil);
    ExplicitForm.Show;
    PumpMessages;
    Require(SameText(ExplicitForm.Caption, 'FMX Lifecycle Source') and
      SameText(ExplicitForm.lblProbe.Text, 'FMX source text'),
      'AutoTranslateNewForms=False should leave designer text unchanged.');
    Require(FManager.ApplyToForm(ExplicitForm) > 0,
      'Explicit FMX form application reported no translated properties.');
    RequireGerman(ExplicitForm, 'Explicitly applied form');
    FManager.AutoTranslateNewForms := True;

    Require(FManager.Generation >= 3,
      'Language generations did not advance across selections.');
    Writeln('FMX_MANAGER_BEFORE_SHOW=PASS');
    Writeln('FMX_MANAGER_STABLE_IDENTITY=PASS');
    Writeln('FMX_MANAGER_INSTANT_SWITCH=PASS');
    Writeln('FMX_MANAGER_HIDDEN_FORM_POLICY=PASS');
    Writeln('FMX_MANAGER_CONTROL_STATE=PASS');
    Writeln('FMX_MANAGER_EXPLICIT_APPLY=PASS');
  except
    on E: Exception do
      FRunError := E.ClassName + ': ' + E.Message;
  end;
  ExplicitForm.Free;
  StateForm.Free;
  PopupForm.Free;
  InheritedForm.Free;
  DuplicateForm.Free;
  Application.Terminate;
end;

procedure TFMXManagerTest.FormLifecycle(const AFramework, AFormName,
  AStage, ACaption, AProbeText: string);
begin
  if (AStage = 'show') and not FShowWasGerman then
    FShowWasGerman := (Pos('Deutsch', ACaption) > 0) and
      (Pos('Deutsch', AProbeText) > 0);
  if (AStage = 'paint') and not FPaintWasGerman then
    FPaintWasGerman := (Pos('Deutsch', ACaption) > 0) and
      (Pos('Deutsch', AProbeText) > 0);
end;

procedure TFMXManagerTest.PumpMessages;
var
  PumpIndex: Integer;
begin
  for PumpIndex := 1 to 12 do
  begin
    Application.ProcessMessages;
    Sleep(5);
  end;
end;

procedure TFMXManagerTest.RequireEnglish(const AForm: TfrmFMXLifecycle;
  const AContext: string);
begin
  Require(Pos('English', AForm.Caption) > 0,
    AContext + ': caption is not English: ' + AForm.Caption);
  Require(Pos('English', AForm.lblProbe.Text) > 0,
    AContext + ': label is not English: ' + AForm.lblProbe.Text);
end;

procedure TFMXManagerTest.RequireGerman(const AForm: TfrmFMXLifecycle;
  const AContext: string);
begin
  Require(Pos('Deutsch', AForm.Caption) > 0,
    AContext + ': caption is not German: ' + AForm.Caption);
  Require(Pos('Deutsch', AForm.lblProbe.Text) > 0,
    AContext + ': label is not German: ' + AForm.lblProbe.Text);
end;

var
  LanguagesDirectory: string;
  MainForm: TfrmFMXLifecycle;
  Manager: TDATFMXLanguageManager;
  PreferenceDirectory: string;
  RootDirectory: string;
  RunTimer: TTimer;
  Test: TFMXManagerTest;
begin
  RootDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT_FMX_Manager_' + IntToStr(GetTickCount64));
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

  Test := TFMXManagerTest.Create;
  Manager := TDATFMXLanguageManager.Create(nil);
  try
    SetLifecycleTraceEvent(Test.FormLifecycle);
    Application.Initialize;
    Manager.ApplicationId := 'FMXManagerTest';
    Manager.LanguagesFolder := LanguagesDirectory;
    Manager.SourceLanguage := 'en-US';
    Manager.AutoLoadPreferred := False;
    Manager.PreferenceLocation := plCustomFolder;
    Manager.CustomPreferenceFolder := PreferenceDirectory;
    Manager.RegisterFormIdentity('TfrmFMXLifecycle', 'frmFMXLifecycle');
    Manager.RegisterFormIdentity('TfrmFMXInheritedLifecycle',
      'frmFMXInheritedLifecycle');
    Manager.RegisterFormIdentity('TfrmFMXSample', 'frmFMXSample');
    Require(Manager.Initialize, 'FMX manager initialization failed.');
    Require(Manager.SelectLanguage('de-DE'),
      'Initial German selection failed.');

    MainForm := nil;
    Application.CreateForm(TfrmFMXLifecycle, MainForm);
    Test.Configure(Manager, MainForm);
    RunTimer := TTimer.Create(nil);
    try
      RunTimer.Enabled := False;
      RunTimer.Interval := 100;
      RunTimer.OnTimer := Test.Execute;
      RunTimer.Enabled := True;
      Application.Run;
    finally
      RunTimer.Free;
    end;
    Require(Test.RunError = '', Test.RunError);
    MainForm.Free;
    Require(Manager.TrackedObjectCount = 0,
      'Released FMX forms remained in the manager tracking table.');
    Writeln('FMX_MANAGER_DETERMINISTIC_RELEASE=PASS');
    Writeln('FMX_LANGUAGE_MANAGER_TESTS=PASS');
  except
    on E: Exception do
    begin
      Writeln('FMX_LANGUAGE_MANAGER_TESTS=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  SetLifecycleTraceEvent(nil);
  Manager.Free;
  Test.Free;
  if TDirectory.Exists(RootDirectory) then
    TDirectory.Delete(RootDirectory, True);
end.
