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
  DAT.Integration.Types,
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
    edtSourceLanguage: TEdit;
    lblTargetLanguageCode: TLabel;
    edtTargetLanguageCode: TEdit;
    lblNativeLanguageName: TLabel;
    edtNativeLanguageName: TEdit;
    lblTextDirection: TLabel;
    edtTextDirection: TEdit;
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
    lstCatalogEntries: TListBox;
    lblSourceTextEditor: TLabel;
    memSourceText: TMemo;
    lblTranslatedTextEditor: TLabel;
    memTranslatedText: TMemo;
    btnApplyTranslation: TButton;
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
    lblIntegrationSummary: TLabel;
    btnGenerateIntegrationPackage: TButton;
    lblIntegrationOutput: TLabel;
    btnApplyIntegration: TButton;
    btnRestoreIntegration: TButton;
    dlgOpenProject: TOpenDialog;
    dlgOpenCatalog: TOpenDialog;
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
    FCatalogFileName: string;
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
  public
    destructor Destroy; override;
  end;

var
  frmTranslationStudio: TfrmTranslationStudio;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  DAT.Core.CatalogJson,
  DAT.Core.ProjectDetection,
  DAT.Core.RuntimePack,
  DAT.Core.TranslationWorkspace,
  DAT.Integration.Package,
  DAT.Integration.Plan,
  DAT.Integration.Engine,
  DAT.Integration.Transaction,
  DAT.Studio.Translation,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project;

{$R *.fmx}

procedure TfrmTranslationStudio.FormCreate(Sender: TObject);
begin
  ApplyStudioTranslation(Self);
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
  FreeAndNil(FIntegrationChangeSet);
  FIntegrationPackageDirectory := '';
  FLastIntegrationBackupDirectory := '';
  lstIntegrationPlan.Items.Clear;
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
  FValidationResult.Free;
  FIntegrationChangeSet.Free;
  FTranslationCatalog.Free;
  FScanResult.Free;
  inherited Destroy;
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
        lstCatalogEntries.Items.Add(Entry.Key);
  finally
    lstCatalogEntries.EndUpdate;
  end;
  memSourceText.Text := '';
  memTranslatedText.Text := '';
  if lstCatalogEntries.Count > 0 then
    lstCatalogEntries.ItemIndex := 0;
end;

procedure TfrmTranslationStudio.DisplayCatalogLanguage;
begin
  if FTranslationCatalog = nil then
    Exit;
  edtSourceLanguage.Text := FTranslationCatalog.SourceLanguage;
  edtTargetLanguageCode.Text :=
    FTranslationCatalog.Locale.LanguageCode;
  edtNativeLanguageName.Text :=
    FTranslationCatalog.Locale.NativeLanguageName;
  edtTextDirection.Text := FTranslationCatalog.Locale.TextDirection;
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
  edtSourceLanguage.Text := 'en-US';
  edtTargetLanguageCode.Text := '';
  edtNativeLanguageName.Text := '';
  edtTextDirection.Text := 'ltr';
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

  LanguagePageCard.Visible := AStep = 3;
  ValidationPageCard.Visible := AStep = 4;
  ExportPageCard.Visible := AStep = 5;
  IntegrationPageCard.Visible := AStep = 6;

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
  end;
end;

procedure TfrmTranslationStudio.UpdateCatalogFromLanguageEditors;
var
  LocaleSettings: TFormatSettings;
begin
  if FTranslationCatalog = nil then
    raise Exception.Create(
      'Scan the project or open an existing catalog first.');
  if Trim(edtTargetLanguageCode.Text) = '' then
    raise Exception.Create('Enter a target language code.');
  if Trim(edtNativeLanguageName.Text) = '' then
    raise Exception.Create('Enter the language name in its native form.');

  LocaleSettings := TFormatSettings.Create(
    Trim(edtTargetLanguageCode.Text));
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

  FTranslationCatalog.SourceLanguage := Trim(edtSourceLanguage.Text);
  FTranslationCatalog.Locale.LanguageCode :=
    Trim(edtTargetLanguageCode.Text);
  FTranslationCatalog.Locale.NativeLanguageName :=
    Trim(edtNativeLanguageName.Text);
  FTranslationCatalog.Locale.TextDirection :=
    Trim(edtTextDirection.Text);
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
      FTranslationCatalog.SourceLanguage := edtSourceLanguage.Text;
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

procedure TfrmTranslationStudio.btnBuildIntegrationPlanClick(Sender: TObject);
var
  IntegrationPlan: TIntegrationPlan;
begin
  try
    IntegrationPlan := TIntegrationPlanner.Build(
      FProjectProfile, edtLanguageMenuName.Text);
    try
      lstIntegrationPlan.Items.Assign(IntegrationPlan.Lines);
      lblIntegrationSummary.Text := Format(
        '%d language pack(s) found. Existing menu: %s.',
        [IntegrationPlan.LanguageCount,
         BoolToStr(IntegrationPlan.MenuFound, True)]);
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
    lstIntegrationPlan.Items.Clear;
    for Change in FIntegrationChangeSet.Changes do
      lstIntegrationPlan.Items.Add(Format('%s  |  %s',
        [IntegrationChangeKindDisplayName(Change.Kind),
         Change.TargetFileName]));
    lblIntegrationOutput.Text := OutputDirectory;
    lblIntegrationSummary.Text := Format(
      '%d target file change(s) are ready for review.',
      [FIntegrationChangeSet.Changes.Count]);
    btnApplyIntegration.Enabled := True;
    lblStatus.Text :=
      'Exact integration preview ready. Target source is unchanged.';
  except
    on E: Exception do
      lblStatus.Text := 'Unable to generate integration package: ' + E.Message;
  end;
end;

procedure TfrmTranslationStudio.btnApplyIntegrationClick(Sender: TObject);
var
  ApplyResult: TIntegrationApplyResult;
begin
  if FIntegrationChangeSet = nil then
  begin
    lblStatus.Text := 'Generate and review an integration package first.';
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
    finally
      ApplyResult.Free;
    end;
  except
    on E: Exception do
    begin
      btnApplyIntegration.Enabled := True;
      lblStatus.Text := 'Integration failed and was rolled back: ' + E.Message;
    end;
  end;
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

procedure TfrmTranslationStudio.lstCatalogEntriesChange(Sender: TObject);
var
  Entry: TTranslationEntry;
begin
  if (FTranslationCatalog = nil) or
    (lstCatalogEntries.ItemIndex < 0) or
    (lstCatalogEntries.ItemIndex >= FTranslationCatalog.Entries.Count) then
    Exit;
  Entry := FTranslationCatalog.Entries[lstCatalogEntries.ItemIndex];
  memSourceText.Text := Entry.SourceText;
  memTranslatedText.Text := Entry.TranslatedText;
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
  InvalidateValidation;
  try
    if FCatalogFileName <> '' then
      SaveCatalog;
    lblStatus.Text := 'Translation applied.';
  except
    on E: Exception do
      lblStatus.Text := 'Translation applied but not saved: ' + E.Message;
  end;
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
