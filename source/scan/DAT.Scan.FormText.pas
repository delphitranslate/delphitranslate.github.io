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
  DAT.Scan.Quality,
  DAT.Scan.TextCodec;

type
  TObjectContext = record
    ComponentName: string;
    ComponentClassName: string;
    FontColor: string;
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
  AContext.FontColor := '';
  Result := (AContext.ComponentName <> '') and
    (AContext.ComponentClassName <> '');
end;

{ The class of the objects inside a DFM collection property. A collection is
  written as Columns = <item ... end item ... end>, and the items carry no
  class of their own, so the owner and the property name are what identify
  them. Returning a blank means the items are not text-bearing as far as we
  know, and they are then walked for structure only. }
function CollectionItemClassName(const AOwnerClassName,
  APropertyName: string): string;
begin
  Result := '';
  if SameText(APropertyName, 'Panels') then
    Result := 'TStatusPanel'
  else if SameText(APropertyName, 'Columns') then
  begin
    if SameText(AOwnerClassName, 'TListView') then
      Result := 'TListColumn'
    else
      Result := 'TColumn';
  end
  else if SameText(APropertyName, 'Groups') then
    Result := 'TListGroup'
  else if SameText(APropertyName, 'Sections') then
    Result := 'THeaderSection'
  else if SameText(APropertyName, 'Bands') then
    Result := 'TCoolBand'
  else if SameText(APropertyName, 'ActionBars') or
    SameText(APropertyName, 'Items') then
    Result := 'TActionClientItem'
  else if SameText(APropertyName, 'Categories') then
    Result := 'TButtonCategory';
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
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

class procedure TTextFormScanner.ScanFile(const AFileName: string;
  const AFramework: TTargetFramework; const AResult: TProjectScanResult);
var
  CollectionIndex: Integer;
  ItemContext: TObjectContext;
  ItemClassName: string;
  ItemCollectionProperty: string;
  ItemIndex: Integer;
  InItemCollection: Boolean;
  InCollectionItem: Boolean;
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
    LoadDelphiTextFile(AFileName, Lines);
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
    InItemCollection := False;
    InCollectionItem := False;
    ItemIndex := 0;
    ItemClassName := '';
    ItemCollectionProperty := '';
    while LineIndex < Lines.Count do
    begin
      TrimmedLine := Trim(Lines[LineIndex]);

      { A collection is walked before anything else, because its items are
        delimited by the same 'end' that closes an object. Left unhandled,
        the first item's 'end' closed the component that owned the collection
        and every property after it was recorded against the wrong parent. }
      if InItemCollection then
      begin
        if SameText(TrimmedLine, 'item') then
        begin
          ItemContext.ComponentName := Format('%s.%s[%d]',
            [ContextStack[ContextStack.Count - 1].ComponentName,
             ItemCollectionProperty, ItemIndex]);
          ItemContext.ComponentClassName := ItemClassName;
          ItemContext.FontColor := '';
          InCollectionItem := True;
          Inc(LineIndex);
          Continue;
        end;
        if StartsText('end', TrimmedLine) or StartsText('>', TrimmedLine) then
        begin
          if InCollectionItem then
          begin
            InCollectionItem := False;
            Inc(ItemIndex);
          end;
          if EndsText('>', TrimmedLine) then
            InItemCollection := False;
          Inc(LineIndex);
          Continue;
        end;
        EqualsPosition := Pos('=', TrimmedLine);
        if (EqualsPosition > 0) and InCollectionItem and
          (ItemClassName <> '') then
        begin
          PropertyName := Trim(Copy(TrimmedLine, 1, EqualsPosition - 1));
          Expression := Trim(Copy(TrimmedLine, EqualsPosition + 1, MaxInt));
          if TScanRuleSet.IsTranslatableProperty(AFramework, ItemClassName,
            PropertyName, False) then
          begin
            SourceLine := LineIndex + 1;
            while ((Expression = '') or EndsText('+', Expression)) and
              (LineIndex + 1 < Lines.Count) do
            begin
              Inc(LineIndex);
              if Expression = '' then
                Expression := Trim(Lines[LineIndex])
              else
                Expression := Expression + ' ' + Trim(Lines[LineIndex]);
            end;
            if TryDecodeDelphiStringExpression(Expression, ValueText) then
              AddScanItem(AResult, AFramework, AFileName, FormName,
                ItemContext, PropertyName, ValueText, SourceLine, -1);
          end;
        end;
        Inc(LineIndex);
        Continue;
      end;

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
      if SameText(PropertyName, 'TextSettings.FontColor') or
        SameText(PropertyName, 'Font.Color') then
      begin
        if TryDecodeDelphiStringExpression(Expression, ValueText) then
          Context.FontColor := ValueText
        else
          Context.FontColor := Expression;
        ContextStack[ContextStack.Count - 1] := Context;
        for var ExistingItem in AResult.Items do
          if SameText(ExistingItem.SourceFileName, AFileName) and
            SameText(ExistingItem.FormName, FormName) and
            SameText(ExistingItem.ComponentName, Context.ComponentName) then
            ExistingItem.FontColor := Context.FontColor;
      end;
      { Entered before the translatability test, because the collection has to
        be walked whether or not its items carry text: it is the structure
        that must stay straight. }
      if StartsText('<', Expression) and (ContextStack.Count > 0) then
      begin
        ItemCollectionProperty := PropertyName;
        ItemClassName := CollectionItemClassName(
          Context.ComponentClassName, PropertyName);
        ItemIndex := 0;
        InCollectionItem := False;
        InItemCollection := not EndsText('>', Expression);
        Inc(LineIndex);
        Continue;
      end;

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
