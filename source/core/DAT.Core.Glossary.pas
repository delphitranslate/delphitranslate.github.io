unit DAT.Core.Glossary;

interface

uses
  System.Generics.Collections,
  DAT.Core.Types;

type
  TProjectGlossaryTerm = class
  private
    FSourceText: string;
    FTargetText: string;
    FSemanticConcept: string;
    FContextKind: string;
    FDeveloperNote: string;
    FCaseSensitive: Boolean;
    FApproved: Boolean;
  public
    property SourceText: string read FSourceText write FSourceText;
    property TargetText: string read FTargetText write FTargetText;
    property SemanticConcept: string read FSemanticConcept write FSemanticConcept;
    property ContextKind: string read FContextKind write FContextKind;
    property DeveloperNote: string read FDeveloperNote write FDeveloperNote;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive;
    property Approved: Boolean read FApproved write FApproved;
  end;

  TProjectGlossary = class
  private
    FApplicationId: string;
    FSourceLanguage: string;
    FTargetLanguage: string;
    FTerms: TObjectList<TProjectGlossaryTerm>;
    function TermMatches(const ATerm: TProjectGlossaryTerm;
      const AEntry: TTranslationEntry): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function FindMatch(const AEntry: TTranslationEntry): TProjectGlossaryTerm;
    function ApplyToCatalog(const ACatalog: TTranslationCatalog): Integer;
    procedure SaveToFile(const AFileName: string);
    class function LoadFromFile(const AFileName: string): TProjectGlossary; static;
    property ApplicationId: string read FApplicationId write FApplicationId;
    property SourceLanguage: string read FSourceLanguage write FSourceLanguage;
    property TargetLanguage: string read FTargetLanguage write FTargetLanguage;
    property Terms: TObjectList<TProjectGlossaryTerm> read FTerms;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils;

function JsonText(const AObject: TJSONObject; const AName,
  ADefault: string): string;
var
  Value: TJSONValue;
begin
  Result := ADefault;
  if AObject = nil then
    Exit;
  Value := AObject.GetValue(AName);
  if Value <> nil then
    Result := Value.Value;
end;

constructor TProjectGlossary.Create;
begin
  inherited Create;
  FTerms := TObjectList<TProjectGlossaryTerm>.Create(True);
end;

destructor TProjectGlossary.Destroy;
begin
  FTerms.Free;
  inherited Destroy;
end;

function TProjectGlossary.TermMatches(const ATerm: TProjectGlossaryTerm;
  const AEntry: TTranslationEntry): Boolean;
begin
  if ATerm.CaseSensitive then
    Result := ATerm.SourceText = AEntry.SourceText
  else
    Result := SameText(Trim(ATerm.SourceText), Trim(AEntry.SourceText));
  Result := Result and ATerm.Approved and (Trim(ATerm.TargetText) <> '');
  if Result and (Trim(ATerm.SemanticConcept) <> '') then
    Result := SameText(ATerm.SemanticConcept, AEntry.SemanticConcept);
  if Result and (Trim(ATerm.ContextKind) <> '') then
    Result := SameText(ATerm.ContextKind, AEntry.ContextKind);
end;

function TProjectGlossary.FindMatch(
  const AEntry: TTranslationEntry): TProjectGlossaryTerm;
var
  Term: TProjectGlossaryTerm;
begin
  Result := nil;
  if AEntry = nil then
    Exit;
  for Term in FTerms do
    if TermMatches(Term, AEntry) then
      Exit(Term);
end;

function TProjectGlossary.ApplyToCatalog(
  const ACatalog: TTranslationCatalog): Integer;
var
  Entry: TTranslationEntry;
  Term: TProjectGlossaryTerm;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  for Entry in ACatalog.Entries do
  begin
    Term := FindMatch(Entry);
    if Term = nil then
      Continue;
    if Entry.Status in [tsReviewed, tsApproved] then
      Continue;
    Entry.TranslatedText := Term.TargetText;
    Entry.TranslationOrigin := torProjectGlossary;
    Entry.TranslationConfidence := 'high';
    Entry.TranslationReviewNote := 'Applied from the approved project glossary.';
    Entry.Status := tsMachineTranslated;
    Inc(Result);
  end;
end;

procedure TProjectGlossary.SaveToFile(const AFileName: string);
var
  Root, TermObject: TJSONObject;
  TermsArray: TJSONArray;
  Term: TProjectGlossaryTerm;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(1));
    Root.AddPair('applicationId', ApplicationId);
    Root.AddPair('sourceLanguage', SourceLanguage);
    Root.AddPair('targetLanguage', TargetLanguage);
    TermsArray := TJSONArray.Create;
    for Term in Terms do
    begin
      TermObject := TJSONObject.Create;
      TermObject.AddPair('sourceText', Term.SourceText);
      TermObject.AddPair('targetText', Term.TargetText);
      TermObject.AddPair('semanticConcept', Term.SemanticConcept);
      TermObject.AddPair('contextKind', Term.ContextKind);
      TermObject.AddPair('developerNote', Term.DeveloperNote);
      TermObject.AddPair('caseSensitive', TJSONBool.Create(Term.CaseSensitive));
      TermObject.AddPair('approved', TJSONBool.Create(Term.Approved));
      TermsArray.AddElement(TermObject);
    end;
    Root.AddPair('terms', TermsArray);
    ForceDirectories(TPath.GetDirectoryName(AFileName));
    TFile.WriteAllText(AFileName, Root.Format(2), TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

class function TProjectGlossary.LoadFromFile(
  const AFileName: string): TProjectGlossary;
var
  Root: TJSONObject;
  JsonValue, ArrayValue: TJSONValue;
  TermsArray: TJSONArray;
  TermObject: TJSONObject;
  Term: TProjectGlossaryTerm;
begin
  Result := TProjectGlossary.Create;
  if not TFile.Exists(AFileName) then
    Exit;
  JsonValue := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    Result.Free;
    raise EConvertError.Create('The project glossary is not valid JSON.');
  end;
  Root := TJSONObject(JsonValue);
  try
    Result.ApplicationId := JsonText(Root, 'applicationId', '');
    Result.SourceLanguage := JsonText(Root, 'sourceLanguage', '');
    Result.TargetLanguage := JsonText(Root, 'targetLanguage', '');
    TermsArray := Root.GetValue('terms') as TJSONArray;
    if TermsArray <> nil then
      for ArrayValue in TermsArray do
        if ArrayValue is TJSONObject then
        begin
          TermObject := TJSONObject(ArrayValue);
          Term := TProjectGlossaryTerm.Create;
          Term.SourceText := JsonText(TermObject, 'sourceText', '');
          Term.TargetText := JsonText(TermObject, 'targetText', '');
          Term.SemanticConcept := JsonText(TermObject, 'semanticConcept', '');
          Term.ContextKind := JsonText(TermObject, 'contextKind', '');
          Term.DeveloperNote := JsonText(TermObject, 'developerNote', '');
          Term.CaseSensitive := SameText(
            JsonText(TermObject, 'caseSensitive', 'false'), 'true');
          Term.Approved := SameText(
            JsonText(TermObject, 'approved', 'true'), 'true');
          Result.Terms.Add(Term);
        end;
  finally
    Root.Free;
  end;
end;

end.
