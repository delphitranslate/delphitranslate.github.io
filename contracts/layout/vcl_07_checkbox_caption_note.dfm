object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 260
  ClientWidth = 760
  object chkEnable: TCheckBox
    Left = 260
    Top = 70
    Width = 130
    Height = 24
    Font.Height = -13
    Caption = 'Enable logging'
  end
  object lblNote: TLabel
    WordWrap = True
    Left = 404
    Top = 68
    Width = 210
    Height = 36
    Font.Height = -13
    Caption = 'Check this box to turn on logging.'
  end
end
