unit DAT.Runtime.FMX;

interface

uses
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  TFMXTranslationApplicator = class
  public
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Integer; overload; static;
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const APreserveControlState: Boolean = True;
      const AApplyLayout: Boolean = True): Integer; overload; static;
    class function ApplyLayoutToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const AUseTranslatedValues: Boolean): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils,
  System.StrUtils,
  System.TypInfo,
  FMX.Controls,
  System.UITypes,
  FMX.Edit,
  FMX.Grid,
  FMX.Memo,
  FMX.Types,
  FMX.WebBrowser;

function ApplyFontColorsToForm(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer;
var
  Component: TComponent;
  ColorText: string;
  ComponentKey: string;
  ComponentName: string;
  ParsedColor: TAlphaColor;

  function FindOwnedComponent(const ARoot: TComponent;
    const AName: string): TComponent;
  var
    Index: Integer;
  begin
    Result := nil;
    if ARoot = nil then
      Exit;
    if SameText(ARoot.Name, AName) then
      Exit(ARoot);
    for Index := 0 to ARoot.ComponentCount - 1 do
    begin
      Result := FindOwnedComponent(ARoot.Components[Index], AName);
      if Result <> nil then
        Exit;
    end;
  end;

  function TryParseColor(const AValue: string; out AColor: TAlphaColor): Boolean;
  var
    HexValue: string;
    NumberValue: UInt64;
  begin
    HexValue := Trim(AValue);
    if SameText(HexValue, 'claWhite') then
      AColor := TAlphaColorRec.White
    else if SameText(HexValue, 'claBlack') then
      AColor := TAlphaColorRec.Black
    else if SameText(HexValue, 'claRed') then
      AColor := TAlphaColorRec.Red
    else if SameText(HexValue, 'claGreen') then
      AColor := TAlphaColorRec.Green
    else if SameText(HexValue, 'claBlue') then
      AColor := TAlphaColorRec.Blue
    else
    begin
      if StartsText('x', HexValue) then
        Delete(HexValue, 1, 1);
      if StartsText('$', HexValue) then
        Delete(HexValue, 1, 1);
      Result := TryStrToUInt64('$' + HexValue, NumberValue) and
        (Length(HexValue) <= 8);
      if Result then
        AColor := TAlphaColor(NumberValue)
      else
        Exit(False);
    end;
    Result := True;
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for ComponentKey in APack.FontColors.Keys do
  begin
    if not StartsText(AFormIdentity + '.', ComponentKey) then
      Continue;
    ComponentName := Copy(ComponentKey, Length(AFormIdentity) + 2, MaxInt);
    Component := FindOwnedComponent(AForm, ComponentName);
    if not (Component is TTextControl) then
      Continue;
    ColorText := APack.FontColors[ComponentKey];
    try
      if not TryParseColor(ColorText, ParsedColor) then
        Continue;
      TTextControl(Component).StyledSettings :=
        TTextControl(Component).StyledSettings - [TStyledSetting.FontColor];
      TTextControl(Component).TextSettings.FontColor := ParsedColor;
      Inc(Result);
    except
      // Optional styling metadata must never block translation.
    end;
  end;
end;

function TrySetLayoutProperty(const AComponent: TComponent;
  const APropertyName, AValue: string): Boolean;
var
  FloatValue: Extended;
  IntegerValue: Int64;
  OrdinalValue: NativeInt;
  PropertyInfo: PPropInfo;
begin
  Result := False;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName);
  if PropertyInfo = nil then
    Exit;
  if PropertyInfo.PropType^.Kind = tkFloat then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue < 0) or (FloatValue > 100000) then
      Exit;
    SetFloatProp(AComponent, PropertyInfo, FloatValue);
    Exit(True);
  end;
  if PropertyInfo.PropType^.Kind in [tkInteger, tkInt64] then
  begin
    if not TryStrToInt64(AValue, IntegerValue) or
      (IntegerValue < 0) or (IntegerValue > 100000) then
      Exit;
    OrdinalValue := IntegerValue;
    SetOrdProp(AComponent, PropertyInfo, OrdinalValue);
    Exit(True);
  end;
  if PropertyInfo.PropType^.Kind = tkEnumeration then
  begin
    if SameText(AValue, 'True') then
      OrdinalValue := 1
    else if SameText(AValue, 'False') then
      OrdinalValue := 0
    else
      Exit;
    SetOrdProp(AComponent, PropertyInfo, OrdinalValue);
    Exit(True);
  end;
end;

function JavaScriptString(const AValue: string): string;
var
  JsonString: TJSONString;
begin
  JsonString := TJSONString.Create(AValue);
  try
    Result := JsonString.ToJSON;
  finally
    JsonString.Free;
  end;
end;

function ApplyBrowserText(const AComponent: TComponent;
  const APack: TRuntimeLanguagePack): Integer;
var
  Candidate: string;
  Pairs: TStringList;
  Script: TStringBuilder;
  TranslatedText: string;
begin
  Result := 0;
  if not (AComponent is TCustomWebBrowser) then
    Exit;
  Pairs := TStringList.Create;
  Script := TStringBuilder.Create;
  try
    for Candidate in APack.SourceStrings.Keys do
    begin
      TranslatedText := APack.SourceStrings[Candidate];
      if (Trim(Candidate) <> '') and (Trim(TranslatedText) <> '') and
        not SameText(Candidate, TranslatedText) then
        Pairs.Add(JavaScriptString(Candidate) + ',' +
          JavaScriptString(TranslatedText));
    end;
    if Pairs.Count = 0 then
      Exit;
    Script.Append('(function(){const p=[');
    for Candidate in Pairs do
    begin
      if Script.Chars[Script.Length - 1] <> '[' then
        Script.Append(',');
      Script.Append('[').Append(Candidate).Append(']');
    end;
    Script.Append('];function a(){if(!document.body)return;const w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let n;while(n=w.nextNode()){let v=n.nodeValue;for(const q of p){if(v.trim()===q[0]){const l=v.match(/^\\s*/)[0],r=v.match(/\\s*$/)[0];v=l+q[1]+r;break;}if(v.indexOf(q[0])>=0&&v.indexOf(q[1])<0)v=v.split(q[0]).join(q[1]);}if(n.nodeValue!==v)n.nodeValue=v;}}a();})();');
    TCustomWebBrowser(AComponent).EvaluateJavaScript(Script.ToString);
    Result := Pairs.Count;
  finally
    Script.Free;
    Pairs.Free;
  end;
end;

function ApplyGridText(const AComponent: TComponent;
  const APack: TRuntimeLanguagePack): Integer;
var
  ColumnIndex: Integer;
  CurrentText: string;
  RowIndex: Integer;
  TranslatedText: string;
begin
  Result := 0;
  if not (AComponent is TStringGrid) then
    Exit;
  for ColumnIndex := 0 to TStringGrid(AComponent).ColumnCount - 1 do
    for RowIndex := 0 to TStringGrid(AComponent).RowCount - 1 do
    begin
      CurrentText := TStringGrid(AComponent).Cells[ColumnIndex, RowIndex];
      if APack.TryTranslateDynamicText(CurrentText, TranslatedText) and
        (TranslatedText <> CurrentText) then
      begin
        TStringGrid(AComponent).Cells[ColumnIndex, RowIndex] := TranslatedText;
        Inc(Result);
      end;
    end;
end;

function EditableTextComponent(const AComponent: TComponent): Boolean;
begin
  Result := ((AComponent is TCustomEdit) and
    not TCustomEdit(AComponent).ReadOnly) or
    ((AComponent is TCustomMemo) and
    not TCustomMemo(AComponent).ReadOnly);
end;

function ComponentKey(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName: string): string;
begin
  if AComponent = AForm then
    Result := AFormIdentity + '.' + APropertyName
  else
    Result := AFormIdentity + '.' + AComponent.Name + '.' + APropertyName;
end;

function ApplyTextProperty(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName: string; const APack: TRuntimeLanguagePack;
  const APreserveControlState: Boolean): Boolean;
var
  PropertyInfo: PPropInfo;
  CurrentText: string;
  Key: string;
  SourceText: string;
  TranslatedText: string;
begin
  Result := False;
  if APreserveControlState and SameText(APropertyName, 'Text') and
    EditableTextComponent(AComponent) then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if PropertyInfo = nil then
    Exit;
  CurrentText := GetStrProp(AComponent, PropertyInfo);
  Key := ComponentKey(AFormIdentity, AForm, AComponent, APropertyName);
  if APack.TryGetText(Key, TranslatedText) then
  begin
    if APack.TryGetSource(Key, SourceText) and
      not SameText(CurrentText, SourceText) and
      not ContainsStr(CurrentText, TranslatedText) and
      ContainsStr(CurrentText, SourceText) then
      TranslatedText := StringReplace(CurrentText, SourceText,
        TranslatedText, [rfReplaceAll]);
    if TranslatedText = CurrentText then
      Exit;
    SetStrProp(AComponent, PropertyInfo, TranslatedText);
    Result := True;
  end;
  if Result then
    Exit;
  if APack.TryTranslateDynamicText(CurrentText, TranslatedText) and
    (TranslatedText <> CurrentText) then
  begin
    SetStrProp(AComponent, PropertyInfo, TranslatedText);
    Result := True;
  end;
end;

function ApplyStringCollection(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APropertyName, AKeyPropertyName: string;
  const APack: TRuntimeLanguagePack;
  const APreserveControlState: Boolean): Integer;
var
  ChangeEventInfo: PPropInfo;
  EmptyChangeEvent: TMethod;
  ItemIndexInfo: PPropInfo;
  SavedChangeEvent: TMethod;
  SavedItemIndex: NativeInt;
  PropertyInfo: PPropInfo;
  StringObject: TObject;
begin
  Result := 0;
  if APreserveControlState and SameText(APropertyName, 'Lines') and
    EditableTextComponent(AComponent) then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName, [tkClass]);
  if PropertyInfo = nil then
    Exit;
  StringObject := GetObjectProp(AComponent, PropertyInfo);
  if StringObject is TStrings then
  begin
    ItemIndexInfo := GetPropInfo(AComponent.ClassInfo, 'ItemIndex',
      [tkInteger, tkInt64]);
    if APreserveControlState and (ItemIndexInfo <> nil) then
      SavedItemIndex := GetOrdProp(AComponent, ItemIndexInfo)
    else
      SavedItemIndex := -1;

    ChangeEventInfo := GetPropInfo(AComponent.ClassInfo, 'OnChange', [tkMethod]);
    if ChangeEventInfo <> nil then
    begin
      SavedChangeEvent := GetMethodProp(AComponent, ChangeEventInfo);
      EmptyChangeEvent.Code := nil;
      EmptyChangeEvent.Data := nil;
      SetMethodProp(AComponent, ChangeEventInfo, EmptyChangeEvent);
    end;
    try
      Result := APack.ReadIndexedStrings(
        ComponentKey(AFormIdentity, AForm, AComponent, AKeyPropertyName),
        TStrings(StringObject));
      if APreserveControlState and (Result > 0) and
        (ItemIndexInfo <> nil) and
        (SavedItemIndex >= -1) and
        (SavedItemIndex < TStrings(StringObject).Count) then
        SetOrdProp(AComponent, ItemIndexInfo, SavedItemIndex);
    finally
      if ChangeEventInfo <> nil then
        SetMethodProp(AComponent, ChangeEventInfo, SavedChangeEvent);
    end;
  end;
end;

class function TFMXTranslationApplicator.ApplyToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack): Integer;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('An FMX form is required.');
  Result := ApplyToForm(AForm, APack, AForm.Name, True);
end;

class function TFMXTranslationApplicator.ApplyToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const APreserveControlState, AApplyLayout: Boolean): Integer;
const
  TextProperties: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'TextPrompt', 'Header');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  ComponentIndex: Integer;
  FormIdentity: string;
  PropertyName: string;
  SavedFocusedControl: IControl;
  VisitedComponents: TDictionary<TComponent, Boolean>;

  procedure ApplyComponentTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    LocalPropertyName: string;
    LocalSavedSelLength: Integer;
    LocalSavedSelStart: Integer;
  begin
    if (AComponent = nil) or VisitedComponents.ContainsKey(AComponent) then
      Exit;
    VisitedComponents.Add(AComponent, True);
    LocalSavedSelStart := -1;
    LocalSavedSelLength := -1;
    if APreserveControlState and (AComponent is TCustomEdit) then
    begin
      LocalSavedSelStart := TCustomEdit(AComponent).SelStart;
      LocalSavedSelLength := TCustomEdit(AComponent).SelLength;
    end
    else if APreserveControlState and (AComponent is TCustomMemo) then
    begin
      LocalSavedSelStart := TCustomMemo(AComponent).SelStart;
      LocalSavedSelLength := TCustomMemo(AComponent).SelLength;
    end;
    try
      for LocalPropertyName in TextProperties do
        if ApplyTextProperty(FormIdentity, AForm, AComponent,
          LocalPropertyName, APack, APreserveControlState) then
          Inc(Result);
      for LocalPropertyName in StringProperties do
        Inc(Result, ApplyStringCollection(FormIdentity, AForm, AComponent,
          LocalPropertyName, LocalPropertyName + '.Strings', APack,
          APreserveControlState));
      Inc(Result, ApplyGridText(AComponent, APack));
      Inc(Result, ApplyBrowserText(AComponent, APack));
      for ChildIndex := 0 to AComponent.ComponentCount - 1 do
        ApplyComponentTree(AComponent.Components[ChildIndex]);
    finally
      if LocalSavedSelStart >= 0 then
        if AComponent is TCustomEdit then
        begin
          TCustomEdit(AComponent).SelStart := LocalSavedSelStart;
          TCustomEdit(AComponent).SelLength := LocalSavedSelLength;
        end
        else if AComponent is TCustomMemo then
        begin
          TCustomMemo(AComponent).SelStart := LocalSavedSelStart;
          TCustomMemo(AComponent).SelLength := LocalSavedSelLength;
        end;
    end;
  end;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('An FMX form is required.');
  if APack = nil then
    Exit(0);
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  if APreserveControlState then
    SavedFocusedControl := AForm.Focused;

  Result := 0;
  VisitedComponents := TDictionary<TComponent, Boolean>.Create;
  try
    for PropertyName in TextProperties do
      if ApplyTextProperty(FormIdentity, AForm, AForm, PropertyName,
        APack, APreserveControlState) then
        Inc(Result);
    for ComponentIndex := 0 to AForm.ComponentCount - 1 do
      ApplyComponentTree(AForm.Components[ComponentIndex]);
    if AApplyLayout then
      Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, True));
    Inc(Result, ApplyFontColorsToForm(AForm, APack, FormIdentity));
  finally
    VisitedComponents.Free;
    if APreserveControlState and (SavedFocusedControl <> nil) then
      AForm.Focused := SavedFocusedControl;
  end;
end;

class function TFMXTranslationApplicator.ApplyLayoutToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const AUseTranslatedValues: Boolean): Integer;
var
  Component: TComponent;
  Rule: TRuntimeLayoutRule;
  Value: string;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    if SameText(Rule.ComponentName, AFormIdentity) or
      SameText(Rule.ComponentName, AForm.Name) or
      (Trim(Rule.ComponentName) = '') then
      Component := AForm
    else
      Component := AForm.FindComponent(Rule.ComponentName);
    if Component = nil then
      Continue;
    if AUseTranslatedValues then
      Value := Rule.TranslatedValue
    else
      Value := Rule.OriginalValue;
    if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

end.
