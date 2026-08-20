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
  person to type anything.

  These tests check the shape of what is said rather than its exact wording -
  that a domain sentence is present, that an ambiguous word carries an explicit
  sense - because pinning the phrasing would freeze wording that is meant to be
  read from each application rather than written here.

  The second application matters more than the first. It is a file-renaming
  utility, a kind of program no list of domains would have held, and it shares
  two words with Carillon that mean entirely different things: Volume is a disk
  rather than loudness, and Play is not there at all. Nothing tells either test
  which kind of application it is looking at. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.DomainProfile in '..\..\source\scan\DAT.Scan.DomainProfile.pas',
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

{ ------------------------------------------------------- a bell scheduler }

procedure CheckCarillon;
var
  Scan: TProjectScanResult;
  Column: TScanItem;
  CloseButton: TScanItem;
begin
  Scan := TProjectScanResult.Create;
  try
    { The vocabulary that settles what "play" means here is spread across the
      application, not in any one string. }
    AddItem(Scan, 'fmDailyPlayList', 'lblSongName', 'TLabel', 'Caption',
      'Song Name and Path');
    AddItem(Scan, 'fmDailyPlayList', 'btnPlaySong', 'TButton', 'Caption',
      'Play Song');
    AddItem(Scan, 'fmDailyPlayList', 'lblVolume', 'TLabel', 'Caption',
      'System Volume:');
    AddItem(Scan, 'fmDailyPlayList', 'lblMute', 'TLabel', 'Caption',
      'Mute Sound');
    AddItem(Scan, 'fmDailyPlayList', 'lblChime', 'TLabel', 'Caption',
      'Westminster Chimes and Carillon Bells');
    AddItem(Scan, 'fmDailyPlayList', 'lblAudio', 'TLabel', 'Caption',
      'Audio Song Playback');
    AddItem(Scan, 'fmSchedule', 'lblCalendar', 'TLabel', 'Caption',
      'Calendar Month and Day');
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
    Writeln('  Carillon, the grid heading "Play Date From":');
    Writeln('    ', Column.ContextDescription);
    Writeln;

    Check(ContainsText(Column.ContextDescription, 'column'),
      'It says the string is a column heading.');
    Check(ContainsText(Column.ContextDescription, 'Carillon'),
      'It names the application.');
    Check(ContainsText(Column.ContextDescription, 'uses most are'),
      'It describes the application in the application own words.');
    Check(ContainsText(Column.ContextDescription, 'song') or
      ContainsText(Column.ContextDescription, 'chime'),
      'And those words are the ones this application actually uses.');
    Check(ContainsText(Column.ContextDescription, 'Play Time'),
      'It lists the neighbouring column headings.');
    Check(ContainsText(Column.ContextDescription, 'sound recording'),
      'It says outright which sense of "play" is meant.');
    Check(ContainsText(Column.ContextDescription, 'calendar date'),
      'And which sense of "date" - the half that made it a playdate.');
    Check(ContainsText(Column.ContextDescription, 'fit a column heading'),
      'It asks for something short enough to fit.');

    { A button caption is an instruction, and a menu item is a name. Told
      neither, Arabic returned Help as "he helps", Close as "he closes" and
      Play as "he plays" - grammatically fine and useless on a button. The
      control class is known for every string, so this costs nothing to say. }
    Check(ContainsText(CloseButton.ContextDescription, 'imperative'),
      'A button caption asks for an imperative, not a statement.');
    Check(not ContainsText(Column.ContextDescription, 'imperative'),
      'A column heading does not - it is a name, not an instruction.');
    Check(ContainsText(Column.ContextDescription, 'noun'),
      'and says so.');

    Writeln('  Carillon, the Close button:');
    Writeln('    ', CloseButton.ContextDescription);
    Writeln;
    Check(ContainsText(CloseButton.ContextDescription, 'button'),
      'A button is described as a button.');
    Check(ContainsText(CloseButton.ContextDescription, 'shutting a window'),
      'And "close" is pinned to the verb, not the adjective.');
  finally
    Scan.Free;
  end;
end;

{ ---------------------------------------------------- a file-renaming utility }

procedure CheckUtility;
var
  Scan: TProjectScanResult;
  VolumeLabel: TScanItem;
  MaskLabel: TScanItem;
begin
  Scan := TProjectScanResult.Create;
  try
    AddItem(Scan, 'frmMain', 'lblFolder', 'TLabel', 'Caption',
      'Source Folder and Subdirectories');
    AddItem(Scan, 'frmMain', 'lblRename', 'TLabel', 'Caption',
      'Rename Files Matching');
    AddItem(Scan, 'frmMain', 'lblExtension', 'TLabel', 'Caption',
      'Keep Original Extension');
    AddItem(Scan, 'frmMain', 'lblPrefix', 'TLabel', 'Caption',
      'Filename Prefix');
    AddItem(Scan, 'frmMain', 'lblDisk', 'TLabel', 'Caption',
      'Disk Drive and Partition');
    AddItem(Scan, 'frmMain', 'lblFormat', 'TLabel', 'Caption',
      'Format Drive Capacity');
    MaskLabel := AddItem(Scan, 'frmMain', 'lblMask', 'TLabel', 'Caption',
      'Filename Mask');
    VolumeLabel := AddItem(Scan, 'frmMain', 'lblVolume', 'TLabel', 'Caption',
      'Volume Label');

    TScanContextAnalyzer.Enrich(Scan, 'Renamer');

    Writeln('  A file utility, the "Volume Label" caption:');
    Writeln('    ', VolumeLabel.ContextDescription);
    Writeln;
    Check(ContainsText(VolumeLabel.ContextDescription, 'uses most are'),
      'An application in no known category is still described.');
    Check(ContainsText(VolumeLabel.ContextDescription, 'rename') or
      ContainsText(VolumeLabel.ContextDescription, 'filename') or
      ContainsText(VolumeLabel.ContextDescription, 'folder'),
      'By its own words, which no list of domains would have held.');
    Check(ContainsText(VolumeLabel.ContextDescription, 'storage volume'),
      'Volume here is a disk, because this application talks about disks.');
    Check(not ContainsText(VolumeLabel.ContextDescription, 'loudness'),
      'And not loudness, which is what the same word meant in Carillon.');

    Writeln('  A file utility, the "Filename Mask" caption:');
    Writeln('    ', MaskLabel.ContextDescription);
    Writeln;
    Check(ContainsText(MaskLabel.ContextDescription, 'filenames are matched'),
      'A mask here is a filename pattern, not something worn.');
  finally
    Scan.Free;
  end;
end;

{ --------------------------------------------------------------- an unknown }

procedure CheckSilenceWhenUnsure;
var
  Scan: TProjectScanResult;
  Item: TScanItem;
begin
  Scan := TProjectScanResult.Create;
  try
    { Nothing here says whether a monitor is a screen or an act of watching,
      so nothing should be claimed about it. A guess between two senses is
      worse than saying nothing: it is a confident instruction to be wrong. }
    AddItem(Scan, 'frmMain', 'lblOne', 'TLabel', 'Caption', 'Widget Count');
    AddItem(Scan, 'frmMain', 'lblTwo', 'TLabel', 'Caption', 'Widget Total');
    Item := AddItem(Scan, 'frmMain', 'lblThree', 'TLabel', 'Caption',
      'Monitor');

    TScanContextAnalyzer.Enrich(Scan, 'Widgets');

    Writeln('  An application that settles nothing:');
    Writeln('    ', Item.ContextDescription);
    Writeln;
    Check(not ContainsText(Item.ContextDescription, 'Here "monitor" means'),
      'An ambiguous word the application does not settle is left unsaid.');
    Check(ContainsText(Item.ContextDescription, 'Widgets'),
      'The rest of the context is still given.');
  finally
    Scan.Free;
  end;
end;

begin
  try
    Writeln('  shared ambiguous-term list: ', TDomainProfiler.FileName);
    CheckCarillon;
    CheckUtility;
    CheckSilenceWhenUnsure;

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
