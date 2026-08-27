program FMXRightToLeftSmokeTests;

{ The right-to-left mirror under FireMonkey.

  The VCL has BiDiMode for reading order and FireMonkey has neither a reading
  direction nor a geometry mirror. Both runtimes therefore implement the same
  MirrorChildren pack contract against each live parent width. This is
  deliberately resolved at application time rather than frozen into numeric
  design-time coordinates: maximised forms, DPI scaling, tab-page placeholder
  widths and responsive application layout all remain valid.

  What is left for the framework here is small and specific - which edge the
  text sits against - and it has to go through TextSettings with StyledSettings
  giving up its claim, or the style puts it back at paint time and the
  assignment looks like it worked. }

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Edit,
  FMX.Grid,
  FMX.TabControl,
  FMX.Types,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas';

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

{ The same form in English: no direction, no layout rules. Returning to the
  source language has to put every mirrored decision back, or a user who tries
  Hebrew once is left with an English program laid out backwards. }
function EnglishPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"en-US","nativeName":"English","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",","currencySymbol":"$"},' +
    '"strings":{"frmRtl.lblName.Text":"Name"},' +
    '"sources":{},"layout":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

function HebrewPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"he-IL","nativeName":"Hebrew","direction":"rtl"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"NIS"},' +
    '"strings":{"frmRtl.lblName.Text":"\u05E9\u05DD"},' +
    '"sources":{},' +
    '"layout":[' +
    '{"formName":"frmRtl","componentName":"frmRtl",' +
    '"propertyName":"MirrorChildren","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblHeading",' +
    '"propertyName":"Width","originalValue":"120",' +
    '"translatedValue":"200","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblHeading",' +
    '"propertyName":"TextSettings.HorzAlign","originalValue":"Center",' +
    '"translatedValue":"Trailing","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"TextSettings.HorzAlign","originalValue":"Leading",' +
    '"translatedValue":"Trailing","sourceChecksum":"t"},' +
    { placed by the framework, so only its edge changes }
    '{"formName":"frmRtl","componentName":"lytNav",' +
    '"propertyName":"Align","originalValue":"Left",' +
    '"translatedValue":"Right","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Form: TForm;
  EmailBox: TEdit;
  Name_: TLabel;
  Heading: TLabel;
  Box: TEdit;
  Grid: TGrid;
  GridColumn: TStringColumn;
  Nav: TLayout;
  CenteredLayout: TLayout;
  Tabs: TTabControl;
  Page: TTabItem;
  InactivePage: TTabItem;
  InactiveScroll: TVertScrollBox;
  StartupTabs: TTabControl;
  StartupPage: TTabItem;
  StartupScroll: TVertScrollBox;
  PageCard: TLayout;
  EdgeCard: TLayout;
  InactiveEdgeCard: TLayout;
  StartupEdgeCard: TLayout;
  RewindButton: TButton;
  PlayButton: TButton;
  StopButton: TButton;
  CloseButton: TButton;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmRtl';
      Form.ClientWidth := 400;
      Form.ClientHeight := 300;

      Nav := TLayout.Create(Form);
      Nav.Parent := Form;
      Nav.Name := 'lytNav';
      Nav.SetBounds(0, 0, 100, 300);
      Nav.Align := TAlignLayout.Left;

      Name_ := TLabel.Create(Form);
      Name_.Parent := Form;
      Name_.Name := 'lblName';
      Name_.SetBounds(16, 20, 80, 20);
      Name_.Text := 'Name';
      Name_.TextSettings.HorzAlign := TTextAlign.Leading;

      Heading := TLabel.Create(Form);
      Heading.Parent := Form;
      Heading.Name := 'lblHeading';
      Heading.SetBounds(40, 92, 120, 30);
      Heading.TextSettings.HorzAlign := TTextAlign.Center;
      Heading.TextSettings.Font.Size := 20;
      Heading.Text := 'Large heading';

      Box := TEdit.Create(Form);
      Box.Parent := Form;
      Box.Name := 'edtName';
      Box.SetBounds(104, 16, 200, 28);

      EmailBox := TEdit.Create(Form);
      EmailBox.Parent := Form;
      EmailBox.Name := 'edtEmailAddress';
      EmailBox.SetBounds(104, 52, 200, 28);
      EmailBox.Text := 'user@example.com';

      CenteredLayout := TLayout.Create(Form);
      CenteredLayout.Parent := Form;
      CenteredLayout.Name := 'lytCentered';
      CenteredLayout.SetBounds(150, 84, 100, 28);

      { A live tab page is substantially wider than the placeholder written
        to an FMX file. This is the exact geometry that previously sent cards
        to negative coordinates. }
      Tabs := TTabControl.Create(Form);
      Tabs.Parent := Form;
      Tabs.Name := 'tabsMain';
      Tabs.SetBounds(0, 220, 400, 70);
      Page := TTabItem.Create(Form);
      Page.Parent := Tabs;
      Page.Name := 'tabDashboard';
      Page.Text := 'Dashboard';
      Page.Width := 8;
      PageCard := TLayout.Create(Form);
      PageCard.Parent := Page;
      PageCard.Name := 'lytDashboardCard';
      PageCard.SetBounds(12, 4, 100, 40);
      EdgeCard := TLayout.Create(Form);
      EdgeCard.Parent := Page;
      EdgeCard.Name := 'lytEdgeCard';
      { The one-pixel overrun is representative of an FMX tab client whose
        streamed width and live width round differently. }
      EdgeCard.SetBounds(12, 4, 389, 40);
      InactivePage := TTabItem.Create(Form);
      InactivePage.Parent := Tabs;
      InactivePage.Name := 'tabProjectScan';
      InactivePage.Text := 'Project Scan';
      InactivePage.Width := 8;
      InactiveScroll := TVertScrollBox.Create(Form);
      InactiveScroll.Parent := InactivePage;
      { This is the transient state seen while an inactive page has not yet
        received its live client bounds. The V5 application creates these
        wrappers at run time; FMX can still report a narrow placeholder here
        when the translation pass begins. }
      InactiveScroll.Align := TAlignLayout.None;
      InactiveScroll.SetBounds(0, 0, 50, 70);
      InactiveEdgeCard := TLayout.Create(Form);
      InactiveEdgeCard.Name := 'lytInactiveEdgeCard';
      InactiveEdgeCard.SetBounds(12, 4, 389, 40);
      InactiveScroll.AddObject(InactiveEdgeCard);
      Tabs.ActiveTab := Page;

      { Before a form is shown, FMX can report the tab control and its
        inactive scroll content using only their placeholder dimensions.
        The first language pass must not bake those transient values into a
        full-width application card. }
      StartupTabs := TTabControl.Create(Form);
      StartupTabs.Parent := Form;
      StartupTabs.Name := 'tabsStarting';
      StartupTabs.SetBounds(0, 220, 400, 70);
      StartupPage := TTabItem.Create(Form);
      StartupPage.Parent := StartupTabs;
      StartupPage.Name := 'tabStarting';
      StartupPage.Width := 8;
      StartupScroll := TVertScrollBox.Create(Form);
      StartupScroll.Parent := StartupPage;
      StartupScroll.Align := TAlignLayout.None;
      StartupScroll.SetBounds(0, 0, 400, 70);
      StartupEdgeCard := TLayout.Create(Form);
      StartupEdgeCard.Name := 'lytStartupEdgeCard';
      StartupEdgeCard.SetBounds(12, 4, 389, 40);
      StartupScroll.AddObject(StartupEdgeCard);

      RewindButton := TButton.Create(Form);
      RewindButton.Parent := Form;
      RewindButton.Name := 'btnRewind';
      RewindButton.SetBounds(20, 165, 60, 24);
      PlayButton := TButton.Create(Form);
      PlayButton.Parent := Form;
      PlayButton.Name := 'btnPlay';
      PlayButton.SetBounds(90, 165, 60, 24);
      StopButton := TButton.Create(Form);
      StopButton.Parent := Form;
      StopButton.Name := 'btnStop';
      StopButton.SetBounds(160, 165, 60, 24);
      CloseButton := TButton.Create(Form);
      CloseButton.Parent := Form;
      CloseButton.Name := 'btnClose';
      CloseButton.SetBounds(300, 195, 75, 24);

      Grid := TGrid.Create(Form);
      Grid.Parent := Form;
      Grid.Name := 'grdData';
      Grid.SetBounds(16, 130, 300, 80);
      GridColumn := TStringColumn.Create(Grid);
      GridColumn.Parent := Grid;

      { Snapshot the streamed designer geometry before simulating the narrow
        dimensions FMX reports for an inactive page during startup. }
      Pack := EnglishPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;
      StartupTabs.Width := 8;
      StartupScroll.Width := 50;

      Pack := HebrewPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln;
      Writeln(Format('        label  X=%.0f  HorzAlign=%d',
        [Name_.Position.X, Ord(Name_.TextSettings.HorzAlign)]));
      Writeln(Format('        edit   X=%.0f', [Box.Position.X]));
      Writeln(Format('        grid   columns=%d  HorzAlign=%d',
        [Grid.ColumnCount, Ord(GridColumn.HorzAlign)]));
      Writeln(Format('        layout Align=%d (Left=%d, Right=%d)',
        [Ord(Nav.Align), Ord(TAlignLayout.Left), Ord(TAlignLayout.Right)]));
      Writeln;

      Check(Abs(Name_.Position.X - 304) < 1, Format(
        'The caption is mirrored to the right of its box: %.0f, expected 304.',
        [Name_.Position.X]));
      Check(Abs(Box.Position.X - 96) < 1,
        Format('And the box moves with it: %.0f, expected 96.',
          [Box.Position.X]));
      Check(Nav.Align = TAlignLayout.Right,
        'A framework-placed layout is mirrored by its edge.');
      Check(Abs(CenteredLayout.Position.X - 150) < 1,
        'A container centred by the application remains centred after RTL layout.');
      Check(Abs(PageCard.Position.X - 288) < 1,
        Format('A tab-page card uses the live 400-pixel parent width: %.0f, expected 288.',
          [PageCard.Position.X]));
      Check(Abs(EdgeCard.Position.X - 12) < 1,
        Format('An edge card preserves the parent''s 12-pixel content gutter: %.0f, expected 12.',
          [EdgeCard.Position.X]));
      Check(Abs(EdgeCard.Width - 376) < 1,
        'A near-full-width card preserves the opposite 12-pixel gutter too.');
      Check((Abs(InactiveEdgeCard.Position.X - 12) < 1) and
        (Abs(InactiveEdgeCard.Width - 376) < 1),
        'A card on an inactive tab uses the tab control client width and does not collapse.');
      Check((Abs(StartupEdgeCard.Position.X - 12) < 1) and
        (StartupEdgeCard.Width > 300),
        'A startup placeholder width is ignored rather than collapsing its card.');
      Writeln(Format('        transport X=%.0f, %.0f, %.0f; close=%.0f; form=%d/%d',
        [RewindButton.Position.X, PlayButton.Position.X,
         StopButton.Position.X, CloseButton.Position.X, Form.Width,
         Form.ClientWidth]));
      Check((Abs(RewindButton.Position.X -
          (Form.ClientWidth - (160 + StopButton.Width))) < 1) and
        (Abs((PlayButton.Position.X - RewindButton.Position.X) - 70) < 1) and
        (Abs((StopButton.Position.X - PlayButton.Position.X) - 70) < 1),
        'Transport buttons move as one block without reversing their machine order.');
      Check(Abs(CloseButton.Position.X - 16) < 1,
        'A trailing form button preserves the designer content gutter.');
      Check((Abs(Heading.Position.X - 100) < 1) and
        (Abs(Heading.Width - 200) < 1),
        'A large centred heading is centred after its translated width changes.');
      Check(Heading.TextSettings.HorzAlign = TTextAlign.Center,
        'A designer-centred heading remains centred under an RTL pack.');
      Check(Name_.TextSettings.HorzAlign = TTextAlign.Trailing,
        'The text sits against the opposite edge.');
      Check(Box.TextSettings.HorzAlign = TTextAlign.Trailing,
        'A FireMonkey edit starts input at the right-hand reading edge.');
      Check(EmailBox.TextSettings.HorzAlign = TTextAlign.Leading,
        'An email address keeps its technical left-to-right ordering inside the RTL form.');
      Check(GridColumn.HorzAlign = TTextAlign.Trailing,
        'A future FireMonkey grid editor copies right-to-left alignment from its column.');
      Check(not (TStyledSetting.Other in Name_.StyledSettings),
        'and the style has given up its claim on it, so it survives a repaint.');

      { This is the post-show state used by the manager's deferred pass. }
      StartupTabs.Width := 400;
      StartupScroll.Width := 400;
      Pack := HebrewPack;
      try
        TFMXTranslationApplicator.RefreshDirectionLayout(Form, Pack,
          'frmRtl');
        TFMXTranslationApplicator.RefreshDirectionLayout(Form, Pack,
          'frmRtl');
      finally
        Pack.Free;
      end;
      Check((Abs(StartupEdgeCard.Position.X - 12) < 1) and
        (Abs(StartupEdgeCard.Width - 376) < 1),
        'The idempotent post-show pass fits the card to the live tab width.');

      { The numbers match the VCL test exactly. That is the point: the mirror
        is one implementation, not two that happen to agree today. }
      Writeln('  (the same numbers as the VCL test, from the same pass)');
      Writeln;

      Pack := EnglishPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln(Format('        back to English: label X=%.0f  HorzAlign=%d  ' +
        'layout Align=%d',
        [Name_.Position.X, Ord(Name_.TextSettings.HorzAlign),
         Ord(Nav.Align)]));
      Writeln;
      Check(Abs(Name_.Position.X - 16) < 1,
        Format('The caption is back where it was drawn: %.0f, expected 16.',
          [Name_.Position.X]));
      Check(Abs(Box.Position.X - 104) < 1,
        Format('and so is the box: %.0f, expected 104.', [Box.Position.X]));
      Check(Nav.Align = TAlignLayout.Left,
        'The layout returns to its designed edge.');
      Check(Abs(PageCard.Position.X - 12) < 1,
        'The tab-page card returns to its designed inset in an LTR language.');
      Check((Abs(EdgeCard.Position.X - 12) < 1) and
        (Abs(EdgeCard.Width - 389) < 1),
        'The edge card returns to its exact designer geometry in an LTR language.');
      Check((Abs(InactiveEdgeCard.Position.X - 12) < 1) and
        (Abs(InactiveEdgeCard.Width - 389) < 1),
        'The inactive-tab card also returns to its exact designer geometry.');
      Check((Abs(StartupEdgeCard.Position.X - 12) < 1) and
        (Abs(StartupEdgeCard.Width - 389) < 1),
        'The startup-tab card also returns to its exact designer geometry.');
      Check((Abs(RewindButton.Position.X - 20) < 1) and
        (Abs(PlayButton.Position.X - 90) < 1) and
        (Abs(StopButton.Position.X - 160) < 1),
        'The transport block returns to its designed LTR position.');
      Check(Name_.TextSettings.HorzAlign = TTextAlign.Leading,
        'And the text to the edge it was drawn against.');
      Check(GridColumn.HorzAlign = TTextAlign.Leading,
        'The FireMonkey grid column returns to source-language input alignment.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX right-to-left smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('FMX right-to-left smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
