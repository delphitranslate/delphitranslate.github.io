object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 240
  ClientWidth = 620
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object navBar: TPanel
    Left = 0
    Top = 0
    Width = 620
    Height = 60
    Align = alTop
    object navPropertyMap: TPanel
      Left = 0
      Top = 0
      Width = 144
      Height = 48
      Align = alLeft
      object lblPropertyMap: TLabel
        Left = 0
        Top = 0
        Width = 144
        Height = 48
        Align = alClient
        Alignment = taCenter
        Caption = 'Property Mapping'
        Font.Height = -17
        ParentFont = False
      end
    end
  end
end
