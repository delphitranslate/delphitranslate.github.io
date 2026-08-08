program FMXDesignStreamingTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  FMX.Forms,
  FMXDesignHost in 'design\FMXDesignHost.pas' {frmFMXDesignHost},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.FMX in '..\..\source\components\DAT.Components.FMX.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

var
  Form: TfrmFMXDesignHost;
begin
  try
    Application.Initialize;
    Form := TfrmFMXDesignHost.Create(nil);
    try
      Require(Form.DATLanguageManager <> nil,
        'The FMX manager did not stream from the FMX resource.');
      Require(Form.DATLanguageManager.ApplicationId = 'FMXDesignHost',
        'The FMX manager Object Inspector properties did not stream.');
      Require(Form.DATLanguageManager.SourceLanguage = 'en-US',
        'The FMX source language did not stream.');
    finally
      Form.Free;
    end;
    Writeln('FMX_DESIGN_STREAMING=PASS');
  except
    on E: Exception do
    begin
      Writeln('FMX_DESIGN_STREAMING=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
