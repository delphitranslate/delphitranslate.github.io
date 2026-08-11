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
    tabLanguages: TTabItem;
    tabProvider: TTabItem;
    tabScan: TTabItem;
    tabComponent: TTabItem;
    tabReview: TTabItem;
    tabFinish: TTabItem;
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
    memCommands: TMemo;
    btnCopyCommands: TButton;
    btnRunDeployment: TButton;
    btnOpenKitFolder: TButton;
    btnDeployApplicationFolder: TButton;
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
  private
    FCurrentStep: Integer;
    FHighestStep: Integer;
    FFinalProcessing: Boolean;
    FCompleted: Boolean;
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    FCatalog: TTranslationCatalog;
    FCatalogFileName: string;
    FKitDirectory: string;
    FBackupFileName: string;
    FProjectConfigurationBackupDirectory: string;
    FSessionApiKey: string;
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
    function ExistingBuildOutputDirectories: TArray<string>;
    function DeployLanguagePacksToExistingOutputs: Integer;
    function RunDeploymentScript(const AApplicationDirectory: string): Boolean;
  public
  end;

implementation

uses
  System.IOUtils,
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
  DAT.Core.ProjectDetection,
  DAT.Core.RuntimePack,
  DAT.Core.Terminology,
  DAT.Core.TranslationWorkspace,
  DAT.Integration.ComponentPackage,
  DAT.Integration.Transaction,
  DAT.Provider.Client,
  DAT.Provider.CredentialStore,
  DAT.Provider.Settings,
  DAT.Runtime.LanguagePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Validation.Catalog;

{$R *.fmx}

const
  StepCount = 8;
  DeploymentProcessTimeout = 120000;
  ProcessTerminationWait = 5000;

procedure TfrmSetupWizard.FormCreate(Sender: TObject);
begin
  FCurrentStep := 1;
  FHighestStep := 1;
  cboSourceLanguage.ItemIndex := 0;
  cboTargetLanguage.ItemIndex := 36;
  cboProvider.ItemIndex := 0;
  cboDeepLPlan.ItemIndex := 0;
  chkRememberKey.IsChecked := True;
  chkCreateBackup.IsChecked := True;
  chkCreateBackup.Enabled := False;
  chkTargetProjectClosed.IsChecked := False;
  edtApiKey.Password := True;
  ApplyLocaleDefaults;
  SetStep(1);
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
    'After final processing:' + sLineBreak +
    '1. The target project must remain closed during final processing. Then start RAD Studio without opening the target form.' + sLineBreak +
    '2. Choose Component > Install Packages, then click Add.' + sLineBreak +
    '3. Select the exact design BPL shown by this Wizard.' + sLineBreak +
    '4. Confirm the DAT package is checked, then click OK.' + sLineBreak +
    '5. Open the target project and its primary form.' + sLineBreak +
    '6. Place one ' + ManagerClass + ' on the primary form.' + sLineBreak +
    '7. Set ApplicationId to "' + ApplicationId + '". Leave ' +
      'LanguagesFolder as "Localization\Languages".' + sLineBreak +
    '8. Place one ' + SelectorClass + '. In Object Inspector, set its ' +
      'LanguageManager property to the manager; do not leave it blank. A ' +
      'visible selector is required unless you provide an ' +
      'equivalent connected Language menu.' + sLineBreak +
    '9. Save the form and build Win32 and Win64 as required.' + sLineBreak +
    '10. For a portable or USB copy, click Deploy to App Folder and select ' +
      'the folder containing ' + ApplicationId + '.exe.' + sLineBreak +
    'The Wizard configures the ComponentSource Search Path for all build ' +
      'configurations and adds automatic post-build language-pack deployment.';
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
  if FCurrentStep = 7 then
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
  btnFinish.Enabled := FCompleted;
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
    3:
      if SelectedLanguageCode(cboTargetLanguage) = '' then
      begin
        lblFooterStatus.Text := 'Select a target language before continuing.';
        Exit;
      end;
    4:
      if EffectiveApiKey = '' then
      begin
        lblFooterStatus.Text := 'Save or enter an API key before continuing.';
        Exit;
      end;
    5:
      if (FScanResult = nil) or (FCatalog = nil) then
      begin
        lblFooterStatus.Text := 'Run the project scan before continuing.';
        Exit;
      end;
    6:
      if not chkUnderstandManualStep.IsChecked then
      begin
        lblFooterStatus.Text :=
          'Confirm that you understand the remaining manual RAD Studio phase.';
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
    chkTargetProjectClosed.IsChecked := False;
    chkAuthorizeFinal.IsChecked := False;
    lblProjectSummary.Text := Format('%s  |  %s  |  %s  |  %d form resources',
      [FProjectProfile.ProjectName,
       TargetFrameworkToString(FProjectProfile.Framework),
       ProjectPlatformsDisplayName(FProjectProfile),
       FProjectProfile.FormResourceCount]);
    FreeAndNil(FScanResult);
    FreeAndNil(FCatalog);
    FCatalogFileName := '';
    FHighestStep := Min(FHighestStep, 4);
    lblFooterStatus.Text := 'Project identified. No target file was changed.';
    UpdateComponentInstructions;
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
  FreeAndNil(FCatalog);
  FCatalogFileName := '';
  if FHighestStep > 5 then
    FHighestStep := 5;
  UpdateRail;
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
  if TFile.Exists(ExistingFileName) then
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
    lblScanSummary.Text := Format(
      '%d translatable entries  |  %d new  |  %d changed  |  %d unchanged  |  %d obsolete',
      [FScanResult.Items.Count, MergeSummary.NewEntries,
       MergeSummary.ChangedEntries, MergeSummary.UnchangedEntries,
       MergeSummary.ObsoleteEntries]);
    lblFooterStatus.Text := 'Scan complete. The development catalog is ready.';
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
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
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
    'Provider: ' + TranslationProviderDisplayName(SelectedProvider) + sLineBreak +
    Format('Scanned entries: %d', [FScanResult.Items.Count]) + sLineBreak +
    Format('Unresolved entries to translate: %d', [MissingCount]) + sLineBreak +
    'Integration: component kit plus one controlled DPROJ configuration block.' +
      sLineBreak +
    'Search Path: ComponentSource for all configurations and platforms.' +
      sLineBreak +
    'Deployment: automatic after every future build; deploy now to existing outputs.' +
      sLineBreak +
    'RAD Studio: target project must be closed before final processing.' +
      sLineBreak +
    'Backup: required ZIP plus verified DPROJ transaction backup.';
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
  Platform: string;
  ProjectDirectory: string;
  ScriptName: string;
begin
  memCommands.Lines.Clear;
  ProjectDirectory := TPath.GetDirectoryName(FProjectProfile.ProjectFileName);
  ScriptName := TPath.Combine(FKitDirectory, 'Deploy-LanguagePacks.ps1');
  for Platform in Platforms do
    for Configuration in Configurations do
      memCommands.Lines.Add(Format(
        '& "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%s" -ApplicationDirectory "%s"',
        [ScriptName, TPath.Combine(ProjectDirectory,
          TPath.Combine('bin\' + Platform, Configuration))]));
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
          OutputDirectory := TPath.Combine(ProjectDirectory,
            TPath.Combine('bin\' + Platform, Configuration));
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

procedure TfrmSetupWizard.ExecuteFinalProcessing;
var
  ApiKey: string;
  BackupDirectory: string;
  Client: TTranslationProviderClient;
  Entry: TTranslationEntry;
  EntryIndexes: TArray<Integer>;
  Index: Integer;
  MissingCount: Integer;
  Plan: TDeepLPlan;
  Provider: TTranslationProvider;
  Report: TStringList;
  DeployedCount: Integer;
  ProjectBackupDirectory: string;
  RuntimePackFileName: string;
  SourceTexts: TArray<string>;
  TranslatedTexts: TArray<string>;
  Contexts: TArray<string>;
  ProviderCount: Integer;
  ResolvedText: string;
  Validation: TCatalogValidationResult;
begin
  FFinalProcessing := True;
  btnBack.Enabled := False;
  btnCancel.Enabled := False;
  btnNext.Enabled := False;
  UpdateRail;
  memProgress.Lines.Clear;
  FProjectConfigurationBackupDirectory := '';
  try
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

    Provider := SelectedProvider;
    ApiKey := EffectiveApiKey;
    if cboDeepLPlan.ItemIndex = 1 then
      Plan := dpPro
    else
      Plan := dpFree;
    TTerminologyResolver.ApplyAuthoritativeTerms(FCatalog);
    MissingCount := 0;
    for Entry in FCatalog.Entries do
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
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
      if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
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
      AddProgress(Format('%d translations recorded.', [Length(TranslatedTexts)]));
    end
    else
      AddProgress('All unresolved entries were satisfied by approved terminology or translation memory; existing work was preserved.');

    TCatalogJson.SaveToFile(FCatalog, FCatalogFileName);
    AddProgress('Development catalog saved.');
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
    TRuntimePackBuilder.ExportToFile(FCatalog, RuntimePackFileName);
    AddProgress('Runtime JSON pack exported: ' + RuntimePackFileName);
    FKitDirectory := TComponentIntegrationPackageGenerator.Generate(
      FProjectProfile, TPath.Combine(FindStudioRoot,
        'export\component-integration'),
      TPath.Combine(FindStudioRoot, 'source\runtime'),
      TPath.Combine(FindStudioRoot, 'source\components'));
    AddProgress('Component integration kit generated.');
    BuildDeploymentCommands;
    DeployedCount := DeployLanguagePacksToExistingOutputs;
    if DeployedCount = 0 then
      AddProgress('No existing build-output folders were found. The next build will deploy the packs automatically.')
    else
      AddProgress(Format('Automatic deployment completed for %d existing build output(s).',
        [DeployedCount]));
    ProjectBackupDirectory := ChangeFileExt(FBackupFileName, '') +
      '-project-configuration';
    FProjectConfigurationBackupDirectory :=
      TComponentIntegrationPackageGenerator.ConfigureProject(
        FProjectProfile, FKitDirectory, ProjectBackupDirectory);
    AddProgress('Project Search Path and automatic post-build deployment configured.');
    lblKitPath.Text := FKitDirectory;
    Report := TStringList.Create;
    try
      Report.Add('DELPHI APP TRANSLATION - SETUP WIZARD COMPLETION REPORT');
      Report.Add('Created: ' + DateTimeToStr(Now));
      Report.Add('Project: ' + FProjectProfile.ProjectFileName);
      Report.Add('Language: ' + FCatalog.Locale.NativeLanguageName + ' (' +
        FCatalog.Locale.LanguageCode + ')');
      Report.Add('Development catalog: ' + FCatalogFileName);
      Report.Add('Runtime pack: ' + RuntimePackFileName);
      Report.Add('Component kit: ' + FKitDirectory);
      Report.Add('Backup: ' + FBackupFileName);
      Report.Add('DPROJ transaction backup: ' +
        FProjectConfigurationBackupDirectory);
      Report.Add('Application ID: ' + FProjectProfile.ProjectName);
      Report.Add('ComponentSource Search Path: ' +
        TPath.Combine(FKitDirectory, 'ComponentSource'));
      Report.Add('Existing build outputs deployed: ' + DeployedCount.ToString);
      Report.Add('');
      Report.Add('NEXT MANUAL DELPHI STEP');
      Report.AddStrings(memComponentInstructions.Lines);
      Report.Add('');
      Report.Add('DEPLOYMENT COMMANDS');
      Report.AddStrings(memCommands.Lines);
      Report.SaveToFile(TPath.Combine(FKitDirectory,
        'Wizard-Completion-Report.txt'), TEncoding.UTF8);
    finally
      Report.Free;
    end;
    AddProgress('Completion report written. Pascal and form source files remain unchanged.');
    FCompleted := True;
    lblFinishText.Text :=
      'Automatic processing is complete. Perform the clearly listed Delphi package/component step, then build the target. Language packs deploy automatically after each build.';
    lblFooterStatus.Text := 'Setup Wizard completed successfully.';
  except
    on E: Exception do
    begin
      AddProgress('STOPPED: ' + E.Message);
      if FProjectConfigurationBackupDirectory <> '' then
      begin
        try
          TIntegrationTransaction.Restore(
            TPath.GetDirectoryName(FProjectProfile.ProjectFileName),
            FProjectConfigurationBackupDirectory);
          AddProgress('The Delphi project configuration was restored automatically.');
          FProjectConfigurationBackupDirectory := '';
        except
          on RestoreError: Exception do
            AddProgress('URGENT: automatic project restore failed: ' +
              RestoreError.Message);
        end;
      end;
      lblFinishText.Text :=
        'Processing stopped safely. Review the message below. Pascal and form source files were not automatically edited.';
      lblFooterStatus.Text := 'Setup Wizard did not complete: ' + E.Message;
      FCompleted := False;
    end;
  end;
  FFinalProcessing := False;
  btnCancel.Enabled := not FCompleted;
  btnFinish.Enabled := FCompleted;
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
  const AApplicationDirectory: string): Boolean;
var
  ExitCode: Cardinal;
  Parameters: string;
  ShellInfo: TShellExecuteInfo;
  WaitResult: Cardinal;
begin
  Result := False;
  FillChar(ShellInfo, SizeOf(ShellInfo), 0);
  ShellInfo.cbSize := SizeOf(ShellInfo);
  ShellInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShellInfo.Wnd := 0;
  ShellInfo.lpVerb := 'open';
  ShellInfo.lpFile :=
    'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
  Parameters := Format(
    '-NoProfile -ExecutionPolicy Bypass -File "%s" -ApplicationDirectory "%s" -ProjectDirectory "%s"',
    [TPath.Combine(FKitDirectory, 'Deploy-LanguagePacks.ps1'),
     AApplicationDirectory,
     TPath.GetDirectoryName(FProjectProfile.ProjectFileName)]);
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
  ExecutableFileName: string;
begin
  if FKitDirectory = '' then
  begin
    lblFooterStatus.Text := 'Complete final processing before deployment.';
    Exit;
  end;
  ApplicationDirectory := '';
  if not SelectDirectory(
    'Select the folder containing ' + FProjectProfile.ProjectName + '.exe',
    '', ApplicationDirectory) then
    Exit;
  ExecutableFileName := TPath.Combine(ApplicationDirectory,
    FProjectProfile.ProjectName + '.exe');
  if not TFile.Exists(ExecutableFileName) then
  begin
    lblFooterStatus.Text := Format(
      'Select the folder containing %s. Nothing was copied.',
      [FProjectProfile.ProjectName + '.exe']);
    Exit;
  end;
  btnDeployApplicationFolder.Enabled := False;
  try
    if not RunDeploymentScript(ApplicationDirectory) then
      raise Exception.Create('Language-pack deployment failed.');
    lblFooterStatus.Text := 'Language packs deployed to ' +
      TPath.Combine(ApplicationDirectory, 'Localization\Languages');
  except
    on E: Exception do
      lblFooterStatus.Text := E.Message;
  end;
  btnDeployApplicationFolder.Enabled := True;
end;

end.
