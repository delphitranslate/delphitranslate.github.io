unit DAT.Components.Core;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.Manager;

type
  EDATLanguageManagerError = class(Exception);
  EDATLanguageManagerConfigurationError = class(EDATLanguageManagerError);
  EDATLanguageManagerMainThreadError = class(EDATLanguageManagerError);
  EDATLanguageManagerReentrancyError = class(EDATLanguageManagerError);
  EDATFormIdentityError = class(EDATLanguageManagerError);

  TDATPreferenceLocation = (plLocalAppData, plExecutableFolder,
    plCustomFolder);
  TDATMissingPackBehavior = (mpUseSourceLanguage, mpKeepCurrentLanguage,
    mpRaiseError);
  TDATErrorBehavior = (ebNotifyAndContinue, ebRaiseException);

  TDATLanguageChangingEvent = procedure(Sender: TObject;
    const AOldLanguage, ANewLanguage: string; var AAllow: Boolean) of object;
  TDATLanguageChangedEvent = procedure(Sender: TObject;
    const AOldLanguage, ANewLanguage: string;
    const AGeneration: Cardinal) of object;
  TDATManagedObjectTranslatedEvent = procedure(Sender: TObject;
    const AManagedObject: TObject; const AFormIdentity: string;
    const AAppliedPropertyCount: Integer; const AElapsedMilliseconds: Double;
    const AGeneration: Cardinal) of object;
  TDATTranslationErrorEvent = procedure(Sender: TObject;
    const AContext, AMessage: string; var AHandled: Boolean) of object;
  TDATMissingTranslationEvent = procedure(Sender: TObject;
    const AFormIdentity, AKey, AFallbackText: string) of object;

  TDATCustomLanguageManager = class abstract(TComponent)
  private
    FApplicationId: string;
    FLanguagesFolder: string;
    FSourceLanguage: string;
    FActiveLanguage: string;
    FAutoLoadPreferred: Boolean;
    FAutoTranslateOwner: Boolean;
    FAutoTranslateNewForms: Boolean;
    FReapplyOpenForms: Boolean;
    FTranslateHiddenForms: Boolean;
    FPreserveControlState: Boolean;
    FPreferenceLocation: TDATPreferenceLocation;
    FPreferenceFileName: string;
    FCustomPreferenceFolder: string;
    FMissingPackBehavior: TDATMissingPackBehavior;
    FErrorBehavior: TDATErrorBehavior;
    FExcludedForms: TStringList;
    FFormIdentityMappings: TStringList;
    FFormIdentities: TDictionary<string, string>;
    FAppliedGenerations: TDictionary<TObject, Cardinal>;
    FRuntime: TTranslationRuntime;
    FGeneration: Cardinal;
    FInitialized: Boolean;
    FInitializing: Boolean;
    FSelectingLanguage: Boolean;
    FApplying: Boolean;
    FEnableDiagnostics: Boolean;
    FOnLanguageChanging: TDATLanguageChangingEvent;
    FOnLanguageChanged: TDATLanguageChangedEvent;
    FOnManagedObjectTranslated: TDATManagedObjectTranslatedEvent;
    FOnTranslationError: TDATTranslationErrorEvent;
    FOnMissingTranslation: TDATMissingTranslationEvent;
    procedure SetApplicationId(const Value: string);
    procedure SetLanguagesFolder(const Value: string);
    procedure SetSourceLanguage(const Value: string);
    procedure SetPreferenceLocation(const Value: TDATPreferenceLocation);
    procedure SetPreferenceFileName(const Value: string);
    procedure SetCustomPreferenceFolder(const Value: string);
    procedure SetExcludedForms(const Value: TStrings);
    procedure SetFormIdentityMappings(const Value: TStrings);
    function GetExcludedForms: TStrings;
    function GetFormIdentityMappings: TStrings;
    procedure FormIdentityMappingsChanged(Sender: TObject);
    procedure RebuildFormIdentityMap;
    procedure CheckConfigurationMutable;
    procedure CheckMainThread;
    procedure CheckNotReentrant(const AOperation: string);
    function HandleFailure(const AContext: string;
      const AException: Exception): Boolean;
    function ResolveLanguagesDirectory: string;
    function ResolvePreferencePath: string;
    procedure AdvanceGeneration;
    function GetActivePack: TRuntimeLanguagePack;
    function IsExcluded(const AManagedObject: TObject;
      const AIdentity, AInstanceName: string): Boolean;
    function ApplyToManagedObjectInternal(const AManagedObject: TObject;
      const AForce: Boolean): Integer;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; virtual; abstract;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; virtual; abstract;
    function ApplyLanguagePack(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; virtual; abstract;
    procedure CollectOpenManagedObjects(
      const AObjects: TList<TObject>); virtual; abstract;
    procedure NotifyMissingTranslation(const AFormIdentity, AKey,
      AFallbackText: string);
    property Runtime: TTranslationRuntime read FRuntime;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Initialize: Boolean;
    function SelectLanguage(const ALanguageCode: string): Boolean;
    function ApplyToManagedObject(const AManagedObject: TObject): Integer;
    function ReapplyToManagedObject(const AManagedObject: TObject): Integer;
    procedure ApplyToOpenForms;
    procedure RemoveManagedObject(const AManagedObject: TObject);
    procedure InvalidateTranslations(const AApplyImmediately: Boolean = True);
    function WasAppliedInCurrentGeneration(
      const AManagedObject: TObject): Boolean;
    function TrackedObjectCount: Integer;
    function ResolveFormIdentity(const AManagedObject: TObject;
      const AInstanceName: string): string;
    procedure RegisterFormIdentity(const AClassName,
      AResourceRootName: string);
    function AvailableLanguages: TObjectList<TLanguagePackDescriptor>;
    function Translate(const AKey, AFallbackText: string): string;
    function FormatTemplate(const AKey, AFallbackText: string;
      const AArgs: array of const): string;
    function CurrentFormatSettings: TFormatSettings;
    property ActiveLanguage: string read FActiveLanguage;
    property ActivePack: TRuntimeLanguagePack read GetActivePack;
    property Generation: Cardinal read FGeneration;
    property Initialized: Boolean read FInitialized;
  published
    property ApplicationId: string read FApplicationId write SetApplicationId;
    property LanguagesFolder: string read FLanguagesFolder
      write SetLanguagesFolder;
    property SourceLanguage: string read FSourceLanguage
      write SetSourceLanguage;
    property AutoLoadPreferred: Boolean read FAutoLoadPreferred
      write FAutoLoadPreferred default True;
    property AutoTranslateOwner: Boolean read FAutoTranslateOwner
      write FAutoTranslateOwner default True;
    property AutoTranslateNewForms: Boolean read FAutoTranslateNewForms
      write FAutoTranslateNewForms default True;
    property ReapplyOpenForms: Boolean read FReapplyOpenForms
      write FReapplyOpenForms default True;
    property TranslateHiddenForms: Boolean read FTranslateHiddenForms
      write FTranslateHiddenForms default False;
    property PreserveControlState: Boolean read FPreserveControlState
      write FPreserveControlState default True;
    property PreferenceLocation: TDATPreferenceLocation
      read FPreferenceLocation write SetPreferenceLocation
      default plLocalAppData;
    property PreferenceFileName: string read FPreferenceFileName
      write SetPreferenceFileName;
    property CustomPreferenceFolder: string read FCustomPreferenceFolder
      write SetCustomPreferenceFolder;
    property MissingPackBehavior: TDATMissingPackBehavior
      read FMissingPackBehavior write FMissingPackBehavior
      default mpUseSourceLanguage;
    property ErrorBehavior: TDATErrorBehavior read FErrorBehavior
      write FErrorBehavior default ebNotifyAndContinue;
    property ExcludedForms: TStrings read GetExcludedForms
      write SetExcludedForms;
    property FormIdentityMappings: TStrings read GetFormIdentityMappings
      write SetFormIdentityMappings;
    property EnableDiagnostics: Boolean read FEnableDiagnostics
      write FEnableDiagnostics default False;
    property OnLanguageChanging: TDATLanguageChangingEvent
      read FOnLanguageChanging write FOnLanguageChanging;
    property OnLanguageChanged: TDATLanguageChangedEvent
      read FOnLanguageChanged write FOnLanguageChanged;
    property OnFormTranslated: TDATManagedObjectTranslatedEvent
      read FOnManagedObjectTranslated write FOnManagedObjectTranslated;
    property OnTranslationError: TDATTranslationErrorEvent
      read FOnTranslationError write FOnTranslationError;
    property OnMissingTranslation: TDATMissingTranslationEvent
      read FOnMissingTranslation write FOnMissingTranslation;
  end;

implementation

uses
  System.Diagnostics,
  System.IOUtils;

constructor TDATCustomLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLanguagesFolder := 'Localization\Languages';
  FSourceLanguage := 'en-US';
  FPreferenceFileName := 'language.ini';
  FAutoLoadPreferred := True;
  FAutoTranslateOwner := True;
  FAutoTranslateNewForms := True;
  FReapplyOpenForms := True;
  FPreserveControlState := True;
  FPreferenceLocation := plLocalAppData;
  FMissingPackBehavior := mpUseSourceLanguage;
  FErrorBehavior := ebNotifyAndContinue;
  FExcludedForms := TStringList.Create;
  FExcludedForms.CaseSensitive := False;
  FExcludedForms.Duplicates := dupIgnore;
  FExcludedForms.Sorted := True;
  FFormIdentityMappings := TStringList.Create;
  FFormIdentityMappings.CaseSensitive := False;
  FFormIdentityMappings.NameValueSeparator := '=';
  FFormIdentityMappings.OnChange := FormIdentityMappingsChanged;
  FFormIdentities := TDictionary<string, string>.Create;
  FAppliedGenerations := TDictionary<TObject, Cardinal>.Create;
end;

destructor TDATCustomLanguageManager.Destroy;
begin
  FRuntime.Free;
  FAppliedGenerations.Free;
  FFormIdentities.Free;
  FFormIdentityMappings.Free;
  FExcludedForms.Free;
  inherited Destroy;
end;

function TDATCustomLanguageManager.GetActivePack: TRuntimeLanguagePack;
begin
  if FRuntime = nil then
    Result := nil
  else
    Result := FRuntime.ActivePack;
end;

procedure TDATCustomLanguageManager.AdvanceGeneration;
begin
  Inc(FGeneration);
  if FGeneration = 0 then
    Inc(FGeneration);
end;

function TDATCustomLanguageManager.ApplyToManagedObject(
  const AManagedObject: TObject): Integer;
begin
  Result := ApplyToManagedObjectInternal(AManagedObject, False);
end;

function TDATCustomLanguageManager.ApplyToManagedObjectInternal(
  const AManagedObject: TObject; const AForce: Boolean): Integer;
var
  ElapsedMilliseconds: Double;
  FormIdentity: string;
  InstanceName: string;
  Stopwatch: TStopwatch;
begin
  Result := 0;
  CheckMainThread;
  if AManagedObject = nil then
    Exit;
  if not FInitialized then
    if not Initialize then
      Exit;
  if not SupportsManagedObject(AManagedObject) then
    Exit;
  if not AForce and WasAppliedInCurrentGeneration(AManagedObject) then
    Exit;
  if FApplying then
    raise EDATLanguageManagerReentrancyError.Create(
      'ApplyToManagedObject cannot run during another application pass.');

  InstanceName := ManagedObjectInstanceName(AManagedObject);
  FormIdentity := ResolveFormIdentity(AManagedObject, InstanceName);
  if IsExcluded(AManagedObject, FormIdentity, InstanceName) then
    Exit;

  FApplying := True;
  Stopwatch := TStopwatch.StartNew;
  try
    try
      Result := ApplyLanguagePack(AManagedObject, ActivePack, FormIdentity);
      FAppliedGenerations.AddOrSetValue(AManagedObject, FGeneration);
      if AManagedObject is TComponent then
        TComponent(AManagedObject).FreeNotification(Self);
      Stopwatch.Stop;
      if FEnableDiagnostics then
        ElapsedMilliseconds := Stopwatch.Elapsed.TotalMilliseconds
      else
        ElapsedMilliseconds := 0;
      if Assigned(FOnManagedObjectTranslated) then
        FOnManagedObjectTranslated(Self, AManagedObject, FormIdentity,
          Result, ElapsedMilliseconds, FGeneration);
    except
      on E: Exception do
        if not HandleFailure('ApplyToManagedObject(' + FormIdentity + ')', E) then
          raise;
    end;
  finally
    FApplying := False;
  end;
end;

function TDATCustomLanguageManager.ReapplyToManagedObject(
  const AManagedObject: TObject): Integer;
begin
  Result := ApplyToManagedObjectInternal(AManagedObject, True);
end;

procedure TDATCustomLanguageManager.ApplyToOpenForms;
var
  ManagedObject: TObject;
  ManagedObjects: TList<TObject>;
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit;
  if FApplying then
    raise EDATLanguageManagerReentrancyError.Create(
      'ApplyToOpenForms cannot run during another application pass.');
  ManagedObjects := TList<TObject>.Create;
  try
    CollectOpenManagedObjects(ManagedObjects);
    for ManagedObject in ManagedObjects do
      ApplyToManagedObject(ManagedObject);
  finally
    ManagedObjects.Free;
  end;
end;

function TDATCustomLanguageManager.AvailableLanguages:
  TObjectList<TLanguagePackDescriptor>;
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit(TObjectList<TLanguagePackDescriptor>.Create(True));
  Result := FRuntime.AvailableLanguages;
end;

procedure TDATCustomLanguageManager.CheckConfigurationMutable;
begin
  if FInitialized or FInitializing then
    raise EDATLanguageManagerConfigurationError.Create(
      'Language manager configuration cannot change after initialization.');
end;

procedure TDATCustomLanguageManager.CheckMainThread;
begin
  if TThread.CurrentThread.ThreadID <> MainThreadID then
    raise EDATLanguageManagerMainThreadError.Create(
      'The language manager may only be used from the main UI thread.');
end;

procedure TDATCustomLanguageManager.CheckNotReentrant(
  const AOperation: string);
begin
  if FApplying or FSelectingLanguage or FInitializing then
    raise EDATLanguageManagerReentrancyError.CreateFmt(
      '%s cannot run during another language-manager operation.',
      [AOperation]);
end;

function TDATCustomLanguageManager.CurrentFormatSettings: TFormatSettings;
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit(TFormatSettings.Create);
  Result := FRuntime.FormatSettings;
end;

procedure TDATCustomLanguageManager.FormIdentityMappingsChanged(
  Sender: TObject);
begin
  RebuildFormIdentityMap;
end;

function TDATCustomLanguageManager.HandleFailure(const AContext: string;
  const AException: Exception): Boolean;
begin
  Result := FErrorBehavior = ebNotifyAndContinue;
  if Assigned(FOnTranslationError) then
    FOnTranslationError(Self, AContext, AException.Message, Result);
end;

function TDATCustomLanguageManager.Initialize: Boolean;
var
  LoadedLanguage: Boolean;
begin
  Result := False;
  CheckMainThread;
  if FInitialized then
    Exit(True);
  CheckNotReentrant('Initialize');
  if Trim(FApplicationId) = '' then
    raise EDATLanguageManagerConfigurationError.Create(
      'ApplicationId is required.');
  if Trim(FSourceLanguage) = '' then
    raise EDATLanguageManagerConfigurationError.Create(
      'SourceLanguage is required.');

  FInitializing := True;
  try
    try
      FRuntime := TTranslationRuntime.Create(FApplicationId,
        ResolveLanguagesDirectory, ResolvePreferencePath, FSourceLanguage);
      if FAutoLoadPreferred then
        LoadedLanguage := FRuntime.LoadPreferredLanguage
      else
        LoadedLanguage := FRuntime.LoadLanguage(FSourceLanguage);
      if not LoadedLanguage then
        LoadedLanguage := FRuntime.LoadLanguage(FSourceLanguage);
      if not LoadedLanguage then
        raise EDATLanguageManagerError.Create(
          'The initial language could not be loaded.');
      if FRuntime.ActivePack <> nil then
        FActiveLanguage := FRuntime.ActivePack.LanguageCode
      else
        FActiveLanguage := FSourceLanguage;
      AdvanceGeneration;
      FInitialized := True;
      Result := True;
    except
      on E: Exception do
      begin
        FreeAndNil(FRuntime);
        if not HandleFailure('Initialize', E) then
          raise;
      end;
    end;
  finally
    FInitializing := False;
  end;

  if not Result then
    Exit;
  if FAutoTranslateOwner and SupportsManagedObject(Owner) then
    ApplyToManagedObject(Owner);
  if FReapplyOpenForms then
    ApplyToOpenForms;
end;

procedure TDATCustomLanguageManager.InvalidateTranslations(
  const AApplyImmediately: Boolean);
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit;
  CheckNotReentrant('InvalidateTranslations');
  AdvanceGeneration;
  if AApplyImmediately then
    ApplyToOpenForms;
end;

function TDATCustomLanguageManager.IsExcluded(const AManagedObject: TObject;
  const AIdentity, AInstanceName: string): Boolean;
var
  Exclusion: string;
begin
  Result := False;
  for Exclusion in FExcludedForms do
    if SameText(Trim(Exclusion), AIdentity) or
      SameText(Trim(Exclusion), AInstanceName) or
      SameText(Trim(Exclusion), AManagedObject.ClassName) then
      Exit(True);
end;

procedure TDATCustomLanguageManager.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) and
    not (csLoading in ComponentState) then
    Initialize;
end;

procedure TDATCustomLanguageManager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FAppliedGenerations <> nil) then
    FAppliedGenerations.Remove(AComponent);
end;

procedure TDATCustomLanguageManager.NotifyMissingTranslation(
  const AFormIdentity, AKey, AFallbackText: string);
begin
  if Assigned(FOnMissingTranslation) then
    FOnMissingTranslation(Self, AFormIdentity, AKey, AFallbackText);
end;

procedure TDATCustomLanguageManager.RebuildFormIdentityMap;
var
  ClassName: string;
  ExistingRootName: string;
  MappingIndex: Integer;
  ResourceRootName: string;
begin
  FFormIdentities.Clear;
  for MappingIndex := 0 to FFormIdentityMappings.Count - 1 do
  begin
    if Trim(FFormIdentityMappings[MappingIndex]) = '' then
      Continue;
    ClassName := Trim(FFormIdentityMappings.Names[MappingIndex]);
    ResourceRootName := Trim(FFormIdentityMappings.ValueFromIndex[MappingIndex]);
    if (ClassName = '') or (ResourceRootName = '') then
      raise EDATFormIdentityError.CreateFmt(
        'Invalid form identity mapping: %s',
        [FFormIdentityMappings[MappingIndex]]);
    ClassName := LowerCase(ClassName);
    if FFormIdentities.TryGetValue(ClassName, ExistingRootName) and
      not SameText(ExistingRootName, ResourceRootName) then
      raise EDATFormIdentityError.CreateFmt(
        'Form class "%s" is mapped to more than one resource root.',
        [ClassName]);
    FFormIdentities.AddOrSetValue(ClassName, ResourceRootName);
  end;
end;

procedure TDATCustomLanguageManager.RegisterFormIdentity(const AClassName,
  AResourceRootName: string);
var
  NormalizedClassName: string;
  NormalizedRootName: string;
begin
  CheckConfigurationMutable;
  NormalizedClassName := Trim(AClassName);
  NormalizedRootName := Trim(AResourceRootName);
  if (NormalizedClassName = '') or (NormalizedRootName = '') then
    raise EDATFormIdentityError.Create(
      'Form class and resource-root names are required.');
  FFormIdentityMappings.Values[NormalizedClassName] := NormalizedRootName;
end;

procedure TDATCustomLanguageManager.RemoveManagedObject(
  const AManagedObject: TObject);
begin
  if (AManagedObject <> nil) and (FAppliedGenerations <> nil) then
    FAppliedGenerations.Remove(AManagedObject);
end;

function TDATCustomLanguageManager.ResolveFormIdentity(
  const AManagedObject: TObject; const AInstanceName: string): string;
begin
  if AManagedObject = nil then
    raise EDATFormIdentityError.Create(
      'A managed object is required to resolve form identity.');
  if not FFormIdentities.TryGetValue(
    LowerCase(AManagedObject.ClassName), Result) then
  begin
    Result := Trim(AInstanceName);
    if Result = '' then
      Result := AManagedObject.ClassName;
  end;
end;

function TDATCustomLanguageManager.ResolveLanguagesDirectory: string;
begin
  Result := Trim(FLanguagesFolder);
  if Result = '' then
    raise EDATLanguageManagerConfigurationError.Create(
      'LanguagesFolder is required.');
  if not TPath.IsPathRooted(Result) then
    Result := TPath.Combine(ExtractFilePath(ParamStr(0)), Result);
  Result := TPath.GetFullPath(Result);
end;

function TDATCustomLanguageManager.ResolvePreferencePath: string;
var
  BaseFolder: string;
begin
  if TPath.IsPathRooted(FPreferenceFileName) then
    Exit(TPath.GetFullPath(FPreferenceFileName));
  case FPreferenceLocation of
    plLocalAppData:
      begin
        BaseFolder := GetEnvironmentVariable('LOCALAPPDATA');
        if BaseFolder = '' then
          BaseFolder := ExtractFilePath(ParamStr(0));
        BaseFolder := TPath.Combine(BaseFolder, FApplicationId);
      end;
    plExecutableFolder:
      BaseFolder := ExtractFilePath(ParamStr(0));
    plCustomFolder:
      begin
        BaseFolder := Trim(FCustomPreferenceFolder);
        if BaseFolder = '' then
          raise EDATLanguageManagerConfigurationError.Create(
            'CustomPreferenceFolder is required for plCustomFolder.');
        if not TPath.IsPathRooted(BaseFolder) then
          BaseFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), BaseFolder);
      end;
  else
    raise EDATLanguageManagerConfigurationError.Create(
      'Unknown preference location.');
  end;
  Result := TPath.GetFullPath(TPath.Combine(BaseFolder,
    FPreferenceFileName));
end;

function TDATCustomLanguageManager.SelectLanguage(
  const ALanguageCode: string): Boolean;
var
  Allow: Boolean;
  CandidateLanguage: string;
  LoadedLanguage: Boolean;
  OldLanguage: string;
begin
  Result := False;
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit;
  CheckNotReentrant('SelectLanguage');
  CandidateLanguage := Trim(ALanguageCode);
  if CandidateLanguage = '' then
    raise EDATLanguageManagerError.Create('A language code is required.');
  if SameText(CandidateLanguage, FActiveLanguage) then
    Exit(True);

  Allow := True;
  OldLanguage := FActiveLanguage;
  if Assigned(FOnLanguageChanging) then
    FOnLanguageChanging(Self, OldLanguage, CandidateLanguage, Allow);
  if not Allow then
    Exit(False);

  FSelectingLanguage := True;
  try
    try
      LoadedLanguage := FRuntime.LoadLanguage(CandidateLanguage);
      if not LoadedLanguage then
      begin
        case FMissingPackBehavior of
          mpUseSourceLanguage:
            begin
              CandidateLanguage := FSourceLanguage;
              LoadedLanguage := FRuntime.LoadLanguage(CandidateLanguage);
            end;
          mpKeepCurrentLanguage:
            Exit(False);
          mpRaiseError:
            raise EDATLanguageManagerError.CreateFmt(
              'Language pack "%s" was not found.', [CandidateLanguage]);
        end;
      end;
      if not LoadedLanguage then
        raise EDATLanguageManagerError.CreateFmt(
          'Language "%s" could not be loaded.', [CandidateLanguage]);
      if FRuntime.ActivePack <> nil then
        FActiveLanguage := FRuntime.ActivePack.LanguageCode
      else
        FActiveLanguage := CandidateLanguage;
      AdvanceGeneration;
      if FReapplyOpenForms then
        ApplyToOpenForms;
      if Assigned(FOnLanguageChanged) then
        FOnLanguageChanged(Self, OldLanguage, FActiveLanguage, FGeneration);
      Result := True;
    except
      on E: Exception do
        if not HandleFailure('SelectLanguage(' + CandidateLanguage + ')', E) then
          raise;
    end;
  finally
    FSelectingLanguage := False;
  end;
end;

procedure TDATCustomLanguageManager.SetApplicationId(const Value: string);
begin
  CheckConfigurationMutable;
  FApplicationId := Trim(Value);
end;

procedure TDATCustomLanguageManager.SetCustomPreferenceFolder(
  const Value: string);
begin
  CheckConfigurationMutable;
  FCustomPreferenceFolder := Trim(Value);
end;

procedure TDATCustomLanguageManager.SetExcludedForms(const Value: TStrings);
begin
  FExcludedForms.Assign(Value);
end;

function TDATCustomLanguageManager.GetExcludedForms: TStrings;
begin
  Result := FExcludedForms;
end;

function TDATCustomLanguageManager.GetFormIdentityMappings: TStrings;
begin
  Result := FFormIdentityMappings;
end;

procedure TDATCustomLanguageManager.SetFormIdentityMappings(
  const Value: TStrings);
begin
  CheckConfigurationMutable;
  FFormIdentityMappings.Assign(Value);
end;

procedure TDATCustomLanguageManager.SetLanguagesFolder(const Value: string);
begin
  CheckConfigurationMutable;
  FLanguagesFolder := Trim(Value);
end;

procedure TDATCustomLanguageManager.SetPreferenceFileName(
  const Value: string);
begin
  CheckConfigurationMutable;
  FPreferenceFileName := Trim(Value);
end;

procedure TDATCustomLanguageManager.SetPreferenceLocation(
  const Value: TDATPreferenceLocation);
begin
  CheckConfigurationMutable;
  FPreferenceLocation := Value;
end;

procedure TDATCustomLanguageManager.SetSourceLanguage(const Value: string);
begin
  CheckConfigurationMutable;
  FSourceLanguage := Trim(Value);
end;

function TDATCustomLanguageManager.TrackedObjectCount: Integer;
begin
  Result := FAppliedGenerations.Count;
end;

function TDATCustomLanguageManager.Translate(const AKey,
  AFallbackText: string): string;
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit(AFallbackText);
  Result := FRuntime.Translate(AKey, AFallbackText);
end;

function TDATCustomLanguageManager.FormatTemplate(const AKey,
  AFallbackText: string; const AArgs: array of const): string;
begin
  CheckMainThread;
  if not FInitialized then
    if not Initialize then
      Exit(Format(AFallbackText, AArgs));
  Result := FRuntime.FormatTemplate(AKey, AFallbackText, AArgs);
end;

function TDATCustomLanguageManager.WasAppliedInCurrentGeneration(
  const AManagedObject: TObject): Boolean;
var
  AppliedGeneration: Cardinal;
begin
  Result := (AManagedObject <> nil) and
    FAppliedGenerations.TryGetValue(AManagedObject, AppliedGeneration) and
    (AppliedGeneration = FGeneration);
end;

end.
