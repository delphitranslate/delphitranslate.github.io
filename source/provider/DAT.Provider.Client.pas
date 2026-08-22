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
    FGlossaryId: string;
    FBatchSize: Integer;
    { Zero until the service first says "slower", then a short wait kept
      between requests for the rest of the run. Recovering from a rate limit
      costs seconds each time; not provoking one costs milliseconds. }
    FPacingMilliseconds: Integer;
  protected
    function Endpoint: string;
    function BuildRequestBody(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const AContext: string = ''): string;
    function ParseResponse(const AResponseText: string): TArray<string>;
    { The HTTP call itself. TranslateBatch wraps it so that no caller can
      reach the service without the format specifiers being protected. }
    function PostBatch(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const AContext: string): TArray<string>;
    function TranslateBatch(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const AContext: string = ''): TArray<string>;
  public
    constructor Create(const AProvider: TTranslationProvider;
      const ADeepLPlan: TDeepLPlan; const AApiKey: string;
      const ATimeoutSeconds, ABatchSize: Integer);
    { The identifier of a glossary already created on the service, or an
      empty string. The client neither creates nor deletes one, and
      nothing in the product sets this yet, so it is empty in every run
      today and glossary_id is not sent. See DAT.Provider.Glossary for
      what is built and what is still missing. }
    property GlossaryId: string read FGlossaryId write FGlossaryId;
    function Translate(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const ACancelCheck: TTranslationCancelCheck = nil;
      const AProgress: TTranslationProgressEvent = nil): TArray<string>;
    function TranslateWithContexts(const ATexts, AContexts: TArray<string>;
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
  System.Net.URLClient,
  DAT.Provider.Batching,
  DAT.Provider.CalendarTerms,
  DAT.Provider.LanguageCodes,
  DAT.Provider.Placeholders,
  DAT.Provider.Retry;

{ Both live in DAT.Provider.LanguageCodes now, where they can be tested
  without a service. The DeepL one used to keep whatever region the catalog
  named - ar-SA, es-ES - which DeepL rejects with a 400 that reads like a bad
  key. }
function NormalizeGoogleLanguageCode(const ACode: string): string;
begin
  Result := TProviderLanguageCodes.Google(ACode);
end;

function NormalizeDeepLLanguageCode(const ACode: string;
  const AIsTarget: Boolean): string;
begin
  Result := TProviderLanguageCodes.DeepL(ACode, AIsTarget);
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
  ATargetLanguage, AContext: string): string;
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
      if Trim(AContext) <> '' then
        JsonObject.AddPair('context', AContext);
      { A glossary held on the service's side binds it, where a context field
        only informs it. Sent only when one was created for this pair; the
        run translates perfectly well without one. }
      if Trim(FGlossaryId) <> '' then
        JsonObject.AddPair('glossary_id', FGlossaryId);
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

{ Every text that reaches a translation service passes through here.

  Two things happen before the request is built. A string that is nothing but
  format specifiers - "%.2d/%.2d" is a date, not a sentence - is never sent at
  all: there is nothing in it to translate, the engine can only damage it, and
  asking costs money. Everything else has its specifiers lifted out and
  replaced by tokens, so that what the engine sees contains nothing it can
  mistake for a percentage.

  And one thing happens after. The specifiers are put back, and the result is
  checked against the source. If they still do not match - the engine mangled
  the tokens themselves, or dropped them - the source text is returned instead
  of a translation that would make the application print "0.2f gigabytes" at
  its user. An English string among Arabic ones is visible in review; a broken
  format string is not visible until a customer sees it. }
function TTranslationProviderClient.TranslateBatch(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage, AContext: string): TArray<string>;
var
  Sendable: TArray<string>;
  SourceIndex: TArray<Integer>;
  Specifiers: TArray<TArray<string>>;
  Answers: TArray<string>;
  Restored: string;
  Resolved: string;
  Index: Integer;
  Sent: Integer;
begin
  SetLength(Result, Length(ATexts));
  SetLength(Specifiers, Length(ATexts));
  SetLength(Sendable, 0);
  SetLength(SourceIndex, 0);

  for Index := 0 to High(ATexts) do
  begin
    { A day or month name is a closed set the operating system already
      holds for every locale it supports. Sending one asks a service to
      translate three letters with no context, and it answers with
      whatever those letters mean as a word - which for several
      languages is a verb rather than a day. }
    if TCalendarTerms.TryResolve(ATexts[Index], ASourceLanguage,
      ATargetLanguage, Resolved) then
    begin
      Result[Index] := Resolved;
      Continue;
    end;
    if TPlaceholderProtection.IsOnlyPlaceholders(ATexts[Index]) then
    begin
      Result[Index] := ATexts[Index];
      Continue;
    end;
    Sent := Length(Sendable);
    SetLength(Sendable, Sent + 1);
    SetLength(SourceIndex, Sent + 1);
    Sendable[Sent] := TPlaceholderProtection.Protect(ATexts[Index],
      Specifiers[Index]);
    SourceIndex[Sent] := Index;
  end;

  if Length(Sendable) = 0 then
    Exit;

  Answers := PostBatch(Sendable, ASourceLanguage, ATargetLanguage, AContext);
  if Length(Answers) <> Length(Sendable) then
    raise ETranslationProviderError.Create(
      'The provider returned an unexpected number of translations.');

  for Sent := 0 to High(Answers) do
  begin
    Index := SourceIndex[Sent];
    Restored := TPlaceholderProtection.Restore(Answers[Sent],
      Specifiers[Index]);
    if TPlaceholderProtection.Matches(ATexts[Index], Restored) then
      Result[Index] := Restored
    else
      Result[Index] := ATexts[Index];
  end;
end;

{ What the service said, rather than a list of things it might have been.

  This used to read "Check the key, plan, billing, quota, language codes, and
  network connection" - six possibilities, one of them right, and no way to
  tell which. A DeepL 400 caused by sending ar-SA instead of AR looks exactly
  like a bad key from the outside.

  Both services return a message explaining the refusal. It was being thrown
  away. }
function DescribeRejection(const AProvider: TTranslationProvider;
  const AResponse: IHTTPResponse): string;
var
  Body: string;
  Root: TJSONValue;
  Detail: string;
begin
  Detail := '';
  try
    Body := AResponse.ContentAsString(TEncoding.UTF8);
    Root := TJSONObject.ParseJSONValue(Body);
    try
      if Root is TJSONObject then
      begin
        { DeepL answers with a message member at the top level; Google nests
          the same thing one level down under error. }
        Detail := TJSONObject(Root).GetValue<string>('message', '');
        if Detail = '' then
          Detail := TJSONObject(Root).GetValue<string>('error.message', '');
      end;
    finally
      Root.Free;
    end;
    if (Detail = '') and (Trim(Body) <> '') then
      Detail := Copy(Trim(Body), 1, 300);
  except
    { A refusal that is not JSON is still a refusal; say what is known. }
    Detail := '';
  end;

  Result := Format('%s rejected the request (HTTP %d %s).',
    [TranslationProviderDisplayName(AProvider), AResponse.StatusCode,
     AResponse.StatusText]);
  if Detail <> '' then
    Result := Result + ' It said: ' + Detail;

  case AResponse.StatusCode of
    400: Result := Result + ' A 400 is a malformed request rather than a ' +
           'refused key - most often a language code the service does not ' +
           'accept.';
    401, 403: Result := Result + ' Check the key, and that the plan selected ' +
           'here matches the key: a free key sent to the paid endpoint is ' +
           'refused exactly like a wrong one.';
    456: Result := Result + ' The character quota for this key is used up.';
  end;
end;

function TTranslationProviderClient.PostBatch(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage, AContext: string): TArray<string>;
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
    for Attempt := 1 to TProviderRetry.MaximumAttempts do
    begin
      { Whatever pace the run has settled into. }
      if FPacingMilliseconds > 0 then
        TThread.Sleep(FPacingMilliseconds);

      Content := TStringStream.Create(
        BuildRequestBody(ATexts, ASourceLanguage, ATargetLanguage, AContext),
        TEncoding.UTF8);
      try
        Response := Client.Post(Endpoint, Content, nil, Headers);
      finally
        Content.Free;
      end;
      if (Response.StatusCode >= 200) and
         (Response.StatusCode < 300) then
        Exit(ParseResponse(Response.ContentAsString(TEncoding.UTF8)));

      if not TProviderRetry.IsWorthRetrying(Response.StatusCode) or
        (Attempt = TProviderRetry.MaximumAttempts) then
        raise ETranslationProviderError.Create(
          DescribeRejection(FProvider, Response), Response.StatusCode);

      { Having been told once that the pace is too fast, slow down for the
        rest of the run rather than waiting out the same refusal again and
        again. }
      if (Response.StatusCode = 429) and (FPacingMilliseconds < 1000) then
        FPacingMilliseconds := FPacingMilliseconds + 250;

      TThread.Sleep(TProviderRetry.DelayMilliseconds(Attempt,
        Response.HeaderValue['Retry-After']));
    end;
  finally
    Client.Free;
  end;
end;

{ Each string sent with the context that belongs to it.

  A service takes one context per request, and this used to batch fifty
  strings and concatenate all fifty contexts into that one field - so every
  string arrived wearing forty-nine descriptions of other controls. The
  context was generated, paid for in nothing, and diluted into uselessness.

  Billing is per translated character rather than per request, so grouping by
  shared context costs exactly what batching cost. Strings that share a
  context still travel together; a string with a context of its own goes on
  its own. }
function TTranslationProviderClient.TranslateWithContexts(
  const ATexts, AContexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage: string; const ACancelCheck: TTranslationCancelCheck;
  const AProgress: TTranslationProgressEvent): TArray<string>;
var
  Groups: TArray<TContextGroup>;
  Group: TContextGroup;
  Batch: TArray<string>;
  BatchResults: TArray<string>;
  Completed: Integer;
  Index: Integer;
begin
  if Length(AContexts) <> Length(ATexts) then
    raise EArgumentException.Create(
      'Each source string must have one contextual description.');
  SetLength(Result, Length(ATexts));
  Groups := TContextBatching.Group(ATexts, AContexts, FBatchSize);
  Completed := 0;
  for Group in Groups do
  begin
    if Assigned(ACancelCheck) and ACancelCheck() then
      raise TTranslationCancelled.Create('Translation was cancelled.');
    SetLength(Batch, Length(Group.Indexes));
    for Index := 0 to High(Group.Indexes) do
      Batch[Index] := ATexts[Group.Indexes[Index]];
    BatchResults := TranslateBatch(Batch, ASourceLanguage, ATargetLanguage,
      Trim(Group.Context));
    if Length(BatchResults) <> Length(Batch) then
      raise ETranslationProviderError.Create(
        'The provider returned an unexpected number of translations.');
    for Index := 0 to High(Group.Indexes) do
      Result[Group.Indexes[Index]] := BatchResults[Index];
    Inc(Completed, Length(Group.Indexes));
    if Assigned(AProgress) then
      AProgress(Completed, Length(ATexts));
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
