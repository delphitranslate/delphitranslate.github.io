unit DAT.Studio.SetupWizard;

interface

uses
  System.Classes,
  System.Generics.Collections,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Edit,
  FMX.Forms,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Memo,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Types,
  DAT.Core.Types,
  DAT.Provider.Types,
  DAT.Scan.Types;

type
  TfrmSetupWizard = class(TForm)
    RootLayout: TLayout;
    HeaderBackground: TRectangle;
    HeaderAccent: TRectangle;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    BodyLayout: TLayout;
    RailBackground: TRectangle;
    lblRailTitle: TLabel;
    railStep1: TLabel;
    railStep2: TLabel;
    railStep3: TLabel;
    railStep4: TLabel;
    railStep5: TLabel;
    railStep6: TLabel;
    railStep7: TLabel;
    railStep8: TLabel;
    ContentCard: TRectangle;
    WizardTabs: TTabControl;
    tabWelcome: TTabItem;
    tabProject: TTabItem;
    tabDeployment: TTabItem;
    tabLanguages: TTabItem;
    tabProvider: TTabItem;
    tabScan: TTabItem;
    tabReview: TTabItem;
    tabFinish: TTabItem;
    lblDeploymentTitle: TLabel;
    lblDeploymentText: TLabel;
    lstDeploymentDestinations: TListBox;
    btnAddDeploymentDestination: TButton;
    btnRemoveDeploymentDestination: TButton;
    lblDeploymentSummary: TLabel;
    chkReplaceDeployedExecutable: TCheckBox;
    lblWelcomeTitle: TLabel;
    lblWelcomeText: TLabel;
    WelcomeNotice: TRectangle;
    lblWelcomeNotice: TLabel;
    lblProjectTitle: TLabel;
    lblProjectText: TLabel;
    edtProjectFile: TEdit;
    btnBrowseProject: TButton;
    lblProjectSummary: TLabel;
    lblApplicationId: TLabel;
    edtApplicationId: TEdit;
    btnCopyApplicationId: TButton;
    dlgOpenProject: TOpenDialog;
    lblLanguagesTitle: TLabel;
    lblLanguagesText: TLabel;
    lblSourceLanguage: TLabel;
    cboSourceLanguage: TComboBox;
    lblTargetLanguage: TLabel;
    cboTargetLanguage: TComboBox;
    lblNativeName: TLabel;
    edtNativeName: TEdit;
    lblLanguageSummary: TLabel;
    lblProviderTitle: TLabel;
    lblProviderText: TLabel;
    lblProvider: TLabel;
    cboProvider: TComboBox;
    lblDeepLPlan: TLabel;
    cboDeepLPlan: TComboBox;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    chkRememberKey: TCheckBox;
    btnSaveKey: TButton;
    btnTestConnection: TButton;
    lblProviderStatus: TLabel;
    lblScanTitle: TLabel;
    lblScanText: TLabel;
    btnRunScan: TButton;
    lblScanSummary: TLabel;
    memScanResults: TMemo;
    lblReviewTitle: TLabel;
    lblReviewText: TLabel;
    memReview: TMemo;
    chkCreateBackup: TCheckBox;
    chkTargetProjectClosed: TCheckBox;
    chkAuthorizeFinal: TCheckBox;
    lblFinalWarning: TLabel;
    lblFinishTitle: TLabel;
    lblFinishText: TLabel;
    memProgress: TMemo;
    btnDeployApplicationFolder: TButton;
    lblWorkflowMode: TLabel;
    cboWorkflowMode: TComboBox;
    lblWorkflowSummary: TLabel;
    lblLocalizationReviewInfo: TLabel;
    BuildChoiceCard: TRectangle;
    lblBuildChoiceTitle: TLabel;
    lblBuildChoiceText: TLabel;
    chkBuildNow: TCheckBox;
    cboBuildPlatform: TComboBox;
    cboBuildConfiguration: TComboBox;
    btnBuildNow: TButton;
    lblBuildStatus: TLabel;
    FooterLine: TRectangle;
    btnBack: TButton;
    btnNext: TButton;
    btnCancel: TButton;
    btnFinish: TButton;
    lblFooterStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnFinishClick(Sender: TObject);
    procedure btnBrowseProjectClick(Sender: TObject);
    procedure btnCopyApplicationIdClick(Sender: TObject);
    procedure cboTargetLanguageChange(Sender: TObject);
    procedure cboProviderChange(Sender: TObject);
    procedure btnSaveKeyClick(Sender: TObject);
    procedure btnTestConnectionClick(Sender: TObject);
    procedure btnRunScanClick(Sender: TObject);
    procedure chkAuthorizeFinalChange(Sender: TObject);
    procedure railStepClick(Sender: TObject);
    procedure btnDeployApplicationFolderClick(Sender: TObject);
    procedure btnAddDeploymentDestinationClick(Sender: TObject);
    procedure btnRemoveDeploymentDestinationClick(Sender: TObject);
    procedure lstDeploymentDestinationsChange(Sender: TObject);
    procedure cboWorkflowModeChange(Sender: TObject);
    procedure btnLocalizationReviewClick(Sender: TObject);
    procedure btnBuildNowClick(Sender: TObject);
    procedure chkBuildNowChange(Sender: TObject);
    procedure BuildSelectionChange(Sender: TObject);
  private
    FCurrentStep: Integer;
    FHighestStep: Integer;
    FFinalProcessing: Boolean;
    FFinalCancelRequested: Integer;
    FCloseAfterFinalProcessing: Boolean;
    FCompleted: Boolean;
    FBuildCompleted: Boolean;
    FBuildInProgress: Boolean;
    FCloseAfterBuild: Boolean;
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    FCatalog: TTranslationCatalog;
    FDeploymentCommands: TStringList;
    FCatalogFileName: string;
    FKitDirectory: string;
    FBackupFileName: string;
    FProjectConfigurationBackupDirectory: string;
    FSessionApiKey: string;
    FLastScanCompletedAt: TDateTime;
    FReviewOutputDirectory: string;
    FScanInProgress: Boolean;
    FScanCancelRequested: Integer;
    FCloseAfterScan: Boolean;
    FProviderTestInProgress: Boolean;
    FProviderTestCancelRequested: Integer;
    FCloseAfterProviderTest: Boolean;
    procedure UpdateBuildChoice;
    procedure SetStep(const AStep: Integer);
    procedure UpdateNavigation;
    procedure UpdateRail;
    function ValidateCurrentStep: Boolean;
    function SelectedLanguageCode(ACombo: TComboBox): string;
    function SelectedProvider: TTranslationProvider;
    function EffectiveApiKey: string;
    procedure LoadExistingCatalog;
    procedure ApplyLocaleDefaults;
    procedure BuildReview;
    procedure ExecuteFinalProcessing;
    procedure ContinueFinalProcessingAfterBackup;
    procedure ContinueFinalProcessing(
      const AEntryIndexes: TArray<Integer>;
      const ATranslatedTexts: TArray<string>;
      const AProvider: TTranslationProvider;
      const AProjectGlossaryFileName: string);
    procedure ContinueFinalProcessingAfterDeployment(
      const ADeployedCount, AConfiguredDestinationCount: Integer;
      const ARuntimePackFileName: string);
    procedure StopFinalProcessing(const AMessage: string);
    procedure AddProgress(const AText: string);
    function FindStudioRoot: string;
    procedure BuildDeploymentCommands;
    procedure RebuildAllTargetConfigurations;
    function ExistingBuildOutputDirectories: TArray<string>;
    function DeployLanguagePacksToExistingOutputs: Integer;
    function DeployLanguagePacksDirect(const AApplicationDirectory: string): Boolean;
    function RunDeploymentScript(const AApplicationDirectory: string;
      const ASkipConfiguredDestinations: Boolean = True): Boolean;
    function ExistingCatalogFileName: string;
    function EffectiveWorkflowName: string;
    procedure UpdateWorkflowSummary;
    function StagedGlossaryFileName: string;
    procedure GenerateLocalizationReviewArtifacts;
    procedure LoadDeploymentDestinations;
    procedure SaveDeploymentDestinations;
    procedure UpdateDeploymentSummary;
  public
  end;

implementation

uses
  DAT.Core.BuildInfo,
  System.IOUtils,
  System.JSON,
  System.Math,
  System.RegularExpressions,
  System.Rtti,
  System.StrUtils,
  System.SyncObjs,
  System.SysUtils,
  System.UITypes,
  System.Zip,
  Winapi.ShellAPI,
  Winapi.Windows,
  FMX.DialogService.Sync,
  FMX.Platform,
  DAT.Core.AtomicFile,
  DAT.Core.CatalogJson,
  DAT.Core.LocaleFacts,
  DAT.Core.Glossary,
  DAT.Core.Hyphenation,
  DAT.Scan.DomainProfile,
  DAT.Core.SharedDictionary,
  DAT.Core.TranslationMemory,
  DAT.Core.ProjectDetection,
  DAT.Core.RuntimePack,
  DAT.Core.Terminology,
  DAT.Core.TranslationWorkspace,
  DAT.Review.Localization,
  DAT.Integration.ComponentPackage,
  DAT.Provider.Client,
  DAT.Provider.CredentialStore,
  DAT.Provider.Settings,
  DAT.Runtime.LanguagePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Studio.LocalizationReview,
  DAT.Validation.Catalog,
  DAT.Integration.BuildDeploy;

{$R *.fmx}

const
  StepCount = 8;
  DeploymentProcessTimeout = 120000;
  ProcessTerminationWait = 5000;

function WindowsPowerShellFileName: string;
var
  SystemRoot: string;
  WindowsDirectoryBuffer: array[0..MAX_PATH] of Char;
  WindowsDirectoryLength: UINT;
begin
  SystemRoot := Trim(GetEnvironmentVariable('SystemRoot'));
  if SystemRoot = '' then
  begin
    WindowsDirectoryLength := GetWindowsDirectory(WindowsDirectoryBuffer,
      Length(WindowsDirectoryBuffer));
    if (WindowsDirectoryLength > 0) and
      (WindowsDirectoryLength < UINT(Length(WindowsDirectoryBuffer))) then
      SetString(SystemRoot, WindowsDirectoryBuffer, WindowsDirectoryLength);
  end;
  if SystemRoot <> '' then
    Result := TPath.Combine(SystemRoot,
      TPath.Combine('System32',
        TPath.Combine('WindowsPowerShell',
          TPath.Combine('v1.0', 'powershell.exe'))))
  else
    Result := 'powershell.exe';
  if TPath.IsPathRooted(Result) and not TFile.Exists(Result) then
    Result := 'powershell.exe';
end;

procedure TfrmSetupWizard.FormCreate(Sender: TObject);
var
  ProviderSettings: TProviderSettings;
begin
  Caption := 'Translation Setup Wizard - ' + StudioBuildDescription;
  lblSubtitle.Text := 'A safe, step-by-step path from Delphi project to offline language pack - ' +
    StudioBuildDescription;
  FCurrentStep := 1;
  FHighestStep := 1;
  FDeploymentCommands := TStringList.Create;
  cboSourceLanguage.ItemIndex := 0;
  cboTargetLanguage.ItemIndex := -1;
  cboWorkflowMode.ItemIndex := 0;
  ProviderSettings := TProviderSettings.Load;
  try
    cboProvider.ItemIndex := Ord(ProviderSettings.Provider);
    cboDeepLPlan.ItemIndex := Ord(ProviderSettings.DeepLPlan);
    chkRememberKey.IsChecked := ProviderSettings.RememberCredential;
  finally
    ProviderSettings.Free;
  end;
  cboProviderChange(nil);
  chkCreateBackup.IsChecked := True;
  chkCreateBackup.Enabled := False;
  chkTargetProjectClosed.IsChecked := False;
  edtApiKey.Password := True;
  chkBuildNow.IsChecked := False;
  FBuildCompleted := False;
  FBuildInProgress := False;
  chkReplaceDeployedExecutable.IsChecked := False;
  { The lists offer one platform and one configuration, because one executable
    is what a destination folder holds. Win32 and Release are the defaults: the
    build a user of the application would be given, on the architecture whose
    supporting libraries sit beside it in most deployments. }
  cboBuildPlatform.ItemIndex := 0;
  cboBuildConfiguration.ItemIndex := 0;
  UpdateBuildChoice;
  UpdateDeploymentSummary;
  SetStep(1);
end;

procedure TfrmSetupWizard.UpdateBuildChoice;
begin
  BuildChoiceCard.Visible := FCompleted;
  btnBuildNow.Enabled := chkBuildNow.IsChecked and
    (FProjectProfile.ProjectFileName <> '') and FCompleted and
    not FBuildInProgress;
  cboBuildPlatform.Enabled := chkBuildNow.IsChecked and FCompleted and
    not FBuildInProgress;
  cboBuildConfiguration.Enabled := chkBuildNow.IsChecked and FCompleted and
    not FBuildInProgress;
end;

procedure TfrmSetupWizard.chkBuildNowChange(Sender: TObject);
begin
  if chkBuildNow.IsChecked then
    FBuildCompleted := False;
  UpdateBuildChoice;
  UpdateNavigation;
end;

procedure TfrmSetupWizard.BuildSelectionChange(Sender: TObject);
begin
  if chkBuildNow.IsChecked then
  begin
    FBuildCompleted := False;
    lblBuildStatus.Text :=
      'Build selection changed. Click Build and Deploy Selected Targets before Finish.';
  end;
  UpdateBuildChoice;
  UpdateNavigation;
end;

procedure TfrmSetupWizard.btnBuildNowClick(Sender: TObject);
var
  DeployPlatform: string;
  DeployConfiguration: string;
  Destinations: TArray<string>;
  KitDirectory: string;
  ProjectFileName: string;
  ProjectName: string;
  RebuildBeforeDeploy: Boolean;
  ReplaceExecutable: Boolean;
begin
  if not FCompleted or FBuildInProgress then
    Exit;
  btnBuildNow.Enabled := False;
  btnBack.Enabled := False;
  btnFinish.Enabled := False;
  btnCancel.Enabled := False;
  FBuildCompleted := False;
  FBuildInProgress := True;
  lblBuildStatus.Text := 'Deploying the application. Please wait...';
  if cboBuildPlatform.ItemIndex = 1 then
    DeployPlatform := 'Win64'
  else
    DeployPlatform := 'Win32';
  if cboBuildConfiguration.ItemIndex = 1 then
    DeployConfiguration := 'Debug'
  else
    DeployConfiguration := 'Release';
  Destinations := lstDeploymentDestinations.Items.ToStringArray;
  KitDirectory := FKitDirectory;
  ProjectFileName := FProjectProfile.ProjectFileName;
  ProjectName := FProjectProfile.ProjectName;
  RebuildBeforeDeploy := chkBuildNow.IsChecked;
  ReplaceExecutable := chkReplaceDeployedExecutable.IsChecked;
  TThread.CreateAnonymousThread(
    procedure
    var
      ApplicationDirectory: string;
      DestinationAttempt: Integer;
      DestinationReady: Boolean;
      ErrorText: string;
      Succeeded: Boolean;
    begin
      ErrorText := '';
      Succeeded := False;
      try
        if RebuildBeforeDeploy then
        begin
          AddProgress(Format('Rebuilding %s %s before deploying...',
            [DeployPlatform, DeployConfiguration]));
          AddProgress(TTargetBuildDeployer.BuildAndDeploy(ProjectFileName,
            ProjectName, DeployPlatform, DeployConfiguration, KitDirectory));
        end;
        AddProgress(Format('Deploying the %s %s build.',
          [DeployPlatform, DeployConfiguration]));
        for ApplicationDirectory in Destinations do
        begin
          DestinationReady := TDirectory.Exists(ApplicationDirectory);
          if not DestinationReady then
            for DestinationAttempt := 1 to 12 do
            begin
              TThread.Sleep(500);
              DestinationReady := TDirectory.Exists(ApplicationDirectory);
              if DestinationReady then
                Break;
            end;
          if DestinationReady then
            try
              AddProgress('Build step: ' +
                TTargetBuildDeployer.DeployBuildOutput(ProjectFileName,
                  ProjectName, DeployPlatform, DeployConfiguration,
                  ApplicationDirectory, KitDirectory, ReplaceExecutable));
            except
              on E: EInOutError do
                AddProgress(Format(
                  'Executable deployment skipped for %s %s in %s: %s',
                  [DeployPlatform, DeployConfiguration,
                   ApplicationDirectory, E.Message]));
            end
          else
            AddProgress('Destination unavailable after waiting: ' +
              ApplicationDirectory);
        end;
        Succeeded := True;
      except
        on E: Exception do
        begin
          ErrorText := E.Message;
          AddProgress('BUILD STOPPED: ' + ErrorText);
        end;
      end;
      TThread.Queue(nil,
        procedure
        begin
          FBuildInProgress := False;
          FBuildCompleted := Succeeded;
          if Succeeded then
            lblBuildStatus.Text :=
              'The application was deployed to every configured folder.'
          else
            lblBuildStatus.Text := 'Build stopped: ' + ErrorText;
          UpdateBuildChoice;
          UpdateNavigation;
          if FCloseAfterBuild then
          begin
            FCloseAfterBuild := False;
            Close;
          end;
        end);
    end).Start;
end;

function TfrmSetupWizard.ExistingCatalogFileName: string;
begin
  if FProjectProfile.ProjectFileName = '' then
    Exit('');
  Result := TTranslationWorkspace.DevelopmentCatalogFileName(FProjectProfile,
    SelectedLanguageCode(cboTargetLanguage));
end;

function TfrmSetupWizard.EffectiveWorkflowName: string;
begin
  case cboWorkflowMode.ItemIndex of
    1: Result := 'Create a new translation';
    2: Result := 'Update the existing translation';
  else
    Result := 'Create a new translation';
  end;
end;

procedure TfrmSetupWizard.UpdateWorkflowSummary;
var
  Existing: Boolean;
begin
  Existing := (ExistingCatalogFileName <> '') and
    TFile.Exists(ExistingCatalogFileName);
  if FProjectProfile.ProjectFileName = '' then
    lblWorkflowSummary.Text := 'Select a project and target language to detect existing work.'
  else if Existing and (cboWorkflowMode.ItemIndex = 2) then
    lblWorkflowSummary.Text := 'Existing catalog detected. Update the existing translation will preserve reviewed and approved entries.'
  else if Existing then
    lblWorkflowSummary.Text := 'Existing catalog detected, but it will not be used unless Update Existing Translation is selected. Create New and Automatic scan the current saved source into a fresh catalog.'
  else
    lblWorkflowSummary.Text := 'No catalog exists for this language. ' +
      EffectiveWorkflowName + ' will start a new development catalog.';
end;

procedure TfrmSetupWizard.cboWorkflowModeChange(Sender: TObject);
begin
  UpdateWorkflowSummary;
end;

function TfrmSetupWizard.StagedGlossaryFileName: string;
begin
  if FReviewOutputDirectory = '' then
    FReviewOutputDirectory := TPath.Combine(FindStudioRoot,
      TPath.Combine('export\localization-review',
        TPath.Combine(FProjectProfile.ProjectName,
          SelectedLanguageCode(cboTargetLanguage))));
  Result := TPath.Combine(FReviewOutputDirectory, 'project-glossary.json');
end;

procedure TfrmSetupWizard.btnLocalizationReviewClick(Sender: TObject);
var
  ReviewForm: TfrmLocalizationReview;
  ProjectGlossary: string;
begin
  if (FCatalog = nil) or (FScanResult = nil) then
  begin
    lblFooterStatus.Text := 'Run the project scan before opening Localization Review.';
    Exit;
  end;
  if not FFinalProcessing then
  begin
    lblFooterStatus.Text :=
      'Continue through Review & Authorize. Localization Review opens automatically after translation, when translated text is available for layout analysis.';
    Exit;
  end;
  ForceDirectories(FReviewOutputDirectory);
  ProjectGlossary := TTranslationWorkspace.GlossaryFileName(FProjectProfile,
    FCatalog.Locale.LanguageCode);
  if TFile.Exists(ProjectGlossary) and not TFile.Exists(StagedGlossaryFileName) then
    TFile.Copy(ProjectGlossary, StagedGlossaryFileName, False);
  ReviewForm := TfrmLocalizationReview.Create(Self);
  try
    ReviewForm.Prepare(FProjectProfile, FCatalog, FReviewOutputDirectory,
      StagedGlossaryFileName);
    ReviewForm.ShowModal;
  finally
    ReviewForm.Free;
  end;
  if FFinalProcessing then
    lblFooterStatus.Text :=
      'Localization Review closed. Automatic validation, export, and kit generation are continuing.'
  else
    lblFooterStatus.Text :=
      'Localization Review closed. Saved glossary terms will be applied during final processing.';
end;

procedure TfrmSetupWizard.UpdateDeploymentSummary;
begin
  btnRemoveDeploymentDestination.Enabled :=
    lstDeploymentDestinations.ItemIndex >= 0;
  if FProjectProfile.ProjectFileName = '' then
    lblDeploymentSummary.Text :=
      'Select a Delphi project first. Build outputs require no entry here.'
  else if lstDeploymentDestinations.Items.Count = 0 then
    lblDeploymentSummary.Text :=
      'No separate destinations are configured. Detected Win32 and Win64 build outputs will still deploy automatically.'
  else
    lblDeploymentSummary.Text := Format(
      '%d separate application destination(s) will be remembered and deployed automatically when available. Detected build outputs are included separately.',
      [lstDeploymentDestinations.Items.Count]);
  if chkReplaceDeployedExecutable.IsChecked then
    lblDeploymentSummary.Text := lblDeploymentSummary.Text +
      ' Executable create/replace is authorized.'
  else
    lblDeploymentSummary.Text := lblDeploymentSummary.Text +
      ' JSON packs only; the deployed executable will not be replaced.';
end;

{ Whether a deployment destination deserves to be written down.

  A bare drive root is not an application folder. Remembering one means the
  Wizard offers to deploy into the top of whatever disk happens to answer to
  that letter today, and drive letters move: the drive that was F: for a music
  library is a memory stick tomorrow. Once authorised to replace the executable
  it would write one there too. }
function DestinationWorthRemembering(const APath: string): Boolean;
var
  Trimmed: string;
begin
  Trimmed := Trim(APath);
  Result := False;
  if Trimmed = '' then
    Exit;
  if SameText(IncludeTrailingPathDelimiter(Trimmed),
    IncludeTrailingPathDelimiter(TPath.GetPathRoot(Trimmed))) then
    Exit;
  Result := True;
end;

{ A remembered folder is only offered while it is actually there. A destination
  on a drive that is not mounted is not a destination. }
function DestinationAvailableNow(const APath: string): Boolean;
begin
  Result := TDirectory.Exists(APath);
end;

procedure TfrmSetupWizard.LoadDeploymentDestinations;
var
  ArrayValue: TJSONValue;
  Destinations: TJSONArray;
  FileName: string;
  JsonValue: TJSONValue;
  Root: TJSONObject;
begin
  lstDeploymentDestinations.Items.Clear;
  if FProjectProfile.ProjectFileName = '' then
  begin
    UpdateDeploymentSummary;
    Exit;
  end;
  FileName := TTranslationWorkspace.DeploymentDestinationsFileName(
    FProjectProfile);
  if not TFile.Exists(FileName) then
  begin
    UpdateDeploymentSummary;
    Exit;
  end;
  JsonValue := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(FileName, TEncoding.UTF8));
  try
    if not (JsonValue is TJSONObject) then
      raise EConvertError.Create('The saved deployment destinations file is invalid.');
    Root := TJSONObject(JsonValue);
    Destinations := Root.GetValue('destinations') as TJSONArray;
    if Destinations <> nil then
      for ArrayValue in Destinations do
        if DestinationWorthRemembering(ArrayValue.Value) and
          DestinationAvailableNow(ArrayValue.Value) and
          (lstDeploymentDestinations.Items.IndexOf(ArrayValue.Value) < 0) then
          lstDeploymentDestinations.Items.Add(ArrayValue.Value);
  finally
    JsonValue.Free;
  end;
  UpdateDeploymentSummary;
end;

procedure TfrmSetupWizard.SaveDeploymentDestinations;
var
  Destination: string;
  Destinations: TJSONArray;
  FileName: string;
  Root: TJSONObject;
begin
  FileName := TTranslationWorkspace.DeploymentDestinationsFileName(
    FProjectProfile);
  ForceDirectories(TPath.GetDirectoryName(FileName));
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(1));
    Root.AddPair('applicationId', FProjectProfile.ProjectName);
    Destinations := TJSONArray.Create;
    for Destination in lstDeploymentDestinations.Items do
      if DestinationWorthRemembering(Destination) then
        Destinations.Add(Destination);
    Root.AddPair('destinations', Destinations);
    TAtomicTextFile.WriteAllText(FileName, Root.Format(2), TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

procedure TfrmSetupWizard.btnAddDeploymentDestinationClick(Sender: TObject);
var
  ApplicationDirectory: string;
begin
  if FProjectProfile.ProjectFileName = '' then
  begin
    lblFooterStatus.Text := 'Select a Delphi project before adding destinations.';
    Exit;
  end;
  ApplicationDirectory := '';
  if not SelectDirectory(
    'Select an installed, portable, network, or USB application folder',
    '', ApplicationDirectory) then
    Exit;
  ApplicationDirectory := TPath.GetFullPath(ApplicationDirectory);
  if lstDeploymentDestinations.Items.IndexOf(ApplicationDirectory) < 0 then
    lstDeploymentDestinations.Items.Add(ApplicationDirectory);
  lstDeploymentDestinations.ItemIndex :=
    lstDeploymentDestinations.Items.IndexOf(ApplicationDirectory);
  lblFooterStatus.Text :=
    'Destination staged. It will be saved only during authorized final processing.';
  UpdateDeploymentSummary;
end;

procedure TfrmSetupWizard.btnRemoveDeploymentDestinationClick(
  Sender: TObject);
begin
  if lstDeploymentDestinations.ItemIndex < 0 then
  begin
    lblFooterStatus.Text := 'Select a destination to remove.';
    Exit;
  end;
  lstDeploymentDestinations.Items.Delete(
    lstDeploymentDestinations.ItemIndex);
  lblFooterStatus.Text :=
    'Destination removal staged. It will be saved only during authorized final processing.';
  UpdateDeploymentSummary;
end;

procedure TfrmSetupWizard.lstDeploymentDestinationsChange(Sender: TObject);
begin
  UpdateDeploymentSummary;
end;

procedure TfrmSetupWizard.FormDestroy(Sender: TObject);
begin
  FDeploymentCommands.Free;
  FCatalog.Free;
  FScanResult.Free;
end;

procedure TfrmSetupWizard.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if FScanInProgress then
  begin
    TInterlocked.Exchange(FScanCancelRequested, 1);
    FCloseAfterScan := True;
    CanClose := False;
    lblFooterStatus.Text := 'Cancelling the project scan before closing...';
  end
  else if FProviderTestInProgress then
  begin
    TInterlocked.Exchange(FProviderTestCancelRequested, 1);
    FCloseAfterProviderTest := True;
    CanClose := False;
    lblFooterStatus.Text := 'Cancelling the connection test before closing...';
  end
  else if FBuildInProgress then
  begin
    FCloseAfterBuild := True;
    CanClose := False;
    lblFooterStatus.Text := 'Waiting for the build/deployment operation to finish before closing...';
  end
  else if FFinalProcessing then
  begin
    TInterlocked.Exchange(FFinalCancelRequested, 1);
    FCloseAfterFinalProcessing := True;
    CanClose := False;
    lblFooterStatus.Text := 'Cancelling final processing before closing...';
  end
  else
    CanClose := True;
end;

procedure TfrmSetupWizard.btnCancelClick(Sender: TObject);
begin
  if FScanInProgress then
  begin
    TInterlocked.Exchange(FScanCancelRequested, 1);
    lblFooterStatus.Text := 'Cancelling project scan...';
    Exit;
  end;
  if FFinalProcessing then
  begin
    TInterlocked.Exchange(FFinalCancelRequested, 1);
    lblFooterStatus.Text := 'Cancelling final processing...';
    Exit;
  end;
  if FProviderTestInProgress then
  begin
    TInterlocked.Exchange(FProviderTestCancelRequested, 1);
    lblFooterStatus.Text := 'Cancelling the connection test...';
    Exit;
  end;
  if FBuildInProgress then
    Exit;
  ModalResult := mrCancel;
end;

procedure TfrmSetupWizard.btnFinishClick(Sender: TObject);
begin
  if not FCompleted or (chkBuildNow.IsChecked and not FBuildCompleted) then
    Exit;
  ModalResult := mrOk;
end;

function TfrmSetupWizard.SelectedLanguageCode(ACombo: TComboBox): string;
var
  CloseBracket: Integer;
  OpenBracket: Integer;
begin
  Result := '';
  if ACombo.ItemIndex < 0 then
    Exit;
  OpenBracket := LastDelimiter('[', ACombo.Items[ACombo.ItemIndex]);
  CloseBracket := LastDelimiter(']', ACombo.Items[ACombo.ItemIndex]);
  if (OpenBracket > 0) and (CloseBracket > OpenBracket) then
    Result := Copy(ACombo.Items[ACombo.ItemIndex], OpenBracket + 1,
      CloseBracket - OpenBracket - 1);
end;

function TfrmSetupWizard.SelectedProvider: TTranslationProvider;
begin
  if cboProvider.ItemIndex = 1 then
    Result := tpGoogle
  else
    Result := tpDeepL;
end;

function TfrmSetupWizard.EffectiveApiKey: string;
begin
  Result := Trim(FSessionApiKey);
  if Result = '' then
    Result := Trim(edtApiKey.Text);
  if (Result = '') and TProviderCredentialStore.Exists(SelectedProvider) then
    Result := TProviderCredentialStore.Read(SelectedProvider);
end;

procedure TfrmSetupWizard.SetStep(const AStep: Integer);
begin
  if (AStep < 1) or (AStep > StepCount) then
    Exit;
  FCurrentStep := AStep;
  WizardTabs.TabIndex := AStep - 1;
  if FCurrentStep = 7 then
    BuildReview;
  UpdateRail;
  UpdateNavigation;
end;

procedure TfrmSetupWizard.UpdateNavigation;
var
  FinalStep: Boolean;
begin
  FinalStep := FCurrentStep = StepCount;
  btnBack.Visible := not FinalStep;
  btnBack.Enabled := (FCurrentStep > 1) and not FFinalProcessing;
  btnCancel.Enabled := not FBuildInProgress;
  btnCancel.Visible := not (FinalStep and FCompleted);
  if FFinalProcessing then
    btnCancel.Text := 'Stop'
  else
    btnCancel.Text := 'Cancel';
  btnNext.Visible := not FinalStep;
  btnFinish.Visible := FinalStep;
  btnFinish.Enabled := FCompleted and
    not FFinalProcessing and
    not FBuildInProgress and
    ((not chkBuildNow.IsChecked) or FBuildCompleted);
  if FCurrentStep = 7 then
  begin
    btnNext.Text := 'Begin Final Processing';
    btnNext.Enabled := chkTargetProjectClosed.IsChecked and
      chkAuthorizeFinal.IsChecked;
  end
  else
  begin
    btnNext.Text := 'Next';
    btnNext.Enabled := not FFinalProcessing;
  end;
  btnNext.Default := btnNext.Visible and btnNext.Enabled;
  btnFinish.Default := btnFinish.Visible and btnFinish.Enabled;
end;

procedure TfrmSetupWizard.UpdateRail;
var
  Index: Integer;
  Rail: TLabel;
begin
  for Index := 1 to StepCount do
  begin
    Rail := FindComponent('railStep' + Index.ToString) as TLabel;
    if Rail = nil then
      Continue;
    Rail.Enabled := (Index <= FHighestStep) and not FFinalProcessing;
    if Index = FCurrentStep then
    begin
      Rail.TextSettings.FontColor := $FFFFFFFF;
      Rail.TextSettings.Font.Style := [TFontStyle.fsBold];
    end
    else if Index <= FHighestStep then
    begin
      Rail.TextSettings.FontColor := $FFE7F1FF;
      Rail.TextSettings.Font.Style := [];
    end
    else
    begin
      Rail.TextSettings.FontColor := $FF7894B3;
      Rail.TextSettings.Font.Style := [];
    end;
  end;
end;

procedure TfrmSetupWizard.railStepClick(Sender: TObject);
var
  StepNumber: Integer;
begin
  if FFinalProcessing then
    Exit;
  StepNumber := TComponent(Sender).Tag;
  if StepNumber <= FHighestStep then
    SetStep(StepNumber);
end;

procedure TfrmSetupWizard.btnBackClick(Sender: TObject);
begin
  if not FFinalProcessing then
    SetStep(FCurrentStep - 1);
end;

procedure TfrmSetupWizard.btnNextClick(Sender: TObject);
begin
  if not ValidateCurrentStep then
    Exit;
  if FCurrentStep = 7 then
  begin
    FHighestStep := 8;
    SetStep(8);
    ExecuteFinalProcessing;
    Exit;
  end;
  FHighestStep := Max(FHighestStep, FCurrentStep + 1);
  SetStep(FCurrentStep + 1);
end;

function TfrmSetupWizard.ValidateCurrentStep: Boolean;
begin
  Result := False;
  case FCurrentStep of
    2:
      if FProjectProfile.ProjectFileName = '' then
      begin
        lblFooterStatus.Text := 'Select a Delphi project before continuing.';
        Exit;
      end;
    4:
      if SelectedLanguageCode(cboTargetLanguage) = '' then
      begin
        lblFooterStatus.Text := 'Select a target language before continuing.';
        Exit;
      end
      else if (cboWorkflowMode.ItemIndex = 1) and
        TFile.Exists(ExistingCatalogFileName) then
      begin
        lblFooterStatus.Text := 'A catalog already exists, but Create New Translation will ignore it and use the current saved source files. Select Update Existing Translation only if you want to preserve that catalog.';
        Result := True;
        Exit;
      end
      else if (cboWorkflowMode.ItemIndex = 2) and
        not TFile.Exists(ExistingCatalogFileName) then
      begin
        lblFooterStatus.Text := 'No existing catalog was found. Choose Create New Translation or Automatic.';
        Exit;
      end;
    5:
      if EffectiveApiKey = '' then
      begin
        lblFooterStatus.Text := 'Save or enter an API key before continuing.';
        Exit;
      end;
    6:
      if (FScanResult = nil) or (FCatalog = nil) then
      begin
        lblFooterStatus.Text := 'Run the project scan before continuing.';
        Exit;
      end;
    7:
      if not chkTargetProjectClosed.IsChecked then
      begin
        lblFooterStatus.Text :=
          'Close the target project in RAD Studio and confirm it before continuing.';
        Exit;
      end
      else if not chkAuthorizeFinal.IsChecked then
      begin
        lblFooterStatus.Text := 'Authorize final processing to continue.';
        Exit;
      end;
  end;
  lblFooterStatus.Text := '';
  Result := True;
end;

procedure TfrmSetupWizard.btnBrowseProjectClick(Sender: TObject);
begin
  if not dlgOpenProject.Execute then
    Exit;
  try
    FProjectProfile := TProjectDetector.Detect(dlgOpenProject.FileName);
    if FProjectProfile.Framework = tfUnknown then
      raise Exception.Create('The project framework could not be identified.');
    edtProjectFile.Text := FProjectProfile.ProjectFileName;
    edtApplicationId.Text := FProjectProfile.ProjectName;
    LoadDeploymentDestinations;
    chkTargetProjectClosed.IsChecked := False;
    chkAuthorizeFinal.IsChecked := False;
    lblProjectSummary.Text := Format('%s  |  %s  |  %s  |  %d form resources',
      [FProjectProfile.ProjectName,
       TargetFrameworkToString(FProjectProfile.Framework),
       ProjectPlatformsDisplayName(FProjectProfile),
       FProjectProfile.FormResourceCount]);
    FreeAndNil(FScanResult);
    FLastScanCompletedAt := 0;
    FreeAndNil(FCatalog);
    FCatalogFileName := '';
    FReviewOutputDirectory := '';
    FHighestStep := Min(FHighestStep, 5);
    lblFooterStatus.Text := 'Project identified. No target file was changed.';
    UpdateWorkflowSummary;
    UpdateRail;
    btnNext.SetFocus;
  except
    on E: Exception do
    begin
      FProjectProfile := Default(TProjectProfile);
      edtProjectFile.Text := '';
      edtApplicationId.Text := '';
      lblProjectSummary.Text := E.Message;
    end;
  end;
end;

procedure TfrmSetupWizard.btnCopyApplicationIdClick(Sender: TObject);
var
  Clipboard: IFMXClipboardService;
begin
  if (Trim(edtApplicationId.Text) <> '') and
     TPlatformServices.Current.SupportsPlatformService(
       IFMXClipboardService, Clipboard) then
  begin
    Clipboard.SetClipboard(TValue.From<string>(edtApplicationId.Text));
    lblFooterStatus.Text := 'Application ID copied: ' + edtApplicationId.Text;
  end;
end;

procedure TfrmSetupWizard.ApplyLocaleDefaults;
var
  LanguageCode: string;
  DisplayName: string;
  BracketAt: Integer;
begin
  if cboTargetLanguage.ItemIndex < 0 then
    Exit;
  DisplayName := cboTargetLanguage.Items[cboTargetLanguage.ItemIndex];
  BracketAt := Pos(' [', DisplayName);
  if BracketAt > 0 then
    DisplayName := Copy(DisplayName, 1, BracketAt - 1);
  LanguageCode := SelectedLanguageCode(cboTargetLanguage);
  edtNativeName.Text := CanonicalNativeLanguageName(LanguageCode, DisplayName);
  lblLanguageSummary.Text := Format(
    'The runtime pack will use %s. Dates, times, separators, and currency are stored in the JSON pack.',
    [LanguageCode]);
end;

procedure TfrmSetupWizard.cboTargetLanguageChange(Sender: TObject);
begin
  ApplyLocaleDefaults;
  FreeAndNil(FScanResult);
  FLastScanCompletedAt := 0;
  FreeAndNil(FCatalog);
  FCatalogFileName := '';
  FReviewOutputDirectory := '';
  if FHighestStep > 6 then
    FHighestStep := 6;
  UpdateRail;
  UpdateWorkflowSummary;
end;

procedure TfrmSetupWizard.cboProviderChange(Sender: TObject);
begin
  cboDeepLPlan.Enabled := SelectedProvider = tpDeepL;
  edtApiKey.Text := '';
  FSessionApiKey := '';
  if TProviderCredentialStore.Exists(SelectedProvider) then
    lblProviderStatus.Text := 'A saved key is available in Windows Credential Manager.'
  else
    lblProviderStatus.Text := 'No saved key is available for this provider.';
end;

procedure TfrmSetupWizard.btnSaveKeyClick(Sender: TObject);
var
  Key: string;
  Settings: TProviderSettings;
begin
  try
    Key := Trim(edtApiKey.Text);
    if Key = '' then
      raise Exception.Create('Enter an API key first.');
    Settings := TProviderSettings.Load;
    try
      Settings.Provider := SelectedProvider;
      if cboDeepLPlan.ItemIndex = 1 then
        Settings.DeepLPlan := dpPro
      else
        Settings.DeepLPlan := dpFree;
      Settings.RememberCredential := chkRememberKey.IsChecked;
      Settings.Save;
    finally
      Settings.Free;
    end;
    if chkRememberKey.IsChecked then
    begin
      TProviderCredentialStore.Write(SelectedProvider, Key);
      FSessionApiKey := '';
      lblProviderStatus.Text := 'API key saved securely on this computer.';
    end
    else
    begin
      TProviderCredentialStore.Delete(SelectedProvider);
      FSessionApiKey := Key;
      lblProviderStatus.Text := 'API key retained for this Studio session only.';
    end;
    edtApiKey.Text := '';
  except
    on E: Exception do
      lblProviderStatus.Text := 'Unable to save the key: ' + E.Message;
  end;
end;

procedure TfrmSetupWizard.btnTestConnectionClick(Sender: TObject);
var
  ApiKey: string;
  Plan: TDeepLPlan;
  Provider: TTranslationProvider;
begin
  if FProviderTestInProgress then
    Exit;
  btnTestConnection.Enabled := False;
  if cboDeepLPlan.ItemIndex = 1 then
    Plan := dpPro
  else
    Plan := dpFree;
  Provider := SelectedProvider;
  ApiKey := EffectiveApiKey;
  FProviderTestInProgress := True;
  FCloseAfterProviderTest := False;
  TInterlocked.Exchange(FProviderTestCancelRequested, 0);
  lblProviderStatus.Text := 'Testing the provider connection...';
  UpdateNavigation;
  TThread.CreateAnonymousThread(
    procedure
    var
      Client: TTranslationProviderClient;
      ErrorText: string;
      Passed: Boolean;
    begin
      Passed := False;
      ErrorText := '';
      Client := nil;
      try
        try
          Client := TTranslationProviderClient.Create(Provider, Plan,
            ApiKey, 30, 40);
          Client.TestConnection(
            function: Boolean
            begin
              Result := TInterlocked.CompareExchange(
                FProviderTestCancelRequested, 0, 0) <> 0;
            end);
          Passed := True;
        except
          on E: Exception do
            ErrorText := E.Message;
        end;
      finally
        Client.Free;
      end;
      TThread.Queue(nil,
        procedure
        begin
          FProviderTestInProgress := False;
          btnTestConnection.Enabled := True;
          UpdateNavigation;
          if TInterlocked.CompareExchange(
            FProviderTestCancelRequested, 0, 0) <> 0 then
            lblProviderStatus.Text := 'Connection test cancelled.'
          else if Passed then
            lblProviderStatus.Text := 'Connection test passed.'
          else
            lblProviderStatus.Text := 'Connection test failed: ' + ErrorText;
          if FCloseAfterProviderTest then
          begin
            FCloseAfterProviderTest := False;
            Close;
          end;
        end);
    end).Start;
end;

procedure TfrmSetupWizard.LoadExistingCatalog;
var
  ExistingFileName: string;
  LanguageCode: string;
  LocaleFacts: TLocaleFacts;
  LocaleSettings: TFormatSettings;
begin
  LanguageCode := SelectedLanguageCode(cboTargetLanguage);
  ExistingFileName := TTranslationWorkspace.DevelopmentCatalogFileName(
    FProjectProfile, LanguageCode);
  FreeAndNil(FCatalog);
  if (cboWorkflowMode.ItemIndex = 2) and TFile.Exists(ExistingFileName) then
    FCatalog := TCatalogJson.LoadFromFile(ExistingFileName)
  else
  begin
    FCatalog := TTranslationCatalog.Create;
    FCatalog.ApplicationId := FProjectProfile.ProjectName;
    FCatalog.Framework := FProjectProfile.Framework;
    FCatalog.SourceLanguage := SelectedLanguageCode(cboSourceLanguage);
    FCatalog.Locale.LanguageCode := LanguageCode;
    FCatalog.Locale.NativeLanguageName := edtNativeName.Text;
    LocaleFacts := TLocaleFactsReader.Read(LanguageCode);
    if SameText(LocaleFacts.TextDirection, 'rtl') then
      FCatalog.Locale.TextDirection := 'rtl'
    else
      FCatalog.Locale.TextDirection := 'ltr';
    if TLocaleFactsReader.Known(LanguageCode) then
    begin
      FCatalog.Locale.ShortDateFormat := LocaleFacts.ShortDateFormat;
      FCatalog.Locale.LongDateFormat := LocaleFacts.LongDateFormat;
      FCatalog.Locale.ShortTimeFormat := LocaleFacts.ShortTimeFormat;
      FCatalog.Locale.LongTimeFormat := LocaleFacts.LongTimeFormat;
      FCatalog.Locale.DecimalSeparator := LocaleFacts.DecimalSeparator;
      FCatalog.Locale.ThousandSeparator := LocaleFacts.ThousandSeparator;
      FCatalog.Locale.CurrencySymbol := LocaleFacts.CurrencySymbol;
      FCatalogFileName := ExistingFileName;
      Exit;
    end;
    try
      LocaleSettings := TFormatSettings.Create(LanguageCode);
      FCatalog.Locale.ShortDateFormat := LocaleSettings.ShortDateFormat;
      FCatalog.Locale.LongDateFormat := LocaleSettings.LongDateFormat;
      FCatalog.Locale.ShortTimeFormat := LocaleSettings.ShortTimeFormat;
      FCatalog.Locale.LongTimeFormat := LocaleSettings.LongTimeFormat;
      FCatalog.Locale.DecimalSeparator := LocaleSettings.DecimalSeparator;
      FCatalog.Locale.ThousandSeparator := LocaleSettings.ThousandSeparator;
      FCatalog.Locale.CurrencySymbol := LocaleSettings.CurrencyString;
    except
      FCatalog.Locale.ShortDateFormat := 'yyyy-MM-dd';
      FCatalog.Locale.LongDateFormat := 'dddd, d MMMM yyyy';
      FCatalog.Locale.ShortTimeFormat := 'HH:mm';
      FCatalog.Locale.LongTimeFormat := 'HH:mm:ss';
      FCatalog.Locale.DecimalSeparator := '.';
      FCatalog.Locale.ThousandSeparator := ',';
      FCatalog.Locale.CurrencySymbol := '';
    end;
  end;
  FCatalogFileName := ExistingFileName;
end;

procedure TfrmSetupWizard.btnRunScanClick(Sender: TObject);
var
  Profile: TProjectProfile;
begin
  if FScanInProgress then
    Exit;
  btnRunScan.Enabled := False;
  ContentCard.Enabled := False;
  RailBackground.Enabled := False;
  btnBack.Enabled := False;
  btnNext.Enabled := False;
  btnCancel.Enabled := True;
  btnFinish.Enabled := False;
  lblFooterStatus.Text := 'Scanning project text resources...';
  FScanInProgress := True;
  FCloseAfterScan := False;
  TInterlocked.Exchange(FScanCancelRequested, 0);
  Profile := FProjectProfile;
  TThread.CreateAnonymousThread(
    procedure
    var
      ErrorText: string;
      MergeSummary: TCatalogMergeSummary;
      NewScanResult: TProjectScanResult;
      RawScanCount: Integer;
      RecoveredSemanticCount: Integer;
    begin
      ErrorText := '';
      NewScanResult := nil;
      try
        NewScanResult := TProjectScanner.Scan(Profile,
          function: Boolean
          begin
            Result := TInterlocked.CompareExchange(
              FScanCancelRequested, 0, 0) <> 0;
          end,
          procedure(const AStage: string; const AFilesCompleted: Integer)
          begin
            TThread.Queue(nil,
              procedure
              begin
                if not (csDestroying in ComponentState) then
                  lblFooterStatus.Text := Format(
                    'Scanning %s: %d file(s) completed...',
                    [AStage, AFilesCompleted]);
              end);
          end);
      except
        on E: Exception do
          ErrorText := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        var
          LocalItem: TScanItem;
        begin
          try
            if ErrorText <> '' then
            begin
              NewScanResult.Free;
              if TInterlocked.CompareExchange(
                FScanCancelRequested, 0, 0) <> 0 then
                lblFooterStatus.Text := 'Project scan cancelled.'
              else
                lblFooterStatus.Text := 'Scan failed: ' + ErrorText;
            end
            else
            begin
              FreeAndNil(FScanResult);
              FScanResult := NewScanResult;
              NewScanResult := nil;
              FLastScanCompletedAt := Now;
              RawScanCount := FScanResult.Items.Count;
              RecoveredSemanticCount :=
                TScanCatalogMerger.RecoverWorkspaceSemanticContracts(
                TTranslationWorkspace.DevelopmentDirectory(FProjectProfile),
                FProjectProfile.ProjectName,
                SelectedLanguageCode(cboSourceLanguage),
                FProjectProfile.Framework, FScanResult);
              LoadExistingCatalog;
              MergeSummary := TScanCatalogMerger.Merge(FScanResult, FCatalog);
              memScanResults.Lines.BeginUpdate;
              try
                memScanResults.Lines.Clear;
                for LocalItem in FScanResult.Items do
                  memScanResults.Lines.Add(LocalItem.Key + ' = ' +
                    LocalItem.SourceText);
              finally
                memScanResults.Lines.EndUpdate;
              end;
              if cboWorkflowMode.ItemIndex = 2 then
                lblScanSummary.Text := Format(
                  '%d unique catalog entries  |  %d new  |  %d changed  |  %d unchanged  |  %d obsolete',
                  [FScanResult.Items.Count - MergeSummary.DuplicateScanKeys,
                   MergeSummary.NewEntries,
                   MergeSummary.ChangedEntries, MergeSummary.UnchangedEntries,
                   MergeSummary.ObsoleteEntries])
              else
                lblScanSummary.Text := Format(
                  '%d unique catalog entries  |  new catalog',
                  [FScanResult.Items.Count - MergeSummary.DuplicateScanKeys]);
              lblScanSummary.Text := lblScanSummary.Text + sLineBreak + Format(
                '%d raw scanned occurrences | %d recovered semantic contracts | %d duplicate occurrences collapsed',
                [RawScanCount, RecoveredSemanticCount,
                 MergeSummary.DuplicateScanKeys]) + sLineBreak + Format(
                '%d form properties | %d resourcestrings | %d runtime assignments | %d forms | %d source files',
                [FScanResult.CountByKind(stkFormProperty),
                 FScanResult.CountByKind(stkResourceString),
                 FScanResult.CountByKind(stkRuntimeAssignment),
                 FScanResult.FormFilesScanned,
                 FScanResult.SourceFilesScanned]);
              FReviewOutputDirectory := TPath.Combine(FindStudioRoot,
                TPath.Combine('export\localization-review',
                  TPath.Combine(FProjectProfile.ProjectName,
                    SelectedLanguageCode(cboTargetLanguage))));
              UpdateWorkflowSummary;
              lblFooterStatus.Text :=
                'Scan complete. Continue through Review & Authorize; automatic translation and Localization Review occur during final processing.';
            end;
          except
            on E: Exception do
              lblFooterStatus.Text := 'Scan failed: ' + E.Message;
          end;
          FScanInProgress := False;
          ContentCard.Enabled := True;
          RailBackground.Enabled := True;
          UpdateNavigation;
          if FCloseAfterScan then
          begin
            FCloseAfterScan := False;
            ModalResult := mrCancel;
          end;
        end);
    end).Start;
end;

function TfrmSetupWizard.FindStudioRoot: string;
var
  Candidate: string;
  Parent: string;
begin
  Candidate := TPath.GetFullPath(ExtractFilePath(ParamStr(0)));
  while Candidate <> '' do
  begin
    if TFile.Exists(TPath.Combine(Candidate,
      'DelphiAppTranslationStudio.dproj')) then
      Exit(Candidate);
    Parent := TPath.GetDirectoryName(Candidate);
    if SameText(Parent, Candidate) then
      Break;
    Candidate := Parent;
  end;
  raise Exception.Create('The Studio project root could not be located.');
end;

procedure TfrmSetupWizard.chkAuthorizeFinalChange(Sender: TObject);
begin
  UpdateNavigation;
end;

procedure TfrmSetupWizard.BuildReview;
var
  MissingCount: Integer;
  Entry: TTranslationEntry;
begin
  MissingCount := 0;
  if FCatalog <> nil then
    for Entry in FCatalog.Entries do
      if TranslationEntryEligibleForAutomaticTranslation(Entry) and
         not (Entry.Status in [tsExcluded, tsObsolete, tsReviewed,
           tsApproved]) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged, tsError])) then
        Inc(MissingCount);
  memReview.Lines.Text :=
    'Project: ' + FProjectProfile.ProjectName + sLineBreak +
    'Project file: ' + FProjectProfile.ProjectFileName + sLineBreak +
    'Application ID: ' + FProjectProfile.ProjectName + sLineBreak +
    'Framework: ' + TargetFrameworkToString(FProjectProfile.Framework) + sLineBreak +
    'Target language: ' + edtNativeName.Text + ' (' +
      SelectedLanguageCode(cboTargetLanguage) + ')' + sLineBreak +
    'Workflow: ' + EffectiveWorkflowName + sLineBreak +
    'Provider: ' + TranslationProviderDisplayName(SelectedProvider) + sLineBreak +
    Format('Scanned entries: %d', [FScanResult.Items.Count]) + sLineBreak +
    Format('Unresolved entries to translate: %d', [MissingCount]) + sLineBreak +
    'Integration: component kit only; target project files remain read-only.' +
      sLineBreak +
    'Search Path: passed temporarily to Wizard-initiated MSBuild commands.' +
      sLineBreak +
    'Deployment: automatic during final processing and Wizard-initiated builds.' +
      sLineBreak +
    Format('Separate application destinations: %d (automatically deployed when available).',
      [lstDeploymentDestinations.Items.Count]) + sLineBreak +
    'RAD Studio: target project must be closed before final processing.' +
      sLineBreak +
    'Backup: required ZIP before final processing.';
end;

procedure TfrmSetupWizard.GenerateLocalizationReviewArtifacts;
var
  CatalogFiles: TArray<string>;
  EnvelopeFileName: string;
  HtmlFileName: string;
  ProposalFileName: string;
  Review: TLocalizationReview;
begin
  ForceDirectories(FReviewOutputDirectory);
  HtmlFileName := TPath.Combine(FReviewOutputDirectory,
    'localization-review.html');
  ProposalFileName := TPath.Combine(FReviewOutputDirectory,
    'layout-proposal.json');
  EnvelopeFileName := TPath.Combine(FReviewOutputDirectory,
    'multilingual-layout-envelope.json');
  Review := TLocalizationReviewer.Analyze(FCatalog);
  try
    TLocalizationReviewer.GenerateReviewPackage(Review, HtmlFileName,
      ProposalFileName);
    CatalogFiles := TDirectory.GetFiles(
      TTranslationWorkspace.DevelopmentDirectory(FProjectProfile),
      '*.translation-project.json', TSearchOption.soTopDirectoryOnly);
    TLocalizationReviewer.SaveEnvelope(CatalogFiles, EnvelopeFileName);
    AddProgress('Localization audit: ' + Review.Summary);
    AddProgress('Visual review package: ' + HtmlFileName);
    AddProgress('Persistent layout proposals: ' + ProposalFileName);
    AddProgress('Multilingual layout envelope: ' + EnvelopeFileName);
  finally
    Review.Free;
  end;
end;

procedure TfrmSetupWizard.AddProgress(const AText: string);
var
  TextToAdd: string;
begin
  if TThread.CurrentThread.ThreadID <> MainThreadID then
  begin
    TextToAdd := AText;
    TThread.Queue(nil,
      procedure
      begin
        if not (csDestroying in ComponentState) then
          AddProgress(TextToAdd);
      end);
    Exit;
  end;
  memProgress.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
  memProgress.GoToTextEnd;
end;

procedure TfrmSetupWizard.BuildDeploymentCommands;
const
  Configurations: array[0..1] of string = ('Debug', 'Release');
  Platforms: array[0..1] of string = ('Win32', 'Win64');
var
  Configuration: string;
  OutputDirectory: string;
  Platform: string;
  PowerShellFileName: string;
  ScriptName: string;
  UniqueDirectories: TStringList;
begin
  FDeploymentCommands.Clear;
  PowerShellFileName := WindowsPowerShellFileName;
  ScriptName := TPath.Combine(FKitDirectory, 'Deploy-LanguagePacks.ps1');
  UniqueDirectories := TStringList.Create;
  try
    UniqueDirectories.CaseSensitive := False;
    UniqueDirectories.Duplicates := dupIgnore;
    for Platform in Platforms do
      for Configuration in Configurations do
      begin
        OutputDirectory := TTargetBuildDeployer.FindBuildOutputDirectory(
          FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
          Platform, Configuration);
        if (OutputDirectory <> '') and
          (UniqueDirectories.IndexOf(OutputDirectory) < 0) then
          UniqueDirectories.Add(OutputDirectory);
      end;
    for OutputDirectory in UniqueDirectories do
      FDeploymentCommands.Add(Format(
        '& "%s" -NoProfile -ExecutionPolicy Bypass -File "%s" -ApplicationDirectory "%s"',
        [PowerShellFileName, ScriptName, OutputDirectory]));
  finally
    UniqueDirectories.Free;
  end;
end;

function TfrmSetupWizard.ExistingBuildOutputDirectories: TArray<string>;
const
  Configurations: array[0..1] of string = ('Debug', 'Release');
  Platforms: array[0..1] of string = ('Win32', 'Win64');
var
  Configuration: string;
  Match: TMatch;
  Matches: TMatchCollection;
  OutputDirectory: string;
  OutputPattern: string;
  Platform: string;
  ProjectDirectory: string;
  ProjectText: string;
  UniqueDirectories: TStringList;

  procedure AddPattern(const APattern: string);
  var
    Candidate: string;
    LocalConfiguration: string;
    LocalPlatform: string;
  begin
    for LocalPlatform in Platforms do
      for LocalConfiguration in Configurations do
      begin
        Candidate := Trim(APattern);
        Candidate := StringReplace(Candidate, '$(Platform)', LocalPlatform,
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(Config)', LocalConfiguration,
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(PROJECTDIR)', ProjectDirectory,
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(MSBuildProjectDirectory)',
          ProjectDirectory, [rfReplaceAll, rfIgnoreCase]);
        if Pos('$(', Candidate) > 0 then
          Continue;
        if not TPath.IsPathRooted(Candidate) then
          Candidate := TPath.Combine(ProjectDirectory, Candidate);
        Candidate := TPath.GetFullPath(Candidate);
        if TDirectory.Exists(Candidate) then
          UniqueDirectories.Add(Candidate);
      end;
  end;

begin
  ProjectDirectory := TPath.GetDirectoryName(FProjectProfile.ProjectFileName);
  UniqueDirectories := TStringList.Create;
  try
    UniqueDirectories.CaseSensitive := False;
    UniqueDirectories.Duplicates := dupIgnore;
    UniqueDirectories.Sorted := True;
    ProjectText := TFile.ReadAllText(FProjectProfile.ProjectFileName,
      TEncoding.UTF8);
    Matches := TRegEx.Matches(ProjectText,
      '<DCC_ExeOutput>(.*?)</DCC_ExeOutput>',
      [roIgnoreCase, roSingleLine]);
    for Match in Matches do
    begin
      OutputPattern := Match.Groups[1].Value;
      OutputPattern := StringReplace(OutputPattern, '&amp;', '&',
        [rfReplaceAll, rfIgnoreCase]);
      AddPattern(OutputPattern);
    end;
    if Matches.Count = 0 then
      for Platform in Platforms do
        for Configuration in Configurations do
        begin
          OutputDirectory := TTargetBuildDeployer.FindBuildOutputDirectory(
            FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
            Platform, Configuration);
          if TDirectory.Exists(OutputDirectory) then
            UniqueDirectories.Add(TPath.GetFullPath(OutputDirectory));
        end;
    Result := UniqueDirectories.ToStringArray;
  finally
    UniqueDirectories.Free;
  end;
end;

function TfrmSetupWizard.DeployLanguagePacksToExistingOutputs: Integer;
var
  ApplicationDirectory: string;
begin
  Result := 0;
  for ApplicationDirectory in ExistingBuildOutputDirectories do
  begin
    if not RunDeploymentScript(ApplicationDirectory) then
      raise Exception.Create('Deployment failed for ' + ApplicationDirectory);
    Inc(Result);
    AddProgress('Language packs deployed to ' + ApplicationDirectory);
  end;
end;

{ Deployment must never copy a stale executable. Rebuild every platform and
  configuration that already has a build-output folder so each one matches the
  runtime and language packs produced by this pass, before anything is copied
  to build outputs or configured destinations. }
procedure TfrmSetupWizard.RebuildAllTargetConfigurations;
var
  BuiltCount: Integer;
  Configuration: string;
  OutputDirectory: string;
  Platform: string;
begin
  BuiltCount := 0;
  for Platform in ['Win32', 'Win64'] do
    for Configuration in ['Debug', 'Release'] do
    begin
      if TInterlocked.CompareExchange(
        FFinalCancelRequested, 0, 0) <> 0 then
        raise EAbort.Create('Final processing was cancelled.');
      OutputDirectory := TTargetBuildDeployer.FindBuildOutputDirectory(
        FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
        Platform, Configuration, False);
      if (OutputDirectory = '') or not TDirectory.Exists(OutputDirectory) then
        Continue;
      AddProgress(Format('Rebuilding %s %s before deployment...',
        [Platform, Configuration]));
      AddProgress(TTargetBuildDeployer.BuildAndDeploy(
        FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
        Platform, Configuration, FKitDirectory));
      Inc(BuiltCount);
    end;
  if BuiltCount = 0 then
    AddProgress('No existing build-output folders were found to rebuild.')
  else
    AddProgress(Format('%d target configuration(s) rebuilt with the current runtime.',
      [BuiltCount]));
end;

function TfrmSetupWizard.DeployLanguagePacksDirect(
  const AApplicationDirectory: string): Boolean;
const
  RetryCount = 15;
  RetryDelayMilliseconds = 2000;
var
  DestinationDirectory: string;
  FileName: string;
  SourceDirectory: string;
  Attempt: Integer;
begin
  Result := False;
  SourceDirectory := TPath.Combine(FKitDirectory, 'Localization\Languages');
  DestinationDirectory := TPath.Combine(AApplicationDirectory,
    'Localization\Languages');
  for Attempt := 1 to RetryCount do
    try
      { A removable drive may be mounted but not yet ready when the Wizard
        reaches deployment. Create the root and destination on every retry. }
      TDirectory.CreateDirectory(AApplicationDirectory);
      TDirectory.CreateDirectory(DestinationDirectory);
      for FileName in TDirectory.GetFiles(SourceDirectory, '*.json') do
        TFile.Copy(FileName, TPath.Combine(DestinationDirectory,
          TPath.GetFileName(FileName)), True);
      Result := True;
      Exit;
    except
      on E: Exception do
      begin
        if Attempt = RetryCount then
          raise Exception.CreateFmt(
            'Unable to write language packs to %s after %d attempts: %s',
            [DestinationDirectory, RetryCount, E.Message]);
        AddProgress(Format('Destination is not ready; retrying %s (%d/%d)...',
          [AApplicationDirectory, Attempt, RetryCount]));
        Sleep(RetryDelayMilliseconds);
      end;
    end;
end;

procedure TfrmSetupWizard.ExecuteFinalProcessing;
var
  BackupDirectory: string;
  ScanItem: TScanItem;
  MissingSourceFileName: string;
  ProjectDirectory: string;
begin
  FFinalProcessing := True;
  TInterlocked.Exchange(FFinalCancelRequested, 0);
  FCompleted := False;
  FBuildCompleted := False;
  btnBack.Enabled := False;
  btnCancel.Enabled := True;
  btnNext.Enabled := False;
  btnFinish.Enabled := False;
  UpdateBuildChoice;
  UpdateRail;
  memProgress.Lines.Clear;
  FProjectConfigurationBackupDirectory := '';
  try
    if FScanResult = nil then
      raise Exception.Create(
        'Run the project scan before final processing.');
    if not TFile.Exists(FProjectProfile.ProjectFileName) then
      raise Exception.CreateFmt(
        'The selected Delphi project no longer exists: "%s". Select the project again and run a new scan before final processing.',
        [FProjectProfile.ProjectFileName]);
    if not FScanResult.SourcesStillExist(MissingSourceFileName) then
      raise Exception.CreateFmt(
        'A source file included in the previous scan no longer exists: "%s". Return to Scan Project and run the scan again before final processing.',
        [MissingSourceFileName]);
    for ScanItem in FScanResult.Items do
      if TFile.Exists(ScanItem.SourceFileName) and
         (TFile.GetLastWriteTime(ScanItem.SourceFileName) >
          FLastScanCompletedAt) then
        raise Exception.CreateFmt(
          'The source file "%s" was saved after the Wizard scan. Save all files in Delphi, return to Scan Project, run the scan again, and then repeat final processing.',
          [ScanItem.SourceFileName]);
    AddProgress('Creating the required pre-processing safety backup...');
    BackupDirectory := TPath.Combine(TPath.GetDocumentsPath,
      TPath.Combine('Delphi App Translation Backups',
        FProjectProfile.ProjectName));
    FBackupFileName := TPath.Combine(BackupDirectory,
      FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.zip');
    ProjectDirectory := TPath.GetDirectoryName(
      FProjectProfile.ProjectFileName);
    lblFinishText.Text :=
      'Creating the required safety backup. You may cancel while this runs.';
    TThread.CreateAnonymousThread(
      procedure
      var
        ErrorText: string;
      begin
        ErrorText := '';
        try
          if TInterlocked.CompareExchange(
            FFinalCancelRequested, 0, 0) <> 0 then
            raise EAbort.Create('Final processing was cancelled.');
          TDirectory.CreateDirectory(BackupDirectory);
          TZipFile.ZipDirectoryContents(FBackupFileName, ProjectDirectory);
        except
          on E: Exception do
            ErrorText := E.Message;
        end;
        TThread.Queue(nil,
          procedure
          begin
            if TInterlocked.CompareExchange(
              FFinalCancelRequested, 0, 0) <> 0 then
              StopFinalProcessing('Final processing was cancelled.')
            else if ErrorText <> '' then
              StopFinalProcessing(ErrorText)
            else
            begin
              AddProgress('Backup created: ' + FBackupFileName);
              AddProgress(
                'Target Pascal and form source files remain unchanged.');
              lblFinishText.Text :=
                'Safety backup complete. Preparing translations...';
              ContinueFinalProcessingAfterBackup;
            end;
          end);
      end).Start;
  except
    on E: Exception do
      StopFinalProcessing(E.Message);
  end;
end;

procedure TfrmSetupWizard.ContinueFinalProcessingAfterBackup;
var
  SharedMemory: TTranslationMemory;
  MemoryCount: Integer;
  ApiKey: string;
  Entry: TTranslationEntry;
  EntryIndexes: TArray<Integer>;
  Index: Integer;
  MissingCount: Integer;
  Plan: TDeepLPlan;
  Provider: TTranslationProvider;
  SourceTexts: TArray<string>;
  Contexts: TArray<string>;
  SourceLanguage: string;
  TargetLanguage: string;
  ProviderCount: Integer;
  ResolvedText: string;
  Glossary: TProjectGlossary;
  AppliedGlossaryCount: Integer;
  SharedCount: Integer;
  ContributedCount: Integer;
  UnmatchedTermCount: Integer;
  ProjectGlossaryFileName: string;
begin
  try
    if TInterlocked.CompareExchange(FFinalCancelRequested, 0, 0) <> 0 then
      raise EAbort.Create('Final processing was cancelled.');

    Provider := SelectedProvider;
    ApiKey := EffectiveApiKey;
    if cboDeepLPlan.ItemIndex = 1 then
      Plan := dpPro
    else
      Plan := dpFree;
    Glossary := nil;
    ProjectGlossaryFileName := TTranslationWorkspace.GlossaryFileName(
      FProjectProfile, FCatalog.Locale.LanguageCode);
    try
      if TFile.Exists(StagedGlossaryFileName) then
        Glossary := TProjectGlossary.LoadFromFile(StagedGlossaryFileName)
      else if TFile.Exists(ProjectGlossaryFileName) then
        Glossary := TProjectGlossary.LoadFromFile(ProjectGlossaryFileName);
      { The shared dictionary speaks first and the project glossary second, so
        anything this project has settled for itself overrides what the shared
        one believes. Everything already reviewed or approved is left alone by
        both. }
      { A language brings its hyphenation with it. German builds one word
        where English uses three and a single word cannot wrap, so a companion
        dictionary saying where that language allows a break is installed
        beside the shared terminology the first time the language is used. It
        is a plain file and can be corrected by hand. }
      if TDATHyphenation.EnsureInstalled(FCatalog.Locale.LanguageCode) then
        AddProgress(Format('Hyphenation dictionary for %s is installed at %s.',
          [FCatalog.Locale.LanguageCode,
           TDATHyphenation.FileName(FCatalog.Locale.LanguageCode)]));

      { The list of words that are ambiguous in a user interface is about
        English, the source language, so there is one of it rather than one
        per target. Which sense each one means is decided per application
        from the application's own vocabulary. }
      if TDomainProfiler.EnsureInstalled then
        AddProgress(Format('Ambiguous-term list is installed at %s.',
          [TDomainProfiler.FileName]));

      { A right-to-left language changes the shape of the interface and not
        only its words, so say so plainly rather than letting the developer
        discover it in a screenshot. Everything named here is a layout
        proposal like any other and can be rejected in review. }
      if SameText(Trim(FCatalog.Locale.TextDirection), 'rtl') then
      begin
        AddProgress(Format('%s is written right to left, so the layout is ' +
          'mirrored as well as translated.', [FCatalog.Locale.LanguageCode]));
        AddProgress('  Controls are reflected within their parent, edge ' +
          'alignment and anchors change sides, grid columns and tab order ' +
          'reverse, and reading order is set right to left.');
        AddProgress('  Numbers, times and version strings keep their own ' +
          'direction, and media transport buttons keep their order.');
        AddProgress('  Text baked into images is not translated or ' +
          'mirrored, and neither are drawings.');
      end;

      SharedCount := TSharedDictionary.ApplyToCatalog(
        FCatalog.Locale.LanguageCode, FCatalog);
      if SharedCount > 0 then
        AddProgress(Format('%d translation(s) applied from the shared %s dictionary.',
          [SharedCount, FCatalog.Locale.LanguageCode]));
      if Glossary <> nil then
      begin
        AppliedGlossaryCount := Glossary.ApplyToCatalog(FCatalog);
        Glossary.SaveToFile(ProjectGlossaryFileName);
        AddProgress(Format('%d translation(s) applied from the approved project glossary.',
          [AppliedGlossaryCount]));
        UnmatchedTermCount := Glossary.CountTermsMatchingNothing(FCatalog);
        if UnmatchedTermCount > 0 then
          AddProgress(Format('%d approved glossary term(s) matched nothing in this ' +
            'catalogue and had no effect. Check their context against the entries ' +
            'they were meant to reach.', [UnmatchedTermCount]));
        { Approved wording earned here becomes available to every later
          application, which is the whole point of a shared dictionary. }
        ContributedCount := TSharedDictionary.Contribute(
          FCatalog.Locale.LanguageCode, Glossary);
        if ContributedCount > 0 then
          AddProgress(Format('%d approved term(s) contributed to the shared %s dictionary.',
            [ContributedCount, FCatalog.Locale.LanguageCode]));
      end;
    finally
      Glossary.Free;
    end;
    TTerminologyResolver.ApplyAuthoritativeTerms(FCatalog);

    { Segments already settled while translating another application. This
      runs before anything is counted as missing, so a string translated once
      is neither paid for a second time nor given a second, different
      wording. Only exact matches are applied; a near match is a suggestion
      for a human and is deliberately not used here. }
    SharedMemory := TTranslationMemory.Load(FCatalog.Locale.LanguageCode);
    try
      MemoryCount := SharedMemory.ApplyToCatalog(FCatalog);
      if MemoryCount > 0 then
        AddProgress(Format(
          '%d entry(ies) reused from the shared %s translation memory.',
          [MemoryCount, FCatalog.Locale.LanguageCode]));
      { And what this project has already had reviewed goes back the other
        way, so the next application starts from it. }
      MemoryCount := SharedMemory.RememberCatalog(FCatalog,
        FormatDateTime('yyyy-mm-dd', Now));
      if MemoryCount > 0 then
      begin
        SharedMemory.Save;
        AddProgress(Format(
          '%d reviewed entry(ies) contributed to the shared %s memory.',
          [MemoryCount, FCatalog.Locale.LanguageCode]));
      end;
    finally
      SharedMemory.Free;
    end;
    MissingCount := 0;
    for Entry in FCatalog.Entries do
      if TranslationEntryEligibleForAutomaticTranslation(Entry) and
         not (Entry.Status in [tsExcluded, tsObsolete, tsReviewed,
           tsApproved]) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged, tsError])) then
        Inc(MissingCount);
    SetLength(EntryIndexes, MissingCount);
    SetLength(SourceTexts, MissingCount);
    SetLength(Contexts, MissingCount);
    ProviderCount := 0;
    for Index := 0 to FCatalog.Entries.Count - 1 do
    begin
      Entry := FCatalog.Entries[Index];
      if TranslationEntryEligibleForAutomaticTranslation(Entry) and
         not (Entry.Status in [tsExcluded, tsObsolete, tsReviewed,
           tsApproved]) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged, tsError])) then
      begin
        if TTerminologyResolver.TryTranslationMemory(FCatalog, Entry,
          ResolvedText) then
        begin
          Entry.TranslatedText := ResolvedText;
          Entry.Status := tsMachineTranslated;
          Entry.TranslationOrigin := torSuggestion;
          Entry.TranslationConfidence := 'translation-memory';
          Entry.TranslationReviewNote :=
            'Reused from a reviewed or approved entry with matching context.';
        end
        else if TTerminologyResolver.TryResolve(Entry,
          FCatalog.Locale.LanguageCode, ResolvedText) then
        begin
          Entry.TranslatedText := ResolvedText;
          Entry.Status := tsMachineTranslated;
          Entry.TranslationOrigin := torTerminology;
          Entry.TranslationConfidence := 'terminology';
          Entry.TranslationReviewNote := '';
        end
        else
        begin
          EntryIndexes[ProviderCount] := Index;
          SourceTexts[ProviderCount] := Entry.SourceText;
          Contexts[ProviderCount] := Entry.ContextDescription;
          Inc(ProviderCount);
        end;
      end;
    end;
    SetLength(EntryIndexes, ProviderCount);
    SetLength(SourceTexts, ProviderCount);
    SetLength(Contexts, ProviderCount);
    if ProviderCount > 0 then
    begin
      AddProgress(Format('Translating %d unresolved entries with %s...',
        [ProviderCount, TranslationProviderDisplayName(Provider)]));
      SourceLanguage := FCatalog.SourceLanguage;
      TargetLanguage := FCatalog.Locale.LanguageCode;
      TThread.CreateAnonymousThread(
        procedure
        var
          BackgroundClient: TTranslationProviderClient;
          ErrorText: string;
          Translations: TArray<string>;
        begin
          ErrorText := '';
          try
            BackgroundClient := TTranslationProviderClient.Create(Provider,
              Plan, ApiKey, 30, 40);
            try
              Translations := BackgroundClient.TranslateWithContexts(
                SourceTexts, Contexts, SourceLanguage, TargetLanguage,
                function: Boolean
                begin
                  Result := TInterlocked.CompareExchange(
                    FFinalCancelRequested, 0, 0) <> 0;
                end,
                procedure(const ACompleted, ATotal: Integer)
                begin
                  TThread.Queue(nil,
                    procedure
                    begin
                      if not (csDestroying in ComponentState) then
                        lblFinishText.Text := Format(
                          'Automatic translation: %d of %d',
                          [ACompleted, ATotal]);
                    end);
                end);
            finally
              BackgroundClient.Free;
            end;
          except
            on E: Exception do
              ErrorText := E.Message;
          end;
          TThread.Queue(nil,
            procedure
            begin
              if ErrorText <> '' then
                StopFinalProcessing(ErrorText)
              else
                ContinueFinalProcessing(EntryIndexes, Translations, Provider,
                  ProjectGlossaryFileName);
            end);
        end).Start;
      Exit;
    end
    else
    begin
      ContinueFinalProcessing(EntryIndexes, nil, Provider,
        ProjectGlossaryFileName);
      Exit;
    end;
  except
    on E: Exception do
      StopFinalProcessing(E.Message);
  end;
end;

procedure TfrmSetupWizard.ContinueFinalProcessing(
  const AEntryIndexes: TArray<Integer>;
  const ATranslatedTexts: TArray<string>;
  const AProvider: TTranslationProvider;
  const AProjectGlossaryFileName: string);
var
  AppliedGlossaryCount: Integer;
  ContributedCount: Integer;
  Destinations: TArray<string>;
  Entry: TTranslationEntry;
  Glossary: TProjectGlossary;
  Index: Integer;
  RuntimePackFileName: string;
  Validation: TCatalogValidationResult;
begin
  try
    if TInterlocked.CompareExchange(FFinalCancelRequested, 0, 0) <> 0 then
      raise EAbort.Create('Final processing was cancelled.');
    if Length(ATranslatedTexts) > 0 then
    begin
      if Length(ATranslatedTexts) <> Length(AEntryIndexes) then
        raise EInvalidOpException.Create(
          'The provider returned a different number of translations than requested.');
      for Index := 0 to High(ATranslatedTexts) do
      begin
        Entry := FCatalog.Entries[AEntryIndexes[Index]];
        Entry.TranslatedText := ATranslatedTexts[Index];
        Entry.Status := tsMachineTranslated;
        if AProvider = tpGoogle then
          Entry.TranslationOrigin := torGoogle
        else
          Entry.TranslationOrigin := torDeepL;
        if AProvider = tpGoogle then
        begin
          Entry.TranslationConfidence := 'provider-basic';
          if SameText(Entry.ContextConfidence, 'unknown') or
            ((Length(Trim(Entry.SourceText)) <= 12) and
             (Entry.SemanticConcept = '')) then
            Entry.TranslationReviewNote :=
              'Short or ambiguous text translated by Google Basic without provider-side context; review recommended.';
        end
        else
          Entry.TranslationConfidence := 'contextual-provider';
      end;
      TTerminologyResolver.ApplyAuthoritativeTerms(FCatalog);
      AddProgress(Format('%d translations recorded.',
        [Length(ATranslatedTexts)]));
    end
    else
      AddProgress('All unresolved entries were satisfied by approved terminology or translation memory; existing work was preserved.');

    TCatalogJson.SaveToFile(FCatalog, FCatalogFileName);
    AddProgress('Development catalog saved.');
    GenerateLocalizationReviewArtifacts;
    lblFinishText.Text :=
      'Automatic translation is complete. Review terminology and layout now. ' +
      'When Localization Review closes, the Wizard will automatically continue ' +
      'through validation, runtime-pack export, and component-kit generation.';
    AddProgress('Opening the required in-Wizard localization review. Final processing will resume automatically when it closes.');
    btnLocalizationReviewClick(Self);
    AddProgress('Localization review closed. Applying saved review decisions before final export...');
    Glossary := nil;
    try
      if TFile.Exists(StagedGlossaryFileName) then
        Glossary := TProjectGlossary.LoadFromFile(StagedGlossaryFileName)
      else if TFile.Exists(AProjectGlossaryFileName) then
        Glossary := TProjectGlossary.LoadFromFile(AProjectGlossaryFileName);
      if Glossary <> nil then
      begin
        AppliedGlossaryCount := Glossary.ApplyToCatalog(FCatalog);
        Glossary.SaveToFile(AProjectGlossaryFileName);
        AddProgress(Format('%d translation(s) applied from the completed in-Wizard review.',
          [AppliedGlossaryCount]));
        { Terms approved during the review are the best-vetted wording the
          product ever sees, so they travel too. }
        ContributedCount := TSharedDictionary.Contribute(
          FCatalog.Locale.LanguageCode, Glossary);
        if ContributedCount > 0 then
          AddProgress(Format('%d reviewed term(s) contributed to the shared %s dictionary.',
            [ContributedCount, FCatalog.Locale.LanguageCode]));
      end;
    finally
      Glossary.Free;
    end;
    TTerminologyResolver.ApplyAuthoritativeTerms(FCatalog);
    TCatalogJson.SaveToFile(FCatalog, FCatalogFileName);
    AddProgress('Reviewed development catalog saved.');
    GenerateLocalizationReviewArtifacts;
    Validation := TCatalogValidator.Validate(FCatalog);
    try
      if Validation.HasErrors then
        raise Exception.CreateFmt('Validation found %d blocking error(s).',
          [Validation.CountBySeverity(vsError)]);
      AddProgress(Format('Validation passed with %d warning(s).',
        [Validation.CountBySeverity(vsWarning)]));
    finally
      Validation.Free;
    end;
    RuntimePackFileName := TTranslationWorkspace.RuntimePackFileName(
      FProjectProfile, FCatalog.Locale.LanguageCode);
    TRuntimePackBuilder.ExportToFile(FCatalog, RuntimePackFileName,
      TPath.Combine(FReviewOutputDirectory, 'layout-proposal.json'));
    AddProgress('Runtime JSON pack exported: ' + RuntimePackFileName);
    SaveDeploymentDestinations;
    AddProgress(Format('%d separate application destination(s) saved.',
      [lstDeploymentDestinations.Items.Count]));
    FKitDirectory := TComponentIntegrationPackageGenerator.Generate(
      FProjectProfile, TPath.Combine(FindStudioRoot,
        'export\component-integration'),
      TPath.Combine(FindStudioRoot, 'source\runtime'),
      TPath.Combine(FindStudioRoot, 'source\components'));
    AddProgress('Component integration kit generated.');
    BuildDeploymentCommands;
    Destinations := lstDeploymentDestinations.Items.ToStringArray;
    TThread.CreateAnonymousThread(
      procedure
      var
        ApplicationDirectory: string;
        ConfiguredCount: Integer;
        DeployedCount: Integer;
        ErrorText: string;
      begin
        ConfiguredCount := 0;
        DeployedCount := 0;
        ErrorText := '';
        try
          RebuildAllTargetConfigurations;
          if TInterlocked.CompareExchange(
            FFinalCancelRequested, 0, 0) <> 0 then
            raise EAbort.Create('Final processing was cancelled.');
          DeployedCount := DeployLanguagePacksToExistingOutputs;
          for ApplicationDirectory in Destinations do
          begin
            if TInterlocked.CompareExchange(
              FFinalCancelRequested, 0, 0) <> 0 then
              raise EAbort.Create('Final processing was cancelled.');
            if not DeployLanguagePacksDirect(ApplicationDirectory) then
              raise Exception.Create(
                'Language-pack deployment failed for configured destination ' +
                ApplicationDirectory + '.');
            Inc(ConfiguredCount);
            AddProgress('Language packs deployed to configured destination ' +
              ApplicationDirectory);
          end;
        except
          on E: Exception do
            ErrorText := E.Message;
        end;
        TThread.Queue(nil,
          procedure
          begin
            if ErrorText <> '' then
              StopFinalProcessing(ErrorText)
            else
              ContinueFinalProcessingAfterDeployment(DeployedCount,
                ConfiguredCount, RuntimePackFileName);
          end);
      end).Start;
    Exit;
  except
    on E: Exception do
      StopFinalProcessing(E.Message);
  end;
end;

procedure TfrmSetupWizard.ContinueFinalProcessingAfterDeployment(
  const ADeployedCount, AConfiguredDestinationCount: Integer;
  const ARuntimePackFileName: string);
var
  Report: TStringList;
begin
  try
    if ADeployedCount = 0 then
      AddProgress('No existing build-output folders were found. The next build will deploy the packs automatically.')
    else
      AddProgress(Format('Automatic deployment completed for %d existing build output(s).',
        [ADeployedCount]));
    if lstDeploymentDestinations.Items.Count = 0 then
      AddProgress('No separate application destinations were configured.')
    else
      AddProgress(Format(
        'Automatic deployment completed for %d of %d configured application destination(s).',
        [AConfiguredDestinationCount,
         lstDeploymentDestinations.Items.Count]));
    FProjectConfigurationBackupDirectory := '';
    AddProgress('Target project source and project files were not modified.');
    Report := TStringList.Create;
    try
      Report.Add('DELPHI APP TRANSLATION - SETUP WIZARD COMPLETION REPORT');
      Report.Add('Created: ' + DateTimeToStr(Now));
      Report.Add('Project: ' + FProjectProfile.ProjectFileName);
      Report.Add('Language: ' + FCatalog.Locale.NativeLanguageName + ' (' +
        FCatalog.Locale.LanguageCode + ')');
      Report.Add('Workflow: ' + EffectiveWorkflowName);
      Report.Add('Development catalog: ' + FCatalogFileName);
      Report.Add('Runtime pack: ' + ARuntimePackFileName);
      Report.Add('Component kit: ' + FKitDirectory);
      Report.Add('Backup: ' + FBackupFileName);
      Report.Add('DPROJ transaction backup: not created; target project file was not modified');
      Report.Add('Application ID: ' + FProjectProfile.ProjectName);
      Report.Add('ComponentSource Search Path: ' +
        TPath.Combine(FKitDirectory, 'ComponentSource'));
      Report.Add('Existing build outputs deployed: ' + ADeployedCount.ToString);
      Report.Add('Configured application destinations: ' +
        lstDeploymentDestinations.Items.Count.ToString);
      Report.Add('Available configured destinations deployed: ' +
        AConfiguredDestinationCount.ToString);
      Report.Add('Localization review package: ' +
        TPath.Combine(FReviewOutputDirectory, 'localization-review.html'));
      Report.Add('Review workflow: completed inside the same Wizard processing pass before final export');
      Report.Add('');
      Report.Add('NEXT MANUAL DELPHI STEP');
      Report.Add('Install the matching DAT design package in RAD Studio if it is not already installed.');
      if FProjectProfile.Framework = tfVCL then
        Report.Add('Confirm that the primary form contains one TDATVCLLanguageManager and one connected TDATVCLLanguageComboBox.')
      else
        Report.Add('Confirm that the primary form contains one TDATFMXLanguageManager and one connected TDATFMXLanguageComboBox.');
      Report.Add('ApplicationId: ' + FProjectProfile.ProjectName);
      Report.Add('LanguagesFolder: Localization\Languages');
      Report.Add('For a manual RAD Studio build, add the ComponentSource folder listed above to the project Search Path.');
      Report.Add('');
      Report.Add('DEPLOYMENT COMMANDS');
      Report.AddStrings(FDeploymentCommands);
      Report.Add('');
      Report.Add('WIZARD PROGRESS AND DEPLOYMENT LOG');
      Report.AddStrings(memProgress.Lines);
      TAtomicTextFile.WriteAllText(TPath.Combine(FKitDirectory,
        'Wizard-Completion-Report.txt'), Report.Text, TEncoding.UTF8);
    finally
      Report.Free;
    end;
    AddProgress('Completion report written. Target Pascal, form, DPR, and DPROJ files remain unchanged.');
    FCompleted := True;
    UpdateBuildChoice;
    lblFinishText.Text :=
      'Single-pass automatic processing is complete. Translation review decisions were applied before final validation, runtime-pack export, and component-kit generation. Existing build outputs and every available application destination were deployed automatically. Target Pascal, form, DPR, and DPROJ files were not edited. If needed, use the build panel to build and deploy selected targets now.';
    lblFooterStatus.Text := 'Setup Wizard completed successfully.';
  except
    on E: Exception do
    begin
      AddProgress('STOPPED: ' + E.Message);
      FProjectConfigurationBackupDirectory := '';
      lblFinishText.Text :=
        'Processing stopped safely. Review the message below. Target Pascal, form, DPR, and DPROJ files were not edited.';
      lblFooterStatus.Text := 'Setup Wizard did not complete: ' + E.Message;
      FCompleted := False;
    end;
  end;
  FFinalProcessing := False;
  btnCancel.Enabled := not FCompleted;
  UpdateBuildChoice;
  UpdateNavigation;
  UpdateRail;
  if FCloseAfterFinalProcessing then
  begin
    FCloseAfterFinalProcessing := False;
    Close;
  end;
end;

procedure TfrmSetupWizard.StopFinalProcessing(const AMessage: string);
begin
  AddProgress('STOPPED: ' + AMessage);
  FProjectConfigurationBackupDirectory := '';
  lblFinishText.Text :=
    'Processing stopped safely. Review the message below. Target Pascal, form, DPR, and DPROJ files were not edited.';
  lblFooterStatus.Text := 'Setup Wizard did not complete: ' + AMessage;
  FCompleted := False;
  FFinalProcessing := False;
  btnCancel.Enabled := True;
  UpdateBuildChoice;
  UpdateNavigation;
  UpdateRail;
  if FCloseAfterFinalProcessing then
  begin
    FCloseAfterFinalProcessing := False;
    Close;
  end;
end;

function TfrmSetupWizard.RunDeploymentScript(
  const AApplicationDirectory: string;
  const ASkipConfiguredDestinations: Boolean): Boolean;
var
  ExitCode: Cardinal;
  Parameters: string;
  PowerShellFileName: string;
  ShellInfo: TShellExecuteInfo;
  WaitResult: Cardinal;
begin
  Result := False;
  FillChar(ShellInfo, SizeOf(ShellInfo), 0);
  ShellInfo.cbSize := SizeOf(ShellInfo);
  ShellInfo.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
  ShellInfo.Wnd := 0;
  ShellInfo.lpVerb := 'open';
  PowerShellFileName := WindowsPowerShellFileName;
  ShellInfo.lpFile := PChar(PowerShellFileName);
  Parameters := Format(
    '-NoProfile -ExecutionPolicy Bypass -File "%s" -ApplicationDirectory "%s" -ProjectDirectory "%s"',
    [TPath.Combine(FKitDirectory, 'Deploy-LanguagePacks.ps1'),
     AApplicationDirectory,
     TPath.GetDirectoryName(FProjectProfile.ProjectFileName)]);
  if ASkipConfiguredDestinations then
    Parameters := Parameters + ' -SkipConfiguredDestinations';
  ShellInfo.lpParameters := PChar(Parameters);
  ShellInfo.nShow := SW_HIDE;
  if not ShellExecuteEx(@ShellInfo) then
    Exit;
  try
    WaitResult := WaitForSingleObject(ShellInfo.hProcess,
      DeploymentProcessTimeout);
    case WaitResult of
      WAIT_OBJECT_0:
        begin
          if not GetExitCodeProcess(ShellInfo.hProcess, ExitCode) then
            RaiseLastOSError;
          Result := ExitCode = 0;
        end;
      WAIT_TIMEOUT:
        begin
          TerminateProcess(ShellInfo.hProcess, ERROR_TIMEOUT);
          WaitForSingleObject(ShellInfo.hProcess, ProcessTerminationWait);
          raise Exception.Create(
            'Language-pack deployment timed out. Its PowerShell process was stopped.');
        end;
      WAIT_FAILED:
        RaiseLastOSError;
    else
      raise Exception.CreateFmt(
        'Unexpected PowerShell wait result: %d.', [WaitResult]);
    end;
  finally
    CloseHandle(ShellInfo.hProcess);
  end;
end;

procedure TfrmSetupWizard.btnDeployApplicationFolderClick(Sender: TObject);
var
  ApplicationDirectory: string;
  Configuration: string;
  DestinationExecutable: string;
  Platform: string;
  SourceExecutable: string;
  ShouldDeployExecutable: Boolean;
  DeployedExecutable: Boolean;
begin
  if FKitDirectory = '' then
  begin
    lblFooterStatus.Text := 'Complete final processing before deployment.';
    Exit;
  end;
  ApplicationDirectory := '';
  if not SelectDirectory(
    'Select or create the application deployment folder',
    '', ApplicationDirectory) then
    Exit;
  btnDeployApplicationFolder.Enabled := False;
  try
    DeployedExecutable := False;
    DestinationExecutable := TPath.Combine(ApplicationDirectory,
      FProjectProfile.ProjectName + '.exe');
    ShouldDeployExecutable := chkReplaceDeployedExecutable.IsChecked or
      not TFile.Exists(DestinationExecutable);
    if ShouldDeployExecutable then
    begin
      for Platform in ['Win32', 'Win64'] do
      begin
        if DeployedExecutable then
          Break;
        { Release before Debug, for the same reason the build page prefers it:
          a folder chosen by hand receives whatever a user of the application
          would be given, not a build carrying a symbol table and arithmetic
          checks because it happened to be looked for first. }
        for Configuration in ['Release', 'Debug'] do
        begin
          if DeployedExecutable then
            Break;
          SourceExecutable := TTargetBuildDeployer.FindBuildOutputDirectory(
            FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
            Platform, Configuration, True);
          if SourceExecutable <> '' then
          begin
            lblFooterStatus.Text := TTargetBuildDeployer.DeployBuildOutput(
              FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
              Platform, Configuration, ApplicationDirectory, FKitDirectory,
              chkReplaceDeployedExecutable.IsChecked);
            DeployedExecutable := True;
          end;
        end;
      end;
    end;
    if not DeployedExecutable then
    begin
      if not RunDeploymentScript(ApplicationDirectory) then
        raise Exception.Create('Language-pack deployment failed.');
      if ShouldDeployExecutable then
        lblFooterStatus.Text := 'Language packs deployed to ' +
          TPath.Combine(ApplicationDirectory, 'Localization\Languages') +
          '. No current build output was found for executable deployment.'
      else
        lblFooterStatus.Text := 'Language packs deployed to ' +
          TPath.Combine(ApplicationDirectory, 'Localization\Languages') +
          '. Existing executable left unchanged.';
    end;
  except
    on E: Exception do
      lblFooterStatus.Text := E.Message;
  end;
  btnDeployApplicationFolder.Enabled := True;
end;

end.

