program LanguageManagerCoreTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.SysUtils,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas';

type
  TMockManagedForm = class(TComponent)
  private
    FDisplayText: string;
    FApplyCount: Integer;
    FRaiseOnApply: Boolean;
    FTriggerReentrancy: Boolean;
  public
    property DisplayText: string read FDisplayText write FDisplayText;
    property ApplyCount: Integer read FApplyCount write FApplyCount;
    property RaiseOnApply: Boolean read FRaiseOnApply write FRaiseOnApply;
    property TriggerReentrancy: Boolean read FTriggerReentrancy
      write FTriggerReentrancy;
  end;

  TExcludedMockManagedForm = class(TMockManagedForm);

  TMockLanguageManager = class(TDATCustomLanguageManager)
  private
    FOpenObjects: TList<TObject>;
    FNestedApplicationBlocked: Boolean;
  protected
    function SupportsManagedObject(
      const AManagedObject: TObject): Boolean; override;
    function ManagedObjectInstanceName(
      const AManagedObject: TObject): string; override;
    function ApplyLanguagePack(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreLanguageLayout(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    function RestoreSourceLanguage(const AManagedObject: TObject;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; override;
    procedure CollectOpenManagedObjects(
      const AObjects: TList<TObject>); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddOpenObject(const AObject: TObject);
    procedure RemoveOpenObject(const AObject: TObject);
    property NestedApplicationBlocked: Boolean
      read FNestedApplicationBlocked;
  end;

  TCoreTestObserver = class
  private
    FCancelNextLanguageChange: Boolean;
    FErrorCount: Integer;
    FLanguageChangedCount: Integer;
    FTranslatedCount: Integer;
    FLastIdentity: string;
  public
    procedure LanguageChanging(Sender: TObject; const AOldLanguage,
      ANewLanguage: string; var AAllow: Boolean);
    procedure LanguageChanged(Sender: TObject; const AOldLanguage,
      ANewLanguage: string; const AGeneration: Cardinal);
    procedure ManagedObjectTranslated(Sender: TObject;
      const AManagedObject: TObject; const AFormIdentity: string;
      const AAppliedPropertyCount: Integer;
      const AElapsedMilliseconds: Double; const AGeneration: Cardinal);
    procedure TranslationError(Sender: TObject; const AContext,
      AMessage: string; var AHandled: Boolean);
    property CancelNextLanguageChange: Boolean
      read FCancelNextLanguageChange write FCancelNextLanguageChange;
    property ErrorCount: Integer read FErrorCount;
    property LanguageChangedCount: Integer read FLanguageChangedCount;
    property TranslatedCount: Integer read FTranslatedCount;
    property LastIdentity: string read FLastIdentity;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure WritePack(const AFileName, ALanguageCode, ANativeName,
  AShortDateFormat, AText: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":1,"applicationId":"CoreTestApp",' +
    '"applicationVersion":"1.0","framework":"Neutral",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"core-test",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"' + AShortDateFormat + '",' +
    '"longDateFormat":"","shortTimeFormat":"HH:mm",' +
    '"longTimeFormat":"HH:mm:ss","decimalSeparator":",",' +
    '"thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmMock.Text":"' + AText + '",' +
    '"Messages.Dynamic":"Dynamic ' + ALanguageCode + '"}}';
  TFile.WriteAllText(AFileName, JsonText, TEncoding.UTF8);
end;

constructor TMockLanguageManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOpenObjects := TList<TObject>.Create;
end;

destructor TMockLanguageManager.Destroy;
begin
  FOpenObjects.Free;
  inherited Destroy;
end;

procedure TMockLanguageManager.AddOpenObject(const AObject: TObject);
begin
  if FOpenObjects.IndexOf(AObject) < 0 then
    FOpenObjects.Add(AObject);
end;

function TMockLanguageManager.ApplyLanguagePack(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
var
  ManagedForm: TMockManagedForm;
begin
  ManagedForm := TMockManagedForm(AManagedObject);
  if ManagedForm.RaiseOnApply then
    raise Exception.Create('Deliberate adapter failure.');
  if ManagedForm.TriggerReentrancy then
  begin
    ManagedForm.TriggerReentrancy := False;
    try
      ApplyToManagedObject(ManagedForm);
    except
      on EDATLanguageManagerReentrancyError do
        FNestedApplicationBlocked := True;
    end;
  end;
  if APack = nil then
    Exit(0);
  ManagedForm.DisplayText := APack.GetText(
    AFormIdentity + '.Text', ManagedForm.DisplayText);
  ManagedForm.ApplyCount := ManagedForm.ApplyCount + 1;
  Result := 1;
end;

function TMockLanguageManager.RestoreLanguageLayout(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := 0;
end;

function TMockLanguageManager.RestoreSourceLanguage(
  const AManagedObject: TObject; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
begin
  Result := 0;
end;

procedure TMockLanguageManager.CollectOpenManagedObjects(
  const AObjects: TList<TObject>);
var
  ManagedObject: TObject;
begin
  for ManagedObject in FOpenObjects do
    AObjects.Add(ManagedObject);
end;

function TMockLanguageManager.ManagedObjectInstanceName(
  const AManagedObject: TObject): string;
begin
  Result := TComponent(AManagedObject).Name;
end;

procedure TMockLanguageManager.RemoveOpenObject(const AObject: TObject);
begin
  RemoveManagedObject(AObject);
  FOpenObjects.Remove(AObject);
end;

function TMockLanguageManager.SupportsManagedObject(
  const AManagedObject: TObject): Boolean;
begin
  Result := AManagedObject is TMockManagedForm;
end;

procedure TCoreTestObserver.LanguageChanging(Sender: TObject;
  const AOldLanguage, ANewLanguage: string; var AAllow: Boolean);
begin
  if FCancelNextLanguageChange then
  begin
    FCancelNextLanguageChange := False;
    AAllow := False;
  end;
end;

procedure TCoreTestObserver.LanguageChanged(Sender: TObject;
  const AOldLanguage, ANewLanguage: string; const AGeneration: Cardinal);
begin
  Inc(FLanguageChangedCount);
end;

procedure TCoreTestObserver.ManagedObjectTranslated(Sender: TObject;
  const AManagedObject: TObject; const AFormIdentity: string;
  const AAppliedPropertyCount: Integer; const AElapsedMilliseconds: Double;
  const AGeneration: Cardinal);
begin
  Inc(FTranslatedCount);
  FLastIdentity := AFormIdentity;
end;

procedure TCoreTestObserver.TranslationError(Sender: TObject;
  const AContext, AMessage: string; var AHandled: Boolean);
begin
  Inc(FErrorCount);
  AHandled := True;
end;

procedure RunCoreTests;
var
  Available: TObjectList<TLanguagePackDescriptor>;
  ConfigurationBlocked: Boolean;
  ErrorForm: TMockManagedForm;
  ExcludedForm: TExcludedMockManagedForm;
  FirstForm: TMockManagedForm;
  InitialApplyCount: Integer;
  LanguagesDirectory: string;
  Manager: TMockLanguageManager;
  MissingGeneration: Cardinal;
  Observer: TCoreTestObserver;
  PreferenceDirectory: string;
  SecondForm: TMockManagedForm;
  SecondManager: TMockLanguageManager;
  TempRoot: string;
  ThirdForm: TMockManagedForm;
  ThreadGuardPassed: Boolean;
  Worker: TThread;
begin
  TempRoot := TPath.Combine(TPath.GetTempPath,
    'DAT-Core-' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  LanguagesDirectory := TPath.Combine(TempRoot, 'Languages');
  PreferenceDirectory := TPath.Combine(TempRoot, 'Preferences');
  TDirectory.CreateDirectory(LanguagesDirectory);
  WritePack(TPath.Combine(LanguagesDirectory, 'en-US.json'),
    'en-US', 'English', 'M/d/yyyy', 'English catalog text');
  WritePack(TPath.Combine(LanguagesDirectory, 'de-DE.json'),
    'de-DE', 'Deutsch', 'dd.MM.yyyy', 'Deutscher Katalogtext');

  Observer := TCoreTestObserver.Create;
  Manager := TMockLanguageManager.Create(nil);
  FirstForm := TMockManagedForm.Create(nil);
  SecondForm := TMockManagedForm.Create(nil);
  ThirdForm := nil;
  ExcludedForm := nil;
  ErrorForm := nil;
  try
    FirstForm.Name := 'frmMock';
    SecondForm.Name := 'frmMock_1';
    FirstForm.DisplayText := 'first source';
    SecondForm.DisplayText := 'second source';
    Manager.ApplicationId := 'CoreTestApp';
    Manager.LanguagesFolder := LanguagesDirectory;
    Manager.SourceLanguage := 'en-US';
    Manager.PreferenceLocation := plCustomFolder;
    Manager.CustomPreferenceFolder := PreferenceDirectory;
    Manager.PreferenceFileName := 'language.ini';
    Manager.AutoLoadPreferred := False;
    Manager.AutoTranslateOwner := False;
    Manager.ReapplyOpenForms := False;
    Manager.EnableDiagnostics := True;
    Manager.RegisterFormIdentity('TMockManagedForm', 'frmMock');
    Manager.RegisterFormIdentity('TExcludedMockManagedForm', 'frmExcluded');
    Manager.OnLanguageChanging := Observer.LanguageChanging;
    Manager.OnLanguageChanged := Observer.LanguageChanged;
    Manager.OnFormTranslated := Observer.ManagedObjectTranslated;
    Manager.OnTranslationError := Observer.TranslationError;
    Manager.AddOpenObject(FirstForm);
    Manager.AddOpenObject(SecondForm);

    Require(Manager.Initialize, 'Core manager did not initialize.');
    Require(Manager.Generation = 1,
      'Initial generation was not one.');
    Require(SameText(Manager.ActiveLanguage, 'en-US'),
      'Initial source language was not active.');
    Manager.ApplyToOpenForms;
    Require(FirstForm.DisplayText = 'English catalog text',
      'First form did not receive source-pack text: ' +
      FirstForm.DisplayText);
    Require(SecondForm.DisplayText = 'English catalog text',
      'Stable class identity did not translate the suffixed second instance.');
    Require(Manager.ResolveFormIdentity(SecondForm, SecondForm.Name) =
      'frmMock', 'Stable form identity resolved incorrectly.');
    Require(Observer.LastIdentity = 'frmMock',
      'Translated event did not report stable identity.');
    Require(Manager.TrackedObjectCount = 2,
      'Initial form-generation tracking count is wrong.');

    InitialApplyCount := FirstForm.ApplyCount;
    Require(Manager.ApplyToManagedObject(FirstForm) = 0,
      'Current-generation form was applied twice.');
    Require(FirstForm.ApplyCount = InitialApplyCount,
      'Idempotence did not preserve the apply count.');

    Manager.ReapplyOpenForms := True;
    Require(Manager.SelectLanguage('de-DE'),
      'German language selection failed.');
    Require(Manager.Generation = 2,
      'Language selection did not advance generation.');
    Require((FirstForm.DisplayText = 'Deutscher Katalogtext') and
      (SecondForm.DisplayText = 'Deutscher Katalogtext'),
      'Open forms did not reapply the selected language.');
    Require(Manager.Translate('Messages.Dynamic', 'fallback') =
      'Dynamic de-DE', 'Dynamic translation lookup failed.');
    { The pack asked for dd.MM.yyyy and does not get it.

      A language is what someone reads; a date format is what their
      country writes. Someone in Chicago reading an application in German
      still wants the dates their calendar and their bank statement use,
      and Windows already knows which those are. This asserts the machine
      wins, which is the opposite of what it asserted before. }
    Require(Manager.CurrentFormatSettings.ShortDateFormat =
      TFormatSettings.Create.ShortDateFormat,
      'Dates should follow the machine''s regional settings, not the pack.');
    Require(Manager.CurrentFormatSettings.ShortDateFormat <> 'dd.MM.yyyy',
      'The pack overrode the date format, which it must not do.');
    { Numbers still travel with the pack - they describe the content
      rather than the reader. }
    Require(Manager.CurrentFormatSettings.DecimalSeparator = ',',
      'Number formats should still follow the active pack.');

    InitialApplyCount := FirstForm.ApplyCount;
    MissingGeneration := Manager.Generation;
    Require(Manager.SelectLanguage('de-DE'),
      'Selecting the active language should succeed.');
    Require((Manager.Generation = MissingGeneration) and
      (FirstForm.ApplyCount = InitialApplyCount),
      'Selecting the active language performed unnecessary work.');

    ThirdForm := TMockManagedForm.Create(nil);
    ThirdForm.Name := 'frmMock_2';
    ThirdForm.DisplayText := 'third source';
    Manager.AddOpenObject(ThirdForm);
    Require(Manager.ApplyToManagedObject(ThirdForm) = 1,
      'New form was not applied in the active generation.');
    Require(ThirdForm.DisplayText = 'Deutscher Katalogtext',
      'New form did not use stable identity.');

    ExcludedForm := TExcludedMockManagedForm.Create(nil);
    ExcludedForm.Name := 'frmExcluded_1';
    ExcludedForm.DisplayText := 'excluded source';
    Manager.ExcludedForms.Add('frmExcluded');
    Manager.AddOpenObject(ExcludedForm);
    Manager.InvalidateTranslations(False);
    Manager.ApplyToOpenForms;
    Require(ExcludedForm.DisplayText = 'excluded source',
      'Excluded form was translated.');
    Require(not Manager.WasAppliedInCurrentGeneration(ExcludedForm),
      'Excluded form was incorrectly marked applied.');

    FirstForm.TriggerReentrancy := True;
    Manager.InvalidateTranslations(False);
    Manager.ApplyToManagedObject(FirstForm);
    Require(Manager.NestedApplicationBlocked,
      'Nested application was not blocked by the reentrancy guard.');

    ErrorForm := TMockManagedForm.Create(nil);
    ErrorForm.Name := 'frmMock_3';
    ErrorForm.RaiseOnApply := True;
    Manager.AddOpenObject(ErrorForm);
    Manager.InvalidateTranslations(False);
    Manager.ApplyToOpenForms;
    Require(Observer.ErrorCount > 0,
      'Translation failure did not reach the error event.');
    Require(not Manager.WasAppliedInCurrentGeneration(ErrorForm),
      'Failed form was incorrectly marked applied.');

    ThreadGuardPassed := False;
    Worker := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          Manager.ApplyToManagedObject(FirstForm);
        except
          on EDATLanguageManagerMainThreadError do
            ThreadGuardPassed := True;
        end;
      end);
    Worker.FreeOnTerminate := False;
    try
      Worker.Start;
      Worker.WaitFor;
    finally
      Worker.Free;
    end;
    Require(ThreadGuardPassed,
      'Off-main-thread manager access was not rejected.');

    Observer.CancelNextLanguageChange := True;
    MissingGeneration := Manager.Generation;
    Require(not Manager.SelectLanguage('en-US'),
      'Cancelled language selection unexpectedly succeeded.');
    Require(Manager.Generation = MissingGeneration,
      'Cancelled language selection changed generation.');

    Manager.MissingPackBehavior := mpKeepCurrentLanguage;
    MissingGeneration := Manager.Generation;
    Require(not Manager.SelectLanguage('zz-ZZ'),
      'Missing pack should have kept the active language.');
    Require((Manager.Generation = MissingGeneration) and
      SameText(Manager.ActiveLanguage, 'de-DE'),
      'Keep-current missing-pack policy changed state.');

    Manager.MissingPackBehavior := mpUseSourceLanguage;
    Require(Manager.SelectLanguage('zz-ZZ'),
      'Missing pack did not fall back to source language.');
    Require(SameText(Manager.ActiveLanguage, 'en-US'),
      'Source-language fallback was not activated.');

    Available := Manager.AvailableLanguages;
    try
      Require(Available.Count = 2,
        'Available-language discovery returned the wrong count.');
    finally
      Available.Free;
    end;

    ConfigurationBlocked := False;
    try
      Manager.ApplicationId := 'ChangedAfterInitialization';
    except
      on EDATLanguageManagerConfigurationError do
        ConfigurationBlocked := True;
    end;
    Require(ConfigurationBlocked,
      'Configuration changed after initialization.');

    Manager.RemoveOpenObject(ErrorForm);
    ErrorForm.Free;
    ErrorForm := nil;
    Manager.RemoveOpenObject(ExcludedForm);
    ExcludedForm.Free;
    ExcludedForm := nil;
    Manager.RemoveOpenObject(ThirdForm);
    ThirdForm.Free;
    ThirdForm := nil;
    Require(Manager.TrackedObjectCount = 2,
      'Destroyed forms remained in generation tracking.');
    Manager.RemoveOpenObject(SecondForm);
    SecondForm.Free;
    SecondForm := nil;
    Require(Manager.TrackedObjectCount = 1,
      'FreeNotification did not remove the second form.');
    Manager.RemoveOpenObject(FirstForm);
    FirstForm.Free;
    FirstForm := nil;
    Require(Manager.TrackedObjectCount = 0,
      'FreeNotification did not clear form tracking.');

    SecondManager := TMockLanguageManager.Create(nil);
    try
      SecondManager.ApplicationId := 'CoreTestApp';
      SecondManager.LanguagesFolder := LanguagesDirectory;
      SecondManager.SourceLanguage := 'en-US';
      SecondManager.PreferenceLocation := plCustomFolder;
      SecondManager.CustomPreferenceFolder := PreferenceDirectory;
      SecondManager.PreferenceFileName := 'language.ini';
      SecondManager.AutoTranslateOwner := False;
      SecondManager.ReapplyOpenForms := False;
      Require(SecondManager.Initialize,
        'Second manager did not initialize from saved preference.');
      Require(SameText(SecondManager.ActiveLanguage, 'en-US'),
        'Saved source-language preference was not loaded.');
    finally
      SecondManager.Free;
    end;

    Require(Observer.LanguageChangedCount >= 2,
      'Language-changed events were not raised.');
    Require(Observer.TranslatedCount > 0,
      'Form-translated events were not raised.');
  finally
    ErrorForm.Free;
    ExcludedForm.Free;
    ThirdForm.Free;
    SecondForm.Free;
    FirstForm.Free;
    Manager.Free;
    Observer.Free;
    if TDirectory.Exists(TempRoot) then
      TDirectory.Delete(TempRoot, True);
  end;
end;

begin
  try
    RunCoreTests;
    Writeln('LANGUAGE_MANAGER_CORE_TESTS=PASS');
    Writeln('FRAMEWORK_UNITS_LINKED=NONE');
    Writeln('STABLE_FORM_IDENTITY=PASS');
    Writeln('GENERATION_TRACKING=PASS');
    Writeln('MAIN_THREAD_GUARD=PASS');
    Writeln('REENTRANCY_GUARD=PASS');
    Writeln('DETERMINISTIC_REMOVAL=PASS');
  except
    on E: Exception do
    begin
      Writeln('LANGUAGE_MANAGER_CORE_TESTS=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
