unit DAT.LifecycleSpike.Trace;

interface

uses
  System.Classes;

type
  TLifecycleTraceEvent = procedure(const AFramework, AFormName,
    AStage, ACaption, AProbeText: string) of object;

procedure RecordLifecycle(const AFramework, AFormName, AStage,
  ACaption, AProbeText: string);
procedure SetLifecycleTraceEvent(const AEvent: TLifecycleTraceEvent);

implementation

var
  ActiveTraceEvent: TLifecycleTraceEvent;

procedure RecordLifecycle(const AFramework, AFormName, AStage,
  ACaption, AProbeText: string);
begin
  if Assigned(ActiveTraceEvent) then
    ActiveTraceEvent(AFramework, AFormName, AStage, ACaption, AProbeText);
end;

procedure SetLifecycleTraceEvent(const AEvent: TLifecycleTraceEvent);
begin
  ActiveTraceEvent := AEvent;
end;

end.
