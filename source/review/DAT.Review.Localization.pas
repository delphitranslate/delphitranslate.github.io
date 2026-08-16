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
    FWordWrap: Boolean;
    FAutoSize: Boolean;
    FHasPosition: Boolean;
    FHasSize: Boolean;
    FPlannedLeft: Double;
    FPlannedTop: Double;
    FPlannedWidth: Double;
    FPlannedHeight: Double;
    FPlannedWordWrap: Boolean;
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
    property Align: string read FAlign write FAlign;
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
  Proposal.Decision := 'pending';
  Proposal.SourceChecksum := THashSHA2.GetHashString(
    AControl.SourceText + '|' + ACurrent);
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
var
  Control, Other: TLayoutControl;
  RequiredWidth, RequiredHeight, FontSize: Double;
  LineCount: Integer;
  NewWidth: Integer;
  IsButton: Boolean;
  IsWrappingText: Boolean;
  Pass: Integer;
  Moved: Boolean;

  { Measure the translated text with the same engine that renders it at
    runtime. Character-count arithmetic cannot predict real glyph widths, so
    every sizing decision below starts from an actual measurement. }
  function TextWidthEstimate(const AControl: TLayoutControl): Double;
  var
    Layout: TTextLayout;
  begin
    if Trim(AControl.TranslatedText) = '' then
      Exit(0);
    Layout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      Layout.BeginUpdate;
      Layout.Text := AControl.TranslatedText;
      Layout.Font.Size := Max(AControl.FontSize, 9);
      Layout.WordWrap := False;
      Layout.EndUpdate;
      Result := Layout.Width + 18;
    finally
      Layout.Free;
    end;
  end;

  function MeasuredLineHeight(const AControl: TLayoutControl): Double;
  begin
    Result := Max(AControl.FontSize, 9) * 1.65;
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

  { The widest this control may become before it would cross either its
    parent's right edge or the nearest planned neighbour on the same row. }
  function AvailableWidth(const AControl: TLayoutControl): Double;
  var
    Candidate: TLayoutControl;
    NearestLeft: Double;
    ParentWidth: Double;
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
      if Candidate.PlannedLeft <= AControl.PlannedLeft + 2 then
        Continue;
      if (Candidate.PlannedTop >= AControl.PlannedTop +
            AControl.PlannedHeight) or
         (Candidate.PlannedTop + Candidate.PlannedHeight <=
            AControl.PlannedTop) then
        Continue;
      if Candidate.PlannedLeft < NearestLeft then
        NearestLeft := Candidate.PlannedLeft;
    end;
    if NearestLeft < MaxDouble then
      Result := NearestLeft - AControl.PlannedLeft - ControlGap
    else
    begin
      ParentWidth := ParentWidthFor(AControl);
      if ParentWidth > 0 then
        Result := ParentWidth - AControl.PlannedLeft - ControlGap
      else
        Result := AControl.PlannedWidth;
    end;
    Result := Max(Result, 24);
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
    Result := Ceil(Min(ARequiredWidth, Min(GrowthCap, HardCap)));
    { Never propose a width that would cross the parent edge or the next
      control on the same row. Wrapping absorbs whatever will not fit. }
    Result := Min(Result, Ceil(AvailableWidth(AControl)));
    if Result < Ceil(AControl.Width) then
      Result := Ceil(AControl.Width);
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

  function PlannedOverlap(const AFirst, ASecond: TLayoutControl): Boolean;
  begin
    Result :=
      (AFirst.PlannedLeft < ASecond.PlannedLeft + ASecond.PlannedWidth) and
      (AFirst.PlannedLeft + AFirst.PlannedWidth > ASecond.PlannedLeft) and
      (AFirst.PlannedTop < ASecond.PlannedTop + ASecond.PlannedHeight) and
      (AFirst.PlannedTop + AFirst.PlannedHeight > ASecond.PlannedTop);
  end;

  function SamePlannedRow(const AFirst, ASecond: TLayoutControl): Boolean;
  begin
    Result := Abs((AFirst.PlannedTop + AFirst.PlannedHeight / 2) -
      (ASecond.PlannedTop + ASecond.PlannedHeight / 2)) <=
      Max(8, Max(AFirst.PlannedHeight, ASecond.PlannedHeight) * 0.55);
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
    if (Control.Width > 0) and (RequiredWidth > Control.Width * 1.05) then
    begin
      AddFinding(AReview, lfsHighRisk, 'Layout',
        Control.FormName + '.' + Control.ComponentName,
        Format('Measured translated width %.0f exceeds the %.0f-pixel control.',
          [RequiredWidth, Control.Width]),
        'Review the proposed width, wrapping, or nearby control placement.');
      NewWidth := BoundedTextWidth(Control, RequiredWidth);
      if IsWrappingText and (Control.Width >= 80) then
      begin
        Control.PlannedWidth := NewWidth;
        Control.PlannedWordWrap := True;
        { Line count is measured against the width the control will actually
          have, so the height matches what the text will really occupy. }
        LineCount := Max(1, Ceil(RequiredWidth / Max(NewWidth, 24)));
        if not IsButton then
          Control.PlannedHeight := Max(Control.PlannedHeight,
            Ceil(RequiredHeight * LineCount));
      end
      else
        Control.PlannedWidth := NewWidth;
    end;
    if (Control.Height > 0) and (RequiredHeight > Control.Height * 1.10) then
    begin
      AddFinding(AReview, lfsWarning, 'Layout',
        Control.FormName + '.' + Control.ComponentName,
        'The control may be too short for its translated text and font.',
        'Review the proposed height or enable automatic sizing.');
      Control.PlannedHeight := Max(Control.PlannedHeight, Ceil(RequiredHeight));
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
        if Pass = 1 then
          AddFinding(AReview, lfsWarning, 'Overlap',
            Control.FormName + '.' + Control.ComponentName,
            'This control intersects ' + Other.ComponentName +
              ' after measured translated sizing.',
            'Review the proposed move/size rule or adjust the designer layout manually.');
        if SamePlannedRow(Control, Other) then
        begin
          { Push the right-hand control clear of the left-hand one. }
          if (Control.PlannedLeft <= Other.PlannedLeft) and
            CanMoveControl(Other) then
          begin
            Other.PlannedLeft := Control.PlannedLeft + Control.PlannedWidth +
              ControlGap;
            Moved := True;
          end
          else if (Other.PlannedLeft < Control.PlannedLeft) and
            CanMoveControl(Control) then
          begin
            Control.PlannedLeft := Other.PlannedLeft + Other.PlannedWidth +
              ControlGap;
            Moved := True;
          end;
        end
        else
        begin
          { Push the lower control clear of the upper one. }
          if (Control.PlannedTop <= Other.PlannedTop) and
            CanMoveControl(Other) then
          begin
            Other.PlannedTop := Control.PlannedTop + Control.PlannedHeight +
              ControlGap;
            Moved := True;
          end
          else if (Other.PlannedTop < Control.PlannedTop) and
            CanMoveControl(Control) then
          begin
            Control.PlannedTop := Other.PlannedTop + Other.PlannedHeight +
              ControlGap;
            Moved := True;
          end;
        end;
      end;
    end;
    if not Moved then
      Break;
  end;

  { Phase 4 - emit proposals from the settled geometry. Because every value
    comes from the same resolved model, the exported rules agree with one
    another instead of describing conflicting placements. }
  for Control in AReview.Controls do
  begin
    if (Control.TranslatedText = '') or not Control.HasSize then
      Continue;
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
         SameText(Proposal.PropertyName, 'Position.Y')) then
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
