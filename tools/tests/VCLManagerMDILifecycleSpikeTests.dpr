program VCLManagerMDILifecycleSpikeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  Winapi.Messages,
  Winapi.Windows,
  Vcl.Forms,
  DAT.LifecycleSpike.Trace in 'lifecycle\DAT.LifecycleSpike.Trace.pas',
  VCLLifecycle.MDIMain in 'lifecycle\VCLLifecycle.MDIMain.pas'
    {frmVCLLifecycleMDIMain},
  VCLLifecycle.MDIChild in 'lifecycle\VCLLifecycle.MDIChild.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.VCL.Spike in '..\..\source\components\DAT.Components.VCL.Spike.pas';

type
  TMDIObserver = class
  private
    FMainFirstPaintTranslated: Boolean;
    FChildFirstPaintTranslated: Boolean;
    FMainPaintSeen: Boolean;
    FChildPaintSeen: Boolean;
  public
    procedure FormLifecycle(const AFramework, AFormName, AStage,
      ACaption, AProbeText: string);
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":1,"applicationId":"LifecycleSpikeVCLMDI",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"spike",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmVCLLifecycleMDIMain.Caption":"VCL MDI main translated",' +
    '"frmVCLLifecycleMDIMain.lblProbe.Caption":"VCL MDI main translated probe",' +
    '"frmVCLLifecycleMDIChild.Caption":"VCL MDI child translated",' +
    '"frmVCLLifecycleMDIChild.lblProbe.Caption":"VCL MDI child translated probe"}}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

procedure TMDIObserver.FormLifecycle(const AFramework, AFormName, AStage,
  ACaption, AProbeText: string);
var
  IsTranslated: Boolean;
begin
  if AStage <> 'paint' then
    Exit;
  IsTranslated := Pos('translated', LowerCase(AProbeText)) > 0;
  if (AFormName = 'frmVCLLifecycleMDIMain') and not FMainPaintSeen then
  begin
    FMainPaintSeen := True;
    FMainFirstPaintTranslated := IsTranslated;
  end;
  if (AFormName = 'frmVCLLifecycleMDIChild') and not FChildPaintSeen then
  begin
    FChildPaintSeen := True;
    FChildFirstPaintTranslated := IsTranslated;
  end;
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

var
  ChildForm: TfrmVCLLifecycleMDIChild;
  Manager: TDATVCLLanguageManagerSpike;
  Observer: TMDIObserver;
  Pack: TRuntimeLanguagePack;
begin
  Observer := TMDIObserver.Create;
  Pack := TestPack;
  Manager := TDATVCLLanguageManagerSpike.Create(nil);
  try
    SetLifecycleTraceEvent(Observer.FormLifecycle);
    Manager.Pack := Pack;
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TfrmVCLLifecycleMDIMain,
      frmVCLLifecycleMDIMain);
    frmVCLLifecycleMDIMain.Show;
    ChildForm := TfrmVCLLifecycleMDIChild.Create(Application);
    try
      ChildForm.Show;
      PumpToIdle;
      Require(Manager.WasApplied(frmVCLLifecycleMDIMain),
        'MDI main form was not discovered.');
      Require(Manager.WasApplied(ChildForm),
        'MDI child form was not discovered.');
      Require(Pos('translated', LowerCase(frmVCLLifecycleMDIMain.Caption)) > 0,
        'MDI main form was not translated after idle.');
      Require(Pos('translated', LowerCase(ChildForm.Caption)) > 0,
        'MDI child form was not translated after idle.');
      Require(Observer.FMainPaintSeen and Observer.FChildPaintSeen,
        'MDI paint instrumentation did not run.');
      Writeln('VCL_MDI_DISCOVERY=PASS');
      Writeln('VCL_MDI_MAIN_FIRST_PAINT_TRANSLATED=',
        BoolToStr(Observer.FMainFirstPaintTranslated, True));
      Writeln('VCL_MDI_CHILD_FIRST_PAINT_TRANSLATED=',
        BoolToStr(Observer.FChildFirstPaintTranslated, True));
    finally
      ChildForm.Free;
    end;
    frmVCLLifecycleMDIMain.Free;
    Require(Manager.TrackedFormCount = 0,
      'VCL MDI forms remained tracked after destruction.');
  except
    on E: Exception do
    begin
      Writeln('VCL_MDI_LIFECYCLE_SPIKE=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
  SetLifecycleTraceEvent(nil);
  Manager.Free;
  Pack.Free;
  Observer.Free;
end.
