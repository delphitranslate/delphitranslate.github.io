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
  object pnlNav: TPanel
    Left = 0
    Top = 0
    Width = 100
    Height = 300
    Align = alLeft
    Caption = ''
  end
  object lblLeft: TLabel
    Left = 120
    Top = 20
    Width = 120
    Height = 17
    AutoSize = False
    Alignment = taLeftJustify
    Caption = 'Name'
  end
  object lblCentre: TLabel
    Left = 120
    Top = 50
    Width = 120
    Height = 17
    AutoSize = False
    Alignment = taCenter
    Caption = 'Title'
  end
  object edtStretch: TEdit
    Left = 120
    Top = 80
    Width = 200
    Height = 25
    Anchors = [akLeft, akTop]
  end
end
