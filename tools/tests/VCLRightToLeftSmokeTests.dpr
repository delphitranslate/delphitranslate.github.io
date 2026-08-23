program VCLRightToLeftSmokeTests;

{ What a right-to-left pack does to a real VCL form.

  The layout contracts prove the planner decides the right numbers. They stop
  there, at a model of a form. This runs the decisions through the applicator
  and onto actual controls, because every gap this project has found so far -
  the grid headings, the duplicate form name, the colour that would not stay -
  lived in exactly that gap.

  Four things have to be true at once, and each was got wrong at least once
  while it was being written:

    - the controls are mirrored, and each within its own parent
    - a control the framework places is mirrored by its Align constant, and
      is NOT also moved, because the two instructions would contradict
    - reading order is right-to-left, but alignment is NOT flipped twice
    - an English pack changes none of it }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.DBGrids,
  Vcl.Menus,
  Winapi.Messages,
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
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

{ A Hebrew pack for the form below. The mirrored positions are the ones the
  planner computes: the container width less the control's right edge. }
function HebrewPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"he-IL","nativeName":"Hebrew","direction":"rtl"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"NIS"},' +
    { The menu caption is translated here on purpose. Writing a menu item's
      caption rebuilds the menu, and the rebuild does not carry the
      right-to-left flag across, so a pack that renames a menu quietly undoes
      the mirroring applied before it. The Hebrew pack used to leave the menu
      alone while the English pack renamed it - which is exactly why this file
      passed while real applications came back with unmirrored menus. }
    '"strings":{"frmRtl.mnuFile.Caption":"\u05E7\u05D5\u05D1\u05E5",' +
    '"frmRtl.lblName.Caption":"\u05E9\u05DD",' +
    '"frmRtl.btnOk.Caption":"\u05D0\u05D9\u05E9\u05D5\u05E8"},' +
    '"sources":{},' +
    '"layout":[' +
    { 400 - (16 + 80) = 304 }
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"Left","originalValue":"16",' +
    '"translatedValue":"304","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"Alignment","originalValue":"taLeftJustify",' +
    '"translatedValue":"taRightJustify","sourceChecksum":"t"},' +
    { 400 - (104 + 200) = 96 }
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"Left","originalValue":"104",' +
    '"translatedValue":"96","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"Anchors","originalValue":"[akLeft,akTop]",' +
    '"translatedValue":"[akRight,akTop]","sourceChecksum":"t"},' +
    { the button inside the panel mirrors against the panel: 200-(10+75)=115 }
    '{"formName":"frmRtl","componentName":"btnInner",' +
    '"propertyName":"Left","originalValue":"10",' +
    '"translatedValue":"115","sourceChecksum":"t"},' +
    { the navigation strip is placed by the framework, so only its edge changes }
    '{"formName":"frmRtl","componentName":"pnlNav",' +
    '"propertyName":"Align","originalValue":"alLeft",' +
    '"translatedValue":"alRight","sourceChecksum":"t"},' +
    { the grid reads the way its language reads }
    '{"formName":"frmRtl","componentName":"grdData",' +
    '"propertyName":"Columns[0].Width","originalValue":"60",' +
    '"translatedValue":"90","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"grdData",' +
    '"propertyName":"ColumnOrder","originalValue":"designed",' +
    '"translatedValue":"reversed","sourceChecksum":"t"},' +
    { and so does the Tab key: the highest order less each control's own }
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"TabOrder","originalValue":"0",' +
    '"translatedValue":"2","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"btnOk",' +
    '"propertyName":"TabOrder","originalValue":"2",' +
    '"translatedValue":"0","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

{ The same form in English: no direction, no layout rules. }
function EnglishPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"en-US","nativeName":"English","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",","currencySymbol":"$"},' +
    '"strings":{"frmRtl.lblName.Caption":"Name",' +
    '"frmRtl.mnuFile.Caption":"File",' +
    '"frmRtl.btnOk.Caption":"OK"},' +
    '"sources":{},"layout":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

{ The order Windows actually holds, which is the thing on screen.

  The flag below is not this. MFT_RIGHTORDER and MFT_RIGHTJUSTIFY decide how
  submenus cascade and push the bar to the right edge; neither reorders the
  top-level items. Asserting the flag while believing it meant order is how a
  bar that never moved passed as mirrored. }
function MenuBarOrder(const AMenu: TMainMenu): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 0 to AMenu.Items.Count - 1 do
    Result := Result + AMenu.Items[Index].Name + ' ';
  Result := Trim(Result);
end;

function MenuIsRightToLeft(const AMenu: TMainMenu): Boolean;
const
  RightToLeftMenuFlag = MFT_RIGHTORDER or MFT_RIGHTJUSTIFY;
var
  Info: TMenuItemInfo;
  Buffer: array[0..79] of Char;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := MIIM_TYPE;
  Info.cch := Length(Buffer);
  Info.dwTypeData := Buffer;
  Result := GetMenuItemInfo(AMenu.Handle, 0, True, Info) and
    ((Info.fType and RightToLeftMenuFlag) <> 0);
end;

var
  Form: TForm;
  Name_: TLabel;
  Box: TEdit;
  Number: TLabel;
  Ok: TButton;
  Nav: TPanel;
  Inner: TButton;
  Grid: TDBGrid;
  Menu: TMainMenu;
  ExtraItem: TMenuItem;
  MenuIndex: Integer;
  DesignedMenuOrder: string;
  ReversedMenuOrder: string;
  FileItem: TMenuItem;
  ExStyleUnderArabic: NativeInt;

  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmRtl';
      Form.ClientWidth := 400;
      Form.ClientHeight := 300;

      Nav := TPanel.Create(Form);
      Nav.Parent := Form;
      Nav.Name := 'pnlNav';
      Nav.SetBounds(0, 0, 100, 300);
      Nav.Align := alLeft;
      Nav.Caption := '';

      Name_ := TLabel.Create(Form);
      Name_.Parent := Form;
      Name_.Name := 'lblName';
      Name_.AutoSize := False;
      Name_.SetBounds(16, 20, 80, 17);
      Name_.Caption := 'Name';
      { A caption of digits and a full stop. Every character in it is a
        Unicode neutral, so in a right-to-left paragraph the algorithm reads
        the run right to left and draws "1." as ".1" - a numbered list comes
        out looking decorated, the same complaint the menu shortcuts drew. }
      Number := TLabel.Create(Form);
      Number.Parent := Form;
      Number.Name := 'lblNumber';
      Number.SetBounds(16, 200, 30, 17);
      Number.Caption := '1.';
      Name_.Alignment := taLeftJustify;

      Box := TEdit.Create(Form);
      Box.Parent := Form;
      Box.Name := 'edtName';
      Box.SetBounds(104, 16, 200, 25);
      Box.Anchors := [akLeft, akTop];

      Ok := TButton.Create(Form);
      Ok.Parent := Form;
      Ok.Name := 'btnOk';
      Ok.SetBounds(230, 120, 75, 25);
      Ok.Caption := 'OK';

      Grid := TDBGrid.Create(Form);
      Grid.Parent := Form;
      Grid.Name := 'grdData';
      Grid.SetBounds(20, 180, 360, 90);
      { Field names matter as much as headings, and their absence is why this
        test passed while a real grid reversed its headings and left its data
        exactly where it was. A heading that moves without its column is worse
        than one that does not move: every value on screen is then under the
        wrong name. }
      Grid.Columns.Add.Title.Caption := 'First';
      Grid.Columns[0].FieldName := 'FIRSTFIELD';
      Grid.Columns[0].Width := 60;
      Grid.Columns.Add.Title.Caption := 'Second';
      Grid.Columns[1].FieldName := 'SECONDFIELD';
      Grid.Columns.Add.Title.Caption := 'Third';
      Grid.Columns[2].FieldName := 'THIRDFIELD';

      { A menu is not a TControl, which is why it was missed at first. The
        caption matters as much as the menu: translating a menu item rebuilds
        the menu, and Delphi stamps each item with the reading order in force
        at that moment. A menu whose caption never changes is never rebuilt,
        and a test using one cannot see the defect this is here to catch. }
      Menu := TMainMenu.Create(Form);
      Menu.Name := 'MainMenu1';
      FileItem := TMenuItem.Create(Form);
      FileItem.Name := 'mnuFile';
      FileItem.Caption := 'File';
      Menu.Items.Add(FileItem);
      Form.Menu := Menu;
      { A menu built in the designer, not at run time. Setting BiDiMode on a
        TMenu clears ParentBiDiMode, so any application whose menu was ever
        given an explicit reading order stops following its form - and a menu
        that does not follow its form is one VCL will never mirror, because
        the only path that mirrors one hangs off that inheritance. Creating
        the menu fresh and leaving it to inherit, as this file used to, is the
        one case where the bug cannot appear. }
      Menu.BiDiMode := bdLeftToRight;
      { Three more, because a bar with one item looks identical mirrored and
        unmirrored - which is why one item was never going to catch this. }
      for MenuIndex := 0 to 2 do
      begin
        ExtraItem := TMenuItem.Create(Form);
        ExtraItem.Name := 'mnuExtra' + IntToStr(MenuIndex);
        ExtraItem.Caption := 'Extra' + IntToStr(MenuIndex);
        Menu.Items.Add(ExtraItem);
      end;
      DesignedMenuOrder := MenuBarOrder(Menu);

      Inner := TButton.Create(Form);
      Inner.Parent := Nav;
      Inner.Name := 'btnInner';
      Inner.SetBounds(10, 15, 75, 25);
      Inner.Caption := 'Inner';

      { A maximised window is the ordinary case for a main form, and changing
        BiDiMode recreates the window. Whatever the recreation does not carry
        across is lost - which is what leaves a strip of desktop down one side
        after a switch to Arabic, until the user maximises it again by hand. }
      Form.WindowState := wsMaximized;

      Pack := HebrewPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln;
      Writeln(Format('        window state after Arabic: %d (maximized=%d)',
        [Ord(Form.WindowState), Ord(wsMaximized)]));
      Check(Form.WindowState = wsMaximized,
        'A maximised form is still maximised after the language changes.');

      Writeln('  after a Hebrew pack:');
      Writeln(Format('        label  Left=%d  Alignment=%d', [Name_.Left,
        Ord(Name_.Alignment)]));
      Writeln(Format('        edit   Left=%d', [Box.Left]));
      Writeln(Format('        panel  Align=%d (alLeft=%d, alRight=%d)',
        [Ord(Nav.Align), Ord(alLeft), Ord(alRight)]));
      Writeln(Format('        inner  Left=%d', [Inner.Left]));
      Writeln;

      Check(Name_.Left = 304, Format(
        'The caption is mirrored to the right of its box: %d, expected 304.',
        [Name_.Left]));
      Check(Box.Left = 96,
        Format('And the box moves with it: %d, expected 96.', [Box.Left]));
      Check(Inner.Left = 115, Format(
        'A control inside a panel mirrors within the panel: %d, expected 115.',
        [Inner.Left]));
      Check(Nav.Align = alRight,
        'A framework-placed strip is mirrored by its edge, not its position.');
      Check(Box.Anchors = [akRight, akTop],
        'An edge anchor follows the edge the reader works from.');

      { The heart of it. bdRightToLeft would flip alignment a second time and
        draw this caption DT_LEFT, undoing the plan without any error. }
      Check(Name_.Alignment = taRightJustify,
        'The caption is right-aligned, as the pack asked.');
      Check(Form.BiDiMode = bdRightToLeftNoAlign,
        'Reading order is right-to-left in the mode that leaves alignment alone.');
      Check((Name_.DrawTextBiDiModeFlags(DT_RIGHT) and DT_RIGHT) <> 0,
        'And it is actually DRAWN right-aligned, not flipped back by BiDiMode.');
      Check((Name_.DrawTextBiDiModeFlags(DT_RIGHT) and DT_RTLREADING) <> 0,
        'while still reading right to left.');
      Check(Form.UseRightToLeftScrollBar,
        'The scroll bar moves to the side the reader starts from.');
      { Where the caret starts is the reader's property, not the layout's.
        bdRightToLeftNoAlign gives the reading order without moving the
        text, which is right for a caption the layout pass has already
        placed and wrong for anything typed into: the field stays left
        aligned, so the first character entered appears at the far end of
        the box from where the reader is looking. }
      Check(Box.BiDiMode = bdRightToLeft,
        'A field takes the full right-to-left, so typing begins at the right.');
      Check(Number.BiDiMode = bdLeftToRight,
        'A caption of digits is left alone, so "1." is not drawn ".1".');
      Writeln(Format('        menu   BiDiMode=%d (form=%d)',
        [Ord(Menu.BiDiMode), Ord(Form.BiDiMode)]));
      Check(Menu.BiDiMode = bdRightToLeftNoAlign,
        'The menu reads right to left as well as the form.');
      { The property follows the form on its own, which is why this looked
        correct while the screen did not. What Windows actually draws from is
        the window's extended style, and WS_EX_RTLREADING and
        WS_EX_LEFTSCROLLBAR are put there when the handle is created. If the
        window is not recreated when the language changes, they stay - and
        every menu keeps opening the way Arabic left it until the application
        is restarted, which is exactly what was reported. }
      ExStyleUnderArabic := GetWindowLong(Form.Handle, GWL_EXSTYLE);
      Writeln(Format('        SysLocale.MiddleEast = %s   menu RTL flag = %s',
        [BoolToStr(SysLocale.MiddleEast, True),
         BoolToStr(MenuIsRightToLeft(Menu), True)]));
      { The assertion this file was missing, and the reason a broken menu
        shipped green.

        The right-to-left side only ever printed this flag. The left-to-right
        side below asserted "not right to left" - which was trivially true,
        because the flag was never being set in either direction. So the pair
        read like symmetric coverage and was nothing of the kind: one half
        tested the applicator, the other half tested nothing at all.

        What it hid: VCL's only menu-mirroring path begins

          if (not SysLocale.MiddleEast) or (WindowHandle = 0) then Exit;

        and SysLocale.MiddleEast is False on a Western Windows install, so the
        flag was never set on this machine no matter what the form was told.
        The window mirrored anyway, so the bar painted right-to-left over hit
        regions that had not moved - the rightmost item read File and opened
        Help. The value was on the screen above this line the whole time. }
      Check(MenuIsRightToLeft(Menu),
        'The menu bar itself opens right to left, not merely the form.');
      ReversedMenuOrder := MenuBarOrder(Menu);
      Writeln('        menu order: ' + ReversedMenuOrder);
      { The assertion that would have caught what shipped: the items are in
        the opposite order, so the first menu sits where a right-to-left
        reader starts. }
      Check(ReversedMenuOrder <> DesignedMenuOrder,
        'The menu bar is in a different order than designed.');
      Check(Menu.Items[Menu.Items.Count - 1].Name = 'mnuFile',
        'The first menu is last in the list, which puts it on the right.');
      { VCL invents a keyboard shortcut for any menu item without one, and
        for scripts Unicode calls OtherLetter - Hebrew here, Arabic in the
        field - it appends it as visible text rather than underlining a
        letter. The menu then reads the Hebrew for "File" followed by (Z), with Roman letters
        marching through a right-to-left menu. Nothing was wrong with the
        translation; VCL decorated it afterwards. }
      Check(Pos('(', Menu.Items[0].Caption) = 0,
        'No Roman keyboard shortcut is bolted onto a translated menu caption.');
      Writeln(Format('        window ExStyle RTLREADING=%s LEFTSCROLLBAR=%s LAYOUTRTL=%s',
        [BoolToStr((ExStyleUnderArabic and WS_EX_RTLREADING) <> 0, True),
         BoolToStr((ExStyleUnderArabic and WS_EX_LEFTSCROLLBAR) <> 0, True),
         BoolToStr((ExStyleUnderArabic and WS_EX_LAYOUTRTL) <> 0, True)]));

      Writeln(Format('        grid   headings: %s, %s, %s   first width %d',
        [Grid.Columns[0].Title.Caption, Grid.Columns[1].Title.Caption,
         Grid.Columns[2].Title.Caption, Grid.Columns[2].Width]));
      Check(Grid.Columns[0].Title.Caption = 'Third',
        'The grid reads right to left: the first column is now last.');
      Check(Grid.Columns[2].Title.Caption = 'First',
        'and the last is first.');
      Writeln(Format('        grid   fields:   %s, %s, %s',
        [Grid.Columns[0].FieldName, Grid.Columns[1].FieldName,
         Grid.Columns[2].FieldName]));
      Check(Grid.Columns[0].FieldName = 'THIRDFIELD',
        'The data comes with the heading: the first column is now the third field.');
      Check(Grid.Columns[2].FieldName = 'FIRSTFIELD',
        'and the last column is the first field.');

      { The same pack applied a second time, which is what an application does
        every time the form is shown again or the language is re-selected.
        Reversing is its own opposite, so an apply that does not first undo the
        previous one reverses twice: the fields come back to their designed
        order while the headings, written by index in between, do not. The grid
        then shows every value under the wrong name, which is worse than not
        mirroring at all. }
      Pack := HebrewPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;
      Writeln(Format('        after a second apply: %s/%s, %s/%s, %s/%s',
        [Grid.Columns[0].Title.Caption, Grid.Columns[0].FieldName,
         Grid.Columns[1].Title.Caption, Grid.Columns[1].FieldName,
         Grid.Columns[2].Title.Caption, Grid.Columns[2].FieldName]));
      Check((Grid.Columns[0].Title.Caption = 'Third') and
        (Grid.Columns[0].FieldName = 'THIRDFIELD'),
        'A second apply leaves the heading with its own column, not another.');
      Check((Grid.Columns[2].Title.Caption = 'First') and
        (Grid.Columns[2].FieldName = 'FIRSTFIELD'),
        'and the same at the other end.');
      { The width rule names column 0 as it was designed, and that column is
        now at the other end. Applying the widths before the reversal is what
        keeps the width with its own column instead of with its position. }
      Check(Grid.Columns[2].Width = 90,
        Format('A column keeps its own width through the reversal: %d, ' +
          'expected 90.', [Grid.Columns[2].Width]));

      Check((Box.TabOrder = 2) and (Ok.TabOrder = 0),
        Format('The Tab key follows the reader: edit %d, button %d.',
          [Box.TabOrder, Ok.TabOrder]));

      { And back to English. Returning to the source language has to put every
        one of those decisions back, or a user who tries Hebrew once is left
        with a mirrored English program. }
      { The path a manager takes when it is leaving a language: apply the
        layout with original values rather than translated ones. It is what
        runs on every switch, before the next pack is loaded.

        While the order was a toggle this call did nothing at all for
        columns - 'designed' was not 'reversed', so the branch was skipped -
        and the grid was only ever put back by a different path that happened
        to run later. Asking for the designed order is as much an instruction
        as asking for its reverse, and both now go through the same call. }
      Pack := HebrewPack;
      try
        TVCLTranslationApplicator.ApplyLayoutToForm(Form, Pack, 'frmRtl',
          False);
      finally
        Pack.Free;
      end;
      Check((Grid.Columns[0].FieldName = 'FIRSTFIELD') and
        (Grid.Columns[2].FieldName = 'THIRDFIELD'),
        'Restoring with original values puts the columns back as designed.');

      Pack := EnglishPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln('  after going back to English:');
      Writeln(Format('        label  Left=%d  Alignment=%d', [Name_.Left,
        Ord(Name_.Alignment)]));
      Writeln(Format('        panel  Align=%d', [Ord(Nav.Align)]));
      Writeln;
      Check(Name_.Left = 16,
        Format('The caption is back where it was drawn: %d, expected 16.',
          [Name_.Left]));
      Check(Box.Left = 104,
        Format('and so is the box: %d, expected 104.', [Box.Left]));
      Check(Inner.Left = 10,
        Format('and the one inside the panel: %d, expected 10.',
          [Inner.Left]));
      Check(Nav.Align = alLeft, 'The strip returns to its designed edge.');
      Check(Name_.Alignment = taLeftJustify, 'Alignment returns too.');
      Check(Box.Anchors = [akLeft, akTop], 'And the anchors.');
      Check(Form.BiDiMode = bdLeftToRight,
        'Reading order returns to left-to-right.');
      { The one the screenshots caught: switching from Arabic to Italian left
        the menus still opening right to left, and only a restart cleared it. }
      Check(Menu.BiDiMode = bdLeftToRight,
        'and so does the menu, without needing the application restarted.');
      Writeln(Format('        window ExStyle now RTLREADING=%s LEFTSCROLLBAR=%s LAYOUTRTL=%s',
        [BoolToStr((GetWindowLong(Form.Handle, GWL_EXSTYLE) and
           WS_EX_RTLREADING) <> 0, True),
         BoolToStr((GetWindowLong(Form.Handle, GWL_EXSTYLE) and
           WS_EX_LEFTSCROLLBAR) <> 0, True),
         BoolToStr((GetWindowLong(Form.Handle, GWL_EXSTYLE) and
           WS_EX_LAYOUTRTL) <> 0, True)]));
      Check((GetWindowLong(Form.Handle, GWL_EXSTYLE) and
        WS_EX_RTLREADING) = 0,
        'The window stops reading right to left, without a restart.');
      Check((GetWindowLong(Form.Handle, GWL_EXSTYLE) and
        WS_EX_LEFTSCROLLBAR) = 0,
        'and its scroll bar returns to the right-hand side.');
      Writeln(Format('        menu RTL flag now = %s',
        [BoolToStr(MenuIsRightToLeft(Menu), True)]));
      { The flag Windows actually draws menus from. The property was already
        correct here while the screen was not, which is why every earlier
        check passed and the menus stayed reversed until a restart. }
      Check(not MenuIsRightToLeft(Menu),
        'The menu itself stops opening right to left.');
      Check(MenuBarOrder(Menu) = DesignedMenuOrder,
        'and the menu bar returns to its designed order.');
      Writeln(Format('        grid   headings: %s, %s, %s',
        [Grid.Columns[0].Title.Caption, Grid.Columns[1].Title.Caption,
         Grid.Columns[2].Title.Caption]));
      Check(Grid.Columns[0].Title.Caption = 'First',
        'The grid columns return to their designed order.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL right-to-left smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('VCL right-to-left smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
