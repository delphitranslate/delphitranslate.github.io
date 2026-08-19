object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 180
  ClientWidth = 560
  object lblDateRange: TLabel
    Left = 70
    Top = 80
    Width = 180
    Height = 28
    Font.Height = -13
    Alignment = taRightJustify
    Caption = 'Start and end time:'
  end
  object edtStart: TEdit
    Left = 270
    Top = 78
    Width = 105
    Height = 32
    Text = ''
  end
end
