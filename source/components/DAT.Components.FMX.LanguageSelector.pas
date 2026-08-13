unit DAT.Components.FMX.LanguageSelector;

interface

uses
  System.Classes,
  FMX.ListBox,
  DAT.Components.FMX;

type
  TDATFMXLanguageComboBox = class(TComboBox)
  private
    FLanguageCodes: TStringList;
    FLanguageManager: TDATFMXLanguageManager;
    FAutoPopulate: Boolean;
    FShowLanguageCode: Boolean;
    FUpdating: Boolean;
    procedure SetLanguageManager(const Value: TDATFMXLanguageManager);
    procedure SetShowLanguageCode(const Value: Boolean);
  protected
    procedure DoChange; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshLanguages;
    function SelectLanguageCode(const ALanguageCode: string): Boolean;
  published
    property LanguageManager: TDATFMXLanguageManager read FLanguageManager
      write SetLanguageManager;
    property AutoPopulate: Boolean read FAutoPopulate write FAutoPopulate
      default True;
    property ShowLanguageCode: Boolean read FShowLanguageCode
      write SetShowLanguageCode default True;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  DAT.Runtime.LanguagePack;

constructor TDATFMXLanguageComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLanguageCodes := TStringList.Create;
  FLanguageCodes.CaseSensitive := False;
  FAutoPopulate := True;
  FShowLanguageCode := True;
end;

destructor TDATFMXLanguageComboBox.Destroy;
begin
  FLanguageCodes.Free;
  inherited Destroy;
end;

procedure TDATFMXLanguageComboBox.DoChange;
begin
  if not FUpdating and (FLanguageManager <> nil) and
    (ItemIndex >= 0) and (ItemIndex < FLanguageCodes.Count) then
    FLanguageManager.SelectLanguage(FLanguageCodes[ItemIndex]);
  inherited DoChange;
end;

procedure TDATFMXLanguageComboBox.Loaded;
begin
  inherited Loaded;
  if FAutoPopulate and not (csDesigning in ComponentState) then
    RefreshLanguages;
end;

procedure TDATFMXLanguageComboBox.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and not (csDestroying in ComponentState) and
    (AComponent = FLanguageManager) then
    FLanguageManager := nil;
end;

procedure TDATFMXLanguageComboBox.RefreshLanguages;
var
  Descriptor: TLanguagePackDescriptor;
  Descriptors: TObjectList<TLanguagePackDescriptor>;
  DisplayName: string;
begin
  if FLanguageManager = nil then
    Exit;
  Descriptors := FLanguageManager.AvailableLanguages;
  try
    FUpdating := True;
    try
      Items.BeginUpdate;
      try
        Items.Clear;
        FLanguageCodes.Clear;
        for Descriptor in Descriptors do
        begin
          DisplayName := Descriptor.NativeLanguageName;
          if FShowLanguageCode then
            DisplayName := Format('%s (%s)',
              [DisplayName, Descriptor.LanguageCode]);
          Items.Add(DisplayName);
          FLanguageCodes.Add(Descriptor.LanguageCode);
        end;
        SelectLanguageCode(FLanguageManager.ActiveLanguage);
      finally
        Items.EndUpdate;
      end;
    finally
      FUpdating := False;
    end;
  finally
    Descriptors.Free;
  end;
end;

function TDATFMXLanguageComboBox.SelectLanguageCode(
  const ALanguageCode: string): Boolean;
var
  LanguageIndex: Integer;
begin
  LanguageIndex := FLanguageCodes.IndexOf(ALanguageCode);
  Result := LanguageIndex >= 0;
  if Result then
  begin
    ItemIndex := LanguageIndex;
    if not FUpdating and (FLanguageManager <> nil) then
      Result := FLanguageManager.SelectLanguage(
        FLanguageCodes[LanguageIndex]);
  end;
end;

procedure TDATFMXLanguageComboBox.SetLanguageManager(
  const Value: TDATFMXLanguageManager);
begin
  if FLanguageManager = Value then
    Exit;
  if FLanguageManager <> nil then
    FLanguageManager.RemoveFreeNotification(Self);
  FLanguageManager := Value;
  if FLanguageManager <> nil then
    FLanguageManager.FreeNotification(Self);
  if FAutoPopulate and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) then
    RefreshLanguages;
end;

procedure TDATFMXLanguageComboBox.SetShowLanguageCode(
  const Value: Boolean);
begin
  if FShowLanguageCode = Value then
    Exit;
  FShowLanguageCode := Value;
  if FAutoPopulate and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) then
    RefreshLanguages;
end;

initialization
  RegisterClass(TDATFMXLanguageComboBox);

finalization
  UnregisterClass(TDATFMXLanguageComboBox);

end.
