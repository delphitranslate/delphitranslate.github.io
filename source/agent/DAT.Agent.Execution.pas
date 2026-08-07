unit DAT.Agent.Execution;

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows;

type
  TTranslationAgent = (taCodex, taClaude);

  TAgentSettings = class
  private
    FAgent: TTranslationAgent;
    FExecutableFileName: string;
    FModelName: string;
  public
    constructor Create;
    procedure Load;
    procedure Save;
    class function SettingsFileName: string; static;
    property Agent: TTranslationAgent read FAgent write FAgent;
    property ExecutableFileName: string read FExecutableFileName
      write FExecutableFileName;
    property ModelName: string read FModelName write FModelName;
  end;

  TAgentProcessRunner = class
  private
    FProcessHandle: THandle;
    FProcessId: Cardinal;
    FLogFileName: string;
    FExitCode: Cardinal;
    function BuildCommandLine(const AExecutableFileName,
      AArguments: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(const AExecutableFileName, AArguments,
      AWorkingDirectory, APrompt, ALogFileName: string);
    function Refresh: Boolean;
    function IsRunning: Boolean;
    procedure Cancel;
    function ReadLog: string;
    class function DetectExecutable(
      const AAgent: TTranslationAgent): string; static;
    class function AgentDisplayName(
      const AAgent: TTranslationAgent): string; static;
    class function TranslationArguments(const AAgent: TTranslationAgent;
      const AProjectDirectory, AModelName: string): string; static;
    property ExitCode: Cardinal read FExitCode;
    property LogFileName: string read FLogFileName;
    property ProcessId: Cardinal read FProcessId;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils;

function Quoted(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

constructor TAgentSettings.Create;
begin
  inherited Create;
  FAgent := taCodex;
  FModelName := 'Default';
end;

class function TAgentSettings.SettingsFileName: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'),
    'DelphiAppTranslationStudio\agent-settings.ini');
end;

procedure TAgentSettings.Load;
var
  EngineValue: Integer;
  Settings: TMemIniFile;
begin
  if not TFile.Exists(SettingsFileName) then
    Exit;
  Settings := TMemIniFile.Create(SettingsFileName, TEncoding.UTF8);
  try
    EngineValue := Settings.ReadInteger('Agent', 'Engine', Ord(taCodex));
    if (EngineValue >= Ord(Low(TTranslationAgent))) and
       (EngineValue <= Ord(High(TTranslationAgent))) then
      FAgent := TTranslationAgent(EngineValue)
    else
      FAgent := taCodex;
    FExecutableFileName := Settings.ReadString('Agent', 'Executable', '');
    FModelName := Settings.ReadString('Agent', 'Model', 'Default');
    if Trim(FModelName) = '' then
      FModelName := 'Default';
  finally
    Settings.Free;
  end;
end;

procedure TAgentSettings.Save;
var
  DirectoryName: string;
  Settings: TMemIniFile;
begin
  DirectoryName := TPath.GetDirectoryName(SettingsFileName);
  TDirectory.CreateDirectory(DirectoryName);
  Settings := TMemIniFile.Create(SettingsFileName, TEncoding.UTF8);
  try
    Settings.WriteInteger('Agent', 'Engine', Ord(FAgent));
    Settings.WriteString('Agent', 'Executable', FExecutableFileName);
    Settings.WriteString('Agent', 'Model', FModelName);
    Settings.UpdateFile;
  finally
    Settings.Free;
  end;
end;

constructor TAgentProcessRunner.Create;
begin
  inherited Create;
  FProcessHandle := 0;
  FExitCode := Cardinal(-1);
end;

destructor TAgentProcessRunner.Destroy;
begin
  if IsRunning then
    Cancel;
  if FProcessHandle <> 0 then
    CloseHandle(FProcessHandle);
  inherited Destroy;
end;

function TAgentProcessRunner.BuildCommandLine(const AExecutableFileName,
  AArguments: string): string;
var
  Extension: string;
begin
  Extension := LowerCase(TPath.GetExtension(AExecutableFileName));
  if (Extension = '.cmd') or (Extension = '.bat') then
    Result := Quoted(GetEnvironmentVariable('ComSpec')) +
      ' /D /S /C ""' + AExecutableFileName + '" ' + AArguments + '"'
  else
    Result := Quoted(AExecutableFileName) + ' ' + AArguments;
end;

procedure TAgentProcessRunner.Start(const AExecutableFileName, AArguments,
  AWorkingDirectory, APrompt, ALogFileName: string);
var
  CommandLine: string;
  ExecutableToLaunch: string;
  LogHandle: THandle;
  ProcessInfo: TProcessInformation;
  PromptFileName: string;
  PromptHandle: THandle;
  Security: TSecurityAttributes;
  StartupInfo: TStartupInfo;
begin
  if IsRunning then
    raise Exception.Create('A translation agent is already running.');
  if not TFile.Exists(AExecutableFileName) then
    raise Exception.CreateFmt('Agent executable not found: %s',
      [AExecutableFileName]);

  FLogFileName := ALogFileName;
  TDirectory.CreateDirectory(TPath.GetDirectoryName(FLogFileName));
  PromptFileName := TPath.ChangeExtension(FLogFileName, '.prompt.txt');
  TFile.WriteAllText(PromptFileName, APrompt, TEncoding.UTF8);

  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  PromptHandle := CreateFile(PChar(PromptFileName), GENERIC_READ,
    FILE_SHARE_READ, @Security, OPEN_EXISTING, FILE_ATTRIBUTE_TEMPORARY, 0);
  if PromptHandle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  LogHandle := CreateFile(PChar(FLogFileName), GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, @Security, CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL, 0);
  if LogHandle = INVALID_HANDLE_VALUE then
  begin
    CloseHandle(PromptHandle);
    RaiseLastOSError;
  end;
  try
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdInput := PromptHandle;
    StartupInfo.hStdOutput := LogHandle;
    StartupInfo.hStdError := LogHandle;
    FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);

    CommandLine := BuildCommandLine(AExecutableFileName, AArguments);
    if SameText(LowerCase(TPath.GetExtension(AExecutableFileName)), '.cmd') or
       SameText(LowerCase(TPath.GetExtension(AExecutableFileName)), '.bat') then
      ExecutableToLaunch := GetEnvironmentVariable('ComSpec')
    else
      ExecutableToLaunch := AExecutableFileName;
    UniqueString(CommandLine);
    if not CreateProcess(PChar(ExecutableToLaunch), PChar(CommandLine), nil,
      nil, True, CREATE_NO_WINDOW, nil, PChar(AWorkingDirectory),
      StartupInfo, ProcessInfo) then
      RaiseLastOSError;
    CloseHandle(ProcessInfo.hThread);
    if FProcessHandle <> 0 then
      CloseHandle(FProcessHandle);
    FProcessHandle := ProcessInfo.hProcess;
    FProcessId := ProcessInfo.dwProcessId;
    FExitCode := STILL_ACTIVE;
  finally
    CloseHandle(LogHandle);
    CloseHandle(PromptHandle);
  end;
end;

function TAgentProcessRunner.Refresh: Boolean;
begin
  if FProcessHandle = 0 then
    Exit(False);
  if not GetExitCodeProcess(FProcessHandle, FExitCode) then
    RaiseLastOSError;
  Result := FExitCode = STILL_ACTIVE;
end;

function TAgentProcessRunner.IsRunning: Boolean;
begin
  Result := (FProcessHandle <> 0) and Refresh;
end;

procedure TAgentProcessRunner.Cancel;
begin
  if (FProcessHandle <> 0) and Refresh then
  begin
    TerminateProcess(FProcessHandle, ERROR_CANCELLED);
    WaitForSingleObject(FProcessHandle, 5000);
    Refresh;
  end;
end;

function TAgentProcessRunner.ReadLog: string;
var
  Bytes: TBytes;
  Stream: TFileStream;
begin
  if (FLogFileName = '') or not TFile.Exists(FLogFileName) then
    Exit('');
  Stream := TFileStream.Create(FLogFileName,
    fmOpenRead or fmShareDenyNone);
  try
    SetLength(Bytes, Stream.Size);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
    Result := TEncoding.UTF8.GetString(Bytes);
  finally
    Stream.Free;
  end;
end;

class function TAgentProcessRunner.DetectExecutable(
  const AAgent: TTranslationAgent): string;
var
  Candidate: string;
  FilePart: array[0..MAX_PATH] of Char;
  FilePartPointer: PChar;
  FoundLength: Cardinal;
begin
  Result := '';
  if AAgent = taCodex then
    Candidate := TPath.Combine(GetEnvironmentVariable('APPDATA'),
      'npm\codex.cmd')
  else
    Candidate := TPath.Combine(GetEnvironmentVariable('USERPROFILE'),
      '.local\bin\claude.exe');
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  if AAgent = taCodex then
    Candidate := 'codex.exe'
  else
    Candidate := 'claude.exe';
  FilePartPointer := nil;
  FoundLength := SearchPath(nil, PChar(Candidate), nil, Length(FilePart),
    @FilePart[0], FilePartPointer);
  if FoundLength > 0 then
  begin
    Candidate := FilePart;
    if Pos('\WindowsApps\OpenAI.Codex_', Candidate) = 0 then
      Result := Candidate;
  end;
end;

class function TAgentProcessRunner.AgentDisplayName(
  const AAgent: TTranslationAgent): string;
begin
  case AAgent of
    taCodex: Result := 'Codex CLI';
    taClaude: Result := 'Claude Code';
  else
    Result := 'Translation agent';
  end;
end;

class function TAgentProcessRunner.TranslationArguments(
  const AAgent: TTranslationAgent; const AProjectDirectory,
  AModelName: string): string;
begin
  case AAgent of
    taCodex:
      begin
        Result := '--ask-for-approval never exec --ephemeral --json ' +
          '--sandbox workspace-write -C ' + Quoted(AProjectDirectory);
        if not SameText(AModelName, 'Default') and
           (Trim(AModelName) <> '') then
          Result := Result + ' --model ' + Quoted(AModelName);
        Result := Result + ' -';
      end;
    taClaude:
      begin
        Result := '-p --output-format stream-json --verbose ' +
          '--permission-mode acceptEdits';
        if not SameText(AModelName, 'Default') and
           (Trim(AModelName) <> '') then
          Result := Result + ' --model ' + Quoted(AModelName);
      end;
  else
    Result := '';
  end;
end;

end.
