unit DAT.Components.VCL.Spike;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Vcl.AppEvnts,
  Vcl.Forms,
  DAT.Runtime.LanguagePack;

type
  TDATVCLLifecycleEvent = procedure(Sender: TObject;
    const AForm: TCustomForm; const AStage: string;
    const AAppliedPropertyCount: Integer) of object;

  TDATVCLLanguageManagerSpike = class(TComponent)
  private
    FApplicationEvents: TApplicationEvents;
    FPack: TRuntimeLanguagePack;
    FAppliedForms: TDictionary<TCustomForm, Integer>;
    FOnLifecycle: TDATVCLLifecycleEvent;
    procedure HandleIdle(Sender: TObject; var Done: Boolean);
    procedure Report(const AForm: TCustomForm; const AStage: string;
      const AAppliedPropertyCount: Integer = 0);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ApplyToForm(const AForm: TCustomForm): Integer;
    procedure InspectOpenForms;
    function WasApplied(const AForm: TCustomForm): Boolean;
    function TrackedFormCount: Integer;
    property Pack: TRuntimeLanguagePack read FPack write FPack;
    property OnLifecycle: TDATVCLLifecycleEvent read FOnLifecycle
      write FOnLifecycle;
  end;

implementation

uses
  DAT.Runtime.VCL;

constructor TDATVCLLanguageManagerSpike.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAppliedForms := TDictionary<TCustomForm, Integer>.Create;
  if not (csDesigning in ComponentState) then
  begin
    FApplicationEvents := TApplicationEvents.Create(Self);
    FApplicationEvents.OnIdle := HandleIdle;
  end;
end;

destructor TDATVCLLanguageManagerSpike.Destroy;
begin
  FApplicationEvents.Free;
  FAppliedForms.Free;
  inherited Destroy;
end;

function TDATVCLLanguageManagerSpike.ApplyToForm(
  const AForm: TCustomForm): Integer;
begin
  Result := 0;
  if (AForm = nil) or (FPack = nil) then
    Exit;
  if FAppliedForms.ContainsKey(AForm) then
    Exit;
  Result := TVCLTranslationApplicator.ApplyToForm(AForm, FPack);
  FAppliedForms.Add(AForm, Result);
  AForm.FreeNotification(Self);
  Report(AForm, 'idle-applied', Result);
end;

procedure TDATVCLLanguageManagerSpike.HandleIdle(Sender: TObject;
  var Done: Boolean);
begin
  InspectOpenForms;
end;

procedure TDATVCLLanguageManagerSpike.InspectOpenForms;
var
  FormIndex: Integer;
begin
  Report(nil, 'idle-scan');
  for FormIndex := 0 to Screen.CustomFormCount - 1 do
    ApplyToForm(Screen.CustomForms[FormIndex]);
end;

procedure TDATVCLLanguageManagerSpike.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent is TCustomForm) and
    (FAppliedForms <> nil) then
  begin
    Report(TCustomForm(AComponent), 'released');
    FAppliedForms.Remove(TCustomForm(AComponent));
  end;
end;

procedure TDATVCLLanguageManagerSpike.Report(const AForm: TCustomForm;
  const AStage: string; const AAppliedPropertyCount: Integer);
begin
  if Assigned(FOnLifecycle) then
    FOnLifecycle(Self, AForm, AStage, AAppliedPropertyCount);
end;

function TDATVCLLanguageManagerSpike.WasApplied(
  const AForm: TCustomForm): Boolean;
begin
  Result := (AForm <> nil) and FAppliedForms.ContainsKey(AForm);
end;

function TDATVCLLanguageManagerSpike.TrackedFormCount: Integer;
begin
  Result := FAppliedForms.Count;
end;

end.
