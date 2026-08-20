program ContextSmokeTests;

{ What the translation provider is told about a string before it translates it.

  A provider sees one string at a time. "Play Date From" on its own is genuinely
  ambiguous - it could be a column of broadcast times or an afternoon arranged
  between children - and told nothing beyond "text used in a desktop
  application" it chose the children and produced Spielverabredungen for a grid
  of bell timings.

  Everything needed to settle it was already in the scan: the control is a
  column heading, the application is full of songs and chimes and volume, and
  the other columns beside it say Group and Play Time. None of that requires a
  person to type anything. This checks that it is gathered and said. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Context in '..\..\source\scan\DAT.Scan.Context.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

function AddItem(const AResult: TProjectScanResult;
  const AForm, AComponent, AClass, AProperty, AText: string): TScanItem;
begin
  Result := TScanItem.Create;
  Result.Key := AForm + '.' + AComponent + '.' + AProperty;
  Result.FormName := AForm;
  Result.ComponentName := AComponent;
  Result.ComponentClassName := AClass;
  Result.PropertyName := AProperty;
  Result.SourceText := AText;
  AResult.Items.Add(Result);
  TScanContextAnalyzer.Analyze(Result);
end;

var
  Scan: TProjectScanResult;
  Column: TScanItem;
  CloseButton: TScanItem;
begin
  try
    Scan := TProjectScanResult.Create;
    try
      { A scheduler for playing bells: the vocabulary that settles what "play"
        means here is spread across the application, not in any one string. }
      AddItem(Scan, 'fmDailyPlayList', 'lblSongName', 'TLabel', 'Caption',
        'Song Name and Path');
      AddItem(Scan, 'fmDailyPlayList', 'btnPlaySong', 'TButton', 'Caption',
        'Play');
      AddItem(Scan, 'fmDailyPlayList', 'lblVolume', 'TLabel', 'Caption',
        'System Volume:');
      AddItem(Scan, 'fmDailyPlayList', 'lblChime', 'TLabel', 'Caption',
        'Westminster Chimes and Carillon Bells');
      AddItem(Scan, 'Groups', 'DBGrid1', 'TColumn',
        'Columns[0].Title.Caption', 'Group');
      AddItem(Scan, 'Groups', 'DBGrid1', 'TColumn',
        'Columns[2].Title.Caption', 'Play Time');
      Column := AddItem(Scan, 'Groups', 'DBGrid1', 'TColumn',
        'Columns[1].Title.Caption', 'Play Date From');
      CloseButton := AddItem(Scan, 'Groups', 'btnClose', 'TButton', 'Caption',
        'Close');

      TScanContextAnalyzer.Enrich(Scan, 'Carillon');

      Writeln;
      Writeln('  context for the grid heading "Play Date From":');
      Writeln('    ', Column.ContextDescription);
      Writeln;

      Check(ContainsText(Column.ContextDescription, 'column'),
        'It says the string is a column heading.');
      Check(ContainsText(Column.ContextDescription, 'Carillon'),
        'It names the application.');
      Check(ContainsText(Column.ContextDescription, 'recorded music'),
        'It says what the application is for.');
      Check(ContainsText(Column.ContextDescription, 'Play Time'),
        'It lists the neighbouring column headings.');
      Check(ContainsText(Column.ContextDescription, 'never a game'),
        'It says outright which sense of "play" is meant.');
      Check(ContainsText(Column.ContextDescription, 'fit a column heading'),
        'It asks for something short enough to fit.');

      Writeln('  context for the Close button:');
      Writeln('    ', CloseButton.ContextDescription);
      Writeln;
      Check(ContainsText(CloseButton.ContextDescription, 'button'),
        'A button is described as a button.');
      Check(ContainsText(CloseButton.ContextDescription, 'shutting a window'),
        'And "close" is pinned to the verb, not the adjective.');
    finally
      Scan.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('Context smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Context smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
