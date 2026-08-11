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
      const APreserveControlState: Boolean = True): Integer; overload; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.StrUtils,
  System.TypInfo,
  FMX.Controls,
  FMX.Edit,
  FMX.Memo,
  FMX.Types;

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
  DynamicText: string;
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
      ContainsStr(CurrentText, SourceText) then
      TranslatedText := StringReplace(CurrentText, SourceText,
        TranslatedText, [rfReplaceAll]);
    if APack.TryTranslateDynamicText(TranslatedText, DynamicText) then
      TranslatedText := DynamicText;
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
  const APreserveControlState: Boolean): Integer;
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
  finally
    VisitedComponents.Free;
    if APreserveControlState and (SavedFocusedControl <> nil) then
      AForm.Focused := SavedFocusedControl;
  end;
end;

end.
