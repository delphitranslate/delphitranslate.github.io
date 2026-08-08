program VCLDesignStreamingTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  VCLDesignHost in 'design\VCLDesignHost.pas' {frmVCLDesignHost},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.VCL in '..\..\source\components\DAT.Components.VCL.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

var
  Form: TfrmVCLDesignHost;
begin
  try
    Application.Initialize;
    Form := TfrmVCLDesignHost.Create(nil);
    try
      Require(Form.DATLanguageManager <> nil,
        'The VCL manager did not stream from the DFM resource.');
      Require(Form.DATLanguageManager.ApplicationId = 'VCLDesignHost',
        'The VCL manager Object Inspector properties did not stream.');
      Require(Form.DATLanguageManager.SourceLanguage = 'en-US',
        'The VCL source language did not stream.');
    finally
      Form.Free;
    end;
    Writeln('VCL_DESIGN_STREAMING=PASS');
  except
    on E: Exception do
    begin
      Writeln('VCL_DESIGN_STREAMING=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
