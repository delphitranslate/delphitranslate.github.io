unit DAT.Integration.Transaction;

interface

uses
  System.SysUtils,
  DAT.Integration.Types;

type
  EIntegrationTransactionError = class(Exception);

  TIntegrationApplyResult = class
  private
    FBackupDirectory: string;
    FFilesWritten: Integer;
  public
    property BackupDirectory: string read FBackupDirectory
      write FBackupDirectory;
    property FilesWritten: Integer read FFilesWritten write FFilesWritten;
  end;

  TIntegrationTransaction = class
  private
    class function DefaultBackupDirectory(
      const AChangeSet: TIntegrationChangeSet): string; static;
    class procedure RestoreAppliedChanges(
      const AChangeSet: TIntegrationChangeSet;
      const ABackupDirectory: string;
      const AAppliedCount: Integer); static;
  public
    class procedure Validate(const AChangeSet: TIntegrationChangeSet); static;
    class function Apply(const AChangeSet: TIntegrationChangeSet;
      const ABackupDirectory: string = ''):
      TIntegrationApplyResult; static;
    class procedure Restore(const AProjectDirectory,
      ABackupDirectory: string); static;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.StrUtils;

function FileSHA256(const AFileName: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashStringFromFile(AFileName));
end;

procedure VerifyFileSHA256(const AFileName, AExpectedHash,
  AFailureContext: string);
begin
  if not TFile.Exists(AFileName) then
    raise EIntegrationTransactionError.CreateFmt(
      '%s: the required file does not exist: %s',
      [AFailureContext, AFileName]);
  if not SameText(FileSHA256(AFileName), AExpectedHash) then
    raise EIntegrationTransactionError.CreateFmt(
      '%s: SHA-256 verification failed for %s',
      [AFailureContext, AFileName]);
end;

function RelativeTargetName(const AProjectDirectory,
  ATargetFileName: string): string;
var
  ProjectPrefix: string;
  TargetPath: string;
begin
  ProjectPrefix := IncludeTrailingPathDelimiter(
    TPath.GetFullPath(AProjectDirectory));
  TargetPath := TPath.GetFullPath(ATargetFileName);
  if not StartsText(ProjectPrefix, TargetPath) then
    raise EIntegrationTransactionError.CreateFmt(
      'Integration target is outside the selected project: %s',
      [ATargetFileName]);
  Result := Copy(TargetPath, Length(ProjectPrefix) + 1, MaxInt);
end;

procedure WriteTextAtomically(const AFileName, AText: string);
var
  DirectoryName: string;
  TemporaryFileName: string;
begin
  DirectoryName := TPath.GetDirectoryName(AFileName);
  TDirectory.CreateDirectory(DirectoryName);
  TemporaryFileName := AFileName + '.translation-studio.tmp';
  if TFile.Exists(TemporaryFileName) then
    TFile.Delete(TemporaryFileName);
  try
    TFile.WriteAllText(TemporaryFileName, AText, TEncoding.UTF8);
    if TFile.Exists(AFileName) then
      TFile.Delete(AFileName);
    TFile.Move(TemporaryFileName, AFileName);
  except
    if TFile.Exists(TemporaryFileName) then
      TFile.Delete(TemporaryFileName);
    raise;
  end;
end;

class function TIntegrationTransaction.DefaultBackupDirectory(
  const AChangeSet: TIntegrationChangeSet): string;
var
  BackupRoot: string;
  Stamp: string;
begin
  Stamp := FormatDateTime('yyyy-mm-dd_hhnnss_zzz', Now);
  if TDirectory.Exists('G:\') then
    BackupRoot := TPath.Combine('G:\',
      AChangeSet.ProjectName + ' Backup')
  else
    BackupRoot := TPath.Combine(AChangeSet.ProjectDirectory,
      'Localization\Integration Backups');
  Result := TPath.Combine(BackupRoot,
    'Translation Integration ' + Stamp);
end;

class procedure TIntegrationTransaction.Validate(
  const AChangeSet: TIntegrationChangeSet);
var
  Attributes: Integer;
  Change: TIntegrationFileChange;
  DirectoryName: string;
begin
  if AChangeSet = nil then
    raise EArgumentNilException.Create('An integration change set is required.');
  if AChangeSet.Changes.Count = 0 then
    raise EIntegrationTransactionError.Create(
      'The integration change set contains no files.');
  if TFile.Exists(TPath.Combine(
    AChangeSet.ProjectDirectory, '.git\index.lock')) then
    raise EIntegrationTransactionError.Create(
      'The target Git repository has an active index lock.');
  for Change in AChangeSet.Changes do
  begin
    RelativeTargetName(AChangeSet.ProjectDirectory, Change.TargetFileName);
    if Change.OriginalExists then
    begin
      {$WARN SYMBOL_PLATFORM OFF}
      Attributes := FileGetAttr(Change.TargetFileName);
      {$WARN SYMBOL_PLATFORM ON}
      if (Attributes < 0) or ((Attributes and faReadOnly) <> 0) then
        raise EIntegrationTransactionError.CreateFmt(
          'A target file is not writable: %s', [Change.TargetFileName]);
    end;
    DirectoryName := TPath.GetDirectoryName(Change.TargetFileName);
    while (DirectoryName <> '') and
      not TDirectory.Exists(DirectoryName) do
      DirectoryName := TPath.GetDirectoryName(DirectoryName);
    if DirectoryName = '' then
      raise EIntegrationTransactionError.CreateFmt(
        'A target directory is not writable: %s',
        [TPath.GetDirectoryName(Change.TargetFileName)]);
  end;
end;

class function TIntegrationTransaction.Apply(
  const AChangeSet: TIntegrationChangeSet;
  const ABackupDirectory: string): TIntegrationApplyResult;
var
  AppliedCount: Integer;
  BackupDirectory: string;
  BackupFileName: string;
  Change: TIntegrationFileChange;
  EntryObject: TJSONObject;
  FilesArray: TJSONArray;
  ManifestObject: TJSONObject;
  OriginalHash: string;
  RelativeName: string;
begin
  Validate(AChangeSet);
  BackupDirectory := ABackupDirectory;
  if BackupDirectory = '' then
    BackupDirectory := DefaultBackupDirectory(AChangeSet);
  TDirectory.CreateDirectory(TPath.Combine(BackupDirectory, 'Files'));

  ManifestObject := TJSONObject.Create;
  FilesArray := TJSONArray.Create;
  try
    ManifestObject.AddPair('schemaVersion', TJSONNumber.Create(2));
    ManifestObject.AddPair('projectName', AChangeSet.ProjectName);
    ManifestObject.AddPair('projectDirectory',
      AChangeSet.ProjectDirectory);
    ManifestObject.AddPair('gitRepository',
      TJSONBool.Create(TDirectory.Exists(TPath.Combine(
        AChangeSet.ProjectDirectory, '.git'))));
    ManifestObject.AddPair('createdUtc',
      DateToISO8601(TTimeZone.Local.ToUniversalTime(Now), True));
    ManifestObject.AddPair('files', FilesArray);
    for Change in AChangeSet.Changes do
    begin
      RelativeName := RelativeTargetName(
        AChangeSet.ProjectDirectory, Change.TargetFileName);
      EntryObject := TJSONObject.Create;
      EntryObject.AddPair('relativeName', RelativeName);
      EntryObject.AddPair('originalExists',
        TJSONBool.Create(Change.OriginalExists));
      FilesArray.AddElement(EntryObject);
      if Change.OriginalExists then
      begin
        OriginalHash := FileSHA256(Change.TargetFileName);
        EntryObject.AddPair('sha256', OriginalHash);
        BackupFileName := TPath.Combine(
          TPath.Combine(BackupDirectory, 'Files'), RelativeName);
        TDirectory.CreateDirectory(
          TPath.GetDirectoryName(BackupFileName));
        TFile.Copy(Change.TargetFileName, BackupFileName, True);
        VerifyFileSHA256(BackupFileName, OriginalHash,
          'Backup verification failed');
      end;
    end;
    TFile.WriteAllText(TPath.Combine(
      BackupDirectory, 'integration-backup.json'),
      ManifestObject.ToJSON, TEncoding.UTF8);
  finally
    ManifestObject.Free;
  end;

  AppliedCount := 0;
  try
    for Change in AChangeSet.Changes do
    begin
      WriteTextAtomically(Change.TargetFileName, Change.NewText);
      Inc(AppliedCount);
    end;
  except
    RestoreAppliedChanges(AChangeSet, BackupDirectory, AppliedCount);
    raise;
  end;

  Result := TIntegrationApplyResult.Create;
  Result.BackupDirectory := BackupDirectory;
  Result.FilesWritten := AppliedCount;
end;

class procedure TIntegrationTransaction.RestoreAppliedChanges(
  const AChangeSet: TIntegrationChangeSet;
  const ABackupDirectory: string; const AAppliedCount: Integer);
var
  BackupFileName: string;
  Change: TIntegrationFileChange;
  ChangeIndex: Integer;
  RelativeName: string;
begin
  for ChangeIndex := AAppliedCount - 1 downto 0 do
  begin
    Change := AChangeSet.Changes[ChangeIndex];
    if Change.OriginalExists then
    begin
      RelativeName := RelativeTargetName(
        AChangeSet.ProjectDirectory, Change.TargetFileName);
      BackupFileName := TPath.Combine(
        TPath.Combine(ABackupDirectory, 'Files'), RelativeName);
      if TFile.Exists(BackupFileName) then
      begin
        TFile.Copy(BackupFileName, Change.TargetFileName, True);
        VerifyFileSHA256(Change.TargetFileName,
          FileSHA256(BackupFileName), 'Automatic rollback failed');
      end;
    end
    else if TFile.Exists(Change.TargetFileName) then
      TFile.Delete(Change.TargetFileName);
  end;
end;

class procedure TIntegrationTransaction.Restore(
  const AProjectDirectory, ABackupDirectory: string);
var
  EntryValue: TJSONValue;
  FilesArray: TJSONArray;
  JsonValue: TJSONValue;
  ManifestObject: TJSONObject;
  OriginalExists: Boolean;
  ExpectedHash: string;
  HashValue: TJSONValue;
  RelativeName: string;
  SourceFileName: string;
  TargetFileName: string;
begin
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(
    TPath.Combine(ABackupDirectory, 'integration-backup.json'),
    TEncoding.UTF8));
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise EIntegrationTransactionError.Create(
      'The integration backup manifest is invalid.');
  end;
  ManifestObject := TJSONObject(JsonValue);
  try
    FilesArray := ManifestObject.GetValue('files') as TJSONArray;
    if FilesArray = nil then
      raise EIntegrationTransactionError.Create(
        'The integration backup contains no file list.');
    { Preflight the complete restore set before changing any project file. }
    for EntryValue in FilesArray do
    begin
      RelativeName := EntryValue.GetValue<string>('relativeName');
      OriginalExists := EntryValue.GetValue<Boolean>('originalExists');
      TargetFileName := TPath.GetFullPath(
        TPath.Combine(AProjectDirectory, RelativeName));
      if not StartsText(IncludeTrailingPathDelimiter(
        TPath.GetFullPath(AProjectDirectory)), TargetFileName) then
        raise EIntegrationTransactionError.Create(
          'The backup contains an unsafe target path.');
      if OriginalExists then
      begin
        SourceFileName := TPath.Combine(
          TPath.Combine(ABackupDirectory, 'Files'), RelativeName);
        HashValue := EntryValue.FindValue('sha256');
        if HashValue <> nil then
          ExpectedHash := HashValue.Value
        else
          ExpectedHash := '';
        if ExpectedHash <> '' then
          VerifyFileSHA256(SourceFileName, ExpectedHash,
            'Restore stopped because the backup is not intact')
        else if not TFile.Exists(SourceFileName) then
          raise EIntegrationTransactionError.CreateFmt(
            'Restore stopped because a backup file is missing: %s',
            [SourceFileName]);
      end;
    end;
    for EntryValue in FilesArray do
    begin
      RelativeName := EntryValue.GetValue<string>('relativeName');
      OriginalExists := EntryValue.GetValue<Boolean>('originalExists');
      TargetFileName := TPath.GetFullPath(
        TPath.Combine(AProjectDirectory, RelativeName));
      if OriginalExists then
      begin
        SourceFileName := TPath.Combine(
          TPath.Combine(ABackupDirectory, 'Files'), RelativeName);
        HashValue := EntryValue.FindValue('sha256');
        if HashValue <> nil then
          ExpectedHash := HashValue.Value
        else
          ExpectedHash := '';
        TDirectory.CreateDirectory(
          TPath.GetDirectoryName(TargetFileName));
        TFile.Copy(SourceFileName, TargetFileName, True);
        if ExpectedHash <> '' then
          VerifyFileSHA256(TargetFileName, ExpectedHash,
            'Restore verification failed');
      end
      else if TFile.Exists(TargetFileName) then
        TFile.Delete(TargetFileName);
    end;
  finally
    ManifestObject.Free;
  end;
end;

end.
