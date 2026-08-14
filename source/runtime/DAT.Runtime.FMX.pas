unit DAT.Runtime.FMX;

interface

uses
  System.Generics.Collections,
  System.Types,
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  TFMXOriginalLayout = record
    Bounds: TRectF;
  end;

  TFMXTranslationApplicator = class
  private
    class var FOriginalLayouts: TDictionary<string, TFMXOriginalLayout>;
    class procedure SnapshotOriginalLayout(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    class procedure RestoreOriginalLayout(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
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
    class function RestoreSourceLanguage(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.JSON,
  System.Math,
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

function PositionKey(const AFormIdentity: string;
  const AComponent: TComponent): string;
begin
  if (AComponent = nil) or (Trim(AComponent.Name) = '') then
    Exit('');
  Result := AFormIdentity + '.' + AComponent.Name;
end;

function ControlBounds(const AControl: TControl): TRectF;
begin
  Result := TRectF.Create(AControl.Position.X, AControl.Position.Y,
    AControl.Position.X + AControl.Width,
    AControl.Position.Y + AControl.Height);
end;

procedure SetControlBounds(const AControl: TControl; const ABounds: TRectF);
begin
  AControl.Position.X := ABounds.Left;
  AControl.Position.Y := ABounds.Top;
  AControl.Width := Max(1, ABounds.Width);
  AControl.Height := Max(1, ABounds.Height);
end;

function ParentClientWidth(const AParent: TFmxObject): Single;
begin
  Result := 0;
  if AParent is TControl then
    Result := TControl(AParent).Width
  else if AParent is TCommonCustomForm then
    Result := TCommonCustomForm(AParent).ClientWidth;
end;

function ParentClientHeight(const AParent: TFmxObject): Single;
begin
  Result := 0;
  if AParent is TControl then
    Result := TControl(AParent).Height
  else if AParent is TCommonCustomForm then
    Result := TCommonCustomForm(AParent).ClientHeight;
end;

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
    for Candidate in APack.SourceTemplates.Keys do
    begin
      TranslatedText := APack.SourceTemplates[Candidate];
      { Format strings belong to code, not browser text nodes. }
      if (Pos('%', Candidate) = 0) and (Pos('%', TranslatedText) = 0) and
        (Trim(Candidate) <> '') and (Trim(TranslatedText) <> '') and
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
    try
      TCustomWebBrowser(AComponent).EvaluateJavaScript(Script.ToString);
      Result := Pairs.Count;
    except
      { A browser may still be loading when a newly-created dynamic dialog is
        first shown. Translation must never turn that platform race into a
        repeated application error dialog; the next explicit language pass
        can retry once the document is ready. }
      Result := 0;
    end;
  finally
    Script.Free;
    Pairs.Free;
  end;
end;

function ApplyGridText(const AFormIdentity: string;
  const AComponent: TComponent; const APack: TRuntimeLanguagePack): Integer;
var
  ColumnIndex: Integer;
  CurrentText: string;
  GridKey: string;
  StringDictionary: TDictionary<string, string>;
  StringPairs: TArray<TPair<string, string>>;
  RowIndex: Integer;
  TranslatedText: string;

  function BuiltInHeaderFallback(const AText: string): string;
  begin
    Result := AText;
    if not StartsText('es', APack.LanguageCode) then
      Exit;
    { These are framework-neutral UI header words that frequently come from
      run-time grid column setup instead of a persisted FMX column object.
      They are deliberately exact matches only. }
    if SameText(AText, 'Time') then
      Result := 'Hora'
    else if SameText(AText, 'Type') then
      Result := 'Tipo'
    else if SameText(AText, 'Song/Purpose') then
      Result := 'Canción/Propósito'
    else if SameText(AText, 'Group') then
      Result := 'Grupo'
    else if SameText(AText, 'Play Date From') then
      Result := 'Fecha inicial'
    else if SameText(AText, 'Play Date To') then
      Result := 'Fecha final'
    else if SameText(AText, 'Play Time') then
      Result := 'Hora de reproducción'
    else if SameText(AText, 'Play Time(s)') then
      Result := 'Hora(s) de reproducción'
    else if SameText(AText, 'Date/Time') then
      Result := 'Fecha/hora'
    else if SameText(AText, 'Event') then
      Result := 'Evento';
  end;

  procedure TryGetHeaderTranslation(const AIndex: Integer;
    const ACurrentText: string; out AText: string);
  var
    Prefix: string;
    PairIndex: Integer;
  begin
    AText := ACurrentText;
    Prefix := Format('%s.%s.Columns[%d].Header.', [AFormIdentity,
      AComponent.Name, AIndex]);
    for PairIndex := 0 to Length(StringPairs) - 1 do
      if StartsText(Prefix, StringPairs[PairIndex].Key) then
      begin
        AText := StringPairs[PairIndex].Value;
        Exit;
      end;
    Prefix := Format('%s.%s.Columns.Header.%d.', [AFormIdentity,
      AComponent.Name, AIndex]);
    for PairIndex := 0 to Length(StringPairs) - 1 do
      if StartsText(Prefix, StringPairs[PairIndex].Key) then
      begin
        AText := StringPairs[PairIndex].Value;
        Exit;
      end;
    APack.TryTranslateDynamicText(ACurrentText, AText);
  end;
begin
  Result := 0;
  if not (AComponent is TStringGrid) then
    Exit;
  StringDictionary := APack.Strings;
  StringPairs := StringDictionary.ToArray;
  for ColumnIndex := 0 to TStringGrid(AComponent).ColumnCount - 1 do
  begin
    CurrentText := TStringGrid(AComponent).Columns[ColumnIndex].Header;
    TranslatedText := CurrentText;
    GridKey := Format('%s.%s.Columns.Header.%d', [AFormIdentity,
      AComponent.Name, ColumnIndex]);
    if not APack.TryGetText(GridKey, TranslatedText) then
      GridKey := Format('%s.%s.Columns[%d].Header', [AFormIdentity,
        AComponent.Name, ColumnIndex]);
    if not APack.TryGetText(GridKey, TranslatedText) then
      TryGetHeaderTranslation(ColumnIndex, CurrentText, TranslatedText);
    if (TranslatedText = CurrentText) and
       APack.TryTranslateSource(CurrentText, TranslatedText) then
      { Header columns are not always owned as ordinary TComponent children;
        the source-text fallback keeps their exact catalog translation. }
      ;
    if TranslatedText = CurrentText then
      TranslatedText := BuiltInHeaderFallback(CurrentText);
    if (TranslatedText <> '') and (TranslatedText <> CurrentText) then
    begin
      TStringGrid(AComponent).Columns[ColumnIndex].Header := TranslatedText;
      Inc(Result);
    end;
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
end;

procedure ApplyAdaptiveTextLayout(const AParent: TFmxObject);
var
  ChildIndex: Integer;
  ChildObject: TFmxObject;
  Child: TControl;
  TextControl: TTextControl;
  WordWrapInfo: PPropInfo;
  AutoSizeInfo: PPropInfo;
  TextValue: string;
  FontSize: Single;
  RequiredWidth: Single;
  RequiredLines: Integer;
  RequiredHeight: Single;
  AvailableWidth: Single;
  ParentWidth: Single;
  ParentHeight: Single;
  Pass: Integer;
  I: Integer;
  J: Integer;
  FirstControl: TControl;
  SecondControl: TControl;
  FirstBounds: TRectF;
  SecondBounds: TRectF;
  Gap: Single;
  MoveRight: Single;
  MoveDown: Single;

  function LayoutCandidate(const AObject: TFmxObject): Boolean;
  begin
    Result := (AObject is TControl) and TControl(AObject).Visible and
      (TControl(AObject).Align = TAlignLayout.None) and
      (TControl(AObject).Width > 0) and (TControl(AObject).Height > 0);
  end;

  function ControlsOverlap(const A, B: TRectF): Boolean;
  begin
    Result := (A.Left < B.Right) and (A.Right > B.Left) and
      (A.Top < B.Bottom) and (A.Bottom > B.Top);
  end;

  procedure KeepInsideParent(const AControl: TControl);
  var
    Bounds: TRectF;
  begin
    if (ParentWidth <= 0) and (ParentHeight <= 0) then
      Exit;
    Bounds := ControlBounds(AControl);
    if (ParentWidth > 0) and (Bounds.Right > ParentWidth - Gap) then
      Bounds.Offset(ParentWidth - Gap - Bounds.Right, 0);
    if Bounds.Left < Gap then
      Bounds.Offset(Gap - Bounds.Left, 0);
    if (ParentHeight > 0) and (Bounds.Bottom > ParentHeight - Gap) then
      Bounds.Offset(0, ParentHeight - Gap - Bounds.Bottom);
    if Bounds.Top < Gap then
      Bounds.Offset(0, Gap - Bounds.Top);
    SetControlBounds(AControl, Bounds);
  end;

begin
  if AParent = nil then
    Exit;
  Gap := 8;
  ParentWidth := ParentClientWidth(AParent);
  ParentHeight := ParentClientHeight(AParent);

  for ChildIndex := 0 to AParent.ChildrenCount - 1 do
  begin
    ChildObject := AParent.Children[ChildIndex];
    if ChildObject = nil then
      Continue;
    ApplyAdaptiveTextLayout(ChildObject);
    if not (ChildObject is TTextControl) or not LayoutCandidate(ChildObject) then
      Continue;
    TextControl := TTextControl(ChildObject);
    Child := TControl(ChildObject);
    TextValue := Trim(TextControl.Text);
    if TextValue = '' then
      Continue;
    WordWrapInfo := GetPropInfo(Child.ClassInfo, 'WordWrap', [tkEnumeration]);
    AutoSizeInfo := GetPropInfo(Child.ClassInfo, 'AutoSize', [tkEnumeration]);
    FontSize := TextControl.TextSettings.Font.Size;
    if FontSize < 9 then
      FontSize := 12;
    RequiredWidth := Length(TextValue) * FontSize * 0.58 + 18;
    AvailableWidth := Child.Width;
    if ParentWidth > 0 then
      AvailableWidth := Max(Child.Width, ParentWidth - Child.Position.X - Gap);
    if RequiredWidth > Child.Width * 1.03 then
    begin
      if AutoSizeInfo <> nil then
        SetOrdProp(Child, AutoSizeInfo, 0);
      if (ParentWidth > 0) and (RequiredWidth <= AvailableWidth) then
        Child.Width := Min(RequiredWidth, AvailableWidth)
      else if WordWrapInfo <> nil then
      begin
        SetOrdProp(Child, WordWrapInfo, 1);
        RequiredLines := Max(2, Ceil(RequiredWidth / Max(Child.Width, 24)));
        RequiredHeight := FontSize * 1.7 * RequiredLines + 8;
        if RequiredHeight > Child.Height then
          Child.Height := RequiredHeight;
      end;
    end;
    KeepInsideParent(Child);
  end;

  { Now resolve sibling collisions caused by the expansions above.  Prefer
    moving a right-side neighbor right, or a lower neighbor down.  This matches
    how a developer would manually clear a label/edit/check box collision. }
  for Pass := 1 to 8 do
    for I := 0 to AParent.ChildrenCount - 1 do
    begin
      if not LayoutCandidate(AParent.Children[I]) then
        Continue;
      FirstControl := TControl(AParent.Children[I]);
      FirstBounds := ControlBounds(FirstControl);
      for J := 0 to AParent.ChildrenCount - 1 do
      begin
        if I = J then
          Continue;
        if not LayoutCandidate(AParent.Children[J]) then
          Continue;
        SecondControl := TControl(AParent.Children[J]);
        SecondBounds := ControlBounds(SecondControl);
        if not ControlsOverlap(FirstBounds, SecondBounds) then
          Continue;
        if (SecondBounds.Left >= FirstBounds.Left) and
          (Abs(SecondBounds.Top - FirstBounds.Top) <=
            Max(FirstBounds.Height, SecondBounds.Height)) then
        begin
          MoveRight := FirstBounds.Right + Gap - SecondBounds.Left;
          if (MoveRight > 0) and
            ((ParentWidth <= 0) or
             (SecondBounds.Right + MoveRight <= ParentWidth - Gap)) then
          begin
            SecondControl.Position.X := SecondControl.Position.X + MoveRight;
            KeepInsideParent(SecondControl);
            Continue;
          end;
        end;
        if SecondBounds.Top >= FirstBounds.Top then
        begin
          MoveDown := FirstBounds.Bottom + Gap - SecondBounds.Top;
          if (MoveDown > 0) and
            ((ParentHeight <= 0) or
             (SecondBounds.Bottom + MoveDown <= ParentHeight - Gap)) then
          begin
            SecondControl.Position.Y := SecondControl.Position.Y + MoveDown;
            KeepInsideParent(SecondControl);
          end;
        end;
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

function RestoreSourceTextProperty(const AFormIdentity: string;
  const AForm, AComponent: TComponent; const APropertyName: string;
  const APack: TRuntimeLanguagePack): Boolean;
var
  PropertyInfo: PPropInfo;
  SourceText: string;
begin
  Result := False;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if (PropertyInfo = nil) or
    not APack.TryGetSource(ComponentKey(AFormIdentity, AForm, AComponent,
      APropertyName), SourceText) then
    Exit;
  if GetStrProp(AComponent, PropertyInfo) = SourceText then
    Exit;
  SetStrProp(AComponent, PropertyInfo, SourceText);
  Result := True;
end;

function RestoreSourceStringCollection(const AFormIdentity: string;
  const AForm, AComponent: TComponent; const APropertyName,
  AKeyPropertyName: string; const APack: TRuntimeLanguagePack): Integer;
var
  Index: Integer;
  Key: string;
  Prefix: string;
  PropertyInfo: PPropInfo;
  StringObject: TObject;
  SourceText: string;
begin
  Result := 0;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName, [tkClass]);
  if PropertyInfo = nil then
    Exit;
  StringObject := GetObjectProp(AComponent, PropertyInfo);
  if not (StringObject is TStrings) then
    Exit;
  Prefix := ComponentKey(AFormIdentity, AForm, AComponent,
    AKeyPropertyName) + '.';
  for Index := 0 to TStrings(StringObject).Count - 1 do
  begin
    Key := Prefix + Index.ToString;
    if APack.TryGetSource(Key, SourceText) and
      (TStrings(StringObject)[Index] <> SourceText) then
    begin
      TStrings(StringObject)[Index] := SourceText;
      Inc(Result);
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

class procedure TFMXTranslationApplicator.SnapshotOriginalLayout(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;
  Component: TComponent;
  Key: string;
  Layout: TFMXOriginalLayout;

  procedure SnapshotTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Child: TComponent;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    if (Key <> '') and (AComponent is TControl) and
      (TControl(AComponent).Align = TAlignLayout.None) and
      not FOriginalLayouts.ContainsKey(Key) then
    begin
      Layout.Bounds := ControlBounds(TControl(AComponent));
      FOriginalLayouts.Add(Key, Layout);
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
    begin
      Child := AComponent.Components[ChildIndex];
      SnapshotTree(Child);
    end;
  end;
begin
  if (AForm = nil) or (FOriginalLayouts = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
  begin
    Component := AForm.Components[ComponentIndex];
    SnapshotTree(Component);
  end;
end;

class procedure TFMXTranslationApplicator.RestoreOriginalLayout(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;
  Component: TComponent;
  Key: string;
  OriginalLayout: TFMXOriginalLayout;

  procedure RestoreTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Child: TComponent;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    if (Key <> '') and (AComponent is TControl) and
      FOriginalLayouts.TryGetValue(Key, OriginalLayout) then
      SetControlBounds(TControl(AComponent), OriginalLayout.Bounds);
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
    begin
      Child := AComponent.Components[ChildIndex];
      RestoreTree(Child);
    end;
  end;
begin
  if (AForm = nil) or (FOriginalLayouts = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
  begin
    Component := AForm.Components[ComponentIndex];
    RestoreTree(Component);
  end;
end;

class function TFMXTranslationApplicator.RestoreSourceLanguage(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
const
  TextProperties: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'TextPrompt', 'Header');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  ComponentIndex: Integer;
  FormIdentity: string;
  PropertyName: string;

  procedure RestoreComponentTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    ColumnIndex: Integer;
    RowIndex: Integer;
    CurrentText: string;
    SourceText: string;
    PropertyName: string;
  begin
    if AComponent = nil then
      Exit;
    for PropertyName in TextProperties do
      if RestoreSourceTextProperty(FormIdentity, AForm, AComponent,
        PropertyName, APack) then
        Inc(Result);
    for PropertyName in StringProperties do
      Inc(Result, RestoreSourceStringCollection(FormIdentity, AForm,
        AComponent, PropertyName, PropertyName + '.Strings', APack));
    if AComponent is TStringGrid then
    begin
      for ColumnIndex := 0 to TStringGrid(AComponent).ColumnCount - 1 do
      begin
        CurrentText := TStringGrid(AComponent).Columns[ColumnIndex].Header;
        if APack.TryRestoreDynamicText(CurrentText, SourceText) then
        begin
          TStringGrid(AComponent).Columns[ColumnIndex].Header := SourceText;
          Inc(Result);
        end;
        for RowIndex := 0 to TStringGrid(AComponent).RowCount - 1 do
        begin
          CurrentText := TStringGrid(AComponent).Cells[ColumnIndex, RowIndex];
          if APack.TryRestoreDynamicText(CurrentText, SourceText) then
          begin
            TStringGrid(AComponent).Cells[ColumnIndex, RowIndex] := SourceText;
            Inc(Result);
          end;
        end;
      end;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      RestoreComponentTree(AComponent.Components[ChildIndex]);
  end;

begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  RestoreOriginalLayout(AForm, FormIdentity);
  for PropertyName in TextProperties do
    if RestoreSourceTextProperty(FormIdentity, AForm, AForm, PropertyName,
      APack) then
      Inc(Result);
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreComponentTree(AForm.Components[ComponentIndex]);
  Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, False));
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
      Inc(Result, ApplyGridText(FormIdentity, AComponent, APack));
      { Browser-backed HTML is applied during the initial language pass only.
        Re-evaluating JavaScript on every dynamic refresh can race the FMX
        browser and produce repeated platform error 80020101 dialogs. }
      if AApplyLayout then
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
  SnapshotOriginalLayout(AForm, FormIdentity);
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
    if AApplyLayout then
    begin
      { Adaptive sizing and bounded sibling collision repair are runtime-only.
        They make fixed FMX forms usable with longer translated text without
        rewriting the developer's form source. }
      ApplyAdaptiveTextLayout(AForm);
    end;
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
  CandidateRule: TRuntimeLayoutRule;
  Component: TComponent;
  CurrentNumber: Extended;
  Rule: TRuntimeLayoutRule;
  CandidateNumber: Extended;
  Superseded: Boolean;
  Value: string;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    { A catalog can contain more than one proposal for the same property
      when several translated entries share a control. For dimensions, keep
      the largest safe proposal instead of allowing a later smaller proposal
      to undo the required expansion. }
    Superseded := False;
    if (SameText(Rule.PropertyName, 'Width') or
        SameText(Rule.PropertyName, 'Height')) and
       TryStrToFloat(Rule.TranslatedValue, CurrentNumber,
         TFormatSettings.Invariant) then
      for CandidateRule in APack.LayoutRules do
        if SameText(CandidateRule.FormName, Rule.FormName) and
           SameText(CandidateRule.ComponentName, Rule.ComponentName) and
           SameText(CandidateRule.PropertyName, Rule.PropertyName) and
           TryStrToFloat(CandidateRule.TranslatedValue, CandidateNumber,
             TFormatSettings.Invariant) and
           (CandidateNumber > CurrentNumber) then
        begin
          Superseded := True;
          Break;
        end;
    if Superseded then
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

initialization
  TFMXTranslationApplicator.FOriginalLayouts :=
    TDictionary<string, TFMXOriginalLayout>.Create;

finalization
  TFMXTranslationApplicator.FOriginalLayouts.Free;
  TFMXTranslationApplicator.FOriginalLayouts := nil;

end.
