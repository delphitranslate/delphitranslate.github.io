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
    FFontFamily: string;
    FAlign: string;
    FHorzAlign: string;
    FWordWrap: Boolean;
    FAutoSize: Boolean;
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
    property FontFamily: string read FFontFamily write FFontFamily;
    property Align: string read FAlign write FAlign;
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
  FMX.TextLayout,
  DAT.Core.CatalogJson,
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

function InvariantFloat(const AValue: string; out AResult: Double): Boolean;
var
  Settings: TFormatSettings;
begin
  Settings := TFormatSettings.Create('en-US');
  Result := TryStrToFloat(Trim(AValue), AResult, Settings);
end;

function UnquoteDelphiString(const AValue: string): string;
begin
  Result := Trim(AValue);
  if (Length(Result) >= 2) and (Result[1] = '''') and
    (Result[Length(Result)] = '''') then
  begin
    Result := Copy(Result, 2, Length(Result) - 2);
    Result := StringReplace(Result, '''''', '''', [rfReplaceAll]);
  end;
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

procedure AddProposal(const AReview: TLocalizationReview;
  const AControl: TLayoutControl; const APropertyName, ACurrent,
  AProposed, ARationale: string);
var
  ExistingNumber: Double;
  NewNumber: Double;
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
  Proposal.ComponentName := AControl.ComponentName;
  Proposal.PropertyName := APropertyName;
  Proposal.CurrentValue := ACurrent;
  Proposal.ProposedValue := AProposed;
  Proposal.Rationale := ARationale;
  { The geometry properties the runtime can apply are the whole point of the
    analysis, and they only reach the pack once accepted. Leaving them pending
    means a form is planned coherently and then ships with an arbitrary subset
    of that plan, which is worse than shipping none of it: a caption is
    widened while the control it displaced stays put. Start them accepted;
    RestoreDecisions still lets an explicit rejection from the review win. }
  if MatchText(APropertyName, ['Width', 'Height', 'WordWrap', 'AutoSize',
    'Left', 'Top', 'Position.X', 'Position.Y', 'FontSize']) then
    Proposal.Decision := 'accepted'
  else
    Proposal.Decision := 'pending';
  Proposal.SourceChecksum := THashSHA2.GetHashString(
    AControl.SourceText + '|' + AControl.TranslatedText + '|' + ACurrent);
  AReview.Proposals.Add(Proposal);
end;

constructor TLocalizationReview.Create;
begin
  inherited Create;
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

class procedure TLocalizationReviewer.ScanLayout(
  const ACatalog: TTranslationCatalog; const AReview: TLocalizationReview);
var
  Entry: TTranslationEntry;
  Files: TStringList;
  Lines: TStringList;
  Stack: TList<TObjectFrame>;
  FileName, Line, Prop, Value, Name, ClassName, FormName: string;
  SourceText, TranslatedText: string;
  I, P: Integer;
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
    for FileName in Files do
    begin
      Stack.Clear;
      LoadDelphiTextFile(FileName, Lines);
      FormName := '';
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        if ParseObject(Line, Name, ClassName) then
        begin
          Frame := Default(TObjectFrame);
          Frame.Name := Name;
          Frame.ClassName := ClassName;
          Frame.Control := TLayoutControl.Create;
          Frame.Control.ComponentName := Name;
          Frame.Control.ComponentClassName := ClassName;
          Frame.Control.SourceFileName := FileName;
          Frame.Control.FontSize := 12;
          if Stack.Count = 0 then
            FormName := Name
          else
          begin
            ParentFrame := Stack[Stack.Count - 1];
            Frame.Control.ParentName := ParentFrame.Name;
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
            Frame.Control.FontSize := Number;
        end
        else if SameText(Prop, 'Align') then
          Frame.Control.Align := Value
        else if MatchText(Prop, ['TextSettings.HorzAlign', 'HorzAlign',
          'Alignment']) then
          Frame.Control.HorzAlign := Value
        else if MatchText(Prop, ['TextSettings.Font.Family', 'Font.Family']) then
          Frame.Control.FontFamily := UnquoteDelphiString(Value)
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
  MaximumComfortableLines = 2;
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
  CompactButtonMaxHeight = 40;
  CompactButtonMinWidth = 86;
  CompactButtonMaxWidth = 150;
  LongButtonMaxWidth = 320;
var
  Control, Other: TLayoutControl;
  RequiredWidth, RequiredHeight, FontSize: Double;
  LineCount: Integer;
  NewWidth: Integer;
  IsButton: Boolean;
  IsWrappingText: Boolean;
  Pass: Integer;
  Moved: Boolean;
  Leader, Follower: TLayoutControl;
  RequiredLeft, Surplus, ReducedWidth, ReducedFont, ShiftedLeft: Double;
  RequiredTop, ReducedHeight, EffectiveFont: Double;
  WrappedLines: Integer;
  PackedButtons, Cluster: TList<TLayoutControl>;
  UniformWidth, ClusterGap, ClusterLeft, ClusterOffset, Available, Total: Double;
  LeftRoom: Double;
  ClusterOverlaysDesign: Boolean;
  Candidate: TLayoutControl;

  { Measure the translated text with the same engine that renders it at
    runtime. Character-count arithmetic cannot predict real glyph widths, so
    every sizing decision below starts from an actual measurement. }
  { Breathing room this class of control keeps between its text and its edge. }
  function PaddingHorizontal(const AControl: TLayoutControl): Double;
  begin
    if ContainsText(AControl.ComponentClassName, 'Button') then
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

  function TextWidthEstimate(const AControl: TLayoutControl): Double;
  var
    Layout: TTextLayout;
    PointSize: Double;
  begin
    if Trim(AControl.TranslatedText) = '' then
      Exit(0);
    { Measure at the size the text will actually be drawn. Measuring a caption
      at its designed size after deciding to shrink it overstates the room it
      needs and buys height it will not use. }
    PointSize := AControl.PlannedFontSize;
    if PointSize <= 0 then
      PointSize := AControl.FontSize;
    Layout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      Layout.BeginUpdate;
      Layout.Text := AControl.TranslatedText;
      Layout.Font.Size := Max(PointSize, 9);
      if Trim(AControl.FontFamily) <> '' then
        Layout.Font.Family := AControl.FontFamily;
      Layout.WordWrap := False;
      Layout.EndUpdate;
      { Ask for the room the text occupies plus the breathing room its class
        keeps, so a control sized from this reads properly rather than merely
        fitting by arithmetic. }
      Result := Layout.Width + 2 * PaddingHorizontal(AControl);
    finally
      Layout.Free;
    end;
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
    BareText: Double;
  begin
    BareText := TextWidthEstimate(AControl) - 2 * PaddingHorizontal(AControl);
    Result := Max(1, Ceil(BareText /
      Max(AWidth - 2 * PaddingHorizontal(AControl), 1)));
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

  { The right-hand edge of the designed content on this control's parent. The
    parent's own size is not always present in the scanned model, so fall back
    to the furthest edge the designer actually placed something at. Growth and
    separation stay inside this, which keeps a widened control on the form. }
  function ContentRightBound(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
    ParentWidth: Double;
  begin
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
    Candidate: TLayoutControl;
  begin
    Result := 0;
    for Candidate in AReview.Controls do
      if SameText(Candidate.FormName, AControl.FormName) and
        SameText(Candidate.ComponentName, AControl.FormName) and
        Candidate.HasSize then
        Exit(Candidate.Height);
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
        this control may become; it will be stepped aside instead. }
      if CanMoveControl(Candidate) then
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
      if (AControl.Width <= CompactButtonMaxWidth) and
        (AControl.Height <= CompactButtonMaxHeight + 8) then
      begin
        GrowthCap := Max(AControl.Width * 1.15, CompactButtonMinWidth);
        HardCap := CompactButtonMaxWidth;
      end
      else
      begin
        GrowthCap := Max(AControl.Width * 1.20, 140);
        HardCap := LongButtonMaxWidth;
      end;
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

  function LooksLikeCompactButton(const AControl: TLayoutControl): Boolean;
  begin
    Result := IsButtonLike(AControl) and
      (AControl.Width <= CompactButtonMaxWidth) and
      (AControl.Height <= CompactButtonMaxHeight + 8);
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

  function IsVisualContainer(const AControl: TLayoutControl): Boolean;
  begin
    Result :=
      ContainsText(AControl.ComponentClassName, 'Rectangle') or
      ContainsText(AControl.ComponentClassName, 'Panel') or
      ContainsText(AControl.ComponentClassName, 'GroupBox') or
      ContainsText(AControl.ComponentClassName, 'Layout');
  end;

  procedure GrowVisualContainersForTranslatedCaptions;
  var
    CaptionControl, Container: TLayoutControl;
  begin
    for CaptionControl in AReview.Controls do
    begin
      if (CaptionControl.TranslatedText = '') or not CaptionControl.HasPosition or
        not CaptionControl.HasSize then
        Continue;
      for Container in AReview.Controls do
      begin
        if (Container = CaptionControl) or not Container.HasPosition or
          not Container.HasSize then
          Continue;
        if not SameText(Container.FormName, CaptionControl.FormName) then
          Continue;
        if not IsVisualContainer(Container) then
          Continue;
        if not DesignedOverlap(CaptionControl, Container) then
          Continue;
        if CaptionControl.PlannedLeft + CaptionControl.PlannedWidth >
          Container.PlannedLeft + Container.PlannedWidth - 4 then
          Container.PlannedWidth :=
            Ceil(CaptionControl.PlannedLeft + CaptionControl.PlannedWidth -
              Container.PlannedLeft + 4);
        if CaptionControl.PlannedTop + CaptionControl.PlannedHeight >
          Container.PlannedTop + Container.PlannedHeight - 4 then
          Container.PlannedHeight :=
            Ceil(CaptionControl.PlannedTop + CaptionControl.PlannedHeight -
              Container.PlannedTop + 4);
      end;
    end;
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
    Control.PlannedWordWrap := Control.WordWrap;
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
      if Control.HasPosition and not IsRightAligned(Control) and
        not IsCentreAligned(Control) and
        (RequiredWidth > SpaceToRight(Control)) then
      begin
        LeftRoom := SpaceToLeft(Control);
        ShiftedLeft := Min(LeftRoom, RequiredWidth - SpaceToRight(Control));
        if ShiftedLeft > 2 then
          Control.PlannedLeft := Max(0, Control.PlannedLeft - ShiftedLeft);
      end;
      { Small centered labels are commonly drawn over a visual container
        (for example a white checkbox caption box). If they simply widen about
        center, the text escapes the container. Treat those like contained
        captions: preserve the designer's box, wrap inside it, and buy only
        the height needed to keep the words visible. Larger centered headings
        are handled by the normal row-free widening rule below. }
      if IsCentreAligned(Control) and
        ContainsText(Control.ComponentClassName, 'Label') and
        (Control.Width < 180) and IsWrappingText and
        (Control.Width >= MinimumWrapWidth) then
      begin
        Control.PlannedWordWrap := True;
        LineCount := WrappedLineCount(Control, Control.Width);
        Control.PlannedHeight := Max(Control.PlannedHeight,
          Ceil(RequiredHeight * LineCount + 2 * PaddingVertical(Control)));
      end
      { Very long action-button captions should wrap inside a compact button
        rather than shrinking into a tiny font or pushing the row apart. Short
        compact buttons such as Play/Pause/Stop still stay one-line. }
      else if IsButton and LooksLikeCompactButton(Control) and
        IsWrappingText and (RequiredWidth > CompactButtonMaxWidth + 8) then
      begin
        Control.PlannedWidth := Max(Control.Width,
          Min(LongButtonMaxWidth, Max(Control.Width, CompactButtonMaxWidth)));
        Control.PlannedWordWrap := True;
        LineCount := WrappedLineCount(Control, Control.PlannedWidth);
        Control.PlannedHeight := Max(Control.PlannedHeight,
          Ceil(RequiredHeight * LineCount + 2 * PaddingVertical(Control)));
      end
      { Widening only costs something when there is something beside the
        control to disturb. A heading alone on its row has empty space either
        side, and taking that space changes nothing else on the form, whereas
        wrapping it doubles its height and can push it into the row below.
        So where the row is genuinely clear, widen and stay on one line. }
      else if RowIsFree(Control, True, False) and RowIsFree(Control, False, False) then
      begin
        NewWidth := BoundedTextWidth(Control, RequiredWidth);
        if NewWidth > Ceil(Control.Width) then
        begin
          SetPlannedWidthRespectingAlignment(Control, NewWidth);
        end;
        if NewWidth < Ceil(RequiredWidth) then
        begin
          { Even the whole row was not enough, so fall back to wrapping. }
          Control.PlannedWordWrap := IsWrappingText and
            not LooksLikeCompactButton(Control);
          LineCount := WrappedLineCount(Control, Max(NewWidth, 24));
          if not IsButton then
            Control.PlannedHeight := Max(Control.PlannedHeight,
              Ceil(RequiredHeight * LineCount));
        end;
      end
      else if IsWrappingText and (Control.Width >= MinimumWrapWidth) and
        (BoundedTextWidth(Control, RequiredWidth) >= RequiredWidth - 1) then
      begin
        { There is room beside this control for the whole caption, so take it
          and stay on one line. Wrapping here would ask for height the form
          often has less of than width: a button in a stacked column has forty
          pixels above the next one but most of the form to its right. }
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
        if (RequiredWidth > Control.Width) and
          (ReducedFont >= FontSize * ModestFontReduction) and
          (ReducedFont >= MinimumReadableFontSize) then
        begin
          Control.PlannedFontSize := ReducedFont;
          RequiredWidth := RequiredWidth * ReducedFont / FontSize;
          RequiredHeight := ReducedFont * 1.65;
        end;
        Control.PlannedWordWrap := not LooksLikeCompactButton(Control);
        LineCount := WrappedLineCount(Control, Control.Width);
        if LineCount > MaximumComfortableLines then
        begin
          { Shrink the text just enough for the lines that will fit, never
            below the readable floor. }
          ReducedFont := Max(SmallestFontFor(Control),
            FontSize * MaximumComfortableLines / LineCount);
          if ReducedFont < FontSize then
          begin
            Control.PlannedFontSize := ReducedFont;
            RequiredWidth := RequiredWidth * ReducedFont / FontSize;
            RequiredHeight := ReducedFont * 1.65;
            LineCount := WrappedLineCount(Control, Control.Width);
          end;
        end;
        if LineCount > MaximumComfortableLines then
        begin
          { Still cramped after shrinking, so widen as a last resort, only far
            enough to reach a comfortable line count. }
          NewWidth := BoundedTextWidth(Control,
            RequiredWidth / MaximumComfortableLines);
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
    if (Control.Height > 0) and (RequiredHeight > Control.Height) then
    begin
      AddFinding(AReview, lfsWarning, 'Layout',
        Control.FormName + '.' + Control.ComponentName,
        'The control may be too short for its translated text and font.',
        'Review the proposed height or enable automatic sizing.');
      if LooksLikeCompactButton(Control) then
        Control.PlannedHeight := Min(Max(Control.PlannedHeight,
          Ceil(RequiredHeight)), CompactButtonMaxHeight)
      else
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
        if LooksLikeCompactButton(Cluster[0]) then
          UniformWidth := Min(Max(UniformWidth, CompactButtonMinWidth),
            CompactButtonMaxWidth);

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
          UniformWidth := Max(0,
            (Available - (Cluster.Count - 1) * ClusterGap) / Cluster.Count);
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

        ClusterOffset := ClusterLeft;
        for Other in Cluster do
        begin
          Other.PlannedLeft := ClusterOffset;
          Other.PlannedWidth := UniformWidth;
          Other.PlannedWordWrap := not LooksLikeCompactButton(Other);
          if LooksLikeCompactButton(Other) then
            Other.PlannedHeight := Min(Max(Other.Height, Other.PlannedHeight),
              CompactButtonMaxHeight);
          if TextWidthEstimate(Other) > UniformWidth then
          begin
            ReducedFont := Max(SmallestFontFor(Other),
              Max(Other.FontSize, 9) * UniformWidth /
              Max(TextWidthEstimate(Other), 1));
            if ReducedFont < Max(Other.FontSize, 9) then
              Other.PlannedFontSize := ReducedFont;
          end;
          ClusterOffset := ClusterOffset + UniformWidth + ClusterGap;
        end;
      finally
        Cluster.Free;
      end;
    end;
  finally
    PackedButtons.Free;
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
      not Control.PlannedWordWrap or (Control.PlannedWidth <= 0) then
      Continue;
    EffectiveFont := Control.PlannedFontSize;
    if EffectiveFont <= 0 then
      EffectiveFont := Max(Control.FontSize, 9);
    { Text wraps inside the padding, not inside the whole control, so count the
      lines against the room the text actually gets. Measuring against the full
      width reports fewer lines than will really appear and buys too little
      height for them. }
    WrappedLines := WrappedLineCount(Control, Control.PlannedWidth);
    Control.PlannedHeight := Max(Control.PlannedHeight,
      Ceil(WrappedLines * EffectiveFont * 1.65 +
        2 * PaddingVertical(Control)));
  end;

  { Phase 2c - when a translated caption is drawn on top of a shaped or white
    visual container, the text box and the visual box are a unit. Growing only
    the text produces exactly the ugly "text outside its box" failure the
    contracts are meant to prevent. Expand the visual box enough to contain
    the translated caption, but do not move unrelated target source. }
  GrowVisualContainersForTranslatedCaptions;

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
            (RequiredLeft - Follower.Left <= MaximumDrift) then
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
          if CanMoveControl(Follower) and
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

  { A separation pass can move a caption after the first containment pass.
    Re-grow visual containers after positions settle so text remains inside
    the white/outlined boxes the developer designed. }
  GrowVisualContainersForTranslatedCaptions;

  { Phase 4 - emit proposals from the settled geometry. Because every value
    comes from the same resolved model, the exported rules agree with one
    another instead of describing conflicting placements. }
  for Control in AReview.Controls do
  begin
    if not Control.HasSize then
      Continue;
    { Sizing and wrapping only mean something for a control whose text was
      translated. }
    if Control.TranslatedText <> '' then
    begin
      if Ceil(Control.PlannedWidth) > Ceil(Control.Width) then
        AddProposal(AReview, Control, 'Width', FloatToStr(Control.Width),
          IntToStr(Ceil(Control.PlannedWidth)),
          'Width measured from the translated text and clamped to the space actually available.');
      if Control.PlannedWordWrap and not Control.WordWrap then
        AddProposal(AReview, Control, 'WordWrap', 'False', 'True',
          'Wrap the translated text instead of expanding across neighboring controls.');
      if Control.PlannedWordWrap and Control.AutoSize then
        AddProposal(AReview, Control, 'AutoSize', 'True', 'False',
          'Disable one-line automatic sizing so the translated text can wrap inside the planned width.');
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
    if (Control.TranslatedText = '') and IsVisualContainer(Control) then
    begin
      if Ceil(Control.PlannedWidth) > Ceil(Control.Width) then
        AddProposal(AReview, Control, 'Width', FloatToStr(Control.Width),
          IntToStr(Ceil(Control.PlannedWidth)),
          'Grow the visual container so translated text remains inside its box.');
      if Ceil(Control.PlannedHeight) > Ceil(Control.Height) then
        AddProposal(AReview, Control, 'Height', FloatToStr(Control.Height),
          IntToStr(Ceil(Control.PlannedHeight)),
          'Grow the visual container so translated text remains inside its box.');
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
            Proposal.Decision := Item.GetValue<string>('decision', 'pending');
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
