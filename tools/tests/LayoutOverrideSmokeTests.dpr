program LayoutOverrideSmokeTests;

{ Adjustments made while the application is running, and remembered.

  The planner measures text and reasons about boxes. It cannot see that a
  caption sits awkwardly against a picture, or that one language reads better
  with a control nudged. The only place that is visible is the running
  application, and until now there was no way to correct it from there.

  Three things have to be true, and each is checked here.

  They must survive a round trip to disk, because "remembered" is the whole
  feature. They must be per language, because German needing a wider button is
  no reason to widen it in Japanese. And they must be applied last, after every
  rule the pack carries: an override is the correction of somebody who looked
  at the result, so where the planner and a person disagree, the person wins.

  A move and a resize are recorded separately on purpose. Nudging a control
  should not also freeze a width the planner ought to keep computing. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  DAT.Runtime.LayoutOverrides in '..\..\source\runtime\DAT.Runtime.LayoutOverrides.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas';

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

{ A pack that moves and widens the button, so that an override has something to
  disagree with. }
function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"OverrideSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".",' +
    '"currencySymbol":"EUR"},' +
    '"strings":{"frmHost.btnSave.Caption":"Speichern"},' +
    '"sources":{"frmHost.btnSave.Caption":"Save"},' +
    '"layout":[' +
    '{"formName":"frmHost","componentName":"btnSave",' +
    '"propertyName":"Left","originalValue":"20",' +
    '"translatedValue":"40","sourceChecksum":"t"},' +
    '{"formName":"frmHost","componentName":"btnSave",' +
    '"propertyName":"Width","originalValue":"80",' +
    '"translatedValue":"140","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Folder: string;
  Overrides: TLayoutOverrides;
  Reloaded: TLayoutOverrides;
  Other: TLayoutOverrides;
  Form: TForm;
  Button: TButton;
  Pack: TRuntimeLanguagePack;
  Applied: Integer;
begin
  try
    Folder := TPath.Combine(TPath.GetTempPath, 'dat-override-tests');
    if TDirectory.Exists(Folder) then
      TDirectory.Delete(Folder, True);
    TDirectory.CreateDirectory(Folder);

    Writeln;
    Writeln('=== remembered across a restart ===');
    Overrides := TLayoutOverrides.Load(Folder, 'OverrideSample', 'de-DE');
    try
      Check(Overrides.Items.Count = 0,
        'An application nobody has adjusted starts with none.');
      Overrides.RecordPosition('frmHost', 'btnSave', 200, 150);
      Overrides.RecordSize('frmHost', 'btnSave', 90, 30);
      Overrides.RecordPosition('frmHost', 'lblNote', 12, 300);
      Overrides.Save;
      Check(TFile.Exists(Overrides.FileName),
        'They are written beside the language packs: ' +
        TPath.GetFileName(Overrides.FileName));
    finally
      Overrides.Free;
    end;

    Reloaded := TLayoutOverrides.Load(Folder, 'OverrideSample', 'de-DE');
    try
      Check(Reloaded.Items.Count = 2, 'Both controls came back.');
      Check((Reloaded.Find('frmHost', 'btnSave') <> nil) and
        Reloaded.Find('frmHost', 'btnSave').HasPosition and
        (Reloaded.Find('frmHost', 'btnSave').Left = 200),
        'A move survives the round trip.');
      Check(Reloaded.Find('frmHost', 'btnSave').HasSize and
        (Reloaded.Find('frmHost', 'btnSave').Width = 90),
        'and so does a resize.');
      Check(Reloaded.Find('frmHost', 'lblNote').HasPosition and
        not Reloaded.Find('frmHost', 'lblNote').HasSize,
        'A control that was only moved is not also frozen at a size - the ' +
        'planner keeps computing that one.');
    finally
      Reloaded.Free;
    end;

    Writeln;
    Writeln('=== one language does not adjust another ===');
    Other := TLayoutOverrides.Load(Folder, 'OverrideSample', 'ja-JP');
    try
      Check(Other.Items.Count = 0,
        'Japanese has none of German''s adjustments.');
    finally
      Other.Free;
    end;

    Writeln;
    Writeln('=== an override beats the pack ===');
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmHost';
      Form.ClientWidth := 400;
      Form.ClientHeight := 300;
      Button := TButton.Create(Form);
      Button.Parent := Form;
      Button.Name := 'btnSave';
      Button.SetBounds(20, 40, 80, 25);
      Button.Caption := 'Save';

      Pack := TestPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmHost', True);
      finally
        Pack.Free;
      end;
      Writeln(Format('        after the pack : left %d, width %d',
        [Button.Left, Button.Width]));
      Check((Button.Left = 40) and (Button.Width = 140),
        'The pack moved and widened it, as it was asked to.');
      Check(Button.Caption = 'Speichern', 'and translated it.');

      Reloaded := TLayoutOverrides.Load(Folder, 'OverrideSample', 'de-DE');
      try
        Applied := TVCLTranslationApplicator.ApplyOverrides(Form, Reloaded,
          'frmHost');
        Writeln(Format('        after the person: left %d, width %d (%d ' +
          'adjustment(s))', [Button.Left, Button.Width, Applied]));
        Check(Applied = 2, 'Both the move and the resize were applied.');
        Check((Button.Left = 200) and (Button.Top = 150),
          'The person''s position wins over the planner''s.');
        Check(Button.Width = 90,
          'and so does the person''s width, even though the planner had ' +
          'widened it to 140 for a reason.');
        Check(Button.Caption = 'Speichern',
          'An adjustment moves a control and never touches its words.');
      finally
        Reloaded.Free;
      end;

      Writeln;
      Writeln('=== and the way back ===');
      Reloaded := TLayoutOverrides.Load(Folder, 'OverrideSample', 'de-DE');
      try
        Check(Reloaded.Forget('frmHost', 'btnSave'),
          'One adjustment can be forgotten.');
        Check(not Reloaded.Forget('frmHost', 'btnSave'),
          'and forgetting it twice is not an error, just nothing to do.');
        Check(Reloaded.ForgetForm('frmHost') = 1,
          'and a whole form can be cleared.');
        Reloaded.Save;
      finally
        Reloaded.Free;
      end;

      Reloaded := TLayoutOverrides.Load(Folder, 'OverrideSample', 'de-DE');
      try
        Check(Reloaded.Items.Count = 0,
          'The clearing was remembered too.');
        Check(TVCLTranslationApplicator.ApplyOverrides(Form, Reloaded,
          'frmHost') = 0, 'and nothing is applied afterwards.');
        Check(TVCLTranslationApplicator.ApplyOverrides(Form, nil,
          'frmHost') = 0, 'An application with no overrides at all is fine.');
      finally
        Reloaded.Free;
      end;
    finally
      Form.Free;
    end;

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Layout override smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Layout override smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
