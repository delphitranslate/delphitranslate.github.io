program VCLCaptionInterceptSmokeTests;

{ A caption the application rebuilds for itself, translated on the way to the
  window.

  The case: a title bar rebuilt on a timer as a literal plus a Format call.
  The format string is translated and shipped as a template, but the
  application calls Format and asks for nothing, so nothing consults it.

  Re-writing the caption after the fact loses - the application writes English
  again a second later, and the two alternate. This catches WM_SETTEXT on the
  way past instead, so the English is never painted.

  The assertion that matters is the last one: the caption is read back from the
  window rather than from the VCL property. The property holds what the
  application assigned, which is still English and correctly so - it is the
  application's string. What the user sees is the window text, and that is what
  had to change. Asserting the property would have passed before this feature
  existed and after it broke. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Controls,
  DAT.Runtime.TemplateRewrite.VCL in '..\..\source\runtime\DAT.Runtime.TemplateRewrite.VCL.pas',
  DAT.Runtime.TemplateRewrite in '..\..\source\runtime\DAT.Runtime.TemplateRewrite.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

const
  { A pack carrying one template, the way a real pack carries the format
    strings the scanner found in the application's own code. }
  PackJson =
    '{"schemaVersion":3,"applicationId":"CaptionProbe",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{},"strings":{},' +
    '"sourceTemplates":{"Uptime: %d years %d months":' +
    '"Betriebszeit: %d Jahre %d Monate"},' +
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

{ What the window is actually showing, which is not always what the VCL
  property says. }
function WindowTextOf(const AForm: TCustomForm): string;
var
  Buffer: array[0..511] of Char;
  Count: Integer;
begin
  Count := GetWindowText(AForm.Handle, Buffer, Length(Buffer));
  SetString(Result, Buffer, Count);
end;

var
  Form: TForm;
  Pack: TRuntimeLanguagePack;
  Shown: string;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmCaption';
      Form.HandleNeeded;

      Pack := TRuntimeLanguagePack.LoadFromJson(PackJson);
      try
        TDATVCLTemplateIntercept.Install(Form, Pack);

        { Exactly what the application does on its timer: its own literal, its
          own Format call, assigned straight to the caption. }
        Form.Caption := 'Carillon Bells Schedule   ' +
          Format('Uptime: %d years %d months', [0, 3]);

        Shown := WindowTextOf(Form);
        Writeln('        window text: ', Shown);
        Check(Pos('Betriebszeit', Shown) > 0,
          'The template was recognised and translated on its way to the window.');
        Check(Pos('0 Jahre 3 Monate', Shown) > 0,
          'and the application''s own numbers came across intact.');
        Check(Pos('Carillon Bells Schedule', Shown) > 0,
          'while the text around it, which is the application''s, is untouched.');
        Check(Pos('Uptime', Shown) = 0,
          'No English is left in the caption for the user to see.');

        { Nothing that does not match a template may be altered. }
        Form.Caption := 'Something else entirely';
        Check(WindowTextOf(Form) = 'Something else entirely',
          'A caption matching no template passes through unchanged.');

        TDATVCLTemplateIntercept.Remove(Form);
        Form.Caption := 'Carillon Bells Schedule   ' +
          Format('Uptime: %d years %d months', [0, 3]);
        Check(Pos('Uptime', WindowTextOf(Form)) > 0,
          'Once removed, the application''s text reaches the window untouched.');
      finally
        Pack.Free;
      end;
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL caption intercept smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('VCL caption intercept smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('VCL caption intercept smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
