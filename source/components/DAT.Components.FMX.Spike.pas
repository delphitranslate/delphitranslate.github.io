unit DAT.Components.FMX.Spike;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Messaging,
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  TDATFMXLifecycleEvent = procedure(Sender: TObject;
    const AForm: TCommonCustomForm; const AStage: string;
    const AAppliedPropertyCount: Integer) of object;

  TDATFMXLanguageManagerSpike = class(TComponent)
  private
    FPack: TRuntimeLanguagePack;
    FAppliedForms: TDictionary<TCommonCustomForm, Integer>;
    FAfterCreateSubscription: TMessageSubscriptionId;
    FBeforeShownSubscription: TMessageSubscriptionId;
    FActivateSubscription: TMessageSubscriptionId;
    FReleasedSubscription: TMessageSubscriptionId;
    FOnLifecycle: TDATFMXLifecycleEvent;
    procedure HandleAfterCreate(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleBeforeShown(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleActivate(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleReleased(const Sender: TObject;
      const AMessage: TMessage);
    procedure Report(const AForm: TCommonCustomForm; const AStage: string;
      const AAppliedPropertyCount: Integer = 0);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ApplyToForm(const AForm: TCommonCustomForm): Integer;
    function WasApplied(const AForm: TCommonCustomForm): Boolean;
    function TrackedFormCount: Integer;
    property Pack: TRuntimeLanguagePack read FPack write FPack;
    property OnLifecycle: TDATFMXLifecycleEvent read FOnLifecycle
      write FOnLifecycle;
  end;

implementation

uses
  DAT.Runtime.FMX;

constructor TDATFMXLanguageManagerSpike.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAppliedForms := TDictionary<TCommonCustomForm, Integer>.Create;
  if not (csDesigning in ComponentState) then
  begin
    FAfterCreateSubscription := TMessageManager.DefaultManager.SubscribeToMessage(
      TAfterCreateFormHandle, HandleAfterCreate);
    FBeforeShownSubscription := TMessageManager.DefaultManager.SubscribeToMessage(
      TFormBeforeShownMessage, HandleBeforeShown);
    FActivateSubscription := TMessageManager.DefaultManager.SubscribeToMessage(
      TFormActivateMessage, HandleActivate);
    FReleasedSubscription := TMessageManager.DefaultManager.SubscribeToMessage(
      TFormReleasedMessage, HandleReleased);
  end;
end;

destructor TDATFMXLanguageManagerSpike.Destroy;
begin
  if FAfterCreateSubscription <> 0 then
    TMessageManager.DefaultManager.Unsubscribe(
      TAfterCreateFormHandle, FAfterCreateSubscription);
  if FBeforeShownSubscription <> 0 then
    TMessageManager.DefaultManager.Unsubscribe(
      TFormBeforeShownMessage, FBeforeShownSubscription);
  if FActivateSubscription <> 0 then
    TMessageManager.DefaultManager.Unsubscribe(
      TFormActivateMessage, FActivateSubscription);
  if FReleasedSubscription <> 0 then
    TMessageManager.DefaultManager.Unsubscribe(
      TFormReleasedMessage, FReleasedSubscription);
  FAppliedForms.Free;
  inherited Destroy;
end;

function TDATFMXLanguageManagerSpike.ApplyToForm(
  const AForm: TCommonCustomForm): Integer;
begin
  Result := 0;
  if (AForm = nil) or (FPack = nil) then
    Exit;
  if FAppliedForms.ContainsKey(AForm) then
    Exit;
  Result := TFMXTranslationApplicator.ApplyToForm(AForm, FPack);
  FAppliedForms.Add(AForm, Result);
  Report(AForm, 'applied', Result);
end;

procedure TDATFMXLanguageManagerSpike.HandleActivate(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if AMessage is TFormActivateMessage then
  begin
    Form := TFormActivateMessage(AMessage).Value;
    Report(Form, 'activate');
  end;
end;

procedure TDATFMXLanguageManagerSpike.HandleAfterCreate(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if AMessage is TAfterCreateFormHandle then
  begin
    Form := TAfterCreateFormHandle(AMessage).Value;
    Report(Form, 'handle-created');
  end;
end;

procedure TDATFMXLanguageManagerSpike.HandleBeforeShown(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if AMessage is TFormBeforeShownMessage then
  begin
    Form := TFormBeforeShownMessage(AMessage).Value;
    Report(Form, 'before-show');
    ApplyToForm(Form);
  end;
end;

procedure TDATFMXLanguageManagerSpike.HandleReleased(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if Sender is TCommonCustomForm then
  begin
    Form := TCommonCustomForm(Sender);
    Report(Form, 'released');
    FAppliedForms.Remove(Form);
  end;
end;

procedure TDATFMXLanguageManagerSpike.Report(const AForm: TCommonCustomForm;
  const AStage: string; const AAppliedPropertyCount: Integer);
begin
  if Assigned(FOnLifecycle) then
    FOnLifecycle(Self, AForm, AStage, AAppliedPropertyCount);
end;

function TDATFMXLanguageManagerSpike.WasApplied(
  const AForm: TCommonCustomForm): Boolean;
begin
  Result := (AForm <> nil) and FAppliedForms.ContainsKey(AForm);
end;

function TDATFMXLanguageManagerSpike.TrackedFormCount: Integer;
begin
  Result := FAppliedForms.Count;
end;

end.
