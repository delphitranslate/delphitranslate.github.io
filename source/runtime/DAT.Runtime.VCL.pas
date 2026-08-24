unit DAT.Runtime.VCL;

interface

uses
  DAT.Runtime.LayoutOverrides,
  System.Classes,
  System.Generics.Collections,
  { TAlign and TAnchors are named in the snapshot below, so they belong in the
    interface rather than only in the implementation. }
  Vcl.Controls,
  Vcl.Forms,
  { TMenuAutoFlag is named in the class below, so it belongs here rather
    than only in the implementation. }
  Vcl.Menus,
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
    { A mirrored layout changes more than coordinates, and everything it
      changes has to be restorable. Returning to the source language must put
      a form back as it was drawn; a user who tries Hebrew once and goes back
      to English should not be left with an English program laid out
      backwards. }
    HasAlign: Boolean;
    Align: TAlign;
    HasAlignment: Boolean;
    Alignment: NativeInt;
    HasAnchors: Boolean;
    Anchors: TAnchors;
  end;

  TVCLTranslationApplicator = class
  private
    class var FOriginalGeometry: TDictionary<string, TDATVCLControlSnapshot>;
    { Which grids are currently showing their columns in reverse.

      The geometry snapshot cannot carry this: it is taken once, before any
      language is applied, and records how the form was drawn. Whether the
      columns are reversed right now is not a fact about the design, it is a
      fact about the language in force, and it has to be remembered so that
      returning to the source language can undo it. Reversing is its own
      opposite, so undoing it is doing it again. }
    { The order each grid was designed in, remembered once. The target
      order is stated in terms of it, so applying twice cannot drift. }
    class var FDesignedColumns: TDictionary<string, TArray<string>>;
    { Which forms currently have their menu bar reversed, so that leaving a
      right-to-left language reverses it back exactly once. Reversal is its
      own inverse; doing it twice or not at all are both wrong. }
    class var FDesignedMenuOrder: TDictionary<string, TArray<string>>;
    { What each form's menu had for AutoHotkeys before a translation was
      applied, so the source language gets it back. }
    class var FMenuAutoHotkeys: TDictionary<string, TMenuAutoFlag>;
    class procedure RecentreSelfPlacedText(const AForm: TCustomForm;
      const AFormIdentity: string); static;
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
    { Adjustments a person made while the application was running, applied
      after every rule the pack carries. They are last on purpose: an
      override is the correction of somebody who looked at the result, and
      where the planner and a person disagree the person is right. }
    class function ApplyOverrides(const AForm: TCustomForm;
      const AOverrides: TLayoutOverrides;
      const AFormIdentity: string): Integer; static;
    class function ApplyLayoutToForm(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const AUseTranslatedValues: Boolean): Integer; static;
    class function RestoreSourceLanguage(const AForm: TCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer; static;
  end;

implementation

uses
  Winapi.Windows,
  System.Character,
  System.SysUtils,
  System.StrUtils,
  System.TypInfo,
  Vcl.Graphics,
  Vcl.StdCtrls;

{ Declared here because restoring a form needs it before it is defined: a
  grid is put back into its designed order the same way it was taken out of
  it, by stating the order rather than counting flips. }
function ApplyColumnOrder(const AComponent: TComponent;
  const AKey: string; const AReversed: Boolean): Boolean; forward;

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
    begin
      { A named value, for the properties a mirror changes: Align becomes
        alRight, Alignment becomes taRightJustify. GetEnumValue answers -1
        for a name the property does not have, which is the guard against a
        rule written for a different control. }
      OrdinalValue := GetEnumValue(PropertyInfo.PropType^, AValue);
      if OrdinalValue < 0 then
        Exit;
    end;
    SetOrdProp(AComponent, PropertyInfo, OrdinalValue);
    Exit(True);
  end;
  { Anchors is a set rather than a single value. }
  if PropertyInfo.PropType^.Kind = tkSet then
  begin
    try
      SetSetProp(AComponent, PropertyInfo, AValue);
    except
      Exit(False);
    end;
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

{ An ordinal property by name, for the enumerated ones a mirror changes. }
function TryReadOrdinal(const AComponent: TComponent;
  const APropertyName: string; out AValue: NativeInt): Boolean;
var
  PropertyInfo: PPropInfo;
begin
  Result := False;
  AValue := 0;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkEnumeration]);
  if PropertyInfo = nil then
    Exit;
  AValue := GetOrdProp(AComponent, PropertyInfo);
  Result := True;
end;

procedure WriteOrdinal(const AComponent: TComponent;
  const APropertyName: string; const AValue: NativeInt);
var
  PropertyInfo: PPropInfo;
begin
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
    [tkEnumeration]);
  if PropertyInfo <> nil then
    SetOrdProp(AComponent, PropertyInfo, AValue);
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
      Snapshot.HasAlign := True;
      Snapshot.Align := Control.Align;
      Snapshot.HasAnchors := True;
      Snapshot.Anchors := Control.Anchors;
      Snapshot.HasAlignment := TryReadOrdinal(AComponent, 'Alignment',
        Snapshot.Alignment);
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
      { The mirror, undone. Align before the bounds would fight them, so it
        goes here, after: a control the framework places ignores the bounds
        anyway, and one it does not is unaffected by the constant. }
      if Snapshot.HasAlign and (Control.Align <> Snapshot.Align) then
      begin
        Control.Align := Snapshot.Align;
        Inc(Restored);
      end;
      if Snapshot.HasAnchors and (Control.Anchors <> Snapshot.Anchors) then
      begin
        Control.Anchors := Snapshot.Anchors;
        Inc(Restored);
      end;
      if Snapshot.HasAlignment then
        WriteOrdinal(AComponent, 'Alignment', Snapshot.Alignment);
      { Back to the order it was designed in - stated, not counted. }
      if ApplyColumnOrder(AComponent, Key, False) then
        Inc(Restored);
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
{ Put a grid's columns in the opposite order.

  A grid reads the way its language reads, so under Hebrew or Arabic the first
  column belongs against the right-hand edge. This is stated once for the grid
  rather than once per column because reversing a collection one index at a
  time depends on the order the moves are made in - the rule for column 1 is
  written against the designed order, and by the time it is applied the item
  at index 1 is no longer the one the rule meant.

  It runs after the column widths for the same reason: a width names a column
  by its designed index, and reversing first would put every width on the
  wrong column. }
function ReadStringProperty(const AInstance: TObject;
  const APropertyName: string; out AValue: string): Boolean;
var
  PropertyInfo: PPropInfo;
begin
  Result := False;
  AValue := '';
  if AInstance = nil then
    Exit;
  PropertyInfo := GetPropInfo(AInstance.ClassInfo, APropertyName);
  if (PropertyInfo = nil) or
    not (PropertyInfo^.PropType^.Kind in
      [tkString, tkLString, tkWString, tkUString]) then
    Exit;
  AValue := GetStrProp(AInstance, PropertyInfo);
  Result := True;
end;

{ How a column is recognised again after it has been moved. }
function ColumnIdentity(const AItem: TCollectionItem): string;
var
  TitleObject: TObject;
  PropertyInfo: PPropInfo;
begin
  { Field name first: it is what the column is for, and it does not change
    when the heading is translated. }
  if ReadStringProperty(AItem, 'FieldName', Result) and
    (Trim(Result) <> '') then
    Exit;
  { Then the heading, for a grid with no data behind it. Title is an object of
    its own, so its Caption is a second hop rather than a dotted name. }
  PropertyInfo := GetPropInfo(AItem.ClassInfo, 'Title');
  if PropertyInfo <> nil then
  begin
    TitleObject := GetObjectProp(AItem, PropertyInfo);
    if (TitleObject <> nil) and
      ReadStringProperty(TitleObject, 'Caption', Result) and
      (Trim(Result) <> '') then
      Exit;
  end;
  { And the designed position for a grid with neither. }
  Result := '#' + IntToStr(AItem.Index);
end;

function ColumnCollectionOf(const AComponent: TComponent;
  out ACollection: TCollection): Boolean;
var
  PropertyInfo: PPropInfo;
  CollectionObject: TObject;
begin
  Result := False;
  ACollection := nil;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Columns');
  if PropertyInfo = nil then
    Exit;
  CollectionObject := GetObjectProp(AComponent, PropertyInfo);
  if not (CollectionObject is TCollection) then
    Exit;
  ACollection := TCollection(CollectionObject);
  Result := ACollection.Count > 1;
end;

{ The order the grid was designed in, remembered the first time it is seen.

  The target is stated in terms of this - right to left means the designed
  order backwards, not whatever it is now backwards - so it has to be captured
  before anything moves it. }
function DesignedColumnOrder(const AComponent: TComponent;
  const AKey: string): TArray<string>;
var
  Collection: TCollection;
  Index: Integer;
begin
  if TVCLTranslationApplicator.FDesignedColumns.TryGetValue(AKey, Result) then
    Exit;
  SetLength(Result, 0);
  if not ColumnCollectionOf(AComponent, Collection) then
    Exit;
  SetLength(Result, Collection.Count);
  for Index := 0 to Collection.Count - 1 do
    Result[Index] := ColumnIdentity(Collection.Items[Index]);
  TVCLTranslationApplicator.FDesignedColumns.AddOrSetValue(AKey, Result);
end;

{ Puts the columns in the order the language calls for.

  This used to reverse the collection. Reversing is a toggle, and a toggle
  only lands right if every caller agrees on how many times it has been
  pulled - which they did not. A form applied twice, or restored by a path
  that did not update the record of what it had done, came back to its
  designed order under a right-to-left language.

  So the order is asserted instead. The target is recomputed from the designed
  order on every call and the columns are moved to match, which makes two
  applications indistinguishable from one - the property a toggle cannot have. }
function ApplyColumnOrder(const AComponent: TComponent;
  const AKey: string; const AReversed: Boolean): Boolean;
var
  Collection: TCollection;
  Designed, Target, Identities: TArray<string>;
  Items: TArray<TCollectionItem>;
  Used: TArray<Boolean>;
  Index, Scan: Integer;
begin
  Result := False;
  if not ColumnCollectionOf(AComponent, Collection) then
    Exit;
  Designed := DesignedColumnOrder(AComponent, AKey);
  if Length(Designed) <> Collection.Count then
    { The grid was rebuilt behind us - by a dataset opening, most likely - so
      the designed order no longer describes it. Leaving it alone is the only
      safe answer; a guess here reorders somebody's data. }
    Exit;

  SetLength(Target, Length(Designed));
  for Index := 0 to High(Designed) do
    if AReversed then
      Target[Index] := Designed[High(Designed) - Index]
    else
      Target[Index] := Designed[Index];

  { Taken by reference before anything moves. Tracking columns by position
    does not work: assigning Index shifts every other item, so a position
    noted a moment ago names a different column now. }
  SetLength(Items, Collection.Count);
  SetLength(Identities, Collection.Count);
  SetLength(Used, Collection.Count);
  for Index := 0 to Collection.Count - 1 do
  begin
    Items[Index] := Collection.Items[Index];
    Identities[Index] := ColumnIdentity(Items[Index]);
  end;

  Collection.BeginUpdate;
  try
    for Index := 0 to High(Target) do
      for Scan := 0 to High(Items) do
      begin
        if Used[Scan] or (Identities[Scan] <> Target[Index]) then
          Continue;
        if Items[Scan].Index <> Index then
        begin
          Items[Scan].Index := Index;
          Result := True;
        end;
        Used[Scan] := True;
        Break;
      end;
  finally
    Collection.EndUpdate;
  end;
end;

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

  { And on in, for as many levels as the path names.

    A heading lives on the column's Title, and the size of that heading lives
    on the Title's Font - "Columns[0].Title.Font.Size", which is two steps in,
    not one. Written for a single step this stopped at the Title and quietly
    did nothing, which is why a grid heading could be widened but never made
    smaller. }
  DotAt := Pos('.', ItemProperty);
  while DotAt > 0 do
  begin
    PropertyInfo := GetPropInfo(Target.ClassInfo,
      Copy(ItemProperty, 1, DotAt - 1));
    if (PropertyInfo = nil) or (PropertyInfo.PropType^.Kind <> tkClass) then
      Exit;
    Target := GetObjectProp(Target, PropertyInfo);
    if Target = nil then
      Exit;
    ItemProperty := Copy(ItemProperty, DotAt + 1, Length(ItemProperty));
    DotAt := Pos('.', ItemProperty);
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
{ ---------------------------------------------------------------------------
  Deciding where a long word breaks, once the control is its final size.

  The pack carries a soft hyphen at every point the language allows a break,
  because the pack is written long before anything knows how wide a label will
  end up. On a renderer that understands soft hyphens that would be the end of
  it. GDI does not: it draws U+00AD as an ordinary hyphen, and DrawText will
  not break a line at one. Measured here, a thirty-letter German compound with
  seven marks in it comes out 35 pixels WIDER than the same word unmarked, and
  still one unbroken line.

  So the marks are opportunities, and the decision is made at the last possible
  moment - here, after every layout rule has been applied and each control is
  the size it will really be. A control that wraps is given a real hyphen and a
  real line break at the last mark that fits its width; one that cannot wrap is
  given the plain word with the marks taken out. Either way no soft hyphen ever
  reaches a caption.
  --------------------------------------------------------------------------- }

const
  SoftHyphen = #$00AD;

function StripSoftHyphens(const AText: string): string;
begin
  Result := StringReplace(AText, SoftHyphen, '', [rfReplaceAll]);
end;

{ One word, broken to fit. Each line ends at the last offered break that still
  fits, with a hyphen of its own; a piece that fits nowhere is left whole
  rather than cut mid-syllable, because a wrong break is worse than an
  overflow. }
function BreakWordToWidth(const AWord: string; const ACanvas: TCanvas;
  const AWidth: Integer): string;
var
  Pieces: TArray<string>;
  Line: string;
  Candidate: string;
  Index: Integer;
begin
  Result := '';
  Pieces := AWord.Split([SoftHyphen]);
  Line := '';
  for Index := 0 to High(Pieces) do
  begin
    if Line = '' then
      Candidate := Pieces[Index]
    else
      Candidate := Line + Pieces[Index];
    { A hyphen has to fit on the line as well as the letters before it. }
    if (Line <> '') and (Index < High(Pieces)) and
      (ACanvas.TextWidth(Candidate + '-') > AWidth) then
    begin
      Result := Result + Line + '-' + #13#10;
      Line := Pieces[Index];
    end
    else if (Line <> '') and (Index = High(Pieces)) and
      (ACanvas.TextWidth(Candidate) > AWidth) then
    begin
      Result := Result + Line + '-' + #13#10;
      Line := Pieces[Index];
    end
    else
      Line := Candidate;
  end;
  Result := Result + Line;
end;

function ResolveSoftHyphens(const AText: string; const ACanvas: TCanvas;
  const AWidth: Integer; const AWraps: Boolean): string;
var
  Words: TArray<string>;
  Index: Integer;
  Plain: string;
begin
  if Pos(SoftHyphen, AText) = 0 then
    Exit(AText);
  if (not AWraps) or (ACanvas = nil) or (AWidth <= 0) then
    Exit(StripSoftHyphens(AText));

  { Only a word that will not fit needs breaking. The framework wraps at
    spaces perfectly well on its own, and a break offered inside a word that
    fits is simply not needed. }
  Words := AText.Split([' ']);
  for Index := 0 to High(Words) do
  begin
    if Pos(SoftHyphen, Words[Index]) = 0 then
      Continue;
    Plain := StripSoftHyphens(Words[Index]);
    if ACanvas.TextWidth(Plain) <= AWidth then
      Words[Index] := Plain
    else
      Words[Index] := BreakWordToWidth(Words[Index], ACanvas, AWidth);
  end;
  Result := string.Join(' ', Words);
end;

{ The width a caption really has to live in. A label is all text; a check box
  or a radio button spends part of its width on the box itself and on the gap
  after it. }
function CaptionWidth(const AControl: TControl): Integer;
begin
  Result := AControl.Width;
  if (AControl is TCustomCheckBox) or (AControl is TRadioButton) then
    Result := Result - 20;
end;

{ Every caption on the form, once the layout is settled. }
function ResolveSoftHyphensOnForm(const AForm: TCustomForm): Integer;
var
  Measure: TBitmap;

  { Break marks taken out of every column heading on a grid. }
  procedure ResolveColumnHeadings(const AComponent: TComponent);
  var
    Collection: TCollection;
    Index: Integer;
    TitleObject: TObject;
    PropertyInfo: PPropInfo;
    Heading: string;
  begin
    if not ColumnCollectionOf(AComponent, Collection) then
      Exit;
    for Index := 0 to Collection.Count - 1 do
    begin
      PropertyInfo := GetPropInfo(Collection.Items[Index].ClassInfo, 'Title');
      if PropertyInfo = nil then
        Continue;
      TitleObject := GetObjectProp(Collection.Items[Index], PropertyInfo);
      if TitleObject = nil then
        Continue;
      if not ReadStringProperty(TitleObject, 'Caption', Heading) then
        Continue;
      if Pos(SoftHyphen, Heading) = 0 then
        Continue;
      PropertyInfo := GetPropInfo(TitleObject.ClassInfo, 'Caption');
      if PropertyInfo = nil then
        Continue;
      SetStrProp(TitleObject, PropertyInfo, StripSoftHyphens(Heading));
      Inc(Result);
    end;
  end;

  procedure Walk(const AComponent: TComponent);
  var
    Child: TComponent;
    Control: TControl;
    Font: TFont;
    PropertyInfo: PPropInfo;
    Resolved: string;
    Text: string;
    Wraps: Boolean;
  begin
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Caption',
      [tkString, tkLString, tkWString, tkUString]);
    if PropertyInfo <> nil then
    begin
      Text := GetStrProp(AComponent, PropertyInfo);
      if Pos(SoftHyphen, Text) > 0 then
      begin
        if AComponent is TControl then
        begin
          Control := TControl(AComponent);
          if TryGetFont(Control, Font) then
            Measure.Canvas.Font.Assign(Font);
          Wraps := False;
          TryReadBoolean(Control, 'WordWrap', Wraps);
          Resolved := ResolveSoftHyphens(Text, Measure.Canvas,
            CaptionWidth(Control), Wraps);
        end
        else
          Resolved := StripSoftHyphens(Text);
        if Resolved <> Text then
        begin
          SetStrProp(AComponent, PropertyInfo, Resolved);
          Inc(Result);
        end;
      end;
    end;

    { A grid heading is not reached by any of the above.

      The walk visits components and their Caption property. A column is
      neither: it is an item in a collection hanging off the grid, carrying its
      heading on a Title object of its own. So the soft hyphens offered for
      breaking a long heading were left in the text, and GDI draws a soft
      hyphen rather than breaking at it - which is why an Italian heading came
      out reading "Data di ripro-du-zione" with the hyphens on the screen.

      A grid heading never wraps, whatever is offered, so the break marks are
      simply removed. }
    ResolveColumnHeadings(AComponent);

    for Child in AComponent do
      Walk(Child);
  end;

begin
  Result := 0;
  if AForm = nil then
    Exit;
  Measure := TBitmap.Create;
  try
    Measure.SetSize(1, 1);
    Walk(AForm);
  finally
    Measure.Free;
  end;
end;

{ Reading order for a right-to-left language.

  Measured rather than assumed, because the obvious choice is the wrong one.
  bdRightToLeft gives right-to-left reading order and the left-hand scroll bar,
  but it also flips text alignment on its own: a label set taLeftJustify is
  drawn DT_RIGHT. The planner has already decided alignment for every control
  and states it in the pack, so that flip would apply on top of ours and land
  each caption back where it started - taRightJustify drawn as DT_LEFT.

  bdRightToLeftNoAlign gives the same reading order and the same scroll bar
  and leaves alignment alone, which is what lets one side own the decision.

  BiDiMode does not move child controls in any mode - also measured - so this
  neither duplicates nor fights the mirrored coordinates in the pack. }

{ The menu bar reads in the language's direction.

  Three things were tried before this one, and the first two are worth
  recording because they look right and are not:

    - TMenu.BiDiMode. Follows the form, reports right-to-left, changes
      nothing on screen. VCL's only mirroring path, DoBiDiModeChanged,
      gives up when the machine is not Middle Eastern or the window handle
      is not yet made.

    - MFT_RIGHTORDER or MFT_RIGHTJUSTIFY on item zero, which is what VCL
      itself sets. These decide which way submenus cascade and push the bar
      against the right edge. Neither reverses the order of the top-level
      items, so File stays leftmost and the bar merely moves. A probe with
      four items read back File Schedule Settings Help both before and
      after applying an Arabic pack - the flag was set and nothing had
      moved. That is exactly what a tester sees and calls "unchanged".

  The order only truly reverses under WS_EX_LAYOUTRTL, and VCL never sets
  it - deliberately, because it mirrors every child window too and this
  applicator already computes mirrored positions itself. Turning it on
  would mirror everything twice.

  So the order is reversed here, the same way grid columns already are:
  explicitly, in the collection, rather than by asking the framework to
  present the same order differently. Delete unlinks a TMenuItem without
  freeing it, so walking the bar backwards and re-adding each item leaves
  the same objects in the opposite order, with their captions, shortcuts
  and handlers intact.

  Reversal is its own inverse, so the registry records which forms are
  currently reversed. Without it, applying Arabic twice would reverse the
  bar back to English order, and returning to English would leave it
  reversed - both of which are worse than never mirroring at all. }
function ReverseMenuBar(const AMenu: TMenu): Boolean;
var
  Items: TList<TMenuItem>;
  Item: TMenuItem;
  Index: Integer;
begin
  Result := False;
  if (AMenu = nil) or (AMenu.Items = nil) or (AMenu.Items.Count < 2) then
    Exit;
  Items := TList<TMenuItem>.Create;
  try
    for Index := AMenu.Items.Count - 1 downto 0 do
    begin
      Item := AMenu.Items[Index];
      AMenu.Items.Delete(Index);
      Items.Add(Item);
    end;
    for Item in Items do
      AMenu.Items.Add(Item);
  finally
    Items.Free;
  end;
  Result := True;
end;

{ The cascade direction of submenus, which is a separate question from the
  order of the bar and is what the flag genuinely controls. }
procedure ApplyMenuCascadeDirection(const AForm: TCustomForm;
  const ARightToLeft: Boolean);
const
  BufferSize = 80;
  { Vcl.Menus declares this in its implementation section, so it cannot be
    imported. Restated rather than invented: the value is VCL's own. }
  RightToLeftMenuFlag = MFT_RIGHTORDER or MFT_RIGHTJUSTIFY;
var
  MenuHandle: HMENU;
  ItemInfo: TMenuItemInfo;
  Buffer: array[0..BufferSize - 1] of Char;
  Desired: UINT;
begin
  if (AForm = nil) or (AForm.Menu = nil) or (not AForm.HandleAllocated) then
    Exit;
  MenuHandle := AForm.Menu.Handle;
  if (MenuHandle = 0) or (GetMenuItemCount(MenuHandle) <= 0) then
    Exit;
  FillChar(ItemInfo, SizeOf(ItemInfo), 0);
  ItemInfo.cbSize := SizeOf(TMenuItemInfo);
  ItemInfo.fMask := MIIM_TYPE;
  ItemInfo.cch := BufferSize;
  ItemInfo.dwTypeData := @Buffer[0];
  if not GetMenuItemInfo(MenuHandle, 0, True, ItemInfo) then
    Exit;
  if ARightToLeft then
    Desired := ItemInfo.fType or RightToLeftMenuFlag
  else
    Desired := ItemInfo.fType and not RightToLeftMenuFlag;
  if Desired = ItemInfo.fType then
    Exit;
  { Only fType is written. Handing back the buffer GetMenuItemInfo filled
    would rewrite item zero's caption as a side effect of a layout flag, and
    on a menu whose captions were just translated that loses one. }
  FillChar(ItemInfo, SizeOf(ItemInfo), 0);
  ItemInfo.cbSize := SizeOf(TMenuItemInfo);
  ItemInfo.fMask := MIIM_FTYPE;
  ItemInfo.fType := Desired;
  if SetMenuItemInfo(MenuHandle, 0, True, ItemInfo) then
    DrawMenuBar(AForm.Handle);
end;

{ VCL stops inventing keyboard shortcuts once the captions are not English.

  Menu items with no ampersand of their own get one from VCL, because
  TMenu.AutoHotkeys defaults to maAutomatic and re-runs every time a caption
  changes - which is every time a language is applied.

  For Latin text that is invisible: a letter gets underlined. For anything
  Unicode calls an OtherLetter - Arabic, Hebrew, Thai, the CJK scripts, most
  of Indic - VCL takes a different branch, InsertHotkeyFarEastFormat, and
  appends the shortcut as visible text:

    ACaption := ACaption + '(' + cHotkeyPrefix + AHotKey + ')';

  So a menu translated to Arabic reads the Arabic for "File" followed by (Z), and its submenus the same, with
  Roman letters marching through them in reverse alphabetical order. The
  translation was never wrong; VCL decorated it afterwards.

  That convention is right where it comes from - a Japanese menu really does
  show (&F) - but it is applied here on the basis of the script alone, with no
  regard for whether the application, the user or the language wants it.

  Turning it off costs the Alt-key shortcuts VCL was inventing. Items with an
  ampersand written into the .dfm keep theirs, because those are the
  application's own and are not touched. Invented ones were never designed and
  the letters were arbitrary, so what is lost is a shortcut nobody chose,
  spelled in an alphabet the reader may not use.

  Only while a translation is active. Back in the source language the menu is
  the application's again, and whatever it did before it does again. }
procedure ApplyMenuHotkeyPolicy(const AForm: TCustomForm;
  const AFormIdentity: string; const ATranslated: Boolean);
var
  Original: TMenuAutoFlag;
begin
  if (AForm = nil) or (AForm.Menu = nil) then
    Exit;
  if ATranslated then
  begin
    { Remembered on the way in, so returning to the source language restores
      what the application chose rather than what this unit prefers. }
    if not TVCLTranslationApplicator.FMenuAutoHotkeys.ContainsKey(
      AFormIdentity) then
      TVCLTranslationApplicator.FMenuAutoHotkeys.Add(AFormIdentity,
        AForm.Menu.AutoHotkeys);
    AForm.Menu.AutoHotkeys := maManual;
  end
  else if TVCLTranslationApplicator.FMenuAutoHotkeys.TryGetValue(
    AFormIdentity, Original) then
  begin
    AForm.Menu.AutoHotkeys := Original;
    TVCLTranslationApplicator.FMenuAutoHotkeys.Remove(AFormIdentity);
  end;
end;

{ The bar is put into the order the language reads, absolutely.

  This used to remember whether it had reversed a form's menu and toggle from
  there. Remembering is only safe while the thing remembered about still
  exists: a form closed and reopened comes back with its menu in the order the
  designer drew, while the note still said "reversed". The next switch then
  toggled from a baseline that was no longer true and left the bar backwards -
  which is a menu still reading right to left after the user had gone back to
  German.

  So nothing is remembered about what was done. The designed order is captured
  the first time a menu is seen and the wanted order is set from it every time,
  which gives the same answer however many times it runs and whatever happened
  to the form in between. The grid columns were changed to work this way for
  the same reason. }
procedure ApplyMenuReadingOrder(const AForm: TCustomForm;
  const AFormIdentity: string; const ARightToLeft: Boolean);
var
  Designed: TList<TMenuItem>;
  Item: TMenuItem;
  Index: Integer;
  Key: string;
  Order: TArray<string>;
  Wanted: TList<TMenuItem>;
begin
  if (AForm = nil) or (AForm.Menu = nil) or (AForm.Menu.Items = nil) then
    Exit;
  ApplyMenuCascadeDirection(AForm, ARightToLeft);
  if AForm.Menu.Items.Count < 2 then
    Exit;

  Key := AFormIdentity + '.' + AForm.Menu.Name;
  { The designed order, named rather than positional so it survives the menu
    being rebuilt. }
  if not TVCLTranslationApplicator.FDesignedMenuOrder.TryGetValue(Key,
    Order) then
  begin
    SetLength(Order, AForm.Menu.Items.Count);
    for Index := 0 to AForm.Menu.Items.Count - 1 do
      Order[Index] := AForm.Menu.Items[Index].Name;
    TVCLTranslationApplicator.FDesignedMenuOrder.AddOrSetValue(Key, Order);
  end;

  Designed := TList<TMenuItem>.Create;
  Wanted := TList<TMenuItem>.Create;
  try
    { Anything the note does not cover - an item the application added since -
      keeps its place at the end rather than being dropped. }
    for Index := 0 to High(Order) do
      for Item in AForm.Menu.Items do
        if SameText(Item.Name, Order[Index]) and (Designed.IndexOf(Item) < 0) then
        begin
          Designed.Add(Item);
          Break;
        end;
    for Item in AForm.Menu.Items do
      if Designed.IndexOf(Item) < 0 then
        Designed.Add(Item);
    if Designed.Count <> AForm.Menu.Items.Count then
      Exit;

    if ARightToLeft then
      for Index := Designed.Count - 1 downto 0 do
        Wanted.Add(Designed[Index])
    else
      for Item in Designed do
        Wanted.Add(Item);

    { Already in the wanted order, so nothing to do and nothing to redraw. }
    Index := 0;
    while (Index < Wanted.Count) and (AForm.Menu.Items[Index] = Wanted[Index]) do
      Inc(Index);
    if Index >= Wanted.Count then
      Exit;

    for Index := AForm.Menu.Items.Count - 1 downto 0 do
      AForm.Menu.Items.Delete(Index);
    for Item in Wanted do
      AForm.Menu.Items.Add(Item);
  finally
    Wanted.Free;
    Designed.Free;
  end;
  if AForm.HandleAllocated then
    DrawMenuBar(AForm.Handle);
end;

{ Text that carries no letters of its own must not be turned round.

  A caption of "1." is digits and a full stop, and Unicode calls every one of
  those characters neutral - they take their direction from whatever is around
  them. Put a neutral run in a right-to-left paragraph and the algorithm reads
  it right to left too, so "1." is drawn ".1" and a numbered list comes out
  looking like the menu captions did with shortcuts bolted on.

  The text is not wrong and translating it differently would not help; only
  the direction it is read in is wrong. A control holding nothing but neutrals
  is therefore left reading left to right, which is what its digits mean. One
  Arabic letter anywhere in it and this does not apply, because then the run
  has a direction of its own and belongs with the rest of the form. }
function HoldsOnlyNeutralText(const AControl: TControl): Boolean;
var
  Text: string;
  Character: Char;
  SawDigit: Boolean;
begin
  Result := False;
  if not ReadStringProperty(AControl, 'Caption', Text) then
    if not ReadStringProperty(AControl, 'Text', Text) then
      Exit;
  Text := Trim(Text);
  if Text = '' then
    Exit;
  SawDigit := False;
  for Character in Text do
  begin
    if TCharacter.IsLetter(Character) then
      Exit;
    if TCharacter.IsDigit(Character) then
      SawDigit := True;
  end;
  { Digits are the case worth correcting. A caption of only punctuation - a
    colon on its own, a dash between two fields - reads the same either way. }
  Result := SawDigit;
end;

{ An entry field a right-to-left reader is going to type into.

  bdRightToLeftNoAlign gives the reading order without moving the text, which
  is right for a caption whose position the layout pass has already decided
  and wrong for anything with a caret in it: the field stays left aligned, so
  typing begins at the left and the first character a reader enters appears at
  the wrong end of the box. An input control gets the full bdRightToLeft, so
  the caret starts where the reader does. }
function IsInputControl(const AControl: TControl): Boolean;
begin
  Result := (AControl is TCustomEdit) or (AControl is TCustomComboBox) or
    (AControl is TCustomListBox);
end;

procedure ApplyReadingOrder(const AForm: TCustomForm;
  const AFormIdentity: string; const APack: TRuntimeLanguagePack);
var
  Component: TComponent;
  Mode: TBiDiMode;
  RightToLeft: Boolean;

  procedure SetTree(const AComponent: TComponent);
  var
    Child: TComponent;
    Control: TControl;
  begin
    { Assigning BiDiMode clears ParentBiDiMode by itself, so the control
      keeps what it is given rather than inheriting it back. }
    if AComponent is TControl then
    begin
      Control := TControl(AComponent);
      if not RightToLeft then
        Control.BiDiMode := Mode
      else if HoldsOnlyNeutralText(Control) then
        Control.BiDiMode := bdLeftToRight
      else if IsInputControl(Control) then
        Control.BiDiMode := bdRightToLeft
      else
        Control.BiDiMode := Mode;
    end;
    for Child in AComponent do
      SetTree(Child);
  end;

begin
  if (AForm = nil) or (APack = nil) then
    Exit;
  RightToLeft := SameText(Trim(APack.TextDirection), 'rtl');
  if RightToLeft then
    Mode := bdRightToLeftNoAlign
  else
    Mode := bdLeftToRight;
  AForm.BiDiMode := Mode;
  for Component in AForm do
    SetTree(Component);
  ApplyMenuReadingOrder(AForm, AFormIdentity, RightToLeft);
end;

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

{ A caption the application centred itself stays centred.

  Some headings are placed by the program rather than by the designer, and the
  analyser is required to leave those alone - moving one overwrites a decision
  the application makes once at start-up and never makes again. Carillon does
  exactly this with its main heading: it sets Left to half the difference
  between the screen and the label, in code, before any translation happens.

  Leaving the position alone is right. Leaving it alone while the width changes
  underneath it is not: the arithmetic that produced the position used the
  English width, and the German caption is a different length, so the heading
  ends up as far off centre as the translation is longer. Every language
  reported it.

  Nothing here decides to centre anything. It reads what the application
  already did - a control whose snapshot sits centred in its parent was
  centred by somebody - and redoes that same arithmetic with the width the
  caption now has. A heading that was never centred is not touched. }
class procedure TVCLTranslationApplicator.RecentreSelfPlacedText(
  const AForm: TCustomForm; const AFormIdentity: string);
const
  { Half a character of slack, so a centring that was rounded still counts. }
  CentreTolerance = 3;
var
  Component: TComponent;
  Control: TControl;
  ParentWidth: Integer;
  Snapshot: TDATVCLControlSnapshot;
  WasCentre, Wanted: Integer;
begin
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  for Component in AForm do
  begin
    if not (Component is TControl) or (Component.Name = '') then
      Continue;
    Control := TControl(Component);
    if Control.Parent = nil then
      Continue;
    { Captions only. A panel that happens to sit centred was placed there
      deliberately and does not move because its contents changed. }
    if not ContainsText(Control.ClassName, 'Label') then
      Continue;
    if not FOriginalGeometry.TryGetValue(
      AFormIdentity + '.' + Component.Name, Snapshot) then
      Continue;
    ParentWidth := Control.Parent.ClientWidth;
    if ParentWidth <= 0 then
      Continue;
    WasCentre := Snapshot.Left + Snapshot.Width div 2;
    if Abs(WasCentre - ParentWidth div 2) > CentreTolerance then
      Continue;
    if Control.Width = Snapshot.Width then
      Continue;
    Wanted := (ParentWidth - Control.Width) div 2;
    if Wanted < 0 then
      Wanted := 0;
    Control.Left := Wanted;
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

  { Reading order before anything else that touches a control.

    It used to run after the text, and that is the wrong way round. Setting a
    menu item's caption rebuilds the menu, and Delphi stamps each item with
    the reading order in force at the moment of the rebuild - so translating
    the menu first meant rebuilding it in the language being left, and the
    later change of direction then had to correct it through
    TMenu.DoBiDiModeChanged, which returns early on several conditions
    including a window handle that is momentarily zero.

    Setting it first removes that dependency entirely: whatever is rebuilt
    afterwards is rebuilt the right way round to begin with. Direction is a
    property of the language rather than of any one control, so first is also
    where it belongs. The alignment rules still come later, in
    ApplyLayoutToForm, and still have the last word on alignment. }
  { Before any caption is written, because the decoration happens as a
    side effect of writing one. }
  ApplyMenuHotkeyPolicy(AForm, FormIdentity,
    not SameText(APack.LanguageCode, APack.SourceLanguage));
  ApplyReadingOrder(AForm, FormIdentity, APack);

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
    { Last of all, now that every control is the size it will really be. }
    ResolveSoftHyphensOnForm(AForm);
    { And the menu once more, after the captions.

      Writing a menu item's caption can rebuild the menu, and a rebuild
      carries no reading order with it. Setting the direction first is
      still right - it decides how anything rebuilt is built - but first
      is not sufficient on its own, because the flag that survives a
      rebuild is the one written after it. Doing both costs an early
      exit when nothing changed. }
    ApplyMenuReadingOrder(AForm, FormIdentity,
      SameText(Trim(APack.TextDirection), 'rtl'));
    { Last, because it reads the widths every pass above settled. }
    RecentreSelfPlacedText(AForm, FormIdentity);
  finally
    if APreserveControlState and SavedFocusedState and
      (SavedFocusedControl <> nil) and SavedFocusedControl.CanFocus then
      SavedFocusedControl.SetFocus;
  end;
end;

class function TVCLTranslationApplicator.ApplyOverrides(
  const AForm: TCustomForm; const AOverrides: TLayoutOverrides;
  const AFormIdentity: string): Integer;
var
  Index: Integer;
  Entry: TLayoutOverride;
  Found: TComponent;
  Control: TControl;
begin
  Result := 0;
  if (AForm = nil) or (AOverrides = nil) then
    Exit;
  for Index := 0 to AOverrides.Items.Count - 1 do
  begin
    Entry := AOverrides.Items[Index];
    if not SameText(Entry.FormName, AFormIdentity) then
      Continue;
    Found := AForm.FindComponent(Entry.ComponentName);
    if not (Found is TControl) then
      Continue;
    Control := TControl(Found);
    { Font size first: changing it on a control that sizes itself moves
      its bounds, so any width or position recorded afterwards has to be
      applied on top of that rather than under it. }
    if Entry.HasFontSize and (Entry.FontSize > 0) then
      if TrySetLayoutProperty(Control, 'FontSize',
        IntToStr(Entry.FontSize)) then
        Inc(Result);
    { Position and size are separate, so nudging a control does not also
      freeze a width the planner should still be free to compute. }
    if Entry.HasSize then
    begin
      Control.Width := Entry.Width;
      Control.Height := Entry.Height;
      Inc(Result);
    end;
    if Entry.HasPosition then
    begin
      Control.Left := Entry.Left;
      Control.Top := Entry.Top;
      Inc(Result);
    end;
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
  OrderedLayoutProperties: array[0..12] of string = (
    'AutoSize', 'FontSize', 'WordWrap',
    { Mirroring, before the geometry. Alignment and Align change where a
      control sits and how its text is measured, so they belong with the
      decisions that come before width and height rather than after them. }
    'Alignment', 'Align',
    'Width', 'Height', 'Left', 'Top',
    { Anchors last of the geometry: it governs what happens on the next
      resize, and setting it after a control is in its final place is what
      makes those distances the right ones. }
    'Anchors',
    { Keyboard order, which is reading order by another name. }
    'TabOrder',
    { Column widths, which name a path rather than a property. Late, because a
      column is inside a control that has already been given its own size. }
    'Columns',
    { And the column order last of all, because every width above names a
      column by the index it was designed at. }
    'ColumnOrder');
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
    else if SameText(OrderedProperty, 'ColumnOrder') then
    begin
      if not SameText(Rule.PropertyName, 'ColumnOrder') then
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
    if SameText(Rule.PropertyName, 'ColumnOrder') then
    begin
      { Both directions go through the same call. Asking for the designed
        order is as much an instruction as asking for the reverse of it,
        and routing only one of them here is why restoring a language left
        a grid in whatever order it happened to be in. }
      if ApplyColumnOrder(Component,
        VCLSnapshotKey(AFormIdentity, Component),
        SameText(Trim(Value), 'reversed')) then
        Inc(Result);
    end
    else if TrySetCollectionProperty(Component, Rule.PropertyName, Value) then
      Inc(Result)
    else if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

initialization
  TVCLTranslationApplicator.FDesignedColumns :=
    TDictionary<string, TArray<string>>.Create;
  TVCLTranslationApplicator.FDesignedMenuOrder :=
    TDictionary<string, TArray<string>>.Create;
  TVCLTranslationApplicator.FMenuAutoHotkeys :=
    TDictionary<string, TMenuAutoFlag>.Create;
  TVCLTranslationApplicator.FOriginalGeometry :=
    TDictionary<string, TDATVCLControlSnapshot>.Create;

finalization
  TVCLTranslationApplicator.FOriginalGeometry.Free;
  TVCLTranslationApplicator.FOriginalGeometry := nil;
  TVCLTranslationApplicator.FDesignedColumns.Free;
  TVCLTranslationApplicator.FDesignedColumns := nil;
  TVCLTranslationApplicator.FDesignedMenuOrder.Free;
  TVCLTranslationApplicator.FDesignedMenuOrder := nil;
  TVCLTranslationApplicator.FMenuAutoHotkeys.Free;
  TVCLTranslationApplicator.FMenuAutoHotkeys := nil;

end.