unit DAT.Integration.Reset;

interface

uses
  System.Classes,
  System.SysUtils;

type
  ECompleteResetError = class(Exception);

  TCompleteResetPlan = class
  private
    FBaselineBackupDirectory: string;
    FProjectDirectory: string;
    FProjectName: string;
    FPreviewLines: TStringList;
    FRemovalDirectories: TStringList;
    FResetFiles: TStringList;
    FSafetyBackupDirectory: string;
  public
    constructor Create;
    destructor Destroy; override;
    property BaselineBackupDirectory: string
      read FBaselineBackupDirectory;
    property PreviewLines: TStringList read FPreviewLines;
    property SafetyBackupDirectory: string
      read FSafetyBackupDirectory;
  end;

  TCompleteResetEngine = class
  public
    class function BuildPlan(const AProjectName,
      AProjectDirectory: string): TCompleteResetPlan; static;
    class procedure Execute(const APlan: TCompleteResetPlan;
      const ASafetyBackupDirectory: string = ''); static;
  end;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Integration.Transaction,
  DAT.Integration.Types;

function CanonicalDirectory(const ADirectory: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(TPath.GetFullPath(ADirectory));
end;

function SafeTargetName(const AProjectDirectory,
  ARelativeName: string): string;
var
  ProjectPrefix: string;
begin
  ProjectPrefix := IncludeTrailingPathDelimiter(
    CanonicalDirectory(AProjectDirectory));
  Result := TPath.GetFullPath(TPath.Combine(
    AProjectDirectory, ARelativeName));
  if not StartsText(ProjectPrefix, Result) then
    raise ECompleteResetError.CreateFmt(
      'The reset backup contains an unsafe target path: %s',
      [ARelativeName]);
end;

function TryReadCandidate(const AManifestFileName,
  AProjectDirectory: string; out ACreatedUtc: string;
  out AContainsGeneratedFiles: Boolean): Boolean;
var
  EntryValue: TJSONValue;
  FilesArray: TJSONArray;
  JsonValue: TJSONValue;
  ManifestObject: TJSONObject;
  ManifestProjectDirectory: string;
begin
  Result := False;
  ACreatedUtc := '';
  AContainsGeneratedFiles := False;
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(
    AManifestFileName, TEncoding.UTF8));
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    Exit;
  end;
  ManifestObject := TJSONObject(JsonValue);
  try
    ManifestProjectDirectory := ManifestObject.GetValue<string>(
      'projectDirectory', '');
    if not SameText(CanonicalDirectory(ManifestProjectDirectory),
      CanonicalDirectory(AProjectDirectory)) then
      Exit;
    FilesArray := ManifestObject.GetValue('files') as TJSONArray;
    if (FilesArray = nil) or (FilesArray.Count = 0) then
      Exit;
    for EntryValue in FilesArray do
      if not EntryValue.GetValue<Boolean>('originalExists') then
      begin
        AContainsGeneratedFiles := True;
        Break;
      end;
    ACreatedUtc := ManifestObject.GetValue<string>('createdUtc', '');
    Result := True;
  finally
    ManifestObject.Free;
  end;
end;

function FindBaselineBackup(const AProjectName,
  AProjectDirectory: string): string;
var
  CandidateCreatedUtc: string;
  CandidateDirectory: string;
  CandidateHasGeneratedFiles: Boolean;
  ManifestFileName: string;
  NewestCreatedUtc: string;
  RootDirectory: string;
  SearchRoots: TStringList;
begin
  Result := '';
  NewestCreatedUtc := '';
  SearchRoots := TStringList.Create;
  try
    SearchRoots.CaseSensitive := False;
    SearchRoots.Duplicates := dupIgnore;
    SearchRoots.Sorted := True;
    if TDirectory.Exists('G:\') then
      SearchRoots.Add(TPath.Combine('G:\',
        AProjectName + ' Backup'));
    SearchRoots.Add(TPath.Combine(AProjectDirectory,
      'Localization\Integration Backups'));
    for RootDirectory in SearchRoots do
    begin
      if not TDirectory.Exists(RootDirectory) then
        Continue;
      for ManifestFileName in TDirectory.GetFiles(RootDirectory,
        'integration-backup.json', TSearchOption.soAllDirectories) do
      begin
        if not TryReadCandidate(ManifestFileName,
          AProjectDirectory, CandidateCreatedUtc,
          CandidateHasGeneratedFiles) then
          Continue;
        if not CandidateHasGeneratedFiles then
          Continue;
        CandidateDirectory := TPath.GetDirectoryName(ManifestFileName);
        if (Result = '') or
           (CompareText(CandidateCreatedUtc, NewestCreatedUtc) > 0) then
        begin
          Result := CandidateDirectory;
          NewestCreatedUtc := CandidateCreatedUtc;
        end;
      end;
    end;
  finally
    SearchRoots.Free;
  end;
end;

procedure LoadBaselineActions(const APlan: TCompleteResetPlan);
var
  EntryValue: TJSONValue;
  FilesArray: TJSONArray;
  JsonValue: TJSONValue;
  ManifestObject: TJSONObject;
  OriginalExists: Boolean;
  RelativeName: string;
begin
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(
    TPath.Combine(APlan.FBaselineBackupDirectory,
      'integration-backup.json'), TEncoding.UTF8));
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise ECompleteResetError.Create(
      'The selected integration backup manifest is invalid.');
  end;
  ManifestObject := TJSONObject(JsonValue);
  try
    FilesArray := ManifestObject.GetValue('files') as TJSONArray;
    for EntryValue in FilesArray do
    begin
      RelativeName := EntryValue.GetValue<string>('relativeName');
      OriginalExists := EntryValue.GetValue<Boolean>('originalExists');
      APlan.FResetFiles.Add(SafeTargetName(
        APlan.FProjectDirectory, RelativeName));
      if OriginalExists then
        APlan.FPreviewLines.Add('RESTORE ORIGINAL  ' + RelativeName)
      else
        APlan.FPreviewLines.Add('REMOVE GENERATED  ' + RelativeName);
    end;
  finally
    ManifestObject.Free;
  end;
end;

procedure AddTranslationDirectory(const APlan: TCompleteResetPlan;
  const ARelativeDirectory: string);
var
  DirectoryName: string;
  FileName: string;
begin
  DirectoryName := SafeTargetName(
    APlan.FProjectDirectory, ARelativeDirectory);
  if not TDirectory.Exists(DirectoryName) then
    Exit;
  APlan.FRemovalDirectories.Add(DirectoryName);
  APlan.FPreviewLines.Add('REMOVE FOLDER     ' + ARelativeDirectory);
  for FileName in TDirectory.GetFiles(DirectoryName, '*',
    TSearchOption.soAllDirectories) do
    APlan.FResetFiles.Add(FileName);
end;

constructor TCompleteResetPlan.Create;
begin
  inherited Create;
  FPreviewLines := TStringList.Create;
  FRemovalDirectories := TStringList.Create;
  FResetFiles := TStringList.Create;
  FRemovalDirectories.CaseSensitive := False;
  FRemovalDirectories.Duplicates := dupIgnore;
  FRemovalDirectories.Sorted := True;
  FResetFiles.CaseSensitive := False;
  FResetFiles.Duplicates := dupIgnore;
  FResetFiles.Sorted := True;
end;

destructor TCompleteResetPlan.Destroy;
begin
  FResetFiles.Free;
  FRemovalDirectories.Free;
  FPreviewLines.Free;
  inherited Destroy;
end;

class function TCompleteResetEngine.BuildPlan(const AProjectName,
  AProjectDirectory: string): TCompleteResetPlan;
begin
  Result := TCompleteResetPlan.Create;
  try
    Result.FProjectName := AProjectName;
    Result.FProjectDirectory := CanonicalDirectory(AProjectDirectory);
    Result.FBaselineBackupDirectory := FindBaselineBackup(
      AProjectName, Result.FProjectDirectory);
    if Result.FBaselineBackupDirectory = '' then
      raise ECompleteResetError.Create(
        'No original pre-integration backup was found for this project. ' +
        'Complete Reset will not guess or rewrite source without it.');
    Result.FPreviewLines.Add('BASELINE BACKUP  ' +
      Result.FBaselineBackupDirectory);
    Result.FPreviewLines.Add('');
    LoadBaselineActions(Result);
    AddTranslationDirectory(Result, 'Localization\Development');
    AddTranslationDirectory(Result, 'Localization\Languages');
    AddTranslationDirectory(Result, 'Localization\Runtime');
    Result.FPreviewLines.Add('');
    Result.FPreviewLines.Add(Format(
      'A new verified safety backup will preserve %d current file(s) before reset.',
      [Result.FResetFiles.Count]));
  except
    Result.Free;
    raise;
  end;
end;

class procedure TCompleteResetEngine.Execute(
  const APlan: TCompleteResetPlan;
  const ASafetyBackupDirectory: string);
var
  Change: TIntegrationFileChange;
  DirectoryIndex: Integer;
  FileName: string;
  SafetyChangeSet: TIntegrationChangeSet;
begin
  raise EInvalidOpException.Create(
    'Complete Reset is disabled. The translator treats target project files as read-only.');
  if APlan = nil then
    raise EArgumentNilException.Create(
      'A complete reset plan is required.');
  SafetyChangeSet := TIntegrationChangeSet.Create;
  try
    SafetyChangeSet.ProjectName := APlan.FProjectName;
    SafetyChangeSet.ProjectDirectory := APlan.FProjectDirectory;
    for FileName in APlan.FResetFiles do
      if TFile.Exists(FileName) then
      begin
        Change := TIntegrationFileChange.Create;
        Change.Kind := ickGeneratedUnit;
        Change.TargetFileName := FileName;
        Change.Description := 'Pre-reset safety copy';
        Change.OriginalExists := True;
        SafetyChangeSet.Changes.Add(Change);
      end;
    if SafetyChangeSet.Changes.Count = 0 then
      raise ECompleteResetError.Create(
        'No current translation or integration files were found to reset.');
    APlan.FSafetyBackupDirectory :=
      TIntegrationTransaction.CreateVerifiedBackup(
        SafetyChangeSet, ASafetyBackupDirectory,
        'Complete Reset Safety');
  finally
    SafetyChangeSet.Free;
  end;

  try
    TIntegrationTransaction.Restore(APlan.FProjectDirectory,
      APlan.FBaselineBackupDirectory);
    for DirectoryIndex := APlan.FRemovalDirectories.Count - 1 downto 0 do
      if TDirectory.Exists(APlan.FRemovalDirectories[DirectoryIndex]) then
        TDirectory.Delete(APlan.FRemovalDirectories[DirectoryIndex], True);
  except
    on E: Exception do
    begin
      try
        TIntegrationTransaction.Restore(APlan.FProjectDirectory,
          APlan.FSafetyBackupDirectory);
      except
        on RollbackError: Exception do
          raise ECompleteResetError.CreateFmt(
            'Complete Reset failed: %s. Safety restore also failed: %s. ' +
            'The verified safety backup is at %s',
            [E.Message, RollbackError.Message,
             APlan.FSafetyBackupDirectory]);
      end;
      raise ECompleteResetError.CreateFmt(
        'Complete Reset failed and the current project was restored: %s',
        [E.Message]);
    end;
  end;
end;

end.
