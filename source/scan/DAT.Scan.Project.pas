unit DAT.Scan.Project;

interface

uses
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TProjectScanner = class
  private
    class function IsExcludedPath(const AProjectDirectory,
      AFileName: string): Boolean; static;
  public
    class function Scan(const AProfile: TProjectProfile): TProjectScanResult; static;
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
  const AResult: TProjectScanResult);
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
  Resources: TJSONArray;
  ResourceObject: TJSONObject;
  RootValue: TJSONValue;
  SeenSources: TStringList;
begin
  ManifestFileName := TPath.Combine(AProjectDirectory,
    ExternalResourceManifestName);
  if not TFile.Exists(ManifestFileName) then
    Exit;
  ManifestRoot := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(ManifestFileName, TEncoding.UTF8));
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
    Resources := TJSONObject(ManifestRoot).GetValue('resources') as TJSONArray;
    if Resources = nil then
      raise EConvertError.CreateFmt('%s must declare a resources array.',
        [ExternalResourceManifestName]);
    for ResourceItem in Resources do
    begin
      if not (ResourceItem is TJSONObject) then
        Continue;
      ResourceObject := TJSONObject(ResourceItem);
      DirectoryName := ResourceObject.GetValue<string>('directory', '');
      FilePattern := ResourceObject.GetValue<string>('filePattern', '*.json');
      PropertiesArray := ResourceObject.GetValue('properties') as TJSONArray;
      if (Trim(DirectoryName) = '') or (PropertiesArray = nil) then
        Continue;
      DirectoryName := TPath.GetFullPath(TPath.Combine(AProjectDirectory,
        DirectoryName));
      if not IsUnderDirectory(AProjectDirectory, DirectoryName) or
        not TDirectory.Exists(DirectoryName) then
        Continue;
      PropertyNames := TStringList.Create;
      try
        PropertyNames.Sorted := True;
        PropertyNames.Duplicates := dupIgnore;
        for PropertyName in PropertiesArray do
          if PropertyName is TJSONString then
            PropertyNames.Add(TJSONString(PropertyName).Value);
        FileNames := TDirectory.GetFiles(DirectoryName, FilePattern,
          TSearchOption.soTopDirectoryOnly);
        for FileName in FileNames do
        begin
          RootValue := TJSONObject.ParseJSONValue(
            TFile.ReadAllText(FileName, TEncoding.UTF8));
          try
            if RootValue <> nil then
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

class function TProjectScanner.IsExcludedPath(const AProjectDirectory,
  AFileName: string): Boolean;
var
  CandidateDirectory: string;
  DirectoryPart: string;
  DirectoryPrefix: string;
  NestedProjects: TArray<string>;
  RelativeDirectory: string;
  RelativeParts: TArray<string>;
  RelativePath: string;
begin
  DirectoryPrefix := IncludeTrailingPathDelimiter(
    LowerCase(TPath.GetFullPath(AProjectDirectory)));
  RelativePath := LowerCase(TPath.GetFullPath(AFileName));
  if StartsText(DirectoryPrefix, RelativePath) then
    Delete(RelativePath, 1, Length(DirectoryPrefix));
  if not IsUnderDirectory(AProjectDirectory, AFileName) then
    Exit(False);
  Result := StartsText('.git' + PathDelim, RelativePath) or
    StartsText('.agents' + PathDelim, RelativePath) or
    StartsText('__history' + PathDelim, RelativePath) or
    StartsText('__recovery' + PathDelim, RelativePath) or
    StartsText('bin' + PathDelim, RelativePath) or
    StartsText('dcu' + PathDelim, RelativePath) or
    StartsText('docs' + PathDelim, RelativePath) or
    StartsText('export' + PathDelim, RelativePath) or
    StartsText('localization' + PathDelim, RelativePath) or
    StartsText('samples' + PathDelim, RelativePath) or
    StartsText('source distributions' + PathDelim, RelativePath) or
    StartsText('test' + PathDelim, RelativePath) or
    StartsText('tests' + PathDelim, RelativePath);
  if Result then
    Exit;

  { Recursive discovery supplements the units explicitly named by the
    selected Delphi project. It must not promote generated build or test
    output into application source. Explicit DCCReference units were added
    before this filter and remain eligible even when a project deliberately
    keeps one beneath a normally generated directory. }
  RelativeDirectory := TPath.GetDirectoryName(RelativePath);
  RelativeParts := RelativeDirectory.Split([PathDelim]);
  for DirectoryPart in RelativeParts do
    if SameText(DirectoryPart, '.git') or
       SameText(DirectoryPart, '.agents') or
       SameText(DirectoryPart, '__history') or
       SameText(DirectoryPart, '__recovery') or
       SameText(DirectoryPart, 'backup') or
       SameText(DirectoryPart, 'backups') or
       SameText(DirectoryPart, 'bin') or
       SameText(DirectoryPart, 'build') or
       SameText(DirectoryPart, 'dcu') or
       SameText(DirectoryPart, 'debug') or
       SameText(DirectoryPart, 'release') or
       SameText(DirectoryPart, 'win32') or
       SameText(DirectoryPart, 'win64') or
       SameText(DirectoryPart, 'output') or
       SameText(DirectoryPart, 'outputs') or
       EndsText('_output', DirectoryPart) or
       ContainsText(DirectoryPart, '_output_') or
       ContainsText(DirectoryPart, 'contract_output') then
      Exit(True);

  { A source tree may contain a separate utility or conversion project. Such
    a nested project is not part of the application selected by the user. }
  CandidateDirectory := TPath.GetDirectoryName(TPath.GetFullPath(AFileName));
  while not SameText(CandidateDirectory,
    TPath.GetFullPath(AProjectDirectory)) do
  begin
    NestedProjects := TDirectory.GetFiles(CandidateDirectory, '*.dproj',
      TSearchOption.soTopDirectoryOnly);
    if Length(NestedProjects) = 0 then
      NestedProjects := TDirectory.GetFiles(CandidateDirectory, '*.dpr',
        TSearchOption.soTopDirectoryOnly);
    if Length(NestedProjects) > 0 then
      Exit(True);
    if SameText(TPath.GetDirectoryName(CandidateDirectory),
      CandidateDirectory) then
      Break;
    CandidateDirectory := TPath.GetDirectoryName(CandidateDirectory);
  end;
end;

class function TProjectScanner.Scan(
  const AProfile: TProjectProfile): TProjectScanResult;
var
  FileName: string;
  FileNames: TArray<string>;
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
        FileNames := TDirectory.GetFiles(ProjectDirectory, '*.dfm',
          TSearchOption.soAllDirectories)
      else
        FileNames := TDirectory.GetFiles(ProjectDirectory, '*.fmx',
          TSearchOption.soAllDirectories);

      for FileName in FileNames do
        if not IsExcludedPath(ProjectDirectory, FileName) then
          AddUniqueFileName(FormFiles, FileName);

      FileNames := TDirectory.GetFiles(ProjectDirectory, '*.pas',
        TSearchOption.soAllDirectories);
      for FileName in FileNames do
        if not IsExcludedPath(ProjectDirectory, FileName) then
          AddUniqueFileName(SourceFiles, FileName);

      { Do not scan every standalone .htm/.html file in the project tree as
        application UI. Real projects often carry websites, help pages,
        release notes, or download pages beside the Delphi source; those are
        separate localization assets and can explode the app catalog with
        non-form text. Browser-backed UI assembled in Pascal is still scanned
        by TPascalResourceStringScanner.ScanHtmlText. }

      for FileName in FormFiles do
      begin
        TTextFormScanner.ScanFile(FileName, AProfile.Framework, Result);
        Result.FormFilesScanned := Result.FormFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
      end;

      for FileName in SourceFiles do
      begin
        TPascalResourceStringScanner.ScanFile(FileName, Result);
        Result.SourceFilesScanned := Result.SourceFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
      end;

      for FileName in HtmlFiles do
      begin
        ScanHtmlFile(FileName, Result);
        Result.SourceFilesScanned := Result.SourceFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
      end;

      { Generated UI can also be fed by JSON or similar project data. Only
        resources explicitly declared by the project are eligible: this
        avoids treating databases, settings, or user content as interface
        copy while giving future applications a reusable opt-in contract. }
      ScanDeclaredExternalResources(ProjectDirectory, Result);
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
