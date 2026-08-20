program PackLayoutSmokeTests;

{ Whether a layout decision actually reaches the pack.

  There is a filter between the layout proposal and the runtime pack that names
  the properties allowed through. It has now eaten a feature twice without a
  word: the FireMonkey applicator had its own copy of the list and dropped
  every right-to-left rule, and this one dropped Alignment and ColumnOrder
  after the planner had correctly worked them out. In both cases the proposal
  file was right, the runtime was right, and the pack in between was silently
  empty.

  Nothing about that is visible from either end. The planner's contracts pass
  because the plan is correct; the applicator's tests pass because they are
  handed a pack written by hand. Only a test that goes proposal-to-pack can
  see the hole, which is what this is. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.Hyphenation in '..\..\source\core\DAT.Core.Hyphenation.pas',
  DAT.Core.RuntimePack in '..\..\source\core\DAT.Core.RuntimePack.pas';

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

{ A proposal file of the shape the reviewer writes, with one accepted decision
  for each kind of thing the planner can decide. }
function WriteProposalFile: string;
const
  Item =
    '{"formName":"frmMain","componentName":"%s","propertyName":"%s",' +
    '"currentValue":"%s","proposedValue":"%s","sourceChecksum":"c",' +
    '"decision":"accepted"}';
var
  Body: string;
begin
  Body :=
    '{"applicationId":"PackSample","languageCode":"he-IL","proposals":[' +
    Format(Item, ['lblName', 'Left', '16', '304']) + ',' +
    Format(Item, ['lblName', 'Alignment', 'taLeftJustify',
      'taRightJustify']) + ',' +
    Format(Item, ['pnlNav', 'Align', 'alLeft', 'alRight']) + ',' +
    Format(Item, ['edtName', 'Anchors', '[akLeft,akTop]',
      '[akRight,akTop]']) + ',' +
    Format(Item, ['edtName', 'TabOrder', '0', '2']) + ',' +
    Format(Item, ['grdData', 'Columns[0].Width', '60', '90']) + ',' +
    Format(Item, ['grdData', 'ColumnOrder', 'designed', 'reversed']) + ',' +
    Format(Item, ['lblName', 'TextSettings.HorzAlign', 'Leading',
      'Trailing']) +
    ']}';
  Result := TPath.Combine(TPath.GetTempPath, 'dat-pack-layout-proposal.json');
  TFile.WriteAllText(Result, Body, TEncoding.UTF8);
end;

function SampleCatalog: TTranslationCatalog;
var
  Entry: TTranslationEntry;
begin
  Result := TTranslationCatalog.Create;
  Result.ApplicationId := 'PackSample';
  Result.ApplicationVersion := '1.0';
  Result.SourceLanguage := 'en-US';
  Result.Framework := tfVCL;
  Result.Locale.LanguageCode := 'he-IL';
  Result.Locale.NativeLanguageName := 'Hebrew';
  Result.Locale.TextDirection := 'rtl';
  Result.Locale.ShortDateFormat := 'dd/mm/yyyy';
  Result.Locale.LongDateFormat := 'dddd, d mmmm yyyy';
  Result.Locale.ShortTimeFormat := 'hh:nn';
  Result.Locale.LongTimeFormat := 'hh:nn:ss';
  Result.Locale.DecimalSeparator := '.';
  Result.Locale.ThousandSeparator := ',';
  Result.Locale.CurrencySymbol := 'NIS';

  Entry := TTranslationEntry.Create;
  Entry.Key := 'frmMain.lblName.Caption';
  Entry.SourceText := 'Name';
  Entry.TranslatedText := 'Shem';
  Entry.FormName := 'frmMain';
  Entry.ComponentName := 'lblName';
  Entry.ComponentClassName := 'TLabel';
  Entry.PropertyName := 'Caption';
  Entry.SourceKind := 'dfm';
  Entry.SourceFileName := 'Main.dfm';
  Entry.SourceChecksum := 'c';
  Entry.Status := tsReviewed;
  Entry.RuntimeTextRole := rtrStaticText;
  Entry.RuntimeApplication := rakAutomatic;
  Entry.RuntimeWiringConfirmed := True;
  Result.Entries.Add(Entry);
end;

function RuleCount(const APack, APropertyName: string): Integer;
var
  Root: TJSONObject;
  Rules: TJSONArray;
  Item: TJSONValue;
begin
  Result := 0;
  Root := TJSONObject.ParseJSONValue(APack) as TJSONObject;
  try
    Rules := Root.Values['layout'] as TJSONArray;
    if Rules = nil then
      Exit;
    for Item in Rules do
      if SameText((Item as TJSONObject).Values['propertyName'].Value,
        APropertyName) then
        Inc(Result);
  finally
    Root.Free;
  end;
end;

var
  Catalog: TTranslationCatalog;
  Pack: string;
  ProposalFile: string;
begin
  try
    ProposalFile := WriteProposalFile;
    Catalog := SampleCatalog;
    try
      Pack := TRuntimePackBuilder.Serialize(Catalog, ProposalFile);
    finally
      Catalog.Free;
    end;

    Writeln;
    Check(RuleCount(Pack, 'Left') = 1,
      'A position reaches the pack, as it always did.');
    Check(RuleCount(Pack, 'Alignment') = 1,
      'So does text alignment - which it did not, and grids stayed unflipped.');
    Check(RuleCount(Pack, 'Align') = 1,
      'And the edge a framework-placed control sits against.');
    Check(RuleCount(Pack, 'Anchors') = 1,
      'And the anchors, or the form comes apart on the first resize.');
    Check(RuleCount(Pack, 'TabOrder') = 1,
      'And the tab order, which is reading order by another name.');
    Check(RuleCount(Pack, 'ColumnOrder') = 1,
      'And the column order, so a grid reads the way its language reads.');
    Check(RuleCount(Pack, 'Columns[0].Width') = 1,
      'And a column width, which names a path rather than a property.');
    Check(RuleCount(Pack, 'TextSettings.HorzAlign') = 1,
      'And the FireMonkey spelling of alignment.');

    TFile.Delete(ProposalFile);

    if Failures = 0 then
    begin
      Writeln('Pack layout export smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Pack layout export smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
