unit DAT.Runtime.FMX;

interface

uses
  System.Generics.Collections,
  System.Types,
  FMX.Forms,
  DAT.Runtime.LanguagePack;

type
  TFMXTranslationApplicator = class
  private
    class var FOriginalPositions: TDictionary<string, TPointF>;
    class procedure SnapshotOriginalPositions(const AForm: TCommonCustomForm;
      const AFormIdentity: string); static;
    class procedure RestoreOriginalPositions(const AForm: TCommonCustomForm;
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
  System.IOUtils,
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
  FMX.StdCtrls,
  FMX.Types,
  FMX.WebBrowser;

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
  RowIndex: Integer;
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

function ApplyConservativeTextFit(const AForm: TCommonCustomForm;
  const APack: TRuntimeLanguagePack): Integer;
const
  MinimumButtonWidth = 96;
  MaximumButtonWidth = 220;
  MinimumLabelHeight = 22;
  MaximumLabelHeight = 86;
var
  ComponentIndex: Integer;
  SourceText: string;

  function EstimatedTextWidth(const AText: string): Single;
  begin
    Result := Max(0, Length(Trim(AText)) * 7.4 + 20);
  end;

  function AvailableWidth(const AControl: TControl): Single;
  begin
    Result := 0;
    if AControl = nil then
      Exit;
    if (AControl.Parent <> nil) and (AControl.Parent is TControl) then
      Result := TControl(AControl.Parent).Width - AControl.Position.X - 12
    else if AForm <> nil then
      Result := AForm.Width - AControl.Position.X - 12;
    if Result < AControl.Width then
      Result := AControl.Width;
  end;

  function SetWordWrapIfSupported(const AComponent: TComponent): Boolean;
  var
    PropertyInfo: PPropInfo;
  begin
    Result := False;
    PropertyInfo := GetPropInfo(AComponent.ClassInfo, 'WordWrap',
      [tkEnumeration]);
    if PropertyInfo = nil then
      Exit;
    if GetOrdProp(AComponent, PropertyInfo) = 0 then
    begin
      SetOrdProp(AComponent, PropertyInfo, 1);
      Result := True;
    end;
  end;

  function FitComponent(const AComponent: TComponent): Integer;
  var
    Control: TControl;
    CurrentText: string;
    CurrentWidth: Single;
    MaxWidth: Single;
    NeededHeight: Single;
    NeededWidth: Single;
    NewWidth: Single;
  begin
    Result := 0;
    if not (AComponent is TTextControl) or not (AComponent is TControl) then
      Exit;
    Control := TControl(AComponent);
    if Control.Align <> TAlignLayout.None then
      Exit;
    CurrentText := Trim(TTextControl(AComponent).Text);
    if CurrentText = '' then
      Exit;
    if not APack.TryRestoreDynamicText(CurrentText, SourceText) then
      Exit;
    CurrentWidth := Control.Width;
    NeededWidth := EstimatedTextWidth(CurrentText);
    if NeededWidth <= CurrentWidth + 6 then
      Exit;
    MaxWidth := AvailableWidth(Control);
    if AComponent is TButton then
    begin
      NewWidth := Min(Max(NeededWidth, MinimumButtonWidth),
        Min(MaxWidth, MaximumButtonWidth));
      if NewWidth > CurrentWidth + 4 then
      begin
        Control.Width := NewWidth;
        Inc(Result);
      end;
      Exit;
    end;
    if AComponent is TLabel then
    begin
      if SetWordWrapIfSupported(AComponent) then
        Inc(Result);
      NeededHeight := Min(MaximumLabelHeight,
        Max(MinimumLabelHeight, Ceil(NeededWidth / Max(40, CurrentWidth)) * 20));
      if NeededHeight > Control.Height + 2 then
      begin
        Control.Height := NeededHeight;
        Inc(Result);
      end;
      if (CurrentWidth < 80) and (MaxWidth > CurrentWidth + 20) then
      begin
        NewWidth := Min(MaxWidth, Min(160, NeededWidth));
        if NewWidth > CurrentWidth + 4 then
        begin
          Control.Width := NewWidth;
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

class procedure TFMXTranslationApplicator.SnapshotOriginalPositions(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;
  Component: TComponent;
  Key: string;

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
      not FOriginalPositions.ContainsKey(Key) then
      FOriginalPositions.Add(Key, TPointF.Create(
        TControl(AComponent).Position.X, TControl(AComponent).Position.Y));
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
    begin
      Child := AComponent.Components[ChildIndex];
      SnapshotTree(Child);
    end;
  end;
begin
  if (AForm = nil) or (FOriginalPositions = nil) then
    Exit;
  for ComponentIndex := 0 to AForm.ComponentCount - 1 do
  begin
    Component := AForm.Components[ComponentIndex];
    SnapshotTree(Component);
  end;
end;

class procedure TFMXTranslationApplicator.RestoreOriginalPositions(
  const AForm: TCommonCustomForm; const AFormIdentity: string);
var
  ComponentIndex: Integer;
  Component: TComponent;
  Key: string;
  OriginalPosition: TPointF;

  procedure RestoreTree(const AComponent: TComponent);
  var
    ChildIndex: Integer;
    Child: TComponent;
  begin
    if AComponent = nil then
      Exit;
    Key := PositionKey(AFormIdentity, AComponent);
    if (Key <> '') and (AComponent is TControl) and
      FOriginalPositions.TryGetValue(Key, OriginalPosition) then
    begin
      TControl(AComponent).Position.X := OriginalPosition.X;
      TControl(AComponent).Position.Y := OriginalPosition.Y;
    end;
    for ChildIndex := 0 to AComponent.ComponentCount - 1 do
    begin
      Child := AComponent.Components[ChildIndex];
      RestoreTree(Child);
    end;
  end;
begin
  if (AForm = nil) or (FOriginalPositions = nil) then
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
  RestoreOriginalPositions(AForm, FormIdentity);
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
  SnapshotOriginalPositions(AForm, FormIdentity);
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
    Inc(Result, ApplyConservativeTextFit(AForm, APack));
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

  function IsSafeRuntimeLayoutProperty(const APropertyName: string): Boolean;
  begin
    Result :=
      SameText(APropertyName, 'Width') or
      SameText(APropertyName, 'Height') or
      SameText(APropertyName, 'WordWrap');
  end;
begin
  Result := 0;
  if (AForm = nil) or (APack = nil) then
    Exit;
  for Rule in APack.LayoutRules do
  begin
    if not SameText(Rule.FormName, AFormIdentity) then
      Continue;
    { Runtime localization must not rearrange a target form. Earlier layout
      packs could contain positional proposals; those are too dangerous to
      apply generically because they can scatter related controls. Keep the
      runtime solver conservative: only expand/wrap controls to fit translated
      text. The developer can still manually redesign the form if a language
      needs a different layout. }
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
    if TrySetLayoutProperty(Component, Rule.PropertyName, Value) then
      Inc(Result);
  end;
end;

initialization
  TFMXTranslationApplicator.FOriginalPositions :=
    TDictionary<string, TPointF>.Create;

finalization
  TFMXTranslationApplicator.FOriginalPositions.Free;
  TFMXTranslationApplicator.FOriginalPositions := nil;

end.
