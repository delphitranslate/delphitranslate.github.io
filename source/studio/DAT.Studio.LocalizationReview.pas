unit DAT.Studio.LocalizationReview;

interface

uses
  System.Classes,
  FMX.Controls,
  FMX.Controls.Presentation,
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
  DAT.Core.Glossary,
  DAT.Review.Localization;

type
  TfrmLocalizationReview = class(TForm)
    RootLayout: TLayout;
    HeaderBackground: TRectangle;
    HeaderAccent: TRectangle;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    ReviewTabs: TTabControl;
    tabAudit: TTabItem;
    tabGlossary: TTabItem;
    tabProposals: TTabItem;
    lblAuditTitle: TLabel;
    lblAuditSummary: TLabel;
    memAudit: TMemo;
    btnGeneratePackage: TButton;
    btnOpenPackage: TButton;
    lblGlossaryTitle: TLabel;
    lblGlossaryText: TLabel;
    lstGlossary: TListBox;
    lblSourceTerm: TLabel;
    edtSourceTerm: TEdit;
    lblTargetTerm: TLabel;
    edtTargetTerm: TEdit;
    lblConcept: TLabel;
    edtConcept: TEdit;
    lblGlossaryNote: TLabel;
    edtGlossaryNote: TEdit;
    chkCaseSensitive: TCheckBox;
    chkApprovedTerm: TCheckBox;
    btnAddTerm: TButton;
    btnNewTerm: TButton;
    btnDeleteTerm: TButton;
    btnSaveGlossary: TButton;
    lblProposalTitle: TLabel;
    lblProposalText: TLabel;
    lstProposals: TListBox;
    memProposalDetail: TMemo;
    cboDecision: TComboBox;
    btnSaveDecision: TButton;
    btnClose: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddTermClick(Sender: TObject);
    procedure btnNewTermClick(Sender: TObject);
    procedure btnDeleteTermClick(Sender: TObject);
    procedure btnSaveGlossaryClick(Sender: TObject);
    procedure lstGlossaryChange(Sender: TObject);
    procedure lstProposalsChange(Sender: TObject);
    procedure btnSaveDecisionClick(Sender: TObject);
    procedure btnGeneratePackageClick(Sender: TObject);
    procedure btnOpenPackageClick(Sender: TObject);
  private
    FProfile: TProjectProfile;
    FCatalog: TTranslationCatalog;
    FGlossary: TProjectGlossary;
    FReview: TLocalizationReview;
    FOutputDirectory: string;
    FGlossaryFileName: string;
    FProposalFileName: string;
    FReviewFileName: string;
    procedure LoadGlossary;
    procedure RefreshGlossary;
    procedure RunAudit;
    procedure RefreshProposals;
  public
    procedure Prepare(const AProfile: TProjectProfile;
      const ACatalog: TTranslationCatalog; const AOutputDirectory,
      AGlossaryFileName: string);
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Winapi.ShellAPI,
  Winapi.Windows,
  System.Math;

{$R *.fmx}

procedure TfrmLocalizationReview.FormCreate(Sender: TObject);
begin
  cboDecision.ItemIndex := 0;
  btnOpenPackage.Enabled := False;
end;

procedure TfrmLocalizationReview.FormDestroy(Sender: TObject);
begin
  FReview.Free;
  FGlossary.Free;
end;

procedure TfrmLocalizationReview.Prepare(const AProfile: TProjectProfile;
  const ACatalog: TTranslationCatalog; const AOutputDirectory,
  AGlossaryFileName: string);
begin
  FProfile := AProfile;
  FCatalog := ACatalog;
  FOutputDirectory := AOutputDirectory;
  FGlossaryFileName := AGlossaryFileName;
  FProposalFileName := TPath.Combine(FOutputDirectory,
    'layout-proposal.json');
  FReviewFileName := TPath.Combine(FOutputDirectory,
    'localization-review.html');
  lblSubtitle.Text := Format('%s | %s | advisory review; target source is never edited',
    [FProfile.ProjectName, FCatalog.Locale.LanguageCode]);
  LoadGlossary;
  RunAudit;
end;

procedure TfrmLocalizationReview.LoadGlossary;
begin
  FreeAndNil(FGlossary);
  FGlossary := TProjectGlossary.LoadFromFile(FGlossaryFileName);
  FGlossary.ApplicationId := FProfile.ProjectName;
  FGlossary.SourceLanguage := FCatalog.SourceLanguage;
  FGlossary.TargetLanguage := FCatalog.Locale.LanguageCode;
  RefreshGlossary;
end;

procedure TfrmLocalizationReview.RefreshGlossary;
var
  Term: TProjectGlossaryTerm;
begin
  lstGlossary.Clear;
  for Term in FGlossary.Terms do
    lstGlossary.Items.Add(Term.SourceText + '  ->  ' + Term.TargetText);
  lblStatus.Text := Format('%d approved project terminology term(s).',
    [FGlossary.Terms.Count]);
end;

procedure TfrmLocalizationReview.RunAudit;
var
  Finding: TLocalizationFinding;
begin
  FreeAndNil(FReview);
  FReview := TLocalizationReviewer.Analyze(FCatalog);
  TLocalizationReviewer.RestoreDecisions(FReview, FProposalFileName);
  memAudit.Lines.BeginUpdate;
  try
    memAudit.Lines.Clear;
    for Finding in FReview.Findings do
      memAudit.Lines.Add(Format('[%s] %s | %s | %s',
        [LocalizationFindingSeverityText(Finding.Severity), Finding.Category,
         Finding.Key, Finding.MessageText]));
  finally
    memAudit.Lines.EndUpdate;
  end;
  lblAuditSummary.Text := FReview.Summary;
  RefreshProposals;
end;

procedure TfrmLocalizationReview.RefreshProposals;
var
  Proposal: TLayoutProposal;
begin
  lstProposals.Clear;
  for Proposal in FReview.Proposals do
    lstProposals.Items.Add(Format('%s.%s %s: %s -> %s [%s]',
      [Proposal.FormName, Proposal.ComponentName, Proposal.PropertyName,
       Proposal.CurrentValue, Proposal.ProposedValue, Proposal.Decision]));
end;

procedure TfrmLocalizationReview.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLocalizationReview.btnAddTermClick(Sender: TObject);
var
  Term: TProjectGlossaryTerm;
begin
  if (Trim(edtSourceTerm.Text) = '') or (Trim(edtTargetTerm.Text) = '') then
  begin
    lblStatus.Text := 'Enter both source and preferred target text.';
    Exit;
  end;
  if lstGlossary.ItemIndex >= 0 then
    Term := FGlossary.Terms[lstGlossary.ItemIndex]
  else
  begin
    Term := TProjectGlossaryTerm.Create;
    FGlossary.Terms.Add(Term);
  end;
  Term.SourceText := Trim(edtSourceTerm.Text);
  Term.TargetText := Trim(edtTargetTerm.Text);
  Term.SemanticConcept := Trim(edtConcept.Text);
  Term.DeveloperNote := Trim(edtGlossaryNote.Text);
  Term.CaseSensitive := chkCaseSensitive.IsChecked;
  Term.Approved := chkApprovedTerm.IsChecked;
  RefreshGlossary;
  lblStatus.Text := 'Term added or updated. Click Save Project Glossary to persist it.';
end;

procedure TfrmLocalizationReview.btnNewTermClick(Sender: TObject);
begin
  lstGlossary.ItemIndex := -1;
  edtSourceTerm.Text := '';
  edtTargetTerm.Text := '';
  edtConcept.Text := '';
  edtGlossaryNote.Text := '';
  chkCaseSensitive.IsChecked := False;
  chkApprovedTerm.IsChecked := True;
  edtSourceTerm.SetFocus;
end;

procedure TfrmLocalizationReview.btnDeleteTermClick(Sender: TObject);
begin
  if lstGlossary.ItemIndex < 0 then
    Exit;
  FGlossary.Terms.Delete(lstGlossary.ItemIndex);
  RefreshGlossary;
end;

procedure TfrmLocalizationReview.btnSaveGlossaryClick(Sender: TObject);
begin
  FGlossary.SaveToFile(FGlossaryFileName);
  lblStatus.Text := 'Project glossary saved: ' + FGlossaryFileName;
end;

procedure TfrmLocalizationReview.lstGlossaryChange(Sender: TObject);
var
  Term: TProjectGlossaryTerm;
begin
  if lstGlossary.ItemIndex < 0 then Exit;
  Term := FGlossary.Terms[lstGlossary.ItemIndex];
  edtSourceTerm.Text := Term.SourceText;
  edtTargetTerm.Text := Term.TargetText;
  edtConcept.Text := Term.SemanticConcept;
  edtGlossaryNote.Text := Term.DeveloperNote;
  chkCaseSensitive.IsChecked := Term.CaseSensitive;
  chkApprovedTerm.IsChecked := Term.Approved;
end;

procedure TfrmLocalizationReview.lstProposalsChange(Sender: TObject);
var
  Proposal: TLayoutProposal;
begin
  if lstProposals.ItemIndex < 0 then Exit;
  Proposal := FReview.Proposals[lstProposals.ItemIndex];
  memProposalDetail.Lines.Text :=
    'Form: ' + Proposal.FormName + sLineBreak +
    'Control: ' + Proposal.ComponentName + sLineBreak +
    'Property: ' + Proposal.PropertyName + sLineBreak +
    'Current: ' + Proposal.CurrentValue + sLineBreak +
    'Proposed: ' + Proposal.ProposedValue + sLineBreak +
    'Reason: ' + Proposal.Rationale + sLineBreak +
    'Decision: ' + Proposal.Decision + sLineBreak + sLineBreak +
    'Advisory only: the Studio will not edit the Delphi form.';
  if SameText(Proposal.Decision, 'accepted') then cboDecision.ItemIndex := 1
  else if SameText(Proposal.Decision, 'rejected') then cboDecision.ItemIndex := 2
  else if SameText(Proposal.Decision, 'manual') then cboDecision.ItemIndex := 3
  else cboDecision.ItemIndex := 0;
end;

procedure TfrmLocalizationReview.btnSaveDecisionClick(Sender: TObject);
const
  Decisions: array[0..3] of string = ('pending', 'accepted', 'rejected', 'manual');
begin
  if lstProposals.ItemIndex < 0 then Exit;
  FReview.Proposals[lstProposals.ItemIndex].Decision :=
    Decisions[EnsureRange(cboDecision.ItemIndex, 0, 3)];
  TLocalizationReviewer.SaveProposal(FReview, FProposalFileName);
  RefreshProposals;
  lblStatus.Text := 'Layout decision saved without modifying target source.';
end;

procedure TfrmLocalizationReview.btnGeneratePackageClick(Sender: TObject);
begin
  TLocalizationReviewer.GenerateReviewPackage(FReview, FReviewFileName,
    FProposalFileName);
  btnOpenPackage.Enabled := True;
  lblStatus.Text := 'Review package generated: ' + FReviewFileName;
end;

procedure TfrmLocalizationReview.btnOpenPackageClick(Sender: TObject);
begin
  if TFile.Exists(FReviewFileName) then
    ShellExecute(0, 'open', PChar(FReviewFileName), nil, nil, SW_SHOWNORMAL);
end;

end.
