unit DAT.Core.Diagnostics;

interface

uses
  System.SysUtils;

type
  TDATDiagnosticSeverity = (dsInformation, dsWarning, dsError);

  TDATDiagnostics = class sealed
  private
    class var FEnabled: Boolean;
    class var FFileName: string;
    class function SeverityText(
      const ASeverity: TDATDiagnosticSeverity): string; static;
  public
    class procedure Configure(const AFileName: string;
      const AEnabled: Boolean = True); static;
    class procedure Log(const ACode, AOperation, AMessage: string;
      const ASeverity: TDATDiagnosticSeverity = dsInformation); static;
    class procedure LogException(const ACode, AOperation: string;
      const AException: Exception); static;
    class property Enabled: Boolean read FEnabled;
    class property FileName: string read FFileName;
  end;

implementation

uses
  System.Classes,
  System.IOUtils;

var
  DiagnosticLock: TObject;

function OneLine(const AValue: string): string;
begin
  Result := StringReplace(AValue, #13#10, ' | ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' | ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' | ', [rfReplaceAll]);
end;

class procedure TDATDiagnostics.Configure(const AFileName: string;
  const AEnabled: Boolean);
begin
  TMonitor.Enter(DiagnosticLock);
  try
    FFileName := Trim(AFileName);
    FEnabled := AEnabled and (FFileName <> '');
  finally
    TMonitor.Exit(DiagnosticLock);
  end;
end;

class procedure TDATDiagnostics.Log(const ACode, AOperation,
  AMessage: string; const ASeverity: TDATDiagnosticSeverity);
var
  DirectoryName: string;
  Line: string;
begin
  if not FEnabled then
    Exit;
  Line := Format('%s'#9'%s'#9'%s'#9'%s'#9'%s%s',
    [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now),
     SeverityText(ASeverity), OneLine(ACode), OneLine(AOperation),
     OneLine(AMessage), sLineBreak]);
  TMonitor.Enter(DiagnosticLock);
  try
    try
      DirectoryName := TPath.GetDirectoryName(FFileName);
      if DirectoryName <> '' then
        TDirectory.CreateDirectory(DirectoryName);
      TFile.AppendAllText(FFileName, Line, TEncoding.UTF8);
    except
      { Diagnostics must never take down the application it is observing. }
    end;
  finally
    TMonitor.Exit(DiagnosticLock);
  end;
end;

class procedure TDATDiagnostics.LogException(const ACode, AOperation: string;
  const AException: Exception);
begin
  if AException = nil then
    Log(ACode, AOperation, 'Unknown exception', dsError)
  else
    Log(ACode, AOperation,
      AException.ClassName + ': ' + AException.Message, dsError);
end;

class function TDATDiagnostics.SeverityText(
  const ASeverity: TDATDiagnosticSeverity): string;
begin
  case ASeverity of
    dsInformation: Result := 'INFO';
    dsWarning: Result := 'WARNING';
    dsError: Result := 'ERROR';
  else
    Result := 'UNKNOWN';
  end;
end;

initialization
  DiagnosticLock := TObject.Create;

finalization
  DiagnosticLock.Free;

end.
