unit DAT.Provider.Client;

interface

uses
  System.Classes,
  System.SysUtils,
  DAT.Provider.Types;

type
  TTranslationCancelled = class(Exception);
  TTranslationCancelCheck = reference to function: Boolean;
  TTranslationProgressEvent = reference to procedure(
    const ACompleted, ATotal: Integer);

  TTranslationProviderClient = class
  private
    FProvider: TTranslationProvider;
    FDeepLPlan: TDeepLPlan;
    FApiKey: string;
    FTimeoutSeconds: Integer;
    FBatchSize: Integer;
  protected
    function Endpoint: string;
    function BuildRequestBody(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string): string;
    function ParseResponse(const AResponseText: string): TArray<string>;
    function TranslateBatch(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string): TArray<string>;
  public
    constructor Create(const AProvider: TTranslationProvider;
      const ADeepLPlan: TDeepLPlan; const AApiKey: string;
      const ATimeoutSeconds, ABatchSize: Integer);
    function Translate(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const ACancelCheck: TTranslationCancelCheck = nil;
      const AProgress: TTranslationProgressEvent = nil): TArray<string>;
    procedure TestConnection;
  end;

implementation

uses
  System.Generics.Collections,
  System.JSON,
  System.Math,
  System.Net.HttpClient,
  System.Net.URLClient;

function NormalizeGoogleLanguageCode(const ACode: string): string;
var
  SeparatorPosition: Integer;
begin
  Result := Trim(ACode);
  SeparatorPosition := Pos('-', Result);
  if SeparatorPosition > 0 then
    Result := Copy(Result, 1, SeparatorPosition - 1);
end;

function NormalizeDeepLLanguageCode(const ACode: string;
  const AIsTarget: Boolean): string;
begin
  Result := UpperCase(StringReplace(Trim(ACode), '_', '-',
    [rfReplaceAll]));
  if not AIsTarget then
    Result := Copy(Result, 1, 2);
end;

constructor TTranslationProviderClient.Create(
  const AProvider: TTranslationProvider; const ADeepLPlan: TDeepLPlan;
  const AApiKey: string; const ATimeoutSeconds, ABatchSize: Integer);
begin
  inherited Create;
  if Trim(AApiKey) = '' then
    raise ETranslationProviderError.Create(
      'Enter or save an API key before connecting.');
  FProvider := AProvider;
  FDeepLPlan := ADeepLPlan;
  FApiKey := Trim(AApiKey);
  FTimeoutSeconds := EnsureRange(ATimeoutSeconds, 5, 300);
  FBatchSize := EnsureRange(ABatchSize, 1, 50);
end;

function TTranslationProviderClient.Endpoint: string;
begin
  if FProvider = tpGoogle then
    Result := 'https://translation.googleapis.com/language/translate/v2'
  else if FDeepLPlan = dpPro then
    Result := 'https://api.deepl.com/v2/translate'
  else
    Result := 'https://api-free.deepl.com/v2/translate';
end;

function TTranslationProviderClient.BuildRequestBody(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage: string): string;
var
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
  TextValue: string;
begin
  JsonObject := TJSONObject.Create;
  try
    JsonArray := TJSONArray.Create;
    for TextValue in ATexts do
      JsonArray.Add(TextValue);
    if FProvider = tpGoogle then
    begin
      JsonObject.AddPair('q', JsonArray);
      JsonObject.AddPair('source',
        NormalizeGoogleLanguageCode(ASourceLanguage));
      JsonObject.AddPair('target',
        NormalizeGoogleLanguageCode(ATargetLanguage));
      JsonObject.AddPair('format', 'text');
    end
    else
    begin
      JsonObject.AddPair('text', JsonArray);
      JsonObject.AddPair('source_lang',
        NormalizeDeepLLanguageCode(ASourceLanguage, False));
      JsonObject.AddPair('target_lang',
        NormalizeDeepLLanguageCode(ATargetLanguage, True));
    end;
    Result := JsonObject.ToJSON;
  finally
    JsonObject.Free;
  end;
end;

function TTranslationProviderClient.ParseResponse(
  const AResponseText: string): TArray<string>;
var
  DataObject: TJSONObject;
  Index: Integer;
  ItemObject: TJSONObject;
  JsonArray: TJSONArray;
  JsonValue: TJSONValue;
  RootObject: TJSONObject;
begin
  JsonValue := TJSONObject.ParseJSONValue(AResponseText);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise ETranslationProviderError.Create(
      'The translation provider returned an invalid JSON response.');
  end;
  RootObject := TJSONObject(JsonValue);
  try
    if FProvider = tpGoogle then
    begin
      DataObject := RootObject.GetValue('data') as TJSONObject;
      if DataObject = nil then
        raise ETranslationProviderError.Create(
          'Google returned a response without translation data.');
      JsonArray := DataObject.GetValue('translations') as TJSONArray;
    end
    else
      JsonArray := RootObject.GetValue('translations') as TJSONArray;
    if JsonArray = nil then
      raise ETranslationProviderError.Create(
        'The provider response did not contain translations.');
    SetLength(Result, JsonArray.Count);
    for Index := 0 to JsonArray.Count - 1 do
    begin
      ItemObject := JsonArray.Items[Index] as TJSONObject;
      Result[Index] := ItemObject.GetValue<string>('translatedText', '');
      if Result[Index] = '' then
        Result[Index] := ItemObject.GetValue<string>('text', '');
    end;
  finally
    RootObject.Free;
  end;
end;

function TTranslationProviderClient.TranslateBatch(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage: string): TArray<string>;
var
  Attempt: Integer;
  Client: THTTPClient;
  Content: TStringStream;
  Headers: TNetHeaders;
  Response: IHTTPResponse;
begin
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := FTimeoutSeconds * 1000;
    Client.ResponseTimeout := FTimeoutSeconds * 1000;
    SetLength(Headers, 2);
    Headers[0].Name := 'Content-Type';
    Headers[0].Value := 'application/json; charset=utf-8';
    if FProvider = tpGoogle then
    begin
      Headers[1].Name := 'X-Goog-Api-Key';
      Headers[1].Value := FApiKey;
    end
    else
    begin
      Headers[1].Name := 'Authorization';
      Headers[1].Value := 'DeepL-Auth-Key ' + FApiKey;
    end;
    for Attempt := 1 to 3 do
    begin
      Content := TStringStream.Create(
        BuildRequestBody(ATexts, ASourceLanguage, ATargetLanguage),
        TEncoding.UTF8);
      try
        Response := Client.Post(Endpoint, Content, nil, Headers);
      finally
        Content.Free;
      end;
      if (Response.StatusCode >= 200) and
         (Response.StatusCode < 300) then
        Exit(ParseResponse(Response.ContentAsString(TEncoding.UTF8)));
      if not ((Response.StatusCode = 429) or
        (Response.StatusCode >= 500)) or (Attempt = 3) then
        raise ETranslationProviderError.Create(Format(
          '%s rejected the request (HTTP %d %s). Check the key, plan, billing, quota, language codes, and network connection.',
          [TranslationProviderDisplayName(FProvider),
           Response.StatusCode, Response.StatusText]),
          Response.StatusCode);
      TThread.Sleep(Attempt * 300);
    end;
  finally
    Client.Free;
  end;
end;

function TTranslationProviderClient.Translate(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage: string; const ACancelCheck: TTranslationCancelCheck;
  const AProgress: TTranslationProgressEvent): TArray<string>;
var
  Batch: TArray<string>;
  BatchCount: Integer;
  BatchResults: TArray<string>;
  Completed: Integer;
  Index: Integer;
  ResultIndex: Integer;
begin
  SetLength(Result, Length(ATexts));
  Completed := 0;
  while Completed < Length(ATexts) do
  begin
    if Assigned(ACancelCheck) and ACancelCheck() then
      raise TTranslationCancelled.Create('Translation was cancelled.');
    BatchCount := Min(FBatchSize, Length(ATexts) - Completed);
    SetLength(Batch, BatchCount);
    for Index := 0 to BatchCount - 1 do
      Batch[Index] := ATexts[Completed + Index];
    BatchResults := TranslateBatch(Batch,
      ASourceLanguage, ATargetLanguage);
    if Length(BatchResults) <> BatchCount then
      raise ETranslationProviderError.Create(
        'The provider returned an unexpected number of translations.');
    for Index := 0 to BatchCount - 1 do
    begin
      ResultIndex := Completed + Index;
      Result[ResultIndex] := BatchResults[Index];
    end;
    Inc(Completed, BatchCount);
    if Assigned(AProgress) then
      AProgress(Completed, Length(ATexts));
  end;
end;

procedure TTranslationProviderClient.TestConnection;
var
  TestSource: TArray<string>;
  TestResult: TArray<string>;
begin
  SetLength(TestSource, 1);
  TestSource[0] := 'Connection test';
  TestResult := Translate(TestSource, 'en', 'it');
  if (Length(TestResult) <> 1) or (Trim(TestResult[0]) = '') then
    raise ETranslationProviderError.Create(
      'The provider returned no text for the connection test.');
end;

end.
