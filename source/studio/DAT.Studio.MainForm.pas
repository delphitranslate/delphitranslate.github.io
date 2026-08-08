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
  DAT.Integration.Reset,
  DAT.Integration.Types,
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
    ProjectCard: TRectangle;
    lblProjectCardTitle: TLabel;
    lblProjectCardDescription: TLabel;
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
    lblSourceTextEditor: TLabel;
    lblRuntimeApplicationValue: TLabel;
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
    procedure btnOpenProjectClick(Sender: TObject);
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
    procedure cboTargetLanguageChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure datLanguageMenuItemClick(Sender: TObject);
  private
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    FTranslationCatalog: TTranslationCatalog;
    FValidationResult: TCatalogValidationResult;
    FIntegrationChangeSet: TIntegrationChangeSet;
    FIntegrationPackageDirectory: string;
    FLastIntegrationBackupDirectory: string;
    FCompleteResetPlan: TCompleteResetPlan;
    FCatalogFileName: string;
    FProviderSettings: TProviderSettings;
    FSessionApiKeys: array[TTranslationProvider] of string;
    FUpdatingEntryControls: Boolean;
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
  System.IOUtils,
  System.Math,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  FMX.DialogService.Sync,
  DAT.Core.CatalogJson,
  DAT.Core.ProjectDetection,
  DAT.Core.RuntimePack,
  DAT.Core.TranslationWorkspace,
  DAT.Integration.Package,
  DAT.Integration.BuildDeploy,
  DAT.Integration.Plan,
  DAT.Integration.Engine,
  DAT.Integration.Transaction,
  DAT.Provider.Client,
  DAT.Provider.CredentialStore,
  DAT.Runtime.LanguagePack,
  DAT.Studio.Translation,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project;

{$R *.fmx}

procedure TfrmTranslationStudio.FormCreate(Sender: TObject);
begin
  ApplyStudioTranslation(Self);
  SelectLanguageCode(cboSourceLanguage, 'en-US');
  cboTextDirection.ItemIndex := 0;
  cboBuildPlatform.ItemIndex := 0;
  cboBuildConfiguration.ItemIndex := 0;
  LoadProviderSettings;
  SetWorkflowStep(1);
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
  FreeAndNil(FIntegrationChangeSet);
  FreeAndNil(FCompleteResetPlan);
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
  lblScanSummaryValue.Text := 'No scan has been run';
  lblScanBreakdown.Text :=
    'Open a project, then scan its forms and resourcestrings.';
  lstScanResults.Items.Clear;
end;

destructor TfrmTranslationStudio.Destroy;
begin
  FProviderSettings.Free;
  FValidationResult.Free;
  FIntegrationChangeSet.Free;
  FCompleteResetPlan.Free;
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
  NativeSeparator: Integer;
  OpeningBracket: Integer;
begin
  LanguageCode := SelectedLanguageCode(cboTargetLanguage);
  if LanguageCode = '' then
    Exit;
  DisplayText := cboTargetLanguage.Items[cboTargetLanguage.ItemIndex];
  NativeSeparator := DisplayText.IndexOf(' / ');
  OpeningBracket := DisplayText.LastIndexOf('[');
  if (NativeSeparator >= 0) and (OpeningBracket > NativeSeparator) then
    edtNativeLanguageName.Text := Trim(Copy(DisplayText,
      NativeSeparator + 4, OpeningBracket - NativeSeparator - 4));
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
  Change: TIntegrationFileChange;
  Index: Integer;
begin
  if FCompleteResetPlan <> nil then
  begin
    memIntegrationDiff.Lines.Assign(FCompleteResetPlan.PreviewLines);
    memIntegrationDiff.GoToTextBegin;
    Exit;
  end;
  if (FIntegrationChangeSet = nil) or
     (lstIntegrationPlan.ItemIndex < 0) or
     (lstIntegrationPlan.ItemIndex >=
      FIntegrationChangeSet.Changes.Count) then
  begin
    memIntegrationDiff.Text :=
      'Select a changed file to review its exact original and proposed text.';
    Exit;
  end;

  Index := lstIntegrationPlan.ItemIndex;
  Change := FIntegrationChangeSet.Changes[Index];
  memIntegrationDiff.Text := Change.ExactReviewText;
  memIntegrationDiff.GoToTextBegin;
end;

procedure TfrmTranslationStudio.UpdateIntegrationApplyState;
begin
  if FCompleteResetPlan <> nil then
  begin
    chkIntegrationReviewConfirmed.Enabled := True;
    btnApplyIntegration.Enabled :=
      chkIntegrationReviewConfirmed.IsChecked;
    lblIntegrationDiffTitle.Text :=
      'Complete reset preview — one confirmation required';
    Exit;
  end;
  chkIntegrationReviewConfirmed.Enabled :=
    (FIntegrationChangeSet <> nil) and
    (FIntegrationChangeSet.Changes.Count > 0);
  btnApplyIntegration.Enabled := chkIntegrationReviewConfirmed.Enabled and
    chkIntegrationReviewConfirmed.IsChecked;
  if FIntegrationChangeSet <> nil then
    lblIntegrationDiffTitle.Text :=
      'Optional exact-change preview — select any file to inspect'
  else
    lblIntegrationDiffTitle.Text := 'Exact changes';
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
  btnCompleteReset.Enabled := AProfile.Framework <> tfUnknown;
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
  ScanItem: TScanItem;
begin
  lblScanSummaryValue.Text := Format('%d translatable entries in %d ms',
    [AResult.Items.Count, AResult.ElapsedMilliseconds]);
  lblScanBreakdown.Text := Format(
    '%d form properties  |  %d resourcestrings  |  %d files',
    [AResult.CountByKind(stkFormProperty),
     AResult.CountByKind(stkResourceString), AResult.FilesScanned]);

  lstScanResults.BeginUpdate;
  try
    lstScanResults.Items.Clear;
    for ScanItem in AResult.Items do
      lstScanResults.Items.Add(Format('%s  =  %s',
        [ScanItem.Key, ScanItem.SourceText]));
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
      if not (Entry.Status in [tsExcluded, tsObsolete]) then
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
        Candidate.TranslatedText + '  —  ' + Candidate.Key, Candidate);
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
  Issue: TValidationIssue;
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
    '%d errors  |  %d warnings  |  %d information messages',
    [FValidationResult.CountBySeverity(vsError),
     FValidationResult.CountBySeverity(vsWarning),
     FValidationResult.CountBySeverity(vsInformation)]);
  btnExportRuntimePack.Enabled := not FValidationResult.HasErrors;
  if FValidationResult.HasErrors then
    lblExportSummary.Text := 'Export is blocked by validation errors.'
  else
    lblExportSummary.Text := Format(
      '%d translated entries are ready for offline export.',
      [FTranslationCatalog.Entries.Count]);
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
      end;
    2:
      begin
        NavigationSelection.Position.Y := 128;
        lblNavigationScan.TextSettings.FontColor := ActiveColor;
      end;
    3:
      begin
        NavigationSelection.Position.Y := 184;
        lblNavigationLanguages.TextSettings.FontColor := ActiveColor;
        LanguagePageCard.BringToFront;
      end;
    4:
      begin
        NavigationSelection.Position.Y := 240;
        lblNavigationValidation.TextSettings.FontColor := ActiveColor;
        ValidationPageCard.BringToFront;
      end;
    5:
      begin
        NavigationSelection.Position.Y := 296;
        lblNavigationExport.TextSettings.FontColor := ActiveColor;
        ExportPageCard.BringToFront;
      end;
    6:
      begin
        NavigationSelection.Position.Y := 352;
        lblNavigationIntegration.TextSettings.FontColor := ActiveColor;
        IntegrationPageCard.BringToFront;
      end;
    7:
      begin
        NavigationSelection.Position.Y := 408;
        lblNavigationSettings.TextSettings.FontColor := ActiveColor;
        SettingsPageCard.BringToFront;
        UpdateCredentialStatus;
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
  IntegrationPlan: TIntegrationPlan;
begin
  FreeAndNil(FCompleteResetPlan);
  btnApplyIntegration.Text := 'Apply';
  chkIntegrationReviewConfirmed.Text :=
    'I authorize the backed-up, transactional integration changes';
  chkIntegrationReviewConfirmed.IsChecked := False;
  chkIntegrationReviewConfirmed.Enabled := False;
  btnApplyIntegration.Enabled := False;
  btnRestoreIntegration.Enabled :=
    FLastIntegrationBackupDirectory <> '';
  try
    IntegrationPlan := TIntegrationPlanner.Build(
      FProjectProfile, edtLanguageMenuName.Text);
    try
      lstIntegrationPlan.Items.Assign(IntegrationPlan.Lines);
      if IntegrationPlan.MenuFound then
        lblIntegrationSummary.Text := Format(
          '%d language pack(s) found. Existing designer menu will be populated.',
          [IntegrationPlan.LanguageCount])
      else
        lblIntegrationSummary.Text := Format(
          '%d language pack(s) found. A designer menu will be added to the primary form.',
          [IntegrationPlan.LanguageCount]);
      btnGenerateIntegrationPackage.Enabled := True;
      lblStatus.Text :=
        'Integration plan ready. No target source files were changed.';
    finally
      IntegrationPlan.Free;
    end;
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

procedure TfrmTranslationStudio.btnGenerateIntegrationPackageClick(
  Sender: TObject);
var
  Change: TIntegrationFileChange;
  OutputDirectory: string;
  StudioProjectRoot: string;
begin
  try
    FreeAndNil(FCompleteResetPlan);
    btnApplyIntegration.Text := 'Apply';
    chkIntegrationReviewConfirmed.Text :=
      'I authorize the backed-up, transactional integration changes';
    StudioProjectRoot := FindStudioProjectRoot;
    OutputDirectory := TIntegrationPackageGenerator.Generate(
      FProjectProfile,
      TPath.Combine(StudioProjectRoot, 'export\integration'),
      TPath.Combine(StudioProjectRoot, 'source\runtime'));
    FIntegrationPackageDirectory := OutputDirectory;
    FreeAndNil(FIntegrationChangeSet);
    FIntegrationChangeSet := TTargetIntegrationEngine.BuildChangeSet(
      FProjectProfile, FIntegrationPackageDirectory,
      edtLanguageMenuName.Text);
    chkIntegrationReviewConfirmed.IsChecked := False;
    chkIntegrationReviewConfirmed.Enabled :=
      FIntegrationChangeSet.Changes.Count > 0;
    btnApplyIntegration.Enabled := False;
    lstIntegrationPlan.Items.Clear;
    for Change in FIntegrationChangeSet.Changes do
      lstIntegrationPlan.Items.Add(Format('%s  |  %s',
        [IntegrationChangeKindDisplayName(Change.Kind),
         Change.TargetFileName]));
    if lstIntegrationPlan.Items.Count > 0 then
    begin
      lstIntegrationPlan.ItemIndex := 0;
      DisplaySelectedIntegrationChange;
    end
    else
      memIntegrationDiff.Text := 'No target file changes are required.';
    lblIntegrationOutput.Text := OutputDirectory;
    lblIntegrationSummary.Text := Format(
      '%d target file change(s) are ready. Exact review is optional.',
      [FIntegrationChangeSet.Changes.Count]);
    lblStatus.Text :=
      'Integration preview ready. Confirm once to enable Apply.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to generate integration package: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnApplyIntegrationClick(Sender: TObject);
var
  ApplyResult: TIntegrationApplyResult;
  BuildMessage: string;
  SafetyBackupDirectory: string;
begin
  if FCompleteResetPlan <> nil then
  begin
    if not chkIntegrationReviewConfirmed.IsChecked then
    begin
      lblStatus.Text :=
        'Review the reset preview and confirm before continuing.';
      Exit;
    end;
    if TDialogServiceSync.MessageDialog(
      'Complete Reset will restore the original pre-integration source and ' +
      'remove the Development, Languages, and Runtime translation folders. ' +
      'A new verified safety backup will be created first. Continue?',
      TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0) <> mrYes then
      Exit;
    btnApplyIntegration.Enabled := False;
    btnCompleteReset.Enabled := False;
    try
      TCompleteResetEngine.Execute(FCompleteResetPlan);
      SafetyBackupDirectory :=
        FCompleteResetPlan.SafetyBackupDirectory;
      FreeAndNil(FIntegrationChangeSet);
      FIntegrationPackageDirectory := '';
      FLastIntegrationBackupDirectory := '';
      ClearScanSummary;
      ResetCatalog;
      lstIntegrationPlan.Items.Clear;
      memIntegrationDiff.Text :=
        'Complete Reset finished. Scan the project to begin again.';
      lblIntegrationSummary.Text :=
        'The target is back at its pre-translation state.';
      lblIntegrationOutput.Text :=
        'Pre-reset safety backup: ' + SafetyBackupDirectory;
      chkIntegrationReviewConfirmed.IsChecked := False;
      chkIntegrationReviewConfirmed.Enabled := False;
      chkIntegrationReviewConfirmed.Text :=
        'I authorize the backed-up, transactional integration changes';
      btnApplyIntegration.Text := 'Apply';
      btnGenerateIntegrationPackage.Enabled := False;
      btnRestoreIntegration.Enabled := False;
      btnCompleteReset.Enabled := True;
      FreeAndNil(FCompleteResetPlan);
      lblStatus.Text :=
        'Complete Reset succeeded. The safety backup was retained.';
    except
      on E: Exception do
      begin
        btnCompleteReset.Enabled := True;
        UpdateIntegrationApplyState;
        lblStatus.Text := 'Complete Reset failed safely: ' + E.Message;
      end;
    end;
    Exit;
  end;
  if FIntegrationChangeSet = nil then
  begin
    lblStatus.Text := 'Generate an integration package first.';
    Exit;
  end;
  if not chkIntegrationReviewConfirmed.IsChecked then
  begin
    lblStatus.Text :=
      'Confirm authorization before Apply.';
    Exit;
  end;
  btnApplyIntegration.Enabled := False;
  try
    ApplyResult := TIntegrationTransaction.Apply(FIntegrationChangeSet);
    try
      FLastIntegrationBackupDirectory := ApplyResult.BackupDirectory;
      lblIntegrationOutput.Text := Format(
        '%d files written. Backup: %s',
        [ApplyResult.FilesWritten, ApplyResult.BackupDirectory]);
      lblStatus.Text :=
        'Target integration completed. Reopen and build the target project.';
      btnRestoreIntegration.Enabled := True;
      if chkBuildAfterIntegration.IsChecked then
      begin
        try
          BuildMessage := TTargetBuildDeployer.BuildAndDeploy(
            FProjectProfile.ProjectFileName,
            FProjectProfile.ProjectName,
            cboBuildPlatform.Selected.Text,
            cboBuildConfiguration.Selected.Text,
            FIntegrationPackageDirectory);
          lblStatus.Text := BuildMessage + ' The application was not launched.';
        except
          on E: Exception do
            lblStatus.Text :=
              'Integration succeeded, but automatic build/deploy failed: ' +
              E.Message;
        end;
      end;
    finally
      ApplyResult.Free;
    end;
  except
    on E: Exception do
    begin
      UpdateIntegrationApplyState;
      lblStatus.Text := 'Integration failed and was rolled back: ' + E.Message;
    end;
  end;
end;

procedure TfrmTranslationStudio.btnCompleteResetClick(Sender: TObject);
var
  ProjectDirectory: string;
begin
  if FProjectProfile.ProjectFileName = '' then
  begin
    lblStatus.Text := 'Open the Delphi project to reset first.';
    Exit;
  end;
  btnCompleteReset.Enabled := False;
  try
    ProjectDirectory := TPath.GetDirectoryName(
      FProjectProfile.ProjectFileName);
    FreeAndNil(FCompleteResetPlan);
    FCompleteResetPlan := TCompleteResetEngine.BuildPlan(
      FProjectProfile.ProjectName, ProjectDirectory);
    FreeAndNil(FIntegrationChangeSet);
    lstIntegrationPlan.Items.Assign(FCompleteResetPlan.PreviewLines);
    memIntegrationDiff.Lines.Assign(FCompleteResetPlan.PreviewLines);
    memIntegrationDiff.GoToTextBegin;
    lblIntegrationSummary.Text :=
      'Complete Reset is ready. No project files have changed.';
    lblIntegrationOutput.Text := 'Original baseline: ' +
      FCompleteResetPlan.BaselineBackupDirectory;
    chkIntegrationReviewConfirmed.IsChecked := False;
    chkIntegrationReviewConfirmed.Text :=
      'I reviewed this reset plan and authorize Complete Reset';
    chkIntegrationReviewConfirmed.Enabled := True;
    btnApplyIntegration.Text := 'Reset Project';
    btnApplyIntegration.Enabled := False;
    btnRestoreIntegration.Enabled := False;
    lblIntegrationDiffTitle.Text :=
      'Complete reset preview — one confirmation required';
    lblStatus.Text :=
      'Reset preview ready. One confirmation enables Reset Project.';
  except
    on E: Exception do
    begin
      FreeAndNil(FCompleteResetPlan);
      lblStatus.Text := 'Unable to prepare Complete Reset: ' + E.Message;
    end;
  end;
  btnCompleteReset.Enabled := True;
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
  if FLastIntegrationBackupDirectory = '' then
  begin
    lblStatus.Text := 'No integration backup is available in this session.';
    Exit;
  end;
  try
    TIntegrationTransaction.Restore(
      TPath.GetDirectoryName(FProjectProfile.ProjectFileName),
      FLastIntegrationBackupDirectory);
    btnRestoreIntegration.Enabled := False;
    btnApplyIntegration.Enabled := False;
    chkIntegrationReviewConfirmed.IsChecked := False;
    chkIntegrationReviewConfirmed.Enabled := False;
    lblStatus.Text := 'The target project was restored from its backup.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to restore integration backup: ' + E.Message;
  end;
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
      ' | Origin: ' +
      TranslationOriginDisplayName(Entry.TranslationOrigin);
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

procedure TfrmTranslationStudio.btnTranslateMissingClick(Sender: TObject);
var
  ApiKey: string;
  Client: TTranslationProviderClient;
  Entry: TTranslationEntry;
  EntryIndexes: TArray<Integer>;
  Index: Integer;
  MissingCount: Integer;
  Provider: TTranslationProvider;
  SourceTexts: TArray<string>;
  TranslatedTexts: TArray<string>;
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
    MissingCount := 0;
    for Entry in FTranslationCatalog.Entries do
      if not (Entry.Status in [tsExcluded, tsObsolete,
        tsReviewed, tsApproved]) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged,
            tsError])) then
        Inc(MissingCount);
    if MissingCount = 0 then
    begin
      lblStatus.Text := 'No missing translations were found.';
      Exit;
    end;
    if TDialogServiceSync.MessageDialog(Format(
      'Send %d unresolved source strings to %s? Reviewed and approved entries will remain unchanged. Results are saved automatically and marked Machine translated for review.',
      [MissingCount, TranslationProviderDisplayName(Provider)]),
      TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0) <> mrYes then
      Exit;

    SetLength(EntryIndexes, MissingCount);
    SetLength(SourceTexts, MissingCount);
    MissingCount := 0;
    for Index := 0 to FTranslationCatalog.Entries.Count - 1 do
    begin
      Entry := FTranslationCatalog.Entries[Index];
      if not (Entry.Status in [tsExcluded, tsObsolete,
        tsReviewed, tsApproved]) and
         ((Trim(Entry.TranslatedText) = '') or
          (Entry.Status in [tsNeedsTranslation, tsSourceChanged,
            tsError])) then
      begin
        EntryIndexes[MissingCount] := Index;
        SourceTexts[MissingCount] := Entry.SourceText;
        Inc(MissingCount);
      end;
    end;

    btnTranslateMissing.Enabled := False;
    lblStatus.Text := Format('Translating %d strings with %s...',
      [MissingCount, TranslationProviderDisplayName(Provider)]);
    Application.ProcessMessages;
    Client := TTranslationProviderClient.Create(Provider,
      FProviderSettings.DeepLPlan, ApiKey,
      FProviderSettings.RequestTimeoutSeconds,
      FProviderSettings.BatchSize);
    try
      TranslatedTexts := Client.Translate(SourceTexts,
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
      Entry.TranslationConfidence := '';
      Entry.TranslationReviewNote := '';
    end;
    DisplayCatalogEntries;
    InvalidateValidation;
    SaveCatalog;
    lblStatus.Text := Format(
      '%d machine translations recorded and saved. Review provider results before export.',
      [Length(TranslatedTexts)]);
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
  RuntimeFileName: string;
begin
  try
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
    TRuntimePackBuilder.ExportToFile(FTranslationCatalog, RuntimeFileName);
    lblExportPathValue.Text := RuntimeFileName;
    lblExportSummary.Text := Format(
      '%d entries exported successfully.',
      [FTranslationCatalog.Entries.Count]);
    lblStatus.Text := 'Offline runtime language pack created.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to export runtime pack: ' + E.Message;
  end;
end;

end.
