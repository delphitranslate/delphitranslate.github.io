unit ScanFixture;

// Fixtures for the Pascal scanner. Each function below is a shape that has
// produced a wrong capture at some point, kept here so it cannot again.
// Note: no apostrophes anywhere in these comments. The statement collector
// does not skip comments, so an apostrophe in one opens a string literal that
// never closes and silently swallows the rest of the file.

interface

implementation

uses
  System.IOUtils, System.SysUtils;

// A path assembled from literals and a separator. Joined blindly it reads as
// logsCarillonPlayLog.txt, a file name with its separator missing, which is
// neither a path nor a caption and slips past a guard looking for either.
function LogFileName: string;
begin
  Result := 'logs' + PathDelim + 'CarillonPlayLog.txt';
end;

// A bare file name returned as is.
function BackupFileName: string;
begin
  Result := 'CarillonBackup.dat';
end;

// Literals with a value between them are not one string, and gluing them
// makes a caption the program never shows.
function ItemSummary(const ACount: Integer): string;
begin
  Result := 'Total: ' + IntToStr(ACount) + ' items';
end;

// One caption written across two lines is one string, and must survive.
function WelcomeMessage: string;
begin
  Result := 'Enter information in these fields to silence ' +
    'the bell system on selected dates.';
end;

// Both arms of a conditional are captions and both must be claimed.
function ColumnHeading(const AByTime: Boolean): string;
begin
  if AByTime then Result := 'Time' else Result := 'Song';
end;


{ A block comment containing Carillon's apostrophe. Before comments were
  understood this opened a string literal that never closed, and every
  statement after it in the file was lost without a word. }
function AfterApostropheComment: string;
begin
  Result := 'Caption after an apostrophe in a comment';
end;

{ A heading an application writes into a list, ending with a line break.

  The break is punctuation, not data: the heading is still text a person reads.
  Requiring pure literals threw the whole phrase away because sLineBreak is an
  identifier, which is how the schedule dialog's heading came to be missing
  from the catalogue while every caption around it was claimed. }
procedure AddScheduleHeading(const ALines: TStrings);
begin
  ALines.Add('Remaining events for Today:' + sLineBreak);
end;

end.
