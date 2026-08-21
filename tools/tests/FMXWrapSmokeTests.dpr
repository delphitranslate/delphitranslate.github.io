program FMXWrapSmokeTests;

{ The FireMonkey counterpart of VCLWrapSmokeTests, and the place where the two
  frameworks are allowed to disagree.

  Most of this file asks the same questions its VCL twin asks. A label told to
  stop sizing itself, to wrap, and to be 577 wide must actually end up wrapped
  at 577, and must still be there after the language is applied a second time,
  because applying starts by putting the form back as it was drawn and every
  decision has to be made again from there.

  One question has the opposite answer, and that is the point of having the
  twin at all. The pack carries a soft hyphen at every point the language
  allows a break, written long before anything knows how wide a label will be.
  GDI draws U+00AD as an ordinary hyphen and refuses to break a line at one,
  so the VCL runtime resolves every mark away before it can reach a caption -
  a real hyphen and a real line break where the word fits, the plain word
  where it cannot wrap. DirectWrite honours the mark. So the FireMonkey
  runtime deliberately does nothing: the marks reach the caption intact and
  the renderer chooses the break, which is both simpler and better, because
  the renderer knows the final width and the pack never can.

  A test that asserted "no soft hyphen reaches a caption" on both frameworks
  would be asserting that the FireMonkey runtime has a bug. This one asserts
  what each framework is actually for.

  Column headings are not repeated here. A VCL grid keeps its heading on a
  collection item, so the pack reaches into it as Columns[0].Title.Caption; a
  FireMonkey column is an ordinary named component with a Header, and that
  path is already covered by FMXRuntimeSmokeTests. }

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Types,
  FMX.TextLayout,
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

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

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"WrapSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"es-ES","nativeName":"Espanol","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{' +
    '"frmWrap.lblPara.Text":' +
    '"Haz clic en el boton Seleccionar directorio aleatorio para cualquier ' +
    'cuadro de directorio, selecciona un directorio y anade las fechas para ' +
    'incluirlo en la rotacion.",' +
    { The same German compound the VCL twin carries, marked at every break the
      language allows, written as the JSON escape for a soft hyphen. Here the
      marks are meant to survive. }
    '"frmWrap.lblLong.Text":' +
    '"Be\u00ADnach\u00ADrich\u00ADti\u00ADgung\u00ADsein\u00ADstel' +
    '\u00ADlun\u00ADgen",' +
    '"frmWrap.btnLong.Text":' +
    '"Be\u00ADnach\u00ADrich\u00ADti\u00ADgung\u00ADsein\u00ADstel' +
    '\u00ADlun\u00ADgen"},' +
    '"sources":{},' +
    '"layout":[' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"AutoSize","originalValue":"True",' +
    '"translatedValue":"False","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"Width","originalValue":"577",' +
    '"translatedValue":"577","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"Height","originalValue":"60",' +
    '"translatedValue":"60","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblLong",' +
    '"propertyName":"AutoSize","originalValue":"True",' +
    '"translatedValue":"False","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblLong",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblLong",' +
    '"propertyName":"Width","originalValue":"120",' +
    '"translatedValue":"120","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

const
  SoftHyphen = #$00AD;

function Shown(const AText: string): string;
begin
  Result := StringReplace(AText, SoftHyphen, '|', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, ' / ', [rfReplaceAll]);
end;

{ The width DirectWrite actually uses for AText when it is given AWidth to
  wrap in. Width rather than height, because height only counts the lines and
  both of these words come out on the same number of them: an unbreakable word
  is broken mid-letter instead, which costs the same lines and says nothing.
  Where the break falls shows in the width the wrap leaves behind. Pass a very
  large width to measure one unwrapped line. }
function UsedWidth(const AText: string; const AWidth: Single): Single;
var
  Layout: TTextLayout;
begin
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    try
      Layout.Font.Size := 12;
      Layout.WordWrap := AWidth < 5000;
      Layout.Trimming := TTextTrimming.None;
      Layout.MaxSize := TPointF.Create(AWidth, 10000);
      Layout.Text := AText;
    finally
      Layout.EndUpdate;
    end;
    Result := Layout.TextRect.Width;
  finally
    Layout.Free;
  end;
end;

var
  Form: TForm;
  Para: TLabel;
  Long: TLabel;
  Button: TButton;
  Pack: TRuntimeLanguagePack;
  MarkedOneLine, PlainOneLine: Single;
  MarkedWrapped, PlainWrapped: Single;
  Plain: string;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmWrap';
      Form.ClientWidth := 974;
      Form.ClientHeight := 400;

      Para := TLabel.Create(Form);
      Para.Parent := Form;
      Para.Name := 'lblPara';
      Para.Position.X := 176;
      Para.Position.Y := 85;
      Para.Size.Width := 577;
      Para.Size.Height := 60;
      Para.AutoSize := True;
      Para.Text := 'Click the button for any directory box, select a ' +
        'directory and add dates to put it into the rotation.';

      Long := TLabel.Create(Form);
      Long.Parent := Form;
      Long.Name := 'lblLong';
      Long.Position.X := 24;
      Long.Position.Y := 340;
      Long.Size.Width := 120;
      Long.Size.Height := 40;
      Long.Text := 'Notification Settings';

      Button := TButton.Create(Form);
      Button.Parent := Form;
      Button.Name := 'btnLong';
      Button.Position.X := 600;
      Button.Position.Y := 340;
      Button.Size.Width := 300;
      Button.Size.Height := 30;
      Button.Text := 'Notification Settings';

      Pack := TestPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmWrap', True);
      finally
        Pack.Free;
      end;

      Writeln(Format('        label: width %.0f, height %.0f, wordwrap %s, ' +
        'autosize %s', [Para.Size.Width, Para.Size.Height,
        BoolToStr(Para.TextSettings.WordWrap, True),
        BoolToStr(Para.AutoSize, True)]));
      Check(not Para.AutoSize, 'It stops sizing itself.');
      Check(Para.TextSettings.WordWrap, 'It wraps.');
      Check(Abs(Para.Size.Width - 577) < 1,
        Format('It is the width the rule gives it, not %.0f.',
          [Para.Size.Width]));
      Check(Para.Size.Height >= 54,
        Format('It keeps room for its wrapped lines: height %.0f.',
          [Para.Size.Height]));

      { The second application, the way an application does it when the
        language is chosen again or the form is shown again. }
      Pack := TestPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmWrap', True);
      finally
        Pack.Free;
      end;
      Writeln(Format('        after a second apply: width %.0f, wordwrap %s',
        [Para.Size.Width, BoolToStr(Para.TextSettings.WordWrap, True)]));
      Check(Para.TextSettings.WordWrap,
        'It still wraps after a second application.');
      Check(Abs(Para.Size.Width - 577) < 1,
        Format('and is still 577 wide, not %.0f.', [Para.Size.Width]));

      Writeln(Format('        long label : "%s"', [Shown(Long.Text)]));
      Writeln(Format('        long button: "%s"', [Shown(Button.Text)]));

      { The framework difference, stated as an assertion rather than as a
        comment. Nothing resolves the marks on this side, so they arrive as
        the pack wrote them. }
      Check(Pos(SoftHyphen, Long.Text) > 0,
        'The soft hyphens reach a FireMonkey caption: DirectWrite honours ' +
        'them, so the runtime leaves the choice of break to the renderer.');
      Check(Pos(#13#10, Long.Text) = 0,
        'and nothing has been broken in advance at a width the renderer had ' +
        'not been told about yet.');
      Check(Pos(SoftHyphen, Button.Text) > 0,
        'The same word on a button keeps its marks too.');

      { And that leaving the marks in is right, which is two separate claims
        and needs two separate measurements.

        First, that a mark costs nothing when it is not used. On one wide line
        the marked word must measure exactly what the plain word measures: if
        DirectWrite drew U+00AD the way GDI does, every unbroken caption would
        silently gain a hyphen for each mark in it and this is where that would
        show.

        Second, that a mark is used when it is needed. In a narrow box both
        words come out on the same number of lines - an unbreakable word is
        simply broken mid-letter - so the line count proves nothing and the
        width the wrap leaves behind is what separates them. A different width
        means a different break point, which means the mark was taken. }
      Plain := StringReplace(Long.Text, SoftHyphen, '', [rfReplaceAll]);
      MarkedOneLine := UsedWidth(Long.Text, 100000);
      PlainOneLine := UsedWidth(Plain, 100000);
      Writeln(Format('        one line   : marked %.2f, plain %.2f',
        [MarkedOneLine, PlainOneLine]));
      Check(Abs(MarkedOneLine - PlainOneLine) < 0.5,
        'An unused mark is invisible to DirectWrite: the marked word is no ' +
        'wider than the plain one, where GDI would have drawn a hyphen for ' +
        'every mark.');

      MarkedWrapped := UsedWidth(Long.Text, 120);
      PlainWrapped := UsedWidth(Plain, 120);
      Writeln(Format('        in a box of 120: marked %.2f, plain %.2f',
        [MarkedWrapped, PlainWrapped]));
      Check(Abs(MarkedWrapped - PlainWrapped) > 0.5,
        'and a needed mark is taken: the marked word breaks at a syllable ' +
        'where the plain one can only break mid-letter, which is why the ' +
        'runtime leaves the choice to the renderer.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX wrap smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('FMX wrap smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
