program FormScanContracts;

{ Checks that the form scanner reads the text-bearing properties it claims to.

  Each fixture in contracts\formscan is a .dfm or .fmx form paired with an
  .expected.txt listing, one per line, the component, property and text that
  must come out of it:

      pnlHeader|Caption|Panel used as a header

  The framework comes from the extension. A fixture passes when every expected
  line is produced; text the scanner finds beyond the list is reported but is
  not a failure, since reading more than was asked for is the point of the
  exercise. Exit code is 0 when every fixture passes.

  Usage: FormScanContracts [fixture directory] }

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Generics.Collections,
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
  DAT.Scan.FormText in '..\..\source\scan\DAT.Scan.FormText.pas';

function Triple(const AComponent, AProperty, AText: string): string;
begin
  Result := AComponent + '|' + AProperty + '|' + AText;
end;

var
  FixtureDirectory: string;
  FixtureFileName: string;
  ExpectedFileName: string;
  Expected: TStringList;
  Produced: TStringList;
  ScanResult: TProjectScanResult;
  Item: TScanItem;
  Framework: TTargetFramework;
  Line: string;
  FixtureCount, FailedCount, MissingCount, ExtraCount: Integer;
  FixturePassed: Boolean;
begin
  try
    if ParamCount >= 1 then
      FixtureDirectory := ParamStr(1)
    else
      FixtureDirectory := TPath.GetFullPath(TPath.Combine(
        ExtractFilePath(ParamStr(0)), '..\..\..\contracts\formscan'));

    Writeln('Form scan contracts');
    Writeln('Fixtures: ' + FixtureDirectory);
    Writeln('');

    if not TDirectory.Exists(FixtureDirectory) then
    begin
      Writeln('Fixture directory not found.');
      ExitCode := 2;
      Exit;
    end;

    FixtureCount := 0;
    FailedCount := 0;

    for FixtureFileName in TDirectory.GetFiles(FixtureDirectory, '*.*') do
    begin
      if not (SameText(TPath.GetExtension(FixtureFileName), '.dfm') or
        SameText(TPath.GetExtension(FixtureFileName), '.fmx')) then
        Continue;

      ExpectedFileName := TPath.ChangeExtension(FixtureFileName, '') +
        'expected.txt';
      if not TFile.Exists(ExpectedFileName) then
      begin
        Writeln('  skip  ' + TPath.GetFileName(FixtureFileName) +
          ' (no expectations file)');
        Continue;
      end;

      Inc(FixtureCount);
      if SameText(TPath.GetExtension(FixtureFileName), '.dfm') then
        Framework := tfVCL
      else
        Framework := tfFireMonkey;

      Expected := TStringList.Create;
      Produced := TStringList.Create;
      ScanResult := TProjectScanResult.Create;
      try
        Expected.LoadFromFile(ExpectedFileName, TEncoding.UTF8);
        for var Index := Expected.Count - 1 downto 0 do
          if (Trim(Expected[Index]) = '') or
            StartsText('#', Trim(Expected[Index])) then
            Expected.Delete(Index);

        TTextFormScanner.ScanFile(FixtureFileName, Framework, ScanResult);
        for Item in ScanResult.Items do
          Produced.Add(Triple(Item.ComponentName, Item.PropertyName,
            Item.SourceText));

        FixturePassed := True;
        MissingCount := 0;
        for Line in Expected do
          if Produced.IndexOf(Trim(Line)) < 0 then
          begin
            if FixturePassed then
              Writeln('  FAIL  ' + TPath.GetFileName(FixtureFileName));
            FixturePassed := False;
            Inc(MissingCount);
            Writeln('        not read: ' + Trim(Line));
          end;

        ExtraCount := 0;
        for Line in Produced do
          if Expected.IndexOf(Line) < 0 then
            Inc(ExtraCount);

        if FixturePassed then
        begin
          Writeln(Format('  ok    %s (%d of %d read)',
            [TPath.GetFileName(FixtureFileName), Expected.Count,
             Expected.Count]));
          if ExtraCount > 0 then
            Writeln(Format('        %d further item(s) read beyond the list',
              [ExtraCount]));
        end
        else
        begin
          Inc(FailedCount);
          Writeln(Format('        %d of %d expected item(s) missing',
            [MissingCount, Expected.Count]));
        end;
      finally
        ScanResult.Free;
        Produced.Free;
        Expected.Free;
      end;
    end;

    Writeln('');
    Writeln(Format('Fixtures: %d   failed: %d', [FixtureCount, FailedCount]));
    if FailedCount = 0 then
      Writeln('RESULT: pass')
    else
      Writeln('RESULT: fail');
    if FailedCount > 0 then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln('ERROR: ' + E.Message);
      ExitCode := 2;
    end;
  end;
end.
