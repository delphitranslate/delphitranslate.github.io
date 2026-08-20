program ScannerSmokeTests;

{ Runs the Pascal scanner over one source file and prints what it claims, so a
  scanner change can be judged without translating a project or running the
  Wizard.

  Usage: ScannerSmokeTests <file.pas> [filter]

  A filter, when given, keeps only items whose source text contains it. Exit
  code is 0 when at least one item is reported, 1 when none is, so a check for
  a particular string can gate a change. }

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in '..\..\source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.DomainProfile in '..\..\source\scan\DAT.Scan.DomainProfile.pas',
  DAT.Scan.Context in '..\..\source\scan\DAT.Scan.Context.pas',
  DAT.Scan.Quality in '..\..\source\scan\DAT.Scan.Quality.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.PascalResources in '..\..\source\scan\DAT.Scan.PascalResources.pas';

var
  FileName, Filter: string;
  ScanResult: TProjectScanResult;
  Item: TScanItem;
  Reported: Integer;
begin
  try
    if ParamCount < 1 then
    begin
      Writeln('Usage: ScannerSmokeTests <file.pas> [filter]');
      ExitCode := 2;
      Exit;
    end;
    FileName := ParamStr(1);
    if ParamCount >= 2 then
      Filter := ParamStr(2)
    else
      Filter := '';

    if not TFile.Exists(FileName) then
    begin
      Writeln('Not found: ' + FileName);
      ExitCode := 2;
      Exit;
    end;

    Writeln('Scanner smoke test');
    Writeln('File  : ' + FileName);
    if Filter <> '' then
      Writeln('Filter: ' + Filter);
    Writeln('');

    Reported := 0;
    ScanResult := TProjectScanResult.Create;
    try
      TPascalResourceStringScanner.ScanFile(FileName, ScanResult);
      for Item in ScanResult.Items do
      begin
        if (Filter <> '') and not ContainsText(Item.SourceText, Filter) then
          Continue;
        Inc(Reported);
        Writeln(Format('  line %-6d %-16s %-22s %s',
          [Item.SourceLine, Item.PropertyName, Item.Key, Item.SourceText]));
      end;
      Writeln('');
      Writeln(Format('items reported: %d (of %d scanned)',
        [Reported, ScanResult.Items.Count]));
    finally
      ScanResult.Free;
    end;

    if Reported > 0 then
      ExitCode := 0
    else
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 3;
    end;
  end;
end.
