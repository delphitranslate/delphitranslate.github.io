unit DAT.Provider.Settings;

interface

uses
  DAT.Provider.Types;

type
  TProviderSettings = class
  private
    FProvider: TTranslationProvider;
    FDeepLPlan: TDeepLPlan;
    FRememberCredential: Boolean;
    FRequestTimeoutSeconds: Integer;
    FBatchSize: Integer;
  public
    constructor Create;
    class function DefaultFileName: string; static;
    class function Load: TProviderSettings; static;
    procedure Save;
    property Provider: TTranslationProvider read FProvider write FProvider;
    property DeepLPlan: TDeepLPlan read FDeepLPlan write FDeepLPlan;
    property RememberCredential: Boolean read FRememberCredential
      write FRememberCredential;
    property RequestTimeoutSeconds: Integer read FRequestTimeoutSeconds
      write FRequestTimeoutSeconds;
    property BatchSize: Integer read FBatchSize write FBatchSize;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  DAT.Core.AtomicFile,
  DAT.Core.Diagnostics;

procedure ValidateProviderSettingsText(const AText: string);
var
  JsonValue: TJSONValue;
begin
  JsonValue := TJSONObject.ParseJSONValue(AText);
  try
    if not (JsonValue is TJSONObject) then
      raise EConvertError.Create('Provider settings are not a JSON object.');
  finally
    JsonValue.Free;
  end;
end;

constructor TProviderSettings.Create;
begin
  inherited Create;
  FProvider := tpDeepL;
  FDeepLPlan := dpFree;
  FRememberCredential := True;
  FRequestTimeoutSeconds := 30;
  FBatchSize := 40;
end;

class function TProviderSettings.DefaultFileName: string;
var
  LocalApplicationData: string;
begin
  LocalApplicationData := GetEnvironmentVariable('LOCALAPPDATA');
  if LocalApplicationData = '' then
    LocalApplicationData := TPath.GetHomePath;
  Result := TPath.Combine(LocalApplicationData,
    'DelphiAppTranslationStudio\provider-settings.json');
end;

class function TProviderSettings.Load: TProviderSettings;
var
  FileName: string;
  JsonObject: TJSONObject;
  JsonValue: TJSONValue;
  JsonText: string;
  Recovered: Boolean;
begin
  Result := TProviderSettings.Create;
  FileName := DefaultFileName;
  if not TFile.Exists(FileName) then
    Exit;
  JsonText := TAtomicTextFile.ReadAllText(FileName, TEncoding.UTF8,
    ValidateProviderSettingsText, Recovered);
  if Recovered then
    TDATDiagnostics.Log('DAT-PROVIDER-SETTINGS-RECOVERY-001', 'Load',
      'Recovered the prior valid provider settings and quarantined the invalid file: ' +
      FileName, dsWarning);
  JsonValue := TJSONObject.ParseJSONValue(JsonText);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    Exit;
  end;
  JsonObject := TJSONObject(JsonValue);
  try
    Result.Provider := StringToTranslationProvider(
      JsonObject.GetValue<string>('provider', 'deepl'));
    Result.DeepLPlan := StringToDeepLPlan(
      JsonObject.GetValue<string>('deepLPlan', 'free'));
    Result.RememberCredential :=
      JsonObject.GetValue<Boolean>('rememberCredential', True);
    Result.RequestTimeoutSeconds :=
      JsonObject.GetValue<Integer>('requestTimeoutSeconds', 30);
    Result.BatchSize := JsonObject.GetValue<Integer>('batchSize', 40);
    if Result.RequestTimeoutSeconds < 5 then
      Result.RequestTimeoutSeconds := 5;
    if Result.BatchSize < 1 then
      Result.BatchSize := 1;
  finally
    JsonObject.Free;
  end;
end;

procedure TProviderSettings.Save;
var
  DirectoryName: string;
  JsonObject: TJSONObject;
begin
  JsonObject := TJSONObject.Create;
  try
    JsonObject.AddPair('provider',
      TranslationProviderToString(FProvider));
    JsonObject.AddPair('deepLPlan', DeepLPlanToString(FDeepLPlan));
    JsonObject.AddPair('rememberCredential',
      TJSONBool.Create(FRememberCredential));
    JsonObject.AddPair('requestTimeoutSeconds',
      TJSONNumber.Create(FRequestTimeoutSeconds));
    JsonObject.AddPair('batchSize', TJSONNumber.Create(FBatchSize));
    DirectoryName := TPath.GetDirectoryName(DefaultFileName);
    TDirectory.CreateDirectory(DirectoryName);
    TAtomicTextFile.WriteAllText(DefaultFileName,
      JsonObject.ToJSON, TEncoding.UTF8, ValidateProviderSettingsText);
  finally
    JsonObject.Free;
  end;
end;

end.
