unit DAT.Review.ApplicationStrings;

{ The strings the application has to translate for itself, named and located.

  Some interface text cannot be translated by a language pack, and the product
  is right to say so. A caption the application composes in code and reassigns
  whenever the display refreshes is overwritten moments after anything writes
  to it:

    StatusBar1.Panels[1].Text := 'Items in list:  ' + ItemCount.ToString;

  The scan classifies that correctly as runtimeUnwired, and the standing rule
  that the target application is evidence rather than a workpiece forbids the
  product from adding the TranslateText call that would fix it.

  What was missing is that nobody was ever told. The classification sat in the
  catalog, the strings quietly stayed in the source language, and a developer
  looking at a half-translated status bar had no way to discover which strings
  those were or where they lived - even though the scan had recorded the file
  and the line for every one of them.

  So the facts are written out as a report the developer can act on. It is the
  difference between a silent gap and a five-minute job. }

interface

uses
  DAT.Core.Types;

type
  TApplicationOwnedStrings = record
  public
    { How many entries in this catalog the application must translate itself.
      Zero is the common and happy answer. }
    class function Count(const ACatalog: TTranslationCatalog): Integer; static;

    { Writes the report and answers how many strings it names. Writes nothing
      and answers zero when there are none, because an empty report in the
      output folder is a question every time somebody sees it. }
    class function WriteReport(const ACatalog: TTranslationCatalog;
      const AFileName: string): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.SysUtils;

{ The one classification that means "the application must ask for this
  itself". The others are either applied by the pack or deliberately not
  translated at all. }
function IsApplicationOwned(const AEntry: TTranslationEntry): Boolean;
begin
  Result := AEntry.TextOwnership = tokRuntimeUnwired;
end;

class function TApplicationOwnedStrings.Count(
  const ACatalog: TTranslationCatalog): Integer;
var
  Entry: TTranslationEntry;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  for Entry in ACatalog.Entries do
    if IsApplicationOwned(Entry) then
      Inc(Result);
end;

class function TApplicationOwnedStrings.WriteReport(
  const ACatalog: TTranslationCatalog; const AFileName: string): Integer;
var
  Report: TStringList;
  Entry: TTranslationEntry;
  Files: TStringList;
  FileName_: string;
  Shown: string;
begin
  Result := Count(ACatalog);
  if Result = 0 then
  begin
    { Leave no stale report from a previous run to be read as current. }
    if TFile.Exists(AFileName) then
      TFile.Delete(AFileName);
    Exit;
  end;

  Report := TStringList.Create;
  Files := TStringList.Create;
  try
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    for Entry in ACatalog.Entries do
      if IsApplicationOwned(Entry) then
        Files.Add(Entry.SourceFileName);

    Report.Add('# Strings this application must translate for itself');
    Report.Add('');
    Report.Add(Format('%s, %s', [ACatalog.ApplicationId,
      ACatalog.Locale.LanguageCode]));
    Report.Add('');
    Report.Add(Format('%d string(s) cannot be translated by the language ' +
      'pack.', [Result]));
    Report.Add('');
    Report.Add('Each of these is built in code and written to the control ' +
      'again whenever');
    Report.Add('the display refreshes, so anything the pack puts there is ' +
      'overwritten moments');
    Report.Add('later. The translator cannot fix this from the outside: it ' +
      'never edits the');
    Report.Add('application''s own source. One call in the application ' +
      'does fix it.');
    Report.Add('');
    Report.Add('Wrap the literal in a call to the language manager, for ' +
      'example:');
    Report.Add('');
    Report.Add('    StatusBar1.Panels[1].Text :=');
    Report.Add('      TDATLanguageManager.TranslateText(''Items in list:  '') +');
    Report.Add('      ItemCount.ToString;');
    Report.Add('');
    Report.Add('The source text below is the exact literal to wrap.');
    Report.Add('');

    for FileName_ in Files do
    begin
      Report.Add('---');
      Report.Add('');
      if Trim(FileName_) = '' then
        Report.Add('## (source file not recorded)')
      else
        Report.Add('## ' + FileName_);
      Report.Add('');
      Report.Add('| Line | Control | Source text |');
      Report.Add('|---|---|---|');
      for Entry in ACatalog.Entries do
      begin
        if not IsApplicationOwned(Entry) then
          Continue;
        if not SameText(Entry.SourceFileName, FileName_) then
          Continue;
        { A pipe inside the text would break the table row it sits in. }
        Shown := StringReplace(Entry.SourceText, '|', '\|', [rfReplaceAll]);
        Shown := StringReplace(Shown, #13#10, ' ', [rfReplaceAll]);
        Shown := StringReplace(Shown, #10, ' ', [rfReplaceAll]);
        Report.Add(Format('| %d | %s | `%s` |',
          [Entry.SourceLine, Entry.Key, Shown]));
      end;
      Report.Add('');
    end;

    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
    Report.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Files.Free;
    Report.Free;
  end;
end;

end.
