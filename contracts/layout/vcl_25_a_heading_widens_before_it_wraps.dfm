object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 400
  ClientWidth = 989
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object lblHeader: TLabel
    Left = 392
    Top = 32
    Width = 231
    Height = 50
    Alignment = taCenter
    AutoSize = False
    Caption = 'Email Settings'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object chkEnableEmail: TCheckBox
    Left = 745
    Top = 44
    Width = 120
    Height = 17
    Caption = 'Enable Email'
  end
  object lblRecipients: TLabel
    Left = 470
    Top = 150
    Width = 130
    Height = 15
    Caption = 'Email Recipients:'
  end
end
