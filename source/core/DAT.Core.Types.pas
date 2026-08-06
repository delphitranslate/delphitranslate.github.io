unit DAT.Core.Types;

interface

uses
  System.Generics.Collections;

type
  TTargetFramework = (
    tfUnknown,
    tfVCL,
    tfFireMonkey
  );

  TTranslationStatus = (
    tsNeedsTranslation,
    tsMachineTranslated,
    tsEdited,
    tsReviewed,
    tsApproved,
    tsSourceChanged,
    tsExcluded,
    tsObsolete,
    tsError
  );

  TProjectProfile = record
    ProjectFileName: string;
    ProjectName: string;
    Framework: TTargetFramework;
    SupportsWin32: Boolean;
    SupportsWin64: Boolean;
    FormResourceCount: Integer;
    SourceFileCount: Integer;
  end;

  TLocaleProfile = class
  private
    FLanguageCode: string;
    FNativeLanguageName: string;
    FTextDirection: string;
    FShortDateFormat: string;
    FLongDateFormat: string;
    FShortTimeFormat: string;
    FLongTimeFormat: string;
    FDecimalSeparator: string;
    FThousandSeparator: string;
    FCurrencySymbol: string;
  public
    property LanguageCode: string read FLanguageCode write FLanguageCode;
    property NativeLanguageName: string read FNativeLanguageName write FNativeLanguageName;
    property TextDirection: string read FTextDirection write FTextDirection;
    property ShortDateFormat: string read FShortDateFormat write FShortDateFormat;
    property LongDateFormat: string read FLongDateFormat write FLongDateFormat;
    property ShortTimeFormat: string read FShortTimeFormat write FShortTimeFormat;
    property LongTimeFormat: string read FLongTimeFormat write FLongTimeFormat;
    property DecimalSeparator: string read FDecimalSeparator write FDecimalSeparator;
    property ThousandSeparator: string read FThousandSeparator write FThousandSeparator;
    property CurrencySymbol: string read FCurrencySymbol write FCurrencySymbol;
  end;

  TTranslationEntry = class
  private
    FKey: string;
    FSourceText: string;
    FTranslatedText: string;
    FFormName: string;
    FComponentName: string;
    FComponentClassName: string;
    FPropertyName: string;
    FSourceFileName: string;
    FSourceLine: Integer;
    FSourceKind: string;
    FSourceChecksum: string;
    FDeveloperNote: string;
    FStatus: TTranslationStatus;
  public
    property Key: string read FKey write FKey;
    property SourceText: string read FSourceText write FSourceText;
    property TranslatedText: string read FTranslatedText write FTranslatedText;
    property FormName: string read FFormName write FFormName;
    property ComponentName: string read FComponentName write FComponentName;
    property ComponentClassName: string read FComponentClassName write FComponentClassName;
    property PropertyName: string read FPropertyName write FPropertyName;
    property SourceFileName: string read FSourceFileName write FSourceFileName;
    property SourceLine: Integer read FSourceLine write FSourceLine;
    property SourceKind: string read FSourceKind write FSourceKind;
    property SourceChecksum: string read FSourceChecksum write FSourceChecksum;
    property DeveloperNote: string read FDeveloperNote write FDeveloperNote;
    property Status: TTranslationStatus read FStatus write FStatus;
  end;

  TTranslationCatalog = class
  private
    FSchemaVersion: Integer;
    FApplicationId: string;
    FApplicationVersion: string;
    FFramework: TTargetFramework;
    FSourceLanguage: string;
    FLocale: TLocaleProfile;
    FEntries: TObjectList<TTranslationEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    function FindEntry(const AKey: string): TTranslationEntry;
    function CountByStatus(const AStatus: TTranslationStatus): Integer;
    property SchemaVersion: Integer read FSchemaVersion write FSchemaVersion;
    property ApplicationId: string read FApplicationId write FApplicationId;
    property ApplicationVersion: string read FApplicationVersion write FApplicationVersion;
    property Framework: TTargetFramework read FFramework write FFramework;
    property SourceLanguage: string read FSourceLanguage write FSourceLanguage;
    property Locale: TLocaleProfile read FLocale;
    property Entries: TObjectList<TTranslationEntry> read FEntries;
  end;

function TargetFrameworkToString(const AFramework: TTargetFramework): string;
function StringToTargetFramework(const AValue: string): TTargetFramework;
function TranslationStatusToString(const AStatus: TTranslationStatus): string;
function StringToTranslationStatus(const AValue: string): TTranslationStatus;
function ProjectPlatformsDisplayName(const AProfile: TProjectProfile): string;

implementation

uses
  System.SysUtils;

constructor TTranslationCatalog.Create;
begin
  inherited Create;
  FSchemaVersion := 1;
  FFramework := tfUnknown;
  FLocale := TLocaleProfile.Create;
  FLocale.TextDirection := 'ltr';
  FEntries := TObjectList<TTranslationEntry>.Create(True);
end;

destructor TTranslationCatalog.Destroy;
begin
  FEntries.Free;
  FLocale.Free;
  inherited Destroy;
end;

function TTranslationCatalog.FindEntry(const AKey: string): TTranslationEntry;
var
  Entry: TTranslationEntry;
begin
  Result := nil;
  for Entry in FEntries do
    if SameText(Entry.Key, AKey) then
      Exit(Entry);
end;

function TTranslationCatalog.CountByStatus(
  const AStatus: TTranslationStatus): Integer;
var
  Entry: TTranslationEntry;
begin
  Result := 0;
  for Entry in FEntries do
    if Entry.Status = AStatus then
      Inc(Result);
end;

function TargetFrameworkToString(const AFramework: TTargetFramework): string;
begin
  case AFramework of
    tfVCL:
      Result := 'VCL';
    tfFireMonkey:
      Result := 'FireMonkey';
  else
    Result := 'Unknown';
  end;
end;

function StringToTargetFramework(const AValue: string): TTargetFramework;
begin
  if SameText(AValue, 'VCL') then
    Result := tfVCL
  else if SameText(AValue, 'FireMonkey') or SameText(AValue, 'FMX') then
    Result := tfFireMonkey
  else
    Result := tfUnknown;
end;

function TranslationStatusToString(
  const AStatus: TTranslationStatus): string;
begin
  case AStatus of
    tsNeedsTranslation:
      Result := 'needsTranslation';
    tsMachineTranslated:
      Result := 'machineTranslated';
    tsEdited:
      Result := 'edited';
    tsReviewed:
      Result := 'reviewed';
    tsApproved:
      Result := 'approved';
    tsSourceChanged:
      Result := 'sourceChanged';
    tsExcluded:
      Result := 'excluded';
    tsObsolete:
      Result := 'obsolete';
    tsError:
      Result := 'error';
  else
    Result := 'needsTranslation';
  end;
end;

function StringToTranslationStatus(
  const AValue: string): TTranslationStatus;
begin
  if SameText(AValue, 'machineTranslated') then
    Result := tsMachineTranslated
  else if SameText(AValue, 'edited') then
    Result := tsEdited
  else if SameText(AValue, 'reviewed') then
    Result := tsReviewed
  else if SameText(AValue, 'approved') then
    Result := tsApproved
  else if SameText(AValue, 'sourceChanged') then
    Result := tsSourceChanged
  else if SameText(AValue, 'excluded') then
    Result := tsExcluded
  else if SameText(AValue, 'obsolete') then
    Result := tsObsolete
  else if SameText(AValue, 'error') then
    Result := tsError
  else
    Result := tsNeedsTranslation;
end;

function ProjectPlatformsDisplayName(const AProfile: TProjectProfile): string;
begin
  if AProfile.SupportsWin32 and AProfile.SupportsWin64 then
    Result := 'Win32, Win64'
  else if AProfile.SupportsWin32 then
    Result := 'Win32'
  else if AProfile.SupportsWin64 then
    Result := 'Win64'
  else
    Result := 'Not declared';
end;

end.
