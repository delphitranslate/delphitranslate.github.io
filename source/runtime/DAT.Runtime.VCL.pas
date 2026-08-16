unit DAT.Runtime.VCL;

interface

uses
  System.Classes,
  Vcl.Forms,
  DAT.Runtime.LanguagePack;

type
  TVCLTranslationApplicator = class
  public
    class function ApplyToForm(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack): Integer; overload; static;
    class function ApplyToForm(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const APreserveControlState: Boolean = True): Integer; overload; static;
    class function ApplyLayoutToForm(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const AUseTranslatedValues: Boolean): Integer; static;
    class function RestoreSourceLanguage(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls;

function TrySetLayoutProperty(const AComponent: TComponent;
  const APropertyName, AValue: string): Boolean;
var
  FloatValue: Extended;
  FontObject: TObject;
  IntegerValue: Int64;
  OrdinalValue: NativeInt;
  PropertyInfo: PPropInfo;
begin
  Result := False;
  if (AComponent is TControl) and
    (SameText(APropertyName, 'Left') or SameText(APropertyName, 'Top')) then
  begin
    if not TryStrToInt64(AValue, IntegerValue) or
      (IntegerValue < -100000) or (IntegerValue > 100000) then
      Exit;
    if SameText(APropertyName, 'Left') then
      TControl(AComponent).Left := IntegerValue
    else
      TControl(AComponent).Top := IntegerValue;
    Exit(True);
  end;
  { VCL keeps the point size on the control's TFont rather than in a property
    of its own, so a FontSize rule has to be routed there. Looking it up by
    name finds nothing, and the reduction would be skipped in silence, leaving
    the caption at its designed size and overflowing exactly as before. }
  if SameText(APropertyName, 'FontSize') then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue <= 0) or (FloatValue > 400) then
      Exit;
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Font');
    if PropertyInfo = nil then
      Exit;
    FontObject := GetObjectProp(AComponent, PropertyInfo);
    if not (FontObject is TFont) then
      Exit;
    TFont(FontObject).Size := Round(FloatValue);
    Exit(True);
  end;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName);
  if PropertyInfo = nil then
    Exit;
  if PropertyInfo.PropType^.Kind in [tkInteger, tkInt64] then
  begin
    if not TryStrToInt64(AValue, IntegerValue) or
      (IntegerValue < 0) or (IntegerValue > 100000) then
      Exit;
    SetOrdProp(AComponent, PropertyInfo, IntegerValue);
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

function EditableLinesComponent(const AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TCustomMemo) and
    not TCustomMemo(AComponent).ReadOnly;
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
  const APropertyName: string; const APack: TRuntimeLanguagePack): Boolean;
var
  PropertyInfo: PPropInfo;
  TranslatedText: string;
begin
  Result := False;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkString, tkLString, tkWString, tkUString]);
  if (PropertyInfo <> nil) and APack.TryGetText(
    ComponentKey(AFormIdentity, AForm, AComponent, APropertyName),
    TranslatedText) then
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
    EditableLinesComponent(AComponent) then
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
  if (PropertyInfo = nil) or not APack.TryGetSource(
    ComponentKey(AFormIdentity, AForm, AComponent, APropertyName), SourceText) then
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

class function TVCLTranslationApplicator.ApplyToForm(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack): Integer;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('A VCL form is required.');
  Result := ApplyToForm(AForm, APack, AForm.Name, True);
end;

class function TVCLTranslationApplicator.RestoreSourceLanguage(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
const
  TextProperties: array[0..2] of string = ('Caption', 'Hint', 'TextHint');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  ComponentIndex: Integer;
  FormIdentity: string;
  PropertyName: string;

  procedure RestoreComponentTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    LocalPropertyName: string;
  begin
    if AComponent = nil then
      Exit;
    for LocalPropertyName in TextProperties do
      if RestoreSourceTextProperty(FormIdentity, AForm, AComponent,
        LocalPropertyName, APack) then
        Inc(Result);
    for LocalPropertyName in StringProperties do
      Inc(Result, RestoreSourceStringCollection(FormIdentity, AForm,
        AComponent, LocalPropertyName, LocalPropertyName + '.Strings', APack));
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
  for PropertyName in TextProperties do
    if RestoreSourceTextProperty(FormIdentity, AForm, AForm, PropertyName,
      APack) then
      Inc(Result);
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreComponentTree(AForm.Components[ComponentIndex]);
  Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, False));
end;

class function TVCLTranslationApplicator.ApplyToForm(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const APreserveControlState: Boolean): Integer;
const
  TextProperties: array[0..2] of string = ('Caption', 'Hint', 'TextHint');
  StringProperties: array[0..1] of string = ('Items', 'Lines');
var
  Component: TComponent;
  ComponentIndex: Integer;
  FormIdentity: string;
  PropertyName: string;
  SavedFocusedControl: TWinControl;
  SavedFocusedState: Boolean;
  SavedSelLength: Integer;
  SavedSelStart: Integer;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('A VCL form is required.');
  if APack = nil then
    Exit(0);
  FormIdentity := Trim(AFormIdentity);
  if FormIdentity = '' then
    FormIdentity := AForm.Name;
  SavedFocusedControl := nil;
  SavedFocusedState := False;
  if APreserveControlState then
  begin
    SavedFocusedControl := AForm.ActiveControl;
    SavedFocusedState := (SavedFocusedControl <> nil) and
      SavedFocusedControl.Focused;
  end;

  Result := 0;
  try
    for PropertyName in TextProperties do
      if ApplyTextProperty(FormIdentity, AForm, AForm, PropertyName,
        APack) then
        Inc(Result);
    for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Component := AForm.Components[ComponentIndex];
      if Component.Name = '' then
        Continue;
      SavedSelStart := -1;
      SavedSelLength := -1;
      if APreserveControlState and (Component is TCustomEdit) then
      begin
        SavedSelStart := TCustomEdit(Component).SelStart;
        SavedSelLength := TCustomEdit(Component).SelLength;
      end;
      try
        for PropertyName in TextProperties do
          if ApplyTextProperty(FormIdentity, AForm, Component, PropertyName,
            APack) then
            Inc(Result);
        for PropertyName in StringProperties do
          Inc(Result, ApplyStringCollection(
            FormIdentity, AForm, Component, PropertyName,
            PropertyName + '.Strings', APack, APreserveControlState));
      finally
        if SavedSelStart >= 0 then
        begin
          TCustomEdit(Component).SelStart := SavedSelStart;
          TCustomEdit(Component).SelLength := SavedSelLength;
        end;
      end;
    end;
    Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, True));
  finally
    if APreserveControlState and SavedFocusedState and
      (SavedFocusedControl <> nil) and SavedFocusedControl.CanFocus then
      SavedFocusedControl.SetFocus;
  end;
end;

class function TVCLTranslationApplicator.ApplyLayoutToForm(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const AUseTranslatedValues: Boolean): Integer;
const
  { Order matters here for the same reason it does under FireMonkey. An
    auto-sizing label recomputes its own bounds from one line of text and
    discards an assigned Width, so AutoSize has to be cleared first. The font
    size follows, so the width and height that come after are measured against
    the size the text will really be, and positions are applied last, once
    every control has its final size. }
  OrderedLayoutProperties: array[0..6] of string = (
    'AutoSize', 'FontSize', 'WordWrap', 'Width', 'Height', 'Left', 'Top');
var
  CandidateRule: TRuntimeLayoutRule;
  Component: TComponent;
  CurrentNumber: Extended;
  OrderedProperty: string;
  Rule: TRuntimeLayoutRule;
  CandidateNumber: Extended;
  Superseded: Boolean;
  Value: string;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for OrderedProperty in OrderedLayoutProperties do
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    if not SameText(Rule.PropertyName, OrderedProperty) then
      Continue;
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

end.
