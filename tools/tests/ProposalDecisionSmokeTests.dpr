program ProposalDecisionSmokeTests;

{ Whether yesterday's proposal file can veto today's analyser.

  Layout decisions survive between runs so that a rejection made in review is
  not quietly undone by the next scan. That is right. But the saved file also
  carries every proposal that was merely *pending*, and pending is not a
  decision - it is the absence of one.

  It cost two rebuilds to find out. The analyser was taught to accept the
  right-to-left decisions; the pack still shipped without them. The analyser
  was creating them accepted, and then the proposal file written by the
  previous build - where they had been pending, because that build did not
  know about them - put them straight back. Every subsequent run inherited the
  veto. A stale file poisoned the feature permanently, and nothing anywhere
  said a word.

  So a saved "pending" now means "nobody has decided", and the analyser's own
  judgement stands. Only an explicit decision overrides it. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  FMX.Forms,
  FMX.TextLayout,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Review.Localization in '..\..\source\review\DAT.Review.Localization.pas',
  DAT.Review.TextMeasurement in '..\..\source\review\DAT.Review.TextMeasurement.pas',
  DAT.Review.TextMeasurement.GDI in '..\..\source\review\DAT.Review.TextMeasurement.GDI.pas',
  DAT.Review.TextMeasurement.FMX in '..\..\source\review\DAT.Review.TextMeasurement.FMX.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

{ A saved proposal file of the shape the reviewer writes, naming one decision
  of each kind against the review handed in. }
function WriteSavedProposal(const AReview: TLocalizationReview;
  const AFileName: string): Integer;
var
  Proposal: TLayoutProposal;
  Body: string;
  Saved: string;
begin
  Result := 0;
  Body := '';
  for Proposal in AReview.Proposals do
  begin
    { The first Left proposal is marked rejected, standing for a human
      saying no; everything else is written back as pending, standing for a
      build that did not know the property existed. }
    if (Result = 0) and SameText(Proposal.PropertyName, 'Left') then
    begin
      Saved := 'rejected';
      Inc(Result);
    end
    else
      Saved := 'pending';
    if Body <> '' then
      Body := Body + ',';
    Body := Body + Format(
      '{"formName":"%s","componentName":"%s","propertyName":"%s",' +
      '"sourceChecksum":"%s","decision":"%s"}',
      [Proposal.FormName, Proposal.ComponentName, Proposal.PropertyName,
       Proposal.SourceChecksum, Saved]);
  end;
  TFile.WriteAllText(AFileName,
    '{"applicationId":"x","languageCode":"x","proposals":[' + Body + ']}',
    TEncoding.UTF8);
end;

function DecisionOf(const AReview: TLocalizationReview;
  const APropertyName: string): string;
var
  Proposal: TLayoutProposal;
begin
  Result := '(none)';
  for Proposal in AReview.Proposals do
    if SameText(Proposal.PropertyName, APropertyName) then
      Exit(Proposal.Decision);
end;

function RejectedCount(const AReview: TLocalizationReview): Integer;
var
  Proposal: TLayoutProposal;
begin
  Result := 0;
  for Proposal in AReview.Proposals do
    if SameText(Proposal.Decision, 'rejected') then
      Inc(Result);
end;

var
  Catalog: TTranslationCatalog;
  Review: TLocalizationReview;
  SavedFile: string;
  FixtureDir: string;
  CatalogText: string;
  TemporaryCatalog: string;
begin
  try
    FixtureDir := TPath.Combine(
      TPath.GetDirectoryName(TPath.GetDirectoryName(
        TPath.GetDirectoryName(ParamStr(0)))), 'contracts\layout');
    if not TDirectory.Exists(FixtureDir) then
      FixtureDir := 'contracts\layout';

    { The fixture points at its form through a placeholder so it can live
      anywhere; resolve it into a copy, exactly as the contract harness does. }
    CatalogText := TFile.ReadAllText(TPath.Combine(FixtureDir,
      'vcl_32_right_to_left_flips_alignment_and_anchors.catalog.json'),
      TEncoding.UTF8);
    CatalogText := StringReplace(CatalogText, '{FIXTUREDIR}',
      StringReplace(FixtureDir, '\', '\\', [rfReplaceAll]), [rfReplaceAll]);
    TemporaryCatalog := TPath.Combine(TPath.GetTempPath,
      'dat-proposal-decisions-catalog.json');
    TFile.WriteAllText(TemporaryCatalog, CatalogText, TEncoding.UTF8);
    Catalog := TCatalogJson.LoadFromFile(TemporaryCatalog);
    try
      Review := TLocalizationReviewer.Analyze(Catalog);
      try
        Writeln;
        Writeln('  fresh analysis:');
        Writeln('    Alignment  = ', DecisionOf(Review, 'Alignment'));
        Writeln('    Left       = ', DecisionOf(Review, 'Left'));
        Check(SameText(DecisionOf(Review, 'Alignment'), 'accepted'),
          'The analyser accepts a mirror decision to begin with.');

        SavedFile := TPath.Combine(TPath.GetTempPath,
          'dat-proposal-decisions.json');
        WriteSavedProposal(Review, SavedFile);
      finally
        Review.Free;
      end;

      { A second run, exactly as the wizard does it. }
      Review := TLocalizationReviewer.Analyze(Catalog);
      try
        TLocalizationReviewer.RestoreDecisions(Review, SavedFile);
        Writeln('  after restoring yesterday''s file:');
        Writeln('    Alignment  = ', DecisionOf(Review, 'Alignment'));
        Writeln('    rejected   = ', RejectedCount(Review));
        Writeln;
        Check(SameText(DecisionOf(Review, 'Alignment'), 'accepted'),
          'A saved "pending" does not veto it - that is what shipped empty.');
        Check(RejectedCount(Review) = 1,
          'while an explicit rejection is still obeyed.');
      finally
        Review.Free;
      end;
      TFile.Delete(SavedFile);
    finally
      Catalog.Free;
      TFile.Delete(TemporaryCatalog);
    end;

    if Failures = 0 then
    begin
      Writeln('Proposal decision smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Proposal decision smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
