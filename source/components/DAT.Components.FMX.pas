unit DAT.Components.FMX;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Messaging,
  FMX.Forms,
  FMX.Types,
  DAT.Components.Core,
  DAT.Runtime.LanguagePack;

type
  TDATFMXLanguageManager = class(TDATCustomLanguageManager)
  private
    FBeforeShownSubscription: TMessageSubscriptionId;
    FReleasedSubscription: TMessageSubscriptionId;
    FAutoRefreshDynamicText: Boolean;
    FDynamicRefreshInterval: Cardinal;
    FDynamicTimer: TTimer;
    procedure EnsureDynamicTimer;
    procedure DynamicTimerTick(Sender: TObject);
    procedure SetAutoRefreshDynamicText(const Value: Boolean);
    procedure SetDynamicRefreshInterval(const Value: Cardinal);
    procedure SubscribeToLifecycle;
    procedure UnsubscribeFromLifecycle;
    procedure HandleBeforeShown(const Sender: TObject;
      const AMessage: TMessage);
    procedure HandleReleased(const Sender: TObject;
      const AMessage: TMessage);
  protected
    procedure Loaded; override;
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; override;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; override;
    function ApplyLanguagePack(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreLanguageLayout(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreSourceLanguage(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    procedure CollectOpenManagedObjects(
      const AObjects: TList<TObject>); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ApplyToForm(const AForm: TCommonCustomForm): Integer;
    procedure RefreshDynamicText;
  published
    property AutoRefreshDynamicText: Boolean read FAutoRefreshDynamicText
      write SetAutoRefreshDynamicText default True;
    property DynamicRefreshInterval: Cardinal read FDynamicRefreshInterval
      write SetDynamicRefreshInterval default 1000;
  end;

implementation

uses
  DAT.Runtime.SplashTranslation,
  { Named so it is linked at all.

    Its work happens in its initialization section, and a unit no other
    unit uses is a unit the linker leaves out - so copying it into the
    component kit was not enough to make it run. It was reached only by
    its own harness, which lists it explicitly, so every test passed while
    no real application ever installed the hook. }
  DAT.Runtime.SplashTranslation.FMX,
  DAT.Runtime.TemplateRewrite.FMX,
  DAT.Runtime.FMX;

constructor TDATFMXLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoRefreshDynamicText := True;
  FDynamicRefreshInterval := 1000;
  if not (csDesigning in ComponentState) then
    SubscribeToLifecycle;
end;

destructor TDATFMXLanguageManager.Destroy;
begin
  UnsubscribeFromLifecycle;
  if FDynamicTimer <> nil then
  begin
    FDynamicTimer.Enabled := False;
    FDynamicTimer.OnTimer := nil;
  end;
  FDynamicTimer.Free;
  FDynamicTimer := nil;
  inherited Destroy;
end;

procedure TDATFMXLanguageManager.DynamicTimerTick(Sender: TObject);
begin
  RefreshDynamicText;
end;

procedure TDATFMXLanguageManager.EnsureDynamicTimer;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if FDynamicTimer = nil then
  begin
    FDynamicTimer := TTimer.Create(nil);
    FDynamicTimer.OnTimer := DynamicTimerTick;
  end;
  FDynamicTimer.Interval := FDynamicRefreshInterval;
  FDynamicTimer.Enabled := FAutoRefreshDynamicText and
    (FDynamicRefreshInterval > 0);
end;

procedure TDATFMXLanguageManager.Loaded;
begin
  inherited Loaded;
  EnsureDynamicTimer;
end;

procedure TDATFMXLanguageManager.RefreshDynamicText;
var
  Form: TObject;
  FormIdentity: string;
  Forms: TList<TObject>;
begin
  if not Initialized or (ActivePack = nil) then
    Exit;
  Forms := TList<TObject>.Create;
  try
    CollectOpenManagedObjects(Forms);
    for Form in Forms do
    begin
      FormIdentity := ResolveFormIdentity(Form,
        TCommonCustomForm(Form).Name);
      TFMXTranslationApplicator.ApplyToForm(TCommonCustomForm(Form),
        ActivePack, FormIdentity, PreserveControlState, False);
      { Text the application built for itself, which no property this
        applicator sets ever carried. VCL catches this at the window; FMX
        has no message to catch, so it is corrected here instead. }
      TDATFMXTemplateRewrite.RefreshCaption(TCommonCustomForm(Form),
        ActivePack);
    end;
  finally
    Forms.Free;
  end;
end;

procedure TDATFMXLanguageManager.SetAutoRefreshDynamicText(
  const Value: Boolean);
begin
  FAutoRefreshDynamicText := Value;
  EnsureDynamicTimer;
end;

procedure TDATFMXLanguageManager.SetDynamicRefreshInterval(
  const Value: Cardinal);
begin
  FDynamicRefreshInterval := Value;
  EnsureDynamicTimer;
end;

function TDATFMXLanguageManager.ApplyLanguagePack(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  { The manager is now doing the work, so the startup hook that covered
    forms appearing before any manager existed - a splash, typically - stops.
    It inferred its settings from the shipping defaults; this component was
    told them, and being told beats inferring. }
  TDATSplashTranslation.StandDown;
  Result := TFMXTranslationApplicator.ApplyToForm(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity,
    PreserveControlState);
end;

function TDATFMXLanguageManager.RestoreLanguageLayout(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TFMXTranslationApplicator.ApplyLayoutToForm(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity, False);
end;

function TDATFMXLanguageManager.RestoreSourceLanguage(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TFMXTranslationApplicator.RestoreSourceLanguage(
    TCommonCustomForm(AManagedObject), APack, AFormIdentity);
end;

function TDATFMXLanguageManager.ApplyToForm(
  const AForm: TCommonCustomForm): Integer;
begin
  Result := ApplyToManagedObject(AForm);
end;

procedure TDATFMXLanguageManager.CollectOpenManagedObjects(
  const AObjects: TList<TObject>);
var
  Form: TCommonCustomForm;
  FormIndex: Integer;
begin
  if Screen = nil then
    Exit;
  for FormIndex := 0 to Screen.FormCount - 1 do
  begin
    Form := Screen.Forms[FormIndex];
    if (Form <> nil) and (TranslateHiddenForms or Form.Visible) and
      (AObjects.IndexOf(Form) < 0) then
      AObjects.Add(Form);
  end;
  for FormIndex := 0 to Screen.PopupFormCount - 1 do
  begin
    Form := Screen.PopupForms[FormIndex];
    if (Form <> nil) and (TranslateHiddenForms or Form.Visible) and
      (AObjects.IndexOf(Form) < 0) then
      AObjects.Add(Form);
  end;
end;

procedure TDATFMXLanguageManager.HandleBeforeShown(const Sender: TObject;
  const AMessage: TMessage);
var
  Form: TCommonCustomForm;
begin
  if AutoTranslateNewForms and (AMessage is TFormBeforeShownMessage) then
  begin
    Form := TFormBeforeShownMessage(AMessage).Value;
    ReapplyToManagedObject(Form);
  end;
end;

procedure TDATFMXLanguageManager.HandleReleased(const Sender: TObject;
  const AMessage: TMessage);
begin
  if Sender is TCommonCustomForm then
    RemoveManagedObject(Sender);
end;

function TDATFMXLanguageManager.ManagedObjectInstanceName(
  const AManagedObject: TObject): string;
begin
  Result := TCommonCustomForm(AManagedObject).Name;
end;

procedure TDATFMXLanguageManager.SubscribeToLifecycle;
begin
  if FBeforeShownSubscription = 0 then
    FBeforeShownSubscription :=
      TMessageManager.DefaultManager.SubscribeToMessage(
        TFormBeforeShownMessage, HandleBeforeShown);
  if FReleasedSubscription = 0 then
    FReleasedSubscription :=
      TMessageManager.DefaultManager.SubscribeToMessage(
        TFormReleasedMessage, HandleReleased);
end;

function TDATFMXLanguageManager.SupportsManagedObject(
  const AManagedObject: TObject): Boolean;
begin
  Result := AManagedObject is TCommonCustomForm;
end;

procedure TDATFMXLanguageManager.UnsubscribeFromLifecycle;
begin
  if FBeforeShownSubscription <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(
      TFormBeforeShownMessage, FBeforeShownSubscription);
    FBeforeShownSubscription := 0;
  end;
  if FReleasedSubscription <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(
      TFormReleasedMessage, FReleasedSubscription);
    FReleasedSubscription := 0;
  end;
end;

initialization
  RegisterClass(TDATFMXLanguageManager);

finalization
  UnregisterClass(TDATFMXLanguageManager);

end.
