unit DAT.Runtime.VCL;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Vcl.Forms,
  DAT.Runtime.LanguagePack;

type
  { What a control looked like before any translation touched it.

    The same reasoning as on the FireMonkey side. Restoring by re-applying each
    rule's original value reaches only the controls the analyser wrote a rule
    for, and only the properties named in those rules; anything else a
    translation changed has nothing to restore from, so returning to the
    original language gives back the words and leaves the geometry where the
    last language put it.

    This side carries no fitting heuristics, so it is less exposed than the
    other, but the gap is the same gap and it is worth closing in the same way.
    Fields are plain types so that declaring this costs the interface nothing
    beyond the dictionary itself. }
  TDATVCLControlSnapshot = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    HasFont: Boolean;
    FontSize: Integer;
    HasAutoSize: Boolean;
    AutoSize: Boolean;
    HasWordWrap: Boolean;
    WordWrap: Boolean;
  end;

  TVCLTranslationApplicator = class
  private
    class var FOriginalGeometry: TDictionary<string, TDATVCLControlSnapshot>;
    class procedure SnapshotOriginalGeometry(const AForm: TCustomForm;
      const AFormIdentity: string); static;
    class function RestoreOriginalGeometry(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack;
      const AFormIdentity: string): Integer; static;
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
  System.StrUtils,
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

function VCLSnapshotKey(const AFormIdentity: string;
  const AComponent: TComponent): string;
begin
  if (AComponent = nil) or (Trim(AComponent.Name) = '') then
    Exit('');
  Result := AFormIdentity + '.' + AComponent.Name;
end;

{ True when this component publishes the named boolean, with its value. }
function TryReadBoolean(const AComponent: TComponent;
  const APropertyName: string; out AValue: Boolean): Boolean;
var
  PropertyInfo: PPropInfo;
begin
  Result := False;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName);
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  AValue := GetOrdProp(AComponent, PropertyInfo) <> 0;
  Result := True;
end;

procedure WriteBoolean(const AComponent: TComponent;
  const APropertyName: string; const AValue: Boolean);
var
  PropertyInfo: PPropInfo;
begin
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName);
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  SetOrdProp(AComponent, PropertyInfo, Ord(AValue));
end;

function TryGetFont(const AComponent: TComponent; out AFont: TFont): Boolean;
var
  FontObject: TObject;
  PropertyInfo: PPropInfo;
begin
  Result := False;
  AFont := nil;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Font');
  if (PropertyInfo = nil) or (PropertyInfo.PropType^.Kind <> tkClass) then
    Exit;
  FontObject := GetObjectProp(AComponent, PropertyInfo);
  if not (FontObject is TFont) then
    Exit;
  AFont := TFont(FontObject);
  Result := True;
end;

class procedure TVCLTranslationApplicator.SnapshotOriginalGeometry(
  const AForm: TCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;

  procedure SnapshotTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Font: TFont;
    Key: string;
    Snapshot: TDATVCLControlSnapshot;
  begin
    if AComponent = nil then
      Exit;
    Key := VCLSnapshotKey(AFormIdentity, AComponent);
    { Taken once, before the first language is applied, so that a second
      language cannot quietly become the original. }
    if (Key <> '') and (AComponent is TControl) and
      not FOriginalGeometry.ContainsKey(Key) then
    begin
      Control := TControl(AComponent);
      Snapshot := Default(TDATVCLControlSnapshot);
      Snapshot.Left := Control.Left;
      Snapshot.Top := Control.Top;
      Snapshot.Width := Control.Width;
      Snapshot.Height := Control.Height;
      Snapshot.HasFont := TryGetFont(AComponent, Font);
      if Snapshot.HasFont then
        Snapshot.FontSize := Font.Size;
      Snapshot.HasAutoSize := TryReadBoolean(AComponent, 'AutoSize',
        Snapshot.AutoSize);
      Snapshot.HasWordWrap := TryReadBoolean(AComponent, 'WordWrap',
        Snapshot.WordWrap);
      FOriginalGeometry.Add(Key, Snapshot);
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      SnapshotTree(AComponent.Components[ChildIndex]);
  end;
begin
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    SnapshotTree(AForm.Components[ComponentIndex]);
end;

class function TVCLTranslationApplicator.RestoreOriginalGeometry(
  const AForm: TCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string): Integer;
var
  ComponentIndex: Integer;
  Restored: Integer;

  procedure RestoreTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Font: TFont;
    Key: string;
    Snapshot: TDATVCLControlSnapshot;
  begin
    if AComponent = nil then
      Exit;
    Key := VCLSnapshotKey(AFormIdentity, AComponent);
    { Every control, not only the ones the pack names. Setting a longer caption
      on a label that sizes itself changes its width with no rule involved at
      all, so restricting this to governed controls left exactly those
      stretched - which the VCL runtime test says plainly, and it is right. }
    if (Key <> '') and (AComponent is TControl) and
      FOriginalGeometry.TryGetValue(Key, Snapshot) then
    begin
      Control := TControl(AComponent);
      { Automatic sizing off first and back on last, or a width will not stick,
        and the text settings before the bounds, because both are read when the
        control lays its text out. }
      if Snapshot.HasAutoSize then
        WriteBoolean(AComponent, 'AutoSize', False);
      { Size only. Colour is never something this applicator sets, so putting
        one back can only undo what the application itself did: Carillon paints
        its own colours from a Colors menu after the form is up, and restoring
        the design-time colour stamped a maroon heading over a white one and
        turned captions black. What we never changed, we never restore. }
      if Snapshot.HasFont and TryGetFont(AComponent, Font) then
      begin
        Font.Size := Snapshot.FontSize;
        Inc(Restored);
      end;
      if Snapshot.HasWordWrap then
        WriteBoolean(AComponent, 'WordWrap', Snapshot.WordWrap);
      if (Control.Left <> Snapshot.Left) or (Control.Top <> Snapshot.Top) or
        (Control.Width <> Snapshot.Width) or
        (Control.Height <> Snapshot.Height) then
      begin
        Control.SetBounds(Snapshot.Left, Snapshot.Top, Snapshot.Width,
          Snapshot.Height);
        Inc(Restored);
      end;
      if Snapshot.HasAutoSize then
        WriteBoolean(AComponent, 'AutoSize', Snapshot.AutoSize);
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
      RestoreTree(AComponent.Components[ChildIndex]);
  end;
begin
  Result := 0;
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  Restored := 0;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreTree(AForm.Components[ComponentIndex]);
  Result := Restored;
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
  { Last, and after the text. The snapshot holds the form as it was before any
    translation touched it, so it settles anything the rules restored only
    approximately - for the controls those rules govern, which are the only
    ones this applicator ever moved. }
  Inc(Result, RestoreOriginalGeometry(AForm, APack, FormIdentity));
end;

{ A property reached through a collection: "Columns[1].Width".

  A grid's columns are not components, so nothing can be found by name and the
  ordinary property path does not reach them. The analyser plans a column's
  width the way it plans anything else - a German heading is one unbreakable
  word, so widening the column is the only thing that will hold it - and the
  rule names the grid with the path into it. This walks that path.

  Returns False for anything that is not of that shape, so the ordinary
  handling below is left to deal with it. }
function TrySetCollectionProperty(const AComponent: TComponent;
  const APropertyName, AValue: string): Boolean;
var
  Collection: TCollection;
  CollectionName: string;
  CollectionObject: TObject;
  IndexText: string;
  ItemIndex: Integer;
  ItemProperty: string;
  ItemPropertyInfo: PPropInfo;
  OpenAt, CloseAt, DotAt: Integer;
  PropertyInfo: PPropInfo;
  Target: TObject;
  NumberValue: Extended;
begin
  Result := False;
  OpenAt := Pos('[', APropertyName);
  CloseAt := Pos(']', APropertyName);
  if (OpenAt < 2) or (CloseAt < OpenAt + 2) then
    Exit;
  DotAt := CloseAt + 1;
  if (DotAt > Length(APropertyName)) or (APropertyName[DotAt] <> '.') then
    Exit;
  CollectionName := Copy(APropertyName, 1, OpenAt - 1);
  IndexText := Copy(APropertyName, OpenAt + 1, CloseAt - OpenAt - 1);
  ItemProperty := Copy(APropertyName, DotAt + 1, Length(APropertyName));
  if not TryStrToInt(IndexText, ItemIndex) then
    Exit;

  PropertyInfo := GetPropInfo(AComponent.ClassInfo, CollectionName);
  if (PropertyInfo = nil) or (PropertyInfo.PropType^.Kind <> tkClass) then
    Exit;
  CollectionObject := GetObjectProp(AComponent, PropertyInfo);
  if not (CollectionObject is TCollection) then
    Exit;
  Collection := TCollection(CollectionObject);
  if (ItemIndex < 0) or (ItemIndex >= Collection.Count) then
    Exit;
  Target := Collection.Items[ItemIndex];

  { One level further in again, for a heading held on the column's Title. }
  DotAt := Pos('.', ItemProperty);
  if DotAt > 0 then
  begin
    PropertyInfo := GetPropInfo(Target.ClassInfo,
      Copy(ItemProperty, 1, DotAt - 1));
    if (PropertyInfo = nil) or (PropertyInfo.PropType^.Kind <> tkClass) then
      Exit;
    Target := GetObjectProp(Target, PropertyInfo);
    if Target = nil then
      Exit;
    ItemProperty := Copy(ItemProperty, DotAt + 1, Length(ItemProperty));
  end;

  ItemPropertyInfo := GetPropInfo(Target.ClassInfo, ItemProperty);
  if ItemPropertyInfo = nil then
    Exit;
  case ItemPropertyInfo.PropType^.Kind of
    tkInteger, tkInt64:
      begin
        if not TryStrToFloat(AValue, NumberValue,
          TFormatSettings.Invariant) then
          Exit;
        if (NumberValue < 0) or (NumberValue > 100000) then
          Exit;
        SetOrdProp(Target, ItemPropertyInfo, Round(NumberValue));
        Result := True;
      end;
    tkString, tkLString, tkWString, tkUString:
      begin
        SetStrProp(Target, ItemPropertyInfo, AValue);
        Result := True;
      end;
  end;
end;

{ Text that lives in a design-time collection rather than in a property of the
  control itself.

  A list view keeps its column headings this way, a status bar its panels, a
  header control its sections. The scanner has always read them - the pack
  carries "lvSchedule.Columns[0].Caption" - but nothing here could write one
  back, so those headings stayed in the source language on an otherwise
  translated form while the pack sat there holding the answer.

  The collection is found by name and confirmed by type, so a property called
  Items that holds a string list rather than a collection is left to the code
  that already handles string lists. }
function ApplyCollectionText(const AFormIdentity: string;
  const AForm, AComponent: TComponent;
  const APack: TRuntimeLanguagePack): Integer;
const
  CollectionProperties: array[0..3] of string =
    ('Columns', 'Panels', 'Sections', 'Items');
  ItemTextProperties: array[0..1] of string = ('Caption', 'Text');
  { Sub-objects of a collection item that carry text of their own. }
  ItemHolderProperties: array[0..1] of string = ('Title', 'Header');
var
  Collection: TCollection;
  CollectionName: string;
  CollectionObject: TObject;
  Item: TCollectionItem;
  ItemIndex: Integer;
  ItemPropertyInfo: PPropInfo;
  ItemTextName: string;
  ItemHolderName: string;
  HolderObject: TObject;
  HolderPropertyInfo: PPropInfo;
  PropertyInfo: PPropInfo;
  TranslatedText: string;
begin
  Result := 0;
  if (AComponent = nil) or (AComponent.Name = '') then
    Exit;
  for CollectionName in CollectionProperties do
  begin
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, CollectionName);
    if (PropertyInfo = nil) or (PropertyInfo.PropType^.Kind <> tkClass) then
      Continue;
    CollectionObject := GetObjectProp(AComponent, PropertyInfo);
    if not (CollectionObject is TCollection) then
      Continue;
    Collection := TCollection(CollectionObject);
    for ItemIndex := 0 to Collection.Count - 1 do
    begin
      Item := Collection.Items[ItemIndex];
      for ItemTextName in ItemTextProperties do
      begin
        ItemPropertyInfo := GetPropInfo(Item.ClassInfo, ItemTextName,
          [tkString, tkLString, tkWString, tkUString]);
        if ItemPropertyInfo = nil then
          Continue;
        if not APack.TryGetText(ComponentKey(AFormIdentity, AForm, AComponent,
          Format('%s[%d].%s', [CollectionName, ItemIndex, ItemTextName])),
          TranslatedText) then
          Continue;
        SetStrProp(Item, ItemPropertyInfo, TranslatedText);
        Inc(Result);
      end;
      { And one level further in. A grid does not keep its heading on the
        column: it keeps it on the column's Title, so the pack carries
        "Columns[0].Title.Caption" and nothing here reached it. Those headings
        stayed in the source language on a grid whose every row was translated
        around them. }
      for ItemHolderName in ItemHolderProperties do
      begin
        HolderPropertyInfo := GetPropInfo(Item.ClassInfo, ItemHolderName);
        if (HolderPropertyInfo = nil) or
          (HolderPropertyInfo.PropType^.Kind <> tkClass) then
          Continue;
        HolderObject := GetObjectProp(Item, HolderPropertyInfo);
        if not (HolderObject is TPersistent) then
          Continue;
        for ItemTextName in ItemTextProperties do
        begin
          ItemPropertyInfo := GetPropInfo(HolderObject.ClassInfo, ItemTextName,
            [tkString, tkLString, tkWString, tkUString]);
          if ItemPropertyInfo = nil then
            Continue;
          if not APack.TryGetText(ComponentKey(AFormIdentity, AForm,
            AComponent, Format('%s[%d].%s.%s',
              [CollectionName, ItemIndex, ItemHolderName, ItemTextName])),
            TranslatedText) then
            Continue;
          SetStrProp(HolderObject, ItemPropertyInfo, TranslatedText);
          Inc(Result);
        end;
      end;
    end;
  end;
end;

{ Stop a control sizing itself before its text changes, not after.

  A label that sizes itself is measured by the caption it is holding. Give it a
  translation with no line breaks in it and it collapses to a single line -
  wide and one line tall - the instant the caption is assigned. Switching
  AutoSize off afterwards, which is what the ordered layout pass does, only
  freezes it in that shape: the width is put right by the Width rule, the text
  wraps inside it, and two of its three lines are drawn outside a box twenty
  pixels high. The instruction paragraph on the random-directory page was one
  line of three for exactly this reason.

  So the AutoSize rules are applied first, on their own, before a single
  caption is written. The ordered pass applies them again afterwards, which
  costs nothing and keeps that pass complete in itself. }
procedure ApplyAutoSizeRulesFirst(const AForm: TCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string);
var
  Component: TComponent;
  Rule: TRuntimeLayoutRule;
begin
  if (AForm = nil) or (APack = nil) then
    Exit;
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    if not SameText(Rule.PropertyName, 'AutoSize') then
      Continue;
    if SameText(Rule.ComponentName, AFormIdentity) or
      SameText(Rule.ComponentName, AForm.Name) or
      (Trim(Rule.ComponentName) = '') then
      Component := AForm
    else
      Component := AForm.FindComponent(Rule.ComponentName);
    if Component = nil then
      Continue;
    TrySetLayoutProperty(Component, Rule.PropertyName, Rule.TranslatedValue);
  end;
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
  SnapshotOriginalGeometry(AForm, FormIdentity);
  { Every language is laid out from the form as it was designed, never on top
    of the language before it.

    A form is only restored when the language changes while it is on screen; a
    form that is closed at that moment is not collected, and nothing puts it
    back. Opening it again applied the new language over geometry left by the
    old one, so a dialog kept the widths, the font sizes and the colours of
    whichever language it happened to be open in last, and every switch left a
    little more behind. Starting from the snapshot costs one pass over the
    controls and makes applying a language mean the same thing every time. }
  RestoreOriginalGeometry(AForm, APack, FormIdentity);
  SavedFocusedControl := nil;
  SavedFocusedState := False;
  if APreserveControlState then
  begin
    SavedFocusedControl := AForm.ActiveControl;
    SavedFocusedState := (SavedFocusedControl <> nil) and
      SavedFocusedControl.Focused;
  end;

  { Before any caption is written, so nothing has a chance to resize itself
    around its new text. }
  ApplyAutoSizeRulesFirst(AForm, APack, FormIdentity);

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
        Inc(Result, ApplyCollectionText(FormIdentity, AForm, Component,
          APack));
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
  OrderedLayoutProperties: array[0..7] of string = (
    'AutoSize', 'FontSize', 'WordWrap', 'Width', 'Height', 'Left', 'Top',
    { Column widths, which name a path rather than a property. Last, because a
      column is inside a control that has already been given its own size. }
    'Columns');
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
    if SameText(OrderedProperty, 'Columns') then
    begin
      if not StartsText('Columns[', Rule.PropertyName) then
        Continue;
    end
    else if not SameText(Rule.PropertyName, OrderedProperty) then
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
    if TrySetCollectionProperty(Component, Rule.PropertyName, Value) then
      Inc(Result)
    else if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

initialization
  TVCLTranslationApplicator.FOriginalGeometry :=
    TDictionary<string, TDATVCLControlSnapshot>.Create;

finalization
  TVCLTranslationApplicator.FOriginalGeometry.Free;
  TVCLTranslationApplicator.FOriginalGeometry := nil;

end.