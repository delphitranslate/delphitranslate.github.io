unit DAT.Scan.Project;

interface

uses
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TProjectScanner = class
  private
  public
    class function Scan(const AProfile: TProjectProfile): TProjectScanResult;
      overload; static;
    class function Scan(const AProfile: TProjectProfile;
      const ACancelCheck: TProjectScanCancelCheck;
      const AProgress: TProjectScanProgress = nil): TProjectScanResult;
      overload; static;
  end;

implementation

uses
  System.Classes,
  System.Diagnostics,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.RegularExpressions,
  System.StrUtils,
  System.SysUtils,
  DAT.Scan.Context,
  DAT.Scan.FormText,
  DAT.Scan.PascalResources,
  DAT.Scan.Quality,
  DAT.Scan.TextCodec;

const
  ExternalResourceManifestName = 'dat-translatable-resources.json';

function IsUnderDirectory(const ADirectory, AFileName: string): Boolean; forward;

procedure ValidateUniqueJsonMemberNames(const AValue: TJSONValue;
  const AFileName, AJsonPath: string);
var
  ChildPath: string;
  Index: Integer;
  MemberNames: TStringList;
  Pair: TJSONPair;
begin
  if AValue is TJSONObject then
  begin
    MemberNames := TStringList.Create;
    try
      MemberNames.CaseSensitive := True;
      MemberNames.Sorted := True;
      MemberNames.Duplicates := dupError;
      for Pair in TJSONObject(AValue) do
      begin
        try
          MemberNames.Add(Pair.JsonString.Value);
        except
          on E: EStringListError do
            raise EConvertError.CreateFmt(
              '%s contains duplicate JSON member "%s" at %s.',
              [AFileName, Pair.JsonString.Value, AJsonPath]);
        end;
        ChildPath := AJsonPath + '.' + Pair.JsonString.Value;
        ValidateUniqueJsonMemberNames(Pair.JsonValue, AFileName, ChildPath);
      end;
    finally
      MemberNames.Free;
    end;
  end
  else if AValue is TJSONArray then
    for Index := 0 to TJSONArray(AValue).Count - 1 do
      ValidateUniqueJsonMemberNames(TJSONArray(AValue).Items[Index],
        AFileName, Format('%s[%d]', [AJsonPath, Index]));
end;

function ParseValidatedJsonFile(const AFileName: string): TJSONValue;
begin
  Result := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if Result = nil then
    raise EConvertError.CreateFmt('%s is not valid JSON.', [AFileName]);
  try
    ValidateUniqueJsonMemberNames(Result, AFileName, '$');
  except
    Result.Free;
    raise;
  end;
end;

procedure AddExternalResourceItem(const AResult: TProjectScanResult;
  const AFileName, APropertyName, ASourceText: string;
  const ASeenSources: TStrings);
var
  ScanItem: TScanItem;
  SourceHash: string;
  Text: string;
begin
  Text := Trim(ASourceText);
  if (Text = '') or (ASeenSources.IndexOf(Text) >= 0) then
    Exit;
  ASeenSources.Add(Text);
  SourceHash := LowerCase(THashSHA2.GetHashString(Text));
  ScanItem := TScanItem.Create;
  ScanItem.Key := Format('ExternalData.%s.%s',
    [APropertyName, Copy(SourceHash, 1, 24)]);
  ScanItem.SourceText := Text;
  ScanItem.FormName := 'ExternalData';
  ScanItem.ComponentName := APropertyName;
  ScanItem.ComponentClassName := 'TJSONObject';
  ScanItem.PropertyName := APropertyName;
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := 0;
  ScanItem.Framework := tfUnknown;
  ScanItem.Kind := stkRuntimeAssignment;
  ScanItem.RuntimeTextRole := rtrStaticText;
  TScanContextAnalyzer.Analyze(ScanItem);
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

procedure ScanExternalJsonValue(const AValue: TJSONValue;
  const AFileName: string; const APropertyNames, ASeenSources: TStrings;
  const AResult: TProjectScanResult);
var
  ArrayValue: TJSONValue;
  Pair: TJSONPair;
begin
  if AValue is TJSONObject then
    for Pair in TJSONObject(AValue) do
    begin
      if (Pair.JsonValue is TJSONString) and
        (APropertyNames.IndexOf(Pair.JsonString.Value) >= 0) then
        AddExternalResourceItem(AResult, AFileName, Pair.JsonString.Value,
          TJSONString(Pair.JsonValue).Value, ASeenSources);
      ScanExternalJsonValue(Pair.JsonValue, AFileName, APropertyNames,
        ASeenSources, AResult);
    end
  else if AValue is TJSONArray then
    for ArrayValue in TJSONArray(AValue) do
      ScanExternalJsonValue(ArrayValue, AFileName, APropertyNames,
        ASeenSources, AResult);
end;

procedure ScanDeclaredExternalResources(const AProjectDirectory: string;
  const AResult: TProjectScanResult;
  const ACancelCheck: TProjectScanCancelCheck);
var
  DirectoryName: string;
  FileName: string;
  FileNames: TArray<string>;
  FilePattern: string;
  ManifestFileName: string;
  ManifestRoot: TJSONValue;
  PropertiesArray: TJSONArray;
  PropertyName: TJSONValue;
  PropertyNames: TStringList;
  ResourceItem: TJSONValue;
  ResourceIndex: Integer;
  Resources: TJSONArray;
  ResourceObject: TJSONObject;
  RootValue: TJSONValue;
  SchemaVersion: Integer;
  SeenSources: TStringList;
begin
  ManifestFileName := TPath.Combine(AProjectDirectory,
    ExternalResourceManifestName);
  if not TFile.Exists(ManifestFileName) then
    Exit;
  ManifestRoot := ParseValidatedJsonFile(ManifestFileName);
  if not (ManifestRoot is TJSONObject) then
  begin
    ManifestRoot.Free;
    raise EConvertError.CreateFmt('%s must contain a JSON object.',
      [ExternalResourceManifestName]);
  end;
  SeenSources := TStringList.Create;
  try
    SeenSources.Sorted := True;
    SeenSources.Duplicates := dupIgnore;
    SchemaVersion := TJSONObject(ManifestRoot).GetValue<Integer>(
      'schemaVersion', 0);
    if SchemaVersion <> 1 then
      raise EConvertError.CreateFmt(
        '%s schemaVersion must be 1; found %d.',
        [ExternalResourceManifestName, SchemaVersion]);
    if not (TJSONObject(ManifestRoot).GetValue('resources') is TJSONArray) then
      Resources := nil
    else
      Resources := TJSONArray(TJSONObject(ManifestRoot).GetValue('resources'));
    if Resources = nil then
      raise EConvertError.CreateFmt('%s must declare a resources array.',
        [ExternalResourceManifestName]);
    for ResourceIndex := 0 to Resources.Count - 1 do
    begin
      ResourceItem := Resources.Items[ResourceIndex];
      if not (ResourceItem is TJSONObject) then
        raise EConvertError.CreateFmt(
          '%s resources[%d] must be a JSON object.',
          [ExternalResourceManifestName, ResourceIndex]);
      ResourceObject := TJSONObject(ResourceItem);
      DirectoryName := ResourceObject.GetValue<string>('directory', '');
      FilePattern := ResourceObject.GetValue<string>('filePattern', '*.json');
      if not (ResourceObject.GetValue('properties') is TJSONArray) then
        PropertiesArray := nil
      else
        PropertiesArray := TJSONArray(ResourceObject.GetValue('properties'));
      if Trim(DirectoryName) = '' then
        raise EConvertError.CreateFmt(
          '%s resources[%d].directory must not be empty.',
          [ExternalResourceManifestName, ResourceIndex]);
      if (Trim(FilePattern) = '') or ContainsText(FilePattern, '..') or
        (Pos(PathDelim, FilePattern) > 0) or (Pos('/', FilePattern) > 0) then
        raise EConvertError.CreateFmt(
          '%s resources[%d].filePattern must be a file-name pattern, not a path.',
          [ExternalResourceManifestName, ResourceIndex]);
      if PropertiesArray = nil then
        raise EConvertError.CreateFmt(
          '%s resources[%d].properties must be an array.',
          [ExternalResourceManifestName, ResourceIndex]);
      DirectoryName := TPath.GetFullPath(TPath.Combine(AProjectDirectory,
        DirectoryName));
      if not IsUnderDirectory(AProjectDirectory, DirectoryName) then
        raise EConvertError.CreateFmt(
          '%s resources[%d].directory resolves outside the selected project.',
          [ExternalResourceManifestName, ResourceIndex]);
      if not TDirectory.Exists(DirectoryName) then
        raise EConvertError.CreateFmt(
          '%s declares a missing resource directory: %s.',
          [ExternalResourceManifestName, DirectoryName]);
      PropertyNames := TStringList.Create;
      try
        PropertyNames.Sorted := True;
        PropertyNames.Duplicates := dupIgnore;
        for PropertyName in PropertiesArray do
          if not (PropertyName is TJSONString) or
             (Trim(TJSONString(PropertyName).Value) = '') then
            raise EConvertError.CreateFmt(
              '%s resources[%d].properties must contain non-empty strings.',
              [ExternalResourceManifestName, ResourceIndex])
          else
            PropertyNames.Add(TJSONString(PropertyName).Value);
        if PropertyNames.Count = 0 then
          raise EConvertError.CreateFmt(
            '%s resources[%d].properties must not be empty.',
            [ExternalResourceManifestName, ResourceIndex]);
        FileNames := TDirectory.GetFiles(DirectoryName, FilePattern,
          TSearchOption.soTopDirectoryOnly);
        TArray.Sort<string>(FileNames);
        for FileName in FileNames do
        begin
          if Assigned(ACancelCheck) and ACancelCheck() then
            raise EProjectScanCancelled.Create('Project scan was cancelled.');
          RootValue := ParseValidatedJsonFile(FileName);
          try
            ScanExternalJsonValue(RootValue, FileName, PropertyNames,
              SeenSources, AResult);
          finally
            RootValue.Free;
          end;
        end;
      finally
        PropertyNames.Free;
      end;
    end;
  finally
    SeenSources.Free;
    ManifestRoot.Free;
  end;
end;

function IsUnderDirectory(const ADirectory, AFileName: string): Boolean;
var
  DirectoryPrefix: string;
  FullFileName: string;
begin
  DirectoryPrefix := IncludeTrailingPathDelimiter(
    LowerCase(TPath.GetFullPath(ADirectory)));
  FullFileName := LowerCase(TPath.GetFullPath(AFileName));
  Result := StartsText(DirectoryPrefix, FullFileName);
end;

procedure AddUniqueFileName(const AFiles: TList<string>; const AFileName: string);
var
  ExistingFileName: string;
  FullFileName: string;
begin
  if Trim(AFileName) = '' then
    Exit;
  FullFileName := TPath.GetFullPath(AFileName);
  if not TFile.Exists(FullFileName) then
    Exit;
  for ExistingFileName in AFiles do
    if SameText(ExistingFileName, FullFileName) then
      Exit;
  AFiles.Add(FullFileName);
end;

function ExtractXmlAttribute(const AText, AAttributeName: string): string;
var
  AttributeAt: Integer;
  QuoteChar: Char;
  StartAt: Integer;
  EndAt: Integer;
begin
  Result := '';
  AttributeAt := Pos(LowerCase(AAttributeName + '='), LowerCase(AText));
  if AttributeAt = 0 then
    Exit;
  StartAt := AttributeAt + Length(AAttributeName) + 1;
  if StartAt > Length(AText) then
    Exit;
  QuoteChar := AText[StartAt];
  if not CharInSet(QuoteChar, ['"', '''']) then
    Exit;
  Inc(StartAt);
  EndAt := StartAt;
  while (EndAt <= Length(AText)) and (AText[EndAt] <> QuoteChar) do
    Inc(EndAt);
  if EndAt <= Length(AText) then
    Result := Copy(AText, StartAt, EndAt - StartAt);
end;

procedure CollectProjectReferences(const AProjectFileName: string;
  const AFramework: TTargetFramework; const AFormFiles, ASourceFiles: TList<string>);
var
  Extension: string;
  IncludeName: string;
  Line: string;
  Lines: TStringList;
  ProjectDirectory: string;
  ResolvedFileName: string;
begin
  ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);
  if AFramework = tfVCL then
    Extension := '.dfm'
  else
    Extension := '.fmx';

  Lines := TStringList.Create;
  try
    LoadDelphiTextFile(AProjectFileName, Lines);
    for Line in Lines do
    begin
      if not ContainsText(Line, '<DCCReference') then
        Continue;
      IncludeName := ExtractXmlAttribute(Line, 'Include');
      if IncludeName = '' then
        Continue;
      ResolvedFileName := TPath.GetFullPath(
        TPath.Combine(ProjectDirectory, IncludeName));
      if SameText(TPath.GetExtension(ResolvedFileName), '.pas') then
      begin
        AddUniqueFileName(ASourceFiles, ResolvedFileName);
        AddUniqueFileName(AFormFiles, TPath.ChangeExtension(
          ResolvedFileName, Extension));
      end
      else if SameText(TPath.GetExtension(ResolvedFileName), Extension) then
        AddUniqueFileName(AFormFiles, ResolvedFileName);
    end;
  finally
    Lines.Free;
  end;
end;

function DecodeHtmlText(const AValue: string): string;
begin
  Result := AValue;
  Result := StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&#39;', '''', [rfReplaceAll, rfIgnoreCase]);
  Result := Trim(TRegEx.Replace(Result, '\s+', ' '));
end;

function LooksLikeHumanText(const AValue: string): Boolean;
var
  CharacterIndex: Integer;
begin
  Result := False;
  if Length(Trim(AValue)) < 2 then
    Exit;
  if ContainsText(AValue, '://') or ContainsText(AValue, '@') or
    ContainsText(AValue, '.css') or ContainsText(AValue, '.js') then
    Exit;
  for CharacterIndex := 1 to Length(AValue) do
    if CharInSet(AValue[CharacterIndex], ['A'..'Z', 'a'..'z']) then
      Exit(True);
end;

procedure AddHtmlScanItem(const AResult: TProjectScanResult;
  const AFileName, ASourceText: string; const AIndex: Integer);
var
  ScanItem: TScanItem;
begin
  if not LooksLikeHumanText(ASourceText) then
    Exit;
  ScanItem := TScanItem.Create;
  ScanItem.Key := Format('%s.HtmlText.%d',
    [TPath.GetFileNameWithoutExtension(AFileName), AIndex]);
  ScanItem.SourceText := ASourceText;
  ScanItem.FormName := TPath.GetFileNameWithoutExtension(AFileName);
  ScanItem.ComponentName := 'HtmlText';
  ScanItem.ComponentClassName := 'TWebBrowser';
  ScanItem.PropertyName := 'BrowserText';
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := 0;
  ScanItem.CollectionIndex := AIndex;
  ScanItem.Framework := tfUnknown;
  ScanItem.Kind := stkRuntimeAssignment;
  ScanItem.RuntimeTextRole := rtrStaticText;
  TScanContextAnalyzer.Analyze(ScanItem);
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

procedure ScanHtmlFile(const AFileName: string; const AResult: TProjectScanResult);
var
  CleanHtml: string;
  Index: Integer;
  Parts: TArray<string>;
  Seen: TStringList;
  RawText: string;
  Text: string;
begin
  CleanHtml := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  CleanHtml := TRegEx.Replace(CleanHtml, '<script\b[^>]*>.*?</script>', ' ',
    [roIgnoreCase, roSingleLine]);
  CleanHtml := TRegEx.Replace(CleanHtml, '<style\b[^>]*>.*?</style>', ' ',
    [roIgnoreCase, roSingleLine]);
  CleanHtml := TRegEx.Replace(CleanHtml, '<[^>]+>', sLineBreak,
    [roIgnoreCase, roSingleLine]);
  Parts := CleanHtml.Split([sLineBreak]);
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Index := 0;
    for RawText in Parts do
    begin
      Text := DecodeHtmlText(RawText);
      if not LooksLikeHumanText(Text) or (Seen.IndexOf(Text) >= 0) then
        Continue;
      Seen.Add(Text);
      AddHtmlScanItem(AResult, AFileName, Text, Index);
      Inc(Index);
    end;
  finally
    Seen.Free;
  end;
end;

function IsExcludedDirectoryName(const ADirectoryName: string): Boolean;
var
  Name: string;
begin
  Name := LowerCase(Trim(ADirectoryName));
  Result :=
    (Name = '.git') or (Name = '.agents') or
    (Name = '__history') or (Name = '__recovery') or
    (Name = 'backup') or (Name = 'backups') or
    (Name = 'bin') or (Name = 'build') or (Name = 'dcu') or
    (Name = 'debug') or (Name = 'release') or
    (Name = 'win32') or (Name = 'win64') or
    (Name = 'output') or (Name = 'outputs') or
    (Name = 'docs') or (Name = 'export') or
    (Name = 'localization') or (Name = 'samples') or
    (Name = 'source distributions') or
    (Name = 'test') or (Name = 'tests') or
    EndsText('_output', Name) or ContainsText(Name, '_output_') or
    ContainsText(Name, 'contract_output');
end;

procedure AddScanDiagnostic(const AResult: TProjectScanResult;
  const ASeverity: TScanDiagnosticSeverity; const AMessage,
  AFileName: string);
var
  Diagnostic: TScanDiagnostic;
begin
  Diagnostic := TScanDiagnostic.Create;
  Diagnostic.Severity := ASeverity;
  Diagnostic.MessageText := AMessage;
  Diagnostic.SourceFileName := AFileName;
  AResult.Diagnostics.Add(Diagnostic);
end;

procedure CollectSupplementalFiles(const AProjectDirectory, AFilePattern: string;
  const AFiles: TList<string>; const AResult: TProjectScanResult;
  const ACancelCheck: TProjectScanCancelCheck);
var
  CurrentDirectory: string;
  Directories: TStringList;
  DirectoryName: string;
  Files: TStringList;
  FileName: string;
  Pending: TQueue<string>;
  ProjectFiles: TArray<string>;
  SeenDirectories: TDictionary<string, Boolean>;
begin
  Pending := TQueue<string>.Create;
  SeenDirectories := TDictionary<string, Boolean>.Create;
  Directories := TStringList.Create;
  Files := TStringList.Create;
  try
    Directories.Sorted := True;
    Files.Sorted := True;
    Pending.Enqueue(TPath.GetFullPath(AProjectDirectory));
    while Pending.Count > 0 do
    begin
      if Assigned(ACancelCheck) and ACancelCheck() then
        raise EProjectScanCancelled.Create('Project scan was cancelled.');
      CurrentDirectory := Pending.Dequeue;
      if SeenDirectories.ContainsKey(LowerCase(CurrentDirectory)) then
        Continue;
      SeenDirectories.Add(LowerCase(CurrentDirectory), True);
      try
        if not SameText(CurrentDirectory,
          TPath.GetFullPath(AProjectDirectory)) then
        begin
          ProjectFiles := TDirectory.GetFiles(CurrentDirectory, '*.dproj',
            TSearchOption.soTopDirectoryOnly);
          if Length(ProjectFiles) = 0 then
            ProjectFiles := TDirectory.GetFiles(CurrentDirectory, '*.dpr',
              TSearchOption.soTopDirectoryOnly);
          if Length(ProjectFiles) > 0 then
            Continue;
        end;

        Files.Clear;
        Files.AddStrings(TDirectory.GetFiles(CurrentDirectory, AFilePattern,
          TSearchOption.soTopDirectoryOnly));
        for FileName in Files do
          AddUniqueFileName(AFiles, FileName);

        Directories.Clear;
        Directories.AddStrings(TDirectory.GetDirectories(CurrentDirectory,
          '*', TSearchOption.soTopDirectoryOnly));
        for DirectoryName in Directories do
          if not IsExcludedDirectoryName(TPath.GetFileName(DirectoryName)) then
            Pending.Enqueue(DirectoryName);
      except
        on E: Exception do
          AddScanDiagnostic(AResult, sdsWarning,
            'Directory skipped because it could not be enumerated: ' +
            E.Message, CurrentDirectory);
      end;
    end;
  finally
    Files.Free;
    Directories.Free;
    SeenDirectories.Free;
    Pending.Free;
  end;
end;

class function TProjectScanner.Scan(
  const AProfile: TProjectProfile): TProjectScanResult;
begin
  Result := Scan(AProfile, nil, nil);
end;

class function TProjectScanner.Scan(const AProfile: TProjectProfile;
  const ACancelCheck: TProjectScanCancelCheck;
  const AProgress: TProjectScanProgress): TProjectScanResult;
var
  FileName: string;
  FormFiles: TList<string>;
  HtmlFiles: TList<string>;
  ProjectDirectory: string;
  SourceFiles: TList<string>;
  Stopwatch: TStopwatch;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('A detected Delphi project is required.');
  if AProfile.Framework = tfUnknown then
    raise EArgumentException.Create(
      'The project framework must be identified before scanning.');

  Result := TProjectScanResult.Create;
  try
    ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
    Stopwatch := TStopwatch.StartNew;
    FormFiles := TList<string>.Create;
    HtmlFiles := TList<string>.Create;
    SourceFiles := TList<string>.Create;
    try
      CollectProjectReferences(AProfile.ProjectFileName, AProfile.Framework,
        FormFiles, SourceFiles);

      if AProfile.Framework = tfVCL then
        CollectSupplementalFiles(ProjectDirectory, '*.dfm', FormFiles,
          Result, ACancelCheck)
      else
        CollectSupplementalFiles(ProjectDirectory, '*.fmx', FormFiles,
          Result, ACancelCheck);

      CollectSupplementalFiles(ProjectDirectory, '*.pas', SourceFiles,
        Result, ACancelCheck);

      { Do not scan every standalone .htm/.html file in the project tree as
        application UI. Real projects often carry websites, help pages,
        release notes, or download pages beside the Delphi source; those are
        separate localization assets and can explode the app catalog with
        non-form text. Browser-backed UI assembled in Pascal is still scanned
        by TPascalResourceStringScanner.ScanHtmlText. }

      for FileName in FormFiles do
      begin
        if Assigned(ACancelCheck) and ACancelCheck() then
          raise EProjectScanCancelled.Create('Project scan was cancelled.');
        TTextFormScanner.ScanFile(FileName, AProfile.Framework, Result);
        Result.FormFilesScanned := Result.FormFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
        if Assigned(AProgress) then
          AProgress('Forms', Result.FilesScanned);
      end;

      for FileName in SourceFiles do
      begin
        if Assigned(ACancelCheck) and ACancelCheck() then
          raise EProjectScanCancelled.Create('Project scan was cancelled.');
        TPascalResourceStringScanner.ScanFile(FileName, Result);
        Result.SourceFilesScanned := Result.SourceFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
        if Assigned(AProgress) then
          AProgress('Pascal source', Result.FilesScanned);
      end;

      for FileName in HtmlFiles do
      begin
        if Assigned(ACancelCheck) and ACancelCheck() then
          raise EProjectScanCancelled.Create('Project scan was cancelled.');
        ScanHtmlFile(FileName, Result);
        Result.SourceFilesScanned := Result.SourceFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
        if Assigned(AProgress) then
          AProgress('HTML', Result.FilesScanned);
      end;

      { Generated UI can also be fed by JSON or similar project data. Only
        resources explicitly declared by the project are eligible: this
        avoids treating databases, settings, or user content as interface
        copy while giving future applications a reusable opt-in contract. }
      ScanDeclaredExternalResources(ProjectDirectory, Result, ACancelCheck);
    finally
      SourceFiles.Free;
      HtmlFiles.Free;
      FormFiles.Free;
    end;

    { Now that every string has been read, each one can be told what the
      application is about and what stands beside it. Nothing here needs a
      person: it is all in what was just scanned. }
    TScanContextAnalyzer.Enrich(Result, AProfile.ProjectName);

    Stopwatch.Stop;
    Result.ElapsedMilliseconds := Stopwatch.ElapsedMilliseconds;
  except
    Result.Free;
    raise;
  end;
end;

end.
