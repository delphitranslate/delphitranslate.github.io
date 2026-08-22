program FMXCaptionRewriteSmokeTests;

{ The FireMonkey twin of VCLCaptionInterceptSmokeTests.

  Same outcome, different mechanism, and the difference is the point. VCL
  catches WM_SETTEXT on the way to the window, so the source language is never
  painted. FMX has no such message: the caption goes to a platform service.
  So FMX corrects the caption on the manager's dynamic tick instead, which
  reaches the same text and can briefly show the application's own version
  first. That is a real difference in quality, recorded here rather than
  glossed over. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  DAT.Runtime.TemplateRewrite.FMX in '..\..\source\runtime\DAT.Runtime.TemplateRewrite.FMX.pas',
  DAT.Runtime.TemplateRewrite in '..\..\source\runtime\DAT.Runtime.TemplateRewrite.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

const
  PackJson =
    '{"schemaVersion":3,"applicationId":"CaptionProbe",' +
    '"applicationVersion":"1.0","framework":"FMX",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{},"strings":{},' +
    '"sourceTemplates":{"App.Runtime.Uptime.1":' +
    '"Uptime: %d years %d months"},' +
    '"templates":{"App.Runtime.Uptime.1":' +
    '"Betriebszeit: %d Jahre %d Monate"},' +
    '"sources":{},"layout":[]}';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

var
  Form: TForm;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmCaption';
      Pack := TRuntimeLanguagePack.LoadFromJson(PackJson);
      try
        Form.Caption := 'Carillon Bells Schedule   ' +
          Format('Uptime: %d years %d months', [0, 3]);

        Check(TDATFMXTemplateRewrite.RefreshCaption(Form, Pack),
          'The tick reports that it rewrote the caption.');
        Writeln('        caption: ', Form.Caption);
        Check(Pos('Betriebszeit', Form.Caption) > 0,
          'The template was recognised and translated.');
        Check(Pos('0 Jahre 3 Monate', Form.Caption) > 0,
          'and the application''s own numbers came across intact.');
        Check(Pos('Carillon Bells Schedule', Form.Caption) > 0,
          'while the text around it, which is the application''s, is untouched.');
        Check(Pos('Uptime', Form.Caption) = 0,
          'No English is left in the caption.');

        { A tick that changes nothing must say so, or the timer becomes a
          repaint loop. }
        Check(not TDATFMXTemplateRewrite.RefreshCaption(Form, Pack),
          'A second tick finds nothing to do and reports no change.');

        Form.Caption := 'Something else entirely';
        Check(not TDATFMXTemplateRewrite.RefreshCaption(Form, Pack),
          'A caption matching no template is left alone.');
        Check(Form.Caption = 'Something else entirely',
          'and really is unchanged.');
      finally
        Pack.Free;
      end;
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX caption rewrite smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('FMX caption rewrite smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('FMX caption rewrite smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
