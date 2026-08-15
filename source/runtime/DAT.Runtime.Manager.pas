unit DAT.Runtime.Manager;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DAT.Runtime.LanguagePack;

type
  TTranslationRuntime = class
  private
    FApplicationId: string;
    FLanguagesDirectory: string;
    FPreferenceFileName: string;
    FSourceLanguageCode: string;
    FActivePack: TRuntimeLanguagePack;
    FFormatSettings: TFormatSettings;
    procedure UpdateFormatSettings;
  public
    constructor Create(const AApplicationId, ALanguagesDirectory,
      APreferenceFileName, ASourceLanguageCode: string);
    destructor Destroy; override;
    function AvailableLanguages: TObjectList<TLanguagePackDescriptor>;
    function LoadLanguage(const ALanguageCode: string): Boolean;
    function LoadPreferredLanguage: Boolean;
    function Translate(const AKey, AFallbackText: string): string;
    function TranslateDynamicText(const ASourceText: string): string;
    function TranslateHtmlText(const AHtmlText: string): string;
    function FormatTemplate(const AKey, AFallbackText: string;
      const AArgs: array of const): string;
    property ActivePack: TRuntimeLanguagePack read FActivePack;
    property FormatSettings: TFormatSettings read FFormatSettings;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  DAT.Runtime.Preference;

constructor TTranslationRuntime.Create(const AApplicationId,
  ALanguagesDirectory, APreferenceFileName, ASourceLanguageCode: string);
begin
  inherited Create;
  FApplicationId := AApplicationId;
  FLanguagesDirectory := ALanguagesDirectory;
  FPreferenceFileName := APreferenceFileName;
  FSourceLanguageCode := ASourceLanguageCode;
  FFormatSettings := TFormatSettings.Create;
end;

destructor TTranslationRuntime.Destroy;
begin
  FActivePack.Free;
  inherited Destroy;
end;

function TTranslationRuntime.AvailableLanguages:
  TObjectList<TLanguagePackDescriptor>;
begin
  Result := TLanguagePackDiscovery.Discover(
    FLanguagesDirectory, FApplicationId);
end;

function TTranslationRuntime.LoadLanguage(
  const ALanguageCode: string): Boolean;
var
  CandidateFileName: string;
  NewPack: TRuntimeLanguagePack;
begin
  CandidateFileName := TPath.Combine(
    FLanguagesDirectory, ALanguageCode + '.json');
  if not TFile.Exists(CandidateFileName) then
  begin
    Result := SameText(ALanguageCode, FSourceLanguageCode);
    if Result then
    begin
      FreeAndNil(FActivePack);
      FFormatSettings := TFormatSettings.Create;
      TLanguagePreference.WriteLanguageCode(
        FPreferenceFileName, ALanguageCode);
    end;
    Exit;
  end;

  NewPack := TRuntimeLanguagePack.LoadFromFile(CandidateFileName);
  try
    if not SameText(NewPack.ApplicationId, FApplicationId) then
      raise ELanguagePackError.CreateFmt(
        'Language pack "%s" belongs to application "%s", not "%s".',
        [CandidateFileName, NewPack.ApplicationId, FApplicationId]);
    if not SameText(NewPack.LanguageCode, ALanguageCode) then
      raise ELanguagePackError.CreateFmt(
        'Language pack filename and language code do not match: %s',
        [CandidateFileName]);
    FreeAndNil(FActivePack);
    FActivePack := NewPack;
    NewPack := nil;
    UpdateFormatSettings;
    TLanguagePreference.WriteLanguageCode(
      FPreferenceFileName, ALanguageCode);
    Result := True;
  finally
    NewPack.Free;
  end;
end;

function TTranslationRuntime.LoadPreferredLanguage: Boolean;
begin
  if not TFile.Exists(FPreferenceFileName) then
  begin
    FreeAndNil(FActivePack);
    FFormatSettings := TFormatSettings.Create;
    Exit(True);
  end;
  Result := LoadLanguage(TLanguagePreference.ReadLanguageCode(
    FPreferenceFileName, FSourceLanguageCode));
end;

function TTranslationRuntime.Translate(
  const AKey, AFallbackText: string): string;
begin
  if FActivePack = nil then
    Result := AFallbackText
  else
    Result := FActivePack.GetAnyText(AKey, AFallbackText);
end;

function TTranslationRuntime.TranslateDynamicText(
  const ASourceText: string): string;
begin
  if (FActivePack = nil) or
    not FActivePack.TryTranslateDynamicText(ASourceText, Result) then
    Result := ASourceText;
end;

function TTranslationRuntime.TranslateHtmlText(const AHtmlText: string): string;
var
  Candidate: string;
  InTag: Boolean;
  I: Integer;
  J: Integer;
  Keys: TStringList;
  Segment: string;
  SwapText: string;
  TextIndex: Integer;

  function IsWordCharacter(const AValue: Char): Boolean;
  begin
    Result := CharInSet(AValue, ['A'..'Z', 'a'..'z', '0'..'9', '_']) or
      (Ord(AValue) > 127);
  end;

  function ReplaceWholeTerm(const AText, ASource,
    AReplacement: string): string;
  var
    AfterIsWord: Boolean;
    At: Integer;
    BeforeIsWord: Boolean;
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

  function TranslateVisibleSegment(const AText: string): string;
  var
    KeyIndex: Integer;
    SourceText: string;
    TranslatedText: string;
  begin
    Result := AText;
    for KeyIndex := 0 to Keys.Count - 1 do
    begin
      SourceText := Keys[KeyIndex];
      TranslatedText := FActivePack.SourceStrings[SourceText];
      if (Trim(SourceText) <> '') and (Trim(TranslatedText) <> '') and
        not SameText(SourceText, TranslatedText) then
        Result := ReplaceWholeTerm(Result, SourceText, TranslatedText);
    end;
  end;

begin
  Result := AHtmlText;
  if (FActivePack = nil) or (AHtmlText = '') then
    Exit;
  Keys := TStringList.Create;
  try
    for Candidate in FActivePack.SourceStrings.Keys do
      if Trim(Candidate) <> '' then
        Keys.Add(Candidate);
    for I := 0 to Keys.Count - 2 do
      for J := I + 1 to Keys.Count - 1 do
      begin
        if (Length(Keys[J]) > Length(Keys[I])) or
          ((Length(Keys[J]) = Length(Keys[I])) and
           (CompareText(Keys[J], Keys[I]) < 0)) then
        begin
          SwapText := Keys[I];
          Keys[I] := Keys[J];
          Keys[J] := SwapText;
        end;
      end;

    Result := '';
    Segment := '';
    InTag := False;
    for TextIndex := 1 to Length(AHtmlText) do
    begin
      if AHtmlText[TextIndex] = '<' then
      begin
        if Segment <> '' then
        begin
          Result := Result + TranslateVisibleSegment(Segment);
          Segment := '';
        end;
        InTag := True;
        Result := Result + AHtmlText[TextIndex];
      end
      else if AHtmlText[TextIndex] = '>' then
      begin
        InTag := False;
        Result := Result + AHtmlText[TextIndex];
      end
      else if InTag then
        Result := Result + AHtmlText[TextIndex]
      else
        Segment := Segment + AHtmlText[TextIndex];
    end;
    if Segment <> '' then
      Result := Result + TranslateVisibleSegment(Segment);
  finally
    Keys.Free;
  end;
end;

function TTranslationRuntime.FormatTemplate(const AKey,
  AFallbackText: string; const AArgs: array of const): string;
begin
  if FActivePack = nil then
    Result := Format(AFallbackText, AArgs)
  else
    Result := FActivePack.FormatTemplate(AKey, AFallbackText, AArgs);
end;

procedure TTranslationRuntime.UpdateFormatSettings;
begin
  FFormatSettings := TFormatSettings.Create(FActivePack.LanguageCode);
  if FActivePack.Locale.ShortDateFormat <> '' then
    FFormatSettings.ShortDateFormat := FActivePack.Locale.ShortDateFormat;
  if FActivePack.Locale.LongDateFormat <> '' then
    FFormatSettings.LongDateFormat := FActivePack.Locale.LongDateFormat;
  if FActivePack.Locale.ShortTimeFormat <> '' then
    FFormatSettings.ShortTimeFormat := FActivePack.Locale.ShortTimeFormat;
  if FActivePack.Locale.LongTimeFormat <> '' then
    FFormatSettings.LongTimeFormat := FActivePack.Locale.LongTimeFormat;
  if FActivePack.Locale.DecimalSeparator <> '' then
    FFormatSettings.DecimalSeparator :=
      FActivePack.Locale.DecimalSeparator[1];
  if FActivePack.Locale.ThousandSeparator <> '' then
    FFormatSettings.ThousandSeparator :=
      FActivePack.Locale.ThousandSeparator[1];
  if FActivePack.Locale.CurrencySymbol <> '' then
    FFormatSettings.CurrencyString := FActivePack.Locale.CurrencySymbol;
end;

end.
