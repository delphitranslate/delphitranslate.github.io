unit DAT.Studio.LocalizationReview;

interface

uses
  System.Classes,
  System.Generics.Collections,
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
    tabSuggestions: TTabItem;
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
    lblSuggestionsTitle: TLabel;
    lblSuggestionsText: TLabel;
    lstSuggestions: TListBox;
    memSuggestionDetail: TMemo;
    btnUseSuggestion: TButton;
    btnApproveHighConfidence: TButton;
    btnRejectSuggestion: TButton;
    lblProposalTitle: TLabel;
    lblProposalText: TLabel;
    lstProposals: TListBox;
    memProposalDetail: TMemo;
    cboDecision: TComboBox;
    lblDecisionQuestion: TLabel;
    btnSaveDecision: TButton;
    btnAcceptSafeAll: TButton;
    btnResetPending: TButton;
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
    procedure lstSuggestionsChange(Sender: TObject);
    procedure btnUseSuggestionClick(Sender: TObject);
    procedure btnApproveHighConfidenceClick(Sender: TObject);
    procedure btnRejectSuggestionClick(Sender: TObject);
    procedure btnAcceptSafeAllClick(Sender: TObject);
    procedure btnResetPendingClick(Sender: TObject);
  private
    FProfile: TProjectProfile;
    FCatalog: TTranslationCatalog;
    FGlossary: TProjectGlossary;
    FReview: TLocalizationReview;
    FOutputDirectory: string;
    FGlossaryFileName: string;
    FProposalFileName: string;
    FReviewFileName: string;
    FGlossarySuggestions: TObjectList<TGlossarySuggestion>;
    procedure LoadGlossary;
    procedure RefreshGlossary;
    procedure RunAudit;
    procedure RefreshProposals;
    procedure RefreshSuggestions;
    procedure AddSuggestionToGlossary(const ASuggestion: TGlossarySuggestion);
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
  FGlossarySuggestions.Free;
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
  TLocalizationReviewer.GenerateReviewPackage(FReview, FReviewFileName,
    FProposalFileName);
  btnOpenPackage.Enabled := TFile.Exists(FReviewFileName);
end;

procedure TfrmLocalizationReview.LoadGlossary;
begin
  FreeAndNil(FGlossary);
  FGlossary := TProjectGlossary.LoadFromFile(FGlossaryFileName);
  FGlossary.ApplicationId := FProfile.ProjectName;
  FGlossary.SourceLanguage := FCatalog.SourceLanguage;
  FGlossary.TargetLanguage := FCatalog.Locale.LanguageCode;
  RefreshGlossary;
  RefreshSuggestions;
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
  if FGlossary.Terms.Count = 0 then
    lblGlossaryText.Text := 'No project-specific terms have been approved yet. This is normal. Built-in UI terminology remains active; catalog-derived candidates appear on the Terminology Suggestions tab.';
end;

procedure TfrmLocalizationReview.RefreshSuggestions;
var
  Suggestion: TGlossarySuggestion;
begin
  FreeAndNil(FGlossarySuggestions);
  FGlossarySuggestions := TProjectGlossarySuggester.Build(FCatalog, FGlossary);
  lstSuggestions.Clear;
  for Suggestion in FGlossarySuggestions do
    lstSuggestions.Items.Add(Format('[%s | %s] %s  ->  %s',
      [Suggestion.Provenance, Suggestion.Confidence, Suggestion.SourceText,
       Suggestion.TargetText]));
  if lstSuggestions.Count > 0 then
  begin
    lstSuggestions.ItemIndex := 0;
    lstSuggestionsChange(lstSuggestions);
  end
  else
    memSuggestionDetail.Lines.Text :=
      'No new glossary candidates are available. The project glossary and built-in terminology remain active.';
end;

procedure TfrmLocalizationReview.AddSuggestionToGlossary(
  const ASuggestion: TGlossarySuggestion);
var
  Term: TProjectGlossaryTerm;
begin
  if ASuggestion = nil then Exit;
  Term := TProjectGlossaryTerm.Create;
  Term.SourceText := ASuggestion.SourceText;
  Term.TargetText := ASuggestion.TargetText;
  Term.SemanticConcept := ASuggestion.SemanticConcept;
  Term.ContextKind := ASuggestion.ContextKind;
  Term.DeveloperNote := 'Approved from ' + ASuggestion.Provenance +
    ' in the Localization Review Center.';
  Term.Approved := True;
  FGlossary.Terms.Add(Term);
  if FCatalog.FindEntry(ASuggestion.EntryKey) <> nil then
  begin
    FCatalog.FindEntry(ASuggestion.EntryKey).TranslationOrigin := torProjectGlossary;
    FCatalog.FindEntry(ASuggestion.EntryKey).TranslationConfidence := 'high';
    FCatalog.FindEntry(ASuggestion.EntryKey).TranslationReviewNote :=
      'Approved as project terminology in the Localization Review Center.';
    FCatalog.FindEntry(ASuggestion.EntryKey).Status := tsApproved;
  end;
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
  if lstProposals.Count > 0 then
  begin
    lstProposals.ItemIndex := 0;
    lstProposalsChange(lstProposals);
  end
  else
    memProposalDetail.Lines.Text := 'No layout proposals were generated for this catalog.';
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
  RefreshSuggestions;
  lblStatus.Text := 'Project glossary saved: ' + FGlossaryFileName;
end;

procedure TfrmLocalizationReview.lstSuggestionsChange(Sender: TObject);
var
  Suggestion: TGlossarySuggestion;
begin
  if (FGlossarySuggestions = nil) or (lstSuggestions.ItemIndex < 0) then Exit;
  Suggestion := FGlossarySuggestions[lstSuggestions.ItemIndex];
  memSuggestionDetail.Lines.Text :=
    'Source term: ' + Suggestion.SourceText + sLineBreak +
    'Suggested target: ' + Suggestion.TargetText + sLineBreak +
    'Context: ' + Suggestion.ContextKind + sLineBreak +
    'Semantic concept: ' + Suggestion.SemanticConcept + sLineBreak +
    'Provenance: ' + Suggestion.Provenance + sLineBreak +
    'Confidence: ' + Suggestion.Confidence + sLineBreak +
    'Why suggested: ' + Suggestion.Reason + sLineBreak + sLineBreak +
    'Provider output is never promoted automatically. Approve Selected only after review. Approve High-confidence All accepts only human-reviewed or approved terminology.';
end;

procedure TfrmLocalizationReview.btnUseSuggestionClick(Sender: TObject);
begin
  if (FGlossarySuggestions = nil) or (lstSuggestions.ItemIndex < 0) then Exit;
  AddSuggestionToGlossary(FGlossarySuggestions[lstSuggestions.ItemIndex]);
  FGlossary.SaveToFile(FGlossaryFileName);
  RefreshGlossary;
  RefreshSuggestions;
  lblStatus.Text := 'Selected terminology approved and saved to the project glossary.';
end;

procedure TfrmLocalizationReview.btnApproveHighConfidenceClick(Sender: TObject);
var
  Index: Integer;
  Added: Integer;
begin
  Added := 0;
  if FGlossarySuggestions <> nil then
    for Index := 0 to FGlossarySuggestions.Count - 1 do
      if FGlossarySuggestions[Index].CanBulkApprove then
      begin
        AddSuggestionToGlossary(FGlossarySuggestions[Index]);
        Inc(Added);
      end;
  FGlossary.SaveToFile(FGlossaryFileName);
  RefreshGlossary;
  RefreshSuggestions;
  lblStatus.Text := Format('%d high-confidence terminology term(s) approved and saved.', [Added]);
end;

procedure TfrmLocalizationReview.btnRejectSuggestionClick(Sender: TObject);
var
  SelectedIndex: Integer;
begin
  if (FGlossarySuggestions = nil) or (lstSuggestions.ItemIndex < 0) then Exit;
  SelectedIndex := lstSuggestions.ItemIndex;
  FGlossarySuggestions.Delete(SelectedIndex);
  lstSuggestions.Items.Delete(SelectedIndex);
  if lstSuggestions.Count > 0 then
  begin
    lstSuggestions.ItemIndex := 0;
    lstSuggestionsChange(lstSuggestions);
  end
  else
    memSuggestionDetail.Lines.Text := 'No remaining suggestions in this review session.';
  lblStatus.Text := 'Suggestion rejected for this review session; no catalog or source file was changed.';
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
    'How to judge it: click Open Visual Review. The left preview shows the translated text in the current designer geometry; the right preview shows this language''s proposed runtime geometry. Green controls have proposed changes.' + sLineBreak + sLineBreak +
    'What happens: Accept stores this checksum-backed rule in layout-proposal.json. The next runtime-pack export embeds accepted safe rules in this language''s JSON pack. The component applies them when this language is selected and restores the original value before switching away. Delphi source and form files are never edited.';
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
  TLocalizationReviewer.GenerateReviewPackage(FReview, FReviewFileName,
    FProposalFileName);
  RefreshProposals;
  lblStatus.Text := 'Decision saved. Accepted safe rules will be included in the next runtime-pack export; target source remains unchanged.';
end;

procedure TfrmLocalizationReview.btnAcceptSafeAllClick(Sender: TObject);
var
  Proposal: TLayoutProposal;
  AcceptedCount: Integer;
begin
  AcceptedCount := 0;
  for Proposal in FReview.Proposals do
    if SameText(Proposal.PropertyName, 'Width') or
      SameText(Proposal.PropertyName, 'Height') or
      SameText(Proposal.PropertyName, 'WordWrap') or
      SameText(Proposal.PropertyName, 'AutoSize') then
    begin
      Proposal.Decision := 'accepted';
      Inc(AcceptedCount);
    end;
  TLocalizationReviewer.SaveProposal(FReview, FProposalFileName);
  TLocalizationReviewer.GenerateReviewPackage(FReview, FReviewFileName,
    FProposalFileName);
  RefreshProposals;
  lblStatus.Text := Format(
    '%d safe proposal(s) accepted for the next language-pack export.',
    [AcceptedCount]);
end;

procedure TfrmLocalizationReview.btnResetPendingClick(Sender: TObject);
var
  Proposal: TLayoutProposal;
begin
  for Proposal in FReview.Proposals do
    Proposal.Decision := 'pending';
  TLocalizationReviewer.SaveProposal(FReview, FProposalFileName);
  TLocalizationReviewer.GenerateReviewPackage(FReview, FReviewFileName,
    FProposalFileName);
  RefreshProposals;
  lblStatus.Text := 'All layout decisions reset to Pending.';
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
