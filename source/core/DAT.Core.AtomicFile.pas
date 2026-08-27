unit DAT.Core.AtomicFile;

interface

uses
  System.SysUtils;

type
  EDATAtomicFileError = class(Exception);

  TAtomicTextValidator = reference to procedure(const AText: string);

  TAtomicTextFile = class sealed
  public
    class function ReadAllText(const AFileName: string;
      const AEncoding: TEncoding; const AValidator: TAtomicTextValidator;
      out ARecoveredFromPrevious: Boolean): string; static;
    class procedure WriteAllText(const AFileName, AText: string;
      const AEncoding: TEncoding;
      const AValidator: TAtomicTextValidator = nil); static;
  end;

implementation

uses
  System.IOUtils;

var
  AtomicWriteLock: TObject;

function TemporaryFileName(const AFileName: string): string;
var
  Identifier: TGUID;
begin
  CreateGUID(Identifier);
  Result := AFileName + '.' + GUIDToString(Identifier) + '.tmp';
end;

function CorruptFileName(const AFileName: string): string;
var
  Identifier: TGUID;
begin
  CreateGUID(Identifier);
  Result := AFileName + '.corrupt-' +
    FormatDateTime('yyyymmdd-hhnnss-zzz', Now) + '-' +
    Copy(GUIDToString(Identifier), 2, 8);
end;

class function TAtomicTextFile.ReadAllText(const AFileName: string;
  const AEncoding: TEncoding; const AValidator: TAtomicTextValidator;
  out ARecoveredFromPrevious: Boolean): string;
var
  BackupFileName: string;
  CorruptName: string;
  PrimaryError: string;
begin
  ARecoveredFromPrevious := False;
  if not TFile.Exists(AFileName) then
    raise EDATAtomicFileError.CreateFmt('File not found: %s', [AFileName]);
  if AEncoding = nil then
    raise EDATAtomicFileError.Create('A text encoding is required.');

  try
    Result := TFile.ReadAllText(AFileName, AEncoding);
    if Assigned(AValidator) then
      AValidator(Result);
    Exit;
  except
    on E: Exception do
      PrimaryError := E.ClassName + ': ' + E.Message;
  end;

  BackupFileName := AFileName + '.previous';
  if not TFile.Exists(BackupFileName) then
    raise EDATAtomicFileError.CreateFmt(
      'The file is invalid and no recovery copy exists: %s (%s)',
      [AFileName, PrimaryError]);

  try
    Result := TFile.ReadAllText(BackupFileName, AEncoding);
    if Assigned(AValidator) then
      AValidator(Result);
  except
    on E: Exception do
      raise EDATAtomicFileError.CreateFmt(
        'The file and its recovery copy are both invalid: %s (%s; recovery: %s: %s)',
        [AFileName, PrimaryError, E.ClassName, E.Message]);
  end;

  { Preserve the evidence before restoring. The validated recovery copy is
    retained too; nothing is destroyed while handling corruption. }
  CorruptName := CorruptFileName(AFileName);
  TMonitor.Enter(AtomicWriteLock);
  try
    TFile.Move(AFileName, CorruptName);
    try
      TAtomicTextFile.WriteAllText(AFileName, Result, AEncoding,
        AValidator);
    except
      if not TFile.Exists(AFileName) and TFile.Exists(CorruptName) then
        TFile.Move(CorruptName, AFileName);
      raise;
    end;
  finally
    TMonitor.Exit(AtomicWriteLock);
  end;
  ARecoveredFromPrevious := True;
end;

class procedure TAtomicTextFile.WriteAllText(const AFileName, AText: string;
  const AEncoding: TEncoding; const AValidator: TAtomicTextValidator);
var
  BackupFileName: string;
  DirectoryName: string;
  ReadBackText: string;
  TemporaryName: string;
begin
  if Trim(AFileName) = '' then
    raise EDATAtomicFileError.Create('A destination file name is required.');
  if AEncoding = nil then
    raise EDATAtomicFileError.Create('A text encoding is required.');

  TMonitor.Enter(AtomicWriteLock);
  try
    DirectoryName := TPath.GetDirectoryName(AFileName);
    if DirectoryName <> '' then
      TDirectory.CreateDirectory(DirectoryName);

    TemporaryName := TemporaryFileName(AFileName);
    BackupFileName := AFileName + '.previous';
    try
      TFile.WriteAllText(TemporaryName, AText, AEncoding);
      ReadBackText := TFile.ReadAllText(TemporaryName, AEncoding);
      if ReadBackText <> AText then
        raise EDATAtomicFileError.CreateFmt(
          'The staged file did not pass its round-trip check: %s',
          [TemporaryName]);
      if Assigned(AValidator) then
        AValidator(ReadBackText);

      if TFile.Exists(AFileName) then
      begin
        { Removing an older recovery copy cannot damage the current file. If
          the process stops here, the current destination is still intact. }
        if TFile.Exists(BackupFileName) then
          TFile.Delete(BackupFileName);
        TFile.Replace(TemporaryName, AFileName, BackupFileName);
      end
      else
        TFile.Move(TemporaryName, AFileName);

      if not TFile.Exists(AFileName) or
        (TFile.ReadAllText(AFileName, AEncoding) <> AText) then
        raise EDATAtomicFileError.CreateFmt(
          'The atomic replacement could not be verified: %s', [AFileName]);
    finally
      if TFile.Exists(TemporaryName) then
        TFile.Delete(TemporaryName);
    end;
  finally
    TMonitor.Exit(AtomicWriteLock);
  end;
end;

initialization
  AtomicWriteLock := TObject.Create;

finalization
  AtomicWriteLock.Free;

end.
