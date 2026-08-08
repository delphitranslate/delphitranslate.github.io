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
    property ActivePack: TRuntimeLanguagePack read FActivePack;
    property FormatSettings: TFormatSettings read FFormatSettings;
  end;

implementation

uses
  System.IOUtils,
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
    Result := FActivePack.GetText(AKey, AFallbackText);
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
