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
    railStep9: TLabel;
    ContentCard: TRectangle;
    WizardTabs: TTabControl;
    tabWelcome: TTabItem;
    tabProject: TTabItem;
    tabDeployment: TTabItem;
    tabLanguages: TTabItem;
    tabProvider: TTabItem;
    tabScan: TTabItem;
    tabComponent: TTabItem;
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
    lblComponentTitle: TLabel;
    lblComponentText: TLabel;
    memComponentInstructions: TMemo;
    btnShowDesignBPL: TButton;
    chkUnderstandManualStep: TCheckBox;
    lblManualConfirmationRequired: TLabel;
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
    lblKitPath: TLabel;
    lblFallbackCommands: TLabel;
    memCommands: TMemo;
    btnCopyCommands: TButton;
    btnRunDeployment: TButton;
    btnOpenKitFolder: TButton;
    btnDeployApplicationFolder: TButton;
    lblWorkflowMode: TLabel;
    cboWorkflowMode: TComboBox;
    lblWorkflowSummary: TLabel;
    lblLocalizationReviewInfo: TLabel;
    btnFinishLocalizationReview: TButton;
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
    procedure btnShowDesignBPLClick(Sender: TObject);
    procedure chkUnderstandManualStepChange(Sender: TObject);
    procedure chkAuthorizeFinalChange(Sender: TObject);
    procedure railStepClick(Sender: TObject);
    procedure btnCopyCommandsClick(Sender: TObject);
    procedure btnRunDeploymentClick(Sender: TObject);
    procedure btnOpenKitFolderClick(Sender: TObject);
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
    FCompleted: Boolean;
    FBuildCompleted: Boolean;
    FBuildInProgress: Boolean;
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    FCatalog: TTranslationCatalog;
    FCatalogFileName: string;
    FKitDirectory: string;
    FBackupFileName: string;
    FProjectConfigurationBackupDirectory: string;
    FSessionApiKey: string;
    FLastScanCompletedAt: TDateTime;
    FReviewOutputDirectory: string;
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
    procedure AddProgress(const AText: string);
    function FindStudioRoot: string;
    function DesignBPLFileName: string;
    procedure BuildDeploymentCommands;
    procedure UpdateComponentInstructions;
    procedure RebuildAllTargetConfigurations;
    function PreferredDeploymentPlatforms: TArray<string>;
    function PreferredDeploymentConfigurations: TArray<string>;
    function ExistingBuildOutputDirectories: TArray<string>;
    function DeployLanguagePacksToExistingOutputs: Integer;
    function DeployLanguagePacksToConfiguredDestinations: Integer;
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
  System.IOUtils,
  System.JSON,
  System.Math,
  System.RegularExpressions,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  System.Zip,
  Winapi.ShellAPI,
  Winapi.Windows,
  FMX.DialogService.Sync,
  FMX.Platform,
  DAT.Core.CatalogJson,
  DAT.Core.Glossary,
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
  StepCount = 9;
  DeploymentProcessTimeout = 120000;
  ProcessTerminationWait = 5000;
  StudioBuildLabel = 'Build 2026.08.17.1046';

procedure TfrmSetupWizard.FormCreate(Sender: TObject);
begin
  Caption := 'Translation Setup Wizard - ' + StudioBuildLabel;
  lblSubtitle.Text := 'A safe, step-by-step path from Delphi project to offline language pack - ' +
    StudioBuildLabel;
  FCurrentStep := 1;
  FHighestStep := 1;
  cboSourceLanguage.ItemIndex := 0;
  cboTargetLanguage.ItemIndex := 36;
  cboProvider.ItemIndex := 0;
  cboDeepLPlan.ItemIndex := 0;
  cboWorkflowMode.ItemIndex := 0;
  chkRememberKey.IsChecked := True;
  chkCreateBackup.IsChecked := True;
  chkCreateBackup.Enabled := False;
  chkTargetProjectClosed.IsChecked := False;
  edtApiKey.Password := True;
  ApplyLocaleDefaults;
  chkBuildNow.IsChecked := False;
  FBuildCompleted := False;
  FBuildInProgress := False;
  chkReplaceDeployedExecutable.IsChecked := False;
  cboBuildPlatform.ItemIndex := 2;
  cboBuildConfiguration.ItemIndex := 2;
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
  Configurations: TArray<string>;
  Platforms: TArray<string>;
  Configuration: string;
  Platform: string;
  ApplicationDirectory: string;
  DestinationAttempt: Integer;
  DestinationReady: Boolean;
begin
  if not FCompleted then
    Exit;
  btnBuildNow.Enabled := False;
  btnBack.Enabled := False;
  btnFinish.Enabled := False;
  btnCancel.Enabled := False;
  FBuildCompleted := False;
  FBuildInProgress := True;
  lblBuildStatus.Text := 'Building selected targets. Please wait...';
  Application.ProcessMessages;
  try
    if cboBuildPlatform.ItemIndex = 0 then
      Platforms := ['Win32']
    else if cboBuildPlatform.ItemIndex = 1 then
      Platforms := ['Win64']
    else
      Platforms := ['Win32', 'Win64'];
    if cboBuildConfiguration.ItemIndex = 0 then
      Configurations := ['Debug']
    else if cboBuildConfiguration.ItemIndex = 1 then
      Configurations := ['Release']
    else
      Configurations := ['Debug', 'Release'];
    for Platform in Platforms do
      for Configuration in Configurations do
      begin
        AddProgress(Format('Building %s %s...', [Platform, Configuration]));
        AddProgress(TTargetBuildDeployer.BuildAndDeploy(
          FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
          Platform, Configuration, FKitDirectory));
        for ApplicationDirectory in lstDeploymentDestinations.Items do
        begin
          DestinationReady := TDirectory.Exists(ApplicationDirectory);
          if not DestinationReady then
            for DestinationAttempt := 1 to 12 do
            begin
              Sleep(500);
              DestinationReady := TDirectory.Exists(ApplicationDirectory);
              if DestinationReady then
                Break;
            end;
          if DestinationReady then
            try
              AddProgress(TTargetBuildDeployer.DeployBuildOutput(
                FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
                Platform, Configuration, ApplicationDirectory, FKitDirectory,
                chkReplaceDeployedExecutable.IsChecked));
            except
              on E: EInOutError do
                AddProgress(Format(
                  'Executable deployment skipped for %s %s in %s: %s',
                  [Platform, Configuration, ApplicationDirectory, E.Message]));
            end
          else
            AddProgress(Format(
              'Destination unavailable after waiting: %s',
              [ApplicationDirectory]));
        end;
      end;
    FBuildCompleted := True;
    lblBuildStatus.Text := 'Build and deployment completed for every selected target.';
  except
    on E: Exception do
    begin
      FBuildCompleted := False;
      lblBuildStatus.Text := 'Build stopped: ' + E.Message;
      AddProgress('BUILD STOPPED: ' + E.Message);
    end;
  end;
  FBuildInProgress := False;
  UpdateBuildChoice;
  UpdateNavigation;
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

procedure TfrmSetupWizard.UpdateComponentInstructions;
var
  ApplicationId: string;
  ManagerClass: string;
  SelectorClass: string;
begin
  ApplicationId := FProjectProfile.ProjectName;
  if FProjectProfile.Framework = tfVCL then
  begin
    ManagerClass := 'TDATVCLLanguageManager';
    SelectorClass := 'TDATVCLLanguageComboBox';
  end
  else
  begin
    ManagerClass := 'TDATFMXLanguageManager';
    SelectorClass := 'TDATFMXLanguageComboBox';
  end;
  memComponentInstructions.Lines.Text :=
    'These instructions were generated for the selected project:' +
      sLineBreak + FProjectProfile.ProjectFileName + sLineBreak +
    'Detected Application ID: "' + ApplicationId + '"' + sLineBreak +
    'Before the Wizard:' + sLineBreak +
    '1. Install the matching DAT design package in RAD Studio.' + sLineBreak +
    '2. Place one ' + ManagerClass + ' and one ' + SelectorClass +
      ' on the primary form, connect the selector to the manager, and Save All.' + sLineBreak +
    '3. Add any supporting Language label or menu and complete its layout.' + sLineBreak +
    'The Wizard verifies and preserves this setup:' + sLineBreak +
    '4. ApplicationId must be "' +
      ApplicationId + '". This value comes from the selected .dproj file. ' +
      'Leave LanguagesFolder as "Localization\Languages".' + sLineBreak +
    '5. Build-output folders and every available application destination ' +
      'entered on the Deployment page receive the current JSON packs ' +
      'automatically.' + sLineBreak +
    'For Wizard-initiated builds, the Wizard passes ComponentSource to MSBuild ' +
      'without editing the target project file. For manual RAD Studio builds, ' +
      'add the generated ComponentSource folder to the project Search Path or ' +
      'use an approved common source location.';
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
        if (Trim(ArrayValue.Value) <> '') and
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
      Destinations.Add(Destination);
    Root.AddPair('destinations', Destinations);
    TFile.WriteAllText(FileName, Root.Format(2), TEncoding.UTF8);
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
  FCatalog.Free;
  FScanResult.Free;
end;

procedure TfrmSetupWizard.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not FFinalProcessing;
end;

procedure TfrmSetupWizard.btnCancelClick(Sender: TObject);
begin
  if FFinalProcessing then
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
    Result := tpDeepL
  else
    Result := tpGoogle;
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
  if FCurrentStep = 8 then
    BuildReview;
  UpdateRail;
  UpdateNavigation;
end;

procedure TfrmSetupWizard.UpdateNavigation;
begin
  btnBack.Enabled := (FCurrentStep > 1) and not FFinalProcessing;
  btnCancel.Enabled := not FFinalProcessing;
  btnNext.Visible := FCurrentStep < StepCount;
  btnFinish.Visible := FCurrentStep = StepCount;
  btnFinish.Enabled := FCompleted and
    not FFinalProcessing and
    not FBuildInProgress and
    ((not chkBuildNow.IsChecked) or FBuildCompleted);
  if FCurrentStep = 8 then
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
  if FCurrentStep = 8 then
  begin
    FHighestStep := 9;
    SetStep(9);
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
      ;
    8:
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
    UpdateComponentInstructions;
    UpdateWorkflowSummary;
    UpdateRail;
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
  Client: TTranslationProviderClient;
  Plan: TDeepLPlan;
begin
  btnTestConnection.Enabled := False;
  try
    if cboDeepLPlan.ItemIndex = 1 then
      Plan := dpPro
    else
      Plan := dpFree;
    Client := TTranslationProviderClient.Create(SelectedProvider, Plan,
      EffectiveApiKey, 30, 40);
    try
      Client.TestConnection;
      lblProviderStatus.Text := 'Connection test passed.';
    finally
      Client.Free;
    end;
  except
    on E: Exception do
      lblProviderStatus.Text := 'Connection test failed: ' + E.Message;
  end;
  btnTestConnection.Enabled := True;
end;

procedure TfrmSetupWizard.LoadExistingCatalog;
var
  ExistingFileName: string;
  LanguageCode: string;
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
    if StartsText('ar-', LanguageCode) or StartsText('fa-', LanguageCode) or
       StartsText('he-', LanguageCode) or StartsText('ur-', LanguageCode) then
      FCatalog.Locale.TextDirection := 'rtl'
    else
      FCatalog.Locale.TextDirection := 'ltr';
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
  Item: TScanItem;
  MergeSummary: TCatalogMergeSummary;
begin
  btnRunScan.Enabled := False;
  try
    FreeAndNil(FScanResult);
    FScanResult := TProjectScanner.Scan(FProjectProfile);
    FLastScanCompletedAt := Now;
    LoadExistingCatalog;
    MergeSummary := TScanCatalogMerger.Merge(FScanResult, FCatalog);
    memScanResults.Lines.BeginUpdate;
    try
      memScanResults.Lines.Clear;
      for Item in FScanResult.Items do
        memScanResults.Lines.Add(Item.Key + ' = ' + Item.SourceText);
    finally
      memScanResults.Lines.EndUpdate;
    end;
    if cboWorkflowMode.ItemIndex = 2 then
      lblScanSummary.Text := Format(
        '%d translatable entries  |  %d new  |  %d changed  |  %d unchanged  |  %d obsolete',
        [FScanResult.Items.Count, MergeSummary.NewEntries,
         MergeSummary.ChangedEntries, MergeSummary.UnchangedEntries,
         MergeSummary.ObsoleteEntries])
    else
      lblScanSummary.Text := Format(
        '%d current translatable entries  |  new catalog  |  %d duplicate scan key(s) ignored',
        [FScanResult.Items.Count, MergeSummary.DuplicateScanKeys]);
    FReviewOutputDirectory := TPath.Combine(FindStudioRoot,
      TPath.Combine('export\localization-review',
        TPath.Combine(FProjectProfile.ProjectName,
          SelectedLanguageCode(cboTargetLanguage))));
    UpdateWorkflowSummary;
    lblFooterStatus.Text :=
      'Scan complete. Continue through Review & Authorize; automatic translation and Localization Review occur during final processing.';
  except
    on E: Exception do
      lblFooterStatus.Text := 'Scan failed: ' + E.Message;
  end;
  btnRunScan.Enabled := True;
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

function TfrmSetupWizard.DesignBPLFileName: string;
var
  PackageName: string;
begin
  if FProjectProfile.Framework = tfVCL then
    PackageName := 'DATLanguageManagerVCLDesign.bpl'
  else
    PackageName := 'DATLanguageManagerFMXDesign.bpl';
  Result := TPath.Combine(FindStudioRoot,
    TPath.Combine('bin\packages\Win32\Release', PackageName));
end;

procedure TfrmSetupWizard.btnShowDesignBPLClick(Sender: TObject);
var
  BPLName: string;
begin
  try
    BPLName := DesignBPLFileName;
    if not TFile.Exists(BPLName) then
      raise Exception.Create('The verified design BPL has not been built yet.');
    if ShellExecute(0, 'open', 'explorer.exe',
      PChar('/select,"' + BPLName + '"'), nil, SW_SHOWNORMAL) <= 32 then
      raise Exception.Create('Windows could not open the package folder.');
    lblFooterStatus.Text := 'The exact design BPL is selected in File Explorer.';
  except
    on E: Exception do
      lblFooterStatus.Text := E.Message;
  end;
end;

procedure TfrmSetupWizard.chkUnderstandManualStepChange(Sender: TObject);
begin
  if chkUnderstandManualStep.IsChecked then
  begin
    chkUnderstandManualStep.TextSettings.FontColor := $FF245587;
    lblManualConfirmationRequired.Text :=
      'Confirmed. Click Next to review and authorize final processing.';
    lblManualConfirmationRequired.TextSettings.FontColor := $FF245587;
  end
  else
  begin
    chkUnderstandManualStep.TextSettings.FontColor := $FFB25400;
    lblManualConfirmationRequired.Text :=
      'Required before continuing: check the confirmation box above.';
    lblManualConfirmationRequired.TextSettings.FontColor := $FFB25400;
  end;
  UpdateNavigation;
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
begin
  memProgress.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
  memProgress.GoToTextEnd;
  Application.ProcessMessages;
end;

procedure TfrmSetupWizard.BuildDeploymentCommands;
const
  Configurations: array[0..1] of string = ('Debug', 'Release');
  Platforms: array[0..1] of string = ('Win32', 'Win64');
var
  Configuration: string;
  OutputDirectory: string;
  Platform: string;
  ScriptName: string;
  UniqueDirectories: TStringList;
begin
  memCommands.Lines.Clear;
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
      memCommands.Lines.Add(Format(
        '& "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%s" -ApplicationDirectory "%s"',
        [ScriptName, OutputDirectory]));
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

function TfrmSetupWizard.PreferredDeploymentPlatforms: TArray<string>;
begin
  if cboBuildPlatform.ItemIndex = 1 then
    Result := ['Win64', 'Win32']
  else
    Result := ['Win32', 'Win64'];
end;

function TfrmSetupWizard.PreferredDeploymentConfigurations: TArray<string>;
begin
  if cboBuildConfiguration.ItemIndex = 1 then
    Result := ['Release', 'Debug']
  else
    Result := ['Debug', 'Release'];
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
      OutputDirectory := TTargetBuildDeployer.FindBuildOutputDirectory(
        FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
        Platform, Configuration, False);
      if (OutputDirectory = '') or not TDirectory.Exists(OutputDirectory) then
        Continue;
      AddProgress(Format('Rebuilding %s %s before deployment...',
        [Platform, Configuration]));
      Application.ProcessMessages;
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

function TfrmSetupWizard.DeployLanguagePacksToConfiguredDestinations: Integer;
var
  ApplicationDirectory: string;
  Configuration: string;
  DestinationExecutable: string;
  ExecutableDeployed: Boolean;
  ShouldDeployExecutable: Boolean;
  Platform: string;
  SourceExecutable: string;
begin
  Result := 0;
  for ApplicationDirectory in lstDeploymentDestinations.Items do
  begin
    if not DeployLanguagePacksDirect(ApplicationDirectory) then
      raise Exception.Create('Language-pack deployment failed for configured destination ' +
        ApplicationDirectory + '. The drive may still be waking or may be read-only.');
    DestinationExecutable := TPath.Combine(ApplicationDirectory,
      FProjectProfile.ProjectName + '.exe');
    ShouldDeployExecutable := chkReplaceDeployedExecutable.IsChecked or
      not TFile.Exists(DestinationExecutable);
    if ShouldDeployExecutable then
    begin
      ExecutableDeployed := False;
      { Honour the platform and configuration chosen on the build page first so
        the destination receives the executable the developer asked for, not
        whichever output folder happens to come first alphabetically. }
      for Platform in PreferredDeploymentPlatforms do
      begin
        if ExecutableDeployed then
          Break;
        for Configuration in PreferredDeploymentConfigurations do
        begin
          if ExecutableDeployed then
            Break;
          SourceExecutable := TTargetBuildDeployer.FindBuildOutputDirectory(
            FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
            Platform, Configuration, True);
          if SourceExecutable <> '' then
          begin
            AddProgress(Format('Deploying the %s %s executable to %s.',
              [Platform, Configuration, ApplicationDirectory]));
            AddProgress(TTargetBuildDeployer.DeployBuildOutput(
              FProjectProfile.ProjectFileName, FProjectProfile.ProjectName,
              Platform, Configuration, ApplicationDirectory, FKitDirectory,
              chkReplaceDeployedExecutable.IsChecked));
            ExecutableDeployed := True;
          end;
        end;
      end;
      if not ExecutableDeployed then
        AddProgress('Executable not copied to ' + ApplicationDirectory +
          ': no current build output was found. Use Build and Deploy Selected Targets after final processing.');
    end
    else
      AddProgress('Executable left unchanged at ' + DestinationExecutable +
        ' (replace/create authorization was not selected).');
    Inc(Result);
    AddProgress('Language packs deployed to configured destination ' +
      ApplicationDirectory);
  end;
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
  ApiKey: string;
  BackupDirectory: string;
  Client: TTranslationProviderClient;
  Entry: TTranslationEntry;
  ScanItem: TScanItem;
  EntryIndexes: TArray<Integer>;
  Index: Integer;
  MissingCount: Integer;
  Plan: TDeepLPlan;
  Provider: TTranslationProvider;
  Report: TStringList;
  DeployedCount: Integer;
  ConfiguredDestinationCount: Integer;
  RuntimePackFileName: string;
  SourceTexts: TArray<string>;
  TranslatedTexts: TArray<string>;
  Contexts: TArray<string>;
  ProviderCount: Integer;
  ResolvedText: string;
  Validation: TCatalogValidationResult;
  Glossary: TProjectGlossary;
  AppliedGlossaryCount: Integer;
  ProjectGlossaryFileName: string;
begin
  FFinalProcessing := True;
  FCompleted := False;
  FBuildCompleted := False;
  btnBack.Enabled := False;
  btnCancel.Enabled := False;
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
    TDirectory.CreateDirectory(BackupDirectory);
    FBackupFileName := TPath.Combine(BackupDirectory,
      FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.zip');
    TZipFile.ZipDirectoryContents(FBackupFileName,
      TPath.GetDirectoryName(FProjectProfile.ProjectFileName));
    AddProgress('Backup created: ' + FBackupFileName);
    AddProgress('Target Pascal and form source files remain unchanged.');

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
      if Glossary <> nil then
      begin
        AppliedGlossaryCount := Glossary.ApplyToCatalog(FCatalog);
        Glossary.SaveToFile(ProjectGlossaryFileName);
        AddProgress(Format('%d translation(s) applied from the approved project glossary.',
          [AppliedGlossaryCount]));
      end;
    finally
      Glossary.Free;
    end;
    TTerminologyResolver.ApplyAuthoritativeTerms(FCatalog);
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
      Client := TTranslationProviderClient.Create(Provider, Plan, ApiKey, 30, 40);
      try
        TranslatedTexts := Client.TranslateWithContexts(SourceTexts, Contexts,
          FCatalog.SourceLanguage, FCatalog.Locale.LanguageCode,
          nil,
          procedure(const ACompleted, ATotal: Integer)
          begin
            lblFinishText.Text := Format('Automatic translation: %d of %d',
              [ACompleted, ATotal]);
            Application.ProcessMessages;
          end);
      finally
        Client.Free;
      end;
      for Index := 0 to High(TranslatedTexts) do
      begin
        Entry := FCatalog.Entries[EntryIndexes[Index]];
        Entry.TranslatedText := TranslatedTexts[Index];
        Entry.Status := tsMachineTranslated;
        if Provider = tpGoogle then
          Entry.TranslationOrigin := torGoogle
        else
          Entry.TranslationOrigin := torDeepL;
        if Provider = tpGoogle then
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
      AddProgress(Format('%d translations recorded.', [Length(TranslatedTexts)]));
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
      else if TFile.Exists(ProjectGlossaryFileName) then
        Glossary := TProjectGlossary.LoadFromFile(ProjectGlossaryFileName);
      if Glossary <> nil then
      begin
        AppliedGlossaryCount := Glossary.ApplyToCatalog(FCatalog);
        Glossary.SaveToFile(ProjectGlossaryFileName);
        AddProgress(Format('%d translation(s) applied from the completed in-Wizard review.',
          [AppliedGlossaryCount]));
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
    RebuildAllTargetConfigurations;
    DeployedCount := DeployLanguagePacksToExistingOutputs;
    if DeployedCount = 0 then
      AddProgress('No existing build-output folders were found. The next build will deploy the packs automatically.')
    else
      AddProgress(Format('Automatic deployment completed for %d existing build output(s).',
        [DeployedCount]));
    ConfiguredDestinationCount :=
      DeployLanguagePacksToConfiguredDestinations;
    if lstDeploymentDestinations.Items.Count = 0 then
      AddProgress('No separate application destinations were configured.')
    else
      AddProgress(Format(
        'Automatic deployment completed for %d of %d configured application destination(s).',
        [ConfiguredDestinationCount,
         lstDeploymentDestinations.Items.Count]));
    FProjectConfigurationBackupDirectory := '';
    AddProgress('Target project source and project files were not modified.');
    lblKitPath.Text := FKitDirectory;
    lblKitPath.Hint := 'Click to open the generated component kit folder.';
    Report := TStringList.Create;
    try
      Report.Add('DELPHI APP TRANSLATION - SETUP WIZARD COMPLETION REPORT');
      Report.Add('Created: ' + DateTimeToStr(Now));
      Report.Add('Project: ' + FProjectProfile.ProjectFileName);
      Report.Add('Language: ' + FCatalog.Locale.NativeLanguageName + ' (' +
        FCatalog.Locale.LanguageCode + ')');
      Report.Add('Workflow: ' + EffectiveWorkflowName);
      Report.Add('Development catalog: ' + FCatalogFileName);
      Report.Add('Runtime pack: ' + RuntimePackFileName);
      Report.Add('Component kit: ' + FKitDirectory);
      Report.Add('Backup: ' + FBackupFileName);
      Report.Add('DPROJ transaction backup: not created; target project file was not modified');
      Report.Add('Application ID: ' + FProjectProfile.ProjectName);
      Report.Add('ComponentSource Search Path: ' +
        TPath.Combine(FKitDirectory, 'ComponentSource'));
      Report.Add('Existing build outputs deployed: ' + DeployedCount.ToString);
      Report.Add('Configured application destinations: ' +
        lstDeploymentDestinations.Items.Count.ToString);
      Report.Add('Available configured destinations deployed: ' +
        ConfiguredDestinationCount.ToString);
      Report.Add('Localization review package: ' +
        TPath.Combine(FReviewOutputDirectory, 'localization-review.html'));
      Report.Add('Review workflow: completed inside the same Wizard processing pass before final export');
      Report.Add('');
      Report.Add('NEXT MANUAL DELPHI STEP');
      Report.AddStrings(memComponentInstructions.Lines);
      Report.Add('');
      Report.Add('DEPLOYMENT COMMANDS');
      Report.AddStrings(memCommands.Lines);
      Report.Add('');
      Report.Add('WIZARD PROGRESS AND DEPLOYMENT LOG');
      Report.AddStrings(memProgress.Lines);
      Report.SaveToFile(TPath.Combine(FKitDirectory,
        'Wizard-Completion-Report.txt'), TEncoding.UTF8);
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
end;

procedure TfrmSetupWizard.btnCopyCommandsClick(Sender: TObject);
var
  Clipboard: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(
    IFMXClipboardService, Clipboard) then
  begin
    Clipboard.SetClipboard(TValue.From<string>(memCommands.Text));
    lblFooterStatus.Text := 'All deployment commands copied to the clipboard.';
  end;
end;

procedure TfrmSetupWizard.btnOpenKitFolderClick(Sender: TObject);
begin
  if (FKitDirectory <> '') and TDirectory.Exists(FKitDirectory) then
    ShellExecute(0, 'open', PChar(FKitDirectory), nil, nil, SW_SHOWNORMAL);
end;

function TfrmSetupWizard.RunDeploymentScript(
  const AApplicationDirectory: string;
  const ASkipConfiguredDestinations: Boolean): Boolean;
var
  ExitCode: Cardinal;
  Parameters: string;
  ShellInfo: TShellExecuteInfo;
  WaitResult: Cardinal;
begin
  Result := False;
  FillChar(ShellInfo, SizeOf(ShellInfo), 0);
  ShellInfo.cbSize := SizeOf(ShellInfo);
  ShellInfo.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
  ShellInfo.Wnd := 0;
  ShellInfo.lpVerb := 'open';
  ShellInfo.lpFile :=
    'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
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

procedure TfrmSetupWizard.btnRunDeploymentClick(Sender: TObject);
var
  DeployedCount: Integer;
begin
  btnRunDeployment.Enabled := False;
  try
    DeployedCount := DeployLanguagePacksToExistingOutputs;
    if DeployedCount = 0 then
      lblFooterStatus.Text :=
        'No built target folders were found. Build the target, then run deployment again.'
    else
      lblFooterStatus.Text := Format(
        'Language packs deployed to %d existing build folder(s).',
        [DeployedCount]);
  except
    on E: Exception do
      lblFooterStatus.Text := E.Message;
  end;
  btnRunDeployment.Enabled := True;
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
        for Configuration in ['Debug', 'Release'] do
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

