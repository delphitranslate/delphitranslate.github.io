unit DAT.Validation.Catalog;

interface

uses
  System.Generics.Collections,
  DAT.Core.Types;

type
  TValidationSeverity = (
    vsInformation,
    vsWarning,
    vsError
  );

  TValidationIssue = class
  private
    FSeverity: TValidationSeverity;
    FCode: string;
    FEntryKey: string;
    FMessageText: string;
  public
    property Severity: TValidationSeverity read FSeverity write FSeverity;
    property Code: string read FCode write FCode;
    property EntryKey: string read FEntryKey write FEntryKey;
    property MessageText: string read FMessageText write FMessageText;
  end;

  TCatalogValidationResult = class
  private
    FIssues: TObjectList<TValidationIssue>;
  public
    constructor Create;
    destructor Destroy; override;
    function CountBySeverity(const ASeverity: TValidationSeverity): Integer;
    function HasErrors: Boolean;
    property Issues: TObjectList<TValidationIssue> read FIssues;
  end;

  TCatalogValidator = class
  private
    class procedure AddIssue(const AResult: TCatalogValidationResult;
      const ASeverity: TValidationSeverity; const ACode, AEntryKey,
      AMessage: string); static;
    class function AcceleratorCount(const AText: string): Integer; static;
    class function PlaceholderSignature(const AText: string): string; static;
  public
    class function Validate(
      const ACatalog: TTranslationCatalog): TCatalogValidationResult; static;
  end;

function ValidationSeverityDisplayName(
  const ASeverity: TValidationSeverity): string;

implementation

uses
  System.Classes,
  System.SysUtils;

constructor TCatalogValidationResult.Create;
begin
  inherited Create;
  FIssues := TObjectList<TValidationIssue>.Create(True);
end;

destructor TCatalogValidationResult.Destroy;
begin
  FIssues.Free;
  inherited Destroy;
end;

function TCatalogValidationResult.CountBySeverity(
  const ASeverity: TValidationSeverity): Integer;
var
  Issue: TValidationIssue;
begin
  Result := 0;
  for Issue in FIssues do
    if Issue.Severity = ASeverity then
      Inc(Result);
end;

function TCatalogValidationResult.HasErrors: Boolean;
begin
  Result := CountBySeverity(vsError) > 0;
end;

class procedure TCatalogValidator.AddIssue(
  const AResult: TCatalogValidationResult;
  const ASeverity: TValidationSeverity; const ACode, AEntryKey,
  AMessage: string);
var
  Issue: TValidationIssue;
begin
  Issue := TValidationIssue.Create;
  Issue.Severity := ASeverity;
  Issue.Code := ACode;
  Issue.EntryKey := AEntryKey;
  Issue.MessageText := AMessage;
  AResult.Issues.Add(Issue);
end;

class function TCatalogValidator.AcceleratorCount(
  const AText: string): Integer;
var
  CharacterIndex: Integer;
begin
  Result := 0;
  CharacterIndex := 1;
  while CharacterIndex <= Length(AText) do
  begin
    if AText[CharacterIndex] = '&' then
    begin
      if (CharacterIndex < Length(AText)) and
        (AText[CharacterIndex + 1] = '&') then
        Inc(CharacterIndex)
      else
        Inc(Result);
    end;
    Inc(CharacterIndex);
  end;
end;

class function TCatalogValidator.PlaceholderSignature(
  const AText: string): string;
const
  FormatTypes = ['D', 'E', 'F', 'G', 'M', 'N', 'P', 'S', 'U', 'X',
    'd', 'e', 'f', 'g', 'm', 'n', 'p', 's', 'u', 'x'];
var
  ArgumentIndex: Integer;
  BraceEnd: Integer;
  CharacterIndex: Integer;
  ExplicitIndex: Integer;
  FormatType: Char;
  NextArgumentIndex: Integer;
  IndexText: string;
  ScanIndex: Integer;
  Placeholders: TStringList;

  function TypeGroup(const AType: Char): string;
  begin
    case AType of
      'D', 'U', 'X', 'd', 'u', 'x':
        Result := 'integer';
      'E', 'F', 'G', 'M', 'N', 'e', 'f', 'g', 'm', 'n':
        Result := 'float';
      'P', 'p':
        Result := 'pointer';
    else
      Result := 'string';
    end;
  end;

  procedure AddArgument(const AIndex: Integer; const AType: Char);
  var
    ExistingIndex: Integer;
    Value: string;
  begin
    Value := Format('arg:%d=%s', [AIndex, TypeGroup(AType)]);
    ExistingIndex := Placeholders.IndexOf(Value);
    if ExistingIndex < 0 then
      Placeholders.Add(Value);
  end;

begin
  Placeholders := TStringList.Create;
  try
    Placeholders.CaseSensitive := False;
    Placeholders.Sorted := True;
    Placeholders.Duplicates := dupIgnore;
    NextArgumentIndex := 0;
    CharacterIndex := 1;
    while CharacterIndex <= Length(AText) do
    begin
      if AText[CharacterIndex] = '%' then
      begin
        if (CharacterIndex < Length(AText)) and
          (AText[CharacterIndex + 1] = '%') then
        begin
          Inc(CharacterIndex, 2);
          Continue;
        end;
        ScanIndex := CharacterIndex + 1;
        ExplicitIndex := -1;
        IndexText := '';
        while (ScanIndex <= Length(AText)) and
          CharInSet(AText[ScanIndex], ['0'..'9']) do
        begin
          IndexText := IndexText + AText[ScanIndex];
          Inc(ScanIndex);
        end;
        if (IndexText <> '') and (ScanIndex <= Length(AText)) and
           (AText[ScanIndex] = ':') then
        begin
          ExplicitIndex := StrToIntDef(IndexText, -1);
          Inc(ScanIndex);
        end
        else
          ScanIndex := CharacterIndex + 1;
        while (ScanIndex <= Length(AText)) and
          not CharInSet(AText[ScanIndex], FormatTypes) do
          Inc(ScanIndex);
        if ScanIndex <= Length(AText) then
        begin
          FormatType := AText[ScanIndex];
          if ExplicitIndex >= 0 then
            ArgumentIndex := ExplicitIndex
          else
            ArgumentIndex := NextArgumentIndex;
          AddArgument(ArgumentIndex, FormatType);
          NextArgumentIndex := ArgumentIndex + 1;
          CharacterIndex := ScanIndex;
        end;
      end
      else if AText[CharacterIndex] = '{' then
      begin
        BraceEnd := Pos('}', AText, CharacterIndex + 1);
        if BraceEnd > CharacterIndex + 1 then
        begin
          Placeholders.Add('brace:' + LowerCase(
            Copy(AText, CharacterIndex,
              BraceEnd - CharacterIndex + 1)));
          CharacterIndex := BraceEnd;
        end;
      end;
      Inc(CharacterIndex);
    end;
    Result := Placeholders.CommaText;
  finally
    Placeholders.Free;
  end;
end;

class function TCatalogValidator.Validate(
  const ACatalog: TTranslationCatalog): TCatalogValidationResult;
var
  Entry: TTranslationEntry;
  KnownKeys: TStringList;
begin
  Result := TCatalogValidationResult.Create;
  if ACatalog = nil then
  begin
    AddIssue(Result, vsError, 'catalog.missing', '',
      'No translation catalog is loaded.');
    Exit;
  end;

  if Trim(ACatalog.ApplicationId) = '' then
    AddIssue(Result, vsError, 'catalog.applicationId', '',
      'Application identifier is required.');
  if ACatalog.Framework = tfUnknown then
    AddIssue(Result, vsError, 'catalog.framework', '',
      'The target framework is unknown.');
  if Trim(ACatalog.SourceLanguage) = '' then
    AddIssue(Result, vsError, 'catalog.sourceLanguage', '',
      'Source language code is required.');
  if Trim(ACatalog.Locale.LanguageCode) = '' then
    AddIssue(Result, vsError, 'locale.languageCode', '',
      'Target language code is required.');
  if Trim(ACatalog.Locale.NativeLanguageName) = '' then
    AddIssue(Result, vsError, 'locale.nativeName', '',
      'Target language native name is required.');
  if not SameText(ACatalog.Locale.TextDirection, 'ltr') and
    not SameText(ACatalog.Locale.TextDirection, 'rtl') then
    AddIssue(Result, vsError, 'locale.direction', '',
      'Text direction must be ltr or rtl.');
  if Trim(ACatalog.Locale.ShortDateFormat) = '' then
    AddIssue(Result, vsError, 'locale.shortDateFormat', '',
      'Short date format is required.');
  if Trim(ACatalog.Locale.ShortTimeFormat) = '' then
    AddIssue(Result, vsError, 'locale.shortTimeFormat', '',
      'Short time format is required.');
  if ACatalog.Locale.DecimalSeparator = '' then
    AddIssue(Result, vsError, 'locale.decimalSeparator', '',
      'Decimal separator is required.');
  if (ACatalog.Locale.ThousandSeparator <> '') and
    (ACatalog.Locale.DecimalSeparator =
     ACatalog.Locale.ThousandSeparator) then
    AddIssue(Result, vsError, 'locale.numberSeparators', '',
      'Decimal and thousands separators must differ.');

  KnownKeys := TStringList.Create;
  try
    KnownKeys.CaseSensitive := False;
    KnownKeys.Sorted := True;
    KnownKeys.Duplicates := dupIgnore;
    for Entry in ACatalog.Entries do
    begin
      if KnownKeys.IndexOf(Entry.Key) >= 0 then
        AddIssue(Result, vsError, 'entry.duplicateKey', Entry.Key,
          'The catalog contains a duplicate key.')
      else
        KnownKeys.Add(Entry.Key);

      if Entry.Status in [tsExcluded, tsObsolete] then
        Continue;

      if Entry.SourceText = '' then
        AddIssue(Result, vsError, 'entry.emptySource', Entry.Key,
          'Source text is empty.');
      if Trim(Entry.TranslatedText) = '' then
        AddIssue(Result, vsError, 'entry.untranslated', Entry.Key,
          'Translation is required before export.')
      else
      begin
        if PlaceholderSignature(Entry.SourceText) <>
          PlaceholderSignature(Entry.TranslatedText) then
          AddIssue(Result, vsError, 'entry.placeholders', Entry.Key,
            'Source and translation placeholders do not match.');
        if AcceleratorCount(Entry.SourceText) <>
          AcceleratorCount(Entry.TranslatedText) then
          AddIssue(Result, vsWarning, 'entry.accelerators', Entry.Key,
            'Source and translation accelerator counts differ.');
        if SameText(Entry.SourceText, Entry.TranslatedText) then
          AddIssue(Result, vsWarning, 'entry.sameText', Entry.Key,
            'Translation is identical to the source text.');
      end;

      if Entry.Status = tsSourceChanged then
        AddIssue(Result, vsError, 'entry.sourceChanged', Entry.Key,
          'Changed source text must be reviewed before export.');
      if (Entry.RuntimeApplication = rakManualTranslateText) and
         not Entry.RuntimeWiringConfirmed then
        AddIssue(Result, vsWarning, 'entry.runtimeWiring', Entry.Key,
          'Pascal resourcestring requires a confirmed TranslateText call.');
    end;
  finally
    KnownKeys.Free;
  end;
end;

function ValidationSeverityDisplayName(
  const ASeverity: TValidationSeverity): string;
begin
  case ASeverity of
    vsInformation:
      Result := 'Information';
    vsWarning:
      Result := 'Warning';
    vsError:
      Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

end.
