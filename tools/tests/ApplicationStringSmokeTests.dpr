program ApplicationStringSmokeTests;

{ The report that names the strings a language pack cannot translate.

  A caption the application composes in code is written to the control again
  whenever the display refreshes, so anything the pack puts there is
  overwritten. The classification for that has always been right and the scan
  has always recorded the file and the line - but nobody was ever told, so a
  developer looking at a half-translated status bar had no way to find out
  which strings those were.

  This exercises the report: that it names every such string and no others,
  that it carries the file and line a developer needs, and that it writes
  nothing at all when there is nothing to say. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Review.ApplicationStrings in '..\..\source\review\DAT.Review.ApplicationStrings.pas';

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

procedure AddEntry(const ACatalog: TTranslationCatalog;
  const AKey, ASourceText, AFileName: string; const ALine: Integer;
  const AOwnership: TTextOwnershipKind);
var
  Entry: TTranslationEntry;
begin
  Entry := TTranslationEntry.Create;
  Entry.Key := AKey;
  Entry.SourceText := ASourceText;
  Entry.SourceFileName := AFileName;
  Entry.SourceLine := ALine;
  Entry.TextOwnership := AOwnership;
  ACatalog.Entries.Add(Entry);
end;

var
  Catalog: TTranslationCatalog;
  FileName_: string;
  Report: string;
  Written: Integer;
begin
  try
    FileName_ := TPath.Combine(TPath.GetTempPath, 'dat-application-strings.md');
    if TFile.Exists(FileName_) then
      TFile.Delete(FileName_);

    Catalog := TTranslationCatalog.Create;
    try
      Catalog.ApplicationId := 'ReportSample';
      Catalog.Locale.LanguageCode := 'de-DE';

      { Two the application owns, in two different units, and three the pack
        handles perfectly well. }
      AddEntry(Catalog, 'frmMain.StatusBar1.Panels[1].Text',
        'Items in list:  ', 'C:\App\MainForm.pas', 2096, tokRuntimeUnwired);
      AddEntry(Catalog, 'frmMain.StatusBar1.Panels[2].Text',
        'Last updated:  ', 'C:\App\MainForm.pas', 2101, tokRuntimeUnwired);
      AddEntry(Catalog, 'frmReport.lblHeading.Caption',
        'Monthly report', 'C:\App\ReportForm.pas', 44, tokRuntimeUnwired);
      AddEntry(Catalog, 'frmMain.btnSave.Caption',
        'Save', 'C:\App\MainForm.dfm', 12, tokDesignerAutomatic);
      AddEntry(Catalog, 'frmMain.edtName.Text',
        '12345', 'C:\App\MainForm.dfm', 20, tokApplicationData);

      Writeln;
      Writeln('=== counting ===');
      Check(TApplicationOwnedStrings.Count(Catalog) = 3,
        Format('Three strings are owned by the application, not %d.',
          [TApplicationOwnedStrings.Count(Catalog)]));

      Written := TApplicationOwnedStrings.WriteReport(Catalog, FileName_);
      Check(Written = 3, 'and the report says it named three.');
      Check(TFile.Exists(FileName_), 'The report was written.');

      Report := TFile.ReadAllText(FileName_, TEncoding.UTF8);
      Writeln;
      Writeln('=== what the report carries ===');
      Check(ContainsStr(Report, 'MainForm.pas') and
        ContainsStr(Report, 'ReportForm.pas'),
        'Both source files are named.');
      Check(ContainsStr(Report, '2096') and ContainsStr(Report, '2101') and
        ContainsStr(Report, '44'),
        'Every line number is there, which is the whole point of it.');
      Check(ContainsStr(Report, 'Items in list:'),
        'The exact literal to wrap is quoted.');
      Check(ContainsStr(Report, 'TranslateText'),
        'and the call that fixes it is named.');

      Writeln;
      Writeln('=== and nothing that belongs to the pack ===');
      Check(not ContainsStr(Report, 'btnSave'),
        'A caption the pack handles is not in the report.');
      Check(not ContainsStr(Report, 'edtName'),
        'Neither is a data value.');
    finally
      Catalog.Free;
    end;

    Writeln;
    Writeln('=== a clean application gets no report at all ===');
    Catalog := TTranslationCatalog.Create;
    try
      Catalog.ApplicationId := 'CleanSample';
      Catalog.Locale.LanguageCode := 'de-DE';
      AddEntry(Catalog, 'frmMain.btnSave.Caption', 'Save',
        'C:\App\MainForm.dfm', 12, tokDesignerAutomatic);
      Check(TApplicationOwnedStrings.WriteReport(Catalog, FileName_) = 0,
        'Nothing to report.');
      Check(not TFile.Exists(FileName_),
        'and the stale report from the previous run was removed, rather ' +
        'than left to be read as current.');
    finally
      Catalog.Free;
    end;

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Application string report smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Application string report smoke tests failed: %d',
      [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
