program AtomicPersistenceSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.IOUtils,
  System.SysUtils,
  DAT.Core.AtomicFile in '..\..\source\core\DAT.Core.AtomicFile.pas';

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

var
  CorruptFiles: TArray<string>;
  FileName: string;
  Folder: string;
  Recovered: Boolean;
  Rejected: Boolean;
  Text: string;
begin
  Folder := TPath.Combine(TPath.GetTempPath,
    'DAT-atomic-' + FormatDateTime('yyyymmddhhnnsszzz', Now));
  TDirectory.CreateDirectory(Folder);
  FileName := TPath.Combine(Folder, 'catalog.json');
  try
    TAtomicTextFile.WriteAllText(FileName, '{"generation":1}',
      TEncoding.UTF8);
    Check(TFile.ReadAllText(FileName, TEncoding.UTF8) = '{"generation":1}',
      'The first generation was not committed.');

    TAtomicTextFile.WriteAllText(FileName, '{"generation":2}',
      TEncoding.UTF8);
    Check(TFile.ReadAllText(FileName, TEncoding.UTF8) = '{"generation":2}',
      'The replacement generation was not committed.');
    Check(TFile.ReadAllText(FileName + '.previous', TEncoding.UTF8) =
      '{"generation":1}', 'The prior valid generation was not preserved.');

    Rejected := False;
    try
      TAtomicTextFile.WriteAllText(FileName, '{"generation":3}',
        TEncoding.UTF8,
        procedure(const AText: string)
        begin
          raise Exception.Create('Rejected staged content');
        end);
    except
      on E: Exception do
        Rejected := Pos('Rejected staged content', E.Message) > 0;
    end;
    Check(Rejected, 'The validator failure was not returned.');
    Check(TFile.ReadAllText(FileName, TEncoding.UTF8) = '{"generation":2}',
      'A rejected generation changed the destination.');

    TFile.WriteAllText(FileName, 'not valid', TEncoding.UTF8);
    Text := TAtomicTextFile.ReadAllText(FileName, TEncoding.UTF8,
      procedure(const AText: string)
      begin
        if Pos('{"generation":', AText) <> 1 then
          raise Exception.Create('Invalid generation document');
      end, Recovered);
    Check(Recovered, 'The prior valid generation was not recovered.');
    Check(Text = '{"generation":1}',
      'Recovery returned the wrong prior generation.');
    Check(TFile.ReadAllText(FileName, TEncoding.UTF8) = '{"generation":1}',
      'The recovered generation was not restored as the primary file.');
    CorruptFiles := TDirectory.GetFiles(Folder, 'catalog.json.corrupt-*');
    Check(Length(CorruptFiles) = 1,
      'The invalid primary was not retained as quarantine evidence.');

    Writeln('Atomic persistence smoke tests passed.');
  finally
    if TDirectory.Exists(Folder) then
      TDirectory.Delete(Folder, True);
  end;
end.
