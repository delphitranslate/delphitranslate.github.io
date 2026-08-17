unit DAT.Studio.MainForm;

interface

uses
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Edit,
  FMX.Memo,
  FMX.Dialogs,
  FMX.Menus,
  DAT.Core.Types,
  DAT.Provider.Settings,
  DAT.Provider.Types,
  DAT.Scan.Types,
  DAT.Validation.Catalog, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Controls.Presentation;

type
  TfrmTranslationStudio = class(TForm)
    MainMenuBar: TMenuBar;
    mnuLanguage: TMenuItem;
    datLanguage_en_US: TMenuItem;
    RootLayout: TLayout;
    HeaderBackground: TRectangle;
    HeaderAccent: TRectangle;
    lblApplicationTitle: TLabel;
    lblApplicationSubtitle: TLabel;
    BodyLayout: TLayout;
    NavigationCard: TRectangle;
    lblNavigationTitle: TLabel;
    NavigationSelection: TRectangle;
    lblNavigationProject: TLabel;
    lblNavigationScan: TLabel;
    lblNavigationLanguages: TLabel;
    lblNavigationValidation: TLabel;
    lblNavigationExport: TLabel;
    lblNavigationIntegration: TLabel;
    lblNavigationSettings: TLabel;
    ContentLayout: TLayout;
    IntroCard: TRectangle;
    lblIntroTitle: TLabel;
    lblIntroText: TLabel;
    btnIntroRunWizard: TButton;
    btnIntroMaintenance: TButton;
    btnIntroClose: TButton;
    ProjectCard: TRectangle;
    lblProjectCardTitle: TLabel;
    lblProjectCardDescription: TLabel;
    btnGuidedSetup: TButton;
    btnOpenProject: TButton;
    ProjectDetailsCard: TRectangle;
    lblProjectNameCaption: TLabel;
    lblProjectNameValue: TLabel;
    lblFrameworkCaption: TLabel;
    lblFrameworkValue: TLabel;
    lblPlatformsCaption: TLabel;
    lblPlatformsValue: TLabel;
    lblFormsCaption: TLabel;
    lblFormsValue: TLabel;
    lblSourcesCaption: TLabel;
    lblSourcesValue: TLabel;
    DetailsDivider: TRectangle;
    btnScanProject: TButton;
    lblScanSummaryTitle: TLabel;
    lblScanSummaryValue: TLabel;
    lblScanBreakdown: TLabel;
    lstScanResults: TListBox;
    StatusCard: TRectangle;
    StatusAccent: TRectangle;
    lblStatus: TLabel;
    LanguagePageCard: TRectangle;
    lblLanguagePageTitle: TLabel;
    lblSourceLanguage: TLabel;
    cboSourceLanguage: TComboBox;
    lblTargetLanguageCode: TLabel;
    cboTargetLanguage: TComboBox;
    lblNativeLanguageName: TLabel;
    edtNativeLanguageName: TEdit;
    lblTextDirection: TLabel;
    cboTextDirection: TComboBox;
    btnOpenCatalog: TButton;
    btnSaveCatalog: TButton;
    edtShortDateFormat: TEdit;
    edtLongDateFormat: TEdit;
    edtShortTimeFormat: TEdit;
    edtLongTimeFormat: TEdit;
    edtDecimalSeparator: TEdit;
    edtThousandSeparator: TEdit;
    edtCurrencySymbol: TEdit;
    lblCatalogPathValue: TLabel;
    btnExportCatalogCsv: TButton;
    btnImportCatalogCsv: TButton;
    lblCatalogReadiness: TLabel;
    lstCatalogEntries: TListBox;
    btnMarkTranslationReviewed: TButton;
    btnApproveTranslation: TButton;
    btnReviewAllTranslations: TButton;
    btnApproveAllReviewed: TButton;
    lblSourceTextEditor: TLabel;
    lblRuntimeApplicationValue: TLabel;
    lblTranslationContextValue: TLabel;
    memSourceText: TMemo;
    chkRuntimeWiringConfirmed: TCheckBox;
    lblTranslationSuggestion: TLabel;
    cboTranslationSuggestions: TComboBox;
    btnAcceptSuggestion: TButton;
    lblTranslatedTextEditor: TLabel;
    memTranslatedText: TMemo;
    btnApplyTranslation: TButton;
    btnTranslateMissing: TButton;
    ValidationPageCard: TRectangle;
    lblValidationPageTitle: TLabel;
    lblValidationDescription: TLabel;
    btnValidateCatalog: TButton;
    lblValidationSummary: TLabel;
    lstValidationIssues: TListBox;
    ExportPageCard: TRectangle;
    lblExportPageTitle: TLabel;
    lblExportDescription: TLabel;
    ExportAccentCard: TRectangle;
    lblExportSummary: TLabel;
    lblExportPathValue: TLabel;
    btnExportRuntimePack: TButton;
    IntegrationPageCard: TRectangle;
    lblIntegrationPageTitle: TLabel;
    lblIntegrationDescription: TLabel;
    lblIntegrationMode: TLabel;
    cboIntegrationMode: TComboBox;
    lblLanguageMenuName: TLabel;
    edtLanguageMenuName: TEdit;
    btnBuildIntegrationPlan: TButton;
    lstIntegrationPlan: TListBox;
    lblIntegrationDiffTitle: TLabel;
    memIntegrationDiff: TMemo;
    chkIntegrationReviewConfirmed: TCheckBox;
    lblIntegrationSummary: TLabel;
    btnGenerateIntegrationPackage: TButton;
    lblIntegrationOutput: TLabel;
    btnApplyIntegration: TButton;
    btnRestoreIntegration: TButton;
    btnCompleteReset: TButton;
    btnOpenDesignPackageLocation: TButton;
    btnOpenComponentKitFolder: TButton;
    chkBuildAfterIntegration: TCheckBox;
    cboBuildPlatform: TComboBox;
    cboBuildConfiguration: TComboBox;
    SettingsPageCard: TRectangle;
    lblSettingsPageTitle: TLabel;
    lblSettingsDescription: TLabel;
    lblProviderName: TLabel;
    cboTranslationProvider: TComboBox;
    lblDeepLPlan: TLabel;
    cboDeepLPlan: TComboBox;
    lblProviderApiKey: TLabel;
    edtProviderApiKey: TEdit;
    chkRememberCredential: TCheckBox;
    lblCredentialExplanation: TLabel;
    btnSaveProviderKey: TButton;
    btnTestProviderConnection: TButton;
    btnRemoveProviderKey: TButton;
    lblCredentialStatus: TLabel;
    lblRequestTimeout: TLabel;
    edtRequestTimeout: TEdit;
    lblBatchSize: TLabel;
    edtProviderBatchSize: TEdit;
    dlgOpenProject: TOpenDialog;
    dlgOpenCatalog: TOpenDialog;
    dlgImportCatalogCsv: TOpenDialog;
    dlgExportCatalogCsv: TSaveDialog;
    rectWizardBackdrop: TRectangle;
    procedure btnOpenProjectClick(Sender: TObject);
    procedure btnGuidedSetupClick(Sender: TObject);
    procedure btnIntroMaintenanceClick(Sender: TObject);
    procedure btnIntroCloseClick(Sender: TObject);
    procedure btnScanProjectClick(Sender: TObject);
    procedure lblNavigationProjectClick(Sender: TObject);
    procedure lblNavigationScanClick(Sender: TObject);
    procedure lblNavigationLanguagesClick(Sender: TObject);
    procedure lblNavigationValidationClick(Sender: TObject);
    procedure lblNavigationExportClick(Sender: TObject);
    procedure btnOpenCatalogClick(Sender: TObject);
    procedure btnSaveCatalogClick(Sender: TObject);
    procedure lstCatalogEntriesChange(Sender: TObject);
    procedure btnApplyTranslationClick(Sender: TObject);
    procedure btnValidateCatalogClick(Sender: TObject);
    procedure btnExportRuntimePackClick(Sender: TObject);
    procedure lblNavigationIntegrationClick(Sender: TObject);
    procedure btnBuildIntegrationPlanClick(Sender: TObject);
    procedure btnGenerateIntegrationPackageClick(Sender: TObject);
    procedure btnApplyIntegrationClick(Sender: TObject);
    procedure btnRestoreIntegrationClick(Sender: TObject);
    procedure btnCompleteResetClick(Sender: TObject);
    procedure lstIntegrationPlanChange(Sender: TObject);
    procedure chkIntegrationReviewConfirmedChange(Sender: TObject);
    procedure cboIntegrationModeChange(Sender: TObject);
    procedure lblNavigationSettingsClick(Sender: TObject);
    procedure cboTranslationProviderChange(Sender: TObject);
    procedure btnSaveProviderKeyClick(Sender: TObject);
    procedure btnTestProviderConnectionClick(Sender: TObject);
    procedure btnRemoveProviderKeyClick(Sender: TObject);
    procedure btnTranslateMissingClick(Sender: TObject);
    procedure btnExportCatalogCsvClick(Sender: TObject);
    procedure btnImportCatalogCsvClick(Sender: TObject);
    procedure chkRuntimeWiringConfirmedChange(Sender: TObject);
    procedure btnAcceptSuggestionClick(Sender: TObject);
    procedure btnMarkTranslationReviewedClick(Sender: TObject);
    procedure btnApproveTranslationClick(Sender: TObject);
    procedure btnReviewAllTranslationsClick(Sender: TObject);
    procedure btnApproveAllReviewedClick(Sender: TObject);
    procedure lblCatalogPathValueClick(Sender: TObject);
    procedure lblExportPathValueClick(Sender: TObject);
    procedure lstValidationIssuesDblClick(Sender: TObject);
    procedure btnOpenDesignPackageLocationClick(Sender: TObject);
    procedure btnOpenComponentKitFolderClick(Sender: TObject);
    procedure cboTargetLanguageChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure datLanguageMenuItemClick(Sender: TObject);
  private
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    FTranslationCatalog: TTranslationCatalog;
    FValidationResult: TCatalogValidationResult;
    FIntegrationPackageDirectory: string;
    FLastIntegrationBackupDirectory: string;
    FCatalogFileName: string;
    FProviderSettings: TProviderSettings;
    FSessionApiKeys: array[TTranslationProvider] of string;
    FUpdatingEntryControls: Boolean;
    FIntroScreen: Boolean;
    FLastScanCompletedAt: TDateTime;
    procedure ClearProjectSummary;
    procedure ClearScanSummary;
    procedure ResetCatalog;
    procedure DisplayProjectSummary(const AProfile: TProjectProfile);
    procedure DisplayScanResult(const AResult: TProjectScanResult);
    procedure DisplayCatalogEntries;
    procedure DisplayCatalogLanguage;
    procedure DisplayValidationResult;
    procedure InvalidateValidation;
    procedure SetWorkflowStep(const AStep: Integer);
    procedure UpdateCatalogFromLanguageEditors;
    procedure SaveCatalog;
    procedure RunCatalogValidation;
    function SelectedProvider: TTranslationProvider;
    function EffectiveApiKey(
      const AProvider: TTranslationProvider): string;
    procedure LoadProviderSettings;
    procedure SaveProviderSettings;
    procedure UpdateCredentialStatus;
    procedure UpdateCatalogReadiness;
    procedure UpdateTranslationSuggestions(
      const AEntry: TTranslationEntry);
    procedure DisplaySelectedIntegrationChange;
    procedure UpdateIntegrationApplyState;
    procedure UpdateIntegrationModeUI;
    function IsComponentIntegrationMode: Boolean;
    function SelectedLanguageCode(AComboBox: TComboBox): string;
    procedure SelectLanguageCode(AComboBox: TComboBox;
      const ALanguageCode: string);
    procedure ApplyTargetLanguageDefaults;
  public
    destructor Destroy; override;
  end;

var
  frmTranslationStudio: TfrmTranslationStudio;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.Math,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  Winapi.ShellAPI,
  Winapi.Windows,
  FMX.DialogService.Sync,
  DAT.Core.CatalogJson,
  DAT.Core.ProjectDetection,
  DAT.Core.RuntimePack,
  DAT.Core.Terminology,
  DAT.Core.TranslationWorkspace,
  DAT.Integration.Package,
  DAT.Integration.BuildDeploy,
  DAT.Integration.ComponentPackage,
  DAT.Provider.Client,
  DAT.Provider.CredentialStore,
  DAT.Runtime.LanguagePack,
  DAT.Studio.SetupWizard,
  DAT.Studio.Translation,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project;

{$R *.fmx}

const
  StudioBuildLabel = 'Build 2026.08.17.1145';

procedure TfrmTranslationStudio.btnGuidedSetupClick(Sender: TObject);
var
  SetupWizard: TfrmSetupWizard;
  WizardResult: TModalResult;
begin
  rectWizardBackdrop.Visible := True;
  rectWizardBackdrop.BringToFront;
  rectWizardBackdrop.Repaint;
  Application.ProcessMessages;
  SetupWizard := TfrmSetupWizard.Create(Self);
  try
    WizardResult := SetupWizard.ShowModal;
  finally
    SetupWizard.Free;
    rectWizardBackdrop.Visible := False;
  end;
  if WizardResult = mrCancel then
  begin
    FIntroScreen := True;
    lblStatus.Text := 'Setup Wizard canceled. Choose a workflow to continue.';
  end
  else
  begin
    FIntroScreen := False;
    lblStatus.Text :=
      'Setup Wizard closed. Advanced Studio pages remain available.';
  end;
  SetWorkflowStep(1);
end;

procedure TfrmTranslationStudio.FormCreate(Sender: TObject);
var
  BaseCaption: string;
  BaseSubtitle: string;
begin
  FIntroScreen := True;
  ApplyStudioTranslation(Self);
  BaseCaption := Trim(Caption);
  if BaseCaption = '' then
    BaseCaption := 'Delphi App Translation Studio';
  Caption := BaseCaption + ' - ' + StudioBuildLabel;
  BaseSubtitle := Trim(lblApplicationSubtitle.Text);
  if BaseSubtitle = '' then
    BaseSubtitle :=
      'Offline language packs for Delphi VCL and FireMonkey applications';
  lblApplicationSubtitle.Text := BaseSubtitle + ' - ' + StudioBuildLabel;
  SelectLanguageCode(cboSourceLanguage, 'en-US');
  cboTextDirection.ItemIndex := 0;
  cboBuildPlatform.ItemIndex := 0;
  cboBuildConfiguration.ItemIndex := 0;
  cboIntegrationMode.ItemIndex := 0;
  UpdateIntegrationModeUI;
  LoadProviderSettings;
  SetWorkflowStep(1);
end;

procedure TfrmTranslationStudio.btnIntroMaintenanceClick(Sender: TObject);
begin
  FIntroScreen := False;
  lblStatus.Text :=
    'Maintenance Studio selected. Open a project to continue.';
  SetWorkflowStep(1);
end;

procedure TfrmTranslationStudio.btnIntroCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmTranslationStudio.IsComponentIntegrationMode: Boolean;
begin
  Result := True;
end;

procedure TfrmTranslationStudio.UpdateIntegrationModeUI;
begin
  lblLanguageMenuName.Enabled := False;
  edtLanguageMenuName.Enabled := False;
  chkBuildAfterIntegration.Visible := False;
  cboBuildPlatform.Visible := False;
  cboBuildConfiguration.Visible := False;
  chkIntegrationReviewConfirmed.Visible := False;
  btnApplyIntegration.Visible := False;
  btnRestoreIntegration.Visible := False;
  btnCompleteReset.Visible := False;
  btnOpenDesignPackageLocation.Visible := True;
  btnOpenComponentKitFolder.Visible := True;
  btnOpenDesignPackageLocation.Enabled := False;
  btnOpenComponentKitFolder.Enabled := False;
  btnGenerateIntegrationPackage.Text := 'Generate Component Kit';
  lblIntegrationDescription.Text :=
    'Recommended: generate a component setup kit without modifying any ' +
    'target project or source file.';
  lblIntegrationDiffTitle.Text := 'Setup instructions and generated files';
  chkIntegrationReviewConfirmed.IsChecked := False;
  btnApplyIntegration.Enabled := False;
  btnRestoreIntegration.Enabled := False;
  lstIntegrationPlan.Items.Clear;
  memIntegrationDiff.Text := 'Build the integration plan to begin.';
  btnGenerateIntegrationPackage.Enabled := False;
  if FProjectProfile.ProjectFileName <> '' then
    btnBuildIntegrationPlan.Enabled :=
      FProjectProfile.Framework <> tfUnknown;
end;

procedure TfrmTranslationStudio.cboIntegrationModeChange(Sender: TObject);
begin
  UpdateIntegrationModeUI;
  lblStatus.Text :=
    'Component Integration selected. Target source will not be modified.';
end;

procedure TfrmTranslationStudio.datLanguageMenuItemClick(Sender: TObject);
begin
  if SelectStudioLanguageMenuItem(TComponent(Sender).Name) then
    lblStatus.Text :=
      'Language preference saved. Restart the Studio to apply it.'
  else
    lblStatus.Text := 'Unable to select the requested language.';
end;

procedure TfrmTranslationStudio.ClearProjectSummary;
begin
  FProjectProfile := Default(TProjectProfile);
  lblProjectNameValue.Text := 'No project selected';
  lblFrameworkValue.Text := '-';
  lblPlatformsValue.Text := '-';
  lblFormsValue.Text := '-';
  lblSourcesValue.Text := '-';
  btnScanProject.Enabled := False;
  btnBuildIntegrationPlan.Enabled := False;
  btnGenerateIntegrationPackage.Enabled := False;
  btnApplyIntegration.Enabled := False;
  btnRestoreIntegration.Enabled := False;
  btnCompleteReset.Enabled := False;
  FIntegrationPackageDirectory := '';
  FLastIntegrationBackupDirectory := '';
  lstIntegrationPlan.Items.Clear;
  memIntegrationDiff.Text :=
    'Generate a preview, then optionally select any file to inspect its exact text.';
  chkIntegrationReviewConfirmed.IsChecked := False;
  chkIntegrationReviewConfirmed.Enabled := False;
  chkIntegrationReviewConfirmed.Text :=
    'I authorize the backed-up, transactional integration changes';
  btnApplyIntegration.Text := 'Apply';
  lblIntegrationSummary.Text := 'Open a Delphi project to build a plan.';
  lblIntegrationOutput.Text := 'Generated package path will appear here.';
  ClearScanSummary;
  ResetCatalog;
  SetWorkflowStep(1);
end;

procedure TfrmTranslationStudio.ClearScanSummary;
begin
  FreeAndNil(FScanResult);
  FLastScanCompletedAt := 0;
  lblScanSummaryValue.Text := 'No scan has been run';
  lblScanBreakdown.Text :=
    'Open a project, then scan its forms and resourcestrings.';
  lstScanResults.Items.Clear;
end;

destructor TfrmTranslationStudio.Destroy;
begin
  FProviderSettings.Free;
  FValidationResult.Free;
  FTranslationCatalog.Free;
  FScanResult.Free;
  inherited Destroy;
end;

function TfrmTranslationStudio.SelectedLanguageCode(
  AComboBox: TComboBox): string;
var
  ClosingBracket: Integer;
  DisplayText: string;
  OpeningBracket: Integer;
begin
  Result := '';
  if (AComboBox = nil) or (AComboBox.ItemIndex < 0) then
    Exit;
  DisplayText := AComboBox.Items[AComboBox.ItemIndex];
  OpeningBracket := DisplayText.LastIndexOf('[');
  ClosingBracket := DisplayText.LastIndexOf(']');
  if (OpeningBracket >= 0) and (ClosingBracket > OpeningBracket) then
    Result := Copy(DisplayText, OpeningBracket + 2,
      ClosingBracket - OpeningBracket - 1);
end;

procedure TfrmTranslationStudio.SelectLanguageCode(AComboBox: TComboBox;
  const ALanguageCode: string);
var
  ClosingBracket: Integer;
  CodeText: string;
  Index: Integer;
  OpeningBracket: Integer;
begin
  AComboBox.ItemIndex := -1;
  for Index := 0 to AComboBox.Items.Count - 1 do
  begin
    OpeningBracket := AComboBox.Items[Index].LastIndexOf('[');
    ClosingBracket := AComboBox.Items[Index].LastIndexOf(']');
    if (OpeningBracket >= 0) and (ClosingBracket > OpeningBracket) then
    begin
      CodeText := Copy(AComboBox.Items[Index], OpeningBracket + 2,
        ClosingBracket - OpeningBracket - 1);
      if SameText(CodeText, ALanguageCode) then
      begin
        AComboBox.ItemIndex := Index;
        Break;
      end;
    end;
  end;
end;

procedure TfrmTranslationStudio.ApplyTargetLanguageDefaults;
var
  DisplayText: string;
  LanguageCode: string;
  LocaleSettings: TFormatSettings;
  OpeningBracket: Integer;
begin
  LanguageCode := SelectedLanguageCode(cboTargetLanguage);
  if LanguageCode = '' then
    Exit;
  DisplayText := cboTargetLanguage.Items[cboTargetLanguage.ItemIndex];
  OpeningBracket := DisplayText.LastIndexOf('[');
  if OpeningBracket > 0 then
    edtNativeLanguageName.Text := CanonicalNativeLanguageName(LanguageCode,
      Trim(Copy(DisplayText, 1, OpeningBracket)));
  if StartsText('ar-', LanguageCode) or StartsText('fa-', LanguageCode) or
     StartsText('he-', LanguageCode) or StartsText('ur-', LanguageCode) then
    cboTextDirection.ItemIndex := 1
  else
    cboTextDirection.ItemIndex := 0;
  try
    LocaleSettings := TFormatSettings.Create(LanguageCode);
    edtShortDateFormat.Text := LocaleSettings.ShortDateFormat;
    edtLongDateFormat.Text := LocaleSettings.LongDateFormat;
    edtShortTimeFormat.Text := LocaleSettings.ShortTimeFormat;
    edtLongTimeFormat.Text := LocaleSettings.LongTimeFormat;
    edtDecimalSeparator.Text := LocaleSettings.DecimalSeparator;
    edtThousandSeparator.Text := LocaleSettings.ThousandSeparator;
    edtCurrencySymbol.Text := LocaleSettings.CurrencyString;
  except
    edtShortDateFormat.Text := 'yyyy-MM-dd';
    edtLongDateFormat.Text := 'dddd, d MMMM yyyy';
    edtShortTimeFormat.Text := 'HH:mm';
    edtLongTimeFormat.Text := 'HH:mm:ss';
    edtDecimalSeparator.Text := '.';
    edtThousandSeparator.Text := ',';
    edtCurrencySymbol.Text := '';
  end;
end;

procedure TfrmTranslationStudio.DisplaySelectedIntegrationChange;
var
  ComponentFileName: string;
begin
  if (FIntegrationPackageDirectory = '') or
    (lstIntegrationPlan.ItemIndex < 0) then
  begin
    memIntegrationDiff.Text :=
      'Generate the component kit to inspect its files and instructions.';
    Exit;
  end;
  ComponentFileName := TPath.Combine(FIntegrationPackageDirectory,
    lstIntegrationPlan.Items[lstIntegrationPlan.ItemIndex]);
  if TFile.Exists(ComponentFileName) then
    memIntegrationDiff.Lines.LoadFromFile(ComponentFileName, TEncoding.UTF8)
  else
    memIntegrationDiff.Text := 'Generated file not found: ' +
      ComponentFileName;
  memIntegrationDiff.GoToTextBegin;
end;

procedure TfrmTranslationStudio.UpdateIntegrationApplyState;
begin
  btnApplyIntegration.Enabled := False;
  btnRestoreIntegration.Enabled := False;
  btnCompleteReset.Enabled := False;
  chkIntegrationReviewConfirmed.Enabled := False;
  lblIntegrationDiffTitle.Text := 'Setup instructions and generated files';
end;

function TfrmTranslationStudio.SelectedProvider: TTranslationProvider;
begin
  if cboTranslationProvider.ItemIndex = 1 then
    Result := tpGoogle
  else
    Result := tpDeepL;
end;

function TfrmTranslationStudio.EffectiveApiKey(
  const AProvider: TTranslationProvider): string;
begin
  Result := Trim(edtProviderApiKey.Text);
  if Result <> '' then
    Exit;
  Result := FSessionApiKeys[AProvider];
  if (Result = '') and TProviderCredentialStore.Exists(AProvider) then
    Result := TProviderCredentialStore.Read(AProvider);
end;

procedure TfrmTranslationStudio.LoadProviderSettings;
begin
  FreeAndNil(FProviderSettings);
  FProviderSettings := TProviderSettings.Load;
  cboTranslationProvider.ItemIndex := Ord(FProviderSettings.Provider);
  cboDeepLPlan.ItemIndex := Ord(FProviderSettings.DeepLPlan);
  chkRememberCredential.IsChecked :=
    FProviderSettings.RememberCredential;
  edtRequestTimeout.Text :=
    FProviderSettings.RequestTimeoutSeconds.ToString;
  edtProviderBatchSize.Text := FProviderSettings.BatchSize.ToString;
  edtProviderApiKey.Text := '';
  cboDeepLPlan.Enabled := SelectedProvider = tpDeepL;
  lblCredentialStatus.Text :=
    'Provider configuration has not been opened.';
end;

procedure TfrmTranslationStudio.SaveProviderSettings;
begin
  FProviderSettings.Provider := SelectedProvider;
  if cboDeepLPlan.ItemIndex = 1 then
    FProviderSettings.DeepLPlan := dpPro
  else
    FProviderSettings.DeepLPlan := dpFree;
  FProviderSettings.RememberCredential :=
    chkRememberCredential.IsChecked;
  FProviderSettings.RequestTimeoutSeconds :=
    StrToIntDef(edtRequestTimeout.Text, 30);
  FProviderSettings.BatchSize :=
    StrToIntDef(edtProviderBatchSize.Text, 40);
  if FProviderSettings.RequestTimeoutSeconds < 5 then
    FProviderSettings.RequestTimeoutSeconds := 5;
  if FProviderSettings.RequestTimeoutSeconds > 300 then
    FProviderSettings.RequestTimeoutSeconds := 300;
  if FProviderSettings.BatchSize < 1 then
    FProviderSettings.BatchSize := 1;
  if FProviderSettings.BatchSize > 50 then
    FProviderSettings.BatchSize := 50;
  edtRequestTimeout.Text :=
    FProviderSettings.RequestTimeoutSeconds.ToString;
  edtProviderBatchSize.Text :=
    FProviderSettings.BatchSize.ToString;
  FProviderSettings.Save;
end;

procedure TfrmTranslationStudio.UpdateCredentialStatus;
var
  Provider: TTranslationProvider;
begin
  Provider := SelectedProvider;
  if Trim(edtProviderApiKey.Text) <> '' then
    lblCredentialStatus.Text :=
      'A new masked key is ready to save or use for this session.'
  else if FSessionApiKeys[Provider] <> '' then
    lblCredentialStatus.Text :=
      'A session-only key is active. It will be forgotten when the Studio closes.'
  else if TProviderCredentialStore.Exists(Provider) then
    lblCredentialStatus.Text :=
      'A key is stored securely in Windows Credential Manager.'
  else
    lblCredentialStatus.Text :=
      'No API key is configured for this provider.';
end;

procedure TfrmTranslationStudio.cboTargetLanguageChange(Sender: TObject);
begin
  ApplyTargetLanguageDefaults;
  InvalidateValidation;
end;

procedure TfrmTranslationStudio.DisplayProjectSummary(
  const AProfile: TProjectProfile);
begin
  FProjectProfile := AProfile;
  lblProjectNameValue.Text := AProfile.ProjectName;
  lblFrameworkValue.Text := TargetFrameworkToString(AProfile.Framework);
  lblPlatformsValue.Text := ProjectPlatformsDisplayName(AProfile);
  lblFormsValue.Text := AProfile.FormResourceCount.ToString;
  lblSourcesValue.Text := AProfile.SourceFileCount.ToString;
  ClearScanSummary;
  ResetCatalog;
  btnScanProject.Enabled := AProfile.Framework <> tfUnknown;
  btnBuildIntegrationPlan.Enabled := AProfile.Framework <> tfUnknown;
  btnCompleteReset.Enabled := False;
  SetWorkflowStep(1);

  if AProfile.Framework = tfUnknown then
    lblStatus.Text :=
      'Project opened, but its UI framework could not be identified.'
  else
    lblStatus.Text := Format(
      '%s project detected successfully. Ready to scan.',
      [TargetFrameworkToString(AProfile.Framework)]);
end;

procedure TfrmTranslationStudio.DisplayScanResult(
  const AResult: TProjectScanResult);
var
  DisplayText: string;
  ScanItem: TScanItem;
  DesignerCount, RuntimeCount, DataCount, SuspiciousCount, ExcludedCount: Integer;
begin
  DesignerCount := 0;
  RuntimeCount := 0;
  DataCount := 0;
  SuspiciousCount := 0;
  ExcludedCount := 0;
  for ScanItem in AResult.Items do
    case ScanItem.TextOwnership of
      tokRuntimeWired, tokRuntimeUnwired: Inc(RuntimeCount);
      tokApplicationData: Inc(DataCount);
      tokSuspicious: Inc(SuspiciousCount);
      tokExcluded: Inc(ExcludedCount);
    else
      Inc(DesignerCount);
    end;
  lblScanSummaryValue.Text := Format('%d translatable entries in %d ms',
    [AResult.Items.Count, AResult.ElapsedMilliseconds]);
  lblScanBreakdown.Text := Format(
    '%d form properties | %d resourcestrings | %d files' + sLineBreak +
    'Ownership: %d designer | %d runtime | %d data | %d suspicious | %d excluded',
    [AResult.CountByKind(stkFormProperty),
     AResult.CountByKind(stkResourceString), AResult.FilesScanned,
     DesignerCount, RuntimeCount, DataCount, SuspiciousCount, ExcludedCount]);

  lstScanResults.BeginUpdate;
  try
    lstScanResults.Items.Clear;
    for ScanItem in AResult.Items do
    begin
      DisplayText := ScanItem.SourceText.Replace(#13#10, ' / ')
        .Replace(#13, ' / ').Replace(#10, ' / ');
      lstScanResults.Items.Add(Format('[%s] %s  =  %s',
        [TextOwnershipDisplayName(ScanItem.TextOwnership), ScanItem.Key,
         DisplayText]));
    end;
  finally
    lstScanResults.EndUpdate;
  end;
end;

procedure TfrmTranslationStudio.DisplayCatalogEntries;
var
  Entry: TTranslationEntry;
begin
  lstCatalogEntries.BeginUpdate;
  try
    lstCatalogEntries.Items.Clear;
    if FTranslationCatalog <> nil then
      for Entry in FTranslationCatalog.Entries do
        lstCatalogEntries.Items.Add(Entry.Key + '  [' +
          TranslationStatusToString(Entry.Status) + ' / ' +
          TranslationOriginDisplayName(Entry.TranslationOrigin) + ']');
  finally
    lstCatalogEntries.EndUpdate;
  end;
  memSourceText.Text := '';
  memTranslatedText.Text := '';
  lblRuntimeApplicationValue.Text := 'Runtime: select an entry';
  lblTranslationContextValue.Text := 'Context: select an entry';
  lblTranslationContextValue.Hint :=
    'Select an entry to see its inferred translation context.';
  chkRuntimeWiringConfirmed.IsChecked := False;
  chkRuntimeWiringConfirmed.Enabled := False;
  cboTranslationSuggestions.Items.Clear;
  btnAcceptSuggestion.Enabled := False;
  btnMarkTranslationReviewed.Enabled := False;
  btnApproveTranslation.Enabled := False;
  UpdateCatalogReadiness;
  if lstCatalogEntries.Count > 0 then
    lstCatalogEntries.ItemIndex := 0;
end;

procedure TfrmTranslationStudio.UpdateCatalogReadiness;
var
  ActiveCount: Integer;
  ApprovedCount: Integer;
  AIDraftCount: Integer;
  AutomaticCount: Integer;
  Entry: TTranslationEntry;
  ManualConfirmedCount: Integer;
  ManualCount: Integer;
  ReviewedCount: Integer;
  TranslatedCount: Integer;
begin
  AIDraftCount := 0;
  ActiveCount := 0;
  ApprovedCount := 0;
  AutomaticCount := 0;
  ManualConfirmedCount := 0;
  ManualCount := 0;
  ReviewedCount := 0;
  TranslatedCount := 0;
  if FTranslationCatalog <> nil then
    for Entry in FTranslationCatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
        not (Entry.Status in [tsExcluded, tsObsolete]) then
      begin
        Inc(ActiveCount);
        if Trim(Entry.TranslatedText) <> '' then
          Inc(TranslatedCount);
        if Entry.Status in [tsReviewed, tsApproved] then
          Inc(ReviewedCount);
        if Entry.Status = tsApproved then
          Inc(ApprovedCount);
        if Entry.Status = tsAIDraft then
          Inc(AIDraftCount);
        if Entry.RuntimeApplication = rakAutomatic then
          Inc(AutomaticCount)
        else
        begin
          Inc(ManualCount);
          if Entry.RuntimeWiringConfirmed then
            Inc(ManualConfirmedCount);
        end;
      end;
  if FTranslationCatalog = nil then
    lblCatalogReadiness.Text := 'Translation and runtime readiness: no catalog'
  else
    lblCatalogReadiness.Text := Format(
      'Text %d/%d  |  AI drafts %d  |  Reviewed+ %d  |  Approved %d' +
      sLineBreak +
      'Runtime automatic %d  |  Manual wiring %d/%d confirmed',
      [TranslatedCount, ActiveCount, AIDraftCount, ReviewedCount,
       ApprovedCount,
       AutomaticCount, ManualConfirmedCount, ManualCount]);
end;

procedure TfrmTranslationStudio.UpdateTranslationSuggestions(
  const AEntry: TTranslationEntry);
var
  Candidate: TTranslationEntry;
  CandidateIndex: Integer;
  CandidateSortText: string;
  Candidates: TStringList;
  Score: Integer;
begin
  cboTranslationSuggestions.Items.Clear;
  btnAcceptSuggestion.Enabled := False;
  if (FTranslationCatalog = nil) or (AEntry = nil) then
    Exit;

  Candidates := TStringList.Create;
  try
    Candidates.Sorted := True;
    Candidates.Duplicates := dupAccept;
    for Candidate in FTranslationCatalog.Entries do
      if (Candidate <> AEntry) and
         SameText(Candidate.SourceText, AEntry.SourceText) and
         (Candidate.Status in [tsReviewed, tsApproved]) and
         (Trim(Candidate.TranslatedText) <> '') then
      begin
        Score := 0;
        if (AEntry.SemanticConcept <> '') and
          SameText(Candidate.SemanticConcept, AEntry.SemanticConcept) then
          Inc(Score, 300)
        else if SameText(Candidate.ContextKind, AEntry.ContextKind) then
          Inc(Score, 80);
        if SameText(Candidate.FormName, AEntry.FormName) then
          Inc(Score, 100);
        if SameText(Candidate.ComponentClassName,
          AEntry.ComponentClassName) and
           SameText(Candidate.PropertyName, AEntry.PropertyName) then
          Inc(Score, 60)
        else if SameText(Candidate.PropertyName,
          AEntry.PropertyName) then
          Inc(Score, 20);
        if SameText(Candidate.SourceKind, AEntry.SourceKind) then
          Inc(Score, 10);
        CandidateSortText := Format('%.4d|%s|%s',
          [9999 - Score, Candidate.Key, Candidate.TranslatedText]);
        Candidates.AddObject(CandidateSortText, Candidate);
      end;

    for CandidateIndex := 0 to Candidates.Count - 1 do
    begin
      Candidate := TTranslationEntry(Candidates.Objects[CandidateIndex]);
      cboTranslationSuggestions.Items.AddObject(
        Candidate.TranslatedText + '  â€”  ' + Candidate.Key, Candidate);
    end;
  finally
    Candidates.Free;
  end;
  if cboTranslationSuggestions.Items.Count > 0 then
  begin
    cboTranslationSuggestions.ItemIndex := 0;
    btnAcceptSuggestion.Enabled := True;
  end;
end;

procedure TfrmTranslationStudio.DisplayCatalogLanguage;
begin
  if FTranslationCatalog = nil then
    Exit;
  SelectLanguageCode(cboSourceLanguage,
    FTranslationCatalog.SourceLanguage);
  SelectLanguageCode(cboTargetLanguage,
    FTranslationCatalog.Locale.LanguageCode);
  edtNativeLanguageName.Text := CanonicalNativeLanguageName(
    FTranslationCatalog.Locale.LanguageCode,
    FTranslationCatalog.Locale.NativeLanguageName);
  if SameText(FTranslationCatalog.Locale.TextDirection, 'rtl') then
    cboTextDirection.ItemIndex := 1
  else
    cboTextDirection.ItemIndex := 0;
  edtShortDateFormat.Text := FTranslationCatalog.Locale.ShortDateFormat;
  edtLongDateFormat.Text := FTranslationCatalog.Locale.LongDateFormat;
  edtShortTimeFormat.Text := FTranslationCatalog.Locale.ShortTimeFormat;
  edtLongTimeFormat.Text := FTranslationCatalog.Locale.LongTimeFormat;
  edtDecimalSeparator.Text := FTranslationCatalog.Locale.DecimalSeparator;
  edtThousandSeparator.Text := FTranslationCatalog.Locale.ThousandSeparator;
  edtCurrencySymbol.Text := FTranslationCatalog.Locale.CurrencySymbol;
end;

procedure TfrmTranslationStudio.DisplayValidationResult;
var
  Entry: TTranslationEntry;
  Issue: TValidationIssue;
  RuntimeEntryCount: Integer;
begin
  lstValidationIssues.BeginUpdate;
  try
    lstValidationIssues.Items.Clear;
    if FValidationResult <> nil then
      for Issue in FValidationResult.Issues do
        lstValidationIssues.Items.Add(Format('[%s] %s  %s',
          [ValidationSeverityDisplayName(Issue.Severity),
           Issue.EntryKey, Issue.MessageText]));
  finally
    lstValidationIssues.EndUpdate;
  end;

  if FValidationResult = nil then
  begin
    lblValidationSummary.Text := 'Validation has not been run.';
    btnExportRuntimePack.Enabled := False;
    Exit;
  end;

  lblValidationSummary.Text := Format(
    '%d errors  |  %d warnings  |  %d information messages.  %s',
    [FValidationResult.CountBySeverity(vsError),
     FValidationResult.CountBySeverity(vsWarning),
     FValidationResult.CountBySeverity(vsInformation),
     IfThen(FValidationResult.HasErrors,
       'Fix errors before export; double-click an item to open it.',
       'Export may continue; double-click a warning to review it.')]);
  btnExportRuntimePack.Enabled := not FValidationResult.HasErrors;
  if FValidationResult.HasErrors then
    lblExportSummary.Text := 'Export is blocked by validation errors.'
  else
  begin
    RuntimeEntryCount := 0;
    for Entry in FTranslationCatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
         not (Entry.Status in [tsExcluded, tsObsolete]) then
        Inc(RuntimeEntryCount);
    lblExportSummary.Text := Format(
      '%d translated entries are ready for offline export.',
      [RuntimeEntryCount]);
  end;
end;

procedure TfrmTranslationStudio.lblCatalogPathValueClick(Sender: TObject);
var
  Arguments: string;
  CatalogDirectory: string;
begin
  if FCatalogFileName = '' then
  begin
    lblStatus.Text := 'Save or open a catalog before opening its folder.';
    Exit;
  end;
  CatalogDirectory := TPath.GetDirectoryName(FCatalogFileName);
  if TFile.Exists(FCatalogFileName) then
    Arguments := '/select,"' + FCatalogFileName + '"'
  else
    Arguments := '"' + CatalogDirectory + '"';
  if ShellExecute(0, 'open', 'explorer.exe', PChar(Arguments), nil,
    SW_SHOWNORMAL) <= 32 then
    lblStatus.Text := 'Unable to open the catalog folder.'
  else
    lblStatus.Text := 'Catalog selected in File Explorer.';
end;

procedure TfrmTranslationStudio.lblExportPathValueClick(Sender: TObject);
var
  Arguments: string;
  RuntimeFileName: string;
begin
  RuntimeFileName := Trim(lblExportPathValue.Text);
  if not TFile.Exists(RuntimeFileName) then
  begin
    lblStatus.Text := 'Export a runtime pack before opening its location.';
    Exit;
  end;
  Arguments := '/select,"' + RuntimeFileName + '"';
  if ShellExecute(0, 'open', 'explorer.exe', PChar(Arguments), nil,
    SW_SHOWNORMAL) <= 32 then
    lblStatus.Text := 'Unable to open the runtime-pack folder.'
  else
    lblStatus.Text := 'Runtime language pack selected in File Explorer.';
end;

procedure TfrmTranslationStudio.lstValidationIssuesDblClick(Sender: TObject);
var
  EntryIndex: Integer;
  Issue: TValidationIssue;
begin
  if (FValidationResult = nil) or (FTranslationCatalog = nil) or
     (lstValidationIssues.ItemIndex < 0) or
     (lstValidationIssues.ItemIndex >= FValidationResult.Issues.Count) then
    Exit;
  Issue := FValidationResult.Issues[lstValidationIssues.ItemIndex];
  if Issue.EntryKey = '' then
  begin
    lblStatus.Text :=
      'This message concerns the catalog settings at the top of Translate.';
    SetWorkflowStep(3);
    Exit;
  end;
  for EntryIndex := 0 to FTranslationCatalog.Entries.Count - 1 do
    if SameText(FTranslationCatalog.Entries[EntryIndex].Key,
      Issue.EntryKey) then
    begin
      SetWorkflowStep(3);
      lstCatalogEntries.ItemIndex := EntryIndex;
      lblStatus.Text := 'Opened ' + Issue.EntryKey + ': ' + Issue.MessageText;
      Exit;
    end;
  lblStatus.Text := 'The referenced catalog entry is no longer present.';
end;

procedure TfrmTranslationStudio.InvalidateValidation;
begin
  FreeAndNil(FValidationResult);
  DisplayValidationResult;
  lblExportPathValue.Text := 'Output path will appear here.';
end;

procedure TfrmTranslationStudio.ResetCatalog;
begin
  FreeAndNil(FValidationResult);
  FreeAndNil(FTranslationCatalog);
  FCatalogFileName := '';
  SelectLanguageCode(cboSourceLanguage, 'en-US');
  cboTargetLanguage.ItemIndex := -1;
  edtNativeLanguageName.Text := '';
  cboTextDirection.ItemIndex := 0;
  edtShortDateFormat.Text := '';
  edtLongDateFormat.Text := '';
  edtShortTimeFormat.Text := '';
  edtLongTimeFormat.Text := '';
  edtDecimalSeparator.Text := '';
  edtThousandSeparator.Text := '';
  edtCurrencySymbol.Text := '';
  lblCatalogPathValue.Text := 'Catalog has not been saved.';
  lstCatalogEntries.Items.Clear;
  memSourceText.Text := '';
  memTranslatedText.Text := '';
  lblRuntimeApplicationValue.Text := 'Runtime: select an entry';
  lblTranslationContextValue.Text := 'Context: select an entry';
  lblTranslationContextValue.Hint :=
    'Select an entry to see its inferred translation context.';
  chkRuntimeWiringConfirmed.IsChecked := False;
  chkRuntimeWiringConfirmed.Enabled := False;
  cboTranslationSuggestions.Items.Clear;
  btnAcceptSuggestion.Enabled := False;
  btnMarkTranslationReviewed.Enabled := False;
  btnApproveTranslation.Enabled := False;
  UpdateCatalogReadiness;
  DisplayValidationResult;
end;

procedure TfrmTranslationStudio.SetWorkflowStep(const AStep: Integer);
const
  InactiveColor: TAlphaColor = $FFD7E8FF;
  ActiveColor: TAlphaColor = $FFFFFFFF;
begin
  if FIntroScreen then
  begin
    NavigationCard.Visible := False;
    IntroCard.Visible := True;
    ProjectCard.Visible := False;
    ProjectDetailsCard.Visible := False;
    LanguagePageCard.Visible := False;
    ValidationPageCard.Visible := False;
    ExportPageCard.Visible := False;
    IntegrationPageCard.Visible := False;
    SettingsPageCard.Visible := False;
    NavigationSelection.Visible := False;
    lblStatus.Text := 'Choose Setup Wizard for a new project or Maintenance Studio for existing work.';
    Exit;
  end;
  NavigationCard.Visible := True;
  IntroCard.Visible := False;
  NavigationSelection.Visible := True;
  lblNavigationProject.TextSettings.FontColor := InactiveColor;
  lblNavigationScan.TextSettings.FontColor := InactiveColor;
  lblNavigationLanguages.TextSettings.FontColor := InactiveColor;
  lblNavigationValidation.TextSettings.FontColor := InactiveColor;
  lblNavigationExport.TextSettings.FontColor := InactiveColor;
  lblNavigationIntegration.TextSettings.FontColor := InactiveColor;
  lblNavigationSettings.TextSettings.FontColor := InactiveColor;

  ProjectCard.Visible := AStep in [1, 2];
  ProjectDetailsCard.Visible := AStep in [1, 2];
  LanguagePageCard.Visible := AStep = 3;
  ValidationPageCard.Visible := AStep = 4;
  ExportPageCard.Visible := AStep = 5;
  IntegrationPageCard.Visible := AStep = 6;
  SettingsPageCard.Visible := AStep = 7;

  case AStep of
    1:
      begin
        NavigationSelection.Position.Y := 72;
        lblNavigationProject.TextSettings.FontColor := ActiveColor;
        lblStatus.Text :=
          'Project: open a Delphi project or review the current project details.';
      end;
    2:
      begin
        NavigationSelection.Position.Y := 128;
        lblNavigationScan.TextSettings.FontColor := ActiveColor;
        lblStatus.Text :=
          'Scan: inventory translatable controls and resources without changing the project.';
      end;
    3:
      begin
        NavigationSelection.Position.Y := 184;
        lblNavigationLanguages.TextSettings.FontColor := ActiveColor;
        LanguagePageCard.BringToFront;
        lblStatus.Text :=
          'Translate: choose a language, translate automatically, and manage the JSON catalog.';
      end;
    4:
      begin
        NavigationSelection.Position.Y := 240;
        lblNavigationValidation.TextSettings.FontColor := ActiveColor;
        ValidationPageCard.BringToFront;
        lblStatus.Text :=
          'Validation: run checks; errors block export, while warnings request review.';
      end;
    5:
      begin
        NavigationSelection.Position.Y := 296;
        lblNavigationExport.TextSettings.FontColor := ActiveColor;
        ExportPageCard.BringToFront;
        lblStatus.Text :=
          'Export: create the compact JSON runtime language pack after validation passes.';
      end;
    6:
      begin
        NavigationSelection.Position.Y := 352;
        lblNavigationIntegration.TextSettings.FontColor := ActiveColor;
        IntegrationPageCard.BringToFront;
        lblStatus.Text :=
          'Integration: generate a component kit without modifying target source files.';
      end;
    7:
      begin
        NavigationSelection.Position.Y := 408;
        lblNavigationSettings.TextSettings.FontColor := ActiveColor;
        SettingsPageCard.BringToFront;
        UpdateCredentialStatus;
        lblStatus.Text :=
          'Provider Settings: securely configure and test Google Cloud or DeepL.';
      end;
  end;
  StatusCard.BringToFront;
end;

procedure TfrmTranslationStudio.UpdateCatalogFromLanguageEditors;
var
  LocaleSettings: TFormatSettings;
begin
  if FTranslationCatalog = nil then
    raise Exception.Create(
      'Scan the project or open an existing catalog first.');
  if SelectedLanguageCode(cboTargetLanguage) = '' then
    raise Exception.Create('Select a target language.');
  if Trim(edtNativeLanguageName.Text) = '' then
    raise Exception.Create('Enter the language name in its native form.');

  LocaleSettings := TFormatSettings.Create(
    SelectedLanguageCode(cboTargetLanguage));
  if edtShortDateFormat.Text = '' then
    edtShortDateFormat.Text := LocaleSettings.ShortDateFormat;
  if edtLongDateFormat.Text = '' then
    edtLongDateFormat.Text := LocaleSettings.LongDateFormat;
  if edtShortTimeFormat.Text = '' then
    edtShortTimeFormat.Text := LocaleSettings.ShortTimeFormat;
  if edtLongTimeFormat.Text = '' then
    edtLongTimeFormat.Text := LocaleSettings.LongTimeFormat;
  if edtDecimalSeparator.Text = '' then
    edtDecimalSeparator.Text := LocaleSettings.DecimalSeparator;
  if edtThousandSeparator.Text = '' then
    edtThousandSeparator.Text := LocaleSettings.ThousandSeparator;
  if edtCurrencySymbol.Text = '' then
    edtCurrencySymbol.Text := LocaleSettings.CurrencyString;

  FTranslationCatalog.SourceLanguage :=
    SelectedLanguageCode(cboSourceLanguage);
  FTranslationCatalog.Locale.LanguageCode :=
    SelectedLanguageCode(cboTargetLanguage);
  FTranslationCatalog.Locale.NativeLanguageName :=
    Trim(edtNativeLanguageName.Text);
  if cboTextDirection.ItemIndex = 1 then
    FTranslationCatalog.Locale.TextDirection := 'rtl'
  else
    FTranslationCatalog.Locale.TextDirection := 'ltr';
  FTranslationCatalog.Locale.ShortDateFormat :=
    edtShortDateFormat.Text;
  FTranslationCatalog.Locale.LongDateFormat :=
    edtLongDateFormat.Text;
  FTranslationCatalog.Locale.ShortTimeFormat :=
    edtShortTimeFormat.Text;
  FTranslationCatalog.Locale.LongTimeFormat :=
    edtLongTimeFormat.Text;
  FTranslationCatalog.Locale.DecimalSeparator :=
    edtDecimalSeparator.Text;
  FTranslationCatalog.Locale.ThousandSeparator :=
    edtThousandSeparator.Text;
  FTranslationCatalog.Locale.CurrencySymbol :=
    edtCurrencySymbol.Text;
end;

procedure TfrmTranslationStudio.SaveCatalog;
begin
  UpdateCatalogFromLanguageEditors;
  if FCatalogFileName = '' then
    FCatalogFileName :=
      TTranslationWorkspace.DevelopmentCatalogFileName(FProjectProfile,
        FTranslationCatalog.Locale.LanguageCode);
  TCatalogJson.SaveToFile(FTranslationCatalog, FCatalogFileName);
  lblCatalogPathValue.Text := FCatalogFileName;
  lblStatus.Text := 'Development catalog saved.';
end;

procedure TfrmTranslationStudio.RunCatalogValidation;
begin
  UpdateCatalogFromLanguageEditors;
  FreeAndNil(FValidationResult);
  FValidationResult := TCatalogValidator.Validate(FTranslationCatalog);
  DisplayValidationResult;
end;

procedure TfrmTranslationStudio.btnOpenProjectClick(Sender: TObject);
begin
  if not dlgOpenProject.Execute then
    Exit;

  try
    DisplayProjectSummary(TProjectDetector.Detect(dlgOpenProject.FileName));
  except
    on E: Exception do
    begin
      ClearProjectSummary;
      lblStatus.Text := E.Message;
    end;
  end;
end;

procedure TfrmTranslationStudio.btnScanProjectClick(Sender: TObject);
var
  MergeSummary: TCatalogMergeSummary;
  NewScanResult: TProjectScanResult;
begin
  SetWorkflowStep(2);
  btnScanProject.Enabled := False;
  lblStatus.Text := 'Scanning project text resources...';
  Application.ProcessMessages;
  try
    NewScanResult := TProjectScanner.Scan(FProjectProfile);
    FreeAndNil(FScanResult);
    FScanResult := NewScanResult;
    FLastScanCompletedAt := Now;
    DisplayScanResult(FScanResult);

    if FTranslationCatalog = nil then
    begin
      FTranslationCatalog := TTranslationCatalog.Create;
      FTranslationCatalog.ApplicationId := FProjectProfile.ProjectName;
      FTranslationCatalog.Framework := FProjectProfile.Framework;
      FTranslationCatalog.SourceLanguage :=
        SelectedLanguageCode(cboSourceLanguage);
    end;
    MergeSummary := TScanCatalogMerger.Merge(FScanResult,
      FTranslationCatalog);
    DisplayCatalogEntries;
    InvalidateValidation;
    lblStatus.Text := Format(
      'Scan complete: %d new, %d changed, %d unchanged, %d obsolete.',
      [MergeSummary.NewEntries, MergeSummary.ChangedEntries,
       MergeSummary.UnchangedEntries, MergeSummary.ObsoleteEntries]);
  except
    on E: Exception do
      lblStatus.Text := 'Scan failed: ' + E.Message;
  end;
  btnScanProject.Enabled := FProjectProfile.Framework <> tfUnknown;
end;

procedure TfrmTranslationStudio.lblNavigationProjectClick(Sender: TObject);
begin
  SetWorkflowStep(1);
end;

procedure TfrmTranslationStudio.lblNavigationScanClick(Sender: TObject);
begin
  SetWorkflowStep(2);
end;

procedure TfrmTranslationStudio.lblNavigationLanguagesClick(Sender: TObject);
begin
  SetWorkflowStep(3);
end;

procedure TfrmTranslationStudio.lblNavigationValidationClick(Sender: TObject);
begin
  SetWorkflowStep(4);
end;

procedure TfrmTranslationStudio.lblNavigationExportClick(Sender: TObject);
begin
  SetWorkflowStep(5);
end;

procedure TfrmTranslationStudio.lblNavigationIntegrationClick(Sender: TObject);
begin
  SetWorkflowStep(6);
end;

procedure TfrmTranslationStudio.lblNavigationSettingsClick(Sender: TObject);
begin
  SetWorkflowStep(7);
end;

procedure TfrmTranslationStudio.cboTranslationProviderChange(Sender: TObject);
begin
  cboDeepLPlan.Enabled := SelectedProvider = tpDeepL;
  edtProviderApiKey.Text := '';
  UpdateCredentialStatus;
end;

procedure TfrmTranslationStudio.btnSaveProviderKeyClick(Sender: TObject);
var
  ApiKey: string;
  Provider: TTranslationProvider;
begin
  try
    Provider := SelectedProvider;
    ApiKey := Trim(edtProviderApiKey.Text);
    if ApiKey = '' then
      raise Exception.Create(
        'Enter the new API key in the masked field first.');
    SaveProviderSettings;
    if chkRememberCredential.IsChecked then
    begin
      TProviderCredentialStore.Write(Provider, ApiKey);
      FSessionApiKeys[Provider] := '';
      lblStatus.Text :=
        'API key saved securely in Windows Credential Manager.';
    end
    else
    begin
      TProviderCredentialStore.Delete(Provider);
      FSessionApiKeys[Provider] := ApiKey;
      lblStatus.Text :=
        'API key is available for this Studio session only.';
    end;
    edtProviderApiKey.Text := '';
    UpdateCredentialStatus;
  except
    on E: Exception do
      lblStatus.Text := 'Unable to save provider settings: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnRemoveProviderKeyClick(Sender: TObject);
var
  Provider: TTranslationProvider;
begin
  try
    Provider := SelectedProvider;
    TProviderCredentialStore.Delete(Provider);
    FSessionApiKeys[Provider] := '';
    edtProviderApiKey.Text := '';
    UpdateCredentialStatus;
    lblStatus.Text := 'The selected provider key was removed.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to remove the provider key: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnTestProviderConnectionClick(
  Sender: TObject);
var
  Client: TTranslationProviderClient;
begin
  btnTestProviderConnection.Enabled := False;
  try
    SaveProviderSettings;
    Client := TTranslationProviderClient.Create(
      FProviderSettings.Provider, FProviderSettings.DeepLPlan,
      EffectiveApiKey(FProviderSettings.Provider),
      FProviderSettings.RequestTimeoutSeconds,
      FProviderSettings.BatchSize);
    try
      Client.TestConnection;
      lblStatus.Text := Format(
        '%s connection test passed.',
        [TranslationProviderDisplayName(FProviderSettings.Provider)]);
    finally
      Client.Free;
    end;
  except
    on E: Exception do
      lblStatus.Text := 'Connection test failed: ' + E.Message;
  end;
  btnTestProviderConnection.Enabled := True;
end;

procedure TfrmTranslationStudio.btnBuildIntegrationPlanClick(Sender: TObject);
var
  Descriptor: TLanguagePackDescriptor;
  Languages: TObjectList<TLanguagePackDescriptor>;
begin
  btnApplyIntegration.Text := 'Apply';
  chkIntegrationReviewConfirmed.Text :=
    'I authorize the backed-up, transactional integration changes';
  chkIntegrationReviewConfirmed.IsChecked := False;
  chkIntegrationReviewConfirmed.Enabled := False;
  btnApplyIntegration.Enabled := False;
  btnRestoreIntegration.Enabled := False;
  try
    if IsComponentIntegrationMode then
    begin
      lstIntegrationPlan.Items.Clear;
      lstIntegrationPlan.Items.Add(
        '1. Generate a self-contained component integration kit.');
      if FProjectProfile.Framework = tfVCL then
        lstIntegrationPlan.Items.Add(
          '2. In Delphi, add DATLanguageManagerVCLDesign.bpl through ' +
          'Component > Install Packages.')
      else
        lstIntegrationPlan.Items.Add(
          '2. In Delphi, add DATLanguageManagerFMXDesign.bpl through ' +
          'Component > Install Packages.');
      lstIntegrationPlan.Items.Add(
        '3. Place one DAT language manager on the primary form.');
      lstIntegrationPlan.Items.Add(
        '4. Use the detected ApplicationId and LanguagesFolder in Object Inspector.');
      lstIntegrationPlan.Items.Add(
        '5. Place the matching DAT language combo box, or connect an equivalent Language menu.');
      lstIntegrationPlan.Items.Add(
        '6. Configure automatic Search Path and JSON-pack deployment.');
      lstIntegrationPlan.Items.Add(
        '7. Build and test Win32 and Win64. Pascal and form source remain designer-owned.');
      Languages := TLanguagePackDiscovery.Discover(
        TTranslationWorkspace.LanguagesDirectory(FProjectProfile),
        FProjectProfile.ProjectName);
      try
        lblIntegrationSummary.Text := Format(
          '%d translated pack(s) found; English will be generated.',
          [Languages.Count]);
        for Descriptor in Languages do
          lstIntegrationPlan.Items.Add(Format('   %s (%s)',
            [Descriptor.NativeLanguageName, Descriptor.LanguageCode]));
      finally
        Languages.Free;
      end;
      memIntegrationDiff.Text :=
        'The kit is written only under the Studio export folder. The target ' +
        'project is not opened for writing.';
      btnGenerateIntegrationPackage.Enabled := True;
      btnOpenDesignPackageLocation.Enabled := True;
      lblStatus.Text :=
        'Component plan ready. No target project or source files were changed.';
      Exit;
    end;
    lstIntegrationPlan.Items.Clear;
    lstIntegrationPlan.Items.Add(
      'Target source integration is disabled.');
    lstIntegrationPlan.Items.Add(
      'Use Component Integration mode. The Studio may scan, translate, export JSON packs, and generate component kits, but it must not edit target Pascal, form, DPR, or DPROJ files.');
    memIntegrationDiff.Text :=
      'Read-only policy: no source integration preview is generated. ' +
      'Select Component Integration (Recommended) to generate the safe kit.';
    lblIntegrationSummary.Text :=
      'No target file changes are available in read-only mode.';
    lblIntegrationOutput.Text := '';
    lblStatus.Text :=
      'Target source integration is disabled. Use Component Integration.';
    btnGenerateIntegrationPackage.Enabled := False;
    Exit;
  except
    on E: Exception do
      lblStatus.Text := 'Unable to build integration plan: ' + E.Message;
  end;
end;

function FindStudioProjectRoot: string;
var
  CandidateDirectory: string;
  ParentDirectory: string;
begin
  CandidateDirectory := TPath.GetFullPath(
    ExtractFilePath(ParamStr(0)));
  while CandidateDirectory <> '' do
  begin
    if TFile.Exists(TPath.Combine(CandidateDirectory,
      'DelphiAppTranslationStudio.dproj')) then
      Exit(CandidateDirectory);
    ParentDirectory := TPath.GetDirectoryName(CandidateDirectory);
    if SameText(ParentDirectory, CandidateDirectory) then
      Break;
    CandidateDirectory := ParentDirectory;
  end;
  raise Exception.Create(
    'The Studio project root could not be located.');
end;

procedure TfrmTranslationStudio.btnOpenDesignPackageLocationClick(
  Sender: TObject);
var
  DesignPackageFileName: string;
  ExplorerArguments: string;
  StudioProjectRoot: string;
begin
  try
    if FProjectProfile.ProjectFileName = '' then
      raise Exception.Create('Open a Delphi project first.');
    if FProjectProfile.Framework = tfVCL then
      DesignPackageFileName := 'DATLanguageManagerVCLDesign.bpl'
    else
      DesignPackageFileName := 'DATLanguageManagerFMXDesign.bpl';
    StudioProjectRoot := FindStudioProjectRoot;
    DesignPackageFileName := TPath.Combine(StudioProjectRoot,
      TPath.Combine('bin\packages\Win32\Release', DesignPackageFileName));
    if not TFile.Exists(DesignPackageFileName) then
      raise EFileNotFoundException.CreateFmt(
        'Verified Win32 Release design package not found: %s. Run the ' +
        'release validation build first.', [DesignPackageFileName]);
    ExplorerArguments := '/select,"' + DesignPackageFileName + '"';
    if ShellExecute(0, 'open', 'explorer.exe', PChar(ExplorerArguments), nil,
      SW_SHOWNORMAL) <= 32 then
      raise Exception.Create('Windows could not open the package location.');
    lblStatus.Text :=
      'Design BPL selected. In Delphi use Component > Install Packages > Add.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to show the design package: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnOpenComponentKitFolderClick(
  Sender: TObject);
begin
  try
    if (FIntegrationPackageDirectory = '') or
       not TDirectory.Exists(FIntegrationPackageDirectory) then
      raise Exception.Create('Generate the component kit first.');
    if ShellExecute(0, 'open', PChar(FIntegrationPackageDirectory), nil, nil,
      SW_SHOWNORMAL) <= 32 then
      raise Exception.Create('Windows could not open the component kit folder.');
    lblStatus.Text := 'Component kit folder opened. Target source is unchanged.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to open the component kit folder: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnGenerateIntegrationPackageClick(
  Sender: TObject);
var
  FileName: string;
  OutputDirectory: string;
  StudioProjectRoot: string;
begin
  try
    btnApplyIntegration.Text := 'Apply';
    chkIntegrationReviewConfirmed.Text :=
      'I authorize the backed-up, transactional integration changes';
    StudioProjectRoot := FindStudioProjectRoot;
    if IsComponentIntegrationMode then
    begin
      OutputDirectory := TComponentIntegrationPackageGenerator.Generate(
        FProjectProfile,
        TPath.Combine(StudioProjectRoot, 'export\component-integration'),
        TPath.Combine(StudioProjectRoot, 'source\runtime'),
        TPath.Combine(StudioProjectRoot, 'source\components'));
      FIntegrationPackageDirectory := OutputDirectory;
      btnOpenComponentKitFolder.Enabled := True;
      lstIntegrationPlan.Items.Clear;
      for FileName in TDirectory.GetFiles(OutputDirectory, '*',
        TSearchOption.soAllDirectories) do
        lstIntegrationPlan.Items.Add(FileName.Substring(
          IncludeTrailingPathDelimiter(OutputDirectory).Length));
      if lstIntegrationPlan.Items.Count > 0 then
      begin
        lstIntegrationPlan.ItemIndex :=
          lstIntegrationPlan.Items.IndexOf('README.txt');
        if lstIntegrationPlan.ItemIndex < 0 then
          lstIntegrationPlan.ItemIndex := 0;
        DisplaySelectedIntegrationChange;
      end;
      lblIntegrationOutput.Text := OutputDirectory;
      lblIntegrationSummary.Text := Format(
        '%d component-kit file(s) generated; target changes: zero.',
        [lstIntegrationPlan.Items.Count]);
      lblStatus.Text :=
        'Component integration kit generated. The target project is unchanged.';
      Exit;
    end;
    lstIntegrationPlan.Items.Clear;
    lstIntegrationPlan.Items.Add(
      'Target source integration is disabled.');
    lstIntegrationPlan.Items.Add(
      'Use Component Integration mode. The Studio may scan, translate, export JSON packs, and generate component kits, but it must not edit target Pascal, form, DPR, or DPROJ files.');
    memIntegrationDiff.Text :=
      'Read-only policy: no source integration package is generated. ' +
      'Select Component Integration (Recommended) to generate the safe kit.';
    lblIntegrationOutput.Text := '';
    lblIntegrationSummary.Text :=
      'No target file changes are available in read-only mode.';
    lblStatus.Text :=
      'Target source integration is disabled. Use Component Integration.';
    btnGenerateIntegrationPackage.Enabled := False;
    Exit;
  except
    on E: Exception do
      lblStatus.Text := 'Unable to generate integration package: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnApplyIntegrationClick(Sender: TObject);
begin
  lblStatus.Text :=
    'Apply is disabled. Target source, form, DPR, and DPROJ files are read-only.';
  btnApplyIntegration.Enabled := False;
end;

procedure TfrmTranslationStudio.btnCompleteResetClick(Sender: TObject);
begin
  lblStatus.Text :=
    'Complete Reset is disabled because the selected target project is read-only.';
  btnCompleteReset.Enabled := False;
end;

procedure TfrmTranslationStudio.lstIntegrationPlanChange(Sender: TObject);
begin
  DisplaySelectedIntegrationChange;
end;

procedure TfrmTranslationStudio.chkIntegrationReviewConfirmedChange(
  Sender: TObject);
begin
  UpdateIntegrationApplyState;
end;

procedure TfrmTranslationStudio.btnRestoreIntegrationClick(Sender: TObject);
begin
  lblStatus.Text :=
    'Restore is disabled. Target source, form, DPR, and DPROJ files are read-only.';
  btnRestoreIntegration.Enabled := False;
  btnApplyIntegration.Enabled := False;
  chkIntegrationReviewConfirmed.IsChecked := False;
  chkIntegrationReviewConfirmed.Enabled := False;
end;

procedure TfrmTranslationStudio.btnOpenCatalogClick(Sender: TObject);
var
  LoadedCatalog: TTranslationCatalog;
begin
  if FProjectProfile.ProjectFileName = '' then
  begin
    lblStatus.Text := 'Open the matching Delphi project first.';
    Exit;
  end;
  if not dlgOpenCatalog.Execute then
    Exit;

  try
    LoadedCatalog := TCatalogJson.LoadFromFile(dlgOpenCatalog.FileName);
    if (LoadedCatalog.Framework <> tfUnknown) and
      (LoadedCatalog.Framework <> FProjectProfile.Framework) then
    begin
      LoadedCatalog.Free;
      raise Exception.Create(
        'The catalog framework does not match the open Delphi project.');
    end;
    FreeAndNil(FTranslationCatalog);
    FTranslationCatalog := LoadedCatalog;
    FCatalogFileName := dlgOpenCatalog.FileName;
    lblCatalogPathValue.Text := FCatalogFileName;
    DisplayCatalogLanguage;
    DisplayCatalogEntries;
    InvalidateValidation;
    lblStatus.Text := 'Development catalog opened.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to open catalog: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnSaveCatalogClick(Sender: TObject);
begin
  try
    SaveCatalog;
    InvalidateValidation;
  except
    on E: Exception do
      lblStatus.Text := 'Unable to save catalog: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnExportCatalogCsvClick(Sender: TObject);
begin
  if FTranslationCatalog = nil then
  begin
    lblStatus.Text := 'Scan a project or open a catalog first.';
    Exit;
  end;
  if SelectedLanguageCode(cboTargetLanguage) = '' then
  begin
    lblStatus.Text := 'Select a target language before exporting CSV.';
    Exit;
  end;
  try
    UpdateCatalogFromLanguageEditors;
    if FCatalogFileName = '' then
      SaveCatalog;
    dlgExportCatalogCsv.FileName := TPath.ChangeExtension(
      FCatalogFileName, '.csv');
    if not dlgExportCatalogCsv.Execute then
      Exit;
    TCatalogCsv.ExportToFile(FTranslationCatalog,
      dlgExportCatalogCsv.FileName);
    lblStatus.Text := 'Translation CSV exported: ' +
      dlgExportCatalogCsv.FileName;
  except
    on E: Exception do
      lblStatus.Text := 'Unable to export CSV: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnImportCatalogCsvClick(Sender: TObject);
var
  ConfirmationText: string;
  ImportPlan: TCatalogCsvImportPlan;
  IssueIndex: Integer;
begin
  if FTranslationCatalog = nil then
  begin
    lblStatus.Text := 'Scan a project or open a catalog first.';
    Exit;
  end;
  if not dlgImportCatalogCsv.Execute then
    Exit;
  ImportPlan := nil;
  try
    try
      ImportPlan := TCatalogCsv.AnalyzeImport(FTranslationCatalog,
        dlgImportCatalogCsv.FileName);
      ConfirmationText := ImportPlan.Summary;
      if ImportPlan.Issues.Count > 0 then
      begin
        ConfirmationText := ConfirmationText + sLineBreak + sLineBreak +
          'Import issues:';
        for IssueIndex := 0 to
          Min(ImportPlan.Issues.Count - 1, 7) do
          ConfirmationText := ConfirmationText + sLineBreak +
            ImportPlan.Issues[IssueIndex];
        if ImportPlan.Issues.Count > 8 then
          ConfirmationText := ConfirmationText + sLineBreak +
            Format('...and %d more issue(s).',
              [ImportPlan.Issues.Count - 8]);
      end;
      ConfirmationText := ConfirmationText + sLineBreak + sLineBreak +
        'Apply the staged translations?';
      if TDialogServiceSync.MessageDialog(ConfirmationText,
        TMsgDlgType.mtConfirmation,
        [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
        TMsgDlgBtn.mbNo, 0) <> mrYes then
      begin
        lblStatus.Text := 'CSV import canceled. ' +
          StringReplace(ImportPlan.Summary, sLineBreak, ' | ',
            [rfReplaceAll]);
        Exit;
      end;
      ImportPlan.Apply;
      InvalidateValidation;
      DisplayCatalogEntries;
      if FCatalogFileName <> '' then
        SaveCatalog;
      lblStatus.Text := 'CSV import complete. ' +
        StringReplace(ImportPlan.Summary, sLineBreak, ' | ',
          [rfReplaceAll]);
    except
      on E: Exception do
        lblStatus.Text := 'Unable to import CSV: ' + E.Message;
    end;
  finally
    ImportPlan.Free;
  end;
end;

procedure TfrmTranslationStudio.lstCatalogEntriesChange(Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
    (lstCatalogEntries.ItemIndex < 0) or
    (lstCatalogEntries.ItemIndex >= FTranslationCatalog.Entries.Count) then
    Exit;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  FUpdatingEntryControls := True;
  try
    memSourceText.Text := Entry.SourceText;
    memTranslatedText.Text := Entry.TranslatedText;
    lblRuntimeApplicationValue.Text := 'Runtime: ' +
      RuntimeApplicationKindToString(Entry.RuntimeApplication) +
      ' | Role: ' + RuntimeTextRoleDisplayName(Entry.RuntimeTextRole) +
      ' | Ownership: ' + TextOwnershipDisplayName(Entry.TextOwnership) +
      ' | Origin: ' +
      TranslationOriginDisplayName(Entry.TranslationOrigin);
    lblTranslationContextValue.Text := 'Context: ' + Entry.ContextKind;
    lblTranslationContextValue.Hint := Entry.ContextDescription +
      IfThen(Entry.SemanticConcept <> '', sLineBreak + 'Concept: ' +
        Entry.SemanticConcept, '') + sLineBreak + 'Confidence: ' +
        Entry.ContextConfidence;
    chkRuntimeWiringConfirmed.Enabled :=
      Entry.RuntimeApplication = rakManualTranslateText;
    chkRuntimeWiringConfirmed.IsChecked :=
      Entry.RuntimeWiringConfirmed;
    btnMarkTranslationReviewed.Enabled :=
      (Trim(Entry.TranslatedText) <> '') and
      not (Entry.Status in [tsExcluded, tsObsolete, tsApproved]);
    btnApproveTranslation.Enabled := Entry.Status = tsReviewed;
    UpdateTranslationSuggestions(Entry);
  finally
    FUpdatingEntryControls := False;
  end;
end;

procedure TfrmTranslationStudio.btnApplyTranslationClick(Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
    (lstCatalogEntries.ItemIndex < 0) then
  begin
    lblStatus.Text := 'Select a catalog entry first.';
    Exit;
  end;

  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  Entry.TranslatedText := memTranslatedText.Text;
  if Trim(Entry.TranslatedText) = '' then
    Entry.Status := tsNeedsTranslation
  else
    Entry.Status := tsEdited;
  Entry.TranslationOrigin := torHuman;
  Entry.TranslationConfidence := '';
  Entry.TranslationReviewNote := '';
  lstCatalogEntries.Items[lstCatalogEntries.ItemIndex] :=
    Entry.Key + '  [' + TranslationStatusToString(Entry.Status) + ']';
  btnMarkTranslationReviewed.Enabled :=
    Trim(Entry.TranslatedText) <> '';
  btnApproveTranslation.Enabled := False;
  UpdateTranslationSuggestions(Entry);
  InvalidateValidation;
  UpdateCatalogReadiness;
  try
    if FCatalogFileName <> '' then
      SaveCatalog;
    lblStatus.Text := 'Translation applied.';
  except
    on E: Exception do
      lblStatus.Text := 'Translation applied but not saved: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.chkRuntimeWiringConfirmedChange(
  Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if FUpdatingEntryControls or (FTranslationCatalog = nil) or
     (lstCatalogEntries.ItemIndex < 0) then
    Exit;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  if Entry.RuntimeApplication <> rakManualTranslateText then
    Exit;
  Entry.RuntimeWiringConfirmed :=
    chkRuntimeWiringConfirmed.IsChecked;
  InvalidateValidation;
  UpdateCatalogReadiness;
  if FCatalogFileName <> '' then
    SaveCatalog;
end;

procedure TfrmTranslationStudio.btnAcceptSuggestionClick(Sender: TObject);
var
  Entry: TTranslationEntry;
  SuggestedEntry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
     (lstCatalogEntries.ItemIndex < 0) or
     (cboTranslationSuggestions.ItemIndex < 0) then
    Exit;
  SuggestedEntry := TTranslationEntry(
    cboTranslationSuggestions.Items.Objects[
      cboTranslationSuggestions.ItemIndex]);
  if SuggestedEntry = nil then
    Exit;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  Entry.TranslatedText := SuggestedEntry.TranslatedText;
  Entry.Status := tsEdited;
  Entry.TranslationOrigin := torSuggestion;
  Entry.TranslationConfidence := '';
  Entry.TranslationReviewNote := '';
  memTranslatedText.Text := Entry.TranslatedText;
  lstCatalogEntries.Items[lstCatalogEntries.ItemIndex] :=
    Entry.Key + '  [' + TranslationStatusToString(Entry.Status) + ']';
  btnMarkTranslationReviewed.Enabled := True;
  btnApproveTranslation.Enabled := False;
  InvalidateValidation;
  UpdateCatalogReadiness;
  UpdateTranslationSuggestions(Entry);
  lblStatus.Text := 'Translation suggestion accepted for review.';
  if FCatalogFileName <> '' then
    SaveCatalog;
end;

procedure TfrmTranslationStudio.btnMarkTranslationReviewedClick(
  Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
     (lstCatalogEntries.ItemIndex < 0) then
  begin
    lblStatus.Text := 'Select a translated catalog entry first.';
    Exit;
  end;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  if Trim(Entry.TranslatedText) = '' then
  begin
    lblStatus.Text := 'A blank translation cannot be marked reviewed.';
    Exit;
  end;
  Entry.Status := tsReviewed;
  lstCatalogEntries.Items[lstCatalogEntries.ItemIndex] :=
    Entry.Key + '  [' + TranslationStatusToString(Entry.Status) + ']';
  btnMarkTranslationReviewed.Enabled := False;
  btnApproveTranslation.Enabled := True;
  InvalidateValidation;
  UpdateCatalogReadiness;
  UpdateTranslationSuggestions(Entry);
  if FCatalogFileName <> '' then
    SaveCatalog;
  lblStatus.Text :=
    'Translation marked linguistically reviewed. Approval remains separate.';
end;

procedure TfrmTranslationStudio.btnApproveTranslationClick(Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
     (lstCatalogEntries.ItemIndex < 0) then
  begin
    lblStatus.Text := 'Select a reviewed catalog entry first.';
    Exit;
  end;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  if Entry.Status <> tsReviewed then
  begin
    lblStatus.Text :=
      'Mark the translation Reviewed before granting final approval.';
    Exit;
  end;
  Entry.Status := tsApproved;
  lstCatalogEntries.Items[lstCatalogEntries.ItemIndex] :=
    Entry.Key + '  [' + TranslationStatusToString(Entry.Status) + ']';
  btnMarkTranslationReviewed.Enabled := False;
  btnApproveTranslation.Enabled := False;
  InvalidateValidation;
  UpdateCatalogReadiness;
  UpdateTranslationSuggestions(Entry);
  if FCatalogFileName <> '' then
    SaveCatalog;
  lblStatus.Text := 'Translation approved.';
end;

procedure TfrmTranslationStudio.btnReviewAllTranslationsClick(Sender: TObject);
var
  EligibleCount: Integer;
  Entry: TTranslationEntry;
begin
  if FTranslationCatalog = nil then
  begin
    lblStatus.Text := 'Open or create a catalog first.';
    Exit;
  end;
  EligibleCount := 0;
  for Entry in FTranslationCatalog.Entries do
    if (Trim(Entry.TranslatedText) <> '') and
       not (Entry.Status in [tsReviewed, tsApproved, tsExcluded,
         tsObsolete]) then
      Inc(EligibleCount);
  if EligibleCount = 0 then
  begin
    lblStatus.Text := 'No translated drafts are waiting for review.';
    Exit;
  end;
  if TDialogServiceSync.MessageDialog(Format(
    'Mark all %d translated drafts as Reviewed? This records one catalog-wide review decision; it does not change any translated text.',
    [EligibleCount]), TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0) <> mrYes then
    Exit;
  for Entry in FTranslationCatalog.Entries do
    if (Trim(Entry.TranslatedText) <> '') and
       not (Entry.Status in [tsReviewed, tsApproved, tsExcluded,
         tsObsolete]) then
      Entry.Status := tsReviewed;
  InvalidateValidation;
  DisplayCatalogEntries;
  if FCatalogFileName <> '' then
    SaveCatalog;
  lblStatus.Text := Format('%d translated drafts marked Reviewed.',
    [EligibleCount]);
end;

procedure TfrmTranslationStudio.btnApproveAllReviewedClick(Sender: TObject);
var
  ApprovedCount: Integer;
  Entry: TTranslationEntry;
begin
  if FTranslationCatalog = nil then
  begin
    lblStatus.Text := 'Open or create a catalog first.';
    Exit;
  end;
  ApprovedCount := 0;
  for Entry in FTranslationCatalog.Entries do
    if Entry.Status = tsReviewed then
      Inc(ApprovedCount);
  if ApprovedCount = 0 then
  begin
    lblStatus.Text := 'No Reviewed translations are waiting for approval.';
    Exit;
  end;
  if TDialogServiceSync.MessageDialog(Format(
    'Approve all %d Reviewed translations for runtime export?',
    [ApprovedCount]), TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0) <> mrYes then
    Exit;
  for Entry in FTranslationCatalog.Entries do
    if Entry.Status = tsReviewed then
      Entry.Status := tsApproved;
  InvalidateValidation;
  DisplayCatalogEntries;
  if FCatalogFileName <> '' then
    SaveCatalog;
  lblStatus.Text := Format('%d Reviewed translations approved.',
    [ApprovedCount]);
end;

procedure TfrmTranslationStudio.btnTranslateMissingClick(Sender: TObject);
var
  ActiveCount: Integer;
  ApiKey: string;
  Client: TTranslationProviderClient;
  Entry: TTranslationEntry;
  EntryIndexes: TArray<Integer>;
  Index: Integer;
  MissingCount: Integer;
  ProtectedCount: Integer;
  SuspiciousCount: Integer;
  Provider: TTranslationProvider;
  ResolvedCount: Integer;
  SourceTexts: TArray<string>;
  TranslatedTexts: TArray<string>;
  Contexts: TArray<string>;
  ProviderCount: Integer;
  ResolvedText: string;
begin
  if FTranslationCatalog = nil then
  begin
    lblStatus.Text := 'Scan a project or open a catalog first.';
    Exit;
  end;
  try
    UpdateCatalogFromLanguageEditors;
    SaveProviderSettings;
    Provider := FProviderSettings.Provider;
    ApiKey := EffectiveApiKey(Provider);
    if ApiKey = '' then
    begin
      SetWorkflowStep(7);
      lblStatus.Text := Format(
        'Add and test a %s API key before translating.',
        [TranslationProviderDisplayName(Provider)]);
      Exit;
    end;
    ActiveCount := 0;
    TTerminologyResolver.ApplyAuthoritativeTerms(FTranslationCatalog);
    MissingCount := 0;
    ProtectedCount := 0;
    SuspiciousCount := 0;
    ResolvedCount := 0;
    for Entry in FTranslationCatalog.Entries do
    begin
      if Entry.Status = tsObsolete then
        Continue;
      Inc(ActiveCount);
      if Entry.TextOwnership = tokSuspicious then
      begin
        Inc(ProtectedCount);
        Inc(SuspiciousCount);
      end
      else if (Entry.Status = tsExcluded) or
         not TranslationEntryEligibleForAutomaticTranslation(Entry) then
        Inc(ProtectedCount)
      else if not (Entry.Status in [tsReviewed, tsApproved]) and
              ((Trim(Entry.TranslatedText) = '') or
               (Entry.Status in [tsNeedsTranslation, tsSourceChanged,
                 tsError])) then
        Inc(MissingCount)
      else
        Inc(ResolvedCount);
    end;
    if MissingCount = 0 then
    begin
      SaveCatalog;
      DisplayCatalogEntries;
      lblStatus.Text := 'No missing translations were found.';
      Exit;
    end;
    if TDialogServiceSync.MessageDialog(Format(
      'The catalog contains %d active entries: %d require translation, %d are protected or non-translatable (%d suspicious source strings require developer review), and %d are already resolved.' + sLineBreak + sLineBreak +
      'Send the %d unresolved source strings to %s? Reviewed and approved entries will remain unchanged. Results are saved automatically and marked Machine translated for review.',
      [ActiveCount, MissingCount, ProtectedCount, SuspiciousCount, ResolvedCount, MissingCount,
       TranslationProviderDisplayName(Provider)]),
      TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0) <> mrYes then
      Exit;

    SetLength(EntryIndexes, MissingCount);
    SetLength(SourceTexts, MissingCount);
    SetLength(Contexts, MissingCount);
    ProviderCount := 0;
    for Index := 0 to FTranslationCatalog.Entries.Count - 1 do
    begin
      Entry := FTranslationCatalog.Entries[Index];
      if not (Entry.Status in [tsExcluded, tsObsolete,
        tsReviewed, tsApproved]) and
         TranslationEntryEligibleForAutomaticTranslation(Entry) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged,
            tsError])) then
      begin
        if TTerminologyResolver.TryTranslationMemory(FTranslationCatalog,
          Entry, ResolvedText) then
        begin
          Entry.TranslatedText := ResolvedText;
          Entry.Status := tsMachineTranslated;
          Entry.TranslationOrigin := torSuggestion;
          Entry.TranslationConfidence := 'translation-memory';
          Entry.TranslationReviewNote :=
            'Reused from a reviewed or approved entry with matching context.';
        end
        else if TTerminologyResolver.TryResolve(Entry,
          FTranslationCatalog.Locale.LanguageCode, ResolvedText) then
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

    btnTranslateMissing.Enabled := False;
    lblStatus.Text := Format('Translating %d provider strings with %s...',
      [ProviderCount, TranslationProviderDisplayName(Provider)]);
    Application.ProcessMessages;
    Client := TTranslationProviderClient.Create(Provider,
      FProviderSettings.DeepLPlan, ApiKey,
      FProviderSettings.RequestTimeoutSeconds,
      FProviderSettings.BatchSize);
    try
      TranslatedTexts := Client.TranslateWithContexts(SourceTexts, Contexts,
        FTranslationCatalog.SourceLanguage,
        FTranslationCatalog.Locale.LanguageCode);
    finally
      Client.Free;
    end;
    for Index := 0 to High(TranslatedTexts) do
    begin
      Entry := FTranslationCatalog.Entries[EntryIndexes[Index]];
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
            'Short or ambiguous text translated by Google Basic without provider-side context; review recommended.'
        else
          Entry.TranslationReviewNote := '';
      end
      else
      begin
        Entry.TranslationConfidence := 'contextual-provider';
        Entry.TranslationReviewNote := '';
      end;
    end;
    TTerminologyResolver.ApplyAuthoritativeTerms(FTranslationCatalog);
    DisplayCatalogEntries;
    InvalidateValidation;
    SaveCatalog;
    lblStatus.Text := Format(
      '%d entries resolved and saved; %d were sent to the provider. Review flagged ambiguous results before export.',
      [MissingCount, Length(TranslatedTexts)]);
  except
    on E: Exception do
      lblStatus.Text := 'Bulk translation failed: ' + E.Message;
  end;
  btnTranslateMissing.Enabled := True;
end;

procedure TfrmTranslationStudio.btnValidateCatalogClick(Sender: TObject);
begin
  try
    RunCatalogValidation;
    if FValidationResult.HasErrors then
      lblStatus.Text := 'Validation found errors that block export.'
    else
      lblStatus.Text := 'Validation passed. The runtime pack is ready.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to validate catalog: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnExportRuntimePackClick(Sender: TObject);
var
  Entry: TTranslationEntry;
  Item: TScanItem;
  RuntimeEntryCount: Integer;
  RuntimeFileName: string;
begin
  try
    if FScanResult = nil then
      raise Exception.Create(
        'Scan the open project before exporting. This confirms that the catalog matches the saved Delphi forms and source files.');
    for Item in FScanResult.Items do
      if TFile.Exists(Item.SourceFileName) and
         (TFile.GetLastWriteTime(Item.SourceFileName) >
          FLastScanCompletedAt) then
        raise Exception.CreateFmt(
          'The source file "%s" was saved after the last scan. Save all files in Delphi, scan the project again, translate any new entries, and then export.',
          [Item.SourceFileName]);
    SaveCatalog;
    RunCatalogValidation;
    if FValidationResult.HasErrors then
    begin
      SetWorkflowStep(4);
      lblStatus.Text := 'Export is blocked by validation errors.';
      Exit;
    end;

    RuntimeFileName := TTranslationWorkspace.RuntimePackFileName(
      FProjectProfile, FTranslationCatalog.Locale.LanguageCode);
    TRuntimePackBuilder.ExportToFile(FTranslationCatalog, RuntimeFileName,
      TPath.Combine(FindStudioProjectRoot,
        TPath.Combine('export\localization-review',
          TPath.Combine(FProjectProfile.ProjectName,
            TPath.Combine(FTranslationCatalog.Locale.LanguageCode,
              'layout-proposal.json')))));
    lblExportPathValue.Text := RuntimeFileName;
    RuntimeEntryCount := 0;
    for Entry in FTranslationCatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
         not (Entry.Status in [tsExcluded, tsObsolete]) then
        Inc(RuntimeEntryCount);
    lblExportSummary.Text := Format(
      '%d runtime entries exported successfully.',
      [RuntimeEntryCount]);
    lblStatus.Text := 'Offline runtime language pack created.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to export runtime pack: ' + E.Message;
  end;
end;

end.

