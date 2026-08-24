unit DAT.Runtime.FMX;

interface

uses
  DAT.Runtime.LayoutOverrides,
  System.Generics.Collections,
  System.Types,
  { TAlignLayout is named in the snapshot below, so it belongs in the
    interface rather than only in the implementation. }
  FMX.Types,
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  { What a control looked like before any translation touched it.

    Only the position used to be remembered, and only that could be given back.
    Everything else a translation changes - the size, the text size and colour,
    whether the control wraps or sizes itself - was changed and then had no
    record anywhere, so returning to the original language restored the words
    and left the geometry wherever the last language had put it. The run-time
    fitting makes that worse, because it resizes controls the analyser never
    wrote a rule for, and a rule is the only other thing a restore could work
    from.

    So the whole of what can be changed is kept, and it is kept as plain types
    rather than FireMonkey ones: the sets and colours are stored as ordinals so
    that this declaration costs the unit's interface nothing. }
  TDATControlSnapshot = record
    Position: TPointF;
    Size: TPointF;
    HasPosition: Boolean;
    HasTextSettings: Boolean;
    FontSize: Single;
    FontColor: Cardinal;
    WordWrap: Boolean;
    Trimming: Byte;
    StyledSettings: Byte;
    HasAutoSize: Boolean;
    AutoSize: Boolean;
    { A mirrored layout changes more than coordinates, and everything it
      changes has to be restorable. }
    Align: TAlignLayout;
    { As text, read and written through RTTI, so the snapshot does not have to
      name a set type that lives in another unit. }
    Anchors: string;
    HorzAlign: Byte;
  end;

  TFMXTranslationApplicator = class
  private
    class var FOriginalGeometry: TDictionary<string, TDATControlSnapshot>;
    class procedure RecentreSelfPlacedText(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    { The order each grid was designed in, remembered once, so the target
      order can be stated in terms of it rather than counted. }
    class var FDesignedColumns: TDictionary<string, TArray<string>>;
    { And the order each menu bar was designed in, for the same reason. }
    class var FDesignedMenus: TDictionary<string, TArray<string>>;
    class procedure SnapshotOriginalGeometry(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    class function RestoreOriginalGeometry(const AForm: TCommonCustomForm;
      const AFormIdentity: string): Integer; static;
  public
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack): Integer; overload; static;
    class function ApplyToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const APreserveControlState: Boolean = True;
      const AApplyLayout: Boolean = True): Integer; overload; static;
    { Adjustments a person made while the application was running, applied
      after every rule the pack carries. They are last on purpose: an
      override is the correction of somebody who looked at the result, and
      where the planner and a person disagree the person is right. }
    class function ApplyOverrides(const AForm: TCommonCustomForm;
      const AOverrides: TLayoutOverrides;
      const AFormIdentity: string): Integer; static;
    class function ApplyLayoutToForm(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string;
      const AUseTranslatedValues: Boolean): Integer; static;
    class function RestoreSourceLanguage(const AForm: TCommonCustomForm;
      const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Defaults,
  System.IOUtils,
  System.JSON,
  System.Math,
  System.SysUtils,
  System.StrUtils,
  System.TypInfo,
  System.UITypes,
  FMX.Controls,
  FMX.Edit,
  FMX.Grid,
  FMX.Memo,
  FMX.Menus,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.TextLayout,
  FMX.WebBrowser;

const
  { U+00AD, the break offered inside a word. }
  SoftHyphenMark = #$00AD;

type
  TBrowserTranslationRetry = class(TComponent)
  private
    FAttempts: Integer;
    FBrowser: TCustomWebBrowser;
    FScript: string;
    FTimer: TTimer;
    procedure TimerTick(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(ABrowser: TCustomWebBrowser;
      const AScript: string); reintroduce;
  end;

const
  DATRuntimeDebugLogFileName = 'C:\Downloads\DAT_Translation_Debug_Log.txt';

procedure DATRuntimeDebugLog(const AMessage: string);
var
  LogDirectory: string;
begin
  try
    LogDirectory := TPath.GetDirectoryName(DATRuntimeDebugLogFileName);
    if (LogDirectory <> '') and not TDirectory.Exists(LogDirectory) then
      TDirectory.CreateDirectory(LogDirectory);
    TFile.AppendAllText(DATRuntimeDebugLogFileName,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMessage +
      sLineBreak, TEncoding.UTF8);
  except
    { Runtime diagnostics must never change target application behavior. }
  end;
end;

function PositionKey(const AFormIdentity: string;
  const AComponent: TComponent): string;
begin
  if (AComponent = nil) or (Trim(AComponent.Name) = '') then
    Exit('');
  Result := AFormIdentity + '.' + AComponent.Name;
end;

constructor TBrowserTranslationRetry.Create(ABrowser: TCustomWebBrowser;
  const AScript: string);
begin
  inherited Create(ABrowser);
  FBrowser := ABrowser;
  FScript := AScript;
  if FBrowser <> nil then
    FBrowser.FreeNotification(Self);
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 175;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
end;

procedure TBrowserTranslationRetry.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FBrowser) then
  begin
    FBrowser := nil;
    if FTimer <> nil then
      FTimer.Enabled := False;
  end;
end;

procedure TBrowserTranslationRetry.TimerTick(Sender: TObject);
begin
  Inc(FAttempts);
  if FBrowser <> nil then
  begin
    try
      DATRuntimeDebugLog(Format(
        'Browser retry attempt %d on %s.%s; script length=%d',
        [FAttempts, FBrowser.ClassName, FBrowser.Name, Length(FScript)]));
      FBrowser.EvaluateJavaScript(FScript);
    except
      on E: Exception do
      begin
        DATRuntimeDebugLog(Format(
          'Browser retry attempt %d failed on %s.%s: %s: %s',
          [FAttempts, FBrowser.ClassName, FBrowser.Name, E.ClassName,
          E.Message]));
        { TWebBrowser may reject script while the platform view is still
          finishing navigation. Keep retrying quietly; never surface platform
          script timing as an application error. }
      end;
    end;
  end;
  if FAttempts >= 40 then
    FTimer.Enabled := False;
end;

{ Text settings, reached the way FireMonkey means them to be reached.

  TTextControl is only one of the two families of text control. A TLabel, and
  everything else built on TPresentedTextControl, descends from the other and
  is not a TTextControl at all: the compiler will not even permit the two to be
  compared directly. Written against a TComponent the test compiles happily and
  is simply False for every label, which is what it had been doing here.

  The cost of that was invisible and large. Wrapping, text size and font colour
  are the three properties this unit sets through the class, so for labels -
  most of the text on any form - they were never set. The analyser would decide
  a caption needed to be a point smaller, the rule would be written into the
  pack, the runtime would read it, and nothing whatever would happen. Both
  families implement ITextSettings, so ask for the interface. }
function AsTextSettings(const AComponent: TComponent;
  out ASettings: ITextSettings): Boolean;
begin
  Result := Supports(AComponent, ITextSettings, ASettings) and
    Assigned(ASettings) and Assigned(ASettings.TextSettings);
end;

function ApplyFontColorsToForm(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer;
var
  Component: TComponent;
  ColorText: string;
  ComponentKey: string;
  ComponentName: string;
  ComponentTextSettings: ITextSettings;
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
    if not AsTextSettings(Component, ComponentTextSettings) then
      Continue;
    ColorText := APack.FontColors[ComponentKey];
    try
      if not TryParseColor(ColorText, ParsedColor) then
        Continue;
      ComponentTextSettings.StyledSettings :=
        ComponentTextSettings.StyledSettings - [TStyledSetting.FontColor];
      ComponentTextSettings.TextSettings.FontColor := ParsedColor;
      Inc(Result);
    except
      // Optional styling metadata must never block translation.
    end;
  end;
end;

{ Word wrap on an FMX text control lives in TextSettings, and while
  TStyledSetting.Other stays in StyledSettings the platform style supplies
  wrapping and trimming instead of the assigned values. Setting the published
  WordWrap property alone therefore appears to succeed and changes nothing:
  the control keeps rendering one styled line and trims it with an ellipsis.
  Take the setting out of style control, then assign it, and stop trimming so
  a control that has been given a fixed width shows its text on several lines
  rather than clipping it. }
{ Which edge the text sits against.

  FireMonkey has no BiDiMode and no FlipChildren, so under a right-to-left
  language this is the whole of what the framework contributes and the planner
  does everything else. StyledSettings has to give up HorzAlign first or the
  style puts it straight back. }
{ Anchors as the designer would write them, through RTTI. }
function ReadAnchorsText(const AComponent: TComponent): string;
var
  PropertyInfo: PPropInfo;
begin
  Result := '';
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Anchors');
  if PropertyInfo <> nil then
    Result := GetSetProp(AComponent, PropertyInfo, True);
end;

procedure WriteAnchorsText(const AComponent: TComponent;
  const AValue: string);
var
  PropertyInfo: PPropInfo;
begin
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'Anchors');
  if PropertyInfo <> nil then
    try
      SetSetProp(AComponent, PropertyInfo, AValue);
    except
      { A control with no anchors of that shape is left as it is. }
    end;
end;

function ApplyHorzAlignSetting(const AComponent: TComponent;
  const AValue: string): Boolean;
var
  Settings: ITextSettings;
  Alignment: TTextAlign;
begin
  Result := False;
  if not AsTextSettings(AComponent, Settings) then
    Exit;
  if MatchText(Trim(AValue), ['Leading', 'TTextAlign.Leading',
    'taLeftJustify']) then
    Alignment := TTextAlign.Leading
  else if MatchText(Trim(AValue), ['Trailing', 'TTextAlign.Trailing',
    'taRightJustify']) then
    Alignment := TTextAlign.Trailing
  else if MatchText(Trim(AValue), ['Center', 'Centre', 'TTextAlign.Center',
    'taCenter']) then
    Alignment := TTextAlign.Center
  else
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Other];
  if Settings.TextSettings.HorzAlign <> Alignment then
  begin
    Settings.TextSettings.HorzAlign := Alignment;
    Result := True;
  end;
end;

function ApplyWordWrapSetting(const AComponent: TComponent;
  const AValue: Boolean): Boolean;
var
  Settings: ITextSettings;
begin
  Result := False;
  if not AsTextSettings(AComponent, Settings) then
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Other];
  if Settings.TextSettings.WordWrap <> AValue then
  begin
    Settings.TextSettings.WordWrap := AValue;
    Result := True;
  end;
  if AValue and (Settings.TextSettings.Trimming <> TTextTrimming.None) then
  begin
    Settings.TextSettings.Trimming := TTextTrimming.None;
    Result := True;
  end;
end;

{ Font size is style-controlled in the same way wrapping is: while
  TStyledSetting.Size remains, the platform style supplies the size and an
  assignment is quietly ignored. Take it out of style control before setting
  it, or a caption asked to shrink keeps rendering at its designed size and
  overflows exactly as before. }
function ApplyFontSizeSetting(const AComponent: TComponent;
  const AValue: Single): Boolean;
var
  Settings: ITextSettings;
begin
  Result := False;
  if (AValue <= 0) or not AsTextSettings(AComponent, Settings) then
    Exit;
  Settings.StyledSettings := Settings.StyledSettings -
    [TStyledSetting.Size];
  if not SameValue(Settings.TextSettings.Font.Size, AValue, 0.01) then
  begin
    Settings.TextSettings.Font.Size := AValue;
    Result := True;
  end;
end;

{ Reordering a grid's columns for a language that reads the other way.

  The VCL half of this works on a TCollection and moves TCollectionItems.
  FireMonkey has neither: a TColumn is a child object of the grid and its
  place is its Index among the grid's children. The reasoning is identical
  and the mechanics are not, which is the usual shape of parity between these
  two frameworks.

  As on the VCL side the order is stated rather than toggled. The designed
  order is captured the first time a grid is seen, the target is recomputed
  from it on every call, and the columns are moved to match - so applying
  twice is indistinguishable from applying once. }
{ The menu bar reads in the language's direction.

  The VCL half of this had to fight the framework: VCL mirrors a menu only
  through TMenu.DoBiDiModeChanged, which gives up unless the machine itself is
  Middle Eastern, and the flag it sets governs how submenus cascade rather
  than the order of the bar. The order had to be reversed by hand there.

  FireMonkey needs no such argument, because it offers no such flag - there is
  nothing that claims to mirror a menu and does something else. A TMenuItem is
  a child object of the menu and its place is its Index, so reversing the bar
  means moving the items, which is what the VCL side ended up doing anyway.

  Stated rather than toggled, for the same reason as everywhere else here: the
  designed order is captured once and the target recomputed from it, so a form
  translated twice looks like a form translated once. }
{ TMainMenu hands its items back as TFmxObject rather than TMenuItem, and
  both the name and the position live at that level, so there is nothing to
  gain by casting down. }
{ Entry fields a right-to-left reader is going to type into.

  The VCL half of this sets BiDiMode to bdRightToLeft, which moves the caret
  to the edge the reader starts from. FireMonkey has no BiDiMode at all, so
  the same outcome is reached by the only lever it offers: the field's text
  alignment. A field left aligned under Arabic puts the first character
  somebody types at the far end of the box from where they are looking.

  Captions are deliberately not touched here. Their alignment is decided by
  the planner, which knows where each one sits and what it labels; overruling
  that at run time would undo a decision made with the whole form in view.
  A field is different - it has a caret rather than a position in a sentence,
  and where the caret starts is a property of the reader, not the layout. }
function IsFMXInputControl(const AObject: TFmxObject): Boolean;
begin
  { TComboEdit and the list controls live in units this one does not use,
    and pulling them in for a type test would widen what every application
    links. The two that matter are here; anything else keeps the alignment
    the planner gave it. }
  Result := (AObject is TCustomEdit) or (AObject is TCustomMemo);
end;

function FMXApplyInputReadingOrder(const AForm: TCommonCustomForm;
  const ARightToLeft: Boolean): Integer;
var
  Applied: Integer;

  procedure Walk(const AObject: TFmxObject);
  var
    Index: Integer;
    Settings: TTextSettings;
    Desired: TTextAlign;
  begin
    if AObject = nil then
      Exit;
    if IsFMXInputControl(AObject) and
      Supports(AObject, ITextSettings) then
    begin
      Settings := (AObject as ITextSettings).TextSettings;
      if Settings <> nil then
      begin
        if ARightToLeft then
          Desired := TTextAlign.Trailing
        else
          Desired := TTextAlign.Leading;
        if Settings.HorzAlign <> Desired then
        begin
          { The style puts its own alignment back unless the setting is taken
            out of its hands first - the same trap as WordWrap above. }
          Settings.HorzAlign := Desired;
          Inc(Applied);
        end;
      end;
    end;
    for Index := 0 to AObject.ChildrenCount - 1 do
      Walk(AObject.Children[Index]);
  end;

begin
  Applied := 0;
  Walk(AForm);
  Result := Applied;
end;

function FMXMenuIdentity(const AItem: TFmxObject): string;
begin
  Result := Trim(AItem.Name);
  if Result <> '' then
    Exit;
  Result := '#' + IntToStr(AItem.Index);
end;

function FMXMainMenuOf(const AForm: TCommonCustomForm;
  out AMenu: TMainMenu): Boolean;
var
  Index: Integer;
  Child: TFmxObject;
begin
  AMenu := nil;
  Result := False;
  if AForm = nil then
    Exit;
  for Index := 0 to AForm.ChildrenCount - 1 do
  begin
    Child := AForm.Children[Index];
    if Child is TMainMenu then
    begin
      AMenu := TMainMenu(Child);
      Exit(AMenu.ItemsCount > 1);
    end;
  end;
end;

function FMXDesignedMenuOrder(const AMenu: TMainMenu;
  const AKey: string): TArray<string>;
var
  Index: Integer;
  Item: TFmxObject;
begin
  if TFMXTranslationApplicator.FDesignedMenus.TryGetValue(AKey, Result) then
    Exit;
  SetLength(Result, AMenu.ItemsCount);
  for Index := 0 to AMenu.ItemsCount - 1 do
  begin
    Item := AMenu.Items[Index];
    Result[Index] := FMXMenuIdentity(Item);
  end;
  TFMXTranslationApplicator.FDesignedMenus.AddOrSetValue(AKey, Result);
end;

function FMXApplyMenuOrder(const AForm: TCommonCustomForm;
  const AFormIdentity: string; const AReversed: Boolean): Boolean;
var
  Menu: TMainMenu;
  Designed, Target, Identities: TArray<string>;
  Items: TArray<TFmxObject>;
  Used: TArray<Boolean>;
  Index, Scan: Integer;
begin
  Result := False;
  if not FMXMainMenuOf(AForm, Menu) then
    Exit;
  Designed := FMXDesignedMenuOrder(Menu, AFormIdentity);
  if Length(Designed) <> Menu.ItemsCount then
    Exit;

  SetLength(Target, Length(Designed));
  for Index := 0 to High(Designed) do
    if AReversed then
      Target[Index] := Designed[High(Designed) - Index]
    else
      Target[Index] := Designed[Index];

  { By reference, because setting Index moves everything else. }
  SetLength(Items, Menu.ItemsCount);
  SetLength(Identities, Menu.ItemsCount);
  SetLength(Used, Menu.ItemsCount);
  for Index := 0 to Menu.ItemsCount - 1 do
  begin
    Items[Index] := Menu.Items[Index];
    Identities[Index] := FMXMenuIdentity(Items[Index]);
  end;

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
end;

function FMXColumnIdentity(const AColumn: TColumn): string;
begin
  { The header first, since it is what the column is called; the name of the
    object next, which survives translation; and the position last. }
  Result := Trim(AColumn.Header);
  if Result <> '' then
    Exit;
  Result := Trim(AColumn.Name);
  if Result <> '' then
    Exit;
  Result := '#' + IntToStr(AColumn.Index);
end;

function FMXGridOf(const AComponent: TComponent;
  out AGrid: TCustomGrid): Boolean;
begin
  AGrid := nil;
  Result := AComponent is TCustomGrid;
  if Result then
  begin
    AGrid := TCustomGrid(AComponent);
    Result := AGrid.ColumnCount > 1;
  end;
end;

function FMXDesignedColumnOrder(const AComponent: TComponent;
  const AKey: string): TArray<string>;
var
  Grid: TCustomGrid;
  Index: Integer;
begin
  if TFMXTranslationApplicator.FDesignedColumns.TryGetValue(AKey, Result) then
    Exit;
  SetLength(Result, 0);
  if not FMXGridOf(AComponent, Grid) then
    Exit;
  SetLength(Result, Grid.ColumnCount);
  for Index := 0 to Grid.ColumnCount - 1 do
    Result[Index] := FMXColumnIdentity(Grid.Columns[Index]);
  TFMXTranslationApplicator.FDesignedColumns.AddOrSetValue(AKey, Result);
end;

function FMXApplyColumnOrder(const AComponent: TComponent;
  const AKey: string; const AReversed: Boolean): Boolean;
var
  Grid: TCustomGrid;
  Designed, Target, Identities: TArray<string>;
  Columns: TArray<TColumn>;
  Used: TArray<Boolean>;
  Index, Scan: Integer;
begin
  Result := False;
  if not FMXGridOf(AComponent, Grid) then
    Exit;
  Designed := FMXDesignedColumnOrder(AComponent, AKey);
  if Length(Designed) <> Grid.ColumnCount then
    { The grid was rebuilt behind us, so the designed order no longer
      describes it. Leaving it alone is the only safe answer. }
    Exit;

  SetLength(Target, Length(Designed));
  for Index := 0 to High(Designed) do
    if AReversed then
      Target[Index] := Designed[High(Designed) - Index]
    else
      Target[Index] := Designed[Index];

  { Held by reference before anything moves: setting Index shifts every other
    column, so a position noted a moment ago names a different one. }
  SetLength(Columns, Grid.ColumnCount);
  SetLength(Identities, Grid.ColumnCount);
  SetLength(Used, Grid.ColumnCount);
  for Index := 0 to Grid.ColumnCount - 1 do
  begin
    Columns[Index] := Grid.Columns[Index];
    Identities[Index] := FMXColumnIdentity(Columns[Index]);
  end;

  for Index := 0 to High(Target) do
    for Scan := 0 to High(Columns) do
    begin
      if Used[Scan] or (Identities[Scan] <> Target[Index]) then
        Continue;
      if Columns[Scan].Index <> Index then
      begin
        Columns[Scan].Index := Index;
        Result := True;
      end;
      Used[Scan] := True;
      Break;
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
  if (AComponent is TControl) and
    (SameText(APropertyName, 'Left') or
     SameText(APropertyName, 'Top') or
     SameText(APropertyName, 'Position.X') or
     SameText(APropertyName, 'Position.Y')) then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue < -100000) or (FloatValue > 100000) then
      Exit;
    if SameText(APropertyName, 'Left') or
      SameText(APropertyName, 'Position.X') then
      TControl(AComponent).Position.X := FloatValue
    else
      TControl(AComponent).Position.Y := FloatValue;
    Exit(True);
  end;
  { Wrapping must go through TextSettings and leave style control, otherwise
    the assignment is accepted and then ignored at paint time. This matters
    most when AutoSize has just been switched off: without real wrapping the
    control keeps its assigned width and clips the translated text. }
  if SameText(APropertyName, 'WordWrap') and
    Supports(AComponent, ITextSettings) then
  begin
    ApplyWordWrapSetting(AComponent, SameText(AValue, 'True'));
    Exit(True);
  end;
  { Which edge the text sits against. FireMonkey keeps it on TextSettings and
    guards it with StyledSettings in exactly the way wrapping and font size
    are guarded, so it is routed the same way: assigned directly it is
    accepted and then overwritten from the style at paint time. }
  if MatchText(APropertyName, ['TextSettings.HorzAlign', 'HorzAlign']) and
    Supports(AComponent, ITextSettings) then
  begin
    Result := ApplyHorzAlignSetting(AComponent, AValue);
    Exit;
  end;
  if SameText(APropertyName, 'FontSize') and
    Supports(AComponent, ITextSettings) then
  begin
    if not TryStrToFloat(AValue, FloatValue, TFormatSettings.Invariant) or
      (FloatValue <= 0) or (FloatValue > 400) then
      Exit;
    ApplyFontSizeSetting(AComponent, FloatValue);
    Exit(True);
  end;
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
    begin
      { A named value: Align becomes Right for a mirrored layout. }
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
  Key: string;
  Pairs: TStringList;
  PairMap: TDictionary<string, string>;
  Script: TStringBuilder;
  SourceText: string;
  TranslatedText: string;

  procedure LogKnownBrowserTerm(const ASourceText: string);
  var
    LogTranslation: string;
  begin
    LogTranslation := '';
    if APack.TryTranslateSource(ASourceText, LogTranslation) or
      APack.TryTranslateDynamicText(ASourceText, LogTranslation) then
      DATRuntimeDebugLog(Format('Browser term "%s" -> "%s"',
        [ASourceText, LogTranslation]))
    else
      DATRuntimeDebugLog(Format('Browser term "%s" has no runtime translation',
        [ASourceText]));
  end;

  procedure AddBrowserPair(const ASourceText, ATranslatedText: string);
  begin
    if (Trim(ASourceText) = '') or (Trim(ATranslatedText) = '') or
      SameText(ASourceText, ATranslatedText) then
      Exit;
    if not PairMap.ContainsKey(ASourceText) then
      PairMap.Add(ASourceText, ATranslatedText);
  end;
begin
  Result := 0;
  if not (AComponent is TCustomWebBrowser) then
    Exit;
  PairMap := TDictionary<string, string>.Create;
  Pairs := TStringList.Create;
  Script := TStringBuilder.Create;
  try
    DATRuntimeDebugLog(Format('ApplyBrowserText start: %s.%s language=%s',
      [AComponent.ClassName, AComponent.Name, APack.LanguageCode]));
    for Key in APack.Sources.Keys do
      if APack.Strings.TryGetValue(Key, TranslatedText) then
      begin
        SourceText := APack.Sources[Key];
        AddBrowserPair(SourceText, TranslatedText);
      end;
    for Candidate in APack.SourceStrings.Keys do
    begin
      TranslatedText := APack.SourceStrings[Candidate];
      AddBrowserPair(Candidate, TranslatedText);
    end;
    for Candidate in APack.SourceTemplates.Keys do
    begin
      TranslatedText := APack.SourceTemplates[Candidate];
      { Format strings belong to code, not browser text nodes. }
      if (Pos('%', Candidate) = 0) and (Pos('%', TranslatedText) = 0) and
        (Trim(Candidate) <> '') and (Trim(TranslatedText) <> '') then
        AddBrowserPair(Candidate, TranslatedText);
    end;
    LogKnownBrowserTerm('Time');
    LogKnownBrowserTerm('Type');
    LogKnownBrowserTerm('Song/Purpose');
    for Candidate in PairMap.Keys do
      Pairs.Add(JavaScriptString(Candidate) + ',' +
        JavaScriptString(PairMap[Candidate]));
    if Pairs.Count = 0 then
    begin
      DATRuntimeDebugLog('ApplyBrowserText stopped: no browser text pairs.');
      Exit;
    end;
    Script.Append('(function(){var p=[');
    for Candidate in Pairs do
    begin
      if Script.Chars[Script.Length - 1] <> '[' then
        Script.Append(',');
      Script.Append('[').Append(Candidate).Append(']');
    end;
    Script.Append('];function trim(s){return String(s).replace(/^\\s+|\\s+$/g,"");}function apply(n){var c=0,i,v,l,r,ch;if(!n){return 0;}if(n.nodeType===3){v=n.nodeValue;for(i=0;i<p.length;i++){if(trim(v)===p[i][0]){l=(v.match(/^\\s*/)||[""])[0];r=(v.match(/\\s*$/)||[""])[0];n.nodeValue=l+p[i][1]+r;c++;break;}}return c;}ch=n.firstChild;while(ch){c+=apply(ch);ch=ch.nextSibling;}return c;}function run(){if(!document.body){return 0;}return apply(document.body);}var tries=0;function retry(){try{run();}catch(e){}tries++;if(tries<40){window.setTimeout(retry,150);}}retry();})();');
    DATRuntimeDebugLog(Format(
      'ApplyBrowserText executing: pairs=%d script length=%d contains Time=%s Type=%s Song/Purpose=%s',
      [Pairs.Count, Script.Length, BoolToStr(Pos('"Time"', Script.ToString) > 0,
      True), BoolToStr(Pos('"Type"', Script.ToString) > 0, True),
      BoolToStr(Pos('"Song/Purpose"', Script.ToString) > 0, True)]));
    try
      TCustomWebBrowser(AComponent).EvaluateJavaScript(Script.ToString);
    except
      on E: Exception do
      begin
        DATRuntimeDebugLog(Format(
          'ApplyBrowserText immediate EvaluateJavaScript failed on %s.%s: %s: %s',
          [AComponent.ClassName, AComponent.Name, E.ClassName, E.Message]));
        { A browser may still be loading when a newly-created dynamic dialog is
          first shown. Translation must never turn that platform race into a
          repeated application error dialog. The retry component below keeps
          applying the same browser-safe script after the platform view settles. }
      end;
    end;
    TBrowserTranslationRetry.Create(TCustomWebBrowser(AComponent),
      Script.ToString);
    Result := Pairs.Count;
  finally
    Script.Free;
    Pairs.Free;
    PairMap.Free;
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
  TranslatedText: string;

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
    if (TranslatedText <> '') and (TranslatedText <> CurrentText) then
    begin
      { Break marks taken out on the way in.

        A heading is offered soft hyphens so a long word can break, and a
        heading never wraps, so the offer is never taken. DirectWrite
        renders the mark as nothing, which is why this shows on the VCL
        side and not here - but a mark that can only ever do harm is not
        worth carrying on either framework, and a heading narrow enough
        to break at one would break mid-word. }
      TStringGrid(AComponent).Columns[ColumnIndex].Header :=
        StringReplace(TranslatedText, SoftHyphenMark, '',
          [rfReplaceAll]);
      Inc(Result);
    end;
    { The cells are deliberately left alone.

      A column heading is interface text: the application chose those words and
      they mean the same thing in every language. What sits under the heading is
      the application's data - song titles, file names, durations, rows read
      from a database - and it belongs to whoever entered it, not to us. A song
      called Angelus is called Angelus in Spanish, and a row reading
      "--Random Music Generator-1--Do Not Delete--" is a marker the application
      matches on by name.

      Translating them corrupted the grid twice over. The words on screen were
      wrong, and because the substitution has no reliable inverse the rows did
      not come back when the original language was chosen again: the developer
      saw Spanish song titles in an English application with no way to undo it. }
  end;
end;

function ApplyConservativeTextFit(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack; const AFormIdentity: string): Integer;
const
  HorizontalPadding = 10;
  MinimumButtonWidth = 96;
  MaximumButtonWidth = 240;
  MinimumLabelWidth = 42;
  MaximumLabelWidth = 420;
  MinimumLabelHeight = 22;
  MaximumLabelHeight = 120;
var
  ComponentIndex: Integer;

  function MeasuredTextWidth(const AText: string; const AFont: TFont): Single;
  var
    CleanText: string;
    Layout: TTextLayout;
  begin
    CleanText := Trim(AText);
    if CleanText = '' then
      Exit(0);
    if AFont = nil then
      Exit(Length(CleanText) * 7.4 + 20);
    Layout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      Layout.BeginUpdate;
      Layout.Text := CleanText;
      Layout.Font := AFont;
      Layout.WordWrap := False;
      Layout.EndUpdate;
      Result := Layout.Width + 20;
    finally
      Layout.Free;
    end;
  end;

  function ParentClientWidth(const AControl: TControl): Single;
  begin
    Result := 0;
    if AControl = nil then
      Exit;
    if (AControl.Parent <> nil) and (AControl.Parent is TControl) then
      Result := TControl(AControl.Parent).Width
    else if AForm <> nil then
      Result := AForm.Width;
  end;

  function RightEdge(const AControl: TControl): Single;
  begin
    if AControl = nil then
      Exit(0);
    Result := AControl.Position.X + AControl.Width;
  end;

  function BottomEdge(const AControl: TControl): Single;
  begin
    if AControl = nil then
      Exit(0);
    Result := AControl.Position.Y + AControl.Height;
  end;

  function VerticalOverlap(const ALeft, ARight: TControl): Single;
  begin
    if (ALeft = nil) or (ARight = nil) then
      Exit(0);
    Result := Min(BottomEdge(ALeft), BottomEdge(ARight)) -
      Max(ALeft.Position.Y, ARight.Position.Y);
    if Result < 0 then
      Result := 0;
  end;

  function AvailableWidthToParentRight(const AControl: TControl): Single;
  var
    ParentWidth: Single;
  begin
    Result := AControl.Width;
    ParentWidth := ParentClientWidth(AControl);
    if ParentWidth > 0 then
      Result := Max(MinimumLabelWidth,
        ParentWidth - AControl.Position.X - HorizontalPadding);
  end;

  function NearestSameRowRightEdgeLimit(const AControl: TControl): Single;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    CandidateIndex: Integer;
    CandidateLeft: Single;
    BestLeft: Single;
  begin
    Result := AvailableWidthToParentRight(AControl);
    BestLeft := MaxSingle;
    for CandidateIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Candidate := AForm.Components[CandidateIndex];
      if (Candidate = AControl) or not (Candidate is TControl) then
        Continue;
      CandidateControl := TControl(Candidate);
      if (CandidateControl.Parent <> AControl.Parent) or
        (CandidateControl.Align <> TAlignLayout.None) or
        not CandidateControl.Visible then
        Continue;
      CandidateLeft := CandidateControl.Position.X;
      if (CandidateLeft <= AControl.Position.X + 2) or
        (CandidateLeft >= BestLeft) then
        Continue;
      if VerticalOverlap(AControl, CandidateControl) < 4 then
        Continue;
      BestLeft := CandidateLeft;
    end;
    if BestLeft < MaxSingle then
      Result := Max(MinimumLabelWidth, BestLeft - AControl.Position.X -
        HorizontalPadding);
  end;

  function SetBooleanPropertyIfSupported(const AComponent: TComponent;
    const APropertyName: string; const AValue: Boolean): Boolean;
  var
    NewValue: NativeInt;
    PropertyInfo: PPropInfo;
  begin
    Result := False;
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, APropertyName,
      [tkEnumeration]);
    if PropertyInfo = nil then
      Exit;
    if AValue then
      NewValue := 1
    else
      NewValue := 0;
    if GetOrdProp(AComponent, PropertyInfo) <> NewValue then
    begin
      SetOrdProp(AComponent, PropertyInfo, NewValue);
      Result := True;
    end;
  end;

  function SetWordWrapIfSupported(const AComponent: TComponent): Boolean;
  begin
    Result := ApplyWordWrapSetting(AComponent, True) or
      SetBooleanPropertyIfSupported(AComponent, 'WordWrap', True);
  end;

  function DisableAutoSizeIfSupported(const AComponent: TComponent): Boolean;
  begin
    Result := SetBooleanPropertyIfSupported(AComponent, 'AutoSize', False);
  end;

  function FitWrappedHeight(const AText: string; const AFont: TFont;
    const AWidth: Single; const AMinimumHeight, AMaximumHeight: Single): Single;
  var
    Lines: Integer;
  begin
    Lines := Ceil(MeasuredTextWidth(AText, AFont) / Max(40, AWidth));
    Result := Min(AMaximumHeight, Max(AMinimumHeight, Lines * 18 + 6));
  end;

  function ComponentDisplayText(const AComponent: TComponent): string;
  begin
    Result := '';
    if AComponent is TLabel then
      Result := TLabel(AComponent).Text
    else if AComponent is TButton then
      Result := TButton(AComponent).Text
    else if AComponent is TCheckBox then
      Result := TCheckBox(AComponent).Text
    else if AComponent is TTextControl then
      Result := TTextControl(AComponent).Text;
  end;

  function ComponentFont(const AComponent: TComponent): TFont;
  begin
    Result := nil;
    if AComponent is TLabel then
      Result := TLabel(AComponent).Font
    else if AComponent is TButton then
      Result := TButton(AComponent).Font
    else if AComponent is TCheckBox then
      Result := TCheckBox(AComponent).Font
    else if AComponent is TTextControl then
      Result := TTextControl(AComponent).Font;
  end;

  function HasExplicitLayoutRule(const AComponent: TComponent): Boolean;
  var
    Rule: TRuntimeLayoutRule;
  begin
    Result := False;
    if (APack = nil) or (AComponent = nil) or (Trim(AComponent.Name) = '') then
      Exit;
    { Any rule at all, not only the four that name a size or a place.

      This guard exists so the fitting below leaves alone any control the
      analyser has already decided about. Counting only geometry meant a
      control the analyser had spoken about in other terms looked untouched:
      a caption given wrapping, or a button given a size, still fell to the
      fitting, which measures the text afresh and reaches its own conclusion.

      The two disagree, and the fitting runs second. A caption told to stay on
      one line was clamped to the gap between it and the box overlapping its
      row - twenty seven pixels - and wrapped into a column one word wide. A
      button told to take a smaller size was widened instead until it covered
      the caption beside it. In both cases the plan was right and was quietly
      overruled, which is why correcting the plan changed nothing on screen. }
    for Rule in APack.LayoutRules do
      if SameText(Rule.FormName, AFormIdentity) and
        SameText(Rule.ComponentName, AComponent.Name) and
        IsRuntimeLayoutProperty(Rule.PropertyName) then
        Exit(True);
  end;

  function FitButton(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    MaxWidth: Single;
    NeededWidth: Single;
    NewHeight: Single;
    NewWidth: Single;
  begin
    Result := 0;
    NeededWidth := MeasuredTextWidth(AText, ComponentFont(AComponent));
    MaxWidth := Min(MaximumButtonWidth, AvailableWidthToParentRight(AControl));
    NewWidth := Min(MaxWidth, Max(MinimumButtonWidth, NeededWidth));
    if NewWidth > AControl.Width + 4 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;
    if NeededWidth > AControl.Width + 8 then
    begin
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      NewHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
        AControl.Width, AControl.Height, 56);
      if NewHeight > AControl.Height + 2 then
      begin
        AControl.Height := NewHeight;
        Inc(Result);
      end;
    end;
  end;

  function FitCheckBox(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    MaxWidth: Single;
    NeededHeight: Single;
    NeededWidth: Single;
    NewWidth: Single;
  begin
    Result := 0;
    NeededWidth := MeasuredTextWidth(AText, ComponentFont(AComponent)) + 22;
    MaxWidth := Min(MaximumLabelWidth, NearestSameRowRightEdgeLimit(AControl));
    NewWidth := Min(MaxWidth, Max(AControl.Width, NeededWidth));
    if NewWidth > AControl.Width + 4 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;
    if AControl.Width > MaxWidth + 2 then
    begin
      AControl.Width := MaxWidth;
      Inc(Result);
    end;
    if NeededWidth > AControl.Width + 8 then
    begin
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      NeededHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
        AControl.Width, MinimumLabelHeight, MaximumLabelHeight);
      if NeededHeight > AControl.Height + 2 then
      begin
        AControl.Height := NeededHeight;
        Inc(Result);
      end;
    end;
  end;

  function FitLabel(const AComponent: TComponent; const AControl: TControl;
    const AText: string): Integer;
  var
    HasRightNeighbor: Boolean;
    MaxWidth: Single;
    NeededHeight: Single;
    NeededWidth: Single;
    NewWidth: Single;
    ParentWidth: Single;
    RightLimitedWidth: Single;
  begin
    Result := 0;
    NeededWidth := MeasuredTextWidth(AText, ComponentFont(AComponent));
    ParentWidth := ParentClientWidth(AControl);
    RightLimitedWidth := NearestSameRowRightEdgeLimit(AControl);
    HasRightNeighbor := RightLimitedWidth < AvailableWidthToParentRight(AControl) - 1;

    MaxWidth := Min(MaximumLabelWidth, RightLimitedWidth);
    if ParentWidth > 0 then
      MaxWidth := Min(MaxWidth, ParentWidth - AControl.Position.X -
        HorizontalPadding);
    MaxWidth := Max(MinimumLabelWidth, MaxWidth);

    if (NeededWidth <= AControl.Width + 6) and
      (RightEdge(AControl) <= AControl.Position.X + MaxWidth + 1) then
      Exit;

    if DisableAutoSizeIfSupported(AComponent) then
      Inc(Result);
    if SetWordWrapIfSupported(AComponent) then
      Inc(Result);

    if HasRightNeighbor then
      NewWidth := MaxWidth
    else
      NewWidth := Min(MaxWidth, Max(AControl.Width, NeededWidth));
    NewWidth := Max(MinimumLabelWidth, NewWidth);

    if Abs(AControl.Width - NewWidth) > 2 then
    begin
      AControl.Width := NewWidth;
      Inc(Result);
    end;

    NeededHeight := FitWrappedHeight(AText, ComponentFont(AComponent),
      AControl.Width, MinimumLabelHeight, MaximumLabelHeight);
    if NeededHeight > AControl.Height + 2 then
    begin
      AControl.Height := NeededHeight;
      Inc(Result);
    end;
  end;

  function HorizontalOverlapRatio(const ALeft, ARight: TControl): Single;
  var
    MinWidth: Single;
    OverlapWidth: Single;
  begin
    OverlapWidth := Min(RightEdge(ALeft), RightEdge(ARight)) -
      Max(ALeft.Position.X, ARight.Position.X);
    if OverlapWidth <= 0 then
      Exit(0);
    MinWidth := Min(ALeft.Width, ARight.Width);
    if MinWidth <= 0 then
      Exit(0);
    Result := OverlapWidth / MinWidth;
  end;

  { A control that grows taller (because its translated text wrapped to more
    lines) can push its own bottom edge into whatever control was originally
    resting directly beneath it. This does not rearrange the form: it only
    shifts a control that was already touching the grown control's original
    bottom edge, straight down by exactly the growth amount, preserving the
    original gap. It recurses so a short stack (label -> field -> note, all
    touching) moves together, but never touches a control that was not
    already adjacent. }
  function CascadeStackedGrowth(const AControl: TControl; const AOldBottom,
    ADelta: Single; const AVisited: TList<TControl>): Integer;
  const
    StackTouchTolerance = 6;
    MinimumHorizontalOverlapRatio = 0.2;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    CandidateIndex: Integer;
    CandidateOldBottom: Single;
  begin
    Result := 0;
    for CandidateIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Candidate := AForm.Components[CandidateIndex];
      if (Candidate = AControl) or not (Candidate is TControl) then
        Continue;
      CandidateControl := TControl(Candidate);
      if AVisited.IndexOf(CandidateControl) >= 0 then
        Continue;
      if (CandidateControl.Parent <> AControl.Parent) or
        (CandidateControl.Align <> TAlignLayout.None) or
        not CandidateControl.Visible then
        Continue;
      if Abs(CandidateControl.Position.Y - AOldBottom) > StackTouchTolerance then
        Continue;
      if HorizontalOverlapRatio(AControl, CandidateControl) <
        MinimumHorizontalOverlapRatio then
        Continue;
      AVisited.Add(CandidateControl);
      CandidateOldBottom := BottomEdge(CandidateControl);
      CandidateControl.Position.Y := CandidateControl.Position.Y + ADelta;
      Inc(Result);
      Inc(Result, CascadeStackedGrowth(CandidateControl, CandidateOldBottom,
        ADelta, AVisited));
    end;
  end;

  function FitComponent(const AComponent: TComponent): Integer;
  var
    Control: TControl;
    CurrentText: string;
    GrowthDelta: Single;
    OldBottom: Single;
    Visited: TList<TControl>;
  begin
    Result := 0;
    if not (AComponent is TControl) then
      Exit;
    Control := TControl(AComponent);
    if (Control.Align <> TAlignLayout.None) or not Control.Visible then
      Exit;
    if not ((AComponent is TLabel) or (AComponent is TButton) or
      (AComponent is TCheckBox) or (AComponent is TTextControl)) then
      Exit;
    if HasExplicitLayoutRule(AComponent) then
      Exit;
    CurrentText := Trim(ComponentDisplayText(AComponent));
    if CurrentText = '' then
      Exit;

    OldBottom := BottomEdge(Control);
    if AComponent is TButton then
      Result := FitButton(AComponent, Control, CurrentText)
    else if AComponent is TCheckBox then
      Result := FitCheckBox(AComponent, Control, CurrentText)
    else if AComponent is TLabel then
      Result := FitLabel(AComponent, Control, CurrentText);

    GrowthDelta := BottomEdge(Control) - OldBottom;
    if GrowthDelta > 1 then
    begin
      Visited := TList<TControl>.Create;
      try
        Visited.Add(Control);
        Inc(Result, CascadeStackedGrowth(Control, OldBottom, GrowthDelta,
          Visited));
      finally
        Visited.Free;
      end;
    end;
  end;

  function IsInputLikeControl(const AComponent: TComponent): Boolean;
  begin
    Result :=
      (AComponent is TCustomEdit) or
      ContainsText(AComponent.ClassName, 'Combo') or
      ContainsText(AComponent.ClassName, 'Date') or
      ContainsText(AComponent.ClassName, 'Time') or
      ContainsText(AComponent.ClassName, 'Spin') or
      ContainsText(AComponent.ClassName, 'Number');
  end;

  function SameTightRow(const ALeft, ARight: TControl): Boolean;
  var
    LeftCenter: Single;
    RightCenter: Single;
  begin
    LeftCenter := ALeft.Position.Y + ALeft.Height / 2;
    RightCenter := ARight.Position.Y + ARight.Height / 2;
    Result := Abs(LeftCenter - RightCenter) <=
      Max(12, Max(ALeft.Height, ARight.Height) * 0.65);
  end;

  function ApplyLabelInputGuards: Integer;
  const
    FieldGap = 8;
    MinimumReadableLabelWidth = 60;
  var
    Candidate: TComponent;
    CandidateControl: TControl;
    Component: TComponent;
    ComponentControl: TControl;
    ComponentIndex: Integer;
    CandidateIndex: Integer;
    BestField: TControl;
    BestFieldLeft: Single;
    NewHeight: Single;
    NewWidth: Single;
    TextValue: string;
  begin
    Result := 0;
    for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    begin
      Component := AForm.Components[ComponentIndex];
      if not (Component is TLabel) or not (Component is TControl) then
        Continue;
      if HasExplicitLayoutRule(Component) then
        Continue;
      ComponentControl := TControl(Component);
      if (ComponentControl.Align <> TAlignLayout.None) or
        not ComponentControl.Visible then
        Continue;
      TextValue := Trim(ComponentDisplayText(Component));
      if TextValue = '' then
        Continue;

      BestField := nil;
      BestFieldLeft := MaxSingle;
      for CandidateIndex := 0 to AForm.ComponentCount - 1 do
      begin
        Candidate := AForm.Components[CandidateIndex];
        if (Candidate = Component) or not IsInputLikeControl(Candidate) or
          not (Candidate is TControl) then
          Continue;
        CandidateControl := TControl(Candidate);
        if (CandidateControl.Parent <> ComponentControl.Parent) or
          (CandidateControl.Align <> TAlignLayout.None) or
          not CandidateControl.Visible then
          Continue;
        if CandidateControl.Position.X <= ComponentControl.Position.X then
          Continue;
        if not SameTightRow(ComponentControl, CandidateControl) then
          Continue;
        if CandidateControl.Position.X < BestFieldLeft then
        begin
          BestField := CandidateControl;
          BestFieldLeft := CandidateControl.Position.X;
        end;
      end;

      if BestField = nil then
        Continue;
      NewWidth := BestField.Position.X - ComponentControl.Position.X - FieldGap;
      if NewWidth < MinimumReadableLabelWidth then
        Continue;
      if RightEdge(ComponentControl) > BestField.Position.X - FieldGap then
      begin
        if DisableAutoSizeIfSupported(Component) then
          Inc(Result);
        if SetWordWrapIfSupported(Component) then
          Inc(Result);
        if Abs(ComponentControl.Width - NewWidth) > 2 then
        begin
          ComponentControl.Width := NewWidth;
          Inc(Result);
        end;
        NewHeight := FitWrappedHeight(TextValue, ComponentFont(Component),
          ComponentControl.Width, MinimumLabelHeight, MaximumLabelHeight);
        if NewHeight > ComponentControl.Height + 2 then
        begin
          ComponentControl.Height := NewHeight;
          Inc(Result);
        end;
      end;
    end;
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    Inc(Result, FitComponent(AForm.Components[ComponentIndex]));
  Inc(Result, ApplyLabelInputGuards);
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

{ A grid heading, whichever way it arrived, carries no break marks.

  A translation of a long word is offered soft hyphens so it can break, and
  prose is right to keep them. A heading is not prose: it never wraps, so the
  offer is never taken, and what is left is a mark the text engine still has to
  do something with. GDI draws it, which is how an Italian heading came to read
  "Data di ripro-du-zione" on the screen.

  Only headings are stripped. A wrapping paragraph still needs its break
  points. }
function HeadingWithoutBreakMarks(const APropertyName,
  AText: string): string;
begin
  if SameText(APropertyName, 'Header') then
    Result := StringReplace(AText, SoftHyphenMark, '', [rfReplaceAll])
  else
    Result := AText;
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
    SetStrProp(AComponent, PropertyInfo,
      HeadingWithoutBreakMarks(APropertyName, TranslatedText));
    Result := True;
  end;
  if Result then
    Exit;
  if APack.TryTranslateDynamicText(CurrentText, TranslatedText) and
    (TranslatedText <> CurrentText) then
  begin
    SetStrProp(AComponent, PropertyInfo,
      HeadingWithoutBreakMarks(APropertyName, TranslatedText));
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

{ True when this component publishes AutoSize, with its current value. It is
  reached through run-time type information because the property belongs to
  several unrelated classes rather than to a common ancestor. }
function TryReadAutoSize(const AComponent: TComponent;
  out AValue: Boolean): Boolean;
var
  PropertyInfo: PPropInfo;
begin
  Result := False;
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'AutoSize');
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  AValue := GetOrdProp(AComponent, PropertyInfo) <> 0;
  Result := True;
end;

procedure WriteAutoSize(const AComponent: TComponent; const AValue: Boolean);
var
  PropertyInfo: PPropInfo;
begin
  if AComponent = nil then
    Exit;
  PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'AutoSize');
  if (PropertyInfo = nil) or
    (PropertyInfo.PropType^.Kind <> tkEnumeration) then
    Exit;
  SetOrdProp(AComponent, PropertyInfo, Ord(AValue));
end;

class procedure TFMXTranslationApplicator.SnapshotOriginalGeometry(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;

  procedure SnapshotTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Key: string;
    Settings: ITextSettings;
    Snapshot: TDATControlSnapshot;
    StyledSettings: TStyledSettings;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    { Taken once, before the first language is applied. A second language must
      not overwrite it, or the original would quietly become whichever
      translation happened to run first. }
    if (Key <> '') and (AComponent is TControl) and
      not FOriginalGeometry.ContainsKey(Key) then
    begin
      Control := TControl(AComponent);
      Snapshot := Default(TDATControlSnapshot);
      { An aligned control is placed by its parent, so its position is not ours
        to remember or to give back. Its size still is. }
      Snapshot.HasPosition := Control.Align = TAlignLayout.None;
      Snapshot.Position := TPointF.Create(Control.Position.X,
        Control.Position.Y);
      Snapshot.Size := TPointF.Create(Control.Width, Control.Height);
      Snapshot.HasTextSettings := AsTextSettings(AComponent, Settings);
      if Snapshot.HasTextSettings then
      begin
        Snapshot.FontSize := Settings.TextSettings.Font.Size;
        Snapshot.FontColor := Cardinal(Settings.TextSettings.FontColor);
        Snapshot.WordWrap := Settings.TextSettings.WordWrap;
        Snapshot.Trimming := Byte(Settings.TextSettings.Trimming);
        StyledSettings := Settings.StyledSettings;
        Snapshot.StyledSettings := Byte(StyledSettings);
      end;
      Snapshot.HasAutoSize := TryReadAutoSize(AComponent, Snapshot.AutoSize);
      Snapshot.Align := Control.Align;
      Snapshot.Anchors := ReadAnchorsText(AComponent);
      if Snapshot.HasTextSettings then
        Snapshot.HorzAlign := Byte(Settings.TextSettings.HorzAlign);
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

class function TFMXTranslationApplicator.RestoreOriginalGeometry(
  const AForm: TCommonCustomForm; const AFormIdentity: string): Integer;
var
  ComponentIndex: Integer;
  Restored: Integer;

  procedure RestoreTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Control: TControl;
    Key: string;
    Settings: ITextSettings;
    Snapshot: TDATControlSnapshot;
    StyledSettings: TStyledSettings;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    if (Key <> '') and (AComponent is TControl) and
      FOriginalGeometry.TryGetValue(Key, Snapshot) then
    begin
      Control := TControl(AComponent);
      { Order matters here for the same reason it matters when applying. A
        control that sizes itself will not accept a width, so automatic sizing
        is switched off first and put back at the end; and the text settings go
        on before the size, because both the size and the wrapping are read
        when the control lays its text out. }
      if Snapshot.HasAutoSize then
        WriteAutoSize(AComponent, False);
      if Snapshot.HasTextSettings and AsTextSettings(AComponent, Settings) then
      begin
        StyledSettings := TStyledSettings(Snapshot.StyledSettings);
        Settings.StyledSettings := StyledSettings;
        Settings.TextSettings.Font.Size := Snapshot.FontSize;
        Settings.TextSettings.FontColor := TAlphaColor(Snapshot.FontColor);
        Settings.TextSettings.WordWrap := Snapshot.WordWrap;
        Settings.TextSettings.Trimming := TTextTrimming(Snapshot.Trimming);
        Settings.TextSettings.HorzAlign := TTextAlign(Snapshot.HorzAlign);
        Inc(Restored);
      end;
      if not SameValue(Control.Width, Snapshot.Size.X, 0.5) or
        not SameValue(Control.Height, Snapshot.Size.Y, 0.5) then
      begin
        Control.SetBounds(Control.Position.X, Control.Position.Y,
          Snapshot.Size.X, Snapshot.Size.Y);
        Inc(Restored);
      end;
      if Snapshot.HasPosition and
        (not SameValue(Control.Position.X, Snapshot.Position.X, 0.5) or
         not SameValue(Control.Position.Y, Snapshot.Position.Y, 0.5)) then
      begin
        Control.Position.X := Snapshot.Position.X;
        Control.Position.Y := Snapshot.Position.Y;
        Inc(Restored);
      end;
      { The mirror, undone. }
      if Control.Align <> Snapshot.Align then
      begin
        Control.Align := Snapshot.Align;
        Inc(Restored);
      end;
      if (Snapshot.Anchors <> '') and
        (ReadAnchorsText(AComponent) <> Snapshot.Anchors) then
      begin
        WriteAnchorsText(AComponent, Snapshot.Anchors);
        Inc(Restored);
      end;
      if Snapshot.HasAutoSize then
        WriteAutoSize(AComponent, Snapshot.AutoSize);
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
        { Nothing to restore: the cells were never translated. See the note
          beside the applying pass. }
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
  for PropertyName in TextProperties do
    if RestoreSourceTextProperty(FormIdentity, AForm, AForm, PropertyName,
      APack) then
      Inc(Result);
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
    RestoreComponentTree(AForm.Components[ComponentIndex]);
  Inc(Result, ApplyLayoutToForm(AForm, APack, FormIdentity, False));
  { Last, and after the text is back. The rules above can only speak for
    controls the analyser wrote a rule for, and their idea of the original is
    whatever the form file said when it was scanned. The snapshot is the form
    as it actually was, covers every control, and therefore has the final word
    - including over anything the run-time fitting changed on a control no rule
    mentions, which nothing else can undo. It is applied after the text because
    a control that sizes itself resizes when its text changes. }
  Inc(Result, RestoreOriginalGeometry(AForm, FormIdentity));
end;

{ A caption the application centred itself stays centred.

  The FireMonkey counterpart of the VCL pass of the same name, and it exists
  for the same reason: a heading positioned by the program rather than by the
  designer must not be moved by the analyser, but the arithmetic that placed
  it used the width the caption had before it was translated. Leaving the
  position alone while the width changes underneath it leaves the heading as
  far off centre as the translation is longer.

  Nothing decides to centre anything here either. A control whose snapshot
  sits centred in its parent was centred by somebody, and the same arithmetic
  is redone with the width the caption now has. }
class procedure TFMXTranslationApplicator.RecentreSelfPlacedText(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
const
  CentreTolerance = 3;
var
  Component: TComponent;
  Control: TControl;
  ParentWidth: Single;
  Snapshot: TDATControlSnapshot;
  WasCentre, Wanted: Single;
begin
  if (AForm = nil) or (FOriginalGeometry = nil) then
    Exit;
  for Component in AForm do
  begin
    if not (Component is TControl) or (Component.Name = '') then
      Continue;
    Control := TControl(Component);
    if Control.ParentControl = nil then
      Continue;
    if not ContainsText(Control.ClassName, 'Label') then
      Continue;
    if not FOriginalGeometry.TryGetValue(
      AFormIdentity + '.' + Component.Name, Snapshot) then
      Continue;
    if not Snapshot.HasPosition then
      Continue;
    ParentWidth := Control.ParentControl.Width;
    if ParentWidth <= 0 then
      Continue;
    WasCentre := Snapshot.Position.X + Snapshot.Size.X / 2;
    if Abs(WasCentre - ParentWidth / 2) > CentreTolerance then
      Continue;
    if Abs(Control.Width - Snapshot.Size.X) < 0.5 then
      Continue;
    Wanted := (ParentWidth - Control.Width) / 2;
    if Wanted < 0 then
      Wanted := 0;
    Control.Position.X := Wanted;
  end;
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
      { Browser-backed HTML is text, not layout. Dynamic dialogs often contain
        no designer-authored form file, so their browser text must be applied
        whenever the language manager sees the browser component. }
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
  SnapshotOriginalGeometry(AForm, FormIdentity);
  { Back to the form as it was drawn before anything is applied, exactly as
    the VCL applicator does.

    Without this each language inherits whatever the last one changed, and a
    rule that simply is not present in the new pack has nothing to undo it.
    Going from Hebrew to Spanish left the Spanish form still mirrored: the
    Spanish pack says nothing about Align because Spanish needs nothing said,
    and silence cannot put an edge back. }
  RestoreOriginalGeometry(AForm, FormIdentity);
  { The menu bar, in the direction the language reads.

    Both directions go through the one call, so a form returning to its
    source language is put back rather than left wherever it happened to
    be. The VCL side does the same thing for the same reason, by different
    means - it has a framework flag to work around, and this does not. }
  FMXApplyMenuOrder(AForm, FormIdentity,
    SameText(Trim(APack.TextDirection), 'rtl'));
  { Where the caret starts, which is the reader's property rather than the
    layout's. VCL reaches this through BiDiMode; FireMonkey has none, so it
    is reached through the field's own alignment. }
  FMXApplyInputReadingOrder(AForm,
    SameText(Trim(APack.TextDirection), 'rtl'));
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
    { Keep this fitting pass deliberately narrow: no source edits, no movement,
      and no broad rearrangement. It only gives translated labels/buttons a
      little breathing room when the text already came from the language pack. }
    Inc(Result, ApplyConservativeTextFit(AForm, APack, FormIdentity));
    Inc(Result, ApplyFontColorsToForm(AForm, APack, FormIdentity));
    { Last, because it reads the widths every pass above settled. }
    RecentreSelfPlacedText(AForm, FormIdentity);
  finally
    VisitedComponents.Free;
    if APreserveControlState and (SavedFocusedControl <> nil) then
      AForm.Focused := SavedFocusedControl;
  end;
end;

class function TFMXTranslationApplicator.ApplyOverrides(
  const AForm: TCommonCustomForm; const AOverrides: TLayoutOverrides;
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
    { Font size first, for the same reason as under the VCL: it moves
      the bounds of a control that sizes itself. }
    if Entry.HasFontSize and (Entry.FontSize > 0) then
      if ApplyFontSizeSetting(Control, Entry.FontSize) then
        Inc(Result);
    { The same two decisions as the VCL, in FireMonkey's spelling. }
    if Entry.HasSize then
    begin
      Control.Size.Size := TSizeF.Create(Entry.Width, Entry.Height);
      Inc(Result);
    end;
    if Entry.HasPosition then
    begin
      Control.Position.X := Entry.Left;
      Control.Position.Y := Entry.Top;
      Inc(Result);
    end;
  end;
end;

class function TFMXTranslationApplicator.ApplyLayoutToForm(
  const AForm: TCommonCustomForm; const APack: TRuntimeLanguagePack;
  const AFormIdentity: string;
  const AUseTranslatedValues: Boolean): Integer;
const
  { Order matters. AutoSize must be cleared before any width or height is
    assigned, because an auto-sizing FMX text control recomputes its own
    bounds from a single line of text and discards an assigned Width.
    WordWrap follows, so the height that is applied afterwards describes
    wrapped text. Positions are applied last, once every control has its
    final size. }
  OrderedLayoutProperties: array[0..10] of string = (
    'AutoSize', 'FontSize', 'WordWrap',
    { Mirroring, before the geometry, for the same reason as under the VCL. }
    'TextSettings.HorzAlign', 'Align',
    'Width', 'Height', 'Position.X', 'Position.Y',
    'Anchors',
    { Column order last of all, as under the VCL: every width above names a
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

  function IsSafeRuntimeLayoutProperty(const APropertyName: string): Boolean;
  begin
    Result := IsRuntimeLayoutProperty(APropertyName);
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  { The review analyser resolves sizes and positions together against one
    planned model, so the rules for a form describe a single coherent layout.
    Applying only part of that model is what leaves controls overlapping:
    a width means nothing while AutoSize is still on, and a widened control
    still collides with its neighbour unless the neighbour also moves. }
  for OrderedProperty in OrderedLayoutProperties do
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    if not SameText(Rule.PropertyName, OrderedProperty) then
      Continue;
    if not IsSafeRuntimeLayoutProperty(Rule.PropertyName) then
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
    if SameText(Rule.PropertyName, 'ColumnOrder') then
    begin
      { Both directions through one call: asking for the designed order is
        as much an instruction as asking for the reverse of it. }
      if FMXApplyColumnOrder(Component,
        AFormIdentity + '.' + Component.Name,
        SameText(Trim(Value), 'reversed')) then
        Inc(Result);
    end
    else if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

initialization
  TFMXTranslationApplicator.FOriginalGeometry :=
    TDictionary<string, TDATControlSnapshot>.Create;
  TFMXTranslationApplicator.FDesignedColumns :=
    TDictionary<string, TArray<string>>.Create;
  TFMXTranslationApplicator.FDesignedMenus :=
    TDictionary<string, TArray<string>>.Create;

finalization
  TFMXTranslationApplicator.FOriginalGeometry.Free;
  TFMXTranslationApplicator.FOriginalGeometry := nil;
  TFMXTranslationApplicator.FDesignedColumns.Free;
  TFMXTranslationApplicator.FDesignedColumns := nil;
  TFMXTranslationApplicator.FDesignedMenus.Free;
  TFMXTranslationApplicator.FDesignedMenus := nil;

end.

