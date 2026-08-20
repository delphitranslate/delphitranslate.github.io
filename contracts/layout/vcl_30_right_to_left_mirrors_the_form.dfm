object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 300
  ClientWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object lblName: TLabel
    Left = 16
    Top = 20
    Width = 80
    Height = 17
    AutoSize = False
    Caption = 'Name'
  end
  object edtName: TEdit
    Left = 104
    Top = 16
    Width = 200
    Height = 25
  end
  object btnOk: TButton
    Left = 230
    Top = 120
    Width = 75
    Height = 25
    Caption = 'OK'
  end
  object pnlSide: TPanel
    Left = 20
    Top = 160
    Width = 200
    Height = 60
    Caption = ''
    object btnInner: TButton
      Left = 10
      Top = 15
      Width = 75
      Height = 25
      Caption = 'Inner'
    end
  end
end
