program SampleVCLApp;

{ The VCL sample, and the far end of the pipeline.

  Everything upstream of this - scan, catalog, memory, validation, layout
  planning, pack export, component kit - is proved by tests that stop at a
  file. This program is where a pack meets a real application built the way a
  developer builds one: a manager dropped on the form in the designer, its
  three properties set in the Object Inspector, and the packs deployed beside
  the executable.

  --selftest exists so that "and then somebody looked at it" can be an
  assertion rather than an opinion. It applies a language, writes what every
  caption actually became to selftest-result.txt beside the executable, and
  exits without showing a window, so a build can check the far end of the
  pipeline with nobody watching. Without the switch this is an ordinary
  application that shows an ordinary form. }

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Vcl.Forms,
  SampleVCL.MainForm in 'SampleVCL.MainForm.pas' {frmVCLSample};

{$R *.res}

procedure WriteSelfTestResult;
var
  Report: TStringList;

  procedure Line(const AName, AValue: string);
  begin
    Report.Add(AName + '=' + AValue);
  end;

begin
  Report := TStringList.Create;
  try
    Line('managerInitialized',
      BoolToStr(frmVCLSample.DATManager.Initialized, True));
    Line('activeLanguage', frmVCLSample.DATManager.ActiveLanguage);
    Line('formCaption', frmVCLSample.Caption);
    Line('lblHeading', frmVCLSample.lblHeading.Caption);
    Line('lblCustomerName', frmVCLSample.lblCustomerName.Caption);
    Line('btnSave', frmVCLSample.btnSave.Caption);
    Line('mnuFile', frmVCLSample.mnuFile.Caption);
    Line('btnSaveWidth', IntToStr(frmVCLSample.btnSave.Width));
    Report.SaveToFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      'selftest-result.txt'), TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;

{ Read straight from the command line rather than through
  FindCmdLineSwitch, which strips one leading dash and so never matches
  a --double-dash switch: the run then silently becomes an ordinary one
  and puts a window on screen instead of writing a result. The rest of
  this product's tooling uses double dashes, so this does too. }
function Argument(const AName: string; out AValue: string): Boolean;
var
  Index: Integer;
begin
  Result := False;
  AValue := '';
  for Index := 1 to ParamCount do
    if SameText(ParamStr(Index), AName) then
    begin
      if Index < ParamCount then
        AValue := ParamStr(Index + 1);
      Exit(True);
    end;
end;

procedure RunSelfTest;
var
  Wanted: string;
begin
  Argument('--language', Wanted);
  { The manager initialises itself as the form streams, so by here it has
    already loaded whatever the stored preference said. Choosing a language is
    the thing under test. }
  if Wanted <> '' then
    frmVCLSample.DATManager.SelectLanguage(Wanted);
  WriteSelfTestResult;
end;

var
  SwitchValue: string;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVCLSample, frmVCLSample);
  if Argument('--selftest', SwitchValue) then
  begin
    RunSelfTest;
    Exit;
  end;
  Application.Run;
end.
