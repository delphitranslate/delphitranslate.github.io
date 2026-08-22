unit DAT.Runtime.LayoutOverrides;

{ Adjustments made to a translated form while the application is running, and
  remembered.

  The planner is good and it is not always right. It measures text and reasons
  about boxes; it cannot see that a caption sits awkwardly against a picture,
  or that a particular language reads better with one control nudged. Until
  now the only way to correct that was to go back to the Studio, and for a
  translator working from the running application - which is the only place
  the problem is visible - there was no way at all.

  So a control can be moved or resized while the application runs, and what was
  done is written down and applied every time afterwards.

  Three properties this has to have, and each shapes the design:

    - **The target application's source is never involved.** The overrides
      live in their own file beside the language packs. Nothing is written back
      into a .dfm, a .fmx, or a .pas, which is the rule the whole product rests
      on and is not relaxed for the convenience of this feature.

    - **They are per language.** German needs a wider button; Japanese does
      not. An adjustment made while looking at one language has no business
      changing another.

    - **They win.** An override is applied after every rule the pack carries,
      because it is the correction of a human who looked at the result. If the
      planner and a person disagree about a control, the person is right.

  What is deliberately not here: the dragging. Recording an adjustment is a
  runtime concern and belongs in the runtime; putting handles on somebody's
  controls is a user interface, and the host application is better placed to
  decide how that should look and when it is allowed. This unit is the half
  that has to be correct - what is stored, where, and when it is applied. }

interface

uses
  System.Generics.Collections;

type
  TLayoutOverride = class
  private
    FFormName: string;
    FComponentName: string;
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FHasPosition: Boolean;
    FHasSize: Boolean;
    FFontSize: Integer;
    FHasFontSize: Boolean;
  public
    property FormName: string read FFormName write FFormName;
    property ComponentName: string read FComponentName write FComponentName;
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    { A move and a resize are recorded separately, so that nudging a control
      does not also freeze a width the planner should still be free to
      compute. }
    property HasPosition: Boolean read FHasPosition write FHasPosition;
    property HasSize: Boolean read FHasSize write FHasSize;
    { Recorded separately again, and for the case that prompted it: a
      control an application creates in code has no designed geometry, so
      the planner never sees it and never sizes its text. Its type is
      whatever the application happened to choose, which in one real
      application was too small to read comfortably. }
    property FontSize: Integer read FFontSize write FFontSize;
    property HasFontSize: Boolean read FHasFontSize write FHasFontSize;
  end;

  TLayoutOverrides = class
  private
    FApplicationId: string;
    FLanguageCode: string;
    FItems: TObjectList<TLayoutOverride>;
    FFileName: string;
    function IndexOf(const AFormName, AComponentName: string): Integer;
  public
    constructor Create(const AApplicationId, ALanguageCode: string);
    destructor Destroy; override;

    { Where a given application keeps them: beside the language packs, one
      file per language, named so that a person can see what it is. }
    class function FileNameFor(const ALanguagesDirectory,
      ALanguageCode: string): string; static;

    { Never nil. An application nobody has adjusted loads empty. }
    class function Load(const ALanguagesDirectory, AApplicationId,
      ALanguageCode: string): TLayoutOverrides; static;
    procedure Save;

    { Records a move, a resize, or both. Recording the same control twice
      replaces what was there: the last thing a person did is what they
      meant. }
    procedure RecordPosition(const AFormName, AComponentName: string;
      const ALeft, ATop: Integer);
    procedure RecordSize(const AFormName, AComponentName: string;
      const AWidth, AHeight: Integer);
    procedure RecordFontSize(const AFormName, AComponentName: string;
      const APointSize: Integer);

    { Forgets one control, or everything on one form. The way back from an
      adjustment somebody regrets, without editing a file by hand. }
    function Forget(const AFormName, AComponentName: string): Boolean;
    function ForgetForm(const AFormName: string): Integer;

    { The override for one control, or nil. }
    function Find(const AFormName, AComponentName: string): TLayoutOverride;

    property ApplicationId: string read FApplicationId;
    property LanguageCode: string read FLanguageCode;
    property FileName: string read FFileName;
    property Items: TObjectList<TLayoutOverride> read FItems;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils;

constructor TLayoutOverrides.Create(const AApplicationId,
  ALanguageCode: string);
begin
  inherited Create;
  FApplicationId := AApplicationId;
  FLanguageCode := ALanguageCode;
  FItems := TObjectList<TLayoutOverride>.Create(True);
end;

destructor TLayoutOverrides.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

class function TLayoutOverrides.FileNameFor(const ALanguagesDirectory,
  ALanguageCode: string): string;
var
  Safe: string;
  Character: Char;
begin
  Safe := '';
  for Character in ALanguageCode do
    if CharInSet(Character, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_']) then
      Safe := Safe + Character;
  if Safe = '' then
    Safe := 'unknown';
  Result := TPath.Combine(ALanguagesDirectory, Safe + '.adjustments.json');
end;

function TLayoutOverrides.IndexOf(const AFormName,
  AComponentName: string): Integer;
var
  Index: Integer;
begin
  for Index := 0 to FItems.Count - 1 do
    if SameText(FItems[Index].FormName, AFormName) and
      SameText(FItems[Index].ComponentName, AComponentName) then
      Exit(Index);
  Result := -1;
end;

function TLayoutOverrides.Find(const AFormName,
  AComponentName: string): TLayoutOverride;
var
  At: Integer;
begin
  At := IndexOf(AFormName, AComponentName);
  if At < 0 then
    Result := nil
  else
    Result := FItems[At];
end;

class function TLayoutOverrides.Load(const ALanguagesDirectory,
  AApplicationId, ALanguageCode: string): TLayoutOverrides;
var
  Overrides: TLayoutOverrides;
  Path: string;
  Root: TJSONObject;
  Items: TJSONArray;
  Item: TJSONValue;
  Entry: TLayoutOverride;
begin
  Overrides := TLayoutOverrides.Create(AApplicationId, ALanguageCode);
  Overrides.FFileName := FileNameFor(ALanguagesDirectory, ALanguageCode);
  try
    Path := Overrides.FFileName;
    if not TFile.Exists(Path) then
      Exit(Overrides);
    Root := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(Path, TEncoding.UTF8)) as TJSONObject;
    if Root = nil then
      Exit(Overrides);
    try
      Items := Root.GetValue('adjustments') as TJSONArray;
      if Items <> nil then
        for Item in Items do
        begin
          Entry := TLayoutOverride.Create;
          Entry.FormName := (Item as TJSONObject).GetValue<string>(
            'formName', '');
          Entry.ComponentName := (Item as TJSONObject).GetValue<string>(
            'componentName', '');
          Entry.HasPosition := (Item as TJSONObject).GetValue<Boolean>(
            'hasPosition', False);
          Entry.HasSize := (Item as TJSONObject).GetValue<Boolean>(
            'hasSize', False);
          Entry.HasFontSize := (Item as TJSONObject).GetValue<Boolean>(
            'hasFontSize', False);
          Entry.FontSize := (Item as TJSONObject).GetValue<Integer>(
            'fontSize', 0);
          Entry.Left := (Item as TJSONObject).GetValue<Integer>('left', 0);
          Entry.Top := (Item as TJSONObject).GetValue<Integer>('top', 0);
          Entry.Width := (Item as TJSONObject).GetValue<Integer>('width', 0);
          Entry.Height := (Item as TJSONObject).GetValue<Integer>('height', 0);
          if (Entry.FormName <> '') and (Entry.ComponentName <> '') and
            (Entry.HasPosition or Entry.HasSize or Entry.HasFontSize) then
            Overrides.Items.Add(Entry)
          else
            Entry.Free;
        end;
    finally
      Root.Free;
    end;
    Result := Overrides;
  except
    { Adjustments that cannot be read are no adjustments. The application still
      runs, translated, with the layout the planner gave it. }
    Result := Overrides;
  end;
end;

procedure TLayoutOverrides.Save;
var
  Root: TJSONObject;
  Items: TJSONArray;
  Item: TJSONObject;
  Entry: TLayoutOverride;
begin
  if FFileName = '' then
    Exit;
  TDirectory.CreateDirectory(TPath.GetDirectoryName(FFileName));
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(1));
    Root.AddPair('applicationId', FApplicationId);
    Root.AddPair('languageCode', FLanguageCode);
    Items := TJSONArray.Create;
    for Entry in FItems do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('formName', Entry.FormName);
      Item.AddPair('componentName', Entry.ComponentName);
      Item.AddPair('hasPosition', TJSONBool.Create(Entry.HasPosition));
      Item.AddPair('hasSize', TJSONBool.Create(Entry.HasSize));
      Item.AddPair('hasFontSize', TJSONBool.Create(Entry.HasFontSize));
      if Entry.HasPosition then
      begin
        Item.AddPair('left', TJSONNumber.Create(Entry.Left));
        Item.AddPair('top', TJSONNumber.Create(Entry.Top));
      end;
      if Entry.HasSize then
      begin
        Item.AddPair('width', TJSONNumber.Create(Entry.Width));
        Item.AddPair('height', TJSONNumber.Create(Entry.Height));
      end;
      if Entry.HasFontSize then
        Item.AddPair('fontSize', TJSONNumber.Create(Entry.FontSize));
      Items.AddElement(Item);
    end;
    Root.AddPair('adjustments', Items);
    TFile.WriteAllText(FFileName, Root.Format(2), TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

procedure TLayoutOverrides.RecordPosition(const AFormName,
  AComponentName: string; const ALeft, ATop: Integer);
var
  Entry: TLayoutOverride;
begin
  Entry := Find(AFormName, AComponentName);
  if Entry = nil then
  begin
    Entry := TLayoutOverride.Create;
    Entry.FormName := AFormName;
    Entry.ComponentName := AComponentName;
    FItems.Add(Entry);
  end;
  Entry.Left := ALeft;
  Entry.Top := ATop;
  Entry.HasPosition := True;
end;

procedure TLayoutOverrides.RecordSize(const AFormName,
  AComponentName: string; const AWidth, AHeight: Integer);
var
  Entry: TLayoutOverride;
begin
  Entry := Find(AFormName, AComponentName);
  if Entry = nil then
  begin
    Entry := TLayoutOverride.Create;
    Entry.FormName := AFormName;
    Entry.ComponentName := AComponentName;
    FItems.Add(Entry);
  end;
  Entry.Width := AWidth;
  Entry.Height := AHeight;
  Entry.HasSize := True;
end;

procedure TLayoutOverrides.RecordFontSize(const AFormName,
  AComponentName: string; const APointSize: Integer);
var
  Entry: TLayoutOverride;
begin
  Entry := Find(AFormName, AComponentName);
  if Entry = nil then
  begin
    Entry := TLayoutOverride.Create;
    Entry.FormName := AFormName;
    Entry.ComponentName := AComponentName;
    FItems.Add(Entry);
  end;
  Entry.FontSize := APointSize;
  Entry.HasFontSize := True;
end;

function TLayoutOverrides.Forget(const AFormName,
  AComponentName: string): Boolean;
var
  At: Integer;
begin
  At := IndexOf(AFormName, AComponentName);
  Result := At >= 0;
  if Result then
    FItems.Delete(At);
end;

function TLayoutOverrides.ForgetForm(const AFormName: string): Integer;
var
  Index: Integer;
begin
  Result := 0;
  for Index := FItems.Count - 1 downto 0 do
    if SameText(FItems[Index].FormName, AFormName) then
    begin
      FItems.Delete(Index);
      Inc(Result);
    end;
end;

end.
