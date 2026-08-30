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
    function TryRestoreDynamicText(const ATranslatedText: string;
      out ASourceText: string): Boolean;
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
    FApplicationVersion: string;
    FFramework: string;
    FSourceCatalogChecksum: string;
  public
    property FileName: string read FFileName write FFileName;
    property LanguageCode: string read FLanguageCode write FLanguageCode;
    property NativeLanguageName: string read FNativeLanguageName write FNativeLanguageName;
    property TextDirection: string read FTextDirection write FTextDirection;
    property SourceLanguage: string read FSourceLanguage write FSourceLanguage;
    property ApplicationVersion: string read FApplicationVersion
      write FApplicationVersion;
    property Framework: string read FFramework write FFramework;
    property SourceCatalogChecksum: string read FSourceCatalogChecksum
      write FSourceCatalogChecksum;
  end;

  TLanguagePackDiscovery = class
  public
    class function Discover(const ADirectoryName,
      AExpectedApplicationId: string): TObjectList<TLanguagePackDescriptor>; static;
  end;

function CanonicalNativeLanguageName(const ALanguageCode,
  AFallbackName: string): string;

{ The layout properties a pack may carry.

  One list, and only one. There were three: this decision was written out in
  the FireMonkey applicator, in the pack exporter, and in the ordered pass that
  applies rules. They drifted, twice, and both times a whole feature was lost
  in silence - the planner decided correctly, the runtime would have applied it
  correctly, and the pack in between simply did not carry it. A property absent
  from this list is not an error anywhere; it is just gone.

  So it lives here, in the unit the exporter and both applicators already
  share, and nothing else keeps a copy. }
function IsRuntimeLayoutProperty(const APropertyName: string): Boolean;
{ Properties that may be accepted in bulk without tying a translated form to
  one design-time resolution. Absolute geometry remains supported for a
  developer's explicit, visually reviewed per-control decision, but it is not
  "safe" merely because both runtimes know how to assign it. }
function IsAutomaticallySafeLayoutProperty(
  const APropertyName: string): Boolean;

implementation

uses
  System.Generics.Defaults,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Core.AtomicFile,
  DAT.Core.Diagnostics;

function IsRuntimeLayoutProperty(const APropertyName: string): Boolean;
begin
  Result :=
    { geometry }
    SameText(APropertyName, 'Width') or
    SameText(APropertyName, 'Height') or
    SameText(APropertyName, 'Left') or
    SameText(APropertyName, 'Top') or
    SameText(APropertyName, 'Position.X') or
    SameText(APropertyName, 'Position.Y') or
    { text fitting }
    SameText(APropertyName, 'WordWrap') or
    SameText(APropertyName, 'AutoSize') or
    SameText(APropertyName, 'FontSize') or
    { the parts of a right-to-left mirror that are constants rather than
      coordinates }
    SameText(APropertyName, 'Alignment') or
    SameText(APropertyName, 'TextSettings.HorzAlign') or
    SameText(APropertyName, 'Align') or
    SameText(APropertyName, 'Anchors') or
    SameText(APropertyName, 'TabOrder') or
    SameText(APropertyName, 'ColumnOrder') or
    { Opt-in for the direction-aware runtime mirror.  Unlike a numeric Left
      or Position.X rule, this is evaluated against the live parent width, so
      it remains correct after DPI scaling, maximising, responsive layout and
      controls created by the application after the form was streamed. }
    SameText(APropertyName, 'MirrorChildren') or
    { a column names a path into a control rather than a property of it }
    StartsText('Columns[', APropertyName);
end;

function IsAutomaticallySafeLayoutProperty(
  const APropertyName: string): Boolean;
begin
  Result :=
    { Wrapping, automatic sizing and font size are content measurements, not
      direction constants.  They must be reviewed (or decided by the measured
      run-time fitter) rather than bulk-accepted for every translated control. }
    SameText(APropertyName, 'Alignment') or
    SameText(APropertyName, 'TextSettings.HorzAlign') or
    SameText(APropertyName, 'Align') or
    SameText(APropertyName, 'Anchors') or
    SameText(APropertyName, 'TabOrder') or
    SameText(APropertyName, 'ColumnOrder') or
    SameText(APropertyName, 'MirrorChildren') or
    { A grid-column font/alignment rule adapts the text inside the live
      column. A numeric column Width does not: it freezes one design-time
      pixel measurement and therefore follows the same explicit-review rule
      as a control Width. }
    (StartsText('Columns[', APropertyName) and
      (EndsText('.FontSize', APropertyName) or
       EndsText('.Alignment', APropertyName) or
       EndsText('.Title.Alignment', APropertyName)));
end;



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

procedure ValidateNoDuplicateKeys(const AValue: TJSONValue;
  const APath: string);
var
  ArrayItem: TJSONValue;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
  JsonPair: TJSONPair;
  Keys: TDictionary<string, Boolean>;
  PairPath: string;
begin
  if AValue is TJSONObject then
  begin
    JsonObject := TJSONObject(AValue);
    Keys := TDictionary<string, Boolean>.Create;
    try
      for JsonPair in JsonObject do
      begin
        if Keys.ContainsKey(JsonPair.JsonString.Value) then
          raise ELanguagePackError.CreateFmt(
            'The runtime language pack contains duplicate JSON key "%s" at %s.',
            [JsonPair.JsonString.Value, APath]);
        Keys.Add(JsonPair.JsonString.Value, True);
        if APath = '' then
          PairPath := JsonPair.JsonString.Value
        else
          PairPath := APath + '.' + JsonPair.JsonString.Value;
        ValidateNoDuplicateKeys(JsonPair.JsonValue, PairPath);
      end;
    finally
      Keys.Free;
    end;
  end
  else if AValue is TJSONArray then
  begin
    JsonArray := TJSONArray(AValue);
    for ArrayItem in JsonArray do
      ValidateNoDuplicateKeys(ArrayItem, APath + '[]');
  end;
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
    ValidateNoDuplicateKeys(JsonRoot, '$');
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

      LocaleObject := JsonRoot.GetValue('locale') as TJSONObject;
      if LocaleObject <> nil then
      begin
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
      end;

      StringsObject := RequiredObject(JsonRoot, 'strings');
      for JsonPair in StringsObject do
        Result.FStrings.Add(JsonPair.JsonString.Value,
          JsonPair.JsonValue.Value);
      TemplatesObject := JsonRoot.GetValue('templates') as TJSONObject;
      if TemplatesObject <> nil then
        for JsonPair in TemplatesObject do
          Result.FTemplates.Add(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
      SourcesObject := JsonRoot.GetValue('sources') as TJSONObject;
      if SourcesObject <> nil then
        for JsonPair in SourcesObject do
          Result.FSources.Add(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
      SourceStringsObject := JsonRoot.GetValue('sourceStrings') as TJSONObject;
      if SourceStringsObject <> nil then
        for JsonPair in SourceStringsObject do
        begin
          Result.FSourceStrings.Add(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
          if JsonPair.JsonValue.Value <> '' then
            Result.FTranslatedStrings.AddOrSetValue(
              JsonPair.JsonValue.Value, True);
        end;
      SourceTemplatesObject := JsonRoot.GetValue('sourceTemplates') as TJSONObject;
      if SourceTemplatesObject <> nil then
        for JsonPair in SourceTemplatesObject do
        begin
          Result.FSourceTemplates.Add(JsonPair.JsonString.Value,
            JsonPair.JsonValue.Value);
          if JsonPair.JsonValue.Value <> '' then
            Result.FTranslatedStrings.AddOrSetValue(
              JsonPair.JsonValue.Value, True);
        end;
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
          Result.FFontColors.Add(JsonPair.JsonString.Value,
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
var
  JsonText: string;
  Recovered: Boolean;
begin
  if not TFile.Exists(AFileName) then
    raise ELanguagePackError.CreateFmt(
      'Runtime language pack not found: %s', [AFileName]);
  JsonText := TAtomicTextFile.ReadAllText(AFileName, TEncoding.UTF8,
    procedure(const AText: string)
    var
      ValidationPack: TRuntimeLanguagePack;
    begin
      ValidationPack := LoadFromJson(AText);
      ValidationPack.Free;
    end, Recovered);
  if Recovered then
    TDATDiagnostics.Log('DAT-PACK-RECOVERY-001', 'LoadFromFile',
      'Recovered the prior valid language pack and quarantined the invalid file: ' +
      AFileName, dsWarning);
  Result := LoadFromJson(JsonText);
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

function TRuntimeLanguagePack.TryRestoreDynamicText(
  const ATranslatedText: string; out ASourceText: string): Boolean;
var
  Candidate: string;
  LongestTranslation: string;
  Replacement: string;

  function IsWordCharacter(const AValue: Char): Boolean;
  begin
    Result := CharInSet(AValue, ['A'..'Z', 'a'..'z', '0'..'9', '_']) or
      (Ord(AValue) > 127);
  end;

  function ReplaceWholeTerm(const AText, ASource, AReplacement: string): string;
  var
    At: Integer;
    BeforeIsWord: Boolean;
    AfterIsWord: Boolean;
    SearchFrom: Integer;
  begin
    Result := AText;
    SearchFrom := 1;
    while SearchFrom <= Length(Result) do
    begin
      At := PosEx(ASource, Result, SearchFrom);
      if At = 0 then
        Break;
      BeforeIsWord := (At > 1) and IsWordCharacter(Result[At - 1]);
      AfterIsWord := (At + Length(ASource) <= Length(Result)) and
        IsWordCharacter(Result[At + Length(ASource)]);
      if not BeforeIsWord and not AfterIsWord then
      begin
        Delete(Result, At, Length(ASource));
        Insert(AReplacement, Result, At);
        SearchFrom := At + Length(AReplacement);
      end
      else
        SearchFrom := At + Length(ASource);
    end;
  end;
begin
  Result := False;
  ASourceText := '';
  LongestTranslation := '';
  for Candidate in FSourceStrings.Values do
    if (Trim(Candidate) <> '') and
      (ContainsText(ATranslatedText, Candidate)) and
      (Length(Candidate) > Length(LongestTranslation)) then
      LongestTranslation := Candidate;
  if LongestTranslation = '' then
    Exit;
  for Candidate in FSourceStrings.Keys do
    if SameText(FSourceStrings[Candidate], LongestTranslation) then
    begin
      Replacement := ReplaceWholeTerm(ATranslatedText, LongestTranslation,
        Candidate);
      if Replacement <> ATranslatedText then
      begin
        ASourceText := Replacement;
        Exit(True);
      end;
    end;
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
  ATranslatedTemplate: string;
  const ASourceTranslations: TDictionary<string, string>;
  AWholeTextOnly: Boolean;
  out ATranslatedText: string): Boolean;
var
  CaptureCore: string;
  CaptureText: string;
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
  TranslatedCapture: string;
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
    if AWholeTextOnly and
      ((MatchStart <> 1) or (MatchEnd <> Length(ACurrentText) + 1)) then
      Exit;
    OutputText := TranslatedLiterals[0];
    for Index := 0 to Captures.Count - 1 do
    begin
      CaptureText := Captures[Index];
      CaptureCore := Trim(CaptureText);
      { Placeholders usually contain data and must remain verbatim. A value
        that is itself an exact catalog source string, however, is semantic UI
        text (for example On or Off). Translate only that whole value and
        preserve any surrounding whitespace. This avoids unsafe substring
        replacement in filenames, identifiers, counts, and user content. }
      if (ASourceTranslations <> nil) and (CaptureCore <> '') and
        ASourceTranslations.TryGetValue(CaptureCore, TranslatedCapture) then
        CaptureText := Copy(CaptureText, 1,
          Length(CaptureText) - Length(TrimLeft(CaptureText))) +
          TranslatedCapture + Copy(CaptureText,
          Length(TrimRight(CaptureText)) + 1, MaxInt);
      OutputText := OutputText + CaptureText + TranslatedLiterals[Index + 1];
    end;
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
  LongestTemplate: string;
  ProcessedSources: TDictionary<string, Boolean>;
  ProcessedTemplates: TDictionary<string, Boolean>;
  SourceTemplate: string;
  Replacement: string;
  WorkingText: string;

  function IsWordCharacter(const AValue: Char): Boolean;
  begin
    Result := CharInSet(AValue, ['A'..'Z', 'a'..'z', '0'..'9', '_']) or
      (Ord(AValue) > 127);
  end;

  function ReplaceWholeTerm(const AText, ASource, AReplacement: string): string;
  var
    At: Integer;
    BeforeIsWord: Boolean;
    AfterIsWord: Boolean;
    SearchFrom: Integer;
  begin
    Result := AText;
    SearchFrom := 1;
    while SearchFrom <= Length(Result) do
    begin
      At := PosEx(ASource, Result, SearchFrom);
      if At = 0 then
        Break;
      BeforeIsWord := (At > 1) and IsWordCharacter(Result[At - 1]);
      AfterIsWord := (At + Length(ASource) <= Length(Result)) and
        IsWordCharacter(Result[At + Length(ASource)]);
      if not BeforeIsWord and not AfterIsWord then
      begin
        Delete(Result, At, Length(ASource));
        Insert(AReplacement, Result, At);
        SearchFrom := At + Length(AReplacement);
      end
      else
        SearchFrom := At + Length(ASource);
    end;
  end;
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
  { Runtime templates are exact or format-aware UI strings. Resolve them
    before looking for shorter terms inside the text; otherwise a term such
    as Schedule can corrupt Scheduled or a longer dialog title. }
  if FSourceTemplates.TryGetValue(ASourceText, ATranslatedText) then
    Exit(ATranslatedText <> ASourceText);
  { Source text normally retains its original case, so the dictionary lookup
    above is the common path. Preserve the established case-insensitive
    fallback for applications that normalize caption case at runtime. }
  for SourceTemplate in FSourceTemplates.Keys do
    if SameText(ASourceText, SourceTemplate) then
    begin
      ATranslatedText := FSourceTemplates[SourceTemplate];
      Exit(ATranslatedText <> ASourceText);
    end;
  { A formatted semantic template must run before shorter literal terms can
    translate pieces of its source text. Once a label such as Critical Areas
    has changed independently, the complete template no longer matches and
    its short semantic placeholder values (On/Off) would remain untranslated. }
  for SourceTemplate in FSourceTemplates.Keys do
    if (Pos('%', SourceTemplate) > 0) and
      TryApplyFormatTemplate(ASourceText, SourceTemplate,
        FSourceTemplates[SourceTemplate], FSourceStrings, True,
        ATranslatedText) then
      Exit(True);
  WorkingText := ASourceText;
  ProcessedTemplates := TDictionary<string, Boolean>.Create;
  ProcessedSources := TDictionary<string, Boolean>.Create;
  try
    { A rendered HTML text node can contain several independently keyed
      semantic sentences. Apply every literal template, longest first, rather
      than returning after the first match and leaving the rest in the source
      language. Formatted templates remain governed by the parser below. }
    repeat
      LongestTemplate := '';
      for SourceTemplate in FSourceTemplates.Keys do
        if not ProcessedTemplates.ContainsKey(SourceTemplate) and
          (Pos('%', SourceTemplate) = 0) and
          (Length(SourceTemplate) >= 4) and
          (Length(SourceTemplate) > Length(LongestTemplate)) and
          ContainsStr(WorkingText, SourceTemplate) and
          not ContainsStr(WorkingText, FSourceTemplates[SourceTemplate]) then
          LongestTemplate := SourceTemplate;
      if LongestTemplate = '' then
        Break;
      ProcessedTemplates.Add(LongestTemplate, True);
      Replacement := FSourceTemplates[LongestTemplate];
      WorkingText := ReplaceWholeTerm(WorkingText, LongestTemplate,
        Replacement);
    until False;

    { Apply every stable source term for the same reason. This also makes the
      dynamic API itself complete instead of relying on an HTML caller to run
      a second replacement pass. }
    repeat
      LongestSource := '';
      for Candidate in FSourceStrings.Keys do
        if not ProcessedSources.ContainsKey(Candidate) and
          (Length(Candidate) >= 4) and
          (Length(Candidate) > Length(LongestSource)) and
          ContainsStr(WorkingText, Candidate) and
          not ContainsStr(WorkingText, FSourceStrings[Candidate]) then
          LongestSource := Candidate;
      if LongestSource = '' then
        Break;
      ProcessedSources.Add(LongestSource, True);
      Replacement := FSourceStrings[LongestSource];
      WorkingText := ReplaceWholeTerm(WorkingText, LongestSource,
        Replacement);
    until False;
    if WorkingText <> ASourceText then
    begin
      ATranslatedText := WorkingText;
      Exit(True);
    end;
  finally
    ProcessedSources.Free;
    ProcessedTemplates.Free;
  end;
  for SourceTemplate in FSourceTemplates.Keys do
    if TryApplyFormatTemplate(ASourceText, SourceTemplate,
      FSourceTemplates[SourceTemplate], FSourceStrings, False,
      ATranslatedText) then
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
        if not SameText(TPath.GetFileNameWithoutExtension(FileName),
          Pack.LanguageCode) then
          raise ELanguagePackError.CreateFmt(
            'Language pack filename "%s" does not match language code "%s".',
            [TPath.GetFileName(FileName), Pack.LanguageCode]);
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
          Descriptor.ApplicationVersion := Pack.ApplicationVersion;
          Descriptor.Framework := Pack.Framework;
          Descriptor.SourceCatalogChecksum := Pack.SourceCatalogChecksum;
          Result.Add(Descriptor);
        end;
      finally
        Pack.Free;
      end;
    except
      on E: Exception do
      begin
        TDATDiagnostics.LogException('DAT-PACK-DISCOVERY-001',
          'Discover(' + FileName + ')', E);
        Continue;
      end;
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
