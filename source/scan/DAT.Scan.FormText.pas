unit DAT.Scan.FormText;

interface

uses
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TTextFormScanner = class
  public
    class procedure ScanFile(const AFileName: string;
      const AFramework: TTargetFramework;
      const AResult: TProjectScanResult); static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Scan.Rules,
  DAT.Scan.Context,
  DAT.Scan.TextCodec;

type
  TObjectContext = record
    ComponentName: string;
    ComponentClassName: string;
  end;

function StartsObjectDeclaration(const ALine: string): Boolean;
begin
  Result := StartsText('object ', ALine) or
    StartsText('inherited ', ALine) or
    StartsText('inline ', ALine);
end;

function TryParseObjectDeclaration(const ALine: string;
  out AContext: TObjectContext): Boolean;
var
  ColonPosition: Integer;
  DeclarationText: string;
  SpacePosition: Integer;
begin
  Result := False;
  DeclarationText := Trim(ALine);
  if not StartsObjectDeclaration(DeclarationText) then
    Exit;

  SpacePosition := Pos(' ', DeclarationText);
  Delete(DeclarationText, 1, SpacePosition);
  ColonPosition := Pos(':', DeclarationText);
  if ColonPosition = 0 then
    Exit;

  AContext.ComponentName := Trim(Copy(DeclarationText, 1,
    ColonPosition - 1));
  AContext.ComponentClassName := Trim(Copy(DeclarationText,
    ColonPosition + 1, MaxInt));
  Result := (AContext.ComponentName <> '') and
    (AContext.ComponentClassName <> '');
end;

function ScanKey(const AFormName, AComponentName, APropertyName: string;
  const ACollectionIndex: Integer): string;
begin
  if SameText(AFormName, AComponentName) then
    Result := AFormName + '.' + APropertyName
  else
    Result := AFormName + '.' + AComponentName + '.' + APropertyName;

  if ACollectionIndex >= 0 then
    Result := Result + '.' + ACollectionIndex.ToString;
end;

procedure AddDiagnostic(const AResult: TProjectScanResult;
  const ASeverity: TScanDiagnosticSeverity; const AMessage, AFileName: string;
  const ALine: Integer);
var
  Diagnostic: TScanDiagnostic;
begin
  Diagnostic := TScanDiagnostic.Create;
  Diagnostic.Severity := ASeverity;
  Diagnostic.MessageText := AMessage;
  Diagnostic.SourceFileName := AFileName;
  Diagnostic.SourceLine := ALine;
  AResult.Diagnostics.Add(Diagnostic);
end;

procedure AddScanItem(const AResult: TProjectScanResult;
  const AFramework: TTargetFramework; const AFileName, AFormName: string;
  const AContext: TObjectContext; const APropertyName, ASourceText: string;
  const ASourceLine, ACollectionIndex: Integer);
var
  ScanItem: TScanItem;
begin
  if ASourceText = '' then
    Exit;

  ScanItem := TScanItem.Create;
  ScanItem.Key := ScanKey(AFormName, AContext.ComponentName,
    APropertyName, ACollectionIndex);
  ScanItem.SourceText := ASourceText;
  ScanItem.FormName := AFormName;
  ScanItem.ComponentName := AContext.ComponentName;
  ScanItem.ComponentClassName := AContext.ComponentClassName;
  ScanItem.PropertyName := APropertyName;
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := ASourceLine;
  ScanItem.CollectionIndex := ACollectionIndex;
  ScanItem.Framework := AFramework;
  ScanItem.Kind := stkFormProperty;
  ScanItem.RuntimeTextRole := TScanRuleSet.ClassifyRuntimeTextRole(
    AContext.ComponentName, AContext.ComponentClassName, APropertyName,
    ASourceText);
  TScanContextAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

class procedure TTextFormScanner.ScanFile(const AFileName: string;
  const AFramework: TTargetFramework; const AResult: TProjectScanResult);
var
  CollectionIndex: Integer;
  CloseCollectionAfterLine: Boolean;
  Context: TObjectContext;
  ContextStack: TList<TObjectContext>;
  EqualsPosition: Integer;
  Expression: string;
  FormName: string;
  IsCollection: Boolean;
  IsRootObject: Boolean;
  LineIndex: Integer;
  Lines: TStringList;
  PropertyName: string;
  SourceLine: Integer;
  TrimmedLine: string;
  ValueText: string;
begin
  if AResult = nil then
    raise EArgumentNilException.Create('A scan result is required.');

  Lines := TStringList.Create;
  ContextStack := TList<TObjectContext>.Create;
  try
    Lines.LoadFromFile(AFileName);
    if (Lines.Count = 0) or
      not StartsObjectDeclaration(Trim(Lines[0])) then
    begin
      AddDiagnostic(AResult, sdsWarning,
        'The form resource is not a supported text DFM/FMX file.',
        AFileName, 1);
      Exit;
    end;

    FormName := '';
    LineIndex := 0;
    while LineIndex < Lines.Count do
    begin
      TrimmedLine := Trim(Lines[LineIndex]);

      if TryParseObjectDeclaration(TrimmedLine, Context) then
      begin
        ContextStack.Add(Context);
        if FormName = '' then
          FormName := Context.ComponentName;
        Inc(LineIndex);
        Continue;
      end;

      if SameText(TrimmedLine, 'end') then
      begin
        if ContextStack.Count > 0 then
          ContextStack.Delete(ContextStack.Count - 1);
        Inc(LineIndex);
        Continue;
      end;

      if ContextStack.Count = 0 then
      begin
        Inc(LineIndex);
        Continue;
      end;

      EqualsPosition := Pos('=', TrimmedLine);
      if EqualsPosition = 0 then
      begin
        Inc(LineIndex);
        Continue;
      end;

      PropertyName := Trim(Copy(TrimmedLine, 1, EqualsPosition - 1));
      Expression := Trim(Copy(TrimmedLine, EqualsPosition + 1, MaxInt));
      Context := ContextStack[ContextStack.Count - 1];
      IsRootObject := ContextStack.Count = 1;
      if not TScanRuleSet.IsTranslatableProperty(AFramework,
        Context.ComponentClassName, PropertyName, IsRootObject) then
      begin
        Inc(LineIndex);
        Continue;
      end;

      IsCollection := SameText(Expression, '(');
      if IsCollection then
      begin
        CollectionIndex := 0;
        Inc(LineIndex);
        while LineIndex < Lines.Count do
        begin
          TrimmedLine := Trim(Lines[LineIndex]);
          if SameText(TrimmedLine, ')') then
            Break;
          CloseCollectionAfterLine := EndsText(')', TrimmedLine);
          if CloseCollectionAfterLine then
            Delete(TrimmedLine, Length(TrimmedLine), 1);
          SourceLine := LineIndex + 1;
          if TryDecodeDelphiStringExpression(TrimmedLine, ValueText) then
          begin
            AddScanItem(AResult, AFramework, AFileName, FormName, Context,
              PropertyName, ValueText, SourceLine, CollectionIndex);
            Inc(CollectionIndex);
          end;
          if CloseCollectionAfterLine then
            Break;
          Inc(LineIndex);
        end;
      end
      else
      begin
        SourceLine := LineIndex + 1;
        while ((Expression = '') or EndsText('+', Expression)) and
          (LineIndex + 1 < Lines.Count) do
        begin
          Inc(LineIndex);
          TrimmedLine := Trim(Lines[LineIndex]);
          if Expression = '' then
            Expression := TrimmedLine
          else
            Expression := Expression + ' ' + TrimmedLine;
        end;
        if TryDecodeDelphiStringExpression(Expression, ValueText) then
          AddScanItem(AResult, AFramework, AFileName, FormName, Context,
            PropertyName, ValueText, SourceLine, -1);
      end;

      Inc(LineIndex);
    end;
  except
    on E: Exception do
      AddDiagnostic(AResult, sdsError, E.Message, AFileName, 0);
  end;
  ContextStack.Free;
  Lines.Free;
end;

end.
