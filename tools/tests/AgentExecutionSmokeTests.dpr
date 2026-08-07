program AgentExecutionSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows,
  DAT.Agent.Execution in '..\..\source\agent\DAT.Agent.Execution.pas';

const
  GitExecutable = 'C:\Program Files\Git\cmd\git.exe';

var
  Attempt: Integer;
  Arguments: string;
  LogFileName: string;
  Runner: TAgentProcessRunner;
  StartedAt: Cardinal;
  TestId: TGUID;

begin
  try
    if not TFile.Exists(GitExecutable) then
      raise Exception.Create('Git executable required by this test was not found.');
    if not StartsText(GetEnvironmentVariable('LOCALAPPDATA'),
      TAgentSettings.SettingsFileName) then
      raise Exception.Create('Agent settings are not stored under LocalAppData.');

    Arguments := TAgentProcessRunner.TranslationArguments(taCodex,
      TDirectory.GetCurrentDirectory, 'Default');
    if (Pos('exec', Arguments) = 0) or
       (Pos('workspace-write', Arguments) = 0) or
       (Pos('--ask-for-approval never', Arguments) = 0) then
      raise Exception.Create('Codex automatic arguments lost their safety contract.');
    Arguments := TAgentProcessRunner.TranslationArguments(taClaude,
      TDirectory.GetCurrentDirectory, 'Default');
    if (Pos('-p', Arguments) = 0) or
       (Pos('stream-json', Arguments) = 0) or
       (Pos('acceptEdits', Arguments) = 0) then
      raise Exception.Create('Claude automatic arguments are incomplete.');

    CreateGUID(TestId);
    LogFileName := TPath.Combine(TPath.GetTempPath,
      'DAT-AgentExecutionSmoke-' + GUIDToString(TestId) + '.log');
    Runner := TAgentProcessRunner.Create;
    try
      Runner.Start(GitExecutable, '--version',
        TDirectory.GetCurrentDirectory, '', LogFileName);
      StartedAt := Winapi.Windows.GetTickCount;
      while Runner.IsRunning and
        (Winapi.Windows.GetTickCount - StartedAt < 10000) do
        Sleep(10);
      if Runner.IsRunning then
        raise Exception.Create('Child process did not finish within 10 seconds.');
      if Runner.ExitCode <> 0 then
        raise Exception.CreateFmt('Child process exited with code %d.',
          [Runner.ExitCode]);
      if Pos('git version', LowerCase(Runner.ReadLog)) = 0 then
        raise Exception.Create('Redirected child-process output was not captured.');
    finally
      Runner.Free;
      for Attempt := 1 to 50 do
      begin
        try
          if TFile.Exists(LogFileName) then
            TFile.Delete(LogFileName);
          Break;
        except
          Sleep(20);
        end;
      end;
      for Attempt := 1 to 50 do
      begin
        try
          if TFile.Exists(TPath.ChangeExtension(LogFileName,
            '.prompt.txt')) then
            TFile.Delete(TPath.ChangeExtension(LogFileName, '.prompt.txt'));
          Break;
        except
          Sleep(20);
        end;
      end;
    end;
    Writeln('Agent execution, safety arguments, and logging passed.');
  except
    on E: Exception do
    begin
      Writeln('Agent execution smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
