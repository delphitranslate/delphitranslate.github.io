object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 300
  ClientWidth = 600
  object btnRecalculate: TButton
    Left = 200
    Top = 100
    Width = 130
    Height = 46
    Font.Height = -13
    Caption = 'Recalculate'
  end
  object lblWhen: TLabel
    Left = 340
    Top = 106
    Width = 120
    Height = 22
    Font.Height = -13
    Alignment = taRightJustify
    Caption = 'Date:'
  end
  object edtWhen: TEdit
    Left = 470
    Top = 102
    Width = 110
    Height = 28
  end
end
