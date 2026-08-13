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
    tsAIDraft,
    tsMachineTranslated,
    tsImported,
    tsEdited,
    tsReviewed,
    tsApproved,
    tsSourceChanged,
    tsExcluded,
    tsObsolete,
    tsError
  );

  TTranslationOrigin = (
    torUnknown,
    torCodex,
    torClaude,
    torGoogle,
    torDeepL,
    torHuman,
    torImported,
    torSuggestion,
    torTerminology,
    torProjectGlossary
  );

  TRuntimeApplicationKind = (
    rakAutomatic,
    rakManualTranslateText,
    rakNotApplied
  );

  TRuntimeTextRole = (
    rtrStaticText,
    rtrDynamicValue,
    rtrRuntimeTemplate,
    rtrDataValue,
    rtrIdentifier,
    rtrExcluded
  );

  TTextOwnershipKind = (
    tokDesignerAutomatic,
    tokRuntimeWired,
    tokRuntimeUnwired,
    tokApplicationData,
    tokSuspicious,
    tokExcluded
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
    FTranslationOrigin: TTranslationOrigin;
    FTranslationConfidence: string;
    FTranslationReviewNote: string;
    FStatus: TTranslationStatus;
    FRuntimeApplication: TRuntimeApplicationKind;
    FRuntimeTextRole: TRuntimeTextRole;
    FRuntimeWiringConfirmed: Boolean;
    FContextKind: string;
    FContextDescription: string;
    FSemanticConcept: string;
    FContextConfidence: string;
    FFontColor: string;
    FTextOwnership: TTextOwnershipKind;
    FSuspiciousReason: string;
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
    property TranslationOrigin: TTranslationOrigin read FTranslationOrigin
      write FTranslationOrigin;
    property TranslationConfidence: string read FTranslationConfidence
      write FTranslationConfidence;
    property TranslationReviewNote: string read FTranslationReviewNote
      write FTranslationReviewNote;
    property Status: TTranslationStatus read FStatus write FStatus;
    property RuntimeApplication: TRuntimeApplicationKind
      read FRuntimeApplication write FRuntimeApplication;
    property RuntimeTextRole: TRuntimeTextRole read FRuntimeTextRole
      write FRuntimeTextRole;
    property RuntimeWiringConfirmed: Boolean read FRuntimeWiringConfirmed
      write FRuntimeWiringConfirmed;
    property ContextKind: string read FContextKind write FContextKind;
    property ContextDescription: string read FContextDescription
      write FContextDescription;
    property SemanticConcept: string read FSemanticConcept
      write FSemanticConcept;
    property ContextConfidence: string read FContextConfidence
      write FContextConfidence;
    property FontColor: string read FFontColor write FFontColor;
    property TextOwnership: TTextOwnershipKind read FTextOwnership
      write FTextOwnership;
    property SuspiciousReason: string read FSuspiciousReason
      write FSuspiciousReason;
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
function TranslationOriginToString(const AOrigin: TTranslationOrigin): string;
function StringToTranslationOrigin(const AValue: string): TTranslationOrigin;
function TranslationOriginDisplayName(const AOrigin: TTranslationOrigin): string;
function RuntimeApplicationKindToString(
  const AKind: TRuntimeApplicationKind): string;
function StringToRuntimeApplicationKind(
  const AValue: string): TRuntimeApplicationKind;
function RuntimeApplicationDisplayName(
  const AKind: TRuntimeApplicationKind): string;
function RuntimeTextRoleToString(const ARole: TRuntimeTextRole): string;
function StringToRuntimeTextRole(const AValue: string): TRuntimeTextRole;
function RuntimeTextRoleDisplayName(const ARole: TRuntimeTextRole): string;
function RuntimeTextRoleRequiresTranslation(
  const ARole: TRuntimeTextRole): Boolean;
function RuntimeTextRoleIsAutomaticallyApplied(
  const ARole: TRuntimeTextRole): Boolean;
function TextOwnershipKindToString(const AKind: TTextOwnershipKind): string;
function StringToTextOwnershipKind(const AValue: string): TTextOwnershipKind;
function TextOwnershipDisplayName(const AKind: TTextOwnershipKind): string;
function TranslationEntryEligibleForAutomaticTranslation(
  const AEntry: TTranslationEntry): Boolean;
function ProjectPlatformsDisplayName(const AProfile: TProjectProfile): string;

implementation

uses
  System.SysUtils;

constructor TTranslationCatalog.Create;
begin
  inherited Create;
  FSchemaVersion := 6;
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
    tsAIDraft:
      Result := 'aiDraft';
    tsMachineTranslated:
      Result := 'machineTranslated';
    tsImported:
      Result := 'imported';
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
  if SameText(AValue, 'aiDraft') then
    Result := tsAIDraft
  else if SameText(AValue, 'machineTranslated') then
    Result := tsMachineTranslated
  else if SameText(AValue, 'imported') then
    Result := tsImported
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

function TranslationOriginToString(
  const AOrigin: TTranslationOrigin): string;
begin
  case AOrigin of
    torCodex:
      Result := 'codex';
    torClaude:
      Result := 'claude';
    torGoogle:
      Result := 'google';
    torDeepL:
      Result := 'deepL';
    torHuman:
      Result := 'human';
    torImported:
      Result := 'imported';
    torSuggestion:
      Result := 'suggestion';
    torTerminology:
      Result := 'terminology';
    torProjectGlossary:
      Result := 'projectGlossary';
  else
    Result := 'unknown';
  end;
end;

function StringToTranslationOrigin(
  const AValue: string): TTranslationOrigin;
begin
  if SameText(AValue, 'codex') then
    Result := torCodex
  else if SameText(AValue, 'claude') then
    Result := torClaude
  else if SameText(AValue, 'google') then
    Result := torGoogle
  else if SameText(AValue, 'deepL') or SameText(AValue, 'deepl') then
    Result := torDeepL
  else if SameText(AValue, 'human') then
    Result := torHuman
  else if SameText(AValue, 'imported') then
    Result := torImported
  else if SameText(AValue, 'suggestion') then
    Result := torSuggestion
  else if SameText(AValue, 'terminology') then
    Result := torTerminology
  else if SameText(AValue, 'projectGlossary') then
    Result := torProjectGlossary
  else
    Result := torUnknown;
end;

function TranslationOriginDisplayName(
  const AOrigin: TTranslationOrigin): string;
begin
  case AOrigin of
    torCodex:
      Result := 'Codex';
    torClaude:
      Result := 'Claude';
    torGoogle:
      Result := 'Google';
    torDeepL:
      Result := 'DeepL';
    torHuman:
      Result := 'Human';
    torImported:
      Result := 'Imported';
    torSuggestion:
      Result := 'Translation memory / catalog suggestion';
    torTerminology:
      Result := 'Approved UI terminology';
    torProjectGlossary:
      Result := 'Approved project glossary';
  else
    Result := 'Unknown';
  end;
end;

function RuntimeApplicationKindToString(
  const AKind: TRuntimeApplicationKind): string;
begin
  case AKind of
    rakManualTranslateText:
      Result := 'manualTranslateText';
    rakNotApplied:
      Result := 'notApplied';
  else
    Result := 'automatic';
  end;
end;

function StringToRuntimeApplicationKind(
  const AValue: string): TRuntimeApplicationKind;
begin
  if SameText(AValue, 'manualTranslateText') then
    Result := rakManualTranslateText
  else if SameText(AValue, 'notApplied') then
    Result := rakNotApplied
  else
    Result := rakAutomatic;
end;

function RuntimeApplicationDisplayName(
  const AKind: TRuntimeApplicationKind): string;
begin
  case AKind of
    rakManualTranslateText:
      Result := 'Manual: TranslateText call required';
    rakNotApplied:
      Result := 'Protected: not applied to controls';
  else
    Result := 'Automatic: form runtime adapter';
  end;
end;

function RuntimeTextRoleToString(const ARole: TRuntimeTextRole): string;
begin
  case ARole of
    rtrDynamicValue:
      Result := 'dynamicValue';
    rtrRuntimeTemplate:
      Result := 'runtimeTemplate';
    rtrDataValue:
      Result := 'dataValue';
    rtrIdentifier:
      Result := 'identifier';
    rtrExcluded:
      Result := 'excluded';
  else
    Result := 'staticText';
  end;
end;

function StringToRuntimeTextRole(const AValue: string): TRuntimeTextRole;
begin
  if SameText(AValue, 'dynamicValue') then
    Result := rtrDynamicValue
  else if SameText(AValue, 'runtimeTemplate') then
    Result := rtrRuntimeTemplate
  else if SameText(AValue, 'dataValue') then
    Result := rtrDataValue
  else if SameText(AValue, 'identifier') then
    Result := rtrIdentifier
  else if SameText(AValue, 'excluded') then
    Result := rtrExcluded
  else
    Result := rtrStaticText;
end;

function RuntimeTextRoleDisplayName(const ARole: TRuntimeTextRole): string;
begin
  case ARole of
    rtrDynamicValue:
      Result := 'Dynamic runtime value';
    rtrRuntimeTemplate:
      Result := 'Runtime message template';
    rtrDataValue:
      Result := 'Application or user data';
    rtrIdentifier:
      Result := 'Identifier or technical value';
    rtrExcluded:
      Result := 'Excluded content';
  else
    Result := 'Static interface text';
  end;
end;

function RuntimeTextRoleRequiresTranslation(
  const ARole: TRuntimeTextRole): Boolean;
begin
  Result := ARole in [rtrStaticText, rtrDynamicValue, rtrRuntimeTemplate];
end;

function RuntimeTextRoleIsAutomaticallyApplied(
  const ARole: TRuntimeTextRole): Boolean;
begin
  Result := ARole = rtrStaticText;
end;

function TextOwnershipKindToString(const AKind: TTextOwnershipKind): string;
begin
  case AKind of
    tokRuntimeWired: Result := 'runtimeWired';
    tokRuntimeUnwired: Result := 'runtimeUnwired';
    tokApplicationData: Result := 'applicationData';
    tokSuspicious: Result := 'suspicious';
    tokExcluded: Result := 'excluded';
  else
    Result := 'designerAutomatic';
  end;
end;

function StringToTextOwnershipKind(const AValue: string): TTextOwnershipKind;
begin
  if SameText(AValue, 'runtimeWired') then Result := tokRuntimeWired
  else if SameText(AValue, 'runtimeUnwired') then Result := tokRuntimeUnwired
  else if SameText(AValue, 'applicationData') then Result := tokApplicationData
  else if SameText(AValue, 'suspicious') then Result := tokSuspicious
  else if SameText(AValue, 'excluded') then Result := tokExcluded
  else Result := tokDesignerAutomatic;
end;

function TextOwnershipDisplayName(const AKind: TTextOwnershipKind): string;
begin
  case AKind of
    tokRuntimeWired: Result := 'Runtime-generated: translation wiring confirmed';
    tokRuntimeUnwired: Result := 'Runtime-generated: translation wiring required';
    tokApplicationData: Result := 'Application or user data';
    tokSuspicious: Result := 'Suspicious source text: developer review required';
    tokExcluded: Result := 'Protected or excluded text';
  else
    Result := 'Designer text: applied automatically on managed forms';
  end;
end;

function TranslationEntryEligibleForAutomaticTranslation(
  const AEntry: TTranslationEntry): Boolean;
begin
  Result := (AEntry <> nil) and
    RuntimeTextRoleRequiresTranslation(AEntry.RuntimeTextRole) and
    (AEntry.TextOwnership <> tokSuspicious) and
    (Trim(AEntry.SuspiciousReason) = '');
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
