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
  FMX.Dialogs,
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TfrmTranslationStudio = class(TForm)
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
    dlgOpenProject: TOpenDialog;
    procedure btnOpenProjectClick(Sender: TObject);
    procedure btnScanProjectClick(Sender: TObject);
  private
    FProjectProfile: TProjectProfile;
    FScanResult: TProjectScanResult;
    procedure ClearProjectSummary;
    procedure ClearScanSummary;
    procedure DisplayProjectSummary(const AProfile: TProjectProfile);
    procedure DisplayScanResult(const AResult: TProjectScanResult);
  public
    destructor Destroy; override;
  end;

var
  frmTranslationStudio: TfrmTranslationStudio;

implementation

uses
  System.SysUtils,
  DAT.Core.ProjectDetection,
  DAT.Scan.Project;

{$R *.fmx}

procedure TfrmTranslationStudio.ClearProjectSummary;
begin
  FProjectProfile := Default(TProjectProfile);
  lblProjectNameValue.Text := 'No project selected';
  lblFrameworkValue.Text := '-';
  lblPlatformsValue.Text := '-';
  lblFormsValue.Text := '-';
  lblSourcesValue.Text := '-';
  btnScanProject.Enabled := False;
  ClearScanSummary;
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
  btnScanProject.Enabled := AProfile.Framework <> tfUnknown;

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
  NewScanResult: TProjectScanResult;
begin
  btnScanProject.Enabled := False;
  lblStatus.Text := 'Scanning project text resources...';
  Application.ProcessMessages;
  try
    NewScanResult := TProjectScanner.Scan(FProjectProfile);
    FreeAndNil(FScanResult);
    FScanResult := NewScanResult;
    DisplayScanResult(FScanResult);
    lblStatus.Text := Format(
      'Scan complete. %d translatable entries are ready for catalog review.',
      [FScanResult.Items.Count]);
  except
    on E: Exception do
      lblStatus.Text := 'Scan failed: ' + E.Message;
  end;
  btnScanProject.Enabled := FProjectProfile.Framework <> tfUnknown;
end;

end.
