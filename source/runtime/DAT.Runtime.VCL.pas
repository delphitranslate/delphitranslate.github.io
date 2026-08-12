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
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Vcl.Controls,
  Vcl.StdCtrls;

function TrySetLayoutProperty(const AComponent: TComponent;
  const APropertyName, AValue: string): Boolean;
var
  IntegerValue: Int64;
  OrdinalValue: NativeInt;
  PropertyInfo: PPropInfo;
begin
  Result := False;
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

class function TVCLTranslationApplicator.ApplyToForm(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack): Integer;
begin
  if AForm = nil then
    raise EArgumentNilException.Create('A VCL form is required.');
  Result := ApplyToForm(AForm, APack, AForm.Name, True);
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
