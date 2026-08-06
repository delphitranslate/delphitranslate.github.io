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
  end;

implementation

uses
  System.SysUtils;

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

  case AFramework of
    tfVCL:
      begin
        if SameText(APropertyName, 'Caption') then
          Exit(ClassMatches(AComponentClassName,
            ['TLabel', 'TButton', 'TBitBtn', 'TSpeedButton', 'TMenuItem',
             'TCheckBox', 'TRadioButton', 'TGroupBox', 'TTabSheet', 'TAction',
             'TStaticText']));
        if SameText(APropertyName, 'TextHint') then
          Exit(ClassMatches(AComponentClassName,
            ['TEdit', 'TMaskEdit', 'TComboBox', 'TLabeledEdit']));
        if SameText(APropertyName, 'Lines.Strings') then
          Exit(ClassMatches(AComponentClassName, ['TMemo', 'TRichEdit']));
        if SameText(APropertyName, 'Items.Strings') then
          Exit(ClassMatches(AComponentClassName,
            ['TListBox', 'TComboBox', 'TCheckListBox', 'TRadioGroup']));
      end;
    tfFireMonkey:
      begin
        if SameText(APropertyName, 'Text') then
          Exit(ClassMatches(AComponentClassName,
            ['TLabel', 'TButton', 'TSpeedButton', 'TMenuItem', 'TTabItem',
             'TCheckBox', 'TRadioButton', 'TGroupBox', 'TAction']));
        if SameText(APropertyName, 'TextPrompt') then
          Exit(ClassMatches(AComponentClassName,
            ['TEdit', 'TClearingEdit', 'TComboEdit']));
        if SameText(APropertyName, 'Lines.Strings') then
          Exit(ClassMatches(AComponentClassName, ['TMemo']));
        if SameText(APropertyName, 'Items.Strings') then
          Exit(ClassMatches(AComponentClassName,
            ['TListBox', 'TComboBox', 'TPopupBox']));
      end;
  end;
end;

end.
