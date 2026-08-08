program FMXManagerLifecycleSpikeTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.Classes,
  System.SysUtils,
  Winapi.Windows,
  FMX.Forms,
  FMX.Types,
  DAT.LifecycleSpike.Trace in 'lifecycle\DAT.LifecycleSpike.Trace.pas',
  FMXLifecycle.Form in 'lifecycle\FMXLifecycle.Form.pas'
    {frmFMXLifecycle},
  FMXLifecycle.InheritedForm in 'lifecycle\FMXLifecycle.InheritedForm.pas'
    {frmFMXInheritedLifecycle},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.FMX.Spike in '..\..\source\components\DAT.Components.FMX.Spike.pas';

type
  TFMXLifecycleFormClass = class of TfrmFMXLifecycle;

  TFMXSpikeObserver = class
  private
    FScenario: string;
    FSequence: Integer;
    FBeforeShowSequence: Integer;
    FAppliedSequence: Integer;
    FShowSequence: Integer;
    FPaintSequence: Integer;
    FShowTranslated: Boolean;
    FPaintTranslated: Boolean;
    FTrace: TStringList;
    FManager: TDATFMXLanguageManagerSpike;
    FAutoCreatedForm: TfrmFMXLifecycle;
    FRunError: string;
    function IsTranslated(const ACaption, AProbeText: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginScenario(const AScenario: string);
    procedure ConfigureRun(const AManager: TDATFMXLanguageManagerSpike;
      const AAutoCreatedForm: TfrmFMXLifecycle);
    procedure ExecuteScenarios(Sender: TObject);
    procedure FormLifecycle(const AFramework, AFormName, AStage,
      ACaption, AProbeText: string);
    procedure ManagerLifecycle(Sender: TObject;
      const AForm: TCommonCustomForm; const AStage: string;
      const AAppliedPropertyCount: Integer);
    procedure VerifyScenario(const AForm: TfrmFMXLifecycle;
      const AManager: TDATFMXLanguageManagerSpike);
    procedure WriteScenario;
    property RunError: string read FRunError;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":1,"applicationId":"LifecycleSpikeFMX",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"spike",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmFMXLifecycle.Caption":"FMX translated caption",' +
    '"frmFMXLifecycle.lblProbe.Text":"FMX translated probe",' +
    '"frmFMXInheritedLifecycle.Caption":"FMX inherited translated caption",' +
    '"frmFMXInheritedLifecycle.lblProbe.Text":"FMX inherited translated probe"}}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

constructor TFMXSpikeObserver.Create;
begin
  inherited Create;
  FTrace := TStringList.Create;
end;

destructor TFMXSpikeObserver.Destroy;
begin
  FTrace.Free;
  inherited Destroy;
end;

procedure TFMXSpikeObserver.BeginScenario(const AScenario: string);
begin
  FScenario := AScenario;
  FSequence := 0;
  FBeforeShowSequence := 0;
  FAppliedSequence := 0;
  FShowSequence := 0;
  FPaintSequence := 0;
  FShowTranslated := False;
  FPaintTranslated := False;
  FTrace.Clear;
end;

procedure TFMXSpikeObserver.ConfigureRun(
  const AManager: TDATFMXLanguageManagerSpike;
  const AAutoCreatedForm: TfrmFMXLifecycle);
begin
  FManager := AManager;
  FAutoCreatedForm := AAutoCreatedForm;
  FRunError := '';
end;

procedure TFMXSpikeObserver.FormLifecycle(const AFramework, AFormName,
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

function TFMXSpikeObserver.IsTranslated(const ACaption,
  AProbeText: string): Boolean;
begin
  Result := (Pos('translated', LowerCase(ACaption)) > 0) and
    (Pos('translated', LowerCase(AProbeText)) > 0);
end;

procedure TFMXSpikeObserver.ManagerLifecycle(Sender: TObject;
  const AForm: TCommonCustomForm; const AStage: string;
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
  if (AStage = 'before-show') and (FBeforeShowSequence = 0) then
    FBeforeShowSequence := FSequence;
  if (AStage = 'applied') and (FAppliedSequence = 0) then
    FAppliedSequence := FSequence;
end;

procedure TFMXSpikeObserver.VerifyScenario(const AForm: TfrmFMXLifecycle;
  const AManager: TDATFMXLanguageManagerSpike);
begin
  Require(AManager.WasApplied(AForm),
    FScenario + ': manager did not apply the form.');
  Require(Pos('translated', LowerCase(AForm.Caption)) > 0,
    FScenario + ': final caption was not translated; form name=' +
    AForm.Name + '; caption=' + AForm.Caption + '.');
  Require(Pos('translated', LowerCase(AForm.lblProbe.Text)) > 0,
    FScenario + ': final probe text was not translated.');
  Require(FBeforeShowSequence > 0,
    FScenario + ': before-show message was not observed.');
  Require(FAppliedSequence > FBeforeShowSequence,
    FScenario + ': application did not follow before-show.');
  Require(FShowSequence > FAppliedSequence,
    FScenario + ': form OnShow ran before translation.');
  Require(FShowTranslated,
    FScenario + ': OnShow observed source-language text.');
  Require(FPaintSequence > FAppliedSequence,
    FScenario + ': paint did not follow translation.');
  Require(FPaintTranslated,
    FScenario + ': first paint observed source-language text.');
end;

procedure TFMXSpikeObserver.WriteScenario;
var
  TraceIndex: Integer;
begin
  Writeln('SCENARIO=', FScenario);
  for TraceIndex := 0 to FTrace.Count - 1 do
    Writeln(FTrace[TraceIndex]);
  Writeln('RESULT=PASS;SHOW_TRANSLATED=', BoolToStr(FShowTranslated, True),
    ';PAINT_TRANSLATED=', BoolToStr(FPaintTranslated, True));
end;

procedure PumpMessages;
var
  PumpIndex: Integer;
begin
  for PumpIndex := 1 to 12 do
  begin
    Application.ProcessMessages;
    Sleep(5);
  end;
end;

procedure RunModelessScenario(const AScenario: string;
  const AFormClass: TFMXLifecycleFormClass; const AOwner: TComponent;
  const AFormStyle: TFormStyle; const AManager: TDATFMXLanguageManagerSpike;
  const AObserver: TFMXSpikeObserver);
var
  Form: TfrmFMXLifecycle;
begin
  AObserver.BeginScenario(AScenario);
  Form := AFormClass.Create(AOwner);
  try
    Form.FormStyle := AFormStyle;
    Form.Show;
    PumpMessages;
    AObserver.VerifyScenario(Form, AManager);
    Form.Hide;
    AObserver.WriteScenario;
  finally
    Form.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    AScenario + ': released form remained tracked.');
end;

procedure RunModalScenario(const AManager: TDATFMXLanguageManagerSpike;
  const AObserver: TFMXSpikeObserver);
var
  Form: TfrmFMXLifecycle;
begin
  AObserver.BeginScenario('modal');
  Form := TfrmFMXLifecycle.Create(nil);
  try
    Form.CloseModalAutomatically := True;
    Form.ShowModal;
    AObserver.VerifyScenario(Form, AManager);
    AObserver.WriteScenario;
  finally
    Form.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    'Modal FMX form remained tracked after destruction.');
end;

procedure RunDuplicateInstanceKeyProbe(
  const AManager: TDATFMXLanguageManagerSpike);
var
  FirstForm: TfrmFMXLifecycle;
  SecondForm: TfrmFMXLifecycle;
begin
  FirstForm := TfrmFMXLifecycle.Create(nil);
  SecondForm := TfrmFMXLifecycle.Create(nil);
  try
    FirstForm.Show;
    SecondForm.Show;
    PumpMessages;
    Require(AManager.WasApplied(FirstForm) and AManager.WasApplied(SecondForm),
      'FMX duplicate-instance forms were not both observed.');
    Require(Pos('translated', LowerCase(FirstForm.Caption)) > 0,
      'FMX first duplicate-instance form was not translated.');
    Require(Pos('translated', LowerCase(SecondForm.Caption)) = 0,
      'FMX duplicate-instance key probe no longer exposes the expected gap.');
    Writeln('FMX_DUPLICATE_INSTANCE_DISCOVERY=PASS');
    Writeln('FMX_DUPLICATE_INSTANCE_KEY=UNRESOLVED;SECOND_NAME=',
      SecondForm.Name);
  finally
    SecondForm.Free;
    FirstForm.Free;
  end;
  Require(AManager.TrackedFormCount = 1,
    'FMX duplicate-instance forms remained tracked after destruction.');
end;

procedure TFMXSpikeObserver.ExecuteScenarios(Sender: TObject);
var
  ScenarioOwner: TComponent;
begin
  TTimer(Sender).Enabled := False;
  try
    if FAutoCreatedForm = nil then
      FAutoCreatedForm := TfrmFMXLifecycle(Application.MainForm);
    VerifyScenario(FAutoCreatedForm, FManager);
    FAutoCreatedForm.Hide;
    WriteScenario;
    FAutoCreatedForm.Name := 'frmFMXAutoCreatedLifecycle';

    ScenarioOwner := TComponent.Create(nil);
    try
      RunModelessScenario('dynamic-modeless', TfrmFMXLifecycle, ScenarioOwner,
        TFormStyle.Normal, FManager, Self);
    finally
      ScenarioOwner.Free;
    end;
    RunModelessScenario('ownerless', TfrmFMXLifecycle, nil,
      TFormStyle.Normal, FManager, Self);
    RunModelessScenario('inherited', TfrmFMXInheritedLifecycle, Application,
      TFormStyle.Normal, FManager, Self);
    RunModelessScenario('popup-style', TfrmFMXLifecycle, nil,
      TFormStyle.Popup, FManager, Self);
    RunModalScenario(FManager, Self);
    RunDuplicateInstanceKeyProbe(FManager);
  except
    on E: Exception do
      FRunError := E.ClassName + ': ' + E.Message;
  end;
  Application.Terminate;
end;

var
  AutoCreatedForm: TfrmFMXLifecycle;
  Manager: TDATFMXLanguageManagerSpike;
  Observer: TFMXSpikeObserver;
  Pack: TRuntimeLanguagePack;
  RunTimer: TTimer;
begin
  Observer := TFMXSpikeObserver.Create;
  Pack := TestPack;
  Manager := TDATFMXLanguageManagerSpike.Create(nil);
  try
    SetLifecycleTraceEvent(Observer.FormLifecycle);
    Manager.Pack := Pack;
    Manager.OnLifecycle := Observer.ManagerLifecycle;
    Application.Initialize;

    Observer.BeginScenario('auto-created');
    AutoCreatedForm := nil;
    Application.CreateForm(TfrmFMXLifecycle, AutoCreatedForm);
    Observer.ConfigureRun(Manager, AutoCreatedForm);
    RunTimer := TTimer.Create(nil);
    try
      RunTimer.Enabled := False;
      RunTimer.Interval := 100;
      RunTimer.OnTimer := Observer.ExecuteScenarios;
      RunTimer.Enabled := True;
      Application.Run;
    finally
      RunTimer.Free;
    end;
    Require(Observer.RunError = '', Observer.RunError);

    AutoCreatedForm.Free;
    Require(Manager.TrackedFormCount = 0,
      'FMX auto-created form remained tracked after destruction.');
    Writeln('FMX_LIFECYCLE_SPIKE=PASS');
  except
    on E: Exception do
    begin
      Writeln('FMX_LIFECYCLE_SPIKE=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  SetLifecycleTraceEvent(nil);
  Manager.Free;
  Pack.Free;
  Observer.Free;
end.
