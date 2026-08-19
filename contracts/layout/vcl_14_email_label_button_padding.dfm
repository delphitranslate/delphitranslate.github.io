object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 260
  ClientWidth = 760
  object lblAddress: TLabel
    Left = 420
    Top = 86
    Width = 190
    Height = 22
    Font.Height = -13
    Caption = 'Email address'
  end
  object edtAddress: TEdit
    Left = 420
    Top = 112
    Width = 285
    Height = 32
    Text = ''
  end
  object btnSend: TButton
    Left = 420
    Top = 150
    Width = 190
    Height = 34
    Font.Height = -13
    Caption = 'Send test message'
  end
end
