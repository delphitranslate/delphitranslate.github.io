unit DAT.Scan.Rules;

interface

uses
  DAT.Core.Types;

type
  TScanRuleSet = class
  private
    class function ClassMatches(const AComponentClassName: string;
      const AClassNames: array of string): Boolean; static;
  public
    class function IsTranslatableProperty(const AFramework: TTargetFramework;
      const AComponentClassName, APropertyName: string;
      const AIsRootObject: Boolean): Boolean; static;
    class function ClassifyRuntimeTextRole(const AComponentName,
      AComponentClassName, APropertyName, ASourceText: string):
      TRuntimeTextRole; static;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

class function TScanRuleSet.ClassifyRuntimeTextRole(
  const AComponentName, AComponentClassName, APropertyName,
  ASourceText: string): TRuntimeTextRole;
var
  ComponentName: string;
  SourceText: string;
begin
  ComponentName := LowerCase(Trim(AComponentName));
  SourceText := Trim(ASourceText);

  if (SourceText = '-') or (SourceText = '--') or (SourceText = '---') or
    SameText(SourceText, 'N/A') then
    Exit(rtrExcluded);

  if StartsText('http://', SourceText) or StartsText('https://', SourceText) or
    StartsText('mailto:', SourceText) or ContainsText(SourceText, '@') then
    Exit(rtrIdentifier);

  if EndsText('value', ComponentName) or EndsText('count', ComponentName) or
    EndsText('total', ComponentName) or ContainsText(ComponentName, 'datavalue') or
    ContainsText(ComponentName, 'metricvalue') then
    Exit(rtrDataValue);

  if ContainsText(ComponentName, 'statusbar') or
    ContainsText(ComponentName, 'connectionstatus') or
    ContainsText(ComponentName, 'refreshstatus') or
    ContainsText(ComponentName, 'activity') or
    ContainsText(ComponentName, 'message') or
    ContainsText(ComponentName, 'result') or
    ContainsText(ComponentName, 'progress') or
    ContainsText(ComponentName, 'lastupdated') then
    Exit(rtrDynamicValue);

  Result := rtrStaticText;
end;

class function TScanRuleSet.ClassMatches(const AComponentClassName: string;
  const AClassNames: array of string): Boolean;
var
  ClassName: string;
begin
  Result := False;
  for ClassName in AClassNames do
    if SameText(AComponentClassName, ClassName) then
      Exit(True);
end;

class function TScanRuleSet.IsTranslatableProperty(
  const AFramework: TTargetFramework;
  const AComponentClassName, APropertyName: string;
  const AIsRootObject: Boolean): Boolean;
begin
  Result := False;

  if SameText(APropertyName, 'Hint') then
    Exit(True);

  if AIsRootObject and SameText(APropertyName, 'Caption') then
    Exit(True);

  { Dialog captions are user-visible and were staying English in every
    application we scanned. The property is spelled the same either way. }
  if SameText(APropertyName, 'Title') then
    Exit(ClassMatches(AComponentClassName,
      ['TOpenDialog', 'TSaveDialog', 'TOpenPictureDialog',
       'TSavePictureDialog', 'TFileOpenDialog', 'TFileSaveDialog',
       'TTaskDialog', 'TMetropolisUIListBoxItem']));

  case AFramework of
    tfVCL:
      begin
        if SameText(APropertyName, 'Caption') then
          Exit(ClassMatches(AComponentClassName,
            ['TLabel', 'TButton', 'TBitBtn', 'TSpeedButton', 'TMenuItem',
             'TCheckBox', 'TRadioButton', 'TGroupBox', 'TTabSheet', 'TAction',
             'TStaticText',
             { A radio group's own caption. Its items were being read and its
               caption was not, so the box came out with translated choices
               under an English heading. }
             'TRadioGroup',
             { Panels are routinely used as captioned headers, and this is the
               single most common VCL class we were not reading. }
             'TPanel', 'TCategoryPanel', 'TFlowPanel', 'TGridPanel', 'TPage',
             'TLinkLabel', 'TBoundLabel', 'TToolButton', 'TToolBar',
             { Collection items: list-view columns and groups, action manager
               and category button captions. }
             'TListColumn', 'TActionClientItem', 'TActionListItem',
             'TBaseButtonItem', 'TButtonCategory', 'TControlAction',
             'TTaskDialog',
             { Designer-authored rows of a list view or a button group. These
               are collection items, so they are only reachable at all because
               collections are walked properly now. }
             'TListItem', 'TGrpButtonItem']));
        if SameText(APropertyName, 'Text') then
          Exit(ClassMatches(AComponentClassName,
            ['TStatusPanel', 'THeaderSection', 'TCoolBand', 'TComboBoxEx',
             'TButtonedEdit', 'TTaskDialog', 'TTreeNode']));
        if SameText(APropertyName, 'Description') then
          Exit(ClassMatches(AComponentClassName,
            ['TImageCollectionItem']));
        { A list-view row carries more than its first column. }
        if SameText(APropertyName, 'SubItems.Strings') then
          Exit(ClassMatches(AComponentClassName, ['TListItem']));
        if SameText(APropertyName, 'Header') then
          Exit(ClassMatches(AComponentClassName, ['TListGroup']));
        if SameText(APropertyName, 'FooterText') or
          SameText(APropertyName, 'ExpandedText') then
          Exit(ClassMatches(AComponentClassName, ['TTaskDialog']));
        { A data-aware grid column publishes its heading one level down. }
        if SameText(APropertyName, 'Title.Caption') then
          Exit(ClassMatches(AComponentClassName, ['TColumn']));
        if SameText(APropertyName, 'TextHint') then
          Exit(ClassMatches(AComponentClassName,
            ['TEdit', 'TMaskEdit', 'TComboBox', 'TLabeledEdit',
             'TButtonedEdit', 'TNumberBox']));
        if SameText(APropertyName, 'Lines.Strings') then
          Exit(ClassMatches(AComponentClassName, ['TMemo', 'TRichEdit']));
        if SameText(APropertyName, 'Items.Strings') then
          Exit(ClassMatches(AComponentClassName,
            ['TListBox', 'TComboBox', 'TCheckListBox', 'TRadioGroup']));
        { A whole string list of tab captions, authored in the designer. }
        if SameText(APropertyName, 'Tabs.Strings') then
          Exit(ClassMatches(AComponentClassName,
            ['TTabControl', 'TTabSet']));
      end;
    tfFireMonkey:
      begin
        if SameText(APropertyName, 'Header') then
          Exit(ClassMatches(AComponentClassName,
            ['TStringColumn', 'TCheckColumn', 'TDateColumn', 'TTimeColumn',
             'TProgressColumn', 'TImageColumn', 'TPopupColumn',
             { The base class too, so a column type we have not listed, or one
               the application defines itself, is still read. }
             'TColumn']));
        if SameText(APropertyName, 'Text') then
          Exit(ClassMatches(AComponentClassName,
            ['TLabel', 'TButton', 'TSpeedButton', 'TMenuItem', 'TTabItem',
             'TCheckBox', 'TRadioButton', 'TGroupBox', 'TAction',
             { A graphic text primitive used constantly on styled forms in
               place of TLabel, and previously invisible to us. }
             'TText', 'TCornerButton', 'TExpander', 'TExpanderButton',
             'TEditButton', 'TControlAction', 'TMaskEdit',
             { Items placed at design time. We read the string lists of a list
               box already, but not item objects. }
             'TListBoxItem', 'TTreeViewItem', 'THeaderItem']));
        if SameText(APropertyName, 'Description') then
          Exit(ClassMatches(AComponentClassName,
            ['TMetropolisUIListBoxItem']));
        if SameText(APropertyName, 'TextPrompt') then
          Exit(ClassMatches(AComponentClassName,
            ['TEdit', 'TClearingEdit', 'TComboEdit', 'TMaskEdit']));
        if SameText(APropertyName, 'Lines.Strings') then
          Exit(ClassMatches(AComponentClassName, ['TMemo']));
        if SameText(APropertyName, 'Items.Strings') then
          Exit(ClassMatches(AComponentClassName,
            ['TListBox', 'TComboBox', 'TPopupBox', 'TComboEdit']));
      end;
  end;
end;

end.
