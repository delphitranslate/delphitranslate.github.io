unit DAT.Runtime.LanguagePack;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils;

type
  ELanguagePackError = class(Exception);

  TRuntimeLocale = class
  private
    FShortDateFormat: string;
    FLongDateFormat: string;
    FShortTimeFormat: string;
    FLongTimeFormat: string;
    FDecimalSeparator: string;
    FThousandSeparator: string;
    FCurrencySymbol: string;
  public
    property ShortDateFormat: string read FShortDateFormat write FShortDateFormat;
    property LongDateFormat: string read FLongDateFormat write FLongDateFormat;
    property ShortTimeFormat: string read FShortTimeFormat write FShortTimeFormat;
    property LongTimeFormat: string read FLongTimeFormat write FLongTimeFormat;
    property DecimalSeparator: string read FDecimalSeparator write FDecimalSeparator;
    property ThousandSeparator: string read FThousandSeparator write FThousandSeparator;
    property CurrencySymbol: string read FCurrencySymbol write FCurrencySymbol;
  end;

  TRuntimeLayoutRule = class
  private
    FFormName: string;
    FComponentName: string;
    FPropertyName: string;
    FOriginalValue: string;
    FTranslatedValue: string;
    FSourceChecksum: string;
  public
    property FormName: string read FFormName write FFormName;
    property ComponentName: string read FComponentName write FComponentName;
    property PropertyName: string read FPropertyName write FPropertyName;
    property OriginalValue: string read FOriginalValue write FOriginalValue;
    property TranslatedValue: string read FTranslatedValue write FTranslatedValue;
    property SourceChecksum: string read FSourceChecksum write FSourceChecksum;
  end;

  TRuntimeLanguagePack = class
  private
    FSchemaVersion: Integer;
    FApplicationId: string;
    FApplicationVersion: string;
    FFramework: string;
    FSourceLanguage: string;
    FSourceCatalogChecksum: string;
    FLanguageCode: string;
    FNativeLanguageName: string;
    FTextDirection: string;
    FLocale: TRuntimeLocale;
    FStrings: TDictionary<string, string>;
    FTemplates: TDictionary<string, string>;
    FSources: TDictionary<string, string>;
    FSourceStrings: TDictionary<string, string>;
    FSourceTemplates: TDictionary<string, string>;
    FTranslatedStrings: TDictionary<string, Boolean>;
    FLayoutRules: TObjectList<TRuntimeLayoutRule>;
    FFontColors: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    class function LoadFromJson(const AJsonText: string): TRuntimeLanguagePack; static;
    class function LoadFromFile(const AFileName: string): TRuntimeLanguagePack; static;
    function TryGetText(const AKey: string; out AText: string): Boolean;
    function GetText(const AKey, AFallbackText: string): string;
    function TryGetTemplate(const AKey: string; out AText: string): Boolean;
    function TryGetSource(const AKey: string; out AText: string): Boolean;
    function TryTranslateSource(const ASourceText: string;
      out ATranslatedText: string): Boolean;
    function TryTranslateDynamicText(const ASourceText: string;
      out ATranslatedText: string): Boolean;
    function GetTemplate(const AKey, AFallbackText: string): string;
    function GetAnyText(const AKey, AFallbackText: string): string;
    function FormatTemplate(const AKey, AFallbackText: string;
      const AArgs: array of const): string;
    function ReadIndexedStrings(const AKeyPrefix: string;
      const AValues: TStrings): Integer;
    property SchemaVersion: Integer read FSchemaVersion;
    property ApplicationId: string read FApplicationId;
    property ApplicationVersion: string read FApplicationVersion;
    property Framework: string read FFramework;
    property SourceLanguage: string read FSourceLanguage;
    property SourceCatalogChecksum: string read FSourceCatalogChecksum;
    property LanguageCode: string read FLanguageCode;
    property NativeLanguageName: string read FNativeLanguageName;
    property TextDirection: string read FTextDirection;
    property Locale: TRuntimeLocale read FLocale;
    property Strings: TDictionary<string, string> read FStrings;
    property Templates: TDictionary<string, string> read FTemplates;
    property Sources: TDictionary<string, string> read FSources;
    property SourceStrings: TDictionary<string, string> read FSourceStrings;
    property SourceTemplates: TDictionary<string, string> read FSourceTemplates;
    property LayoutRules: TObjectList<TRuntimeLayoutRule> read FLayoutRules;
    property FontColors: TDictionary<string, string> read FFontColors;
  end;

  TLanguagePackDescriptor = class
  private
    FFileName: string;
    FLanguageCode: string;
    FNativeLanguageName: string;
    FTextDirection: string;
    FSourceLanguage: string;
  public
    property FileName: string read FFileName write FFileName;
    property LanguageCode: string read FLanguageCode write FLanguageCode;
    property NativeLanguageName: string read FNativeLanguageName write FNativeLanguageName;
    property TextDirection: string read FTextDirection write FTextDirection;
    property SourceLanguage: string read FSourceLanguage write FSourceLanguage;
  end;

  TLanguagePackDiscovery = class
  public
    class function Discover(const ADirectoryName,
      AExpectedApplicationId: string): TObjectList<TLanguagePackDescriptor>; static;
  end;

function CanonicalNativeLanguageName(const ALanguageCode,
  AFallbackName: string): string;

implementation

uses
  System.Generics.Defaults,
  System.IOUtils,
  System.JSON,
  System.StrUtils;

function CanonicalNativeLanguageName(const ALanguageCode,
  AFallbackName: string): string;
var
  BaseCode: string;
  SeparatorPosition: Integer;
begin
  BaseCode := LowerCase(Trim(ALanguageCode));
  SeparatorPosition := Pos('-', BaseCode);
  if SeparatorPosition > 0 then
    BaseCode := Copy(BaseCode, 1, SeparatorPosition - 1);
  if BaseCode = 'en' then
    Result := 'English'
  else if BaseCode = 'es' then
    Result := 'Espa' + #$00F1 + 'ol'
  else if BaseCode = 'fr' then
    Result := 'Fran' + #$00E7 + 'ais'
  else if BaseCode = 'de' then
    Result := 'Deutsch'
  else if BaseCode = 'it' then
    Result := 'Italiano'
  else if BaseCode = 'pt' then
    Result := 'Portugu' + #$00EA + 's'
  else if BaseCode = 'nl' then
    Result := 'Nederlands'
  else if BaseCode = 'pl' then
    Result := 'Polski'
  else if BaseCode = 'sv' then
    Result := 'Svenska'
  else if BaseCode = 'da' then
    Result := 'Dansk'
  else if BaseCode = 'no' then
    Result := 'Norsk'
  else if BaseCode = 'fi' then
    Result := 'Suomi'
  else if BaseCode = 'bg' then
    Result := #$0411 + #$044A + #$043B + #$0433 + #$0430 + #$0440 +
      #$0441 + #$043A + #$0438
  else if BaseCode = 'hr' then
    Result := 'Hrvatski'
  else if BaseCode = 'cs' then
    Result := #$010C + 'e' + #$0161 + 'tina'
  else if BaseCode = 'et' then
    Result := 'Eesti'
  else if BaseCode = 'el' then
    Result := #$0395 + #$03BB + #$03BB + #$03B7 + #$03BD + #$03B9 +
      #$03BA + #$03AC
  else if BaseCode = 'he' then
    Result := #$05E2 + #$05D1 + #$05E8 + #$05D9 + #$05EA
  else if BaseCode = 'hi' then
    Result := #$0939 + #$093F + #$0928 + #$094D + #$0926 + #$0940
  else if BaseCode = 'hu' then
    Result := 'Magyar'
  else if BaseCode = 'id' then
    Result := 'Bahasa Indonesia'
  else if BaseCode = 'lv' then
    Result := 'Latvie' + #$0161 + 'u'
  else if BaseCode = 'lt' then
    Result := 'Lietuvi' + #$0173
  else if BaseCode = 'nb' then
    Result := 'Norsk bokm' + #$00E5 + 'l'
  else if BaseCode = 'fa' then
    Result := #$0641 + #$0627 + #$0631 + #$0633 + #$06CC
  else if BaseCode = 'ro' then
    Result := 'Rom' + #$00E2 + 'n' + #$0103
  else if BaseCode = 'ru' then
    Result := #$0420 + #$0443 + #$0441 + #$0441 + #$043A + #$0438 + #$0439
  else if BaseCode = 'sr' then
    Result := 'Srpski'
  else if BaseCode = 'sk' then
    Result := 'Sloven' + #$010D + 'ina'
  else if BaseCode = 'sl' then
    Result := 'Sloven' + #$0161 + #$010D + 'ina'
  else if BaseCode = 'th' then
    Result := #$0E44 + #$0E17 + #$0E22
  else if BaseCode = 'tr' then
    Result := 'T' + #$00FC + 'rk' + #$00E7 + 'e'
  else if BaseCode = 'uk' then
    Result := #$0423 + #$043A + #$0440 + #$0430 + #$0457 + #$043D +
      #$0441 + #$044C + #$043A + #$0430
  else if BaseCode = 'ur' then
    Result := #$0627 + #$0631 + #$062F + #$0648
  else if BaseCode = 'vi' then
    Result := 'Ti' + #$1EBF + 'ng Vi' + #$1EC7 + 't'
  else if BaseCode = 'ja' then
    Result := #$65E5 + #$672C + #$8A9E
  else if BaseCode = 'ko' then
    Result := #$D55C + #$AD6D + #$C5B4
  else if BaseCode = 'zh' then
    Result := #$4E2D + #$6587
  else if BaseCode = 'ar' then
    Result := #$0627 + #$0644 + #$0639 + #$0631 + #$0628 + #$064A + #$0629
  else
    Result := Trim(AFallbackName);
  if Result = '' then
    Result := ALanguageCode;
end;

function BaseLanguageCode(const ALanguageCode: string): string;
var
  SeparatorPosition: Integer;
begin
  Result := LowerCase(Trim(ALanguageCode));
  SeparatorPosition := Pos('-', Result);
  if SeparatorPosition > 0 then
    Result := Copy(Result, 1, SeparatorPosition - 1);
end;

function RequiredObject(const AParent: TJSONObject;
  const AName: string): TJSONObject;
begin
  Result := AParent.GetValue(AName) as TJSONObject;
  if Result = nil then
    raise ELanguagePackError.CreateFmt(
      'The runtime language pack is missing the "%s" object.', [AName]);
end;

function JsonString(const AObject: TJSONObject;
  const AName: string; const ARequired: Boolean = False): string;
var
  JsonValue: TJSONValue;
begin
  Result := '';
  JsonValue := AObject.GetValue(AName);
  if JsonValue <> nil then
    Result := JsonValue.Value
  else if ARequired then
    raise ELanguagePackError.CreateFmt(
      'The runtime language pack is missing "%s".', [AName]);
end;

constructor TRuntimeLanguagePack.Create;
begin
  inherited Create;
  FLocale := TRuntimeLocale.Create;
  FStrings := TDictionary<string, string>.Create;
  FTemplates := TDictionary<string, string>.Create;
  FSources := TDictionary<string, string>.Create;
  FSourceStrings := TDictionary<string, string>.Create;
  FSourceTemplates := TDictionary<string, string>.Create;
  FTranslatedStrings := TDictionary<string, Boolean>.Create;
  FLayoutRules := TObjectList<TRuntimeLayoutRule>.Create(True);
  FFontColors := TDictionary<string, string>.Create;
end;

destructor TRuntimeLanguagePack.Destroy;
begin
  FLayoutRules.Free;
  FFontColors.Free;
  FTranslatedStrings.Free;
  FSourceTemplates.Free;
  FSourceStrings.Free;
  FSources.Free;
  FTemplates.Free;
  FStrings.Free;
  FLocale.Free;
  inherited Destroy;
end;

class function TRuntimeLanguagePack.LoadFromJson(
  const AJsonText: string): TRuntimeLanguagePack;
var
  JsonPair: TJSONPair;
  LayoutArray: TJSONArray;
  LayoutItem: TJSONValue;
  LayoutObject: TJSONObject;
  LayoutRule: TRuntimeLayoutRule;
  JsonRoot: TJSONObject;
  JsonValue: TJSONValue;
  LanguageObject: TJSONObject;
  LocaleObject: TJSONObject;
  StringsObject: TJSONObject;
  SourcesObject: TJSONObject;
  SourceStringsObject: TJSONObject;
  SourceTemplatesObject: TJSONObject;
  TemplatesObject: TJSONObject;
  FontColorsObject: TJSONObject;
begin
  JsonValue := TJSONObject.ParseJSONValue(AJsonText);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise ELanguagePackError.Create(
      'The runtime language pack root must be a JSON object.');
  end;

  JsonRoot := TJSONObject(JsonValue);
  try
    Result := TRuntimeLanguagePack.Create;
    try
      Result.FSchemaVersion := JsonRoot.GetValue<Integer>('schemaVersion', 0);
      if not (Result.FSchemaVersion in [1, 2, 3]) then
        raise ELanguagePackError.CreateFmt(
          'Runtime language-pack schema %d is not supported.',
          [Result.FSchemaVersion]);

      Result.FApplicationId := JsonString(JsonRoot, 'applicationId', True);
      Result.FApplicationVersion := JsonString(JsonRoot, 'applicationVersion');
      Result.FFramework := JsonString(JsonRoot, 'framework', True);
      Result.FSourceLanguage := JsonString(JsonRoot, 'sourceLanguage', True);
      Result.FSourceCatalogChecksum :=
        JsonString(JsonRoot, 'sourceCatalogChecksum', True);

      LanguageObject := RequiredObject(JsonRoot, 'language');
      Result.FLanguageCode := JsonString(LanguageObject, 'code', True);
      Result.FNativeLanguageName :=
        JsonString(LanguageObject, 'nativeName', True);
      Result.FTextDirection := JsonString(LanguageObject, 'direction');

      LocaleObject := RequiredObject(JsonRoot, 'locale');
      Result.FLocale.ShortDateFormat :=
        JsonString(LocaleObject, 'shortDateFormat');
      Result.FLocale.LongDateFormat :=
        JsonString(LocaleObject, 'longDateFormat');
      Result.FLocale.ShortTimeFormat :=
        JsonString(LocaleObject, 'shortTimeFormat');
      Result.FLocale.LongTimeFormat :=
        JsonString(LocaleObject, 'longTimeFormat');
      Result.FLocale.DecimalSeparator :=
        JsonString(LocaleObject, 'decimalSeparator');
      Result.FLocale.ThousandSeparator :=
        JsonString(LocaleObject, 'thousandSeparator');
      Result.FLocale.CurrencySymbol :=
        JsonString(LocaleObject, 'currencySymbol');

      StringsObject := RequiredObject(JsonRoot, 'strings');
      for JsonPair in StringsObject do
        Result.FStrings.AddOrSetValue(JsonPair.JsonString.Value,
          JsonPair.JsonValue.Value);
      TemplatesObject := JsonRoot.GetValue('templates') as TJSONObject;
      if TemplatesObject <> nil then
        for JsonPair in TemplatesObject do
          Result.FTemplates.AddOrSetValue(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
      SourcesObject := JsonRoot.GetValue('sources') as TJSONObject;
      if SourcesObject <> nil then
        for JsonPair in SourcesObject do
          Result.FSources.AddOrSetValue(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
      SourceStringsObject := JsonRoot.GetValue('sourceStrings') as TJSONObject;
      if SourceStringsObject <> nil then
        for JsonPair in SourceStringsObject do
        begin
          Result.FSourceStrings.AddOrSetValue(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
          if JsonPair.JsonValue.Value <> '' then
            Result.FTranslatedStrings.AddOrSetValue(
              JsonPair.JsonValue.Value, True);
        end;
      SourceTemplatesObject := JsonRoot.GetValue('sourceTemplates') as TJSONObject;
      if SourceTemplatesObject <> nil then
        for JsonPair in SourceTemplatesObject do
          Result.FSourceTemplates.AddOrSetValue(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
      LayoutArray := JsonRoot.GetValue('layout') as TJSONArray;
      if LayoutArray <> nil then
        for LayoutItem in LayoutArray do
          if LayoutItem is TJSONObject then
          begin
            LayoutObject := TJSONObject(LayoutItem);
            LayoutRule := TRuntimeLayoutRule.Create;
            LayoutRule.FormName := JsonString(LayoutObject, 'formName', True);
            LayoutRule.ComponentName := JsonString(LayoutObject,
              'componentName', True);
            LayoutRule.PropertyName := JsonString(LayoutObject,
              'propertyName', True);
            LayoutRule.OriginalValue := JsonString(LayoutObject,
              'originalValue', True);
            LayoutRule.TranslatedValue := JsonString(LayoutObject,
              'translatedValue', True);
            LayoutRule.SourceChecksum := JsonString(LayoutObject,
              'sourceChecksum', True);
            Result.FLayoutRules.Add(LayoutRule);
          end;
      FontColorsObject := JsonRoot.GetValue('fontColors') as TJSONObject;
      if FontColorsObject <> nil then
        for JsonPair in FontColorsObject do
          Result.FFontColors.AddOrSetValue(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
    except
      Result.Free;
      raise;
    end;
  finally
    JsonRoot.Free;
  end;
end;

class function TRuntimeLanguagePack.LoadFromFile(
  const AFileName: string): TRuntimeLanguagePack;
begin
  if not TFile.Exists(AFileName) then
    raise ELanguagePackError.CreateFmt(
      'Runtime language pack not found: %s', [AFileName]);
  Result := LoadFromJson(TFile.ReadAllText(AFileName, TEncoding.UTF8));
end;

function TRuntimeLanguagePack.TryGetText(
  const AKey: string; out AText: string): Boolean;
begin
  Result := FStrings.TryGetValue(AKey, AText) and (AText <> '');
end;

function TRuntimeLanguagePack.GetText(
  const AKey, AFallbackText: string): string;
begin
  if not TryGetText(AKey, Result) then
    Result := AFallbackText;
end;

function TRuntimeLanguagePack.TryGetTemplate(
  const AKey: string; out AText: string): Boolean;
begin
  Result := FTemplates.TryGetValue(AKey, AText) and (AText <> '');
end;

function TRuntimeLanguagePack.TryGetSource(
  const AKey: string; out AText: string): Boolean;
begin
  Result := FSources.TryGetValue(AKey, AText) and (AText <> '');
end;

function TRuntimeLanguagePack.TryTranslateSource(const ASourceText: string;
  out ATranslatedText: string): Boolean;
begin
  Result := FSourceStrings.TryGetValue(ASourceText, ATranslatedText) and
    (ATranslatedText <> '');
end;

function IsFormatConversion(const AValue: Char): Boolean;
begin
  Result := CharInSet(AValue,
    ['d', 'i', 'u', 'o', 'x', 'X', 'f', 'F', 'e', 'E', 'g', 'G',
     'a', 'A', 'c', 's', 'p', 'n']);
end;

procedure ParseFormatTemplate(const ATemplate: string;
  const ALiterals, APlaceholders: TStrings);
var
  Index: Integer;
  LiteralText: string;
  PlaceholderText: string;
begin
  ALiterals.Clear;
  APlaceholders.Clear;
  LiteralText := '';
  Index := 1;
  while Index <= Length(ATemplate) do
  begin
    if ATemplate[Index] <> '%' then
    begin
      LiteralText := LiteralText + ATemplate[Index];
      Inc(Index);
      Continue;
    end;
    if (Index < Length(ATemplate)) and (ATemplate[Index + 1] = '%') then
    begin
      LiteralText := LiteralText + '%';
      Inc(Index, 2);
      Continue;
    end;
    ALiterals.Add(LiteralText);
    LiteralText := '';
    PlaceholderText := '%';
    Inc(Index);
    while Index <= Length(ATemplate) do
    begin
      PlaceholderText := PlaceholderText + ATemplate[Index];
      if IsFormatConversion(ATemplate[Index]) then
      begin
        Inc(Index);
        Break;
      end;
      Inc(Index);
    end;
    APlaceholders.Add(PlaceholderText);
  end;
  ALiterals.Add(LiteralText);
end;

function TryApplyFormatTemplate(const ACurrentText, ASourceTemplate,
  ATranslatedTemplate: string; out ATranslatedText: string): Boolean;
var
  Captures: TStringList;
  CurrentAt: Integer;
  Index: Integer;
  LiteralAt: Integer;
  MatchEnd: Integer;
  MatchStart: Integer;
  NextLiteral: string;
  OutputText: string;
  SourceLiterals: TStringList;
  SourcePlaceholders: TStringList;
  TranslatedLiterals: TStringList;
  TranslatedPlaceholders: TStringList;
begin
  Result := False;
  ATranslatedText := '';
  SourceLiterals := TStringList.Create;
  SourcePlaceholders := TStringList.Create;
  TranslatedLiterals := TStringList.Create;
  TranslatedPlaceholders := TStringList.Create;
  Captures := TStringList.Create;
  try
    ParseFormatTemplate(ASourceTemplate, SourceLiterals, SourcePlaceholders);
    ParseFormatTemplate(ATranslatedTemplate, TranslatedLiterals,
      TranslatedPlaceholders);
    if (SourcePlaceholders.Count = 0) or
      (SourcePlaceholders.Count <> TranslatedPlaceholders.Count) or
      (TranslatedLiterals.Count <> TranslatedPlaceholders.Count + 1) then
      Exit;
    MatchStart := Pos(SourceLiterals[0], ACurrentText);
    if MatchStart = 0 then
      Exit;
    CurrentAt := MatchStart + Length(SourceLiterals[0]);
    for Index := 1 to SourceLiterals.Count - 1 do
    begin
      NextLiteral := SourceLiterals[Index];
      if NextLiteral = '' then
      begin
        if Index = SourceLiterals.Count - 1 then
          LiteralAt := Length(ACurrentText) + 1
        else
          Exit;
      end
      else
        LiteralAt := PosEx(NextLiteral, ACurrentText, CurrentAt);
      if LiteralAt = 0 then
        Exit;
      Captures.Add(Copy(ACurrentText, CurrentAt, LiteralAt - CurrentAt));
      CurrentAt := LiteralAt + Length(NextLiteral);
    end;
    MatchEnd := CurrentAt;
    OutputText := TranslatedLiterals[0];
    for Index := 0 to Captures.Count - 1 do
      OutputText := OutputText + Captures[Index] + TranslatedLiterals[Index + 1];
    ATranslatedText := Copy(ACurrentText, 1, MatchStart - 1) + OutputText +
      Copy(ACurrentText, MatchEnd, MaxInt);
    Result := ATranslatedText <> ACurrentText;
  finally
    Captures.Free;
    TranslatedPlaceholders.Free;
    TranslatedLiterals.Free;
    SourcePlaceholders.Free;
    SourceLiterals.Free;
  end;
end;

function TRuntimeLanguagePack.TryTranslateDynamicText(
  const ASourceText: string; out ATranslatedText: string): Boolean;
var
  Candidate: string;
  LongestSource: string;
  SourceTemplate: string;
begin
  { Dynamic refresh can see a value translated on an earlier pass.  Treat
    translated values as terminal so source prefixes such as Event -> Evento
    cannot grow by one character on every refresh. }
  if FTranslatedStrings.ContainsKey(ASourceText) then
  begin
    ATranslatedText := ASourceText;
    Exit(False);
  end;
  if TryTranslateSource(ASourceText, ATranslatedText) then
    Exit(True);
  LongestSource := '';
  for Candidate in FSourceStrings.Keys do
    if (Length(Candidate) >= 4) and
      (Length(Candidate) > Length(LongestSource)) and
      ContainsStr(ASourceText, Candidate) and
      not ContainsStr(ASourceText, FSourceStrings[Candidate]) then
      LongestSource := Candidate;
  if LongestSource <> '' then
  begin
    ATranslatedText := StringReplace(ASourceText, LongestSource,
      FSourceStrings[LongestSource], [rfReplaceAll]);
    Exit(ATranslatedText <> ASourceText);
  end;
  for SourceTemplate in FSourceTemplates.Keys do
    if TryApplyFormatTemplate(ASourceText, SourceTemplate,
      FSourceTemplates[SourceTemplate], ATranslatedText) then
      Exit(True);
  ATranslatedText := ASourceText;
  Result := False;
end;

function TRuntimeLanguagePack.GetTemplate(
  const AKey, AFallbackText: string): string;
begin
  if not TryGetTemplate(AKey, Result) then
    Result := AFallbackText;
end;

function TRuntimeLanguagePack.GetAnyText(
  const AKey, AFallbackText: string): string;
begin
  if not TryGetText(AKey, Result) and not TryGetTemplate(AKey, Result) then
    Result := AFallbackText;
end;

function TRuntimeLanguagePack.FormatTemplate(const AKey,
  AFallbackText: string; const AArgs: array of const): string;
begin
  Result := Format(GetTemplate(AKey, AFallbackText), AArgs);
end;

function TRuntimeLanguagePack.ReadIndexedStrings(
  const AKeyPrefix: string; const AValues: TStrings): Integer;
var
  Index: Integer;
  TextValue: string;
  TranslatedValues: TStringList;
begin
  if AValues = nil then
    raise EArgumentNilException.Create('A string collection is required.');
  if not TryGetText(AKeyPrefix + '.0', TextValue) then
    Exit(0);
  TranslatedValues := TStringList.Create;
  try
    TranslatedValues.Add(TextValue);
    Index := 1;
    while TryGetText(AKeyPrefix + '.' + Index.ToString, TextValue) do
    begin
      TranslatedValues.Add(TextValue);
      Inc(Index);
    end;

    AValues.BeginUpdate;
    try
      for Index := 0 to Min(AValues.Count, TranslatedValues.Count) - 1 do
        AValues[Index] := TranslatedValues[Index];
      while AValues.Count > TranslatedValues.Count do
        AValues.Delete(AValues.Count - 1);
      while AValues.Count < TranslatedValues.Count do
        AValues.Add(TranslatedValues[AValues.Count]);
      Result := TranslatedValues.Count;
    finally
      AValues.EndUpdate;
    end;
  finally
    TranslatedValues.Free;
  end;
end;

class function TLanguagePackDiscovery.Discover(const ADirectoryName,
  AExpectedApplicationId: string): TObjectList<TLanguagePackDescriptor>;
var
  BaseCode: string;
  Descriptor: TLanguagePackDescriptor;
  FileName: string;
  Index: Integer;
  RegionalCodes: TDictionary<string, Boolean>;
  SeenCodes: TDictionary<string, Boolean>;
  Pack: TRuntimeLanguagePack;
begin
  Result := TObjectList<TLanguagePackDescriptor>.Create(True);
  if not TDirectory.Exists(ADirectoryName) then
    Exit;

  for FileName in TDirectory.GetFiles(ADirectoryName, '*.json') do
  begin
    Pack := nil;
    try
      try
        Pack := TRuntimeLanguagePack.LoadFromFile(FileName);
        if (((AExpectedApplicationId = '') or
          SameText(Pack.ApplicationId, AExpectedApplicationId))) and
          (Trim(Pack.LanguageCode) <> '') and
          (Pack.Strings.Count > 0) then
        begin
          Descriptor := TLanguagePackDescriptor.Create;
          Descriptor.FileName := FileName;
          Descriptor.LanguageCode := Pack.LanguageCode;
          Descriptor.NativeLanguageName := CanonicalNativeLanguageName(
            Pack.LanguageCode, Pack.NativeLanguageName);
          Descriptor.TextDirection := Pack.TextDirection;
          Descriptor.SourceLanguage := Pack.SourceLanguage;
          Result.Add(Descriptor);
        end;
      finally
        Pack.Free;
      end;
    except
      on Exception do
        Continue;
    end;
  end;
  RegionalCodes := TDictionary<string, Boolean>.Create;
  SeenCodes := TDictionary<string, Boolean>.Create;
  try
    for Index := Result.Count - 1 downto 0 do
    begin
      BaseCode := LowerCase(Result[Index].LanguageCode);
      if SeenCodes.ContainsKey(BaseCode) then
        Result.Delete(Index)
      else
        SeenCodes.Add(BaseCode, True);
    end;
    for Descriptor in Result do
      if Pos('-', Descriptor.LanguageCode) > 0 then
        RegionalCodes.AddOrSetValue(
          BaseLanguageCode(Descriptor.LanguageCode), True);
    for Index := Result.Count - 1 downto 0 do
    begin
      Descriptor := Result[Index];
      BaseCode := BaseLanguageCode(Descriptor.LanguageCode);
      if (Pos('-', Descriptor.LanguageCode) = 0) and
        RegionalCodes.ContainsKey(BaseCode) then
        Result.Delete(Index);
    end;
  finally
    SeenCodes.Free;
    RegionalCodes.Free;
  end;
  Result.Sort(TComparer<TLanguagePackDescriptor>.Construct(
    function(const ALeft, ARight: TLanguagePackDescriptor): Integer
    begin
      Result := CompareText(
        ALeft.NativeLanguageName, ARight.NativeLanguageName);
      if Result = 0 then
        Result := CompareText(
          ALeft.LanguageCode, ARight.LanguageCode);
    end));
end;

end.
