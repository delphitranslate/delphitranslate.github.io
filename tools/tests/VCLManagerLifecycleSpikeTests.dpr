program VCLManagerLifecycleSpikeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.AppEvnts,
  Vcl.Forms,
  DAT.LifecycleSpike.Trace in 'lifecycle\DAT.LifecycleSpike.Trace.pas',
  VCLLifecycle.Form in 'lifecycle\VCLLifecycle.Form.pas'
    {frmVCLLifecycle},
  VCLLifecycle.InheritedForm in 'lifecycle\VCLLifecycle.InheritedForm.pas'
    {frmVCLInheritedLifecycle},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.VCL.Spike in '..\..\source\components\DAT.Components.VCL.Spike.pas';

type
  TVCLLifecycleFormClass = class of TfrmVCLLifecycle;

  TVCLSpikeObserver = class
  private
    FScenario: string;
    FSequence: Integer;
    FAppliedSequence: Integer;
    FShowSequence: Integer;
    FPaintSequence: Integer;
    FActiveSignalSequence: Integer;
    FActiveSignalTranslated: Boolean;
    FShowTranslated: Boolean;
    FPaintTranslated: Boolean;
    FCoexistingIdleCount: Integer;
    FTrace: TStringList;
    function IsTranslated(const ACaption, AProbeText: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginScenario(const AScenario: string);
    procedure CoexistingIdle(Sender: TObject; var Done: Boolean);
    procedure FormLifecycle(const AFramework, AFormName, AStage,
      ACaption, AProbeText: string);
    procedure ManagerLifecycle(Sender: TObject;
      const AForm: TCustomForm; const AStage: string;
      const AAppliedPropertyCount: Integer);
    procedure ScreenActiveFormChanged(Sender: TObject);
    procedure VerifyScenario(const AForm: TfrmVCLLifecycle;
      const AManager: TDATVCLLanguageManagerSpike);
    procedure WriteScenario;
    property CoexistingIdleCount: Integer read FCoexistingIdleCount;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":1,"applicationId":"LifecycleSpikeVCL",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"spike",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmVCLLifecycle.Caption":"VCL translated caption",' +
    '"frmVCLLifecycle.lblProbe.Caption":"VCL translated probe",' +
    '"frmVCLInheritedLifecycle.Caption":"VCL inherited translated caption",' +
    '"frmVCLInheritedLifecycle.lblProbe.Caption":"VCL inherited translated probe"}}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

constructor TVCLSpikeObserver.Create;
begin
  inherited Create;
  FTrace := TStringList.Create;
end;

destructor TVCLSpikeObserver.Destroy;
begin
  FTrace.Free;
  inherited Destroy;
end;

procedure TVCLSpikeObserver.BeginScenario(const AScenario: string);
begin
  FScenario := AScenario;
  FSequence := 0;
  FAppliedSequence := 0;
  FShowSequence := 0;
  FPaintSequence := 0;
  FActiveSignalSequence := 0;
  FActiveSignalTranslated := False;
  FShowTranslated := False;
  FPaintTranslated := False;
  FTrace.Clear;
end;

procedure TVCLSpikeObserver.ScreenActiveFormChanged(Sender: TObject);
var
  Form: TCustomForm;
begin
  Inc(FSequence);
  Form := Screen.ActiveCustomForm;
  if Form <> nil then
  begin
    FTrace.Add(Format('%d|screen|active-form-change|%s|%s',
      [FSequence, Form.Name, Form.Caption]));
    if (FActiveSignalSequence = 0) and (Form.Name <> '') then
    begin
      FActiveSignalSequence := FSequence;
      if Form is TfrmVCLLifecycle then
        FActiveSignalTranslated := IsTranslated(Form.Caption,
          TfrmVCLLifecycle(Form).lblProbe.Caption);
    end;
  end;
end;

procedure TVCLSpikeObserver.CoexistingIdle(Sender: TObject; var Done: Boolean);
begin
  Inc(FCoexistingIdleCount);
end;

procedure TVCLSpikeObserver.FormLifecycle(const AFramework, AFormName,
  AStage, ACaption, AProbeText: string);
begin
  Inc(FSequence);
  FTrace.Add(Format('%d|form|%s|%s|%s',
    [FSequence, AStage, AFormName, AProbeText]));
  if (AStage = 'show') and (FShowSequence = 0) then
  begin
    FShowSequence := FSequence;
    FShowTranslated := IsTranslated(ACaption, AProbeText);
  end;
  if (AStage = 'paint') and (FPaintSequence = 0) then
  begin
    FPaintSequence := FSequence;
    FPaintTranslated := IsTranslated(ACaption, AProbeText);
  end;
end;

function TVCLSpikeObserver.IsTranslated(const ACaption,
  AProbeText: string): Boolean;
begin
  Result := (Pos('translated', LowerCase(ACaption)) > 0) and
    (Pos('translated', LowerCase(AProbeText)) > 0);
end;

procedure TVCLSpikeObserver.ManagerLifecycle(Sender: TObject;
  const AForm: TCustomForm; const AStage: string;
  const AAppliedPropertyCount: Integer);
var
  FormName: string;
begin
  Inc(FSequence);
  if AForm <> nil then
    FormName := AForm.Name
  else
    FormName := '-';
  FTrace.Add(Format('%d|manager|%s|%s|%d',
    [FSequence, AStage, FormName, AAppliedPropertyCount]));
  if (AStage = 'idle-applied') and (FAppliedSequence = 0) and
    (AForm <> nil) and (AForm.Name <> '') then
    FAppliedSequence := FSequence;
end;

procedure TVCLSpikeObserver.VerifyScenario(const AForm: TfrmVCLLifecycle;
  const AManager: TDATVCLLanguageManagerSpike);
begin
  Require(AManager.WasApplied(AForm),
    FScenario + ': idle manager did not discover the form.');
  Require(Pos('translated', LowerCase(AForm.Caption)) > 0,
    FScenario + ': final caption was not translated; form name=' +
    AForm.Name + '; caption=' + AForm.Caption + '.');
  Require(Pos('translated', LowerCase(AForm.lblProbe.Caption)) > 0,
    FScenario + ': final probe text was not translated.');
  Require(FShowSequence > 0,
    FScenario + ': form OnShow was not observed.');
  Require(FAppliedSequence > FShowSequence,
    FScenario + ': expected idle application after OnShow was not observed.');
  Require(not FShowTranslated,
    FScenario + ': lifecycle assumption changed; OnShow was unexpectedly translated.');
  Require(FPaintSequence > 0,
    FScenario + ': form paint was not observed.');
end;

procedure TVCLSpikeObserver.WriteScenario;
var
  TraceIndex: Integer;
begin
  Writeln('SCENARIO=', FScenario);
  for TraceIndex := 0 to FTrace.Count - 1 do
    Writeln(FTrace[TraceIndex]);
  Writeln('RESULT=DISCOVERED;SHOW_TRANSLATED=',
    BoolToStr(FShowTranslated, True), ';FIRST_PAINT_TRANSLATED=',
    BoolToStr(FPaintTranslated, True), ';ACTIVE_SIGNAL_BEFORE_PAINT=',
    BoolToStr((FActiveSignalSequence > 0) and
      (FActiveSignalSequence < FPaintSequence), True),
    ';ACTIVE_SIGNAL_TRANSLATED=', BoolToStr(FActiveSignalTranslated, True));
end;

procedure PumpToIdle;
var
  PumpIndex: Integer;
  WakeThread: TThread;
begin
  for PumpIndex := 1 to 3 do
  begin
    Application.ProcessMessages;
    WakeThread := TThread.CreateAnonymousThread(
      procedure
      begin
        Sleep(5);
        PostMessage(Application.Handle, WM_NULL, 0, 0);
      end);
    WakeThread.FreeOnTerminate := False;
    try
      WakeThread.Start;
      Application.HandleMessage;
      WakeThread.WaitFor;
    finally
      WakeThread.Free;
    end;
  end;
  Application.ProcessMessages;
end;

procedure RunModelessScenario(const AScenario: string;
  const AFormClass: TVCLLifecycleFormClass; const AOwner: TComponent;
  const AFormStyle: TFormStyle; const AManager: TDATVCLLanguageManagerSpike;
  const AObserver: TVCLSpikeObserver);
var
  Form: TfrmVCLLifecycle;
begin
  AObserver.BeginScenario(AScenario);
  Form := AFormClass.Create(AOwner);
  try
    Form.FormStyle := AFormStyle;
    Form.Show;
    PumpToIdle;
    AObserver.VerifyScenario(Form, AManager);
    Form.Hide;
    AObserver.WriteScenario;
  finally
    Form.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    AScenario + ': released form remained tracked.');
end;

procedure RunModalScenario(const AManager: TDATVCLLanguageManagerSpike;
  const AObserver: TVCLSpikeObserver);
var
  Form: TfrmVCLLifecycle;
begin
  AObserver.BeginScenario('modal');
  Form := TfrmVCLLifecycle.Create(nil);
  try
    Form.CloseModalAutomatically := True;
    Require(AManager.ApplyToForm(Form) > 0,
      'modal: explicit pre-display translation did not apply.');
    Require(AManager.WasApplied(Form),
      'modal: explicit pre-display translation was not tracked.');
    Require(Pos('translated', LowerCase(Form.Caption)) > 0,
      'modal: caption was not translated before ShowModal.');
    Require(Pos('translated', LowerCase(Form.lblProbe.Caption)) > 0,
      'modal: probe text was not translated before ShowModal.');
    Form.ShowModal;
    Require(Pos('translated', LowerCase(Form.Caption)) > 0,
      'modal: caption lost its translation during ShowModal.');
    Require(Pos('translated', LowerCase(Form.lblProbe.Caption)) > 0,
      'modal: probe text lost its translation during ShowModal.');
    AObserver.WriteScenario;
  finally
    Form.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    'Modal VCL form remained tracked after destruction.');
end;

procedure RunDuplicateInstanceKeyProbe(
  const AManager: TDATVCLLanguageManagerSpike);
var
  FirstForm: TfrmVCLLifecycle;
  SecondForm: TfrmVCLLifecycle;
begin
  FirstForm := TfrmVCLLifecycle.Create(nil);
  SecondForm := TfrmVCLLifecycle.Create(nil);
  try
    FirstForm.Show;
    SecondForm.Show;
    PumpToIdle;
    Require(AManager.WasApplied(FirstForm) and AManager.WasApplied(SecondForm),
      'VCL duplicate-instance forms were not both discovered.');
    Require(Pos('translated', LowerCase(FirstForm.Caption)) > 0,
      'VCL first duplicate-instance form was not translated.');
    Require(Pos('translated', LowerCase(SecondForm.Caption)) = 0,
      'VCL duplicate-instance key probe no longer exposes the expected gap.');
    Writeln('VCL_DUPLICATE_INSTANCE_DISCOVERY=PASS');
    Writeln('VCL_DUPLICATE_INSTANCE_KEY=UNRESOLVED;SECOND_NAME=',
      SecondForm.Name);
  finally
    SecondForm.Free;
    FirstForm.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    'VCL duplicate-instance forms remained tracked after destruction.');
end;

var
  AutoCreatedForm: TfrmVCLLifecycle;
  CoexistingEvents: TApplicationEvents;
  Manager: TDATVCLLanguageManagerSpike;
  Observer: TVCLSpikeObserver;
  Pack: TRuntimeLanguagePack;
  ScenarioOwner: TComponent;
begin
  Observer := TVCLSpikeObserver.Create;
  Pack := TestPack;
  Manager := TDATVCLLanguageManagerSpike.Create(nil);
  CoexistingEvents := TApplicationEvents.Create(nil);
  try
    SetLifecycleTraceEvent(Observer.FormLifecycle);
    Manager.Pack := Pack;
    Manager.OnLifecycle := Observer.ManagerLifecycle;
    CoexistingEvents.OnIdle := Observer.CoexistingIdle;
    Screen.OnActiveFormChange := Observer.ScreenActiveFormChanged;
    Application.Initialize;
    Application.MainFormOnTaskbar := True;

    Observer.BeginScenario('auto-created');
    AutoCreatedForm := nil;
    Application.CreateForm(TfrmVCLLifecycle, AutoCreatedForm);
    AutoCreatedForm.Show;
    PumpToIdle;
    Observer.VerifyScenario(AutoCreatedForm, Manager);
    AutoCreatedForm.Hide;
    Observer.WriteScenario;
    AutoCreatedForm.Name := 'frmVCLAutoCreatedLifecycle';

    ScenarioOwner := TComponent.Create(nil);
    try
      RunModelessScenario('dynamic-modeless', TfrmVCLLifecycle, ScenarioOwner,
        fsNormal, Manager, Observer);
    finally
      ScenarioOwner.Free;
    end;
    RunModelessScenario('ownerless', TfrmVCLLifecycle, nil,
      fsNormal, Manager, Observer);
    RunModelessScenario('inherited', TfrmVCLInheritedLifecycle, Application,
      fsNormal, Manager, Observer);
    RunModelessScenario('stay-on-top', TfrmVCLLifecycle, nil,
      fsStayOnTop, Manager, Observer);
    RunModalScenario(Manager, Observer);
    RunDuplicateInstanceKeyProbe(Manager);

    Require(Observer.CoexistingIdleCount > 0,
      'A coexisting TApplicationEvents.OnIdle subscriber was not called.');
    AutoCreatedForm.Free;
    Require(Manager.TrackedFormCount = 0,
      'VCL auto-created form remained tracked after destruction.');
    Writeln('VCL_MANAGER_DISCOVERY=PASS');
    Writeln('VCL_BEFORE_SHOW_GUARANTEE=NOT_AVAILABLE');
    Writeln('VCL_COEXISTING_IDLE=PASS');
  except
    on E: Exception do
    begin
      Writeln('VCL_LIFECYCLE_SPIKE=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  SetLifecycleTraceEvent(nil);
  Screen.OnActiveFormChange := nil;
  CoexistingEvents.Free;
  Manager.Free;
  Pack.Free;
  Observer.Free;
end.
