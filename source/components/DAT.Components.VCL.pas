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
    FIdleScanInterval: Cardinal;
    FLastIdleScanTick: UInt64;
    procedure HandleIdle(Sender: TObject; var Done: Boolean);
    procedure HandleModalBegin(Sender: TObject);
    procedure SetIdleScanInterval(const Value: Cardinal);
  protected
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; override;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; override;
    function ApplyLanguagePack(const AManagedObject: TObject;
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
  end;
end;

destructor TDATVCLLanguageManager.Destroy;
begin
  FreeAndNil(FApplicationEvents);
  inherited Destroy;
end;

function TDATVCLLanguageManager.ApplyLanguagePack(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := TVCLTranslationApplicator.ApplyToForm(
    TCustomForm(AManagedObject), APack, AFormIdentity,
    PreserveControlState);
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
