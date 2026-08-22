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
    { Whether this user has ever chosen a language in this application.
      False on a first run, which is the only time the operating
      system's own language is worth consulting - after that, what the
      user chose outranks what the machine is set to. }
    function HasStoredPreference: Boolean;
    { The language the machine is set to, as a locale name, or an empty
      string where the platform cannot say. }
    class function SystemLanguageCode: string; static;
    { Loads the pack that best matches the machine's language: an exact
      locale match first, then any pack sharing its language. False when
      no pack matches, which leaves the caller to fall back. }
    function LoadLanguageForSystem: Boolean;
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
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
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

function TTranslationRuntime.HasStoredPreference: Boolean;
begin
  Result := TFile.Exists(FPreferenceFileName);
end;

class function TTranslationRuntime.SystemLanguageCode: string;
{$IFDEF MSWINDOWS}
var
  Buffer: array [0 .. 85] of Char;
  Count: Integer;
begin
  Result := '';
  Count := GetUserDefaultLocaleName(@Buffer[0], Length(Buffer));
  { The count includes the terminating null. }
  if Count > 1 then
    SetString(Result, PChar(@Buffer[0]), Count - 1);
end;
{$ELSE}
begin
  { Nothing to ask on a platform this runtime has not been taught about.
    An empty answer means the caller keeps its existing behavior. }
  Result := '';
end;
{$ENDIF}

function TTranslationRuntime.LoadLanguageForSystem: Boolean;
var
  Wanted: string;
  WantedLanguage: string;
  Packs: TObjectList<TLanguagePackDescriptor>;
  Pack: TLanguagePackDescriptor;
  Fallback: string;
begin
  Result := False;
  Wanted := Trim(SystemLanguageCode);
  if Wanted = '' then
    Exit;
  WantedLanguage := Wanted;
  if Pos('-', WantedLanguage) > 0 then
    WantedLanguage := Copy(WantedLanguage, 1, Pos('-', WantedLanguage) - 1);
  Fallback := '';
  Packs := AvailableLanguages;
  try
    for Pack in Packs do
    begin
      if SameText(Pack.LanguageCode, Wanted) then
        Exit(LoadLanguage(Pack.LanguageCode));
      { A machine set to one region of a language should still get that
        language where only another region was translated. }
      if (Fallback = '') and
        (SameText(Pack.LanguageCode, WantedLanguage) or
         StartsText(WantedLanguage + '-', Pack.LanguageCode)) then
        Fallback := Pack.LanguageCode;
    end;
  finally
    Packs.Free;
  end;
  if Fallback <> '' then
    Result := LoadLanguage(Fallback);
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

{ Dates and times follow the machine, not the language.

  These used to be built from the pack's language code, so translating an
  application to Arabic also switched its dates to the Saudi calendar
  conventions - on a machine whose owner had chosen US formats and had every
  other application obeying that choice.

  That is the wrong default. A language is what someone reads; a date format
  is what their country writes, and the two are not the same question. Somebody
  in Chicago reading an application in Arabic still wants 8/22/2026, because
  that is what their bank statement, their calendar and every other window on
  the screen says. Windows already knows the answer and every application on
  the machine except this one was already asking it.

  So the base is the user's own regional settings, and the pack is not allowed
  to overrule them for dates or times.

  Numbers and currency are still taken from the pack when it supplies them.
  Those travel with the content rather than the reader: a price written in a
  pack's currency means that currency wherever it is read, and reformatting it
  to local conventions would change what it says rather than how it looks. }
procedure TTranslationRuntime.UpdateFormatSettings;
begin
  { No argument: the user's default locale, which is what every other
    application on this machine formats dates with. }
  FFormatSettings := TFormatSettings.Create;

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
