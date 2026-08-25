unit DAT.Components.VCL;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Vcl.AppEvnts,
  Vcl.Forms,
  DAT.Components.Core,
  DAT.Runtime.LanguagePack;

type
  TDATVCLLanguageManager = class(TDATCustomLanguageManager)
  private
    FApplicationEvents: TApplicationEvents;
    FAutoDiscoverForms: Boolean;
    FPreviousActiveFormChange: TNotifyEvent;
    FTranslatingActiveForm: Boolean;
    FIdleScanInterval: Cardinal;
    FLastIdleScanTick: UInt64;
    procedure HandleIdle(Sender: TObject; var Done: Boolean);
    procedure HandleModalBegin(Sender: TObject);
    procedure HandleActiveFormChange(Sender: TObject);
    procedure SetIdleScanInterval(const Value: Cardinal);
  protected
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
    function ApplyToForm(const AForm: TCustomForm): Integer;
    procedure InspectOpenForms(const AIncludeHiddenForms: Boolean = False);
  published
    property AutoDiscoverForms: Boolean read FAutoDiscoverForms
      write FAutoDiscoverForms default True;
    property IdleScanInterval: Cardinal read FIdleScanInterval
      write SetIdleScanInterval default 100;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  DAT.Runtime.SplashTranslation,
  { Named so it is linked at all.

    Its work happens in its initialization section, and a unit no other
    unit uses is a unit the linker leaves out - so copying it into the
    component kit was not enough to make it run. It was reached only by
    its own harness, which lists it explicitly, so every test passed while
    no real application ever installed the hook. }
  DAT.Runtime.SplashTranslation.VCL,
  DAT.Runtime.TemplateRewrite.VCL,
  DAT.Runtime.VCL;

constructor TDATVCLLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoDiscoverForms := True;
  FIdleScanInterval := 100;
  if not (csDesigning in ComponentState) then
  begin
    FApplicationEvents := TApplicationEvents.Create(Self);
    FApplicationEvents.OnIdle := HandleIdle;
    FApplicationEvents.OnModalBegin := HandleModalBegin;
    { A form becoming active is the moment a form built after the language was
      chosen first appears, and it is the only moment VCL offers that is as
      early as FireMonkey's before-shown message. Without it a form created on
      demand - which is how most applications open a dialog - was left to an
      idle scan, and came up in the source language.

      Whatever was on the hook stays on it: this is a screen-wide event and
      another component may be listening. }
    if Screen <> nil then
    begin
      FPreviousActiveFormChange := Screen.OnActiveFormChange;
      Screen.OnActiveFormChange := HandleActiveFormChange;
    end;
  end;
end;

destructor TDATVCLLanguageManager.Destroy;
var
  OwnHandler: TNotifyEvent;
begin
  { Put back whatever was on the hook, but only if this manager is still the
    one holding it: another component may have taken it since. }
  OwnHandler := HandleActiveFormChange;
  if (Screen <> nil) and
    (TMethod(Screen.OnActiveFormChange).Code = TMethod(OwnHandler).Code) and
    (TMethod(Screen.OnActiveFormChange).Data = Self) then
    Screen.OnActiveFormChange := FPreviousActiveFormChange;
  FreeAndNil(FApplicationEvents);
  inherited Destroy;
end;

function TDATVCLLanguageManager.ApplyLanguagePack(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  { The manager is now doing the work, so the startup hook that covered
    forms appearing before any manager existed - a splash, typically - stops.
    It inferred its settings from the shipping defaults; this component was
    told them, and being told beats inferring. }
  TDATSplashTranslation.StandDown;
  { Text the application builds for itself never passes through a property
    this applicator sets - a caption rebuilt on a timer is the usual case.
    Catching it at the window means the source language is never painted,
    where re-writing it afterwards would only alternate with the
    application. }
  TDATVCLTemplateIntercept.Install(TCustomForm(AManagedObject), APack);
  Result := TVCLTranslationApplicator.ApplyToForm(
    TCustomForm(AManagedObject), APack, AFormIdentity,
    PreserveControlState);
end;

function TDATVCLLanguageManager.RestoreLanguageLayout(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TVCLTranslationApplicator.ApplyLayoutToForm(
    TCustomForm(AManagedObject), APack, AFormIdentity, False);
end;

function TDATVCLLanguageManager.RestoreSourceLanguage(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
var
  Form: TCustomForm;
begin
  Form := TCustomForm(AManagedObject);
  { The interceptors deliberately turn source-language text back into the
    active translation. They must not remain attached while that translation
    is being retired: otherwise restoring an English caption from Arabic can
    be intercepted and changed straight back to Arabic, and the next pack
    correctly preserves it as apparent live application data. ApplyLanguagePack
    installs both interceptors again with the newly selected pack. }
  TDATVCLTemplateIntercept.Remove(Form);
  TVCLTranslationApplicator.StopDynamicRefresh(Form);
  Result := TVCLTranslationApplicator.RestoreSourceLanguage(
    Form, APack, AFormIdentity);
end;

function TDATVCLLanguageManager.ApplyToForm(
  const AForm: TCustomForm): Integer;
begin
  Result := ApplyToManagedObject(AForm);
end;

procedure TDATVCLLanguageManager.CollectOpenManagedObjects(
  const AObjects: TList<TObject>);
var
  Form: TCustomForm;
  FormIndex: Integer;
begin
  if Screen = nil then
    Exit;
  for FormIndex := 0 to Screen.CustomFormCount - 1 do
  begin
    Form := Screen.CustomForms[FormIndex];
    if (Form <> nil) and (TranslateHiddenForms or Form.Visible) and
      (AObjects.IndexOf(Form) < 0) then
      AObjects.Add(Form);
  end;
end;

procedure TDATVCLLanguageManager.HandleIdle(Sender: TObject;
  var Done: Boolean);
var
  CurrentTick: UInt64;
begin
  if not FAutoDiscoverForms then
    Exit;
  CurrentTick := GetTickCount64;
  if (FIdleScanInterval > 0) and (FLastIdleScanTick > 0) and
    (CurrentTick - FLastIdleScanTick < FIdleScanInterval) then
    Exit;
  FLastIdleScanTick := CurrentTick;
  InspectOpenForms(False);
end;

procedure TDATVCLLanguageManager.HandleActiveFormChange(Sender: TObject);
var
  ActiveForm: TCustomForm;
begin
  { Applying can move focus, which can raise this event again. One pass at a
    time, and the form that is already done for this language is skipped by
    the manager itself. }
  if FTranslatingActiveForm then
    Exit;
  if FAutoDiscoverForms and AutoTranslateNewForms and (Screen <> nil) then
  begin
    ActiveForm := Screen.ActiveCustomForm;
    if (ActiveForm <> nil) and not WasAppliedInCurrentGeneration(ActiveForm) then
    begin
      FTranslatingActiveForm := True;
      try
        ApplyToManagedObject(ActiveForm);
      finally
        FTranslatingActiveForm := False;
      end;
    end;
  end;
  if Assigned(FPreviousActiveFormChange) then
    FPreviousActiveFormChange(Sender);
end;

procedure TDATVCLLanguageManager.HandleModalBegin(Sender: TObject);
begin
  if FAutoDiscoverForms then
    InspectOpenForms(True);
end;

procedure TDATVCLLanguageManager.InspectOpenForms(
  const AIncludeHiddenForms: Boolean);
var
  Form: TCustomForm;
  FormIndex: Integer;
begin
  if Screen = nil then
    Exit;
  for FormIndex := 0 to Screen.CustomFormCount - 1 do
  begin
    Form := Screen.CustomForms[FormIndex];
    if (Form <> nil) and
      (AIncludeHiddenForms or TranslateHiddenForms or Form.Visible) then
      ApplyToManagedObject(Form);
  end;
end;

function TDATVCLLanguageManager.ManagedObjectInstanceName(
  const AManagedObject: TObject): string;
begin
  Result := TCustomForm(AManagedObject).Name;
end;

procedure TDATVCLLanguageManager.SetIdleScanInterval(
  const Value: Cardinal);
begin
  FIdleScanInterval := Value;
  FLastIdleScanTick := 0;
end;

function TDATVCLLanguageManager.SupportsManagedObject(
  const AManagedObject: TObject): Boolean;
begin
  Result := AManagedObject is TCustomForm;
end;

initialization
  System.Classes.RegisterClass(TDATVCLLanguageManager);

finalization
  System.Classes.UnregisterClass(TDATVCLLanguageManager);

end.
