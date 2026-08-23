unit DAT.Review.Localization;

interface

uses
  System.Classes,
  System.Generics.Collections,
  DAT.Core.Types;

type
  TLocalizationFindingSeverity = (lfsInformation, lfsWarning, lfsHighRisk);

  TLocalizationFinding = class
  private
    FCategory: string;
    FSeverity: TLocalizationFindingSeverity;
    FKey: string;
    FMessageText: string;
    FRecommendation: string;
    FSourceText: string;
    FTranslatedText: string;
    FOwnership: string;
    FProvenance: string;
  public
    property Category: string read FCategory write FCategory;
    property Severity: TLocalizationFindingSeverity read FSeverity write FSeverity;
    property Key: string read FKey write FKey;
    property MessageText: string read FMessageText write FMessageText;
    property Recommendation: string read FRecommendation write FRecommendation;
    property SourceText: string read FSourceText write FSourceText;
    property TranslatedText: string read FTranslatedText write FTranslatedText;
    property Ownership: string read FOwnership write FOwnership;
    property Provenance: string read FProvenance write FProvenance;
  end;

  TLayoutControl = class
  private
    FFormName: string;
    FParentName: string;
    FComponentName: string;
    FComponentClassName: string;
    FSourceFileName: string;
    FSourceText: string;
    FTranslatedText: string;
    FLeft: Double;
    FTop: Double;
    FWidth: Double;
    FHeight: Double;
    FFontSize: Double;
    FAlign: string;
    FAnchors: string;
    FTabOrder: Integer;
    FHasTabOrder: Boolean;
    FMirrorHandled: Boolean;
    FGeometryOwnedByCode: Boolean;
    FHorzAlign: string;
    FWordWrap: Boolean;
    FAutoSize: Boolean;
    FFontBold: Boolean;
    FHasPosition: Boolean;
    FHasSize: Boolean;
    FPlannedLeft: Double;
    FPlannedTop: Double;
    FPlannedWidth: Double;
    FPlannedHeight: Double;
    FPlannedWordWrap: Boolean;
    FPlannedFontSize: Double;
  public
    property FormName: string read FFormName write FFormName;
    property ParentName: string read FParentName write FParentName;
    property ComponentName: string read FComponentName write FComponentName;
    property ComponentClassName: string read FComponentClassName write FComponentClassName;
    property SourceFileName: string read FSourceFileName write FSourceFileName;
    property SourceText: string read FSourceText write FSourceText;
    property TranslatedText: string read FTranslatedText write FTranslatedText;
    property Left: Double read FLeft write FLeft;
    property Top: Double read FTop write FTop;
    property Width: Double read FWidth write FWidth;
    property Height: Double read FHeight write FHeight;
    property FontSize: Double read FFontSize write FFontSize;
    property FontBold: Boolean read FFontBold write FFontBold;
    property Align: string read FAlign write FAlign;
    { As the designer wrote it, for example [akLeft,akTop]. Only read for a
      right-to-left layout, where an edge anchor has to change edges. }
    property Anchors: string read FAnchors write FAnchors;
    { Keyboard order, which is reading order by another name. In a mirrored
      layout the first control is the rightmost, so this reverses with
      everything else - otherwise the eye starts at the right and the Tab key
      starts at the left. }
    property TabOrder: Integer read FTabOrder write FTabOrder;
    property HasTabOrder: Boolean read FHasTabOrder write FHasTabOrder;
    { Set when the right-to-left pass has already placed this control, so the
      general reflection leaves it alone. }
    property MirrorHandled: Boolean read FMirrorHandled write FMirrorHandled;
    { The application assigns this control's position or size in its own
      source. Its text is translated; its geometry is not touched, because a
      rule computed from the designer values would overwrite a decision the
      application has already made and will not make again. }
    property GeometryOwnedByCode: Boolean read FGeometryOwnedByCode
      write FGeometryOwnedByCode;
    { How the text sits inside the control. This decides which way the control
      has to grow: a right-aligned caption must keep its right edge and extend
      leftwards, or its text walks into whatever sits beside it. }
    property HorzAlign: string read FHorzAlign write FHorzAlign;
    property WordWrap: Boolean read FWordWrap write FWordWrap;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property HasPosition: Boolean read FHasPosition write FHasPosition;
    property HasSize: Boolean read FHasSize write FHasSize;
    { Working geometry used while proposals are being built. Every sizing and
      separation decision reads and writes these values so later decisions see
      the effect of earlier ones instead of the stale designer geometry. }
    property PlannedLeft: Double read FPlannedLeft write FPlannedLeft;
    property PlannedTop: Double read FPlannedTop write FPlannedTop;
    property PlannedWidth: Double read FPlannedWidth write FPlannedWidth;
    property PlannedHeight: Double read FPlannedHeight write FPlannedHeight;
    property PlannedWordWrap: Boolean read FPlannedWordWrap write FPlannedWordWrap;
    property PlannedFontSize: Double read FPlannedFontSize write FPlannedFontSize;
  end;

  TLayoutProposal = class
  private
    FFormName: string;
    FComponentName: string;
    FPropertyName: string;
    FCurrentValue: string;
    FProposedValue: string;
    FRationale: string;
    FDecision: string;
    FSourceChecksum: string;
  public
    property FormName: string read FFormName write FFormName;
    property ComponentName: string read FComponentName write FComponentName;
    property PropertyName: string read FPropertyName write FPropertyName;
    property CurrentValue: string read FCurrentValue write FCurrentValue;
    property ProposedValue: string read FProposedValue write FProposedValue;
    property Rationale: string read FRationale write FRationale;
    property Decision: string read FDecision write FDecision;
    property SourceChecksum: string read FSourceChecksum write FSourceChecksum;
  end;

  TLocalizationReview = class
  private
    FApplicationId: string;
    FLanguageCode: string;
    FFramework: TTargetFramework;
    FTextDirection: string;
    FControls: TObjectList<TLayoutControl>;
    FFindings: TObjectList<TLocalizationFinding>;
    FProposals: TObjectList<TLayoutProposal>;
    FHighRiskCount: Integer;
    FWarningCount: Integer;
    FLowConfidenceCount: Integer;
    FDesignerAutomaticCount: Integer;
    FRuntimeWiredCount: Integer;
    FRuntimeUnwiredCount: Integer;
    FApplicationDataCount: Integer;
    FSuspiciousCount: Integer;
    FExcludedCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Summary: string;
    property ApplicationId: string read FApplicationId write FApplicationId;
    property LanguageCode: string read FLanguageCode write FLanguageCode;
    { Which framework will draw these controls. Text is measured the way that
      framework measures it, so planning a VCL form with FireMonkey metrics -
      which is what happened before this was carried through - sizes every
      caption from the wrong ruler. }
    property Framework: TTargetFramework read FFramework write FFramework;
    { 'rtl' for Arabic, Hebrew, Farsi and Urdu; 'ltr' for everything else. A
      right-to-left interface is not a right-to-left string: the whole layout
      is reflected, so this has to reach the planner and not merely the pack. }
    property TextDirection: string read FTextDirection write FTextDirection;
    property Controls: TObjectList<TLayoutControl> read FControls;
    property Findings: TObjectList<TLocalizationFinding> read FFindings;
    property Proposals: TObjectList<TLayoutProposal> read FProposals;
    property HighRiskCount: Integer read FHighRiskCount write FHighRiskCount;
    property WarningCount: Integer read FWarningCount write FWarningCount;
    property LowConfidenceCount: Integer read FLowConfidenceCount write FLowConfidenceCount;
    property DesignerAutomaticCount: Integer read FDesignerAutomaticCount write FDesignerAutomaticCount;
    property RuntimeWiredCount: Integer read FRuntimeWiredCount write FRuntimeWiredCount;
    property RuntimeUnwiredCount: Integer read FRuntimeUnwiredCount write FRuntimeUnwiredCount;
    property ApplicationDataCount: Integer read FApplicationDataCount write FApplicationDataCount;
    property SuspiciousCount: Integer read FSuspiciousCount write FSuspiciousCount;
    property ExcludedCount: Integer read FExcludedCount write FExcludedCount;
  end;

  TLocalizationReviewer = class
  private
    class procedure ScanLayout(const ACatalog: TTranslationCatalog;
      const AReview: TLocalizationReview); static;
    class procedure AnalyzeTranslations(const ACatalog: TTranslationCatalog;
      const AReview: TLocalizationReview); static;
    class procedure AnalyzeLayout(const AReview: TLocalizationReview); static;
  public
    class function Analyze(const ACatalog: TTranslationCatalog):
      TLocalizationReview; static;
    class procedure SaveProposal(const AReview: TLocalizationReview;
      const AFileName: string); static;
    class procedure RestoreDecisions(const AReview: TLocalizationReview;
      const AFileName: string); static;
    class procedure SaveEnvelope(const ACatalogFiles: TArray<string>;
      const AFileName: string); static;
    class procedure GenerateReviewPackage(const AReview: TLocalizationReview;
      const AHtmlFileName, AProposalFileName: string); static;
  end;

function LocalizationFindingSeverityText(
  const ASeverity: TLocalizationFindingSeverity): string;

implementation

uses
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  DAT.Core.CatalogJson,
  DAT.Review.CodeGeometry,
  DAT.Review.TextMeasurement,
  DAT.Runtime.LanguagePack,
  DAT.Scan.TextCodec;

type
  TObjectFrame = record
    Name: string;
    ClassName: string;
    Control: TLayoutControl;
  end;

function LocalizationFindingSeverityText(
  const ASeverity: TLocalizationFindingSeverity): string;
begin
  case ASeverity of
    lfsInformation: Result := 'Information';
    lfsWarning: Result := 'Warning';
    lfsHighRisk: Result := 'High risk';
  else
    Result := 'Unknown';
  end;
end;

function HtmlEncode(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

{ FireMonkey writes a font weight as a binary record, so boldness arrives as
  a run of hex rather than a readable set. The second byte carries the weight
  on the TFontWeight scale, where Regular is four and Bold is seven, and it
  is the only part of the record that concerns measurement. The VCL writes a
  readable set instead, handled beside this. }
function IsBoldStyleExt(const AValue: string): Boolean;
var
  Digits: string;
  Weight: Integer;
begin
  Result := False;
  Digits := AValue;
  Digits := StringReplace(Digits, '{', '', [rfReplaceAll]);
  Digits := StringReplace(Digits, '}', '', [rfReplaceAll]);
  Digits := Trim(StringReplace(Digits, ' ', '', [rfReplaceAll]));
  if Length(Digits) < 4 then
    Exit;
  if not TryStrToInt('$' + Copy(Digits, 3, 2), Weight) then
    Exit;
  { Semi-bold and heavier are wide enough to matter. }
  Result := Weight >= 6;
end;

function InvariantFloat(const AValue: string; out AResult: Double): Boolean;
var
  Settings: TFormatSettings;
begin
  Settings := TFormatSettings.Create('en-US');
  Result := TryStrToFloat(Trim(AValue), AResult, Settings);
end;

function ParseObject(const ALine: string; out AName, AClassName: string): Boolean;
var
  Text: string;
  P: Integer;
begin
  Text := Trim(ALine);
  Result := StartsText('object ', Text) or StartsText('inherited ', Text) or
    StartsText('inline ', Text);
  if not Result then
    Exit;
  P := Pos(' ', Text);
  Delete(Text, 1, P);
  P := Pos(':', Text);
  Result := P > 0;
  if Result then
  begin
    AName := Trim(Copy(Text, 1, P - 1));
    AClassName := Trim(Copy(Text, P + 1, MaxInt));
  end;
end;

{ The heading a grid column carries, which the catalogue files under the grid
  rather than under the column: "grdSchedule.Columns[0].Title.Caption". }
procedure CatalogTextForColumn(const ACatalog: TTranslationCatalog;
  const AFormName, AGridName: string; const AColumnIndex: Integer;
  out ASourceText, ATranslatedText: string);
var
  Entry: TTranslationEntry;
  Wanted: string;
  ColumnName: string;
begin
  ASourceText := '';
  ATranslatedText := '';
  if ACatalog = nil then
    Exit;
  { A column heading is filed under one of two names, and only one of them
    was being looked for.

    The scanner writes the column as a component in its own right -
    DBGrid1.Columns[0] carrying Title.Caption - which is the shape every
    real catalogue in this product contains. This looked instead for the
    grid carrying Columns[0].Title.Caption, found nothing, and handed back
    an empty translation. A column with no translated text is skipped by
    the sizing pass, so no heading was ever measured and none was ever
    widened: an Arabic heading needing a hundred and twenty four pixels
    sat in a column drawn at a hundred and fifteen with its first letter
    clipped, and nothing in the pack said otherwise.

    Both shapes are accepted rather than one being chosen, because a
    catalogue written by an older build carries the other one. }
  Wanted := Format('Columns[%d].Title.Caption', [AColumnIndex]);
  ColumnName := Format('%s.Columns[%d]', [AGridName, AColumnIndex]);
  for Entry in ACatalog.Entries do
    if SameText(Entry.FormName, AFormName) and
      ((SameText(Entry.ComponentName, AGridName) and
        SameText(Entry.PropertyName, Wanted)) or
       (SameText(Entry.ComponentName, ColumnName) and
        SameText(Entry.PropertyName, 'Title.Caption'))) then
    begin
      ASourceText := Entry.SourceText;
      ATranslatedText := Entry.TranslatedText;
      Exit;
    end;
end;

function CatalogTextForControl(const ACatalog: TTranslationCatalog;
  const AFormName, AComponentName: string; out ASource,
  ATranslation: string): Boolean;
var
  Entry: TTranslationEntry;
begin
  Result := False;
  ASource := '';
  ATranslation := '';
  for Entry in ACatalog.Entries do
    if SameText(Entry.FormName, AFormName) and
       SameText(Entry.ComponentName, AComponentName) and
       (ContainsText(Entry.PropertyName, 'Text') or
        ContainsText(Entry.PropertyName, 'Caption') or
        ContainsText(Entry.PropertyName, 'Header')) then
    begin
      ASource := Entry.SourceText;
      ATranslation := Entry.TranslatedText;
      Exit(True);
    end;
end;

procedure AddFinding(const AReview: TLocalizationReview;
  const ASeverity: TLocalizationFindingSeverity; const ACategory, AKey,
  AMessage, ARecommendation: string);
var
  Finding: TLocalizationFinding;
begin
  Finding := TLocalizationFinding.Create;
  Finding.Severity := ASeverity;
  Finding.Category := ACategory;
  Finding.Key := AKey;
  Finding.MessageText := AMessage;
  Finding.Recommendation := ARecommendation;
  AReview.Findings.Add(Finding);
  if ASeverity = lfsHighRisk then
    AReview.HighRiskCount := AReview.HighRiskCount + 1
  else if ASeverity = lfsWarning then
    AReview.WarningCount := AReview.WarningCount + 1;
end;

procedure EnrichFinding(const AFinding: TLocalizationFinding;
  const AEntry: TTranslationEntry);
begin
  if (AFinding = nil) or (AEntry = nil) then
    Exit;
  AFinding.SourceText := AEntry.SourceText;
  AFinding.TranslatedText := AEntry.TranslatedText;
  AFinding.Ownership := TextOwnershipDisplayName(AEntry.TextOwnership);
  AFinding.Provenance := TranslationOriginDisplayName(AEntry.TranslationOrigin);
end;

{ The opposite edge, for the handful of properties that name one.

  Reflecting coordinates is only half a mirror. A control with Align = alLeft
  is placed by the framework, not by its Left, so moving its coordinate
  achieves nothing at all and the navigation strip stays stubbornly on the
  left of a right-to-left form. The constant is the thing that has to change.

  Anchors are the same story one step later. A control anchored to the left
  edge alone keeps its distance from that edge when the window is resized, so
  in a mirrored layout it drifts away from the edge the reader is working
  from. Anchored to both edges it stretches, which is already symmetrical and
  is left alone.

  Everything here answers with an empty string when there is nothing to
  change, so a caller can tell "flipped" from "no opinion". }

function MirroredAlign(const AValue: string): string;
var
  Trimmed: string;
begin
  Result := '';
  Trimmed := Trim(AValue);
  { The VCL writes alLeft; FireMonkey has written both alLeft and Left across
    versions, and MostLeft for the outermost band. }
  if MatchText(Trimmed, ['alLeft', 'Left']) then
    Result := Copy(Trimmed, 1, Length(Trimmed) - 4) + 'Right'
  else if MatchText(Trimmed, ['alRight', 'Right']) then
    Result := Copy(Trimmed, 1, Length(Trimmed) - 5) + 'Left'
  else if MatchText(Trimmed, ['alMostLeft', 'MostLeft']) then
    Result := Copy(Trimmed, 1, Length(Trimmed) - 8) + 'MostRight'
  else if MatchText(Trimmed, ['alMostRight', 'MostRight']) then
    Result := Copy(Trimmed, 1, Length(Trimmed) - 9) + 'MostLeft';
end;

function MirroredTextAlign(const AValue: string): string;
var
  Trimmed: string;
begin
  Result := '';
  Trimmed := Trim(AValue);
  { Centre is centre in every language and is deliberately absent here. }
  if MatchText(Trimmed, ['taLeftJustify']) then
    Result := 'taRightJustify'
  else if MatchText(Trimmed, ['taRightJustify']) then
    Result := 'taLeftJustify'
  else if MatchText(Trimmed, ['Leading', 'TTextAlign.Leading']) then
    Result := 'Trailing'
  else if MatchText(Trimmed, ['Trailing', 'TTextAlign.Trailing']) then
    Result := 'Leading';
end;

function MirroredAnchors(const AValue: string): string;
var
  Body: string;
  HasLeft, HasRight: Boolean;
begin
  Result := '';
  Body := Trim(AValue);
  if Body = '' then
    Exit;
  Body := StringReplace(Body, '[', '', [rfReplaceAll]);
  Body := StringReplace(Body, ']', '', [rfReplaceAll]);
  HasLeft := ContainsText(Body, 'akLeft');
  HasRight := ContainsText(Body, 'akRight');
  { Anchored to both edges the control stretches, which is symmetrical
    already. Anchored to neither there is nothing horizontal to change. }
  if HasLeft = HasRight then
    Exit;
  if HasLeft then
    Body := StringReplace(Body, 'akLeft', 'akRight', [rfReplaceAll,
      rfIgnoreCase])
  else
    Body := StringReplace(Body, 'akRight', 'akLeft', [rfReplaceAll,
      rfIgnoreCase]);
  Result := StringReplace(Trim(Body), ' ', '', [rfReplaceAll]);
end;

{ The largest tab order among the controls sharing this one's parent. }
function HighestTabOrderAmongSiblings(const AReview: TLocalizationReview;
  const AControl: TLayoutControl): Integer;
var
  Candidate: TLayoutControl;
begin
  Result := 0;
  for Candidate in AReview.Controls do
    if Candidate.HasTabOrder and
      SameText(Candidate.FormName, AControl.FormName) and
      SameText(Candidate.ParentName, AControl.ParentName) and
      (Candidate.TabOrder > Result) then
      Result := Candidate.TabOrder;
end;

{ How many columns were modelled under this control. A column is carried as a
  pseudo-control named grid.Columns[n], so counting them is counting those. }
function ColumnCountOf(const AReview: TLocalizationReview;
  const AControl: TLayoutControl): Integer;
var
  Candidate: TLayoutControl;
  Prefix: string;
begin
  Result := 0;
  Prefix := AControl.ComponentName + '.Columns[';
  for Candidate in AReview.Controls do
    if SameText(Candidate.FormName, AControl.FormName) and
      StartsText(Prefix, Candidate.ComponentName) then
      Inc(Result);
end;

{ A control that works a recording rather than a sentence.

  Rewind, play and stop refer to the direction a tape moves. That direction is
  a fact about the machine, not about the language, so reversing a transport
  group puts rewind to the right of play in a language where the group now
  reads the other way - which says the opposite of what it means. Microsoft's
  and Apple's guidance agree: leave them.

  So the group is moved to the mirrored side of its parent as a block, keeping
  its internal order, rather than being reflected control by control. }
function IsTransportControl(const AControl: TLayoutControl): Boolean;
const
  Transport: array[0..12] of string = (
    'play', 'pause', 'stop', 'rewind', 'forward', 'record', 'eject',
    'skip', 'previous', 'next', 'seek', 'replay', 'shuffle');
var
  Word: string;
begin
  Result := False;
  if not ContainsText(AControl.ComponentClassName, 'Button') and
    not ContainsText(AControl.ComponentClassName, 'SpeedButton') then
    Exit;
  for Word in Transport do
    if ContainsText(AControl.ComponentName, Word) or
      ContainsText(AControl.SourceText, Word) then
      Exit(True);
end;

{ Whether this language is written right to left.

  The wizard settles this when the language is chosen - Arabic, Farsi, Hebrew
  and Urdu - and it travels with the catalog, so the planner asks rather than
  guesses. }
function IsRightToLeft(const AReview: TLocalizationReview): Boolean;
begin
  Result := (AReview <> nil) and SameText(Trim(AReview.TextDirection), 'rtl');
end;

{ The width a control is mirrored within: its parent's, or the form's where the
  parent is the form itself.

  The form is in the control list like everything else - it is the record whose
  component name is its own form name - so both cases are the same lookup. A
  control whose parent cannot be found is left alone rather than reflected
  against a guess, because mirroring against the wrong width is worse than not
  mirroring at all. }
function MirrorContainerWidth(const AReview: TLocalizationReview;
  const AControl: TLayoutControl): Double;
var
  Candidate: TLayoutControl;
  ParentName: string;
begin
  Result := 0;
  if (AReview = nil) or (AControl = nil) then
    Exit;
  ParentName := Trim(AControl.ParentName);
  if ParentName = '' then
    ParentName := AControl.FormName;
  for Candidate in AReview.Controls do
    if SameText(Candidate.FormName, AControl.FormName) and
      SameText(Candidate.ComponentName, ParentName) and
      Candidate.HasSize then
      Exit(Candidate.PlannedWidth);
end;

procedure AddProposal(const AReview: TLocalizationReview;
  const AControl: TLayoutControl; const APropertyName, ACurrent,
  AProposed, ARationale: string);
var
  ExistingNumber: Double;
  NewNumber: Double;
  DotAt: Integer;
  Proposal: TLayoutProposal;
begin
  for Proposal in AReview.Proposals do
    if SameText(Proposal.FormName, AControl.FormName) and
      SameText(Proposal.ComponentName, AControl.ComponentName) and
      SameText(Proposal.PropertyName, APropertyName) then
    begin
      if SameText(Proposal.ProposedValue, AProposed) then
        Exit;
      if TryStrToFloat(Proposal.ProposedValue, ExistingNumber,
          TFormatSettings.Invariant) and
        TryStrToFloat(AProposed, NewNumber, TFormatSettings.Invariant) and
        (NewNumber > ExistingNumber) then
      begin
        Proposal.ProposedValue := AProposed;
        Proposal.Rationale := ARationale;
      end;
      Exit;
    end;
  Proposal := TLayoutProposal.Create;
  Proposal.FormName := AControl.FormName;
  { A column is modelled under a name of its own - grdSchedule.Columns[0] -
    because everything that sizes a control looks controls up by name. The
    runtime has no such component to find, though: it has the grid, and a
    property path into it. The name is split back apart on the way out. }
  Proposal.ComponentName := AControl.ComponentName;
  Proposal.PropertyName := APropertyName;
  DotAt := Pos('.', AControl.ComponentName);
  if DotAt > 0 then
  begin
    Proposal.ComponentName := Copy(AControl.ComponentName, 1, DotAt - 1);
    Proposal.PropertyName := Copy(AControl.ComponentName, DotAt + 1,
      Length(AControl.ComponentName)) + '.' + APropertyName;
  end;
  Proposal.CurrentValue := ACurrent;
  Proposal.ProposedValue := AProposed;
  Proposal.Rationale := ARationale;
  { The geometry properties the runtime can apply are the whole point of the
    analysis, and they only reach the pack once accepted. Leaving them pending
    means a form is planned coherently and then ships with an arbitrary subset
    of that plan, which is worse than shipping none of it: a caption is
    widened while the control it displaced stays put. Start them accepted;
    RestoreDecisions still lets an explicit rejection from the review win. }
  { The same one list the exporter and both applicators use. A fourth copy of
    it lived here and decided which proposals start accepted, which is the
    decision that actually governs whether anything ships: a proposal left
    pending is dropped by the exporter without a word. Every right-to-left
    decision the planner made was created pending and thrown away for that
    reason - the plan was right, the pack was empty, and nothing anywhere
    said so. }
  if IsRuntimeLayoutProperty(Proposal.PropertyName) then
    Proposal.Decision := 'accepted'
  else
    Proposal.Decision := 'pending';
  Proposal.SourceChecksum := THashSHA2.GetHashString(
    AControl.SourceText + '|' + ACurrent);
  AReview.Proposals.Add(Proposal);
end;

constructor TLocalizationReview.Create;
begin
  inherited Create;
  FFramework := tfUnknown;
  FTextDirection := 'ltr';
  FControls := TObjectList<TLayoutControl>.Create(True);
  FFindings := TObjectList<TLocalizationFinding>.Create(True);
  FProposals := TObjectList<TLayoutProposal>.Create(True);
end;

destructor TLocalizationReview.Destroy;
begin
  FProposals.Free;
  FFindings.Free;
  FControls.Free;
  inherited Destroy;
end;

function TLocalizationReview.Summary: string;
begin
  Result := Format('%d controls inspected | %d layout/quality findings | ' +
    '%d high risk | %d warnings | %d proposals | %d low-confidence translations' +
    sLineBreak + 'Ownership: %d designer automatic | %d runtime wired | ' +
    '%d runtime not wired | %d application/data | %d suspicious | %d excluded',
    [Controls.Count, Findings.Count, HighRiskCount, WarningCount,
     Proposals.Count, LowConfidenceCount, DesignerAutomaticCount,
     RuntimeWiredCount, RuntimeUnwiredCount, ApplicationDataCount,
     SuspiciousCount, ExcludedCount]);
end;

const
  { What a control's text measures when nothing on the form says otherwise.
    Nine points is the Windows interface font, which a .dfm records as a height
    of twelve pixels; FireMonkey counts in its own units and starts at twelve.
    Both the scan and the analysis read these, so they live out here. }
  DefaultVCLFontSize = 9;
  DefaultFireMonkeyFontSize = 12;

class procedure TLocalizationReviewer.ScanLayout(
  const ACatalog: TTranslationCatalog; const AReview: TLocalizationReview);
var
  CodePositioned: TStringList;
  Entry: TTranslationEntry;
  Files: TStringList;
  Lines: TStringList;
  Stack: TList<TObjectFrame>;
  FileName, Line, Prop, Value, Name, ClassName, FormName: string;
  SourceText, TranslatedText: string;
  I, P: Integer;
  CollectionDepth: Integer;
  CollectionProperty, CollectionOwner: string;
  CollectionItemIndex: Integer;
  CollectionFontSize: Double;
  ColumnControl: TLayoutControl;
  Frame, ParentFrame: TObjectFrame;
  Number: Double;
  BoolValue: Boolean;
begin
  Files := TStringList.Create;
  Lines := TStringList.Create;
  Stack := TList<TObjectFrame>.Create;
  try
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    for Entry in ACatalog.Entries do
      if TFile.Exists(Entry.SourceFileName) and
         MatchText(LowerCase(TPath.GetExtension(Entry.SourceFileName)),
           ['.fmx', '.dfm']) then
        Files.Add(Entry.SourceFileName);
    CodePositioned := nil;
    for FileName in Files do
    begin
      Stack.Clear;
      CollectionDepth := 0;
      CollectionProperty := '';
      CollectionOwner := '';
      CollectionItemIndex := -1;
      CollectionFontSize := DefaultVCLFontSize;
      ColumnControl := nil;
      { Which controls this form's own unit positions or sizes for itself.
        Read once per form; empty for the ordinary form nobody lays out by
        hand. }
      FreeAndNil(CodePositioned);
      CodePositioned := TCodeGeometry.ControlsPositionedInCode(FileName);
      LoadDelphiTextFile(FileName, Lines);
      FormName := '';
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        { Inside a collection nothing is an object and nothing closes one.

          A .dfm writes a collection as Columns = < item ... end item ... end >
          and every one of those item blocks is closed by a line reading "end".
          Those were being counted as objects closing, so a grid with three
          columns popped three frames that had never been pushed. The stack
          ran empty and every control after the grid looked like a top-level
          object - which is to say, like a form. That is how a group box came
          to be filed as a form of its own, and why the layout rules for the
          controls inside it named a form that does not exist at run time and
          were never applied to anything. The strings were unaffected, because
          the text scanner walks collections properly; only the layout half
          was reading the file this way. }
        if CollectionDepth > 0 then
        begin
          { A grid's columns are the one collection worth reading. Each item
            carries the heading and the width that has to hold it, and until
            now neither was measurable: a collection item is not an object, so
            the scan skipped straight over it and the planner never saw a
            column in its life. German is where that stops being survivable -
            a heading like Spielverabredungen is one unbreakable word, a grid
            heading does not wrap, and width is the only thing left to give.

            Each column is modelled as a control of its own, named for the
            grid and its position, so everything that already knows how to
            size a control can size a column too. It has a width but no
            position: where a column sits is the grid's business, and the
            passes that move things must leave it alone. }
          if SameText(CollectionProperty, 'Columns') then
          begin
            if SameText(Line, 'item') then
            begin
              Inc(CollectionItemIndex);
              ColumnControl := TLayoutControl.Create;
              ColumnControl.FormName := FormName;
              ColumnControl.ParentName := CollectionOwner;
              ColumnControl.ComponentName := Format('%s.Columns[%d]',
                [CollectionOwner, CollectionItemIndex]);
              ColumnControl.ComponentClassName := 'TColumn';
              ColumnControl.SourceFileName := FileName;
              ColumnControl.FontSize := CollectionFontSize;
              ColumnControl.HasSize := True;
              ColumnControl.HasPosition := False;
              CatalogTextForColumn(ACatalog, FormName, CollectionOwner,
                CollectionItemIndex, SourceText, TranslatedText);
              ColumnControl.SourceText := SourceText;
              ColumnControl.TranslatedText := TranslatedText;
              AReview.Controls.Add(ColumnControl);
            end
            else if (ColumnControl <> nil) and StartsText('Width', Line) then
            begin
              P := Pos('=', Line);
              if (P > 0) and TryStrToFloat(Trim(Copy(Line, P + 1, Length(Line))),
                Number, TFormatSettings.Invariant) then
                ColumnControl.Width := Number;
            end
            else if SameText(Line, 'end') then
              ColumnControl := nil;
          end;
          if EndsText('>', Line) then
          begin
            Dec(CollectionDepth);
            CollectionProperty := '';
            ColumnControl := nil;
          end;
          Continue;
        end;
        if ParseObject(Line, Name, ClassName) then
        begin
          Frame := Default(TObjectFrame);
          Frame.Name := Name;
          Frame.ClassName := ClassName;
          Frame.Control := TLayoutControl.Create;
          Frame.Control.ComponentName := Name;
          Frame.Control.ComponentClassName := ClassName;
          Frame.Control.SourceFileName := FileName;
          Frame.Control.GeometryOwnedByCode :=
            CodePositioned.IndexOf(Name) >= 0;

          { A property absent from a form file is not a property set to False:
            it is the framework's default, and the two frameworks disagree. A
            FireMonkey label wraps unless told otherwise; a VCL one does not.
            Reading the absence as False meant every FireMonkey caption was
            believed not to wrap, so a plan that kept text on one line was
            never written down - there was nothing to change - and the label
            wrapped anyway at run time. That is how the hero banner came to be
            drawn on two lines inside a box built for one, losing the top and
            bottom of both. }
          Frame.Control.WordWrap := SameText(TPath.GetExtension(FileName),
            '.fmx');
          { And a VCL label sizes itself unless told not to.

            TLabel.AutoSize is True by default, so a label that says nothing
            about it will widen to fit whatever caption it is given, on one
            line, however long. Reading the absence as False hid that: the
            planner saw a fixed box, decided wrapping would solve the overflow,
            and turned WordWrap on - but the caption is applied before the
            layout, so by then the label had already stretched itself to the
            full width of the Spanish sentence and ran off the side of the
            form. Knowing the label sizes itself is what lets the planner pin
            the width instead. }
          Frame.Control.AutoSize :=
            SameText(TPath.GetExtension(FileName), '.dfm') and
            SameText(ClassName, 'TLabel');
          { The size this control's text is actually drawn at.

            A VCL control with no font of its own draws in its parent's font,
            and almost none of them have one: a form says Font.Height = -12 and
            every label, button and check box on it inherits nine point text.
            Assuming twelve for all of them - which is what happened here until
            now - overstated every caption by a third. The planner measured
            text a third wider than it draws, and then "reduced" a font to
            10.2 points, which at run time is an increase. That is why a button
            filled up with its own caption, why a heading that had been
            correct wrapped onto three lines, and why returning to English
            looked smaller than the translation: English was the size the
            designer chose and the translation was inflated.

            FireMonkey is left exactly as it was. Its defaults differ and its
            nineteen contracts encode the current behaviour; changing both
            frameworks at once on the evidence of one would be a guess. }
          if Stack.Count = 0 then
          begin
            FormName := Name;
            if SameText(TPath.GetExtension(FileName), '.dfm') then
              Frame.Control.FontSize := DefaultVCLFontSize
            else
              Frame.Control.FontSize := DefaultFireMonkeyFontSize;
          end
          else
          begin
            ParentFrame := Stack[Stack.Count - 1];
            Frame.Control.ParentName := ParentFrame.Name;
            if SameText(TPath.GetExtension(FileName), '.dfm') then
              Frame.Control.FontSize := ParentFrame.Control.FontSize
            else
              Frame.Control.FontSize := DefaultFireMonkeyFontSize;
          end;
          Frame.Control.FormName := FormName;
          CatalogTextForControl(ACatalog, FormName, Name,
            SourceText, TranslatedText);
          Frame.Control.SourceText := SourceText;
          Frame.Control.TranslatedText := TranslatedText;
          AReview.Controls.Add(Frame.Control);
          Stack.Add(Frame);
          Continue;
        end;
        if SameText(Line, 'end') then
        begin
          if Stack.Count > 0 then
            Stack.Delete(Stack.Count - 1);
          Continue;
        end;
        if Stack.Count = 0 then
          Continue;
        P := Pos('=', Line);
        if P = 0 then
          Continue;
        { A value that opens with '<' and does not close on the same line is a
          collection; everything up to its closing '>' belongs to it. }
        if StartsText('<', Trim(Copy(Line, P + 1, Length(Line)))) and
          not EndsText('>', Line) then
        begin
          Inc(CollectionDepth);
          { Read from this line, not from Prop: that is assigned further down
            and still holds whatever the line before this one was called. }
          CollectionProperty := Trim(Copy(Line, 1, P - 1));
          CollectionItemIndex := -1;
          ColumnControl := nil;
          if Stack.Count > 0 then
          begin
            CollectionOwner := Stack[Stack.Count - 1].Name;
            CollectionFontSize := Stack[Stack.Count - 1].Control.FontSize;
          end
          else
          begin
            CollectionOwner := '';
            CollectionFontSize := DefaultVCLFontSize;
          end;
          Continue;
        end;
        Prop := Trim(Copy(Line, 1, P - 1));
        Value := Trim(Copy(Line, P + 1, MaxInt));
        Frame := Stack[Stack.Count - 1];
        if InvariantFloat(Value, Number) then
        begin
          if MatchText(Prop, ['Left', 'Position.X']) then
          begin Frame.Control.Left := Number; Frame.Control.HasPosition := True; end
          else if MatchText(Prop, ['Top', 'Position.Y']) then
          begin Frame.Control.Top := Number; Frame.Control.HasPosition := True; end
          else if MatchText(Prop, ['Width', 'Size.Width', 'ClientWidth']) then
          begin Frame.Control.Width := Number; Frame.Control.HasSize := True; end
          else if MatchText(Prop, ['Height', 'Size.Height', 'ClientHeight']) then
          begin Frame.Control.Height := Number; Frame.Control.HasSize := True; end
          else if MatchText(Prop, ['TextSettings.Font.Size', 'Font.Size']) then
            Frame.Control.FontSize := Number
          { A VCL form records a font by height in pixels, negative to mean the
            character height rather than the cell height, and that is what the
            designer writes: Font.Size appears in a .dfm only when someone has
            typed it. Reading only Font.Size meant every VCL control fell back
            to the twelve point default above, so text was planned larger than
            it is drawn and boxes were sized for something nobody sees. At the
            standard ninety-six dots per inch a point is four thirds of a
            pixel. }
          else if MatchText(Prop, ['Font.Height']) then
          begin
            { Rounded, because VCL rounds. A thirteen point font is stored as
              a height of seventeen pixels, and seventeen pixels is twelve and
              three quarter points back again; TFont.Size reports thirteen
              because it converts through MulDiv, which rounds to the nearest
              whole point. Keeping the fraction would have every font read back
              a quarter point smaller than the designer set, and every rule
              that preserves a font size would then think it had been shrunk. }
            if Number < 0 then
              Frame.Control.FontSize := Round(-Number * 72 / 96)
            else if Number > 0 then
              Frame.Control.FontSize := Round(Number * 72 / 96);
          end;
        end
        else if SameText(Prop, 'Align') then
          Frame.Control.Align := Value
        else if SameText(Prop, 'Anchors') then
          Frame.Control.Anchors := Value
        else if SameText(Prop, 'TabOrder') then
        begin
          if InvariantFloat(Value, Number) then
          begin
            Frame.Control.TabOrder := Round(Number);
            Frame.Control.HasTabOrder := True;
          end;
        end
        else if MatchText(Prop, ['TextSettings.HorzAlign', 'HorzAlign',
          'Alignment']) then
          Frame.Control.HorzAlign := Value
        else if MatchText(Prop, ['TextSettings.Font.Style', 'Font.Style']) then
          Frame.Control.FontBold := ContainsText(Value, 'fsBold')
        else if MatchText(Prop, ['TextSettings.Font.StyleExt',
          'Font.StyleExt']) then
          Frame.Control.FontBold := IsBoldStyleExt(Value)
        else if MatchText(Prop, ['WordWrap', 'AutoSize']) then
        begin
          BoolValue := SameText(Value, 'True');
          if SameText(Prop, 'WordWrap') then
            Frame.Control.WordWrap := BoolValue
          else
            Frame.Control.AutoSize := BoolValue;
        end;
      end;
    end;
  finally
    CodePositioned.Free;
    Stack.Free;
    Lines.Free;
    Files.Free;
  end;
end;

class procedure TLocalizationReviewer.AnalyzeTranslations(
  const ACatalog: TTranslationCatalog; const AReview: TLocalizationReview);
var
  Entry, Other: TTranslationEntry;
  Confidence: string;
begin
  for Entry in ACatalog.Entries do
  begin
    if Entry.Status in [tsExcluded, tsObsolete] then
      Continue;
    Confidence := LowerCase(Entry.TranslationConfidence);
    if Entry.SuspiciousReason <> '' then
    begin
      AddFinding(AReview, lfsHighRisk, 'Source quality', Entry.Key,
        Entry.SuspiciousReason,
        'Correct or explicitly approve the source text before automatic translation.');
      EnrichFinding(AReview.Findings.Last, Entry);
      Continue;
    end;
    if Entry.TextOwnership = tokRuntimeUnwired then
    begin
      AddFinding(AReview, lfsWarning, 'Runtime ownership', Entry.Key,
        TextOwnershipDisplayName(Entry.TextOwnership),
        'Call TranslateText or FormatTemplate when the application creates this text.');
      EnrichFinding(AReview.Findings.Last, Entry);
    end;
    if (Entry.TranslatedText = '') then
    begin
      AddFinding(AReview, lfsHighRisk, 'Translation', Entry.Key,
        'No translated text is available.', 'Translate this entry before release.');
      EnrichFinding(AReview.Findings.Last, Entry);
    end
    else if SameText(Trim(Entry.SourceText), Trim(Entry.TranslatedText)) and
      not (Entry.RuntimeTextRole in [rtrIdentifier, rtrDataValue, rtrExcluded]) then
    begin
      AddFinding(AReview, lfsWarning, 'Translation', Entry.Key,
        'Translation is identical to the source text.',
        'Confirm that this is a product name, acronym, or deliberate loan word.');
      EnrichFinding(AReview.Findings.Last, Entry);
    end
    else if (Confidence = '') or MatchText(Confidence, ['low', 'unknown']) then
    begin
      Inc(AReview.FLowConfidenceCount);
      AddFinding(AReview, lfsWarning, 'Confidence', Entry.Key,
        'Translation confidence is not established.',
        'Review this entry with context or add an approved glossary term.');
      EnrichFinding(AReview.Findings.Last, Entry);
    end;

    for Other in ACatalog.Entries do
      if (Other <> Entry) and (CompareText(Other.Key, Entry.Key) > 0) and
         SameText(Trim(Other.SourceText), Trim(Entry.SourceText)) and
         (Trim(Other.TranslatedText) <> '') and
         not SameText(Trim(Other.TranslatedText), Trim(Entry.TranslatedText)) and
         SameText(Other.SemanticConcept, Entry.SemanticConcept) then
        AddFinding(AReview, lfsWarning, 'Disagreement', Entry.Key,
          Format('The same source phrase has another translation at %s.',
            [Other.Key]),
          'Confirm whether the contexts differ; otherwise standardize in the project glossary.');
    if (AReview.Findings.Count > 0) and
      SameText(AReview.Findings.Last.Key, Entry.Key) and
      (AReview.Findings.Last.SourceText = '') then
      EnrichFinding(AReview.Findings.Last, Entry);
  end;
end;

class procedure TLocalizationReviewer.AnalyzeLayout(
  const AReview: TLocalizationReview);
const
  ControlGap = 8;
  MaximumSeparationPasses = 6;
  { Stands in for "no measured limit" while staying small enough to round into
    an integer safely. }
  UnboundedWidthAllowance = 100000;
  { How far apart two designed edges may sit and still count as one column. }
  ColumnTolerance = 6;
  { Below this width a control cannot hold a whole word, so wrapping it only
    produces fragments. }
  MinimumWrapWidth = 60;
  { More lines than this in a caption reads as a cramped block rather than a
    label, and is where shrinking the text becomes the better trade. }
  { Never shrink text past the point where it stops being comfortable to read. }
  MinimumReadableFontSize = 9;
  { Buttons further apart than this were never laid out as one row. }
  MaximumClusterGap = 40;
  { Controls touching by less than this were placed side by side, not stacked
    on purpose. }
  DesignedOverlapTolerance = 3;
  { How far a control may be displaced from where it was drawn. Beyond this a
    chain of pushes has stopped being a correction and become a rearrangement. }
  MaximumDrift = 120;
  { Padding a control keeps at the sides of wrapped text. }
  WrapSideAllowance = 6;
  { Gap kept between a caption and the frame the designer drew around it. }
  ContainerInset = 4;
  { Room a tick box or radio dot takes from the caption beside it. }
  TickBoxAllowance = 22;
  { A frame may grow this much to hold its own children, and no more. Beyond it
    the frame has stopped adjusting and started redesigning the form. }
  MaximumContainerGrowth = 2.0;
  { Text drawn at least this large is a title rather than a caption, and a
    title is the one thing worth widening across a form to keep on one line. }
  HeadingFontSize = 16;
  { As wide as a button may be grown to hold a caption that will not fit. }
  MinimumComfortableButtonWidth = 180;
  { More lines than this and a caption has become a paragraph. }
  MaximumWrappedLines = 4;
  { Text at least this long is a sentence rather than a label. }
  ParagraphTextLength = 60;
  { We measure with a default typeface; the application draws with whichever
    one it was designed in. Allow for the difference before concluding that a
    translation fits, since concluding wrongly leaves an auto-sizing control to
    resize itself at run time and walk into its neighbour. }
  MeasurementSafety = 1.08;
  CaptionFieldGap = 28;
  CentredRowTolerance = 12;
  { A reduction no deeper than this is preferable to wrapping a caption onto a
    second line, and no caption should ever be reduced further: past this the
    text reads as noticeably smaller than everything around it. }
  ModestFontReduction = 0.85;
  { Breathing room text keeps inside its control, each side. Text that reaches
    within a pixel or two of the edge fits by arithmetic and looks jammed, so
    a caption is only considered to fit when it clears these. }
  ButtonPaddingHorizontal = 12;
  ButtonPaddingVertical = 6;
  LabelPaddingHorizontal = 4;
  LabelPaddingVertical = 2;
  OtherPaddingHorizontal = 6;
  OtherPaddingVertical = 3;
var
  Control, Other: TLayoutControl;
  RequiredWidth, RequiredHeight, FontSize: Double;
  SettleGuard, SettleLines: Integer;
  SettleFont, SettleHeight: Double;
  SettleRoom, SettleNeeded, SettleCentre: Double;
  RowMembers, RowSettled: TList<TLayoutControl>;
  RowWidth, RowGap, RowRoom: Double;
  SettleRow: TList<TLayoutControl>;
  SettleAlone: Boolean;
  SettleWanted, SettleTakeLeft, SettleTakeRight: Double;
  SettleFloor: Double;
  SettleSavedLeft, SettleSavedWidth: Double;
  BalanceLines: Integer;
  BalanceWidth, BalanceStep: Double;
  MirrorWidth: Double;
  AlignSource: string;
  MirrorValue: string;
  MirrorHighest: Integer;
  MirrorBlockLeft, MirrorBlockRight: Double;
  MirrorGroup: TList<TLayoutControl>;
  SettleFits: Boolean;
  LineCount: Integer;
  NewWidth: Integer;
  IsButton: Boolean;
  IsWrappingText: Boolean;
  Pass: Integer;
  Moved: Boolean;
  Leader, Follower, ClampContainer: TLayoutControl;
  ClampLeft, ClampTop, ClampRight, ClampBottom: Double;
  LinesThatFit: Integer;
  RequiredLeft, Surplus, ReducedWidth, ReducedFont, ShiftedLeft: Double;
  RequiredTop, ReducedHeight, EffectiveFont: Double;
  NeededWidth, NeededHeight: Double;
  WrappedLines: Integer;
  PackedButtons, Cluster: TList<TLayoutControl>;
  UniformWidth, ClusterGap, ClusterLeft, ClusterOffset, Available, Total: Double;
  LeftRoom: Double;
  ClusterOverlaysDesign: Boolean;
  Candidate: TLayoutControl;
  SetFont, UniformFont, UniformHeight, DesignedPitch: Double;
  SavedFontSize: Double;
  SetFitsOneLine, RowCanWrap: Boolean;
  CaptionRow: TList<TLayoutControl>;
  PitchedCaptions: TList<TLayoutControl>;

  { Measure the translated text with the same engine that renders it at
    runtime. Character-count arithmetic cannot predict real glyph widths, so
    every sizing decision below starts from an actual measurement. }
  { Breathing room this class of control keeps between its text and its edge. }
  function PaddingHorizontal(const AControl: TLayoutControl): Double;
  begin
    if ContainsText(AControl.ComponentClassName, 'CheckBox') or
      ContainsText(AControl.ComponentClassName, 'RadioButton') then
      { The tick box or dot is drawn beside the caption and takes its room from
        the same width. Measuring the text against the whole control promises
        it space the glyph is already using, and the caption then wraps to a
        line the control was never given height for. }
      Result := OtherPaddingHorizontal + TickBoxAllowance
    else if ContainsText(AControl.ComponentClassName, 'Button') then
      Result := ButtonPaddingHorizontal
    else if ContainsText(AControl.ComponentClassName, 'Label') then
      Result := LabelPaddingHorizontal
    else
      Result := OtherPaddingHorizontal;
  end;

  function PaddingVertical(const AControl: TLayoutControl): Double;
  begin
    if ContainsText(AControl.ComponentClassName, 'Button') then
      Result := ButtonPaddingVertical
    else if ContainsText(AControl.ComponentClassName, 'Label') then
      Result := LabelPaddingVertical
    else
      Result := OtherPaddingVertical;
  end;

  { The lines the author wrote, as opposed to the lines wrapping will produce.
    A caption holding a hard break occupies at least as many lines as it has
    pieces, however wide the control is, and measuring the whole string as one
    run reports neither the width it needs nor the height. The silencing note
    on the settings page is two sentences separated by a break: measured as one
    run it was given the height of two lines and drew four, losing the top and
    bottom of the block. }
  function TextSegments(const AText: string): TArray<string>;
  var
    Normalised: string;
  begin
    Normalised := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
    Normalised := StringReplace(Normalised, #13, #10, [rfReplaceAll]);
    Result := Normalised.Split([#10]);
    if Length(Result) = 0 then
      Result := [AText];
  end;

  { Width of one run of text, without the control's padding.

    Measured by whichever framework will draw it. Everything else in this
    routine is arithmetic on top of this number, so this is the single point
    where planning meets the thing that actually renders. }
  function MeasuredTextWidth(const AControl: TLayoutControl;
    const AText: string): Double;
  var
    Measurer: ITextMeasurer;
    PointSize: Double;
  begin
    if Trim(AText) = '' then
      Exit(0);
    PointSize := AControl.PlannedFontSize;
    if PointSize <= 0 then
      PointSize := AControl.FontSize;
    Measurer := TTextMeasurement.Measurer(AReview.Framework);
    { No measurer at all means no framework unit was linked into whatever is
      running this. Returning zero would read as "every caption fits", which is
      the one answer guaranteed to be wrong, so the estimate below stands in:
      it is crude, but it is the right order of magnitude and it errs wide. }
    if Measurer = nil then
      Exit(Length(AText) * Max(PointSize, 9) * 0.6);
    Result := Measurer.TextWidth(AText, PointSize, AControl.FontBold);
  end;

  function TextWidthEstimate(const AControl: TLayoutControl): Double;
  var
    Segment: string;
    Widest: Double;
  begin
    if Trim(AControl.TranslatedText) = '' then
      Exit(0);
    { The width a control needs is the width of its longest authored line.
      Measuring every line end to end reports a caption needing the room of a
      paragraph, and the passes above would then widen or shrink it to suit a
      line that is never drawn. }
    Widest := 0;
    for Segment in TextSegments(AControl.TranslatedText) do
      Widest := Max(Widest, MeasuredTextWidth(AControl, Segment));
    { Ask for the room the text occupies plus the breathing room its class
      keeps, so a control sized from this reads properly rather than merely
      fitting by arithmetic. }
    Result := Widest + 2 * PaddingHorizontal(AControl);
  end;

  { The smallest this control's text may become. A caption reduced far below
    the size it was drawn at reads as noticeably smaller than everything around
    it, so the floor is a proportion of the designed size and not merely the
    point at which text stops being legible on its own. }
  function SmallestFontFor(const AControl: TLayoutControl): Double;
  begin
    Result := Max(MinimumReadableFontSize,
      Max(AControl.FontSize, 9) * ModestFontReduction);
  end;

  { Lines the translated text breaks into inside a control of the given width.
    Text wraps within the padding, so that is the room it has. }
  function WrappedLineCount(const AControl: TLayoutControl;
    const AWidth: Double): Integer;
  var
    Room: Double;
    Segment: string;
  begin
    Room := Max(AWidth - 2 * PaddingHorizontal(AControl), 1);
    { Each line the author wrote wraps on its own and cannot share a line with
      the next, so the count is the sum over them rather than one division of
      the total. A note written as two sentences with a break between them
      needs four lines in a box that fits two of its words across, and being
      told it needs two is how it came to be drawn with its head and feet cut
      off. }
    Result := 0;
    for Segment in TextSegments(AControl.TranslatedText) do
      Result := Result + Max(1,
        Ceil(MeasuredTextWidth(AControl, Segment) / Room));
    Result := Max(1, Result);
  end;

  function MeasuredLineHeight(const AControl: TLayoutControl): Double;
  var
    PointSize: Double;
  begin
    PointSize := AControl.PlannedFontSize;
    if PointSize <= 0 then
      PointSize := AControl.FontSize;
    Result := Max(PointSize, 9) * 1.65;
  end;

  { The height the translated text really occupies at the width and size we
    have planned for it. Granting a control fewer lines than its text needs
    does not shorten the text, it clips it, and a caption drawn right to left
    loses its beginning rather than its end. }
  function RequiredHeightFor(const AControl: TLayoutControl;
    const AWidth: Double): Double;
  begin
    Result := WrappedLineCount(AControl, AWidth) * MeasuredLineHeight(AControl) +
      2 * PaddingVertical(AControl);
  end;

  { The point size at which this control's text fits on one line inside the
    given width. Only the glyphs shrink with the size: the padding either side
    is fixed, so scaling the whole measured width leaves the text a fraction
    too wide and it wraps anyway, which is how one button in a row came to be
    twice the height of its neighbours. }
  function FontFittingOneLine(const AControl: TLayoutControl;
    const AWidth: Double): Double;
  var
    GlyphWidth, Room, Current: Double;
  begin
    Current := AControl.PlannedFontSize;
    if Current <= 0 then
      Current := AControl.FontSize;
    Current := Max(Current, 9);
    GlyphWidth := TextWidthEstimate(AControl) -
      2 * PaddingHorizontal(AControl);
    Room := AWidth - 2 * PaddingHorizontal(AControl);
    if (GlyphWidth <= 0) or (Room <= 0) then
      Exit(Current);
    if GlyphWidth <= Room then
      Exit(Current);
    Result := Current * Room / GlyphWidth;
  end;


  function ParentWidthFor(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
  begin
    Result := 0;
    for Candidate in AReview.Controls do
      if SameText(Candidate.FormName, AControl.FormName) and
        SameText(Candidate.ComponentName, AControl.ParentName) and
        Candidate.HasSize then
        Exit(Candidate.Width);
  end;

  { FireMonkey writes Trailing, the VCL writes taRightJustify, and either means
    the text is anchored to the control's right edge. }
  function IsRightAligned(const AControl: TLayoutControl): Boolean;
  begin
    Result := MatchText(Trim(AControl.HorzAlign),
      ['Trailing', 'TTextAlign.Trailing', 'taRightJustify']);
  end;

  function IsCentreAligned(const AControl: TLayoutControl): Boolean;
  begin
    Result := MatchText(Trim(AControl.HorzAlign),
      ['Center', 'TTextAlign.Center', 'taCenter']);
  end;

  { Apply a new width in the direction the text is anchored. Growing a
    right-aligned caption rightwards moves its text into whatever sits beside
    it, which on a form of captions and fields is always the field it labels. }
  procedure SetPlannedWidthRespectingAlignment(const AControl: TLayoutControl;
    const ANewWidth: Double);
  var
    DesignedRight: Double;
  begin
    DesignedRight := AControl.PlannedLeft + AControl.PlannedWidth;
    AControl.PlannedWidth := ANewWidth;
    if not AControl.HasPosition then
      Exit;
    if IsRightAligned(AControl) then
      AControl.PlannedLeft := Max(0, DesignedRight - ANewWidth)
    else if IsCentreAligned(AControl) then
      AControl.PlannedLeft := Max(0, AControl.Left + AControl.Width / 2 -
        ANewWidth / 2);
  end;

  function ShouldPreferWrap(const AControl: TLayoutControl): Boolean;
  begin
    Result := ContainsText(AControl.ComponentClassName, 'Label') or
      ContainsText(AControl.ComponentClassName, 'CheckBox') or
      ContainsText(AControl.ComponentClassName, 'RadioButton') or
      ContainsText(AControl.ComponentClassName, 'GroupBox') or
      ContainsText(AControl.ComponentClassName, 'Button');
  end;

  function CanMoveControl(const AControl: TLayoutControl): Boolean;
  begin
    Result := AControl.HasPosition and AControl.HasSize and
      ((Trim(AControl.Align) = '') or SameText(Trim(AControl.Align), 'None') or
       SameText(Trim(AControl.Align), 'TAlignLayout.None')) and
      not ContainsText(AControl.ComponentClassName, 'Form') and
      not ContainsText(AControl.ComponentClassName, 'Layout') and
      not ContainsText(AControl.ComponentClassName, 'Panel') and
      not ContainsText(AControl.ComponentClassName, 'Rectangle') and
      not ContainsText(AControl.ComponentClassName, 'Grid') and
      not ContainsText(AControl.ComponentClassName, 'WebBrowser');
  end;

  function IsVisualContainer(const AControl: TLayoutControl): Boolean;
  begin
    Result :=
      ContainsText(AControl.ComponentClassName, 'Rectangle') or
      ContainsText(AControl.ComponentClassName, 'Panel') or
      ContainsText(AControl.ComponentClassName, 'GroupBox') or
      ContainsText(AControl.ComponentClassName, 'Layout');
  end;

  { The control this one actually belongs to, when that is something with a
    size of its own. A child's position is expressed relative to its parent, so
    a checkbox at 2,4 inside a panel is nowhere near the coordinates of a shape
    drawn at the same numbers on the form. }
  function ParentContainerOf(const AControl: TLayoutControl): TLayoutControl;
  var
    Candidate: TLayoutControl;
  begin
    Result := nil;
    if Trim(AControl.ParentName) = '' then
      Exit;
    if SameText(AControl.ParentName, AControl.FormName) then
      Exit;
    for Candidate in AReview.Controls do
      if SameText(Candidate.FormName, AControl.FormName) and
        SameText(Candidate.ComponentName, AControl.ParentName) and
        Candidate.HasSize then
        Exit(Candidate);
  end;

  { The smallest shape the designer drew around this control. A caption sitting
    inside a rounded rectangle or a group box was framed deliberately, and that
    frame is a boundary the caption must respect however long its translation
    turns out to be.

    Containment is judged from the designed bounds because that is what the eye
    reads: in FireMonkey a control is frequently drawn inside a shape it does
    not belong to in the object tree. Note the direction of this rule. It only
    ever holds a caption in. Growing the frame to fit the caption is the same
    reasoning run backwards, and it ends with a decorative layout swallowing
    the form. }
  function DesignedContainerOf(const AControl: TLayoutControl): TLayoutControl;
  var
    Candidate: TLayoutControl;
    CandidateArea, SmallestArea: Double;
  begin
    Result := nil;
    SmallestArea := MaxDouble;
    if not AControl.HasPosition or not AControl.HasSize or
      IsVisualContainer(AControl) then
      Exit;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize or not IsVisualContainer(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) then
        Continue;
      if SameText(Candidate.ComponentName, Candidate.FormName) then
        Continue;
      if (AControl.Left < Candidate.Left - 1) or
        (AControl.Top < Candidate.Top - 1) or
        (AControl.Left + AControl.Width >
           Candidate.Left + Candidate.Width + 1) or
        (AControl.Top + AControl.Height >
           Candidate.Top + Candidate.Height + 1) then
        Continue;
      CandidateArea := Candidate.Width * Candidate.Height;
      if CandidateArea < SmallestArea then
      begin
        SmallestArea := CandidateArea;
        Result := Candidate;
      end;
    end;
  end;

  { True when nothing else that carries text shares this frame, so widening the
    control to fill it cannot land on a neighbour. }
  { Controls a person types or chooses into. They anchor a form: a caption may
    wrap, shrink or take the margin beside it, but it does not get to shove the
    field it labels across the screen. }
  function IsInputControl(const AControl: TLayoutControl): Boolean;
  begin
    Result :=
      ContainsText(AControl.ComponentClassName, 'Edit') or
      ContainsText(AControl.ComponentClassName, 'Combo') or
      ContainsText(AControl.ComponentClassName, 'Memo') or
      ContainsText(AControl.ComponentClassName, 'Spin') or
      ContainsText(AControl.ComponentClassName, 'Date') or
      ContainsText(AControl.ComponentClassName, 'Time') or
      ContainsText(AControl.ComponentClassName, 'Number') or
      ContainsText(AControl.ComponentClassName, 'Grid');
  end;

  { The frame that governs this control, whether it owns the control in the
    object tree or merely encloses it on screen. Every rule about containment
    has to agree on this: asking one question of the parent and another of the
    geometry is how a button in a group of three came to be treated as the only
    thing in its group box. }
  function ContainerOf(const AControl: TLayoutControl): TLayoutControl;
  begin
    Result := ParentContainerOf(AControl);
    if Result = nil then
      Result := DesignedContainerOf(AControl);
  end;

  function AloneInContainer(const AControl, AContainer: TLayoutControl): Boolean;
  var
    Candidate: TLayoutControl;
  begin
    Result := True;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or (Candidate = AContainer) or
        not Candidate.HasPosition or not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) then
        Continue;
      if IsVisualContainer(Candidate) then
        Continue;
      if ContainerOf(Candidate) = AContainer then
        Exit(False);
    end;
  end;

  { The right-hand edge of the designed content on this control's parent. The
    parent's own size is not always present in the scanned model, so fall back
    to the furthest edge the designer actually placed something at. Growth and
    separation stay inside this, which keeps a widened control on the form. }
  function ContentRightBound(const AControl: TLayoutControl): Double;
  var
    Candidate, Container: TLayoutControl;
    ParentWidth: Double;
  begin
    { A child is measured against the inside of its parent, whose own position
      does not enter into it. }
    Container := ParentContainerOf(AControl);
    if Container <> nil then
      Exit(Container.Width - ContainerInset);
    Container := DesignedContainerOf(AControl);
    if Container <> nil then
      Exit(Container.Left + Container.Width - ContainerInset);
    ParentWidth := ParentWidthFor(AControl);
    if ParentWidth > 0 then
      Exit(ParentWidth);
    Result := AControl.Left + AControl.Width;
    for Candidate in AReview.Controls do
      if SameText(Candidate.FormName, AControl.FormName) and
        SameText(Candidate.ParentName, AControl.ParentName) and
        Candidate.HasPosition and Candidate.HasSize then
        Result := Max(Result, Candidate.Left + Candidate.Width);
  end;

  { The bottom edge of the form holding this control, or zero when the scanned
    model does not record it. }
  function ContentBottomBound(const AControl: TLayoutControl): Double;
  var
    Candidate, Container: TLayoutControl;
  begin
    Result := 0;
    Container := ParentContainerOf(AControl);
    if Container <> nil then
      Exit(Container.Height - ContainerInset);
    Container := DesignedContainerOf(AControl);
    if Container <> nil then
      Exit(Container.Top + Container.Height - ContainerInset);
    for Candidate in AReview.Controls do
      if SameText(Candidate.FormName, AControl.FormName) and
        SameText(Candidate.ComponentName, AControl.FormName) and
        Candidate.HasSize then
        Exit(Candidate.Height);
  end;

  { Prose, as opposed to a caption. Explanatory sentences want to wrap into a
    block; widening them buys one very long line the eye has to track across
    the form. Judge by the length of the text rather than by how much room the
    control happens to occupy, since a short caption inside a small frame fills
    its space too. }
  function IsParagraphWidth(const AControl: TLayoutControl): Boolean;
  begin
    Result := Length(Trim(AControl.TranslatedText)) >= ParagraphTextLength;
  end;

  { A paragraph is not a field caption, whichever language it is read in.

    Captions are short: a few words naming the control beside or below them.
    A block of prose that happens to sit above a field is not naming it, and
    treating it as that field's caption carries the whole paragraph into the
    field's column. The introduction on the VCL test form was moved three
    hundred and seventy pixels right and a hundred and thirty up, landing
    across a panel, colliding with another caption and running off the edge of
    the form, because a text box lower down happened to be the nearest thing
    underneath it.

    Judged on the source text as well as the translation, so a control does
    not change character merely because one language renders it longer. }
  function IsParagraphLike(const AControl: TLayoutControl): Boolean;
  begin
    Result := (Length(Trim(AControl.SourceText)) >= ParagraphTextLength) or
      (Length(Trim(AControl.TranslatedText)) >= ParagraphTextLength);
  end;

  { True when a control that is not a caption sits just under this one, close
    enough that the two read as a labelled field. }
  function HasFieldDirectlyBelow(const AControl: TLayoutControl): Boolean;
  const
    CloseEnough = 30;
  var
    Candidate: TLayoutControl;
    Gap: Double;
  begin
    Result := False;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize or IsVisualContainer(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.Left >= AControl.Left + AControl.Width) or
         (Candidate.Left + Candidate.Width <= AControl.Left) then
        Continue;
      Gap := Candidate.Top - (AControl.Top + AControl.Height);
      if (Gap > -AControl.Height) and (Gap < CloseEnough) then
        Exit(True);
    end;
  end;

  { The lowest edge anything above this control reaches, which is as far up as
    it may grow. }
  function RoomAbove(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
  begin
    Result := 0;
    for Candidate in AReview.Controls do
    begin
      { Everything above counts here, frames and grids included: growing a
        caption up into a panel is no better than growing it down into a
        field. }
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.Left >= AControl.Left + AControl.Width) or
         (Candidate.Left + Candidate.Width <= AControl.Left) then
        Continue;
      if Candidate.Top + Candidate.Height > AControl.Top then
        Continue;
      Result := Max(Result, Candidate.Top + Candidate.Height + ControlGap);
    end;
  end;

  { True when this control's planned box lands on a neighbour it was not drawn
    on top of. Controls the designer deliberately overlapped stay overlapped;
    only a collision this planning would have created is one to answer for. }
  function PlannedBoxIntrudes(const AControl: TLayoutControl): Boolean;
  var
    Candidate: TLayoutControl;

    function Overlaps(const ALeft, ATop, AWidth, AHeight: Double;
      const AOther: TLayoutControl): Boolean;
    begin
      Result := (ALeft < AOther.Left + AOther.Width) and
        (ALeft + AWidth > AOther.Left) and
        (ATop < AOther.Top + AOther.Height) and
        (ATop + AHeight > AOther.Top);
    end;

  begin
    Result := False;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if IsVisualContainer(Candidate) then
        Continue;
      { A caption drawn beside its own check box or edit shares a row with it
        by design and often ends up touching it; that is the pairing working,
        not an intrusion, and treating it as one shrank captions that were
        placed perfectly. Anything else - a button, another caption - is
        something this control has no business landing on, in any direction.
        The settings page put a caption straight through the button to its
        left, which a downward-only test could never have seen. }
      if IsInputControl(Candidate) or
        ContainsText(Candidate.ComponentClassName, 'CheckBox') or
        ContainsText(Candidate.ComponentClassName, 'RadioButton') then
        Continue;
      if not Overlaps(AControl.PlannedLeft, AControl.PlannedTop,
        AControl.PlannedWidth, AControl.PlannedHeight, Candidate) then
        Continue;
      { Drawn overlapping already, so not this planning's doing. }
      if Overlaps(AControl.Left, AControl.Top, AControl.Width,
        AControl.Height, Candidate) then
        Continue;
      Exit(True);
    end;
  end;

  { Where a control's edges are once the plan is taken into account. Before
    anything has been planned these are simply the designed edges. }
  function PlannedLeftEdge(const AControl: TLayoutControl): Double;
  begin
    if AControl.PlannedWidth > AControl.Width then
      Result := Min(AControl.PlannedLeft, AControl.Left)
    else
      Result := AControl.Left;
  end;

  function PlannedRightEdge(const AControl: TLayoutControl): Double;
  begin
    Result := Max(AControl.Left + AControl.Width,
      PlannedLeftEdge(AControl) + AControl.PlannedWidth);
  end;

  { How many lines this control can grow to before reaching whatever sits below
    it: the next control in its own column, the frame drawn around it, or the
    bottom of the form. This is what decides whether wrapping is affordable.
    Lines cost nothing where there is room for them; shrinking text to force a
    fixed line count makes a caption read smaller than its neighbours to solve
    a problem the form did not have. }
  function LinesFittingBelow(const AControl: TLayoutControl): Integer;
  var
    Candidate: TLayoutControl;
    Ceiling, Available, LineHeight, PointSize: Double;
  begin
    Ceiling := ContentBottomBound(AControl);
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if IsVisualContainer(Candidate) then
        Continue;
      if Candidate.Top < AControl.Top + AControl.Height - 1 then
        Continue;
      { Only something standing in this control's own column blocks it - and
        the column is where the control is going to be, not where it was
        drawn. A heading widened across half a form stands over things its
        designed box never reached: the email heading was measured in its
        original two hundred and thirty pixels, saw nothing beneath it,
        wrapped onto three lines and came down through the labels below. }
      if (Candidate.Left >= PlannedRightEdge(AControl)) or
         (Candidate.Left + Candidate.Width <= PlannedLeftEdge(AControl)) then
        Continue;
      if (Ceiling <= 0) or (Candidate.Top - ControlGap < Ceiling) then
        Ceiling := Candidate.Top - ControlGap;
    end;
    PointSize := AControl.PlannedFontSize;
    if PointSize <= 0 then
      PointSize := AControl.FontSize;
    LineHeight := Max(PointSize, 9) * 1.65;
    if Ceiling <= 0 then
      Available := AControl.Height
    else
      Available := Ceiling - AControl.Top;
    Available := Max(Available, AControl.Height);
    Result := Max(1, Floor((Available - 2 * PaddingVertical(AControl)) /
      Max(LineHeight, 1)));
    { Never fewer than the control's own box already holds: that height is
      room it certainly has, whatever stands beneath it. A flat floor of two
      lines instead claimed a second line existed wherever it was asked,
      including directly above a row of buttons with eighteen pixels of
      clearance, and every later decision believed it: the caption was given
      wrapping on the strength of a line it could not have, the separation
      pass took the height back to keep it off the buttons, and what remained
      was a caption wrapped, shrunk and cut off at once. Measure the room and
      report it. }
    Result := Max(1, Max(Result,
      Floor((AControl.Height - 2 * PaddingVertical(AControl)) /
        Max(LineHeight, 1))));
    { Never so many that a caption turns into a paragraph. }
    Result := Min(Result, MaximumWrappedLines);
  end;

  { The widest this control may become before it would cross either the edge of
    the designed content or the nearest fixed neighbour on the same row. }
  function AvailableWidth(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
    NearestLeft: Double;
    ParentWidth: Double;
    GrowsLeftwards: Boolean;
    NearestRight: Double;
    OwnRight: Double;
  begin
    { A right-aligned caption keeps its right edge and expands towards the
      left, so the room it has is the gap back to the previous control, not
      the gap forward to the next one. }
    GrowsLeftwards := IsRightAligned(AControl);
    OwnRight := AControl.PlannedLeft + AControl.PlannedWidth;
    NearestLeft := MaxDouble;
    NearestRight := -MaxDouble;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.PlannedTop >= AControl.PlannedTop +
            AControl.PlannedHeight) or
         (Candidate.PlannedTop + Candidate.PlannedHeight <=
            AControl.PlannedTop) then
        Continue;
      { A neighbour the separation pass can move is not a limit on how wide
        this control may become; it will be stepped aside instead. A field is
        the exception: it stays where the designer put it. }
      if CanMoveControl(Candidate) and not IsInputControl(Candidate) then
        Continue;
      if GrowsLeftwards then
      begin
        if (Candidate.PlannedLeft + Candidate.PlannedWidth <= OwnRight - 2) and
          (Candidate.PlannedLeft + Candidate.PlannedWidth > NearestRight) then
          NearestRight := Candidate.PlannedLeft + Candidate.PlannedWidth;
      end
      else if (Candidate.PlannedLeft > AControl.PlannedLeft + 2) and
        (Candidate.PlannedLeft < NearestLeft) then
        NearestLeft := Candidate.PlannedLeft;
    end;
    if GrowsLeftwards then
    begin
      if NearestRight > -MaxDouble then
        Result := OwnRight - NearestRight - ControlGap
      else
        Result := OwnRight;
    end
    else if NearestLeft < MaxDouble then
      Result := NearestLeft - AControl.PlannedLeft - ControlGap
    else
    begin
      ParentWidth := ParentWidthFor(AControl);
      if ParentWidth > 0 then
        Result := ParentWidth - AControl.PlannedLeft - ControlGap
      else
        { Nothing fixed sits to the right, so the only limit is the edge of the
          designed content. Returning the control's own width would pin it to
          its source-language size and clip the translation. }
        Result := ContentRightBound(AControl) - AControl.PlannedLeft -
          ControlGap;
    end;
    Result := Min(Result, UnboundedWidthAllowance);
    Result := Max(Result, 24);
  end;

  { True when nothing shares this control's row on the given side. When
    AIgnoreMovable is set, a sibling that the separation pass is free to move
    is not treated as an obstruction: capping a control's width against a
    neighbour that would simply step aside only clips the translation. }
  function RowIsFree(const AControl: TLayoutControl;
    const ATowardsRight, AIgnoreMovable: Boolean): Boolean;
  var
    Candidate: TLayoutControl;
  begin
    Result := True;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.PlannedTop >= AControl.PlannedTop +
            AControl.PlannedHeight) or
         (Candidate.PlannedTop + Candidate.PlannedHeight <=
            AControl.PlannedTop) then
        Continue;
      if AIgnoreMovable and CanMoveControl(Candidate) then
        Continue;
      if ATowardsRight then
      begin
        if Candidate.PlannedLeft > AControl.PlannedLeft then
          Exit(False);
      end
      else
        if Candidate.PlannedLeft < AControl.PlannedLeft then
          Exit(False);
    end;
  end;

  function BoundedTextWidth(const AControl: TLayoutControl;
    const ARequiredWidth: Double): Integer;
  var
    GrowthCap: Double;
    HardCap: Double;
  begin
    if ContainsText(AControl.ComponentClassName, 'Column') then
    begin
      GrowthCap := Max(AControl.Width * 1.60, 160);
      HardCap := 460;
    end
    else if ContainsText(AControl.ComponentClassName, 'Button') then
    begin
      GrowthCap := Max(AControl.Width * 1.20, 120);
      HardCap := 220;
    end
    else
    begin
      GrowthCap := Max(AControl.Width * 1.35, 180);
      HardCap := 360;
    end;
    { Both caps exist to stop a control expanding over its neighbours. Where
      the only things beside it are siblings the separation pass can move,
      there is nothing to protect, and the real limit is the space the row
      actually has, which AvailableWidth measures below. A fixed ceiling here
      makes a caption wrap on a wide form with an empty row beside it. }
    if RowIsFree(AControl, True, False) and RowIsFree(AControl, False, False) then
    begin
      { Nothing at all shares this row, so the space really is the control's to
        take and the only limit is the edge of the form. }
      GrowthCap := UnboundedWidthAllowance;
      HardCap := UnboundedWidthAllowance;
    end
    else if RowIsFree(AControl, True, True) then
      { Only movable siblings sit beside it, so the proportional cap has
        nothing to protect. The per-class ceiling still applies: the row is
        shared, and taking all of it would displace whatever is there. }
      GrowthCap := HardCap;
    Result := Ceil(Min(ARequiredWidth, Min(GrowthCap, HardCap)));
    { Never propose a width that would cross the parent edge or the next
      control on the same row. Wrapping absorbs whatever will not fit. }
    Result := Min(Result, Ceil(AvailableWidth(AControl)));
    if Result < Ceil(AControl.Width) then
      Result := Ceil(AControl.Width);
  end;

  { Unused margin to the left of this control, back to the nearest neighbour on
    its row or to the parent edge. A caption pinned against the field it labels
    can often take the room it needs from here, which leaves every field where
    the designer put it. }
  function SpaceToLeft(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
    NearestRight: Double;
  begin
    NearestRight := 0;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.PlannedTop >= AControl.PlannedTop +
            AControl.PlannedHeight) or
         (Candidate.PlannedTop + Candidate.PlannedHeight <=
            AControl.PlannedTop) then
        Continue;
      if Candidate.PlannedLeft + Candidate.PlannedWidth >
        AControl.PlannedLeft then
        Continue;
      NearestRight := Max(NearestRight,
        Candidate.PlannedLeft + Candidate.PlannedWidth);
    end;
    Result := Max(0, AControl.PlannedLeft - NearestRight - ControlGap);
  end;

  { True when these two already sat on top of one another in the designer.
    Overlapping controls are frequently deliberate: custom buttons laid over
    the navigator they replace, a caption over a shaped background, a badge
    over a graphic. Pulling those apart destroys the design, so only overlaps
    that translation itself introduced are worth resolving. }
  function DesignedOverlap(const AFirst, ASecond: TLayoutControl): Boolean;
  begin
    { Require a real overlap, not a hairline. Adjacent controls very often
      touch by a pixel or two through rounding, and treating that as a
      deliberate arrangement would excuse the analyser from separating them
      however far apart the translation later drives them. }
    Result :=
      (Min(AFirst.Left + AFirst.Width, ASecond.Left + ASecond.Width) -
        Max(AFirst.Left, ASecond.Left) > DesignedOverlapTolerance) and
      (Min(AFirst.Top + AFirst.Height, ASecond.Top + ASecond.Height) -
        Max(AFirst.Top, ASecond.Top) > DesignedOverlapTolerance);
  end;

  { Room before the next control on this row, counting every neighbour. This is
    deliberately stricter than AvailableWidth, which ignores neighbours the
    separation pass could move: a caption should take the unused margin on its
    left rather than expect the field beside it to shift along. }
  function SpaceToRight(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
    NearestLeft: Double;
  begin
    NearestLeft := MaxDouble;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Candidate.PlannedTop >= AControl.PlannedTop +
            AControl.PlannedHeight) or
         (Candidate.PlannedTop + Candidate.PlannedHeight <=
            AControl.PlannedTop) then
        Continue;
      if DesignedOverlap(AControl, Candidate) then
        Continue;
      if (Candidate.PlannedLeft > AControl.PlannedLeft + 2) and
        (Candidate.PlannedLeft < NearestLeft) then
        NearestLeft := Candidate.PlannedLeft;
    end;
    if NearestLeft < MaxDouble then
      Result := Max(24, NearestLeft - AControl.PlannedLeft - ControlGap)
    else
      Result := UnboundedWidthAllowance;
  end;

  function IsButtonLike(const AControl: TLayoutControl): Boolean;
  begin
    Result := ContainsText(AControl.ComponentClassName, 'Button') and
      not ContainsText(AControl.ComponentClassName, 'RadioButton') and
      not ContainsText(AControl.ComponentClassName, 'CheckBox');
  end;

  { The buttons drawn as one row with this control: same parent, same designed
    row, and close enough together to have been laid out as a set rather than
    placed independently. Ordered the way the designer placed them. }
  function CollectButtonRow(const AControl: TLayoutControl): TList<TLayoutControl>;
  var
    Candidate: TLayoutControl;
    Index, Scan: Integer;
    Swap: TLayoutControl;
  begin
    Result := TList<TLayoutControl>.Create;
    for Candidate in AReview.Controls do
    begin
      if not IsButtonLike(Candidate) or not Candidate.HasPosition or
        not Candidate.HasSize or not CanMoveControl(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if Abs((Candidate.Top + Candidate.Height / 2) -
        (AControl.Top + AControl.Height / 2)) >
        Max(8, Max(Candidate.Height, AControl.Height) * 0.55) then
        Continue;
      Result.Add(Candidate);
    end;
    for Index := 0 to Result.Count - 2 do
      for Scan := 0 to Result.Count - 2 - Index do
        if Result[Scan].Left > Result[Scan + 1].Left then
        begin
          Swap := Result[Scan];
          Result[Scan] := Result[Scan + 1];
          Result[Scan + 1] := Swap;
        end;
    { Only treat it as a row if the buttons sit close together. Two buttons at
      opposite ends of a form were never a set. }
    for Index := Result.Count - 1 downto 1 do
      if Result[Index].Left -
        (Result[Index - 1].Left + Result[Index - 1].Width) > MaximumClusterGap then
      begin
        Result.Clear;
        Break;
      end;
  end;

  { The buttons drawn as a column with this control: same parent, same left
    edge, and close enough one above the next to have been placed as a set.
    A stacked pair is as much a set as a row is, and reads worse when its
    members differ, because their left edges line up and their right edges
    then visibly do not. Ordered top to bottom. }
  function CollectButtonStack(const AControl: TLayoutControl): TList<TLayoutControl>;
  var
    Candidate: TLayoutControl;
    Index, Scan: Integer;
    Swap: TLayoutControl;
  begin
    Result := TList<TLayoutControl>.Create;
    for Candidate in AReview.Controls do
    begin
      if not IsButtonLike(Candidate) or not Candidate.HasPosition or
        not Candidate.HasSize or not CanMoveControl(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if Abs(Candidate.Left - AControl.Left) > DesignedOverlapTolerance then
        Continue;
      Result.Add(Candidate);
    end;
    for Index := 0 to Result.Count - 2 do
      for Scan := 0 to Result.Count - 2 - Index do
        if Result[Scan].Top > Result[Scan + 1].Top then
        begin
          Swap := Result[Scan];
          Result[Scan] := Result[Scan + 1];
          Result[Scan + 1] := Swap;
        end;
    { Two buttons at opposite ends of a form share a left edge by accident,
      not by design. }
    for Index := Result.Count - 1 downto 1 do
      if Result[Index].Top -
        (Result[Index - 1].Top + Result[Index - 1].Height) >
        MaximumClusterGap then
      begin
        Result.Clear;
        Break;
      end;
  end;

  { The captions drawn as one evenly spaced row with this control: same
    parent, same designed top and height, and a constant step from each to the
    next. The even step is the evidence that they were positioned as a set
    over something rather than placed one at a time. Returns them in the order
    the designer placed them, and reports the step. }
  function EffectiveFontOf(const AControl: TLayoutControl): Double;
  begin
    Result := AControl.PlannedFontSize;
    if Result <= 0 then
      Result := Max(AControl.FontSize, 9);
  end;

  { The field this control captions from directly above it. A caption written
    over its box, rather than beside it, is read down the column: the words and
    the box below them line up on the left, and that shared left edge is what
    ties the two together. Returns nil where there is no such field. }
  function FieldDirectlyBelow(const AControl: TLayoutControl): TLayoutControl;
  var
    Candidate: TLayoutControl;
    Nearest: Double;
  begin
    Result := nil;
    Nearest := MaxDouble;
    if IsInputControl(AControl) or IsButtonLike(AControl) or
      IsParagraphLike(AControl) then
      Exit;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize or not IsInputControl(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      { Below the caption's top, and close enough underneath to be the thing it
        names. Designers routinely let the two overlap by a few pixels, so the
        test is against the caption's top rather than its bottom. }
      if (Candidate.Top <= AControl.Top) or
        (Candidate.Top > AControl.Top + AControl.Height + CaptionFieldGap) then
        Continue;
      { And in the same column: a field off to one side is somebody else's. }
      if (Candidate.Left >= AControl.Left + AControl.Width) or
        (Candidate.Left + Candidate.Width <= AControl.Left) then
        Continue;
      if Candidate.Top < Nearest then
      begin
        Nearest := Candidate.Top;
        Result := Candidate;
      end;
    end;
  end;

  { True when this control was drawn level with a field on its own row. The
    pairing is how a reader tells which box a caption belongs to, and it is
    read vertically: the words level with the box are the words for that box.
    A caption with a partner therefore cannot be slid down the form to make
    room for something above it, however much room there is below. }
  function IsPairedWithField(const AControl: TLayoutControl): Boolean;
  var
    Candidate: TLayoutControl;
  begin
    Result := False;
    if IsInputControl(AControl) or IsButtonLike(AControl) or
      IsParagraphLike(AControl) then
      Exit;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize or not IsInputControl(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if Abs((Candidate.Top + Candidate.Height / 2) -
        (AControl.Top + AControl.Height / 2)) <=
        Max(8, Max(Candidate.Height, AControl.Height) * 0.55) then
        Exit(True);
    end;
  end;

  function CollectPitchedCaptionRow(const AControl: TLayoutControl;
    out APitch: Double): TList<TLayoutControl>;
  var
    Candidate: TLayoutControl;
    Index, Scan: Integer;
    Swap: TLayoutControl;
    Step: Double;
  begin
    APitch := 0;
    Result := TList<TLayoutControl>.Create;
    for Candidate in AReview.Controls do
    begin
      if not Candidate.HasPosition or not Candidate.HasSize or
        IsButtonLike(Candidate) or IsInputControl(Candidate) then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if (Abs(Candidate.Top - AControl.Top) > DesignedOverlapTolerance) or
        (Abs(Candidate.Height - AControl.Height) > DesignedOverlapTolerance) then
        Continue;
      Result.Add(Candidate);
    end;
    if Result.Count < 3 then
      Exit;
    for Index := 0 to Result.Count - 2 do
      for Scan := 0 to Result.Count - 2 - Index do
        if Result[Scan].Left > Result[Scan + 1].Left then
        begin
          Swap := Result[Scan];
          Result[Scan] := Result[Scan + 1];
          Result[Scan + 1] := Swap;
        end;
    APitch := Result[1].Left - Result[0].Left;
    if APitch <= 0 then
    begin
      Result.Clear;
      Exit;
    end;
    { One uneven step and this was never a pitched row. }
    for Index := 1 to Result.Count - 1 do
    begin
      Step := Result[Index].Left - Result[Index - 1].Left;
      if Abs(Step - APitch) > DesignedOverlapTolerance then
      begin
        Result.Clear;
        Exit;
      end;
    end;
  end;

  { What each framework calls the property that says which edge text sits
    against. Same decision, two spellings. }
  function TextAlignPropertyName(const AControl: TLayoutControl): string;
  begin
    if SameText(TPath.GetExtension(AControl.SourceFileName), '.dfm') then
      Result := 'Alignment'
    else
      Result := 'TextSettings.HorzAlign';
  end;

  { The alignment a form file does not bother to write down.

    A designer stores a property only when it differs from the default, so a
    label left as it was drawn carries no Alignment at all. Reading that
    absence as "nothing to mirror" is why stacked paragraphs came out ragged
    under a right-to-left language: each was placed correctly, against a
    shared right edge, and each then rendered its text hard against its own
    left edge - so blocks of different widths began in different places.

    The absence means the default, and the default mirrors like any other
    value. }
  function DefaultTextAlign(const AControl: TLayoutControl): string;
  begin
    if SameText(TextAlignPropertyName(AControl), 'Alignment') then
      Result := 'taLeftJustify'
    else
      Result := 'Leading';
  end;

  function PositionPropertyName(const AControl: TLayoutControl;
    const AAxis: string): string;
  begin
    if SameText(TPath.GetExtension(AControl.SourceFileName), '.dfm') then
      if SameText(AAxis, 'X') then
        Exit('Left')
      else
        Exit('Top');
    Result := 'Position.' + AAxis;
  end;

  { True when moving this control down to the given top would not put it on
    top of anything else it does not already sit on. }
  function DestinationIsClear(const AControl: TLayoutControl;
    const ATop: Double): Boolean;
  var
    Candidate: TLayoutControl;
  begin
    Result := True;
    for Candidate in AReview.Controls do
    begin
      if (Candidate = AControl) or not Candidate.HasPosition or
        not Candidate.HasSize then
        Continue;
      if not SameText(Candidate.FormName, AControl.FormName) or
        not SameText(Candidate.ParentName, AControl.ParentName) then
        Continue;
      if DesignedOverlap(AControl, Candidate) then
        Continue;
      if (AControl.PlannedLeft <
            Candidate.PlannedLeft + Candidate.PlannedWidth) and
         (AControl.PlannedLeft + AControl.PlannedWidth >
            Candidate.PlannedLeft) and
         (ATop < Candidate.PlannedTop + Candidate.PlannedHeight) and
         (ATop + AControl.PlannedHeight > Candidate.PlannedTop) then
        Exit(False);
    end;
  end;

  function PlannedOverlap(const AFirst, ASecond: TLayoutControl): Boolean;
  begin
    Result :=
      (AFirst.PlannedLeft < ASecond.PlannedLeft + ASecond.PlannedWidth) and
      (AFirst.PlannedLeft + AFirst.PlannedWidth > ASecond.PlannedLeft) and
      (AFirst.PlannedTop < ASecond.PlannedTop + ASecond.PlannedHeight) and
      (AFirst.PlannedTop + AFirst.PlannedHeight > ASecond.PlannedTop);
  end;

  { Row membership is a fact about the design, not about the working geometry.
    Reading it from planned values lets a caption that has grown taller be
    treated as sharing a row with the control beneath it, so a purely vertical
    crowding problem is answered by shoving one of them sideways. }
  function SamePlannedRow(const AFirst, ASecond: TLayoutControl): Boolean;
  begin
    Result := Abs((AFirst.Top + AFirst.Height / 2) -
      (ASecond.Top + ASecond.Height / 2)) <=
      Max(8, Max(AFirst.Height, ASecond.Height) * 0.55);
  end;

begin
  { Phase 1 - start every control from its designer geometry. }
  for Control in AReview.Controls do
  begin
    Control.PlannedLeft := Control.Left;
    Control.PlannedTop := Control.Top;
    Control.PlannedWidth := Control.Width;
    Control.PlannedHeight := Control.Height;
    { The plan starts from not wrapping, whatever the framework would do left
      to itself. Wrapping is something the passes below decide to ask for when
      the text needs it; seeding the plan with the framework default would mean
      every FireMonkey caption began life asking to wrap, and be granted the
      height of two lines it does not need. Control.WordWrap still records what
      the framework really does, which is what decides whether a rule has to be
      written. }
    Control.PlannedWordWrap := False;
    Control.PlannedFontSize := Control.FontSize;
  end;

  { Phase 2 - size each control against its measured translated text, writing
    the outcome back into the planned geometry. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasSize then
      Continue;
    FontSize := Max(Control.FontSize, 9);
    RequiredWidth := TextWidthEstimate(Control);
    { The headroom is only wanted where being wrong is expensive. A control with
      a fixed width that we measure slightly short simply sits a little tight;
      one that sizes itself will grow around the text at run time, to whatever
      width that takes, and walk into its neighbour. Give the second kind the
      benefit of the doubt. }
    if Control.AutoSize then
      RequiredWidth := RequiredWidth * MeasurementSafety;
    RequiredHeight := MeasuredLineHeight(Control);
    IsButton := ContainsText(Control.ComponentClassName, 'Button');
    IsWrappingText := ShouldPreferWrap(Control);
    if (Control.Width > 0) and (RequiredWidth > Control.Width) then
    begin
      AddFinding(AReview, lfsHighRisk, 'Layout',
        Control.FormName + '.' + Control.ComponentName,
        Format('Measured translated width %.0f exceeds the %.0f-pixel control.',
          [RequiredWidth, Control.Width]),
        'Review the proposed width, wrapping, or nearby control placement.');
      { Order of preference, most faithful to the design first.

        Growing a control is what starts every cascade: the neighbour has to
        move, the column it belonged to comes apart, and the row below is
        disturbed in turn. So try the operations that disturb nothing before
        the one that disturbs everything.

        1. Wrap inside the designed width. Position and width are untouched;
           only the height grows.
        2. If that needs an uncomfortable number of lines, reduce the font a
           little so it fits in fewer. This changes no geometry at all.
        3. Only when neither is enough, widen the control. }
      { A caption sitting immediately left of the field it labels has almost no
        room on its right, but forms usually leave a margin on the far left
        that nothing occupies. Sliding the caption back into that margin buys
        the width it needs and leaves every field exactly where it was drawn,
        which is better than wrapping the caption or shrinking its text. }
      { Captions only. A button is not a caption: it has no field to its right
        that it is naming, so sliding it towards one moves it away from the
        thing it was drawn against and buys nothing. Two buttons drawn as a
        pair against a shared right edge on the settings page were carried a
        hundred and twenty six and a hundred and forty two pixels to the left
        margin by this, arriving ragged and attached to nothing, while the
        space they left behind went unused. A button whose text has outgrown it
        wraps or takes a smaller size, as the passes below arrange. }
      if Control.HasPosition and not IsRightAligned(Control) and
        not IsCentreAligned(Control) and not IsParagraphWidth(Control) and
        not IsButtonLike(Control) and not IsInputControl(Control) and
        (RequiredWidth > SpaceToRight(Control)) then
      begin
        LeftRoom := SpaceToLeft(Control);
        ShiftedLeft := Min(LeftRoom, RequiredWidth - SpaceToRight(Control));
        if ShiftedLeft > 2 then
          Control.PlannedLeft := Max(0, Control.PlannedLeft - ShiftedLeft);
      end;
      { Widening only costs something when there is something beside the
        control to disturb. A heading alone on its row has empty space either
        side, and taking that space changes nothing else on the form, whereas
        wrapping it doubles its height and can push it into the row below.
        So where the row is genuinely clear, widen and stay on one line. }
      if RowIsFree(Control, True, False) and RowIsFree(Control, False, False) and
        not IsParagraphWidth(Control) then
      begin
        NewWidth := BoundedTextWidth(Control, RequiredWidth);
        if NewWidth > Ceil(Control.Width) then
        begin
          SetPlannedWidthRespectingAlignment(Control, NewWidth);
        end;
        if NewWidth < Ceil(RequiredWidth) then
        begin
          { Even the whole row was not enough, so fall back to wrapping. }
          Control.PlannedWordWrap := IsWrappingText;
          LineCount := WrappedLineCount(Control, Max(NewWidth, 24));
          if not IsButton then
            Control.PlannedHeight := Max(Control.PlannedHeight,
              Ceil(RequiredHeight * LineCount));
        end;
      end
      else if IsWrappingText and (Control.Width >= MinimumWrapWidth) and
        not IsParagraphWidth(Control) and
        (BoundedTextWidth(Control, RequiredWidth) >= RequiredWidth - 1) and
        (not IsRightAligned(Control) or RowIsFree(Control, False, False)) then
      begin
        { There is room beside this control for the whole caption, and that room
          is genuinely empty, so take it and stay on one line. Wrapping here
          would ask for height the form often has less of than width: a button
          in a stacked column has forty pixels above the next one but most of
          the form to its right.

          The room has to be empty rather than merely yielding. Taking space a
          neighbour occupies buys one line at the cost of displacing something,
          and where a caption can simply wrap instead, that trade is not worth
          making: the buttons beside a date caption should keep their places. }
        SetPlannedWidthRespectingAlignment(Control,
          BoundedTextWidth(Control, RequiredWidth));
      end
      else if IsWrappingText and (Control.Width >= MinimumWrapWidth) then
      begin
        { Wrapping doubles a control's height, which is a heavy price for text
          that only just overflows, and the extra height is often the thing
          that will not fit. Where a small reduction in size keeps the caption
          on the single line it was drawn for, take that instead. }
        ReducedFont := FontSize * Control.Width / Max(RequiredWidth, 1);
        { Not for a paragraph with room to wrap. Prose is written to run onto
          another line, and shrinking it instead buys a single line at the cost
          of making the whole block read smaller than the text around it. It is
          also the more fragile choice: a size chosen so the words only just
          reach the edge depends on our measurement being exact, and where it
          is a shade optimistic the text wraps at run time anyway, into a
          control whose height was fixed for one line. That is how the note on
          the folder screen came to be cut through the middle. }
        if (RequiredWidth > Control.Width) and
          not (IsParagraphWidth(Control) and (LinesFittingBelow(Control) > 1)) and
          (ReducedFont >= FontSize * ModestFontReduction) and
          (ReducedFont >= MinimumReadableFontSize) then
        begin
          Control.PlannedFontSize := ReducedFont;
          RequiredWidth := RequiredWidth * ReducedFont / FontSize;
          RequiredHeight := ReducedFont * 1.65;
        end;
        { A caption anchored to its right edge can still use whatever gap is
          genuinely empty on its left. Taking that first often turns three
          cramped lines into two comfortable ones, and it costs nothing: the
          gap belongs to no one. }
        if IsRightAligned(Control) and Control.HasPosition then
        begin
          { Take only what the line count needs. The gap beside a caption is
            often the whole left margin of the form, and swallowing it drags a
            short caption clear across the screen. }
          LeftRoom := Min(SpaceToLeft(Control),
            Max(0, RequiredWidth / Max(LinesFittingBelow(Control), 1) +
              2 * PaddingHorizontal(Control) - Control.PlannedWidth));
          if LeftRoom > 2 then
          begin
            Control.PlannedWidth := Control.PlannedWidth + LeftRoom;
            Control.PlannedLeft := Control.PlannedLeft - LeftRoom;
          end;
        end;
        Control.PlannedWordWrap := True;
        LineCount := WrappedLineCount(Control, Control.PlannedWidth);
        { Lines cost nothing where there is room for them. Shrinking text to
          force it into a fixed number of lines makes a caption read smaller
          than everything around it in order to solve a problem the form did
          not have. Count the lines that actually fit below the control and
          only reduce the size when the text needs more than that. }
        LinesThatFit := LinesFittingBelow(Control);
        if LineCount > LinesThatFit then
        begin
          { Shrink the text just enough for the lines that will fit, never
            below the readable floor. }
          ReducedFont := Max(SmallestFontFor(Control),
            FontSize * LinesThatFit / LineCount);
          if ReducedFont < FontSize then
          begin
            Control.PlannedFontSize := ReducedFont;
            RequiredWidth := RequiredWidth * ReducedFont / FontSize;
            RequiredHeight := ReducedFont * 1.65;
            LineCount := WrappedLineCount(Control, Control.Width);
          end;
        end;
        if LineCount > LinesThatFit then
        begin
          { Still cramped after shrinking, so widen as a last resort, only far
            enough to reach a line count that fits. }
          NewWidth := BoundedTextWidth(Control,
            RequiredWidth / Max(LinesThatFit, 1));
          if NewWidth > Ceil(Control.Width) then
          begin
            SetPlannedWidthRespectingAlignment(Control, NewWidth);
            LineCount := WrappedLineCount(Control, NewWidth);
          end;
        end;
        if not IsButton then
          Control.PlannedHeight := Max(Control.PlannedHeight,
            Ceil(RequiredHeight * LineCount));
      end
      else
      begin
        { A control that cannot wrap has only the two remaining options. }
        ReducedFont := Max(SmallestFontFor(Control),
          FontSize * Control.Width / RequiredWidth);
        if ReducedFont < FontSize then
        begin
          Control.PlannedFontSize := ReducedFont;
          RequiredWidth := RequiredWidth * ReducedFont / FontSize;
        end;
        if RequiredWidth > Control.Width then
          SetPlannedWidthRespectingAlignment(Control,
            BoundedTextWidth(Control, RequiredWidth));
      end;
    end;
    { Only a control whose text now needs more lines than the design allowed for
      should get more height. Our idea of a line is a little taller than the
      designer's, and growing every caption to match it quietly eats the gap
      below each one: a row of navigator captions eighteen pixels tall becomes
      twenty-two and closes on the grid above it, for text that still occupies
      a single line. }
    { And only where the text will really wrap. Height bought for lines a
      control is not going to draw leaves it standing taller than the captions
      beside it, off their baseline, for no visible gain. }
    if (Control.Height > 0) and (RequiredHeight > Control.Height) and
      Control.PlannedWordWrap and
      (WrappedLineCount(Control, Control.PlannedWidth) > 1) then
    begin
      AddFinding(AReview, lfsWarning, 'Layout',
        Control.FormName + '.' + Control.ComponentName,
        'The control may be too short for its translated text and font.',
        'Review the proposed height or enable automatic sizing.');
      Control.PlannedHeight := Max(Control.PlannedHeight, Ceil(RequiredHeight));
    end;
  end;

  { Phase 2b - a row of buttons is a set, not a collection of individuals.
    Navigator and dialog rows are drawn as equal buttons at an even pitch, and
    sizing each one on its own text breaks that pattern and pushes each into
    the small gap beside it. Size the whole row to its widest member and lay it
    out again at an even pitch, sharing the space the row actually has. }
  PackedButtons := TList<TLayoutControl>.Create;
  try
    for Control in AReview.Controls do
    begin
      if PackedButtons.IndexOf(Control) >= 0 then
        Continue;
      if not IsButtonLike(Control) or not Control.HasPosition or
        not Control.HasSize or not CanMoveControl(Control) then
        Continue;
      Cluster := CollectButtonRow(Control);
      try
        if Cluster.Count < 2 then
          Continue;
        for Other in Cluster do
          PackedButtons.Add(Other);

        { Every button takes the width of the hungriest, so the row stays
          uniform the way it was drawn. }
        UniformWidth := 0;
        for Other in Cluster do
          UniformWidth := Max(UniformWidth,
            Max(Other.Width, TextWidthEstimate(Other)));

        ClusterGap := ControlGap;
        if Cluster.Count > 1 then
          ClusterGap := Max(ControlGap,
            Cluster[1].Left - (Cluster[0].Left + Cluster[0].Width));
        ClusterLeft := Cluster[0].Left;
        Available := ContentRightBound(Cluster[0]) - ClusterLeft;
        Total := Cluster.Count * UniformWidth +
          (Cluster.Count - 1) * ClusterGap;
        if Total > Available then
        begin
          { The row cannot have everything it wants, so share what there is
            evenly and let the text wrap or shrink inside it. }
          { Round the shared width down. Dividing the space exactly leaves the
            last button ending a fraction beyond the edge, and the pass that
            holds controls inside their frame then pulls only that one back,
            breaking the even pitch the row is supposed to keep. }
          UniformWidth := Max(0,
            Floor((Available - (Cluster.Count - 1) * ClusterGap) /
              Cluster.Count));
          UniformWidth := Max(UniformWidth, 24);
        end;

        { If the row was drawn over something else, its placement is
          deliberate and repacking it would move the buttons off whatever they
          were positioned against. Size them, but leave them where they are. }
        ClusterOverlaysDesign := False;
        for Other in Cluster do
          for Candidate in AReview.Controls do
            if (Candidate <> Other) and (Cluster.IndexOf(Candidate) < 0) and
              Candidate.HasPosition and Candidate.HasSize and
              SameText(Candidate.FormName, Other.FormName) and
              SameText(Candidate.ParentName, Other.ParentName) and
              DesignedOverlap(Other, Candidate) then
              ClusterOverlaysDesign := True;
        if ClusterOverlaysDesign then
          Continue;

        { A row of buttons is read as one control. One member a size smaller
          than the rest, or twice the height because its caption wrapped,
          reads as a fault however carefully the boxes line up. So the row
          settles on a single size: the smallest any member needs to keep its
          text on the one line it was drawn for. }
        UniformFont := 0;
        for Other in Cluster do
        begin
          SetFont := Max(FontFittingOneLine(Other, UniformWidth),
            SmallestFontFor(Other));
          if (UniformFont = 0) or (SetFont < UniformFont) then
            UniformFont := SetFont;
        end;

        { A row drawn with equal margins either side of it was centred in its
          frame, and it should still look centred once its buttons have grown.
          Holding the left edge and letting the row extend to the right leaves
          it lopsided: the media controls kept a margin of thirty-eight on the
          left and were left with five on the right, which reads as a row that
          has slipped rather than one that was placed. }
        Total := Cluster.Count * UniformWidth + (Cluster.Count - 1) * ClusterGap;
        DesignedPitch := Cluster[Cluster.Count - 1].Left +
          Cluster[Cluster.Count - 1].Width;
        Available := ContentRightBound(Cluster[0]);
        if (Available > 0) and
          (Abs(Cluster[0].Left - (Available - DesignedPitch)) <=
            CentredRowTolerance) then
          ClusterLeft := Max(0, (Available - Total) / 2);

        ClusterOffset := ClusterLeft;
        for Other in Cluster do
        begin
          Other.PlannedLeft := ClusterOffset;
          Other.PlannedWidth := UniformWidth;
          if UniformFont < Max(Other.FontSize, 9) then
            Other.PlannedFontSize := UniformFont;
          ClusterOffset := ClusterOffset + UniformWidth + ClusterGap;
        end;

        { Wrapping belongs to the row, not to its longest caption. Where the
          shared size keeps every member on one line the row keeps the height
          it was drawn with; where one member still needs two lines they all
          take the same height, so the row stays level either way. }
        SetFitsOneLine := True;
        for Other in Cluster do
          if WrappedLineCount(Other, UniformWidth) > 1 then
            SetFitsOneLine := False;
        UniformHeight := 0;
        for Other in Cluster do
        begin
          Other.PlannedWordWrap := not SetFitsOneLine;
          if not SetFitsOneLine then
            UniformHeight := Max(UniformHeight,
              RequiredHeightFor(Other, UniformWidth));
        end;
        if not SetFitsOneLine then
          for Other in Cluster do
            Other.PlannedHeight := Max(Other.PlannedHeight,
              Ceil(UniformHeight));
      finally
        Cluster.Free;
      end;
    end;

    { The same courtesy for a stacked column. Its members share a left edge,
      so any difference in width shows along their right edges as a ragged
      step, and a column has the whole width beside it to grow into: there is
      no reason for one button in it to be wider than the next. }
    for Control in AReview.Controls do
    begin
      if PackedButtons.IndexOf(Control) >= 0 then
        Continue;
      if not IsButtonLike(Control) or not Control.HasPosition or
        not Control.HasSize or not CanMoveControl(Control) then
        Continue;
      Cluster := CollectButtonStack(Control);
      try
        if Cluster.Count < 2 then
          Continue;
        for Other in Cluster do
          PackedButtons.Add(Other);

        UniformWidth := 0;
        for Other in Cluster do
          UniformWidth := Max(UniformWidth,
            Max(Other.Width, TextWidthEstimate(Other)));
        UniformWidth := Min(UniformWidth,
          ContentRightBound(Cluster[0]) - Cluster[0].Left);

        UniformFont := 0;
        for Other in Cluster do
        begin
          SetFont := Max(FontFittingOneLine(Other, UniformWidth),
            SmallestFontFor(Other));
          if (UniformFont = 0) or (SetFont < UniformFont) then
            UniformFont := SetFont;
        end;

        for Other in Cluster do
        begin
          Other.PlannedWidth := UniformWidth;
          if UniformFont < Max(Other.FontSize, 9) then
            Other.PlannedFontSize := UniformFont;
        end;

        SetFitsOneLine := True;
        for Other in Cluster do
          if WrappedLineCount(Other, UniformWidth) > 1 then
            SetFitsOneLine := False;
        UniformHeight := 0;
        for Other in Cluster do
        begin
          Other.PlannedWordWrap := not SetFitsOneLine;
          if not SetFitsOneLine then
            UniformHeight := Max(UniformHeight,
              RequiredHeightFor(Other, UniformWidth));
        end;
        if not SetFitsOneLine then
          for Other in Cluster do
            Other.PlannedHeight := Max(Other.PlannedHeight,
              Ceil(UniformHeight));
      finally
        Cluster.Free;
      end;
    end;
  finally
    PackedButtons.Free;
  end;

  { Phase 2b2 - a caption written above its field shares that field's column.

    Where a caption sits beside its field it keeps its right edge and takes the
    empty margin on its left, because that is the edge the reader follows. A
    caption written above its field is read the other way: down the column, and
    the caption and the box beneath it line up on the left. Growing such a
    caption leftwards walks it off the box it belongs to and out over whatever
    is to the left, which is what the email settings page showed - a line of
    words starting well left of the box it names and running past it.

    So take the field's left edge and its width, and wrap inside them. The
    height that needs is taken upwards, keeping the caption's bottom against
    the box it labels; the passes below will take it back if the room above is
    not there. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasSize or
      not Control.HasPosition or (Control.PlannedWidth <= 0) then
      Continue;
    Follower := FieldDirectlyBelow(Control);
    if Follower = nil then
      Continue;
    SavedFontSize := Control.PlannedFontSize;
    { Judged against the box the caption was drawn in, not the one an earlier
      pass has already stretched it into. By this point a caption that would
      not fit has usually been widened leftwards, which is precisely the
      treatment being overruled here: measured against that new width it looks
      settled, and the question of whether it ever fitted where it was drawn
      has been lost. A caption that fits as drawn is left exactly alone. }
    if WrappedLineCount(Control, Control.Width) <= 1 then
      Continue;

    { The band the caption has to live in: clear of whatever is above it in the
      same column, and clear of the field itself. Growing onto the box is not
      an option - the words would be drawn across the thing they name - so
      where the band is too small the text is reduced to suit it rather than
      the box being encroached on. }
    ClampBottom := Follower.Top - ControlGap;
    ClampTop := 0;
    for Other in AReview.Controls do
    begin
      if (Other = Control) or (Other = Follower) or not Other.HasPosition or
        not Other.HasSize then
        Continue;
      if not SameText(Other.FormName, Control.FormName) or
        not SameText(Other.ParentName, Control.ParentName) then
        Continue;
      if IsVisualContainer(Other) then
        Continue;
      if (Other.Left >= Follower.Left + Follower.Width) or
        (Other.Left + Other.Width <= Follower.Left) then
        Continue;
      if Other.Top + Other.Height > ClampBottom then
        Continue;
      ClampTop := Max(ClampTop, Other.Top + Other.Height + ControlGap);
    end;

    NeededHeight := Ceil(RequiredHeightFor(Control, Follower.Width));
    { Where the band cannot hold the lines, reduce the size until it can, and
      only then. A floor applies: past a point a caption nobody can read is
      worse than one that sits tight. }
    while (NeededHeight > ClampBottom - ClampTop) and
      (EffectiveFontOf(Control) > SmallestFontFor(Control)) do
    begin
      Control.PlannedFontSize := Max(SmallestFontFor(Control),
        EffectiveFontOf(Control) - 0.5);
      NeededHeight := Ceil(RequiredHeightFor(Control, Follower.Width));
    end;
    { Where even a modest reduction will not fit the lines into the band, this
      treatment is declined rather than forced. Squeezing the caption over its
      box to a size nobody can read trades a tidy edge for an unreadable label,
      and the passes above have already found it somewhere workable. A caption
      that reaches this point is telling us the text is too long for the space
      the form gives it, which is a matter for the wording, not the geometry. }
    if NeededHeight > ClampBottom - ClampTop then
    begin
      Control.PlannedFontSize := SavedFontSize;
      Continue;
    end;

    Control.PlannedLeft := Follower.Left;
    Control.PlannedWidth := Follower.Width;
    Control.PlannedWordWrap := True;
    Control.PlannedHeight := Max(Control.PlannedHeight, NeededHeight);
    { Bottom against the box it names, so the pairing reads down the column. }
    Control.PlannedTop := ClampBottom - Control.PlannedHeight;
  end;

  { Phase 2c - a row of captions laid out at an even pitch keeps that pitch.
    Captions spaced evenly above a row of buttons are not placed where they
    happen to fit, they are placed over the thing each one names, and the
    reader checks them against the buttons rather than against each other.
    Sizing them one at a time walks them off their marks and the drift
    accumulates along the row, so the last caption ends up furthest from the
    control it belongs to. Hold the whole row where it was drawn and let the
    text size settle to fit the space each one has. }
  PitchedCaptions := TList<TLayoutControl>.Create;
  try
    for Control in AReview.Controls do
    begin
      if PitchedCaptions.IndexOf(Control) >= 0 then
        Continue;
      if not Control.HasPosition or not Control.HasSize or
        IsButtonLike(Control) or IsInputControl(Control) then
        Continue;
      CaptionRow := CollectPitchedCaptionRow(Control, DesignedPitch);
      try
        if CaptionRow.Count < 3 then
          Continue;
        for Other in CaptionRow do
          PitchedCaptions.Add(Other);

        { How far the shared size may fall. The modest floor protects a
          control from reading smaller than everything around it, which is a
          real risk when one caption shrinks alone and none of its neighbours
          do. A row shrinking together does not have that problem: it stays
          consistent with itself, which is the whole point of holding it as a
          set. So keep the modest floor while another line is still available
          and wrapping remains an option, and lift it when it is not. A
          caption row sitting directly above the buttons it names has nowhere
          to put a second line, and there the choice is between a slightly
          smaller row and a clipped one. }
        RowCanWrap := True;
        for Other in CaptionRow do
          if LinesFittingBelow(Other) < 2 then
            RowCanWrap := False;
        UniformFont := 0;
        for Other in CaptionRow do
        begin
          SetFont := FontFittingOneLine(Other, Other.Width);
          if RowCanWrap then
            SetFont := Max(SetFont, SmallestFontFor(Other))
          else
            SetFont := Max(SetFont, MinimumReadableFontSize);
          if (UniformFont = 0) or (SetFont < UniformFont) then
            UniformFont := SetFont;
        end;

        for Other in CaptionRow do
        begin
          Other.PlannedLeft := Other.Left;
          Other.PlannedWidth := Other.Width;
          if UniformFont < Max(Other.FontSize, 9) then
            Other.PlannedFontSize := UniformFont;
        end;

        SetFitsOneLine := True;
        for Other in CaptionRow do
          if WrappedLineCount(Other, Other.Width) > 1 then
            SetFitsOneLine := False;
        UniformHeight := 0;
        for Other in CaptionRow do
        begin
          Other.PlannedWordWrap := not SetFitsOneLine;
          if not SetFitsOneLine then
            UniformHeight := Max(UniformHeight,
              RequiredHeightFor(Other, Other.Width));
        end;
        if not SetFitsOneLine then
          for Other in CaptionRow do
            Other.PlannedHeight := Max(Other.PlannedHeight,
              Ceil(UniformHeight));
      finally
        CaptionRow.Free;
      end;
    end;
  finally
    PitchedCaptions.Free;
  end;

  { Phase 2a - make sure every planned box can actually hold its text. The
    decisions above each answer one question, and a control can leave them
    holding a width and a height that do not agree with the lines its text
    breaks into: a button given wrapping but not the height to wrap into shows
    its caption cut in half. Measure the settled box and give it the height the
    text really needs. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasSize or
      (Control.PlannedWidth <= 0) then
      Continue;
    { A control that sizes itself belongs here too. Switching that off is what
      makes its height final, and a height left at the single line the form was
      drawn for clips away everything the translation added below it. The
      control had been quietly growing to fit; once it is pinned, the room has
      to be granted deliberately. }
    if not (Control.PlannedWordWrap or Control.AutoSize) then
      Continue;
    { Text wraps inside the padding, not inside the whole control, so count the
      lines against the room the text actually gets. Measuring against the full
      width reports fewer lines than will really appear and buys too little
      height for them. }
    WrappedLines := WrappedLineCount(Control, Control.PlannedWidth);
    if WrappedLines > 1 then
    begin
      { Pinning a control to a width its text overruns, without letting the
        text wrap, does not shorten the text: it cuts it off at the edge, and
        a caption drawn right to left loses its beginning rather than its end. }
      Control.PlannedWordWrap := True;
      Control.PlannedHeight := Max(Control.PlannedHeight,
        Ceil(RequiredHeightFor(Control, Control.PlannedWidth)));
    end;
  end;

  { Phase 2f - a control with nowhere to put a second line must genuinely fit
    on the one it has. Everything above prefers wrapping, and where a caption
    sits directly above the next control there is no room to wrap into: the
    text then overruns a box the height of one line and is cut off, and a
    caption drawn right to left loses its beginning rather than its end, which
    is why a date caption read "as del funeral" instead of "Fechas del
    funeral". Where that is the situation, solve the size against the width
    actually planned rather than reducing by a fixed proportion and hoping. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasSize or
      (Control.PlannedWidth <= 0) or IsParagraphWidth(Control) then
      Continue;
    { Right-aligned only. This is about the particular harm of a caption
      pinned to its right edge, which loses its first words rather than its
      last and so stops naming the thing beside it. Text that overruns to the
      left keeps its beginning and reads as merely tight, and shrinking that
      is not worth the cost: applied to everything, this reduced a check box
      to sixty per cent of its size and a heading to sixty-five. }
    if not IsRightAligned(Control) then
      Continue;
    if LinesFittingBelow(Control) > 1 then
      Continue;
    { Judged with the same headroom used elsewhere. We measure with a default
      typeface and the application draws with its own, so a caption our
      arithmetic calls a perfect fit is the one that wraps on screen. }
    if WrappedLineCount(Control, Control.PlannedWidth / MeasurementSafety) <= 1 then
      Continue;
    { Width before size. Any margin still empty on the left is free: it costs
      nothing, it disturbs no neighbour, and every pixel taken here is one the
      text does not have to give up in size. Six pixels of unused margin was
      the difference between a caption at eighty-four per cent of its designed
      size and one at eighty-nine. }
    { Ask for the width the caption wants at the size it was drawn at, not at
      the reduced size an earlier pass already settled on. Measured against
      the reduced size it asks for almost nothing, takes almost nothing, and
      then has to give the size up anyway - which is how a caption ended up a
      full point smaller than the two directly above it for want of six pixels
      that were sitting there unused. }
    EffectiveFont := Control.PlannedFontSize;
    if EffectiveFont <= 0 then
      EffectiveFont := Max(Control.FontSize, 9);
    NeededWidth := (TextWidthEstimate(Control) -
      2 * PaddingHorizontal(Control)) * Max(Control.FontSize, 9) /
      Max(EffectiveFont, 1) * MeasurementSafety +
      2 * PaddingHorizontal(Control);
    LeftRoom := Min(SpaceToLeft(Control),
      Max(0, NeededWidth - Control.PlannedWidth));
    if LeftRoom > 1 then
    begin
      Control.PlannedWidth := Control.PlannedWidth + LeftRoom;
      Control.PlannedLeft := Control.PlannedLeft - LeftRoom;
    end;
    EffectiveFont := FontFittingOneLine(Control,
      Control.PlannedWidth / MeasurementSafety);
    { A floor, because there is a point past which fitting the text is worse
      than the text not fitting. Where even this will not do it, leave the
      control as the passes above left it rather than shrink it to something
      nobody can read. }
    if (EffectiveFont < Max(Control.FontSize, 9) * 0.75) or
      (EffectiveFont < MinimumReadableFontSize) then
      Continue;
    if EffectiveFont < Max(Control.FontSize, 9) then
    begin
      Control.PlannedFontSize := EffectiveFont;
      { It fits on one line now, so it must not be told to wrap: wrapping a
        line that no longer needs it only invites the renderer to break it. }
      if WrappedLineCount(Control, Control.PlannedWidth) <= 1 then
        Control.PlannedWordWrap := False;
    end;
  end;

  { Phase 3 - resolve collisions against the planned geometry, repeatedly, so a
    control moved on one pass is seen at its new place on the next. Every move
    both reads and writes the planned values, which is what stops two rules
    from being derived from stale positions and contradicting each other. }
  for Pass := 1 to MaximumSeparationPasses do
  begin
    Moved := False;
    for Control in AReview.Controls do
    begin
      if not Control.HasPosition or not Control.HasSize then
        Continue;
      for Other in AReview.Controls do
      begin
        if (Other = Control) or not Other.HasPosition or not Other.HasSize then
          Continue;
        if not SameText(Other.FormName, Control.FormName) or
          not SameText(Other.ParentName, Control.ParentName) then
          Continue;
        if not PlannedOverlap(Control, Other) then
          Continue;
        if DesignedOverlap(Control, Other) then
          Continue;
        if Pass = 1 then
          AddFinding(AReview, lfsWarning, 'Overlap',
            Control.FormName + '.' + Control.ComponentName,
            'This control intersects ' + Other.ComponentName +
              ' after measured translated sizing.',
            'Review the proposed move/size rule or adjust the designer layout manually.');
        if SamePlannedRow(Control, Other) then
        begin
          { Which control gives way is decided by where the designer put them,
            never by where they have been moved to. Judging by current position
            lets a control that has been pushed along leapfrog its neighbour,
            which silently reverses the reading order of a row: a pair of date
            fields can end up showing the end date before the start date. }
          if Control.Left <= Other.Left then
            Leader := Control
          else
            Leader := Other;
          if Leader = Control then
            Follower := Other
          else
            Follower := Control;
          RequiredLeft := Leader.PlannedLeft + Leader.PlannedWidth + ControlGap;
          { A right-aligned caption cannot give way by moving right: its right
            edge is pinned against the field it labels, and moving it would
            walk its text into that field. When such a caption has grown back
            towards a control on its left, it is that control which has to step
            further left, into whatever free margin the form has. This is what
            keeps a button clear of the caption beside it instead of the
            caption being clipped to fit. }
          if IsRightAligned(Follower) and CanMoveControl(Leader) and
            (Leader.PlannedLeft > 0) then
          begin
            ShiftedLeft := Max(0, Follower.PlannedLeft - ControlGap -
              Leader.PlannedWidth);
            if ShiftedLeft < Leader.PlannedLeft - 1 then
            begin
              Leader.PlannedLeft := ShiftedLeft;
              Moved := True;
            end
            else if Leader.PlannedWidth > Leader.Width then
            begin
              Leader.PlannedWidth := Max(Leader.Width,
                Follower.PlannedLeft - ControlGap - Leader.PlannedLeft);
              Leader.PlannedWordWrap := ShouldPreferWrap(Leader);
              Moved := True;
            end;
          end
          else if CanMoveControl(Follower) and
            (RequiredLeft + Follower.PlannedWidth <=
              ContentRightBound(Follower)) and
            { Distance, not direction. Written as a subtraction this only ever
              restrained a control being pushed to the right: pushed left the
              difference is negative and the test passes however far it goes.
              Two buttons drawn as a pair against a shared right edge were
              carried a hundred and twenty six and a hundred and forty two
              pixels across the settings page to the left margin, arriving
              ragged and attached to nothing, because no one was measuring how
              far they had come. }
            (Abs(RequiredLeft - Follower.Left) <= MaximumDrift) then
          begin
            Follower.PlannedLeft := RequiredLeft;
            Moved := True;
          end
          else if Leader.PlannedWidth > Leader.Width then
          begin
            { There is no room to step aside, so the control that grew gives
              width back instead. A row of buttons sized for a longer language
              has nowhere to expand into, and shrinking each one to share the
              space is far better than stacking them on top of each other. }
            Surplus := RequiredLeft + Follower.PlannedWidth -
              ContentRightBound(Follower);
            ReducedWidth := Max(Leader.Width,
              Leader.PlannedWidth - Max(Surplus, 1));
            if ReducedWidth < Leader.PlannedWidth then
            begin
              Leader.PlannedWidth := ReducedWidth;
              Leader.PlannedWordWrap := ShouldPreferWrap(Leader);
              Moved := True;
            end;
          end;
        end
        else
        begin
          { Stacking order comes from the designer's positions too, for the
            same reason: a control pushed down must not end up above the one it
            was beneath. }
          if Control.Top <= Other.Top then
            Leader := Control
          else
            Leader := Other;
          if Leader = Control then
            Follower := Other
          else
            Follower := Control;
          RequiredTop := Leader.PlannedTop + Leader.PlannedHeight + ControlGap;
          { A control pushed off the bottom of the form is gone, which is worse
            than one sitting close under its neighbour. Where there is no room
            below, take the height back from whatever grew instead. Landing it
            on a third control is no better than leaving it alone either, so
            check the destination is clear before using it. }
          if CanMoveControl(Follower) and not IsPairedWithField(Follower) and
            (RequiredTop - Follower.Top <= MaximumDrift) and
            ((ContentBottomBound(Follower) <= 0) or
             (RequiredTop + Follower.PlannedHeight <=
                ContentBottomBound(Follower))) and
            DestinationIsClear(Follower, RequiredTop) then
          begin
            Follower.PlannedTop := RequiredTop;
            Moved := True;
          end
          else if Leader.PlannedHeight > Leader.Height then
          begin
            ReducedHeight := Max(Leader.Height,
              Follower.PlannedTop - ControlGap - Leader.PlannedTop);
            if ReducedHeight < Leader.PlannedHeight then
            begin
              { Taking the height back on its own would simply cut the text
                off, so reduce the size to suit the height that is left. }
              if Leader.PlannedHeight > 0 then
              begin
                EffectiveFont := Leader.PlannedFontSize;
                if EffectiveFont <= 0 then
                  EffectiveFont := Max(Leader.FontSize, 9);
                EffectiveFont := Max(SmallestFontFor(Leader),
                  EffectiveFont * ReducedHeight / Leader.PlannedHeight);
                Leader.PlannedFontSize := EffectiveFont;
              end;
              Leader.PlannedHeight := ReducedHeight;
              Moved := True;
            end;
          end;
        end;
      end;
    end;
    if not Moved then
      Break;
  end;

  { Phase 2d - captions drawn as a set keep one text size. A row of navigator
    captions is read as a group, and one of them at a slightly smaller size
    than its neighbours looks like a mistake even when every box lines up.
    Where sibling captions share a row, a size and a designed height, give them
    all the smallest size any of them needed. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasPosition or
      not Control.HasSize then
      Continue;
    if not ContainsText(Control.ComponentClassName, 'Label') then
      Continue;
    EffectiveFont := Control.PlannedFontSize;
    if EffectiveFont <= 0 then
      EffectiveFont := Control.FontSize;
    for Other in AReview.Controls do
    begin
      if (Other = Control) or not Other.HasPosition or not Other.HasSize then
        Continue;
      if not SameText(Other.FormName, Control.FormName) or
        not SameText(Other.ParentName, Control.ParentName) then
        Continue;
      if not ContainsText(Other.ComponentClassName, 'Label') then
        Continue;
      if (Abs(Other.Top - Control.Top) > 2) or
        (Abs(Other.Height - Control.Height) > 2) or
        (Abs(Other.FontSize - Control.FontSize) > 0.01) then
        Continue;
      if (Other.PlannedFontSize > 0) and (Other.PlannedFontSize < EffectiveFont) then
        EffectiveFont := Other.PlannedFontSize;
    end;
    if (EffectiveFont > 0) and (EffectiveFont < Control.FontSize) then
      Control.PlannedFontSize := EffectiveFont;
  end;

  { Phase 3a - a frame drawn around a caption has to hold it. Where the caption
    inside has grown, give the frame the room, but only from the children it
    actually owns and only within a bound.

    This is deliberately narrower than it sounds. The frame grows for its own
    children, taken from the scanned parentage, never for whatever happens to
    overlap it on screen, and never past twice the size it was drawn. Judging
    that by position instead is what turned a decorative header layout into
    something covering its whole form. }
  for Control in AReview.Controls do
  begin
    if not IsVisualContainer(Control) or not Control.HasSize then
      Continue;
    NeededWidth := 0;
    NeededHeight := 0;
    for Other in AReview.Controls do
    begin
      if (Other = Control) or not Other.HasPosition or not Other.HasSize then
        Continue;
      if not SameText(Other.FormName, Control.FormName) then
        Continue;
      if not SameText(Other.ParentName, Control.ComponentName) then
        Continue;
      NeededWidth := Max(NeededWidth,
        Other.PlannedLeft + Other.PlannedWidth + ContainerInset);
      NeededHeight := Max(NeededHeight,
        Other.PlannedTop + Other.PlannedHeight + ContainerInset);
    end;
    { Never past the edge of what holds the frame itself. A frame pushed off
      the form takes its children with it. }
    if NeededWidth > Control.PlannedWidth then
    begin
      NeededWidth := Min(NeededWidth, Control.Width * MaximumContainerGrowth);
      if ContentRightBound(Control) > 0 then
        NeededWidth := Min(NeededWidth,
          ContentRightBound(Control) - Control.PlannedLeft);
      Control.PlannedWidth := Max(Control.PlannedWidth, NeededWidth);
    end;
    if NeededHeight > Control.PlannedHeight then
    begin
      NeededHeight := Min(NeededHeight, Control.Height * MaximumContainerGrowth);
      if ContentBottomBound(Control) > 0 then
        NeededHeight := Min(NeededHeight,
          ContentBottomBound(Control) - Control.PlannedTop);
      Control.PlannedHeight := Max(Control.PlannedHeight, NeededHeight);
    end;
  end;

  { Phase 3b - hold every caption inside the frame the designer drew round it.
    The sizing rules above each respect the frame, but they answer different
    questions and a control can leave them a little outside it. This is the one
    place that guarantees the invariant, and it only ever pulls a control in.

    Note again the direction. Enlarging the frame instead would satisfy the same
    arithmetic and is how a decorative layout ends up swallowing a form. }
  for Control in AReview.Controls do
  begin
    if not Control.HasPosition or not Control.HasSize then
      Continue;
    ClampContainer := ParentContainerOf(Control);
    if ClampContainer <> nil then
    begin
      { Inside a parent the usable area starts at nothing, not at the parent's
        own coordinates. }
      ClampLeft := Min(ContainerInset, Control.Left);
      ClampTop := Min(ContainerInset, Control.Top);
      { Against the frame as it will be, not as it was drawn. The pass above
        enlarges a frame precisely so its contents fit; measuring the contents
        against the old size here undoes that work in the same breath, and the
        control is pulled back to a box that no longer exists. The scheduling
        check box was the case: its panel was grown from thirty-three to
        sixty-four to hold two lines of Spanish, and the check box was then
        clamped to twenty-five because that is what fitted the panel before it
        grew, so the second line was cut off inside a panel with room to spare. }
      ClampRight := Max(Max(ClampContainer.PlannedWidth, ClampContainer.Width) -
        ContainerInset, Control.Left + Control.Width);
      ClampBottom := Max(Max(ClampContainer.PlannedHeight,
        ClampContainer.Height) - ContainerInset,
        Control.Top + Control.Height);
    end
    else
    begin
      ClampContainer := DesignedContainerOf(Control);
      if ClampContainer = nil then
        Continue;
      ClampLeft := Min(ClampContainer.Left + ContainerInset, Control.Left);
      ClampTop := Min(ClampContainer.Top + ContainerInset, Control.Top);
      ClampRight := Max(ClampContainer.Left +
        Max(ClampContainer.PlannedWidth, ClampContainer.Width) -
        ContainerInset, Control.Left + Control.Width);
      ClampBottom := Max(ClampContainer.Top +
        Max(ClampContainer.PlannedHeight, ClampContainer.Height) -
        ContainerInset, Control.Top + Control.Height);
    end;

    { The inset is what a caption should keep from the frame, not a correction
      to apply to the designer's own placement. A button drawn flush with the
      edge of its group box was put there deliberately, so no control is held
      tighter than it was drawn; only translation carrying one further out is
      prevented. }
    if Control.PlannedWidth > ClampRight - ClampLeft then
      Control.PlannedWidth := ClampRight - ClampLeft;
    if Control.PlannedHeight > ClampBottom - ClampTop then
      Control.PlannedHeight := ClampBottom - ClampTop;

    if Control.PlannedLeft < ClampLeft then
      Control.PlannedLeft := ClampLeft;
    if Control.PlannedTop < ClampTop then
      Control.PlannedTop := ClampTop;
    if Control.PlannedLeft + Control.PlannedWidth > ClampRight then
      Control.PlannedLeft := ClampRight - Control.PlannedWidth;
    if Control.PlannedTop + Control.PlannedHeight > ClampBottom then
      Control.PlannedTop := ClampBottom - Control.PlannedHeight;

    { The caption now has whatever room the frame allows. Where it is the only
      thing in the frame, let it use the whole width before any thought of
      shrinking the text; where it shares the frame, leave it where it is, or a
      row of buttons would all be widened onto the same spot. }
    if Control.TranslatedText = '' then
      Continue;
    if (TextWidthEstimate(Control) > Control.PlannedWidth) and
      AloneInContainer(Control, ClampContainer) and
      (Control.PlannedWidth < ClampRight - ClampLeft) then
    begin
      Control.PlannedWidth := ClampRight - ClampLeft;
      Control.PlannedLeft := ClampLeft;
    end;
    EffectiveFont := Control.PlannedFontSize;
    if EffectiveFont <= 0 then
      EffectiveFont := Max(Control.FontSize, 9);
    WrappedLines := WrappedLineCount(Control, Control.PlannedWidth);
    while (WrappedLines * EffectiveFont * 1.65 + 2 * PaddingVertical(Control) >
        Control.PlannedHeight) and
      (EffectiveFont > SmallestFontFor(Control)) do
    begin
      EffectiveFont := EffectiveFont - 0.5;
      Control.PlannedFontSize := Max(EffectiveFont, SmallestFontFor(Control));
      EffectiveFont := Control.PlannedFontSize;
      WrappedLines := WrappedLineCount(Control, Control.PlannedWidth);
    end;
    Control.PlannedWordWrap := Control.PlannedWordWrap or (WrappedLines > 1);
  end;

  { Phase 3d - nothing is left holding text it cannot hold, or standing on
    something else.

    The passes above each solve one thing well and hand on. What none of them
    owns is the state of the form once they have all run: a caption whose
    translation outgrew the room beside it can be left too narrow for its own
    text, and a heading can be given so many lines that it comes down through
    whatever is underneath. Both were on the settings and email pages.

    This pass changes one thing only, and only downwards: the point size. It
    never moves a control, never grows a box, and never touches a control whose
    text already fits where it has been put. A collision that the designer drew
    is left alone - controls are deliberately stacked often enough - and only
    one this planning would have introduced counts. }
  { A row of buttons keeps one width, whatever the passes in between did.

    The row is sized as a set early on, and everything after that treats each
    button on its own: one whose translated caption still would not fit was
    widened by three pixels and the row stopped being a row. The list that
    marked those buttons as belonging to a set is long gone by then, so the
    row is gathered again here and levelled. Where the row cannot have the
    width its hungriest member wants, every button takes the smaller width and
    the text inside them is what gives - which is the settling loop's job, and
    it runs next. }
  RowMembers := TList<TLayoutControl>.Create;
  RowSettled := TList<TLayoutControl>.Create;
  try
    for Control in AReview.Controls do
    begin
      if not IsButtonLike(Control) or (RowSettled.IndexOf(Control) >= 0) then
        Continue;
      RowMembers.Clear;
      Cluster := CollectButtonRow(Control);
      try
        if Cluster.Count < 2 then
          Continue;
        RowWidth := 0;
        RowGap := ControlGap;
        if Cluster.Count > 1 then
          RowGap := Max(ControlGap,
            Cluster[1].Left - (Cluster[0].Left + Cluster[0].Width));
        for Other in Cluster do
        begin
          RowSettled.Add(Other);
          RowWidth := Max(RowWidth, Other.PlannedWidth);
        end;
        RowRoom := ContentRightBound(Cluster[0]) - Cluster[0].PlannedLeft;
        if Cluster.Count * RowWidth + (Cluster.Count - 1) * RowGap >
          RowRoom then
          RowWidth := Max(24,
            Floor((RowRoom - (Cluster.Count - 1) * RowGap) / Cluster.Count));
        for Other in Cluster do
          Other.PlannedWidth := RowWidth;
      finally
        Cluster.Free;
      end;
    end;
  finally
    RowSettled.Free;
    RowMembers.Free;
  end;

  for Control in AReview.Controls do
  begin
    if Trim(Control.TranslatedText) = '' then
      Continue;
    if not (Control.HasPosition and Control.HasSize) then
      Continue;
    if (Control.PlannedWidth <= 0) or (Control.PlannedHeight <= 0) then
      Continue;
    if IsVisualContainer(Control) then
      Continue;
    SettleGuard := 0;
    while SettleGuard < 60 do
    begin
      Inc(SettleGuard);
      SettleFont := Control.PlannedFontSize;
      if SettleFont <= 0 then
        SettleFont := Max(Control.FontSize, 9);
      SettleLines := WrappedLineCount(Control, Control.PlannedWidth);
      SettleHeight := SettleLines * SettleFont * 1.65 +
        2 * PaddingVertical(Control);
      { One line has to fit across; several have to fit down. }
      if SettleLines <= 1 then
        SettleFits := TextWidthEstimate(Control) <= Control.PlannedWidth + 1
      else
        SettleFits := SettleHeight <= Control.PlannedHeight + 1;
      { Height the text no longer needs is given back here rather than at the
        end, because everything below judges this control by the box it is
        standing in. Held until afterwards, a heading that had just been
        widened onto one line was still being measured as the three-line block
        it used to be, was found to be standing on the labels beneath it, and
        had its widening taken away again. Never below the height drawn. }
      if SettleFits then
        Control.PlannedHeight := Max(Control.Height,
          Min(Control.PlannedHeight, Ceil(SettleHeight)));
      { Room on the row is spent before the text is wrapped or made smaller.
        A heading centred on a form with hundreds of spare pixels either side
        should take them and stay on one line; breaking it onto three and then
        shrinking it to fit the result is the worst of both, and it was what
        the email page did. Asked before the fit is judged, because a caption
        already broken onto three lines inside a box grown to hold them looks
        like it fits perfectly well. A control keeps its centre as it grows,
        so a centred heading stays centred. }
      SettleRoom := AvailableWidth(Control);
      SettleNeeded := TextWidthEstimate(Control);
      { A button standing on its own may be given room; one belonging to a row
        may not, because the row was levelled above and a single member
        growing would break the pitch it is supposed to keep. }
      SettleAlone := False;
      if IsButtonLike(Control) then
      begin
        SettleRow := CollectButtonRow(Control);
        try
          SettleAlone := SettleRow.Count < 2;
        finally
          SettleRow.Free;
        end;
      end;
      { A heading, and nothing else. Widening here is a last resort applied
        after every other pass has had its say, so it is granted only to the
        one shape that clearly wants it: a centred title drawn large. A
        right-aligned caption keeps its right edge by contract, a button
        belongs to a row that must keep its pitch, and a paragraph is meant to
        wrap - all three were widened out of shape when this was let loose on
        everything. }
      if IsCentreAligned(Control) and not IsButtonLike(Control) and
        not IsInputControl(Control) and
        (Max(Control.PlannedFontSize, Control.FontSize) >= HeadingFontSize) and
        (SettleNeeded > Control.PlannedWidth + 1) and
        (SettleRoom > Control.PlannedWidth + 1) then
      begin
        SettleCentre := Control.PlannedLeft + Control.PlannedWidth / 2;
        Control.PlannedWidth := Min(SettleNeeded, SettleRoom);
        if IsCentreAligned(Control) then
          Control.PlannedLeft := SettleCentre - Control.PlannedWidth / 2;
        if Control.PlannedLeft < 0 then
          Control.PlannedLeft := 0;
        Continue;
      end;
      { A button has one caption and no way to fold it away. Where the caption
        will not fit, the button is what has to give, and room to its left
        counts as much as room to its right: the settings page has two buttons
        pressed against labels on the right with a wide empty margin on the
        left, so growing only rightwards left them exactly as cramped as they
        started. A button belonging to a row is left alone - the row was
        levelled just above and one member growing would break it. }
      if IsButtonLike(Control) and (not SettleFits) and
        (SettleNeeded > Control.PlannedWidth + 1) then
      begin
        if SettleAlone then
        begin
          { Rightwards only. Taking the room on the left would mean moving the
            button, and a button keeps the place it was drawn in - it is
            positioned against the thing it acts on, and sliding it to make
            its caption fit trades one fault for a worse one. Capped, too: a
            button allowed to take every spare pixel of its row stops looking
            like a button.

            SpaceToRight is the widest this control may be, measured from its
            own left edge to whatever stands next to it - not the free space
            beyond its right edge. Reading it as free space and adding it to
            the width, once per turn round this loop, is how two buttons on
            the settings page came to be drawn straight through the captions
            beside them. The width is set outright here, and only ever to
            something that fits. }
          SettleWanted := Min(SettleNeeded,
            Min(Max(Control.Width * 1.25, MinimumComfortableButtonWidth),
              SpaceToRight(Control)));
          if SettleWanted > Control.PlannedWidth + 1 then
          begin
            Control.PlannedWidth := SettleWanted;
            Continue;
          end;
        end;
      end;
      { Then taller, before smaller. A button with two lines of caption in a
        box drawn for one is fixed by giving it the second line's worth of
        height, not by shrinking the words until they fit a height nobody
        chose. Only into room that is actually there. }
      if IsButtonLike(Control) and (not SettleFits) and (SettleLines > 1) and
        SettleAlone then
      begin
        SettleFloor := ContentBottomBound(Control);
        if SettleFloor <= 0 then
          SettleFloor := Control.PlannedTop + Control.PlannedHeight;
        if SettleHeight <= SettleFloor - Control.PlannedTop then
        begin
          Control.PlannedHeight := Ceil(SettleHeight);
          Continue;
        end;
      end;
      { Standing on something is undone before the text is touched, and undone
        in the order the damage was done: first give back any move sideways,
        then any width this planning added. A caption slid left to find room
        for itself, straight across the button beside it, is put back where it
        was drawn - the collision is worse than the crowding it was solving,
        and the passes that make the room cannot see each other. }
      { A button belonging to a row is left out: the row was levelled as a set
        above, and handing one member back its designed width while its
        neighbours keep theirs is not a repair, it is the row broken. }
      if PlannedBoxIntrudes(Control) and
        not (IsButtonLike(Control) and not SettleAlone) then
      begin
        { Try giving back the move, then the width, and keep whichever
          actually clears it. Undoing them regardless takes the widening off a
          heading whose collision was vertical and nothing to do with its
          width, and breaks a button row by returning one member to the size
          it was drawn at while its neighbours keep theirs. }
        SettleSavedLeft := Control.PlannedLeft;
        SettleSavedWidth := Control.PlannedWidth;
        if Abs(SettleSavedLeft - Control.Left) > 0.5 then
        begin
          Control.PlannedLeft := Control.Left;
          if not PlannedBoxIntrudes(Control) then
            Continue;
          Control.PlannedLeft := SettleSavedLeft;
        end;
        if SettleSavedWidth > Control.Width + 0.5 then
        begin
          Control.PlannedWidth := Control.Width;
          if not PlannedBoxIntrudes(Control) then
            Continue;
          Control.PlannedWidth := SettleSavedWidth;
        end;
      end;
      if SettleFits and not PlannedBoxIntrudes(Control) then
        Break;
      if SettleFont <= SmallestFontFor(Control) + 0.01 then
        Break;
      Control.PlannedFontSize :=
        Max(SettleFont - 0.5, SmallestFontFor(Control));
    end;
    { Whatever it settled at, say so if the text now takes more than one line. }
    SettleLines := WrappedLineCount(Control, Control.PlannedWidth);
    if SettleLines > 1 then
      Control.PlannedWordWrap := True;
    { And give back height the text no longer needs. An earlier pass grew this
      control to hold the lines it thought it would take; if it now takes
      fewer, holding on to that height is what came down over the labels
      below. Never below the height the designer drew. }
    SettleFont := Control.PlannedFontSize;
    if SettleFont <= 0 then
      SettleFont := Max(Control.FontSize, 9);
    SettleHeight := SettleLines * SettleFont * 1.65 +
      2 * PaddingVertical(Control);
    Control.PlannedHeight := Max(Control.Height,
      Min(Control.PlannedHeight, Ceil(SettleHeight)));
  end;

  { Text that wraps is given the width the wrap uses, and no more.

    A box wider than the text needs does not look generous, it looks ragged:
    the words fill the first line, one or two fall onto the second, and the
    eye reads the gap rather than the sentence. That is the raggedness a
    typesetter spends a career removing, and the lever for it here is the same
    one used for everything else - the width of the box - because the wrapping
    itself is done by the framework at the moment of drawing.

    So the box is narrowed to the least width that still breaks the text into
    the same number of lines. Nothing about the layout changes: the same words
    on the same number of lines, sharing the room evenly instead of leaving it
    all at the end. It never grows a box and never moves one, and a control
    whose text fits on one line is left entirely alone. }
  for Control in AReview.Controls do
  begin
    if Trim(Control.TranslatedText) = '' then
      Continue;
    if not (Control.HasSize and Control.PlannedWordWrap) then
      Continue;
    if IsVisualContainer(Control) or IsButtonLike(Control) then
      Continue;
    { A right-aligned caption is anchored by its right edge and was widened
      leftwards on purpose; narrowing it would walk it straight back again. }
    if IsRightAligned(Control) then
      Continue;
    if Control.PlannedWidth <= MinimumWrapWidth then
      Continue;
    BalanceLines := WrappedLineCount(Control, Control.PlannedWidth);
    if BalanceLines <= 1 then
      Continue;
    { Walk in from the right until one more step would cost another line. }
    BalanceWidth := Control.PlannedWidth;
    BalanceStep := Max(8, Control.PlannedWidth / 40);
    while (BalanceWidth - BalanceStep > MinimumWrapWidth) and
      (WrappedLineCount(Control, BalanceWidth - BalanceStep) <=
        BalanceLines) do
      BalanceWidth := BalanceWidth - BalanceStep;
    if BalanceWidth < Control.PlannedWidth then
    begin
      { A centred caption keeps its centre while it narrows, or balancing the
        lines would slide the block off to one side. }
      if IsCentreAligned(Control) then
        Control.PlannedLeft := Control.PlannedLeft +
          (Control.PlannedWidth - BalanceWidth) / 2
      else if IsRightAligned(Control) then
        Control.PlannedLeft := Control.PlannedLeft +
          (Control.PlannedWidth - BalanceWidth);
      Control.PlannedWidth := BalanceWidth;
    end;
  end;

  { Paragraphs standing together read as one block, so they take one size.

    Two blocks of prose in the same column, drawn at the same size, are read as
    a pair. Their translations rarely grow by the same amount, so deciding each
    one alone leaves the longer visibly smaller than the shorter - which reads
    as a mistake rather than as a decision, and it is what the random-directory
    page showed. Whatever size the pair can settle at, they settle at it
    together, and that is the smallest any of them needs: the others can always
    carry it, while the one that needed it cannot go back up. }
  for Control in AReview.Controls do
  begin
    if not IsParagraphLike(Control) or (Trim(Control.TranslatedText) = '') then
      Continue;
    SettleFont := Control.PlannedFontSize;
    if SettleFont <= 0 then
      SettleFont := Max(Control.FontSize, 9);
    for Other in AReview.Controls do
    begin
      if (Other = Control) or not IsParagraphLike(Other) then
        Continue;
      if Trim(Other.TranslatedText) = '' then
        Continue;
      if not SameText(Other.FormName, Control.FormName) or
        not SameText(Other.ParentName, Control.ParentName) then
        Continue;
      { Drawn at the same size to begin with, or they were never a pair. }
      if Abs(Other.FontSize - Control.FontSize) > 0.01 then
        Continue;
      SettleHeight := Other.PlannedFontSize;
      if SettleHeight <= 0 then
        SettleHeight := Max(Other.FontSize, 9);
      SettleFont := Min(SettleFont, SettleHeight);
    end;
    Control.PlannedFontSize := SettleFont;
  end;

  { Phase 3e - reflect the whole form for a right-to-left language.

    An Arabic or Hebrew interface is not a left-to-right interface with
    right-to-left words in it. The layout itself is reflected: a caption drawn
    to the left of its edit box belongs to the right of it, a row of buttons
    reverses, and the eye starts at the right-hand edge. Anything less reads
    as a translated foreign program rather than as a program in the reader's
    own language.

    This runs last, after every other decision, for two reasons. The geometry
    it reflects is then final - a caption that was widened for a longer
    translation is mirrored at the width it ended up with, not the width it
    started with. And every earlier pass can go on thinking in the left-to-
    right terms it was written and contracted in; none of them needs to know
    about this at all.

    The arithmetic is one line, and it is the same line the VCL's own
    FlipChildren uses: the new left edge is the space that used to lie to the
    right of the control. Coordinates are relative to the parent in both
    frameworks, so reflecting each control within its own parent handles
    nesting on its own - a button inside a panel mirrors against the panel,
    and the panel mirrors against the form, with no recursion needed. }
  if IsRightToLeft(AReview) then
  begin
    { The transport controls of each parent, taken as one shape. Their block
      moves to the mirrored side; their order inside it does not change. }
    MirrorGroup := TList<TLayoutControl>.Create;
    try
      for Control in AReview.Controls do
      begin
        if Control.MirrorHandled or not IsTransportControl(Control) then
          Continue;
        if not (Control.HasPosition and Control.HasSize) then
          Continue;
        if Trim(Control.Align) <> '' then
          Continue;
        MirrorWidth := MirrorContainerWidth(AReview, Control);
        if MirrorWidth <= 0 then
          Continue;

        { The whole group is gathered before any of it moves. Measuring the
          block while its members are already being shifted measures a shape
          that is half in its old place and half in its new one. }
        MirrorGroup.Clear;
        MirrorBlockLeft := Control.PlannedLeft;
        MirrorBlockRight := Control.PlannedLeft + Control.PlannedWidth;
        for Other in AReview.Controls do
          if IsTransportControl(Other) and not Other.MirrorHandled and
            Other.HasPosition and Other.HasSize and
            (Trim(Other.Align) = '') and
            SameText(Other.FormName, Control.FormName) and
            SameText(Other.ParentName, Control.ParentName) then
          begin
            MirrorGroup.Add(Other);
            MirrorBlockLeft := Min(MirrorBlockLeft, Other.PlannedLeft);
            MirrorBlockRight := Max(MirrorBlockRight,
              Other.PlannedLeft + Other.PlannedWidth);
          end;

        for Other in MirrorGroup do
        begin
          Other.PlannedLeft := (MirrorWidth - MirrorBlockRight) +
            (Other.PlannedLeft - MirrorBlockLeft);
          Other.MirrorHandled := True;
        end;
      end;
    finally
      MirrorGroup.Free;
    end;

    for Control in AReview.Controls do
    begin
      if Control.MirrorHandled then
        Continue;
      { A window is not reflected within anything. The form is in this list
        like every other control, and mirroring it against its own width
        reduces to negating its position: Carillon's three forms came out at
        Left -20, -500 and -120, which is why a strip of desktop showed down
        one side of the main window until it was maximised again by hand. }
      if SameText(Control.ComponentName, Control.FormName) then
        Continue;
      { A control the framework positions is mirrored by changing which edge
        it is told to sit against, not by moving it. Moving it would be
        ignored, and the two instructions together would contradict each
        other. }
      if Trim(Control.Align) <> '' then
        Continue;
      if not (Control.HasPosition and Control.HasSize) then
        Continue;
      MirrorWidth := MirrorContainerWidth(AReview, Control);
      if MirrorWidth <= 0 then
        Continue;
      Control.PlannedLeft := MirrorWidth -
        (Control.PlannedLeft + Control.PlannedWidth);
    end;
  end;

  { Phase 4 - emit proposals from the settled geometry. Because every value
    comes from the same resolved model, the exported rules agree with one
    another instead of describing conflicting placements. }
  for Control in AReview.Controls do
  begin
    if not Control.HasSize then
      Continue;
    { A control the application positions or sizes for itself is translated
      and otherwise left alone. Every number here is computed from the
      designer geometry, and the application has already decided differently
      at run time - Carillon centres its main heading against the screen in
      FormShow, which no reading of the form file can know. Proposing anything
      would overwrite that decision, and restoring the designed value later
      would not put it back, because the line that made it never runs again. }
    if Control.GeometryOwnedByCode then
      Continue;
    { Sizing and wrapping only mean something for a control whose text was
      translated. }
    if Control.TranslatedText <> '' then
    begin
      { State the width whenever it changes, and also whenever automatic sizing
        is being switched off. The runtime sets the text before the layout, so
        an auto-sizing control has already stretched itself around the
        translation by then; switching the sizing off at that point freezes it
        at that stretched width, and without a width of its own it keeps it and
        sits across whatever is beside it. }
      if (Ceil(Control.PlannedWidth) > Ceil(Control.Width)) or
        (Control.AutoSize and (Control.SourceText <> Control.TranslatedText)) then
        AddProposal(AReview, Control, 'Width', FloatToStr(Control.Width),
          IntToStr(Ceil(Control.PlannedWidth)),
          'Width measured from the translated text and clamped to the space actually available.');
      if Control.PlannedWordWrap and not Control.WordWrap then
        AddProposal(AReview, Control, 'WordWrap', 'False', 'True',
          'Wrap the translated text instead of expanding across neighboring controls.')
      else if Control.WordWrap and not Control.PlannedWordWrap then
        { Switching wrapping off has to be stated too. A control left wrapping
          because nobody said otherwise will break its line wherever the text
          happens to reach, into whatever height it already had. }
        AddProposal(AReview, Control, 'WordWrap', 'True', 'False',
          'Keep the translated text on the single line the control was drawn for.');
      { Any control that sizes itself has to be pinned once its text changes.
        Left alone it grows around the new string at run time, to whatever
        width that takes, across whatever is beside it. }
      if Control.AutoSize and
        (Control.PlannedWordWrap or (Control.SourceText <> Control.TranslatedText)) then
        AddProposal(AReview, Control, 'AutoSize', 'True', 'False',
          'Fix the size so the translated text cannot resize the control at run time.');
      if Ceil(Control.PlannedHeight) > Ceil(Control.Height) then
        AddProposal(AReview, Control, 'Height', FloatToStr(Control.Height),
          IntToStr(Ceil(Control.PlannedHeight)),
          'Height for the measured wrapped line count at the planned width.');
      if (Control.PlannedFontSize > 0) and
        (Control.PlannedFontSize < Control.FontSize - 0.1) then
        AddProposal(AReview, Control, 'FontSize',
          FormatFloat('0.##', Control.FontSize, TFormatSettings.Invariant),
          FormatFloat('0.##', Control.PlannedFontSize,
            TFormatSettings.Invariant),
          'Slightly smaller text so the translation fits the designed control without moving anything.');
    end;
    { Size is the same story, and it was only half told. A frame enlarged to
      hold its contents carries no text of its own, so the block above never
      speaks for it: the growth was planned and then never written down. The
      scheduling panel is the plain case - the check box inside it was given
      the fifty-six pixels its two lines need, the panel kept the thirty-three
      it was drawn with, and the words were clipped by a container that had
      room to spare everywhere except in the pack. }
    if Control.TranslatedText = '' then
    begin
      if Ceil(Control.PlannedWidth) > Ceil(Control.Width) then
        AddProposal(AReview, Control, 'Width', FloatToStr(Control.Width),
          IntToStr(Ceil(Control.PlannedWidth)),
          'Widened to hold the controls inside it.');
      if Ceil(Control.PlannedHeight) > Ceil(Control.Height) then
        AddProposal(AReview, Control, 'Height', FloatToStr(Control.Height),
          IntToStr(Ceil(Control.PlannedHeight)),
          'Heightened to hold the controls inside it.');
    end;

    { The parts of a mirror that are constants rather than coordinates. Each
      is stated only when it actually changes, so a centred caption and a
      control anchored to both edges produce nothing. }
    if IsRightToLeft(AReview) then
    begin
      MirrorValue := MirroredAlign(Control.Align);
      if MirrorValue <> '' then
        AddProposal(AReview, Control, 'Align', Trim(Control.Align),
          MirrorValue,
          'Right-to-left layout: the control is placed by the framework, so ' +
          'it is mirrored by naming the opposite edge.');
      { An unstated alignment is the framework's default, not an absence
        of one, and it mirrors like anything else.

        Only controls that carry text are given one. A panel has an
        Alignment property too, and proposing a value for a control with
        nothing written in it is noise in the pack and a change nobody
        can see. }
      AlignSource := Trim(Control.HorzAlign);
      if (AlignSource = '') and
        ((Trim(Control.SourceText) <> '') or
         (Trim(Control.TranslatedText) <> '')) then
        AlignSource := DefaultTextAlign(Control);
      MirrorValue := MirroredTextAlign(AlignSource);
      if MirrorValue <> '' then
        AddProposal(AReview, Control, TextAlignPropertyName(Control),
          AlignSource, MirrorValue,
          'Right-to-left layout: the text sits against the opposite edge.');
      MirrorValue := MirroredAnchors(Control.Anchors);
      if MirrorValue <> '' then
        AddProposal(AReview, Control, 'Anchors', Trim(Control.Anchors),
          MirrorValue,
          'Right-to-left layout: an edge anchor has to follow the edge the ' +
          'reader works from, or the control drifts when the window is ' +
          'resized.');
      { Keyboard order follows the eye. The highest tab order among the
        control's siblings less its own gives the reverse, and a control
        alone in its parent is left as it is. }
      if Control.HasTabOrder then
      begin
        MirrorHighest := HighestTabOrderAmongSiblings(AReview, Control);
        if MirrorHighest > 0 then
          AddProposal(AReview, Control, 'TabOrder',
            IntToStr(Control.TabOrder),
            IntToStr(MirrorHighest - Control.TabOrder),
            'Right-to-left layout: the Tab key follows the reader, so the ' +
            'first control is the rightmost.');
      end;
      { A grid reads right to left as well: its first column belongs at the
        right-hand edge. Stated once for the grid rather than once per
        column, because reversing a collection one index at a time depends on
        the order the moves happen in. }
      if ColumnCountOf(AReview, Control) > 1 then
        AddProposal(AReview, Control, 'ColumnOrder', 'designed', 'reversed',
          'Right-to-left layout: the first column belongs at the edge the ' +
          'reader starts from.');
    end;

    { Movement is different. The separation pass steps a control aside to make
      room for a caption that grew, and that control is very often an edit box
      or a check box carrying no text of its own. Exporting only the growth and
      not the matching move is what leaves captions sitting on top of input
      controls, so emit position changes for anything the planner moved. }
    if not Control.HasPosition then
      Continue;
    if Abs(Control.PlannedLeft - Control.Left) > 1 then
      AddProposal(AReview, Control, PositionPropertyName(Control, 'X'),
        FloatToStr(Control.Left), IntToStr(Ceil(Control.PlannedLeft)),
        Format('Move %.0f pixels horizontally to clear the neighbouring control.',
          [Control.PlannedLeft - Control.Left]));
    if Abs(Control.PlannedTop - Control.Top) > 1 then
      AddProposal(AReview, Control, PositionPropertyName(Control, 'Y'),
        FloatToStr(Control.Top), IntToStr(Ceil(Control.PlannedTop)),
        Format('Move %.0f pixels vertically to clear the control above it.',
          [Control.PlannedTop - Control.Top]));
  end;
end;

class function TLocalizationReviewer.Analyze(
  const ACatalog: TTranslationCatalog): TLocalizationReview;
var
  Entry: TTranslationEntry;
begin
  if ACatalog = nil then
    raise EArgumentNilException.Create('A translation catalog is required.');
  Result := TLocalizationReview.Create;
  try
    Result.ApplicationId := ACatalog.ApplicationId;
    Result.LanguageCode := ACatalog.Locale.LanguageCode;
    Result.Framework := ACatalog.Framework;
    Result.TextDirection := ACatalog.Locale.TextDirection;
    for Entry in ACatalog.Entries do
      case Entry.TextOwnership of
        tokRuntimeWired: Inc(Result.FRuntimeWiredCount);
        tokRuntimeUnwired: Inc(Result.FRuntimeUnwiredCount);
        tokApplicationData: Inc(Result.FApplicationDataCount);
        tokSuspicious: Inc(Result.FSuspiciousCount);
        tokExcluded: Inc(Result.FExcludedCount);
      else
        Inc(Result.FDesignerAutomaticCount);
      end;
    ScanLayout(ACatalog, Result);
    AnalyzeTranslations(ACatalog, Result);
    AnalyzeLayout(Result);
  except
    Result.Free;
    raise;
  end;
end;

class procedure TLocalizationReviewer.RestoreDecisions(
  const AReview: TLocalizationReview; const AFileName: string);
var
  Root: TJSONObject;
  Value, ItemValue: TJSONValue;
  Items: TJSONArray;
  Item: TJSONObject;
  Proposal: TLayoutProposal;
  FormName, ComponentName, PropertyName, Checksum: string;
  SavedDecision: string;
begin
  if (AReview = nil) or not TFile.Exists(AFileName) then
    Exit;
  Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if not (Value is TJSONObject) then
  begin Value.Free; Exit; end;
  Root := TJSONObject(Value);
  try
    Items := Root.GetValue('proposals') as TJSONArray;
    if Items = nil then Exit;
    for ItemValue in Items do
      if ItemValue is TJSONObject then
      begin
        Item := TJSONObject(ItemValue);
        FormName := Item.GetValue<string>('formName', '');
        ComponentName := Item.GetValue<string>('componentName', '');
        PropertyName := Item.GetValue<string>('propertyName', '');
        Checksum := Item.GetValue<string>('sourceChecksum', '');
        for Proposal in AReview.Proposals do
          if SameText(Proposal.FormName, FormName) and
             SameText(Proposal.ComponentName, ComponentName) and
             SameText(Proposal.PropertyName, PropertyName) and
             SameText(Proposal.SourceChecksum, Checksum) then
          begin
            { A saved decision overrides the analyser's, which is the whole
              point: a rejection made in review must not be undone by the next
              scan.

              But "pending" is not a decision. It is the absence of one, and
              treating it as a veto means a proposal that was pending once is
              pending for ever - including every proposal written by a build
              that did not yet know the property existed. That is exactly what
              happened to the right-to-left decisions: the analyser was taught
              to accept them, and the previous build's file put them straight
              back, twice, with nothing anywhere saying so. }
            SavedDecision := Trim(Item.GetValue<string>('decision', ''));
            if (SavedDecision <> '') and
              not SameText(SavedDecision, 'pending') then
              Proposal.Decision := SavedDecision;
          end;
      end;
  finally
    Root.Free;
  end;
end;

class procedure TLocalizationReviewer.SaveProposal(
  const AReview: TLocalizationReview; const AFileName: string);
var
  Root, Item: TJSONObject;
  Items: TJSONArray;
  Proposal: TLayoutProposal;
  AcceptedSafeCount: Integer;
begin
  if AReview = nil then Exit;
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(2));
    Root.AddPair('applicationId', AReview.ApplicationId);
    Root.AddPair('languageCode', AReview.LanguageCode);
    Root.AddPair('advisoryOnly', TJSONBool.Create(False));
    Root.AddPair('targetSourceModified', TJSONBool.Create(False));
    Root.AddPair('runtimeApplication',
      'accepted safe rules are embedded in the language runtime pack');
    Items := TJSONArray.Create;
    AcceptedSafeCount := 0;
    for Proposal in AReview.Proposals do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('formName', Proposal.FormName);
      Item.AddPair('componentName', Proposal.ComponentName);
      Item.AddPair('propertyName', Proposal.PropertyName);
      Item.AddPair('currentValue', Proposal.CurrentValue);
      Item.AddPair('proposedValue', Proposal.ProposedValue);
      Item.AddPair('rationale', Proposal.Rationale);
      Item.AddPair('decision', Proposal.Decision);
      Item.AddPair('sourceChecksum', Proposal.SourceChecksum);
      if SameText(Proposal.Decision, 'accepted') and
        (SameText(Proposal.PropertyName, 'Width') or
         SameText(Proposal.PropertyName, 'Height') or
         SameText(Proposal.PropertyName, 'WordWrap') or
         SameText(Proposal.PropertyName, 'AutoSize') or
         SameText(Proposal.PropertyName, 'Left') or
         SameText(Proposal.PropertyName, 'Top') or
         SameText(Proposal.PropertyName, 'Position.X') or
         SameText(Proposal.PropertyName, 'Position.Y') or
         SameText(Proposal.PropertyName, 'FontSize')) then
      begin
        Item.AddPair('runtimeEligible', TJSONBool.Create(True));
        Inc(AcceptedSafeCount);
      end
      else
        Item.AddPair('runtimeEligible', TJSONBool.Create(False));
      Items.AddElement(Item);
    end;
    Root.AddPair('acceptedSafeCount', TJSONNumber.Create(AcceptedSafeCount));
    Root.AddPair('proposals', Items);
    ForceDirectories(TPath.GetDirectoryName(AFileName));
    TFile.WriteAllText(AFileName, Root.Format(2), TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

class procedure TLocalizationReviewer.SaveEnvelope(
  const ACatalogFiles: TArray<string>; const AFileName: string);
var
  Root, Item: TJSONObject;
  Items: TJSONArray;
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  EnvelopeValues, Languages: TStringList;
  FileName, Key: string;
  I, Index, Required: Integer;
begin
  EnvelopeValues := TStringList.Create;
  Languages := TStringList.Create;
  try
    { Values are updated while catalogs are merged. TStringList prohibits
      ValueFromIndex changes while Sorted=True, so sort only after merging. }
    EnvelopeValues.Sorted := False;
    EnvelopeValues.Duplicates := dupIgnore;
    EnvelopeValues.NameValueSeparator := '=';
    for FileName in ACatalogFiles do
      if TFile.Exists(FileName) then
      begin
        Catalog := TCatalogJson.LoadFromFile(FileName);
        try
          Languages.Add(Catalog.Locale.LanguageCode);
          for Entry in Catalog.Entries do
            if Entry.TranslatedText <> '' then
            begin
              Key := Entry.FormName + '.' + Entry.ComponentName;
              Required := Ceil(Length(Entry.TranslatedText) * 12 * 0.57 + 18);
              Index := EnvelopeValues.IndexOfName(Key);
              if Index < 0 then
                EnvelopeValues.Add(Key + '=' + IntToStr(Required))
              else if Required > StrToIntDef(
                EnvelopeValues.ValueFromIndex[Index], 0) then
                EnvelopeValues.ValueFromIndex[Index] := IntToStr(Required);
            end;
        finally
          Catalog.Free;
        end;
      end;
    EnvelopeValues.Sort;
    Root := TJSONObject.Create;
    try
      Root.AddPair('schemaVersion', TJSONNumber.Create(1));
      Root.AddPair('purpose', 'Common multilingual layout envelope');
      Root.AddPair('languages', Languages.CommaText);
      Root.AddPair('advisoryOnly', TJSONBool.Create(True));
      Items := TJSONArray.Create;
      for I := 0 to EnvelopeValues.Count - 1 do
      begin
        Item := TJSONObject.Create;
        Item.AddPair('controlKey', EnvelopeValues.Names[I]);
        Item.AddPair('minimumEstimatedWidth', TJSONNumber.Create(
          StrToIntDef(EnvelopeValues.ValueFromIndex[I], 0)));
        Item.AddPair('decision', 'pending');
        Items.AddElement(Item);
      end;
      Root.AddPair('controls', Items);
      ForceDirectories(TPath.GetDirectoryName(AFileName));
      TFile.WriteAllText(AFileName, Root.Format(2), TEncoding.UTF8);
    finally
      Root.Free;
    end;
  finally
    Languages.Free;
    EnvelopeValues.Free;
  end;
end;

class procedure TLocalizationReviewer.GenerateReviewPackage(
  const AReview: TLocalizationReview; const AHtmlFileName,
  AProposalFileName: string);
var
  Html: TStringList;
  Finding: TLocalizationFinding;
  Control: TLayoutControl;
  Proposal: TLayoutProposal;
  FormNames: TStringList;
  FormName, Color: string;
  Scale, MaxWidth, MaxHeight: Double;
  ProposedWidth, ProposedHeight: Double;
  ProposedWrap: Boolean;
begin
  if AReview = nil then Exit;
  RestoreDecisions(AReview, AProposalFileName);
  SaveProposal(AReview, AProposalFileName);
  Html := TStringList.Create;
  FormNames := TStringList.Create;
  try
    FormNames.Sorted := True; FormNames.Duplicates := dupIgnore;
    for Control in AReview.Controls do
      FormNames.Add(Control.FormName);
    Html.Add('<!doctype html><html><head><meta charset="utf-8">');
    Html.Add('<title>Localization review - ' + HtmlEncode(AReview.ApplicationId) + '</title>');
    Html.Add('<style>body{font:16px Segoe UI,Arial;margin:32px;color:#173b63;background:#f3f7fc}' +
      'h1,h2{color:#173b63}.card{background:white;border:1px solid #cddff1;border-left:7px solid #ff8a00;' +
      'border-radius:14px;padding:20px;margin:18px 0}table{border-collapse:collapse;width:100%}' +
      'th,td{padding:9px;border-bottom:1px solid #dbe6f2;text-align:left}.high{color:#b42318;font-weight:700}' +
      '.warn{color:#9a6700;font-weight:700}.canvas{position:relative;background:#eef5fc;border:1px solid #8db4dc;' +
      'min-height:180px;overflow:auto}.views{display:grid;grid-template-columns:1fr 1fr;gap:18px}' +
      '.view h3{margin:4px 0 10px}.ctl{position:absolute;border:1px solid #2878c8;background:#dcecff;' +
      'overflow:hidden;font-size:11px;padding:2px;box-sizing:border-box}.proposed{background:#e8f7ea;border-color:#238636}' +
      '.wrapped{white-space:normal}.legend{padding:10px;background:#eef5fc;border-radius:8px}' +
      'details{max-width:520px}summary{cursor:pointer;color:#1673d1}</style></head><body>');
    Html.Add('<h1>Localization Review Package</h1><div class="card"><b>' +
      HtmlEncode(AReview.ApplicationId) + '</b> &mdash; ' +
      HtmlEncode(AReview.LanguageCode) + '<p>' + HtmlEncode(AReview.Summary) +
      '</p><p>This is a read-only, estimated review. It does not alter Delphi forms or source.</p></div>');
    Html.Add('<div class="card"><h2>Translation confidence and disagreements</h2><table>' +
      '<tr><th>Risk</th><th>Category</th><th>Entry/control</th><th>Finding</th><th>Complete text and action</th></tr>');
    for Finding in AReview.Findings do
    begin
      if Finding.Severity = lfsHighRisk then Color := 'high'
      else if Finding.Severity = lfsWarning then Color := 'warn'
      else Color := '';
      Html.Add('<tr><td class="' + Color + '">' +
        HtmlEncode(LocalizationFindingSeverityText(Finding.Severity)) + '</td><td>' +
        HtmlEncode(Finding.Category) + '</td><td>' + HtmlEncode(Finding.Key) +
        '</td><td>' + HtmlEncode(Finding.MessageText) + '</td><td><details><summary>Show complete text and recommendation</summary>' +
        '<p><b>Source:</b> ' + HtmlEncode(Finding.SourceText) + '</p><p><b>Translation:</b> ' +
        HtmlEncode(Finding.TranslatedText) + '</p><p><b>Ownership:</b> ' +
        HtmlEncode(Finding.Ownership) + '</p><p><b>Provenance:</b> ' +
        HtmlEncode(Finding.Provenance) + '</p><p><b>Recommendation:</b> ' +
        HtmlEncode(Finding.Recommendation) + '</p></details></td></tr>');
    end;
    Html.Add('</table></div>');
    for FormName in FormNames do
    begin
      MaxWidth := 800; MaxHeight := 450;
      for Control in AReview.Controls do
        if SameText(Control.FormName, FormName) and Control.HasPosition and Control.HasSize then
        begin
          MaxWidth := Max(MaxWidth, Control.Left + Control.Width + 20);
          MaxHeight := Max(MaxHeight, Control.Top + Control.Height + 20);
        end;
      Scale := Min(1, 800 / MaxWidth);
      Html.Add('<div class="card"><h2>' + HtmlEncode(FormName) +
        '</h2><p class="legend">Left: translated text in the designer geometry. Right: the proposed language-specific geometry. Green controls have at least one proposed width, height, wrapping, or sizing rule.</p><div class="views"><div class="view"><h3>Translated - current layout</h3><div class="canvas" style="width:' + IntToStr(Round(MaxWidth * Scale)) +
        'px;height:' + IntToStr(Round(MaxHeight * Scale)) + 'px">');
      for Control in AReview.Controls do
        if SameText(Control.FormName, FormName) and Control.HasPosition and
           Control.HasSize and (Control.TranslatedText <> '') then
          Html.Add(Format('<div class="ctl" title="%s" style="left:%dpx;top:%dpx;width:%dpx;height:%dpx">%s</div>',
            [HtmlEncode(Control.ComponentName), Round(Control.Left * Scale),
             Round(Control.Top * Scale), Max(4, Round(Control.Width * Scale)),
             Max(4, Round(Control.Height * Scale)),
             HtmlEncode(Control.TranslatedText)]));
      Html.Add('</div></div><div class="view"><h3>Proposed runtime layout</h3><div class="canvas" style="width:' +
        IntToStr(Round(MaxWidth * Scale)) + 'px;height:' +
        IntToStr(Round(MaxHeight * Scale)) + 'px">');
      for Control in AReview.Controls do
        if SameText(Control.FormName, FormName) and Control.HasPosition and
           Control.HasSize and (Control.TranslatedText <> '') then
        begin
          ProposedWidth := Control.Width;
          ProposedHeight := Control.Height;
          ProposedWrap := Control.WordWrap;
          Color := 'ctl';
          for Proposal in AReview.Proposals do
            if SameText(Proposal.FormName, Control.FormName) and
              SameText(Proposal.ComponentName, Control.ComponentName) and
              not SameText(Proposal.Decision, 'rejected') and
              not SameText(Proposal.Decision, 'manual') then
            begin
              Color := 'ctl proposed';
              if SameText(Proposal.PropertyName, 'Width') then
                ProposedWidth := StrToFloatDef(Proposal.ProposedValue,
                  ProposedWidth, TFormatSettings.Invariant)
              else if SameText(Proposal.PropertyName, 'Height') then
                ProposedHeight := StrToFloatDef(Proposal.ProposedValue,
                  ProposedHeight, TFormatSettings.Invariant)
              else if SameText(Proposal.PropertyName, 'WordWrap') then
                ProposedWrap := SameText(Proposal.ProposedValue, 'True');
            end;
          if ProposedWrap then
            Color := Color + ' wrapped';
          Html.Add(Format('<div class="%s" title="%s" style="left:%dpx;top:%dpx;width:%dpx;height:%dpx">%s</div>',
            [Color, HtmlEncode(Control.ComponentName),
             Round(Control.Left * Scale), Round(Control.Top * Scale),
             Max(4, Round(ProposedWidth * Scale)),
             Max(4, Round(ProposedHeight * Scale)),
             HtmlEncode(Control.TranslatedText)]));
        end;
      Html.Add('</div></div></div></div>');
    end;
    Html.Add('</body></html>');
    ForceDirectories(TPath.GetDirectoryName(AHtmlFileName));
    TFile.WriteAllText(AHtmlFileName, Html.Text, TEncoding.UTF8);
  finally
    FormNames.Free;
    Html.Free;
  end;
end;

end.
